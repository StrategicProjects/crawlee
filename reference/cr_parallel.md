# Enable parallel (concurrent) fetching

Switches the HTTP engine to fetch requests in concurrent batches via
[`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html),
the rough equivalent of Crawlee's autoscaled pool. Network I/O runs
concurrently while handlers still run sequentially in R, so there is no
shared-state hazard. `robots.txt`, retries, `max_requests`/`max_depth`
and queue checkpointing all still apply.

## Usage

``` r
cr_parallel(crawler, concurrency = 4L, max_active = NULL)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- concurrency:

  Number of requests per batch.

- max_active:

  Maximum simultaneously-active connections (defaults to `concurrency`).

## Value

The crawler, invisibly.

## Details

Parallel mode applies to the HTTP backend only; the browser backend
always runs sequentially. `delay` and `Crawl-delay` are applied
*between* batches.

## Examples

``` r
crawler("https://example.com") |> cr_parallel(concurrency = 8)
```
