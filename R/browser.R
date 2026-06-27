# The fetch backends return a normalised `fetched` list so the engine and the
# handler context are agnostic to how the content was retrieved:
#   status        integer HTTP-ish status
#   content_type  character
#   html()        the (rendered) HTML/text as a string
#   raw()         the body as a raw vector
#   screenshot    function(path) or NULL (browser only)
#   response      the underlying httr2 response, or NULL (browser)

#' Build a `fetched` from an httr2 response
#' @noRd
fetched_response <- function(resp) {
  ct <- tryCatch(httr2::resp_content_type(resp), error = function(e) "")
  list(
    status = httr2::resp_status(resp),
    content_type = ct,
    html = function() httr2::resp_body_string(resp),
    raw = function() httr2::resp_body_raw(resp),
    screenshot = NULL,
    response = resp
  )
}

#' Navigate to a URL in a chromote session and capture the rendered DOM
#'
#' @param session A `chromote::ChromoteSession`.
#' @param url URL to navigate to.
#' @param wait Seconds to sleep after load (for late-rendering content).
#' @param wait_selector Optional CSS selector to wait for before capturing.
#' @param timeout Navigation timeout in seconds.
#'
#' @return A normalised `fetched` list.
#' @keywords internal
#' @noRd
browser_fetch <- function(session, url, wait = 0, wait_selector = NULL,
                          timeout = 30) {
  # Register the load-event listener *before* navigating, otherwise the event
  # may fire before we start waiting and we'd block until the timeout.
  loaded <- session$Page$loadEventFired(wait_ = FALSE)
  session$Page$navigate(url, wait_ = FALSE)
  session$wait_for(loaded)
  if (!is.null(wait_selector)) {
    browser_wait_for(session, wait_selector, timeout)
  }
  if (wait > 0) Sys.sleep(wait)
  doc <- session$DOM$getDocument()
  html <- session$DOM$getOuterHTML(nodeId = doc$root$nodeId)$outerHTML
  list(
    status = 200L,
    content_type = "text/html",
    html = function() html,
    raw = function() charToRaw(html),
    screenshot = function(path) {
      session$screenshot(filename = path)
      path
    },
    response = NULL
  )
}

#' Poll until a CSS selector is present (or the timeout elapses)
#' @noRd
browser_wait_for <- function(session, selector, timeout = 30) {
  sel_js <- paste0('"', gsub('"', '\\\\"', selector), '"')
  expr <- paste0("document.querySelector(", sel_js, ") !== null")
  deadline <- Sys.time() + timeout
  repeat {
    res <- session$Runtime$evaluate(expr)
    if (isTRUE(res$result$value)) {
      return(invisible(TRUE))
    }
    if (Sys.time() > deadline) {
      cli::cli_alert_warning("Timed out waiting for selector {.val {selector}}")
      return(invisible(FALSE))
    }
    Sys.sleep(0.1)
  }
}

#' Use the headless-browser fetch backend
#'
#' Switches the crawler to render pages with a headless Chrome/Chromium via the
#' \pkg{chromote} package — for JavaScript-heavy sites where the plain HTTP
#' backend would see an empty shell. Handlers work exactly as with
#' [cr_use_http()] (`ctx$page`, `enqueue_links()`, ...), and additionally gain
#' `ctx$screenshot()`.
#'
#' Requires \pkg{chromote} and a Chrome/Chromium installation. PDF extraction
#' still requires the HTTP backend.
#'
#' @param crawler A [Crawler].
#' @param wait Seconds to wait after page load before capturing the DOM
#'   (useful for late-rendering content).
#' @param wait_selector Optional CSS selector to wait for before capturing.
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' crawler("https://example.com") |>
#'   cr_use_browser(wait_selector = ".results") |>
#'   cr_on_html(\(ctx) {
#'     ctx$push_data(list(url = ctx$request$url))
#'     ctx$screenshot()
#'   }) |>
#'   cr_run()
#' }
cr_use_browser <- function(crawler, wait = 0, wait_selector = NULL) {
  check_crawler(crawler)
  crawler$mode <- "browser"
  crawler$set_options(browser_wait = wait, browser_wait_selector = wait_selector)
  invisible(crawler)
}
