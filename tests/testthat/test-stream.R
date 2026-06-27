test_that("cr_stream sets streaming options", {
  cr <- crawler("https://x.com") |> cr_stream(concurrency = 10)
  expect_true(cr$options$parallel)
  expect_true(cr$options$stream)
  expect_equal(cr$options$concurrency, 10L)
})

test_that("cr_stream validates concurrency", {
  expect_error(crawler("https://x.com") |> cr_stream(concurrency = 0), "positive")
})

test_that("streaming crawl fetches multiple URLs", {
  skip_on_cran()
  skip_on_ci()
  skip_if_offline()
  skip_if_not_installed("promises")
  skip_if_not_installed("later")

  out <- crawler(c(
    "https://example.com", "https://example.org", "https://example.net"
  )) |>
    cr_options(respect_robots = FALSE) |>
    cr_stream(concurrency = 3) |>
    cr_on_html(function(ctx) {
      ctx$push_data(list(url = ctx$request$url, status = ctx$status))
    }) |>
    cr_run() |>
    cr_collect()

  expect_equal(nrow(out), 3L)
  expect_true(all(out$status == 200))
})
