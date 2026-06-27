test_that("RequestQueue deduplicates by normalised key", {
  q <- RequestQueue$new()
  expect_true(q$add("https://x.com/a"))
  expect_false(q$add("https://x.com/a/")) # duplicate after normalisation
  expect_true(q$add("https://x.com/b"))
  expect_equal(q$pending_count(), 2L)
})

test_that("RequestQueue is FIFO and tracks handled", {
  q <- RequestQueue$new()
  q$add("https://x.com/1")
  q$add("https://x.com/2")
  expect_equal(q$pop()$url, "https://x.com/1")
  q$mark_handled()
  expect_equal(q$handled(), 1L)
  expect_equal(q$pop()$url, "https://x.com/2")
  expect_true(q$is_empty())
})

test_that("reschedule increments retry_count", {
  q <- RequestQueue$new()
  q$add("https://x.com/1")
  req <- q$pop()
  q$reschedule(req)
  expect_equal(q$pop()$retry_count, 1L)
})
