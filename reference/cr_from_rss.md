# Discover URLs from an RSS or Atom feed

Fetches a feed and enqueues each item's link. The item title and date
are attached to the request's `user_data` (available to handlers as
`ctx$request$user_data`), so feed metadata can be carried into the
dataset.

## Usage

``` r
cr_from_rss(
  crawler,
  url,
  label = NULL,
  include = NULL,
  exclude = NULL,
  max = Inf
)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- url:

  URL of an RSS or Atom feed.

- label:

  Optional handler label routing the enqueued URLs.

- include, exclude:

  Optional glob patterns (see
  [`cr_on_html()`](https://strategicprojects.github.io/crawlee/reference/cr_on_html.md)).

- max:

  Maximum number of items to enqueue.

## Value

The crawler, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
crawler() |>
  cr_on_html(\(ctx) ctx$push_data(list(
    url = ctx$request$url, titulo = ctx$request$user_data$title
  ))) |>
  cr_from_rss("https://www.example.gov/noticias/rss")
} # }
```
