# Configure the dataset backend

Configure the dataset backend

## Usage

``` r
cr_dataset(crawler, backend = "memory", path = NULL)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- backend:

  One of `"memory"` (default), `"duckdb"`, `"parquet"`.

- path:

  Optional path used by persistent backends.

## Value

The crawler, invisibly.
