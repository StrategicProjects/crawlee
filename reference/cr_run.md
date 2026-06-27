# Run a crawl

Drains the request queue, fetching each request, dispatching it to the
matching handler and collecting pushed records, until the queue is empty
or the `max_requests` limit is reached.

## Usage

``` r
cr_run(crawler)
```

## Arguments

- crawler:

  A configured
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

## Value

The crawler, invisibly (its dataset now holds the results).

## Examples

``` r
if (FALSE) { # \dontrun{
crawler("https://example.com") |>
  cr_on_html(\(ctx) ctx$push_data(list(url = ctx$request$url))) |>
  cr_run() |>
  cr_collect()
} # }
```
