#' Dataset
#'
#' An append-only structured store for the records produced by handlers via
#' `ctx$push_data()`. Three backends are available:
#'
#' * `"memory"` (default): records accumulate in memory.
#' * `"jsonl"`: each record is appended as a line of JSON to a file —
#'   schema-flexible, append-only and resumable across runs.
#' * `"duckdb"`: records are appended to a table in a DuckDB database, ready for
#'   SQL analysis.
#'
#' Collect everything as a single tibble with [cr_collect()].
#'
#' @export
Dataset <- R6::R6Class(
  "Dataset",
  public = list(
    #' @field backend Name of the storage backend.
    backend = "memory",
    #' @field path Path for persistent backends.
    path = NULL,

    #' @description Create a dataset.
    #' @param backend One of `"memory"`, `"jsonl"`, `"duckdb"`.
    #' @param path File (jsonl) or database (duckdb) path; required for the
    #'   persistent backends.
    #' @param table Table name for the `"duckdb"` backend.
    initialize = function(backend = "memory", path = NULL, table = "dataset") {
      self$backend <- match.arg(backend, c("memory", "jsonl", "duckdb"))
      self$path <- path
      private$records <- list()
      private$n <- 0L
      private$table <- table
      if (self$backend != "memory" && is.null(path)) {
        cli::cli_abort("Backend {.val {self$backend}} requires a {.arg path}.")
      }
      if (self$backend == "jsonl") {
        rlang::check_installed("jsonlite", "for the jsonl dataset backend.")
        if (file.exists(path)) private$n <- length(readLines(path, warn = FALSE))
      }
      if (self$backend == "duckdb") {
        rlang::check_installed(c("DBI", "duckdb"), "for the duckdb dataset backend.")
        private$con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
        if (DBI::dbExistsTable(private$con, private$table)) {
          private$n <- DBI::dbGetQuery(
            private$con, sprintf("SELECT COUNT(*) AS n FROM %s", private$table)
          )$n
        }
      }
    },

    #' @description Append one or more records.
    #' @param data A data frame / tibble or a named list (coerced to one row).
    push = function(data) {
      if (is.null(data)) {
        return(invisible(self))
      }
      if (!is.data.frame(data)) {
        data <- tibble::as_tibble(data)
      } else {
        data <- tibble::as_tibble(data)
      }
      switch(self$backend,
        memory = {
          private$records[[length(private$records) + 1L]] <- data
        },
        jsonl = {
          lines <- vapply(seq_len(nrow(data)), function(i) {
            jsonlite::toJSON(as.list(data[i, , drop = FALSE]), auto_unbox = TRUE)
          }, character(1))
          con <- file(self$path, open = "a")
          on.exit(close(con), add = TRUE)
          writeLines(lines, con)
        },
        duckdb = {
          DBI::dbWriteTable(private$con, private$table, data, append = TRUE)
        }
      )
      private$n <- private$n + nrow(data)
      invisible(self)
    },

    #' @description Collect all records as a single tibble.
    #' @return A tibble (empty if nothing was stored).
    collect = function() {
      switch(self$backend,
        memory = {
          if (length(private$records) == 0L) {
            return(tibble::tibble())
          }
          vctrs::vec_rbind(!!!private$records)
        },
        jsonl = {
          if (!file.exists(self$path)) {
            return(tibble::tibble())
          }
          lines <- readLines(self$path, warn = FALSE)
          lines <- lines[nzchar(lines)]
          if (!length(lines)) {
            return(tibble::tibble())
          }
          rows <- lapply(lines, function(l) {
            tibble::as_tibble(jsonlite::fromJSON(l))
          })
          vctrs::vec_rbind(!!!rows)
        },
        duckdb = {
          if (!DBI::dbExistsTable(private$con, private$table)) {
            return(tibble::tibble())
          }
          tibble::as_tibble(DBI::dbReadTable(private$con, private$table))
        }
      )
    },

    #' @description Number of records (rows) stored.
    #' @return Integer scalar.
    count = function() private$n,

    #' @description Close any open backend resources (e.g. the DuckDB
    #'   connection). Safe to call multiple times.
    close = function() {
      if (!is.null(private$con)) {
        try(DBI::dbDisconnect(private$con, shutdown = TRUE), silent = TRUE)
        private$con <- NULL
      }
      invisible(self)
    }
  ),
  private = list(
    records = NULL,
    n = 0L,
    table = "dataset",
    con = NULL
  )
)
