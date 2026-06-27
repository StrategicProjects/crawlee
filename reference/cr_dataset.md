# Configure the dataset backend

Configure the dataset backend

## Usage

``` r
cr_dataset(crawler, backend = "memory", path = NULL, table = "dataset")
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- backend:

  One of `"memory"` (default), `"jsonl"`, `"duckdb"`.

- path:

  File (jsonl) or database (duckdb) path; required for the persistent
  backends.

- table:

  Table name for the `"duckdb"` backend.

## Value

The crawler, invisibly.
