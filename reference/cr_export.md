# Export chunks (and embeddings) for retrieval

Writes a chunk table to a retrieval-friendly format. `parquet` and
`jsonl` preserve the `embedding` list-column natively; `csv` and
`duckdb` serialise it to a `[...]` string for portability.

## Usage

``` r
cr_export(
  data,
  path,
  format = c("parquet", "jsonl", "csv", "duckdb"),
  table = "chunks"
)
```

## Arguments

- data:

  A data frame (typically from
  [`cr_chunk()`](https://strategicprojects.github.io/crawlee/reference/cr_chunk.md)
  /
  [`cr_embed()`](https://strategicprojects.github.io/crawlee/reference/cr_embed.md)).

- path:

  Output file (or database) path.

- format:

  One of `"parquet"`, `"jsonl"`, `"csv"`, `"duckdb"`.

- table:

  Table name for the `"duckdb"` format.

## Value

`path`, invisibly.
