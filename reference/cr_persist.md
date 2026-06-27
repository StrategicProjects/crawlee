# Persist a crawl to a run directory (and resume it)

Wires a crawler to a directory on disk so a crawl is **reproducible and
resumable**. It persists:

## Usage

``` r
cr_persist(crawler, dir, dataset = c("jsonl", "duckdb", "memory"))
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- dir:

  Run directory (created if needed).

- dataset:

  Dataset backend to use: `"jsonl"` (default), `"duckdb"` or `"memory"`
  (not persisted).

## Value

The crawler, invisibly.

## Details

- the request queue state (`queue.rds`) — pending requests, seen keys
  and handled count, checkpointed during
  [`cr_run()`](https://strategicprojects.github.io/crawlee/reference/cr_run.md);

- the dataset, via a persistent
  [Dataset](https://strategicprojects.github.io/crawlee/reference/Dataset.md)
  backend (`dataset.jsonl` or `dataset.duckdb`);

- binary content saved by `ctx$save_body()` (under `kv/`);

- a run manifest (`manifest.rds`, plus `manifest.json` when jsonlite is
  available).

If a queue state already exists in `dir`, the crawl **resumes**: the
saved pending/seen/handled state is restored, so
[`cr_run()`](https://strategicprojects.github.io/crawlee/reference/cr_run.md)
continues where it left off and already-fetched URLs are not fetched
again.

Call `cr_persist()` before
[`cr_run()`](https://strategicprojects.github.io/crawlee/reference/cr_run.md).
For the `"duckdb"` backend, collect results with
[`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md)
before
[`cr_close()`](https://strategicprojects.github.io/crawlee/reference/cr_close.md).

## Examples

``` r
if (FALSE) { # \dontrun{
crawler("https://www.example.gov") |>
  cr_persist("runs/exemplo", dataset = "duckdb") |>
  cr_on_html(\(ctx) ctx$push_data(list(url = ctx$request$url))) |>
  cr_run() |>
  cr_collect()
# Re-running the same pipeline resumes from runs/exemplo.
} # }
```
