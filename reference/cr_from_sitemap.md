# Discover URLs from a sitemap

Fetches a sitemap (or sitemap index, recursively) and enqueues the page
URLs it lists. Supports gzipped sitemaps, glob filtering and a `since`
filter on `<lastmod>` for incremental re-crawls of large sites that
publish dated sitemaps.

## Usage

``` r
cr_from_sitemap(
  crawler,
  url,
  label = NULL,
  include = NULL,
  exclude = NULL,
  since = NULL,
  max = Inf,
  max_levels = 3L
)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- url:

  URL of a `sitemap.xml` or sitemap index.

- label:

  Optional handler label routing the enqueued URLs.

- include, exclude:

  Optional glob patterns (see
  [`cr_on_html()`](https://strategicprojects.github.io/crawlee/reference/cr_on_html.md)).

- since:

  Optional date (or `YYYY-MM-DD` string); only URLs whose `<lastmod>` is
  on or after this date are enqueued (URLs without a `lastmod` are
  kept).

- max:

  Maximum number of URLs to enqueue.

- max_levels:

  Maximum recursion depth into nested sitemap indexes.

## Value

The crawler, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
crawler() |>
  cr_on_html(\(ctx) ctx$push_data(list(url = ctx$request$url))) |>
  cr_from_sitemap("https://example.com/sitemap.xml", since = "2026-01-01")
} # }
```
