# RAG helpers: split crawled text into chunks, attach embeddings via a
# user-supplied (provider-agnostic) function, and export to retrieval-friendly
# formats. These operate on plain tibbles, so they compose after cr_collect().

#' Split a single string into character windows
#' @noRd
chunk_chars <- function(text, size, overlap) {
  text <- trimws(text)
  n <- nchar(text)
  if (n == 0L) {
    return(character(0))
  }
  if (n <= size) {
    return(text)
  }
  step <- max(1L, size - overlap)
  starts <- seq.int(1L, n, by = step)
  out <- character(0)
  for (s in starts) {
    e <- min(s + size - 1L, n)
    out <- c(out, substr(text, s, e))
    if (e == n) break
  }
  out
}

#' Split a single string into word windows
#' @noRd
chunk_words <- function(text, size, overlap) {
  w <- strsplit(trimws(text), "\\s+")[[1]]
  w <- w[nzchar(w)]
  n <- length(w)
  if (n == 0L) {
    return(character(0))
  }
  if (n <= size) {
    return(paste(w, collapse = " "))
  }
  step <- max(1L, size - overlap)
  starts <- seq.int(1L, n, by = step)
  out <- character(0)
  for (s in starts) {
    e <- min(s + size - 1L, n)
    out <- c(out, paste(w[s:e], collapse = " "))
    if (e == n) break
  }
  out
}

#' Chunk text for retrieval-augmented generation
#'
#' Splits documents into overlapping chunks suitable for embedding and
#' retrieval. Works on a character vector (one element per document) or on a
#' data frame, in which case the chunked column is replaced by `text` and all
#' other columns are carried along as per-chunk metadata.
#'
#' @param data A character vector or a data frame (e.g. the result of
#'   [cr_collect()]).
#' @param text When `data` is a data frame, the (unquoted) column holding the
#'   text to chunk.
#' @param size Target chunk size, in characters (`by = "char"`) or words
#'   (`by = "word"`).
#' @param overlap Overlap between consecutive chunks, in the same unit as
#'   `size`. Must be smaller than `size`.
#' @param by `"char"` (default) or `"word"`.
#'
#' @return A tibble with columns `doc_id`, `chunk_id` (within document),
#'   `chunk` (global index), `text`, `n_chars`, plus any carried metadata.
#' @export
#'
#' @examples
#' cr_chunk(c("um texto longo ...", "outro documento ..."),
#'          size = 10, overlap = 2, by = "word")
cr_chunk <- function(data, text = NULL, size = 1000L, overlap = 200L,
                     by = c("char", "word")) {
  by <- match.arg(by)
  if (overlap >= size) {
    cli::cli_abort("{.arg overlap} ({overlap}) must be smaller than {.arg size} ({size}).")
  }
  if (is.character(data)) {
    docs <- data
    meta <- NULL
  } else if (is.data.frame(data)) {
    q <- rlang::enquo(text)
    if (rlang::quo_is_null(q)) {
      cli::cli_abort("Provide {.arg text}: the column to chunk.")
    }
    col <- rlang::as_name(q)
    if (!col %in% names(data)) {
      cli::cli_abort("Column {.field {col}} not found in {.arg data}.")
    }
    docs <- as.character(data[[col]])
    meta <- data[setdiff(names(data), col)]
  } else {
    cli::cli_abort("{.arg data} must be a character vector or a data frame.")
  }

  split_one <- if (by == "char") chunk_chars else chunk_words
  rows <- list()
  for (d in seq_along(docs)) {
    cs <- split_one(docs[d], size, overlap)
    if (!length(cs)) next
    base <- tibble::tibble(
      doc_id = d, chunk_id = seq_along(cs), text = cs, n_chars = nchar(cs)
    )
    if (!is.null(meta)) {
      rep_meta <- tibble::as_tibble(meta[rep(d, length(cs)), , drop = FALSE])
      base <- vctrs::vec_cbind(base, rep_meta)
    }
    rows[[length(rows) + 1L]] <- base
  }
  out <- vctrs::vec_rbind(!!!rows)
  if (nrow(out)) out$chunk <- seq_len(nrow(out))
  out
}

#' Normalise an embedding function's output into a list of numeric vectors
#' @noRd
normalize_embeddings <- function(res, k) {
  if (is.matrix(res)) {
    if (nrow(res) != k) {
      cli::cli_abort("Embedding function returned {nrow(res)} rows for {k} input{?s}.")
    }
    return(lapply(seq_len(k), function(i) as.numeric(res[i, ])))
  }
  if (is.list(res)) {
    if (length(res) != k) {
      cli::cli_abort("Embedding function returned {length(res)} vectors for {k} input{?s}.")
    }
    return(lapply(res, as.numeric))
  }
  if (is.numeric(res) && k == 1L) {
    return(list(as.numeric(res)))
  }
  cli::cli_abort("Embedding function must return a matrix or a list of numeric vectors.")
}

#' Attach embeddings to chunks
#'
#' Adds an `embedding` list-column by applying a user-supplied, provider-
#' agnostic embedding function in batches. crawlee never calls an external
#' service itself: you pass `embed_fn`, which receives a character vector and
#' returns either a numeric matrix (one row per input) or a list of numeric
#' vectors. This keeps you free to use any provider or a local model.
#'
#' @param data A data frame with a text column (e.g. from [cr_chunk()]).
#' @param embed_fn A function mapping a character vector to a numeric matrix
#'   (rows = inputs) or a list of numeric vectors.
#' @param text_col Name of the text column. Defaults to `"text"`.
#' @param batch_size Number of texts per call to `embed_fn`.
#'
#' @return `data` with an added `embedding` list-column.
#' @export
#'
#' @examples
#' chunks <- cr_chunk(c("a b c d", "e f g h"), size = 2, overlap = 0, by = "word")
#' fake_embed <- function(x) matrix(nchar(x), nrow = length(x), ncol = 1)
#' cr_embed(chunks, fake_embed)
cr_embed <- function(data, embed_fn, text_col = "text", batch_size = 32L) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  if (!is.function(embed_fn)) {
    cli::cli_abort("{.arg embed_fn} must be a function.")
  }
  texts <- as.character(data[[text_col]])
  n <- length(texts)
  embs <- vector("list", n)
  groups <- split(seq_len(n), ceiling(seq_len(n) / batch_size))
  cli::cli_progress_bar("Embedding", total = length(groups))
  for (g in groups) {
    embs[g] <- normalize_embeddings(embed_fn(texts[g]), length(g))
    cli::cli_progress_update()
  }
  cli::cli_progress_done()
  data$embedding <- embs
  tibble::as_tibble(data)
}

#' Flatten an embedding list-column to a JSON-ish string (for flat formats)
#' @noRd
flatten_embeddings <- function(data) {
  if ("embedding" %in% names(data) && is.list(data$embedding)) {
    data$embedding <- vapply(
      data$embedding,
      function(v) paste0("[", paste(v, collapse = ","), "]"),
      character(1)
    )
  }
  data
}

#' Export chunks (and embeddings) for retrieval
#'
#' Writes a chunk table to a retrieval-friendly format. `parquet` and `jsonl`
#' preserve the `embedding` list-column natively; `csv` and `duckdb` serialise
#' it to a `[...]` string for portability.
#'
#' @param data A data frame (typically from [cr_chunk()] / [cr_embed()]).
#' @param path Output file (or database) path.
#' @param format One of `"parquet"`, `"jsonl"`, `"csv"`, `"duckdb"`.
#' @param table Table name for the `"duckdb"` format.
#'
#' @return `path`, invisibly.
#' @export
cr_export <- function(data, path, format = c("parquet", "jsonl", "csv", "duckdb"),
                      table = "chunks") {
  format <- match.arg(format)
  switch(format,
    parquet = {
      rlang::check_installed("arrow", "to export Parquet.")
      arrow::write_parquet(data, path)
    },
    jsonl = {
      rlang::check_installed("jsonlite", "to export JSONL.")
      lines <- vapply(seq_len(nrow(data)), function(i) {
        row <- lapply(data[i, , drop = FALSE], function(x) if (is.list(x)) x[[1]] else x)
        jsonlite::toJSON(row, auto_unbox = TRUE, digits = NA)
      }, character(1))
      writeLines(lines, path)
    },
    csv = {
      utils::write.csv(flatten_embeddings(data), path, row.names = FALSE)
    },
    duckdb = {
      rlang::check_installed(c("DBI", "duckdb"), "to export to DuckDB.")
      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      DBI::dbWriteTable(con, table, flatten_embeddings(data), overwrite = TRUE)
    }
  )
  cli::cli_alert_success("Exported {nrow(data)} chunk{?s} to {.path {path}} ({format})")
  invisible(path)
}
