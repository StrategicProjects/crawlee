# Use the headless-browser fetch backend

Reserved for a future release: rendering JavaScript-heavy pages via
`chromote`. Calling it currently signals an informative
not-yet-implemented error so pipelines fail loudly rather than silently
using HTTP.

## Usage

``` r
cr_use_browser(crawler)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

## Value

The crawler, invisibly.
