# Create a crawler

Constructs a new
[Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md)
seeded with `start_urls`. The result is designed to be piped through the
`cr_*` configuration verbs and finally
[`cr_run()`](https://strategicprojects.github.io/crawlee/reference/cr_run.md).

## Usage

``` r
crawler(start_urls = character(), ...)
```

## Arguments

- start_urls:

  Character vector of seed URLs to enqueue at depth 0.

- ...:

  Options forwarded to
  [`cr_options()`](https://strategicprojects.github.io/crawlee/reference/cr_options.md)
  (e.g. `max_requests`, `delay`, `log_level`).

## Value

A
[Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md)
object.

## Examples

``` r
cr <- crawler("https://example.com", max_requests = 10)
cr
#> <Crawler> ("http" mode)
#> • pending requests: 1
#> • handled: 0 - records: 0
#> • handlers: 0 labelled - defaults: none
```
