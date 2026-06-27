#' Parse a sitemap XML document
#'
#' Handles both a `<sitemapindex>` (a list of child sitemaps) and a `<urlset>`
#' (a list of page URLs). Namespaces are stripped so the same XPath works
#' regardless of the declared sitemap schema.
#'
#' @param doc An `xml_document`.
#'
#' @return A list with `type` (`"index"` or `"urlset"`), `urls`, and (for a
#'   urlset) `lastmod`.
#' @keywords internal
#' @noRd
parse_sitemap <- function(doc) {
  doc <- xml2::xml_ns_strip(doc)
  root <- xml2::xml_name(xml2::xml_root(doc))
  if (identical(root, "sitemapindex")) {
    locs <- xml2::xml_text(xml2::xml_find_all(doc, "//sitemap/loc"))
    return(list(type = "index", urls = trimws(locs)))
  }
  nodes <- xml2::xml_find_all(doc, "//url")
  list(
    type = "urlset",
    urls = trimws(xml2::xml_text(xml2::xml_find_first(nodes, "./loc"))),
    lastmod = trimws(xml2::xml_text(xml2::xml_find_first(nodes, "./lastmod")))
  )
}

#' Discover URLs from a sitemap
#'
#' Fetches a sitemap (or sitemap index, recursively) and enqueues the page URLs
#' it lists. Supports gzipped sitemaps, glob filtering and a `since` filter on
#' `<lastmod>` for incremental crawls — useful for official gazettes and
#' transparency portals that publish dated sitemaps.
#'
#' @param crawler A [Crawler].
#' @param url URL of a `sitemap.xml` or sitemap index.
#' @param label Optional handler label routing the enqueued URLs.
#' @param include,exclude Optional glob patterns (see [cr_on_html()]).
#' @param since Optional date (or `YYYY-MM-DD` string); only URLs whose
#'   `<lastmod>` is on or after this date are enqueued (URLs without a
#'   `lastmod` are kept).
#' @param max Maximum number of URLs to enqueue.
#' @param max_levels Maximum recursion depth into nested sitemap indexes.
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' crawler() |>
#'   cr_on_html(\(ctx) ctx$push_data(list(url = ctx$request$url))) |>
#'   cr_from_sitemap("https://www.example.gov/sitemap.xml", since = "2026-01-01")
#' }
cr_from_sitemap <- function(crawler, url, label = NULL, include = NULL,
                            exclude = NULL, since = NULL, max = Inf,
                            max_levels = 3L) {
  check_crawler(crawler)
  ua <- crawler$options$user_agent
  to <- crawler$options$timeout
  if (!is.null(since)) since <- as.Date(since)

  pending <- list(list(url = url, level = 0L))
  seen <- character()
  added <- 0L
  while (length(pending) > 0L && added < max) {
    cur <- pending[[1L]]
    pending[[1L]] <- NULL
    if (cur$url %in% seen) next
    seen <- c(seen, cur$url)

    resp <- tryCatch(cr_http_get(cur$url, ua, to), error = function(e) NULL)
    if (is.null(resp)) {
      cli::cli_alert_warning("Could not fetch sitemap {.url {cur$url}}")
      next
    }
    doc <- tryCatch(resp_read_xml(resp), error = function(e) NULL)
    if (is.null(doc)) next
    parsed <- parse_sitemap(doc)

    if (identical(parsed$type, "index")) {
      if (cur$level < max_levels) {
        for (u in parsed$urls) {
          pending[[length(pending) + 1L]] <- list(url = u, level = cur$level + 1L)
        }
      }
      next
    }

    urls <- parsed$urls
    keep <- url_matches(urls, include = include, exclude = exclude)
    if (!is.null(since) && length(parsed$lastmod)) {
      lm <- suppressWarnings(as.Date(substr(parsed$lastmod, 1L, 10L)))
      keep <- keep & (is.na(lm) | lm >= since)
    }
    urls <- urls[keep]
    for (u in urls) {
      if (added >= max) break
      if (isTRUE(crawler$queue$add(u, label = label, depth = 0L))) {
        added <- added + 1L
      }
    }
  }
  cli::cli_alert_success("Sitemap: enqueued {added} URL{?s} from {.url {url}}")
  invisible(crawler)
}
