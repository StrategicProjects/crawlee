test_that("cr_chunk splits a character vector by word with overlap", {
  out <- cr_chunk("a b c d e f", size = 3, overlap = 1, by = "word")
  expect_s3_class(out, "tbl_df")
  expect_equal(out$text, c("a b c", "c d e", "e f"))
  expect_equal(out$doc_id, c(1L, 1L, 1L))
  expect_equal(out$chunk, 1:3)
})

test_that("cr_chunk by char respects size", {
  out <- cr_chunk(strrep("x", 25), size = 10, overlap = 0, by = "char")
  expect_equal(nchar(out$text), c(10L, 10L, 5L))
})

test_that("cr_chunk on a data frame carries metadata", {
  df <- tibble::tibble(url = c("u1", "u2"), body = c("a b c d", "e f"))
  out <- cr_chunk(df, text = body, size = 2, overlap = 0, by = "word")
  expect_true(all(c("url", "doc_id", "chunk_id", "text") %in% names(out)))
  expect_false("body" %in% names(out))
  expect_equal(out$url, c("u1", "u1", "u2"))
})

test_that("cr_chunk rejects overlap >= size", {
  expect_error(cr_chunk("x", size = 5, overlap = 5), "must be smaller")
})

test_that("cr_embed attaches an embedding list-column", {
  chunks <- cr_chunk(c("a b", "c d e"), size = 2, overlap = 0, by = "word")
  fake <- function(x) matrix(nchar(x), nrow = length(x), ncol = 1)
  out <- cr_embed(chunks, fake, batch_size = 1)
  expect_true(is.list(out$embedding))
  expect_equal(length(out$embedding), nrow(out))
  expect_true(all(vapply(out$embedding, is.numeric, logical(1))))
})

test_that("cr_embed errors on size mismatch", {
  chunks <- cr_chunk("a b c d", size = 2, overlap = 0, by = "word")
  bad <- function(x) matrix(0, nrow = length(x) + 1, ncol = 1)
  expect_error(cr_embed(chunks, bad), "rows for")
})

test_that("cr_export writes jsonl with embeddings preserved", {
  skip_if_not_installed("jsonlite")
  chunks <- cr_chunk(c("a b", "c d"), size = 2, overlap = 0, by = "word")
  out <- cr_embed(chunks, function(x) matrix(1, nrow = length(x), ncol = 3))
  path <- file.path(tempdir(), "chunks.jsonl")
  cr_export(out, path, format = "jsonl")
  lines <- readLines(path)
  expect_equal(length(lines), nrow(out))
  parsed <- jsonlite::fromJSON(lines[1])
  expect_length(parsed$embedding, 3L)
})

test_that("cr_export csv serialises embeddings to a string", {
  chunks <- cr_chunk("a b c d", size = 2, overlap = 0, by = "word")
  out <- cr_embed(chunks, function(x) matrix(0.5, nrow = length(x), ncol = 2))
  path <- file.path(tempdir(), "chunks.csv")
  cr_export(out, path, format = "csv")
  back <- utils::read.csv(path)
  expect_match(back$embedding[1], "^\\[.*\\]$")
})
