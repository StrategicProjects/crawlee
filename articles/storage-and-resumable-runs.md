# Storage and resumable runs

``` r

library(crawlee)
```

[Crawlee](https://crawlee.dev) separates three kinds of storage: the
**request queue** (what to crawl), the **dataset** (structured results)
and the **key-value store** (binary blobs). crawlee mirrors that split
and adds a one-call setup for **reproducible, resumable** runs.

## The dataset

Handlers call `ctx$push_data()` to append records;
[`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md)
returns them as one tibble. By default the dataset lives in memory.

``` r

result <- crawler("https://books.toscrape.com/") |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(url = ctx$request$url))
  }) |>
  cr_run() |>
  cr_collect()
```

For larger or longer crawls, choose a **persistent backend** with
[`cr_dataset()`](https://strategicprojects.github.io/crawlee/reference/cr_dataset.md):

- `"jsonl"` — append-only, schema-flexible, one JSON object per line;
- `"duckdb"` — appended to a DuckDB table, ready for SQL.

``` r

crawler("https://books.toscrape.com/") |>
  cr_dataset(backend = "duckdb", path = "books.duckdb") |>
  cr_on_html(function(ctx) ctx$push_data(list(url = ctx$request$url))) |>
  cr_run()
```

Both persistent backends *resume* from an existing file: re-opening the
same path keeps the rows already there.

## The key-value store

Use the key-value store for raw, non-tabular content — PDFs, images,
page snapshots. `ctx$save_body()` writes the current response there, and
[`cr_store()`](https://strategicprojects.github.io/crawlee/reference/cr_store.md)
sets the directory.

``` r

crawler("https://example.com/report.pdf") |>
  cr_store("downloads") |>
  cr_on_pdf(function(ctx) {
    ctx$push_data(list(url = ctx$request$url, pages = length(ctx$pdf_text())))
    ctx$save_body(ext = "pdf") # -> downloads/<sanitised-url>.pdf
  }) |>
  cr_run()
```

## The request queue and reproducibility

The request queue deduplicates by a normalised key (see
[`cr_normalize_url()`](https://strategicprojects.github.io/crawlee/reference/cr_normalize_url.md)),
so each URL is fetched at most once and a crawl is deterministic. It can
also persist its state — pending requests, seen keys, handled count —
which is what makes a crawl **resumable**.

## One-call setup: `cr_persist()`

`cr_persist(dir)` wires everything to a run directory:

- the queue is checkpointed to `queue.rds` during the run;
- the dataset uses a persistent backend (`dataset.jsonl` or
  `dataset.duckdb`);
- `ctx$save_body()` writes under `kv/`;
- a manifest (`manifest.rds` / `manifest.json`) records the start URLs,
  an options snapshot and run statistics.

``` r

crawl <- crawler("https://books.toscrape.com/") |>
  cr_persist("runs/books", dataset = "duckdb") |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(url = ctx$request$url))
    ctx$enqueue_links(glob = "*/catalogue/*")
  }) |>
  cr_run()

data <- cr_collect(crawl)
cr_close(crawl) # release the DuckDB connection
```

### Resuming

If a run is interrupted, **run the exact same pipeline again**. Because
the state already exists in `runs/books`,
[`cr_persist()`](https://strategicprojects.github.io/crawlee/reference/cr_persist.md)
restores it and the crawl continues where it left off — already-fetched
URLs are skipped.

``` r

# Same code as above: it resumes instead of starting over.
crawler("https://books.toscrape.com/") |>
  cr_persist("runs/books", dataset = "duckdb") |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(url = ctx$request$url))
    ctx$enqueue_links(glob = "*/catalogue/*")
  }) |>
  cr_run()
```

> For the DuckDB backend, call
> [`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md)
> before
> [`cr_close()`](https://strategicprojects.github.io/crawlee/reference/cr_close.md)
> — closing releases the connection.
