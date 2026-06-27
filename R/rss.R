#' Parse an RSS or Atom feed document
#'
#' Detects RSS (`<item><link>`) and Atom (`<entry><link href>`) feeds and
#' extracts item links together with their titles and publication dates.
#'
#' @param doc An `xml_document`.
#'
#' @return A list with `urls`, `titles` and `dates` (character vectors of equal
#'   length).
#' @keywords internal
#' @noRd
parse_feed <- function(doc) {
  doc <- xml2::xml_ns_strip(doc)
  items <- xml2::xml_find_all(doc, "//item")
  if (length(items) > 0L) {
    return(list(
      urls = trimws(xml2::xml_text(xml2::xml_find_first(items, "./link"))),
      titles = trimws(xml2::xml_text(xml2::xml_find_first(items, "./title"))),
      dates = trimws(xml2::xml_text(xml2::xml_find_first(items, "./pubDate")))
    ))
  }
  entries <- xml2::xml_find_all(doc, "//entry")
  if (length(entries) > 0L) {
    links <- xml2::xml_find_first(
      entries, "./link[not(@rel) or @rel='alternate']"
    )
    return(list(
      urls = trimws(xml2::xml_attr(links, "href")),
      titles = trimws(xml2::xml_text(xml2::xml_find_first(entries, "./title"))),
      dates = trimws(xml2::xml_text(xml2::xml_find_first(entries, "./updated")))
    ))
  }
  list(urls = character(), titles = character(), dates = character())
}

#' Discover URLs from an RSS or Atom feed
#'
#' Fetches a feed and enqueues each item's link. The item title and date are
#' attached to the request's `user_data` (available to handlers as
#' `ctx$request$user_data`), so feed metadata can be carried into the dataset.
#'
#' @param crawler A [Crawler].
#' @param url URL of an RSS or Atom feed.
#' @param label Optional handler label routing the enqueued URLs.
#' @param include,exclude Optional glob patterns (see [cr_on_html()]).
#' @param max Maximum number of items to enqueue.
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' crawler() |>
#'   cr_on_html(\(ctx) ctx$push_data(list(
#'     url = ctx$request$url, titulo = ctx$request$user_data$title
#'   ))) |>
#'   cr_from_rss("https://www.example.gov/noticias/rss")
#' }
cr_from_rss <- function(crawler, url, label = NULL, include = NULL,
                        exclude = NULL, max = Inf) {
  check_crawler(crawler)
  resp <- tryCatch(
    cr_http_get(url, crawler$options$user_agent, crawler$options$timeout),
    error = function(e) NULL
  )
  if (is.null(resp)) {
    cli::cli_alert_warning("Could not fetch feed {.url {url}}")
    return(invisible(crawler))
  }
  doc <- tryCatch(resp_read_xml(resp), error = function(e) NULL)
  if (is.null(doc)) {
    cli::cli_alert_warning("Could not parse feed {.url {url}}")
    return(invisible(crawler))
  }
  feed <- parse_feed(doc)
  urls <- feed$urls
  keep <- nzchar(urls) & url_matches(urls, include = include, exclude = exclude)
  idx <- which(keep)
  added <- 0L
  for (i in idx) {
    if (added >= max) break
    ud <- list(title = feed$titles[i], date = feed$dates[i], source_feed = url)
    if (isTRUE(crawler$queue$add(urls[i], label = label, depth = 0L,
      user_data = ud))) {
      added <- added + 1L
    }
  }
  cli::cli_alert_success("Feed: enqueued {added} item{?s} from {.url {url}}")
  invisible(crawler)
}
