#' Request queue
#'
#' A deduplicating, FIFO-with-priority request queue, the in-memory engine
#' behind every [crawler()]. Requests are keyed by a normalised `unique_key`
#' (see [cr_normalize_url()]) so the same URL is never enqueued twice. The
#' queue tracks which requests have been handled, which makes a crawl
#' resumable: a serialised queue can be reloaded and the crawl continued.
#'
#' This class is exported mainly for advanced use and introspection; most users
#' interact with it indirectly through the `cr_*` verbs.
#'
#' @export
RequestQueue <- R6::R6Class(
  "RequestQueue",
  public = list(
    #' @description Create a new, empty request queue.
    initialize = function() {
      private$pending <- list()
      private$seen <- new.env(parent = emptyenv())
      private$handled_count <- 0L
    },

    #' @description Add a request to the queue.
    #' @param url Character scalar URL.
    #' @param label Optional handler label routing this request.
    #' @param depth Integer crawl depth (distance from a start URL).
    #' @param user_data Optional named list carried with the request.
    #' @param method HTTP method, defaults to `"GET"`.
    #' @param force_unique If `TRUE`, skip deduplication.
    #' @return Invisibly, `TRUE` if added, `FALSE` if a duplicate.
    add = function(url, label = NULL, depth = 0L, user_data = list(),
                   method = "GET", force_unique = FALSE) {
      key <- cr_normalize_url(url)
      if (is.na(key)) {
        return(invisible(FALSE))
      }
      if (!force_unique && !is.null(private$seen[[key]])) {
        return(invisible(FALSE))
      }
      private$seen[[key]] <- TRUE
      req <- list(
        url = url,
        unique_key = key,
        label = label,
        depth = as.integer(depth),
        user_data = user_data,
        method = method,
        retry_count = 0L
      )
      private$pending[[length(private$pending) + 1L]] <- req
      invisible(TRUE)
    },

    #' @description Pop the next request from the front of the queue.
    #' @return A request list, or `NULL` when the queue is empty.
    pop = function() {
      if (length(private$pending) == 0L) {
        return(NULL)
      }
      req <- private$pending[[1L]]
      private$pending[[1L]] <- NULL
      req
    },

    #' @description Re-queue a request for another attempt, incrementing its
    #'   retry counter.
    #' @param request A request list previously obtained from `pop()`.
    reschedule = function(request) {
      request$retry_count <- request$retry_count + 1L
      private$pending[[length(private$pending) + 1L]] <- request
      invisible(TRUE)
    },

    #' @description Mark a request as successfully handled.
    mark_handled = function() {
      private$handled_count <- private$handled_count + 1L
      invisible(TRUE)
    },

    #' @description Number of requests waiting to be processed.
    #' @return Integer scalar.
    pending_count = function() length(private$pending),

    #' @description Number of requests handled so far.
    #' @return Integer scalar.
    handled = function() private$handled_count,

    #' @description Whether the queue has no pending requests.
    #' @return Logical scalar.
    is_empty = function() length(private$pending) == 0L
  ),
  private = list(
    pending = NULL,
    seen = NULL,
    handled_count = 0L
  )
)
