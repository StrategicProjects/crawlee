#' Build the handler context
#'
#' The context object passed to every handler. It bundles the current request,
#' the raw response, the parsed page and a set of action closures bound to the
#' running crawler.
#'
#' @return An environment with elements `request`, `response`, `page`, `kind`,
#'   `content_type`, `log` and the methods `push_data()`, `enqueue_links()`,
#'   `body_raw()`, `body_string()`, `pdf_text()` and `save_body()`.
#' @keywords internal
#' @noRd
crawler_context <- function(crawler, request, response, page, logger,
                            kind = "html", content_type = "") {
  ctx <- new.env(parent = emptyenv())
  ctx$request <- request
  ctx$response <- response
  ctx$page <- page
  ctx$kind <- kind
  ctx$content_type <- content_type
  ctx$log <- logger

  ctx$push_data <- function(data) {
    crawler$dataset$push(data)
    invisible(ctx)
  }

  ctx$body_raw <- function() httr2::resp_body_raw(response)

  ctx$body_string <- function() httr2::resp_body_string(response)

  ctx$pdf_text <- function() {
    rlang::check_installed("pdftools", "to extract text from PDF documents.")
    pdftools::pdf_text(httr2::resp_body_raw(response))
  }

  ctx$save_body <- function(key = NULL, ext = NULL) {
    key <- key %||% request$url
    if (!is.null(ext)) key <- paste0(key, ".", sub("^\\.", "", ext))
    crawler$get_kv()$set_raw(key, httr2::resp_body_raw(response))
  }

  ctx$enqueue_links <- function(selector = "a", glob = NULL, include = NULL,
                                exclude = NULL, label = NULL,
                                same_domain = NULL) {
    if (is.null(page)) {
      return(invisible(0L))
    }
    if (is.null(same_domain)) {
      same_domain <- isTRUE(crawler$options$same_domain)
    }
    nodes <- rvest::html_elements(page, selector)
    hrefs <- rvest::html_attr(nodes, "href")
    hrefs <- hrefs[!is.na(hrefs) & nzchar(hrefs)]
    if (!length(hrefs)) {
      return(invisible(0L))
    }
    urls <- xml2::url_absolute(hrefs, request$url)
    urls <- urls[grepl("^https?://", urls)]
    if (!is.null(glob)) {
      include <- c(include, glob)
    }
    urls <- urls[url_matches(urls, include = include, exclude = exclude)]
    if (same_domain && length(urls)) {
      urls <- urls[url_host(urls) == url_host(request$url)]
    }
    urls <- unique(urls)
    depth <- request$depth + 1L
    added <- 0L
    if (depth <= crawler$options$max_depth) {
      for (u in urls) {
        if (isTRUE(crawler$queue$add(u, label = label, depth = depth))) {
          added <- added + 1L
        }
      }
    }
    invisible(added)
  }

  ctx
}

#' Register an HTML handler
#'
#' Registers a function called for each successfully fetched page whose request
#' carries the given `label` (or for all pages when `label = NULL`). The
#' handler receives a context object exposing the parsed page and the actions
#' `push_data()` and `enqueue_links()`.
#'
#' @param crawler A [Crawler].
#' @param handler A function of one argument (the context). See **Context**.
#' @param label Optional handler label. Requests enqueued with the same label
#'   are routed here; `NULL` registers the default handler.
#'
#' @section Context:
#' The `ctx` passed to a handler contains:
#' \describe{
#'   \item{`request`}{The request list (`url`, `label`, `depth`, ...).}
#'   \item{`response`}{The `httr2` response object.}
#'   \item{`page`}{The parsed page (an `xml_document`) or `NULL`.}
#'   \item{`push_data(data)`}{Append a record to the dataset.}
#'   \item{`enqueue_links(...)`}{Discover and enqueue links from the page.}
#'   \item{`log`}{Logging functions (`info`, `success`, `warn`, `error`).}
#' }
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' crawler("https://example.com") |>
#'   cr_on_html(function(ctx) {
#'     ctx$push_data(list(url = ctx$request$url))
#'     ctx$enqueue_links()
#'   })
cr_on_html <- function(crawler, handler, label = NULL) {
  check_crawler(crawler)
  if (!is.function(handler)) {
    cli::cli_abort("{.arg handler} must be a function of one argument.")
  }
  crawler$set_handler(handler, label = label)
  invisible(crawler)
}
