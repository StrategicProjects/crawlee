test_that("cr_normalize_url canonicalises URLs", {
  expect_equal(
    cr_normalize_url("HTTPS://Example.com:443/a/?b=2&a=1"),
    "https://example.com/a?a=1&b=2"
  )
  expect_equal(cr_normalize_url("http://x.com:80/"), "http://x.com/")
  expect_equal(cr_normalize_url("http://x.com"), "http://x.com/")
  expect_true(is.na(cr_normalize_url("")))
})

test_that("glob matching works", {
  expect_true(url_matches("https://x.com/a/b", include = "*/a/*"))
  expect_false(url_matches("https://x.com/c", include = "*/a/*"))
  expect_false(url_matches("https://x.com/a", exclude = "*/a"))
})

test_that("url_host extracts host", {
  expect_equal(url_host("https://Example.com/x"), "example.com")
})
