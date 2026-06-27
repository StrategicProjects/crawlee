# Enable autoscaled parallel fetching

Like
[`cr_parallel()`](https://strategicprojects.github.io/crawlee/reference/cr_parallel.md),
but the batch concurrency adapts at run time, the rough equivalent of
Crawlee's autoscaled pool. After each batch the engine adjusts
concurrency with an additive-increase / multiplicative-decrease rule: it
grows by one when a batch is clean, and halves on back-pressure (a
transport failure or an HTTP 429/500/502/503/504), staying within
`[min, max]`.

## Usage

``` r
cr_autoscale(crawler, min = 1L, max = 16L, max_active = NULL)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- min, max:

  Concurrency bounds. The crawl starts at `min`.

- max_active:

  Maximum simultaneously-active connections (defaults to the current
  concurrency).

## Value

The crawler, invisibly.

## Examples

``` r
crawler("https://example.com") |> cr_autoscale(min = 2, max = 16)
```
