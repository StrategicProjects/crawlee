#' Dataset
#'
#' An append-only structured store for the records produced by handlers via
#' `ctx$push_data()`. Records accumulate in memory and can be collected as a
#' single tibble with [cr_collect()]. Persistent backends (DuckDB, Parquet) are
#' planned for a future release; the `backend` argument is accepted now so that
#' calling code remains forward-compatible.
#'
#' @export
Dataset <- R6::R6Class(
  "Dataset",
  public = list(
    #' @field backend Name of the storage backend.
    backend = "memory",
    #' @field path Optional path for persistent backends.
    path = NULL,

    #' @description Create a dataset.
    #' @param backend One of `"memory"`, `"duckdb"`, `"parquet"`.
    #' @param path Optional path for persistent backends.
    initialize = function(backend = "memory", path = NULL) {
      self$backend <- match.arg(backend, c("memory", "duckdb", "parquet"))
      self$path <- path
      private$records <- list()
    },

    #' @description Append one or more records.
    #' @param data A data frame / tibble or a named list (coerced to one row).
    push = function(data) {
      if (is.null(data)) {
        return(invisible(self))
      }
      if (!is.data.frame(data)) {
        data <- tibble::as_tibble(data)
      }
      private$records[[length(private$records) + 1L]] <- tibble::as_tibble(data)
      invisible(self)
    },

    #' @description Collect all records as a single tibble.
    #' @return A tibble (empty if nothing was pushed).
    collect = function() {
      if (length(private$records) == 0L) {
        return(tibble::tibble())
      }
      vctrs::vec_rbind(!!!private$records)
    },

    #' @description Number of records (rows) stored.
    #' @return Integer scalar.
    count = function() {
      if (length(private$records) == 0L) {
        return(0L)
      }
      sum(vapply(private$records, nrow, integer(1)))
    }
  ),
  private = list(
    records = NULL
  )
)
