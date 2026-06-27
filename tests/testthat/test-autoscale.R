test_that("autoscale_next applies AIMD within bounds", {
  expect_equal(autoscale_next(4L, FALSE, 1L, 16L), 5L) # additive increase
  expect_equal(autoscale_next(8L, TRUE, 1L, 16L), 4L) # multiplicative decrease
  expect_equal(autoscale_next(16L, FALSE, 1L, 16L), 16L) # clamp to max
  expect_equal(autoscale_next(1L, TRUE, 1L, 16L), 1L) # clamp to min
})

test_that("is_backpressure flags overload, failure and rate-limit", {
  expect_false(is_backpressure(c(200L, 200L, 301L)))
  expect_true(is_backpressure(c(200L, 429L)))
  expect_true(is_backpressure(c(200L, NA_integer_))) # transport failure
  expect_true(is_backpressure(503L))
})

test_that("result_status reads response and error statuses", {
  r <- httr2::response(status_code = 404)
  expect_equal(result_status(r), 404L)
  expect_true(is.na(result_status(simpleError("boom")))) # transport error
})

test_that("cr_autoscale sets options and validates bounds", {
  cr <- crawler("https://x.com") |> cr_autoscale(min = 2, max = 10)
  expect_true(cr$options$parallel)
  expect_true(cr$options$autoscale)
  expect_equal(cr$options$min_concurrency, 2L)
  expect_equal(cr$options$max_concurrency, 10L)
  expect_error(crawler("https://x.com") |> cr_autoscale(min = 5, max = 2), "min <= max")
})

test_that("autoscaled crawl fetches multiple URLs", {
  skip_on_cran()
  skip_on_ci()
  skip_if_offline()

  out <- crawler(c(
    "https://example.com", "https://example.org", "https://example.net"
  )) |>
    cr_options(respect_robots = FALSE) |>
    cr_autoscale(min = 1, max = 4) |>
    cr_on_html(function(ctx) {
      ctx$push_data(list(url = ctx$request$url, status = ctx$status))
    }) |>
    cr_run() |>
    cr_collect()

  expect_equal(nrow(out), 3L)
})
