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

#' Read an XML document from a response, transparently decompressing gzip
#'
#' Many governmental sitemaps are served as gzipped `.xml.gz`. `httr2` only
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
