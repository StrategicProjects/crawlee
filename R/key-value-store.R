#' Turn an arbitrary key into a safe file name
#' @noRd
kv_safe_key <- function(key) {
  k <- gsub("[^A-Za-z0-9._-]+", "_", key)
  k <- sub("^_+", "", k)
  if (nchar(k) > 180L) {
    k <- paste0(substr(k, 1L, 150L), "-", substr(k, nchar(k) - 24L, nchar(k)))
  }
  if (!nzchar(k)) "index" else k
}

#' Key-value store
#'
#' A simple on-disk store for binary or text content keyed by an arbitrary
#' string (typically a URL). It backs `ctx$save_body()`, letting handlers
#' persist raw responses — PDFs, images, snapshots — alongside the structured
#' [Dataset]. Keys are sanitised into safe file names.
#'
#' @export
KeyValueStore <- R6::R6Class(
  "KeyValueStore",
  public = list(
    #' @field dir Directory backing the store.
    dir = NULL,

    #' @description Create a store.
    #' @param dir Target directory; defaults to a `crawlee-store` folder in the
    #'   session's temporary directory. Created if it does not exist.
    initialize = function(dir = NULL) {
      self$dir <- dir %||% file.path(tempdir(), "crawlee-store")
      dir.create(self$dir, recursive = TRUE, showWarnings = FALSE)
    },

    #' @description Store raw bytes under `key`.
    #' @param key Character key.
    #' @param raw A raw vector.
    #' @return The file path, invisibly.
    set_raw = function(key, raw) {
      path <- self$path_of(key)
      writeBin(raw, path)
      invisible(path)
    },

    #' @description Store text under `key`.
    #' @param key Character key.
    #' @param text A character vector (written one element per line).
    #' @return The file path, invisibly.
    set_text = function(key, text) {
      path <- self$path_of(key)
      writeLines(text, path)
      invisible(path)
    },

    #' @description Retrieve raw bytes for `key`, or `NULL` if absent.
    #' @param key Character key.
    get_raw = function(key) {
      path <- self$path_of(key)
      if (!file.exists(path)) {
        return(NULL)
      }
      readBin(path, "raw", n = file.info(path)$size)
    },

    #' @description Full path for `key` (whether or not it exists).
    #' @param key Character key.
    path_of = function(key) {
      file.path(self$dir, kv_safe_key(key))
    },

    #' @description List stored keys (file names).
    keys = function() {
      list.files(self$dir)
    }
  )
)
