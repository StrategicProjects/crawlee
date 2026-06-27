#' Default crawler options
#' @noRd
crawler_default_options <- function() {
  list(
    concurrency = 2L,
    max_requests = Inf,
    max_depth = Inf,
    delay = 0,
    timeout = 30,
    max_retries = 3L,
    user_agent = "crawlee-R (+https://github.com/StrategicProjects/crawlee)",
    respect_robots = TRUE,
    same_domain = TRUE,
    log_level = "info"
  )
}

#' Crawler
#'
#' The stateful object at the centre of crawlee. It holds the request queue,
#' the dataset, the registered handlers and the run configuration. You will
#' rarely create one with `Crawler$new()` directly; use [crawler()] and the
#' `cr_*` verbs, which return the crawler invisibly so they compose with the
#' native pipe (`|>`).
#'
#' @name Crawler-class
#' @aliases Crawler
#' @export
Crawler <- R6::R6Class(
  "Crawler",
  public = list(
    #' @field options Named list of run options.
    options = NULL,
    #' @field queue The [RequestQueue].
    queue = NULL,
    #' @field dataset The [Dataset].
    dataset = NULL,
    #' @field handlers Named list of label-specific handlers.
    handlers = NULL,
    #' @field default_handler Handler used when no label matches.
    default_handler = NULL,
    #' @field mode Fetch mode, `"http"` (default) or `"browser"`.
    mode = "http",
    #' @field stats Named list of run statistics.
    stats = NULL,

    #' @description Create a crawler.
    #' @param start_urls Character vector of seed URLs.
    #' @param ... Options forwarded to [cr_options()].
    initialize = function(start_urls = character(), ...) {
      self$options <- crawler_default_options()
      self$queue <- RequestQueue$new()
      self$dataset <- Dataset$new()
      self$handlers <- list()
      self$default_handler <- NULL
      self$stats <- list(requests = 0L, succeeded = 0L, failed = 0L, skipped = 0L)
      private$logger <- make_logger(self$options$log_level)
      private$robots_cache <- new.env(parent = emptyenv())
      private$crawl_delay <- 0
      opts <- rlang::list2(...)
      if (length(opts)) {
        self$set_options(!!!opts)
      }
      for (u in start_urls) {
        self$queue$add(u, depth = 0L)
      }
      invisible(self)
    },

    #' @description Update one or more options.
    #' @param ... Named options to override.
    set_options = function(...) {
      opts <- rlang::list2(...)
      unknown <- setdiff(names(opts), names(self$options))
      if (length(unknown)) {
        cli::cli_abort("Unknown option{?s}: {.field {unknown}}.")
      }
      self$options <- utils::modifyList(self$options, opts)
      private$logger <- make_logger(self$options$log_level)
      invisible(self)
    },

    #' @description Register a handler for a content label.
    #' @param handler A function of one argument, the handler context.
    #' @param label Optional label; `NULL` registers the default handler.
    set_handler = function(handler, label = NULL) {
      if (is.null(label)) {
        self$default_handler <- handler
      } else {
        self$handlers[[label]] <- handler
      }
      invisible(self)
    },

    #' @description Run the crawl until the queue drains or a limit is hit.
    run = function() {
      log <- private$logger
      cli::cli_rule("crawlee - starting crawl")
      log$info("Mode: {.val {self$mode}} - pending: {self$queue$pending_count()}")
      max_req <- self$options$max_requests
      while (!self$queue$is_empty() && self$stats$requests < max_req) {
        req <- self$queue$pop()
        if (is.null(req)) break
        self$stats$requests <- self$stats$requests + 1L
        private$process(req)
        wait <- max(self$options$delay, private$crawl_delay)
        if (wait > 0) Sys.sleep(wait)
      }
      cli::cli_rule("crawlee - done")
      log$success(
        "Handled {self$stats$succeeded} - failed {self$stats$failed} - ",
        "skipped {self$stats$skipped} - records {self$dataset$count()}"
      )
      invisible(self)
    }
  ),
  private = list(
    logger = NULL,
    robots_cache = NULL,
    crawl_delay = 0,

    # Check (and cache, per host) whether a URL is crawlable per robots.txt.
    robots_check = function(url) {
      if (!isTRUE(self$options$respect_robots)) {
        return(list(allowed = TRUE, crawl_delay = 0))
      }
      p <- xml2::url_parse(url)
      key <- paste0(tolower(p$scheme), "://", tolower(p$server))
      rec <- private$robots_cache[[key]]
      if (is.null(rec)) {
        txt <- tryCatch({
          r <- cr_http_get(
            paste0(key, "/robots.txt"),
            self$options$user_agent, self$options$timeout
          )
          if (httr2::resp_status(r) >= 400L) "" else httr2::resp_body_string(r)
        }, error = function(e) "")
        rec <- list(record = robots_select(parse_robots(txt), self$options$user_agent))
        private$robots_cache[[key]] <- rec
      }
      path <- if (nzchar(p$path)) p$path else "/"
      if (!is.na(p$query) && nzchar(p$query)) {
        path <- paste0(path, "?", p$query)
      }
      cd <- if (is.null(rec$record)) NA_real_ else rec$record$crawl_delay
      list(
        allowed = robots_path_allowed(path, rec$record),
        crawl_delay = if (is.na(cd)) 0 else cd
      )
    },

    # Fetch + dispatch a single request, with retry-on-error.
    process = function(req) {
      log <- private$logger
      rb <- private$robots_check(req$url)
      private$crawl_delay <- rb$crawl_delay %||% 0
      if (!rb$allowed) {
        log$warn("Blocked by robots.txt: {.url {req$url}}")
        self$stats$skipped <- self$stats$skipped + 1L
        return(invisible(NULL))
      }
      resp <- tryCatch(private$fetch(req), error = function(e) e)
      if (inherits(resp, "error")) {
        if (req$retry_count < self$options$max_retries) {
          log$warn("Retry {.url {req$url}} ({conditionMessage(resp)})")
          self$queue$reschedule(req)
        } else {
          log$error("Failed {.url {req$url}}: {conditionMessage(resp)}")
          self$stats$failed <- self$stats$failed + 1L
        }
        return(invisible(NULL))
      }
      handler <- private$resolve_handler(req)
      if (is.null(handler)) {
        log$debug("No handler for {req$url}")
      } else {
        page <- private$parse(resp)
        ctx <- crawler_context(self, req, resp, page, private$logger)
        tryCatch(
          handler(ctx),
          error = function(e) {
            log$error("Handler error on {.url {req$url}}: {conditionMessage(e)}")
          }
        )
      }
      self$queue$mark_handled()
      self$stats$succeeded <- self$stats$succeeded + 1L
      log$info("{.url {req$url}} -> {httr2::resp_status(resp)}")
      invisible(NULL)
    },

    resolve_handler = function(req) {
      if (!is.null(req$label) && !is.null(self$handlers[[req$label]])) {
        return(self$handlers[[req$label]])
      }
      self$default_handler
    },

    fetch = function(req) {
      httr2::request(req$url) |>
        httr2::req_method(req$method) |>
        httr2::req_user_agent(self$options$user_agent) |>
        httr2::req_timeout(self$options$timeout) |>
        httr2::req_retry(max_tries = 1L) |>
        httr2::req_perform()
    },

    parse = function(resp) {
      ct <- tryCatch(httr2::resp_content_type(resp), error = function(e) "")
      if (isTRUE(grepl("html|xml", ct))) {
        return(tryCatch(
          xml2::read_html(httr2::resp_body_string(resp)),
          error = function(e) NULL
        ))
      }
      NULL
    }
  )
)

#' Create a crawler
#'
#' Constructs a new [Crawler] seeded with `start_urls`. The result is designed
#' to be piped through the `cr_*` configuration verbs and finally [cr_run()].
#'
#' @param start_urls Character vector of seed URLs to enqueue at depth 0.
#' @param ... Options forwarded to [cr_options()] (e.g. `max_requests`,
#'   `delay`, `log_level`).
#'
#' @return A [Crawler] object.
#' @export
#'
#' @examples
#' cr <- crawler("https://example.com", max_requests = 10)
#' cr
crawler <- function(start_urls = character(), ...) {
  Crawler$new(start_urls = start_urls, ...)
}

#' Set crawler options
#'
#' @param crawler A [Crawler].
#' @param ... Named options to override. Recognised options: `concurrency`,
#'   `max_requests`, `max_depth`, `delay` (seconds between requests),
#'   `timeout`, `max_retries`, `user_agent`, `respect_robots`, `same_domain`,
#'   `log_level` (`"debug"`, `"info"`, `"warn"`, `"error"`, `"off"`).
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' crawler("https://example.com") |> cr_options(delay = 0.5, max_depth = 2)
cr_options <- function(crawler, ...) {
  check_crawler(crawler)
  crawler$set_options(...)
  invisible(crawler)
}

#' Use the HTTP fetch backend
#'
#' Selects the plain HTTP backend (powered by `httr2`), suitable for static
#' HTML, XML, RSS and document endpoints. This is the default mode.
#'
#' @param crawler A [Crawler].
#'
#' @return The crawler, invisibly.
#' @export
cr_use_http <- function(crawler) {
  check_crawler(crawler)
  crawler$mode <- "http"
  invisible(crawler)
}

#' Use the headless-browser fetch backend
#'
#' Reserved for a future release: rendering JavaScript-heavy pages via
#' `chromote`. Calling it currently signals an informative not-yet-implemented
#' error so pipelines fail loudly rather than silently using HTTP.
#'
#' @param crawler A [Crawler].
#'
#' @return The crawler, invisibly.
#' @export
cr_use_browser <- function(crawler) {
  check_crawler(crawler)
  cli::cli_abort(c(
    "The {.val browser} backend is not implemented yet.",
    "i" = "It is planned for a future release (chromote-based)."
  ))
}

#' Configure the dataset backend
#'
#' @param crawler A [Crawler].
#' @param backend One of `"memory"` (default), `"duckdb"`, `"parquet"`.
#' @param path Optional path used by persistent backends.
#'
#' @return The crawler, invisibly.
#' @export
cr_dataset <- function(crawler, backend = "memory", path = NULL) {
  check_crawler(crawler)
  crawler$dataset <- Dataset$new(backend = backend, path = path)
  invisible(crawler)
}

#' @noRd
check_crawler <- function(crawler) {
  if (!inherits(crawler, "Crawler")) {
    cli::cli_abort("{.arg crawler} must be a {.cls Crawler} object.")
  }
  invisible(crawler)
}
