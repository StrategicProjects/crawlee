test_that("cr_parallel sets parallel options", {
  cr <- crawler("https://x.com") |> cr_parallel(concurrency = 6)
  expect_true(cr$options$parallel)
  expect_equal(cr$options$concurrency, 6L)
})

test_that("cr_parallel validates concurrency", {
  expect_error(crawler("https://x.com") |> cr_parallel(concurrency = 0), "positive")
})

test_that("parallel crawl fetches multiple URLs concurrently", {
  skip_on_cran()
  skip_on_ci()
  skip_if_offline()

  out <- crawler(c(
    "https://example.com", "https://example.org", "https://example.net"
  )) |>
    cr_options(respect_robots = FALSE) |>
    cr_parallel(concurrency = 3) |>
    cr_on_html(function(ctx) {
      ctx$push_data(list(url = ctx$request$url, status = ctx$status))
    }) |>
    cr_run() |>
    cr_collect()

  expect_equal(nrow(out), 3L)
  expect_true(all(out$status == 200))
})
