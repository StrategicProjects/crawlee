# Enable the streaming scheduler

A continuous-pool alternative to
[`cr_parallel()`](https://strategicprojects.github.io/crawlee/reference/cr_parallel.md)'s
synchronous batches. The streaming engine keeps requests in flight at
all times (via async promises,
[`httr2::req_perform_promise()`](https://httr2.r-lib.org/reference/req_perform_promise.html)):
the moment one request finishes, its handler runs and the next request
is pulled from the queue to refill the slot. Under heterogeneous
response latency this avoids the "wait for the slowest in the batch"
stall and improves throughput.

## Usage

``` r
cr_stream(crawler, concurrency = 8L, adaptive = FALSE, min = 1L, max = NULL)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- concurrency:

  Number of requests to keep in flight (the fixed target, or the
  starting point is `min` when `adaptive = TRUE`).

- adaptive:

  If `TRUE`, adapt the in-flight target within `[min, max]`.

- min, max:

  Bounds for the adaptive target. `max` defaults to `concurrency`.

## Value

The crawler, invisibly.

## Details

With `adaptive = TRUE` the in-flight target adapts at run time (AIMD on
back-pressure, like
[`cr_autoscale()`](https://strategicprojects.github.io/crawlee/reference/cr_autoscale.md)),
within `[min, max]`.

Launches are paced **per host**: a host is not hit again until `delay` /
`robots.txt` `Crawl-delay` has elapsed, while different hosts run in
parallel. With `delay = 0` and no `Crawl-delay`, pacing is a no-op.

Requires the promises and later packages, and the HTTP backend.

## Examples

``` r
crawler("https://example.com") |> cr_stream(concurrency = 10)
crawler("https://example.com") |> cr_stream(adaptive = TRUE, min = 2, max = 16)
```
