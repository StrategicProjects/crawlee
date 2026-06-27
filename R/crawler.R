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
    store_dir = NULL,
    browser_wait = 0,
    browser_wait_selector = NULL,
    checkpoint_every = 25L,
    parallel = FALSE,
    max_active = NULL,
    autoscale = FALSE,
    min_concurrency = 1L,
    max_concurrency = 16L,
    stream = FALSE,
    stream_adaptive = FALSE,
    log_level = "info"
  )
}

#' Crawler
#'
#' The stateful object at the center of crawlee. It holds the request queue,
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
    #' @field defaults Named list of default handlers by content kind
    #'   (`html`, `pdf`, `any`).
    defaults = NULL,
    #' @field kv Lazily-created [KeyValueStore] for binary content.
    kv = NULL,
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
      self$defaults <- list()
      self$stats <- list(requests = 0L, succeeded = 0L, failed = 0L, skipped = 0L)
      private$logger <- make_logger(self$options$log_level)
      private$robots_cache <- new.env(parent = emptyenv())
      private$crawl_delay <- 0
      private$start_urls <- start_urls
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

    #' @description Register a handler for a content label or kind.
    #' @param handler A function of one argument, the handler context.
    #' @param label Optional label; `NULL` registers a default handler.
    #' @param kind Content kind for the default handler (`"html"`, `"pdf"`,
    #'   `"any"`). Ignored when `label` is given.
    set_handler = function(handler, label = NULL, kind = "html") {
      if (is.null(label)) {
        self$defaults[[kind]] <- handler
      } else {
        self$handlers[[label]] <- handler
      }
      invisible(self)
    },

    #' @description Get (lazily creating) the key-value store for binaries.
    #' @return A [KeyValueStore].
    get_kv = function() {
      if (is.null(self$kv)) {
        self$kv <- KeyValueStore$new(self$options$store_dir)
      }
      self$kv
    },

    #' @description Set the run directory where the manifest is written.
    #' @param dir A directory path.
    set_persist_dir = function(dir) {
      private$persist_dir <- dir
      invisible(self)
    },

    #' @description Release resources (browser session, DuckDB connection).
    close = function() {
      private$close_browser()
      if (!is.null(self$dataset)) self$dataset$close()
      invisible(self)
    },

    #' @description Run the crawl until the queue drains or a limit is hit.
    run = function() {
      log <- private$logger
      on.exit(private$close_browser(), add = TRUE)
      on.exit(self$queue$save(), add = TRUE)
      on.exit(private$write_manifest(), add = TRUE)
      cli::cli_rule("crawlee - starting crawl")
      if (self$queue$handled() > 0L) {
        log$info("Resuming - already handled: {self$queue$handled()}")
      }
      parallel <- isTRUE(self$options$parallel) &&
        identical(self$mode, "http") &&
        as.integer(self$options$concurrency) > 1L
      streaming <- parallel && isTRUE(self$options$stream)
      conc_txt <- if (!parallel) {
        ""
      } else if (streaming && isTRUE(self$options$stream_adaptive)) {
        paste0(" stream ", self$options$min_concurrency, "-", self$options$max_concurrency)
      } else if (streaming) {
        paste0(" stream x", self$options$concurrency)
      } else if (isTRUE(self$options$autoscale)) {
        paste0(" autoscale ", self$options$min_concurrency, "-", self$options$max_concurrency)
      } else {
        paste0(" x", self$options$concurrency)
      }
      log$info("Mode: {.val {self$mode}}{conc_txt} - pending: {self$queue$pending_count()}")
      if (streaming) {
        private$run_stream()
      } else if (parallel) {
        private$run_parallel()
      } else {
        private$run_sequential()
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
    browser = NULL,
    persist_dir = NULL,
    start_urls = NULL,

    # Write a reproducibility manifest to the run directory (no-op if unset).
    write_manifest = function() {
      if (is.null(private$persist_dir)) {
        return(invisible(FALSE))
      }
      keep <- c(
        "max_requests", "max_depth", "delay", "respect_robots",
        "user_agent", "checkpoint_every"
      )
      manifest <- list(
        package = "crawlee",
        start_urls = private$start_urls,
        mode = self$mode,
        options = self$options[keep],
        stats = self$stats,
        pending = self$queue$pending_count(),
        handled = self$queue$handled(),
        updated_at = format(Sys.time(), tz = "UTC", usetz = TRUE)
      )
      saveRDS(manifest, file.path(private$persist_dir, "manifest.rds"))
      if (requireNamespace("jsonlite", quietly = TRUE)) {
        writeLines(
          jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE, null = "null"),
          file.path(private$persist_dir, "manifest.json")
        )
      }
      invisible(TRUE)
    },

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

    # ---- engine loops -------------------------------------------------------

    # Sequential engine: one request at a time.
    run_sequential = function() {
      every <- max(1L, as.integer(self$options$checkpoint_every))
      processed <- 0L
      while (!self$queue$is_empty() && self$stats$requests < self$options$max_requests) {
        req <- self$queue$pop()
        if (is.null(req)) break
        private$process(req)
        processed <- processed + 1L
        if (processed %% every == 0L) self$queue$save()
        wait <- max(self$options$delay, private$crawl_delay)
        if (wait > 0) Sys.sleep(wait)
      }
    },

    # Parallel engine: fetch a batch concurrently (network I/O), then dispatch
    # handlers sequentially in R (no shared-state hazard).
    run_parallel = function() {
      log <- private$logger
      autoscale <- isTRUE(self$options$autoscale)
      lo <- max(1L, as.integer(self$options$min_concurrency))
      hi <- max(lo, as.integer(self$options$max_concurrency))
      conc <- if (autoscale) lo else as.integer(self$options$concurrency)
      while (!self$queue$is_empty() && self$stats$requests < self$options$max_requests) {
        room <- self$options$max_requests - self$stats$requests
        take <- min(conc, room)
        batch <- list()
        while (length(batch) < take && !self$queue$is_empty()) {
          req <- self$queue$pop()
          if (is.null(req)) break
          rb <- private$robots_check(req$url)
          if (!rb$allowed) {
            log$warn("Blocked by robots.txt: {.url {req$url}}")
            self$stats$skipped <- self$stats$skipped + 1L
            next
          }
          req$crawl_delay <- rb$crawl_delay %||% 0
          batch[[length(batch) + 1L]] <- req
        }
        if (!length(batch)) next
        reqs <- lapply(batch, private$build_request)
        resps <- httr2::req_perform_parallel(
          reqs,
          on_error = "continue",
          max_active = self$options$max_active %||% conc,
          progress = FALSE
        )
        self$stats$requests <- self$stats$requests + length(batch)
        statuses <- vapply(resps, result_status, integer(1))
        for (i in seq_along(batch)) {
          resp <- resps[[i]]
          if (inherits(resp, "httr2_response")) {
            private$dispatch_fetched(batch[[i]], fetched_response(resp))
          } else {
            private$handle_fetch_error(batch[[i]], resp)
          }
        }
        if (autoscale) {
          old <- conc
          conc <- autoscale_next(conc, is_backpressure(statuses), lo, hi)
          if (conc != old) {
            log$debug("autoscale: concurrency {old} -> {conc}")
          }
        }
        self$queue$save()
        cd <- max(vapply(batch, function(r) r$crawl_delay %||% 0, numeric(1)))
        wait <- max(self$options$delay, cd)
        if (wait > 0) Sys.sleep(wait)
      }
      self$stats$final_concurrency <- conc
      if (autoscale) log$info("Autoscale settled at concurrency {conc}.")
    },

    # Streaming engine: keep requests in flight at all times via async
    # promises; as soon as one finishes, dispatch it and pull the next from the
    # queue. Maximises throughput under heterogeneous latency. Optionally
    # adapts the in-flight target (AIMD on back-pressure) and paces launches
    # per host (`delay` / `Crawl-delay`), running distinct hosts in parallel.
    run_stream = function() {
      rlang::check_installed(c("promises", "later"), "for the streaming scheduler.")
      log <- private$logger
      adaptive <- isTRUE(self$options$stream_adaptive)
      lo <- max(1L, as.integer(self$options$min_concurrency))
      hi <- max(lo, as.integer(self$options$max_concurrency))
      every <- max(1L, as.integer(self$options$checkpoint_every))

      e <- new.env(parent = emptyenv())
      e$active <- 0L
      e$completed <- 0L
      e$target <- if (adaptive) lo else as.integer(self$options$concurrency)
      e$win <- integer(0)
      e$deferred <- list()
      e$host_next <- new.env(parent = emptyenv())
      e$timer_set <- FALSE

      budget_left <- function() self$stats$requests < self$options$max_requests
      host_ready_at <- function(h) e$host_next[[h]] %||% 0
      spacing_of <- function(req) max(self$options$delay, req$crawl_delay %||% 0)

      # Next launchable request honouring per-host pacing, or NULL if none now.
      take_one <- function() {
        nowt <- as.numeric(Sys.time())
        if (length(e$deferred)) {
          for (i in seq_along(e$deferred)) {
            r <- e$deferred[[i]]
            if (nowt >= host_ready_at(url_host(r$url))) {
              e$deferred[[i]] <- NULL
              return(r)
            }
          }
        }
        while (!self$queue$is_empty()) {
          req <- self$queue$pop()
          if (is.null(req)) break
          rb <- private$robots_check(req$url)
          if (!rb$allowed) {
            log$warn("Blocked by robots.txt: {.url {req$url}}")
            self$stats$skipped <- self$stats$skipped + 1L
            next
          }
          req$crawl_delay <- rb$crawl_delay %||% 0
          if (nowt >= host_ready_at(url_host(req$url))) {
            return(req)
          }
          e$deferred[[length(e$deferred) + 1L]] <- req
        }
        NULL
      }

      soonest_wait <- function() {
        if (!length(e$deferred)) {
          return(NA_real_)
        }
        nowt <- as.numeric(Sys.time())
        mn <- Inf
        for (r in e$deferred) mn <- min(mn, host_ready_at(url_host(r$url)))
        max(0, mn - nowt)
      }

      adjust <- function() {
        window <- max(2L, e$target)
        if (length(e$win) >= window) {
          old <- e$target
          e$target <- autoscale_next(e$target, is_backpressure(e$win), lo, hi)
          e$win <- integer(0)
          if (e$target != old) log$debug("stream autoscale: {old} -> {e$target}")
        }
      }

      fill <- function() {
        while (e$active < e$target && budget_left()) {
          r <- take_one()
          if (is.null(r)) break
          self$stats$requests <- self$stats$requests + 1L
          e$active <- e$active + 1L
          e$host_next[[url_host(r$url)]] <- as.numeric(Sys.time()) + spacing_of(r)
          local({
            rr <- r
            p <- httr2::req_perform_promise(private$build_request(rr))
            p <- promises::then(
              p,
              onFulfilled = function(resp) {
                if (adaptive) e$win <- c(e$win, result_status(resp))
                private$dispatch_fetched(rr, fetched_response(resp))
              },
              onRejected = function(err) {
                if (adaptive) e$win <- c(e$win, result_status(err))
                private$handle_fetch_error(rr, err)
              }
            )
            promises::finally(p, function() {
              e$active <- e$active - 1L
              e$completed <- e$completed + 1L
              if (e$completed %% every == 0L) self$queue$save()
              if (adaptive) adjust()
              fill()
            })
          })
        }
        # Nothing in flight but paced work remains: wake up when a host frees.
        if (e$active == 0L && !e$timer_set && budget_left()) {
          wait <- soonest_wait()
          if (!is.na(wait)) {
            e$timer_set <- TRUE
            later::later(function() {
              e$timer_set <- FALSE
              fill()
            }, max(0.02, wait))
          }
        }
      }

      fill()
      while (e$active > 0L ||
        (budget_left() && (length(e$deferred) > 0L || !self$queue$is_empty()))) {
        later::run_now(timeout = 0.25)
      }
      self$stats$final_concurrency <- e$target
      if (adaptive) log$info("Streaming autoscale settled at concurrency {e$target}.")
    },

    # Fetch + dispatch a single request (sequential path), with robots gate.
    process = function(req) {
      log <- private$logger
      rb <- private$robots_check(req$url)
      private$crawl_delay <- rb$crawl_delay %||% 0
      if (!rb$allowed) {
        log$warn("Blocked by robots.txt: {.url {req$url}}")
        self$stats$skipped <- self$stats$skipped + 1L
        return(invisible(NULL))
      }
      self$stats$requests <- self$stats$requests + 1L
      fetched <- tryCatch(private$fetch(req), error = function(e) e)
      if (inherits(fetched, "error")) {
        private$handle_fetch_error(req, fetched)
        return(invisible(NULL))
      }
      private$dispatch_fetched(req, fetched)
    },

    # Retry (reschedule) a failed request, or give up after max_retries.
    handle_fetch_error = function(req, cond) {
      log <- private$logger
      if (req$retry_count < self$options$max_retries) {
        log$warn("Retry {.url {req$url}} ({conditionMessage(cond)})")
        self$queue$reschedule(req)
      } else {
        log$error("Failed {.url {req$url}}: {conditionMessage(cond)}")
        self$stats$failed <- self$stats$failed + 1L
      }
      invisible(NULL)
    },

    # Classify content, route to a handler, run it, and update stats.
    dispatch_fetched = function(req, fetched) {
      log <- private$logger
      kind <- classify_content(fetched$content_type, req$url)
      handler <- private$resolve_handler(req, kind)
      if (is.null(handler)) {
        log$debug("No handler for {req$url} (kind: {kind})")
      } else {
        page <- if (kind == "html") {
          tryCatch(xml2::read_html(fetched$html()), error = function(e) NULL)
        }
        ctx <- crawler_context(self, req, fetched, page, private$logger, kind)
        tryCatch(
          handler(ctx),
          error = function(e) {
            log$error("Handler error on {.url {req$url}}: {conditionMessage(e)}")
          }
        )
      }
      self$queue$mark_handled()
      self$stats$succeeded <- self$stats$succeeded + 1L
      log$info("{.url {req$url}} -> {fetched$status} ({kind})")
      invisible(NULL)
    },

    resolve_handler = function(req, kind) {
      if (!is.null(req$label) && !is.null(self$handlers[[req$label]])) {
        return(self$handlers[[req$label]])
      }
      self$defaults[[kind]] %||% self$defaults[["any"]]
    },

    # Dispatch to the active fetch backend, returning a normalised `fetched`.
    fetch = function(req) {
      if (identical(self$mode, "browser")) {
        private$fetch_browser(req)
      } else {
        private$fetch_http(req)
      }
    },

    # Build (but do not perform) an httr2 request — shared by the sequential
    # and parallel HTTP engines.
    build_request = function(req) {
      httr2::request(req$url) |>
        httr2::req_method(req$method) |>
        httr2::req_user_agent(self$options$user_agent) |>
        httr2::req_timeout(self$options$timeout) |>
        httr2::req_retry(max_tries = 1L)
    },

    fetch_http = function(req) {
      fetched_response(httr2::req_perform(private$build_request(req)))
    },

    fetch_browser = function(req) {
      private$ensure_browser()
      browser_fetch(
        private$browser, req$url,
        wait = self$options$browser_wait,
        wait_selector = self$options$browser_wait_selector,
        timeout = self$options$timeout
      )
    },

    ensure_browser = function() {
      if (is.null(private$browser)) {
        rlang::check_installed("chromote", "for the browser backend.")
        private$browser <- chromote::ChromoteSession$new()
      }
      invisible(private$browser)
    },

    close_browser = function() {
      if (!is.null(private$browser)) {
        try(private$browser$close(), silent = TRUE)
        private$browser <- NULL
      }
      invisible(NULL)
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

#' Enable parallel (concurrent) fetching
#'
#' Switches the HTTP engine to fetch requests in concurrent batches via
#' `httr2::req_perform_parallel()`, the rough equivalent of Crawlee's
#' autoscaled pool. Network I/O runs concurrently while handlers still run
#' sequentially in R, so there is no shared-state hazard. `robots.txt`,
#' retries, `max_requests`/`max_depth` and queue checkpointing all still apply.
#'
#' Parallel mode applies to the HTTP backend only; the browser backend always
#' runs sequentially. `delay` and `Crawl-delay` are applied *between* batches.
#'
#' @param crawler A [Crawler].
#' @param concurrency Number of requests per batch.
#' @param max_active Maximum simultaneously-active connections (defaults to
#'   `concurrency`).
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' crawler("https://example.com") |> cr_parallel(concurrency = 8)
cr_parallel <- function(crawler, concurrency = 4L, max_active = NULL) {
  check_crawler(crawler)
  if (concurrency < 1L) {
    cli::cli_abort("{.arg concurrency} must be a positive integer.")
  }
  crawler$set_options(
    parallel = TRUE,
    concurrency = as.integer(concurrency),
    max_active = max_active
  )
  invisible(crawler)
}

#' Enable autoscaled parallel fetching
#'
#' Like [cr_parallel()], but the batch concurrency adapts at run time, the
#' rough equivalent of Crawlee's autoscaled pool. After each batch the engine
#' adjusts concurrency with an additive-increase / multiplicative-decrease
#' rule: it grows by one when a batch is clean, and halves on back-pressure
#' (a transport failure or an HTTP 429/500/502/503/504), staying within
#' `[min, max]`.
#'
#' @param crawler A [Crawler].
#' @param min,max Concurrency bounds. The crawl starts at `min`.
#' @param max_active Maximum simultaneously-active connections (defaults to the
#'   current concurrency).
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' crawler("https://example.com") |> cr_autoscale(min = 2, max = 16)
cr_autoscale <- function(crawler, min = 1L, max = 16L, max_active = NULL) {
  check_crawler(crawler)
  if (min < 1L || max < min) {
    cli::cli_abort("Require {.code 1 <= min <= max} (got min = {min}, max = {max}).")
  }
  crawler$set_options(
    parallel = TRUE,
    autoscale = TRUE,
    min_concurrency = as.integer(min),
    max_concurrency = as.integer(max),
    max_active = max_active
  )
  invisible(crawler)
}

#' Enable the streaming scheduler
#'
#' A continuous-pool alternative to [cr_parallel()]'s synchronous batches. The
#' streaming engine keeps requests in flight at all times (via async promises,
#' [httr2::req_perform_promise()]): the moment one request finishes, its handler
#' runs and the next request is pulled from the queue to refill the slot. Under
#' heterogeneous response latency this avoids the "wait for the slowest in the
#' batch" stall and improves throughput.
#'
#' With `adaptive = TRUE` the in-flight target adapts at run time (AIMD on
#' back-pressure, like [cr_autoscale()]), within `[min, max]`.
#'
#' Launches are paced **per host**: a host is not hit again until `delay` /
#' `robots.txt` `Crawl-delay` has elapsed, while different hosts run in
#' parallel. With `delay = 0` and no `Crawl-delay`, pacing is a no-op.
#'
#' Requires the \pkg{promises} and \pkg{later} packages, and the HTTP backend.
#'
#' @param crawler A [Crawler].
#' @param concurrency Number of requests to keep in flight (the fixed target,
#'   or the starting point is `min` when `adaptive = TRUE`).
#' @param adaptive If `TRUE`, adapt the in-flight target within `[min, max]`.
#' @param min,max Bounds for the adaptive target. `max` defaults to
#'   `concurrency`.
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' crawler("https://example.com") |> cr_stream(concurrency = 10)
#' crawler("https://example.com") |> cr_stream(adaptive = TRUE, min = 2, max = 16)
cr_stream <- function(crawler, concurrency = 8L, adaptive = FALSE,
                      min = 1L, max = NULL) {
  check_crawler(crawler)
  if (concurrency < 1L) {
    cli::cli_abort("{.arg concurrency} must be a positive integer.")
  }
  max <- max %||% concurrency
  if (adaptive && (min < 1L || max < min)) {
    cli::cli_abort("Require {.code 1 <= min <= max} (got min = {min}, max = {max}).")
  }
  crawler$set_options(
    parallel = TRUE,
    stream = TRUE,
    stream_adaptive = adaptive,
    concurrency = as.integer(concurrency),
    min_concurrency = as.integer(min),
    max_concurrency = as.integer(max)
  )
  invisible(crawler)
}

#' Configure the dataset backend
#'
#' @param crawler A [Crawler].
#' @param backend One of `"memory"` (default), `"jsonl"`, `"duckdb"`.
#' @param path File (jsonl) or database (duckdb) path; required for the
#'   persistent backends.
#' @param table Table name for the `"duckdb"` backend.
#'
#' @return The crawler, invisibly.
#' @export
cr_dataset <- function(crawler, backend = "memory", path = NULL,
                       table = "dataset") {
  check_crawler(crawler)
  crawler$dataset <- Dataset$new(backend = backend, path = path, table = table)
  invisible(crawler)
}

#' @noRd
check_crawler <- function(crawler) {
  if (!inherits(crawler, "Crawler")) {
    cli::cli_abort("{.arg crawler} must be a {.cls Crawler} object.")
  }
  invisible(crawler)
}
