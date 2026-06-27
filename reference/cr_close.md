# Release a crawler's resources

Closes the headless browser session (if any) and the DuckDB connection
(if the dataset uses the duckdb backend). Collect results with
[`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md)
before closing a duckdb-backed crawl.

## Usage

``` r
cr_close(crawler)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

## Value

The crawler, invisibly.
