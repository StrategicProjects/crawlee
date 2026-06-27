test_that("cr_use_browser switches mode and sets options", {
  cr <- crawler("https://example.com") |>
    cr_use_browser(wait = 1, wait_selector = ".x")
  expect_equal(cr$mode, "browser")
  expect_equal(cr$options$browser_wait, 1)
  expect_equal(cr$options$browser_wait_selector, ".x")
})

test_that("screenshot() errors on the HTTP backend", {
  fetched <- list(
    status = 200L, content_type = "text/html",
    html = function() "<html></html>", raw = function() raw(0),
    screenshot = NULL, response = NULL
  )
  ctx <- crawler_context(
    crawler("https://x.com"), list(url = "https://x.com"),
    fetched, NULL, make_logger("off")
  )
  expect_error(ctx$screenshot(), "browser backend")
})

test_that("browser backend renders a page end-to-end", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("chromote")
  skip_if(
    is.null(tryCatch(chromote::find_chrome(), error = function(e) NULL)),
    "Chrome not available"
  )
  skip_if_offline()

  out <- crawler("https://example.com") |>
    cr_use_browser() |>
    cr_on_html(function(ctx) {
      ctx$push_data(list(
        title = rvest::html_text2(rvest::html_element(ctx$page, "h1"))
      ))
    }) |>
    cr_run() |>
    cr_collect()

  expect_equal(nrow(out), 1L)
  expect_match(out$title, "Example")
})
