test_that("classify_content detects pdf, html and other", {
  expect_equal(classify_content("application/pdf", "https://x/a"), "pdf")
  expect_equal(classify_content("", "https://x/edital.PDF"), "pdf")
  expect_equal(classify_content("text/html; charset=utf-8", "https://x/a"), "html")
  expect_equal(classify_content("application/xml", "https://x/a"), "html")
  expect_equal(classify_content("application/json", "https://x/a"), "other")
})

test_that("resolve_handler routes by label then by kind", {
  cr <- crawler("https://x.com") |>
    cr_on_html(function(ctx) "html") |>
    cr_on_pdf(function(ctx) "pdf") |>
    cr_on_html(function(ctx) "labelled", label = "special")

  resolve <- cr$.__enclos_env__$private$resolve_handler
  expect_equal(resolve(list(label = NULL), "html")(NULL), "html")
  expect_equal(resolve(list(label = NULL), "pdf")(NULL), "pdf")
  expect_equal(resolve(list(label = "special"), "pdf")(NULL), "labelled")
  expect_null(resolve(list(label = NULL), "other"))
})

test_that("KeyValueStore round-trips raw and text", {
  dir <- file.path(tempdir(), "crawlee-kv-test")
  unlink(dir, recursive = TRUE)
  kv <- KeyValueStore$new(dir)
  kv$set_raw("https://x.com/a.pdf", as.raw(c(1, 2, 3)))
  expect_equal(kv$get_raw("https://x.com/a.pdf"), as.raw(c(1, 2, 3)))
  kv$set_text("note", "hello")
  expect_true(length(kv$keys()) == 2L)
  expect_null(kv$get_raw("missing"))
})

test_that("kv_safe_key sanitises and truncates", {
  expect_equal(kv_safe_key("https://x.com/a b"), "https_x.com_a_b")
  expect_true(nchar(kv_safe_key(strrep("a", 500))) <= 180L)
  expect_equal(kv_safe_key(""), "index")
})
