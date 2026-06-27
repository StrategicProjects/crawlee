test_that("RequestQueue save/restore round-trips state", {
  path <- file.path(tempdir(), "q-roundtrip.rds")
  unlink(path)
  q <- RequestQueue$new(path)
  q$add("https://x.com/a")
  q$add("https://x.com/b")
  q$pop()
  q$mark_handled()
  expect_true(q$save())

  q2 <- RequestQueue$new(path)
  expect_true(q2$has_saved_state())
  q2$restore()
  expect_equal(q2$pending_count(), 1L)
  expect_equal(q2$handled(), 1L)
  # seen set preserved -> the popped URL is not re-added
  expect_false(q2$add("https://x.com/a"))
})

test_that("jsonl dataset persists and resumes", {
  skip_if_not_installed("jsonlite")
  path <- file.path(tempdir(), "ds-resume.jsonl")
  unlink(path)
  d1 <- Dataset$new("jsonl", path)
  d1$push(list(a = 1, b = "x"))
  d1$push(list(a = 2, b = "y"))
  expect_equal(d1$count(), 2L)

  d2 <- Dataset$new("jsonl", path) # reopen -> resumes count
  expect_equal(d2$count(), 2L)
  d2$push(list(a = 3, b = "z"))
  out <- d2$collect()
  expect_equal(nrow(out), 3L)
  expect_equal(out$a, c(1, 2, 3))
})

test_that("duckdb dataset persists, resumes and collects", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")
  path <- file.path(tempdir(), "ds-resume.duckdb")
  unlink(path)
  d <- Dataset$new("duckdb", path)
  d$push(tibble::tibble(a = 1L, b = "x"))
  d$push(tibble::tibble(a = 2L, b = "y"))
  expect_equal(d$count(), 2L)
  expect_equal(nrow(d$collect()), 2L)
  d$close()

  d2 <- Dataset$new("duckdb", path)
  expect_equal(d2$count(), 2L)
  d2$close()
})

test_that("Dataset requires a path for persistent backends", {
  expect_error(Dataset$new("jsonl"), "requires a")
})

test_that("cr_persist resumes a saved queue", {
  dir <- file.path(tempdir(), "run-resume")
  unlink(dir, recursive = TRUE)
  dir.create(dir)
  q <- RequestQueue$new(file.path(dir, "queue.rds"))
  q$add("https://x.com/a")
  q$add("https://x.com/b")
  q$pop()
  q$mark_handled()
  q$save()

  cr <- crawler() |> cr_persist(dir, dataset = "memory")
  expect_equal(cr$queue$pending_count(), 1L)
  expect_equal(cr$queue$handled(), 1L)
})

test_that("cr_persist keeps start_urls on a fresh run", {
  dir <- file.path(tempdir(), "run-fresh")
  unlink(dir, recursive = TRUE)
  cr <- crawler("https://x.com/seed") |> cr_persist(dir, dataset = "memory")
  expect_equal(cr$queue$pending_count(), 1L)
})

test_that("running a persisted crawl writes queue and manifest", {
  dir <- file.path(tempdir(), "run-manifest")
  unlink(dir, recursive = TRUE)
  # empty queue -> run does no network I/O but still checkpoints on exit
  crawler() |>
    cr_persist(dir, dataset = "jsonl") |>
    cr_run()
  expect_true(file.exists(file.path(dir, "queue.rds")))
  expect_true(file.exists(file.path(dir, "manifest.rds")))
  man <- readRDS(file.path(dir, "manifest.rds"))
  expect_equal(man$package, "crawlee")
})
