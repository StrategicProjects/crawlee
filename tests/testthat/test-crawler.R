test_that("crawler() seeds the queue and sets options", {
  cr <- crawler(c("https://x.com/a", "https://x.com/b"), max_depth = 2)
  expect_s3_class(cr, "Crawler")
  expect_equal(cr$queue$pending_count(), 2L)
  expect_equal(cr$options$max_depth, 2)
})

test_that("cr_options rejects unknown options", {
  cr <- crawler("https://x.com")
  expect_error(cr_options(cr, nonsense = 1), "Unknown option")
})

test_that("verbs return the crawler invisibly and compose", {
  cr <- crawler("https://x.com") |>
    cr_options(delay = 0) |>
    cr_use_http() |>
    cr_on_html(function(ctx) ctx$push_data(list(u = ctx$request$url)))
  expect_s3_class(cr, "Crawler")
  expect_false(is.null(cr$default_handler))
})

test_that("cr_use_browser errors as not implemented", {
  expect_error(cr_use_browser(crawler("https://x.com")), "not implemented")
})

test_that("dataset push/collect round-trips", {
  d <- Dataset$new()
  d$push(list(a = 1, b = "x"))
  d$push(data.frame(a = 2, b = "y"))
  out <- d$collect()
  expect_equal(nrow(out), 2L)
  expect_equal(out$a, c(1, 2))
})

test_that("check_crawler guards verbs", {
  expect_error(cr_run("nope"), "must be a")
})
