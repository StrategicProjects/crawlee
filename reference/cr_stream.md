# Enable the streaming scheduler

A continuous-pool alternative to
[`cr_parallel()`](https://strategicprojects.github.io/crawlee/reference/cr_parallel.md)'s
synchronous batches. The streaming engine keeps up to `concurrency`
requests in flight at all times (via async promises,
[`httr2::req_perform_promise()`](https://httr2.r-lib.org/reference/req_perform_promise.html)):
the moment one request finishes, its handler runs and the next request
is pulled from the queue to refill the slot. Under heterogeneous
response latency this avoids the "wait for the slowest in the batch"
stall and improves throughput.

## Usage

``` r
cr_stream(crawler, concurrency = 8L)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- concurrency:

  Number of requests to keep in flight.

## Value

The crawler, invisibly.

## Details

Requires the promises and later packages, and the HTTP backend.
Concurrency is the throttle; `delay` / `robots.txt` `Crawl-delay` pacing
is **not** enforced in streaming mode (use
[`cr_parallel()`](https://strategicprojects.github.io/crawlee/reference/cr_parallel.md)
for strict pacing). `robots.txt` allow/deny rules are still respected.

## Examples

``` r
crawler("https://example.com") |> cr_stream(concurrency = 10)
```
