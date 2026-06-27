# Use the headless-browser fetch backend

Switches the crawler to render pages with a headless Chrome/Chromium via
the chromote package — for JavaScript-heavy sites where the plain HTTP
backend would see an empty shell. Handlers work exactly as with
[`cr_use_http()`](https://strategicprojects.github.io/crawlee/reference/cr_use_http.md)
(`ctx$page`, `enqueue_links()`, ...), and additionally gain
`ctx$screenshot()`.

## Usage

``` r
cr_use_browser(crawler, wait = 0, wait_selector = NULL)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- wait:

  Seconds to wait after page load before capturing the DOM (useful for
  late-rendering content).

- wait_selector:

  Optional CSS selector to wait for before capturing.

## Value

The crawler, invisibly.

## Details

Requires chromote and a Chrome/Chromium installation. PDF extraction
still requires the HTTP backend.

## Examples

``` r
if (FALSE) { # \dontrun{
crawler("https://example.com") |>
  cr_use_browser(wait_selector = ".results") |>
  cr_on_html(\(ctx) {
    ctx$push_data(list(url = ctx$request$url))
    ctx$screenshot()
  }) |>
  cr_run()
} # }
```
