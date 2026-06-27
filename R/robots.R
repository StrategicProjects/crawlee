# A small, dependency-free robots.txt parser and matcher. It implements the
# common subset of the Robots Exclusion Protocol: User-agent grouping,
# Allow/Disallow with `*` wildcards and `$` end-anchors, longest-match wins
# (Allow breaking ties), and Crawl-delay.

#' Parse robots.txt text into records
#'
#' @param text The contents of a robots.txt file.
#'
#' @return A list of records, each a list with `agents`, `disallow`, `allow`
#'   and `crawl_delay`.
#' @keywords internal
#' @noRd
parse_robots <- function(text) {
  if (!nzchar(text)) {
    return(list())
  }
  lines <- strsplit(text, "[\r\n]+")[[1]]
  records <- list()
  cur <- NULL
  reading_rules <- FALSE
  push_cur <- function() {
    if (!is.null(cur)) records[[length(records) + 1L]] <<- cur
  }
  for (raw in lines) {
    line <- trimws(sub("#.*$", "", raw))
    if (!nzchar(line)) next
    kv <- regmatches(line, regexec("^([^:]+):[ \t]*(.*)$", line))[[1]]
    if (length(kv) != 3L) next
    field <- tolower(trimws(kv[2]))
    value <- trimws(kv[3])
    if (field == "user-agent") {
      if (reading_rules || is.null(cur)) {
        push_cur()
        cur <- list(
          agents = character(), disallow = character(),
          allow = character(), crawl_delay = NA_real_
        )
        reading_rules <- FALSE
      }
      cur$agents <- c(cur$agents, tolower(value))
    } else if (is.null(cur)) {
      next
    } else if (field == "disallow") {
      reading_rules <- TRUE
      cur$disallow <- c(cur$disallow, value)
    } else if (field == "allow") {
      reading_rules <- TRUE
      cur$allow <- c(cur$allow, value)
    } else if (field == "crawl-delay") {
      reading_rules <- TRUE
      cd <- suppressWarnings(as.numeric(value))
      if (!is.na(cd)) cur$crawl_delay <- cd
    }
  }
  push_cur()
  records
}

#' Select the robots record applying to a user-agent
#'
#' Picks the group with the most specific matching agent token, falling back to
#' the `*` group.
#'
#' @param records Output of `parse_robots()`.
#' @param ua The crawler's user-agent string.
#'
#' @return A single record, or `NULL` if nothing applies.
#' @keywords internal
#' @noRd
robots_select <- function(records, ua) {
  ua <- tolower(ua)
  best <- NULL
  best_len <- -1L
  star <- NULL
  for (r in records) {
    for (a in r$agents) {
      if (a == "*") {
        star <- r
      } else if (nzchar(a) && grepl(a, ua, fixed = TRUE) && nchar(a) > best_len) {
        best <- r
        best_len <- nchar(a)
      }
    }
  }
  best %||% star
}

#' Does a single robots pattern match a path?
#' @noRd
robots_match <- function(pattern, path) {
  anchored_end <- grepl("\\$$", pattern)
  p <- sub("\\$$", "", pattern)
  p <- gsub("([.+?(){}\\[\\]^|\\\\])", "\\\\\\1", p, perl = TRUE)
  p <- gsub("\\*", ".*", p)
  rx <- paste0("^", p, if (anchored_end) "$" else "")
  grepl(rx, path, perl = TRUE)
}

#' Is `path` allowed for the given robots record?
#'
#' @param path The request path (with query string).
#' @param record A record from `robots_select()` (may be `NULL`).
#'
#' @return `TRUE` if allowed, `FALSE` otherwise.
#' @keywords internal
#' @noRd
robots_path_allowed <- function(path, record) {
  if (is.null(record)) {
    return(TRUE)
  }
  longest <- function(rules) {
    best <- -1L
    for (rule in rules) {
      if (!nzchar(rule)) next
      if (robots_match(rule, path)) best <- max(best, nchar(rule))
    }
    best
  }
  dl <- longest(record$disallow)
  if (dl < 0L) {
    return(TRUE)
  }
  al <- longest(record$allow)
  al >= dl
}
