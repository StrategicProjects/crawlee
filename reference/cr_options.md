# Set crawler options

Set crawler options

## Usage

``` r
cr_options(crawler, ...)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- ...:

  Named options to override. Recognised options: `concurrency`,
  `max_requests`, `max_depth`, `delay` (seconds between requests),
  `timeout`, `max_retries`, `user_agent`, `respect_robots`,
  `same_domain`, `log_level` (`"debug"`, `"info"`, `"warn"`, `"error"`,
  `"off"`).

## Value

The crawler, invisibly.

## Examples

``` r
crawler("https://example.com") |> cr_options(delay = 0.5, max_depth = 2)
```
