#' Normalise a URL into a canonical form
#'
#' Produces a canonical representation of a URL used as the deduplication key
#' (`unique_key`) of a request. Normalisation lower-cases the scheme and host,
#' removes a trailing slash from the path, drops default ports and sorts the
#' query parameters so that semantically identical URLs collapse to the same
#' key.
#'
#' @param url A character vector of URLs.
#'
#' @return A character vector of normalised URLs.
#' @export
#'
#' @examples
#' cr_normalize_url("HTTPS://Example.com:443/a/?b=2&a=1")
cr_normalize_url <- function(url) {
  vapply(url, function(u) {
    if (is.na(u) || !nzchar(u)) {
      return(NA_character_)
    }
    parsed <- xml2::url_parse(u)
    scheme <- tolower(parsed$scheme)
    host <- tolower(parsed$server)
    port <- parsed$port
    if (!is.na(port) && nzchar(port)) {
      default <- (scheme == "http" && port == "80") ||
        (scheme == "https" && port == "443")
      port <- if (default) "" else paste0(":", port)
    } else {
      port <- ""
    }
    path <- parsed$path
    if (!nzchar(path)) {
      path <- "/"
    }
    if (nchar(path) > 1) {
      path <- sub("/+$", "", path)
    }
    query <- parsed$query
    if (!is.na(query) && nzchar(query)) {
      parts <- strsplit(query, "&", fixed = TRUE)[[1]]
      query <- paste0("?", paste(sort(parts), collapse = "&"))
    } else {
      query <- ""
    }
    paste0(scheme, "://", host, port, path, query)
  }, character(1), USE.NAMES = FALSE)
}

#' Convert a glob pattern into a regular expression
#'
#' @param glob A character vector of glob patterns (`*` matches any run of
#'   characters, `?` matches a single character).
#'
#' @return A character vector of anchored regular expressions.
#' @keywords internal
#' @noRd
glob_to_regex <- function(glob) {
  out <- gsub("([.\\+(){}^$|\\[\\]])", "\\\\\\1", glob, perl = TRUE)
  out <- gsub("\\*", ".*", out)
  out <- gsub("\\?", ".", out)
  paste0("^", out, "$")
}

#' Test whether a URL matches include/exclude glob patterns
#'
#' @param url Character vector of URLs to test.
#' @param include,exclude Character vectors of glob patterns. `include = NULL`
#'   accepts everything; any match in `exclude` rejects the URL.
#'
#' @return A logical vector.
#' @keywords internal
#' @noRd
url_matches <- function(url, include = NULL, exclude = NULL) {
  keep <- rep(TRUE, length(url))
  if (!is.null(include) && length(include)) {
    rx <- glob_to_regex(include)
    keep <- vapply(url, function(u) {
      any(grepl(paste(rx, collapse = "|"), u, perl = TRUE))
    }, logical(1), USE.NAMES = FALSE)
  }
  if (!is.null(exclude) && length(exclude)) {
    rx <- glob_to_regex(exclude)
    drop <- vapply(url, function(u) {
      any(grepl(paste(rx, collapse = "|"), u, perl = TRUE))
    }, logical(1), USE.NAMES = FALSE)
    keep <- keep & !drop
  }
  keep
}

#' Extract the host of a URL
#'
#' @param url A character vector of URLs.
#'
#' @return A character vector of host names.
#' @keywords internal
#' @noRd
url_host <- function(url) {
  vapply(url, function(u) tolower(xml2::url_parse(u)$server),
    character(1),
    USE.NAMES = FALSE
  )
}
