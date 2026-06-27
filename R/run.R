#' Run a crawl
#'
#' Drains the request queue, fetching each request, dispatching it to the
#' matching handler and collecting pushed records, until the queue is empty or
#' the `max_requests` limit is reached.
#'
#' @param crawler A configured [Crawler].
#'
#' @return The crawler, invisibly (its dataset now holds the results).
#' @export
#'
#' @examples
#' \dontrun{
#' crawler("https://example.com") |>
#'   cr_on_html(\(ctx) ctx$push_data(list(url = ctx$request$url))) |>
#'   cr_run() |>
#'   cr_collect()
#' }
cr_run <- function(crawler) {
  check_crawler(crawler)
  crawler$run()
  invisible(crawler)
}

#' Collect crawl results
#'
#' @param crawler A [Crawler] that has been run.
#'
#' @return A tibble of all records pushed by handlers.
#' @export
cr_collect <- function(crawler) {
  check_crawler(crawler)
  crawler$dataset$collect()
}

#' @export
print.Crawler <- function(x, ...) {
  defaults <- names(x$defaults)
  defaults_txt <- if (length(defaults)) paste(defaults, collapse = ", ") else "none"
  cli::cli_text("{.cls Crawler} ({.val {x$mode}} mode)")
  cli::cli_bullets(c(
    "*" = "pending requests: {x$queue$pending_count()}",
    "*" = "handled: {x$queue$handled()} - records: {x$dataset$count()}",
    "*" = "handlers: {length(x$handlers)} labelled - defaults: {defaults_txt}"
  ))
  invisible(x)
}
