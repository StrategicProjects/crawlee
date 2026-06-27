# Shared HTTP helpers used by the discovery verbs (sitemap, RSS) and the
# robots.txt machinery. The crawl engine itself fetches via the Crawler's
# private `fetch()` method; these helpers are for one-off, configuration-time
# requests.

#' Perform a simple GET request
#'
#' @param url URL to fetch.
#' @param user_agent User-agent string.
#' @param timeout Timeout in seconds.
#' @param max_tries Maximum attempts (with backoff) on transient failures.
#'
#' @return An `httr2` response.
#' @keywords internal
#' @noRd
cr_http_get <- function(url, user_agent = NULL, timeout = 30, max_tries = 2L) {
  httr2::request(url) |>
    httr2::req_user_agent(user_agent %||% "crawlee-R") |>
    httr2::req_timeout(timeout) |>
    httr2::req_retry(max_tries = max_tries) |>
    httr2::req_perform()
}

#' Extract the HTTP status from a parallel-fetch result
#'
#' `httr2::req_perform_parallel(on_error = "continue")` returns either an
#' `httr2_response` or an error condition (HTTP errors carry the response in
#' `$resp`; transport errors carry none).
#'
#' @param resp A result element.
#'
#' @return The integer status, or `NA_integer_` for a transport-level failure.
#' @keywords internal
#' @noRd
result_status <- function(resp) {
  if (inherits(resp, "httr2_response")) {
    return(httr2::resp_status(resp))
  }
  tryCatch(httr2::resp_status(resp$resp), error = function(e) NA_integer_)
}

#' Whether a batch of statuses signals back-pressure (should scale down)
#'
#' @param statuses Integer vector of statuses (`NA` = transport failure).
#'
#' @return `TRUE` if any status indicates overload / rate-limiting / failure.
#' @keywords internal
#' @noRd
is_backpressure <- function(statuses) {
  any(is.na(statuses)) || any(statuses %in% c(429L, 500L, 502L, 503L, 504L))
}

#' Additive-increase / multiplicative-decrease step for autoscaling
#'
#' @param conc Current concurrency.
#' @param backpressure Whether the last batch signalled back-pressure.
#' @param lo,hi Concurrency bounds.
#'
#' @return The next concurrency, clamped to `[lo, hi]`.
#' @keywords internal
#' @noRd
autoscale_next <- function(conc, backpressure, lo, hi) {
  nxt <- if (backpressure) conc %/% 2L else conc + 1L
  max(lo, min(hi, nxt))
}

#' Classify response content into a handler kind
#'
#' @param content_type The response `Content-Type` (may be empty).
#' @param url The request URL (used as a fallback, e.g. `.pdf` extension).
#'
#' @return One of `"pdf"`, `"html"`, `"other"`.
#' @keywords internal
#' @noRd
classify_content <- function(content_type, url) {
  ct <- tolower(content_type %||% "")
  if (grepl("pdf", ct) || grepl("\\.pdf($|\\?|#)", tolower(url))) {
    return("pdf")
  }
  if (grepl("html|xml", ct)) {
    return("html")
  }
  "other"
}

#' Read an XML document from a response, transparently decompressing gzip
#'
#' Many large sitemaps are served as gzipped `.xml.gz`. `httr2` only
#' auto-decompresses transfer-level gzip, so we detect the gzip magic bytes
#' and decompress the body when needed.
#'
#' @param resp An `httr2` response.
#'
#' @return An `xml_document`.
#' @keywords internal
#' @noRd
resp_read_xml <- function(resp) {
  raw <- httr2::resp_body_raw(resp)
  if (length(raw) >= 2L && raw[1] == as.raw(0x1f) && raw[2] == as.raw(0x8b)) {
    raw <- memDecompress(raw, type = "gzip")
  }
  xml2::read_xml(raw)
}
