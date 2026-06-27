# Changelog

## crawlee 0.1.0

First release. A tidy, native-R, Crawlee-inspired toolkit for
reproducible web crawling.

### Milestone M8 — autoscaling & streaming

- `cr_autoscale(min, max)` adapts the parallel batch concurrency at run
  time (Crawlee autoscaled-pool style): additive-increase on clean
  batches, multiplicative-decrease on back-pressure (a transport failure
  or HTTP 429/500/502/503/504), clamped to `[min, max]`.
- `cr_stream(concurrency)` adds a continuous-pool scheduler (via
  [`httr2::req_perform_promise()`](https://httr2.r-lib.org/reference/req_perform_promise.html) +
  /): keeps `concurrency` requests in flight at all times, dispatching
  and refilling as each finishes — avoiding the batch engine’s “wait for
  the slowest” stall.

### Milestone M7 — parallel fetching

- `cr_parallel(concurrency)` enables concurrent fetching for the HTTP
  backend (Crawlee’s autoscaled-pool equivalent): the queue is drained
  in batches whose network I/O runs concurrently via
  [`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html),
  while handlers still run sequentially in R (no shared-state hazard).
  `robots.txt`, retries, depth/request limits and queue checkpointing
  all still apply; `delay`/`Crawl-delay` are applied between batches.
- The engine was refactored into shared `dispatch`/`error` steps used by
  both the sequential and parallel loops.

### Milestone M6 — persistent & resumable storage

- [`cr_persist()`](https://strategicprojects.github.io/crawlee/reference/cr_persist.md)
  ties a crawl to a run directory: the request queue is checkpointed
  (`queue.rds`) during the run and **restored on the next run**, so a
  crawl resumes where it left off without re-fetching seen URLs.
- Persistent \[Dataset\] backends: `cr_dataset(backend = "jsonl")`
  (append-only, schema-flexible) and `"duckdb"` (SQL-ready). The
  `RequestQueue` gained
  [`save()`](https://rdrr.io/r/base/save.html)/`restore()`/`set_path()`.
- A reproducibility manifest (`manifest.rds` / `manifest.json`) records
  the start URLs, options snapshot and run stats.
- [`cr_close()`](https://strategicprojects.github.io/crawlee/reference/cr_close.md)
  releases the browser session and DuckDB connection.

### Milestone M5 — RAG

- [`cr_chunk()`](https://strategicprojects.github.io/crawlee/reference/cr_chunk.md)
  splits text (a character vector or a data-frame column) into
  overlapping chunks, by character or word, carrying metadata per chunk.
- [`cr_embed()`](https://strategicprojects.github.io/crawlee/reference/cr_embed.md)
  attaches an `embedding` list-column via a user-supplied,
  provider-agnostic embedding function, applied in batches. crawlee
  never calls an external service itself.
- [`cr_export()`](https://strategicprojects.github.io/crawlee/reference/cr_export.md)
  writes chunks (and embeddings) to Parquet, JSONL, CSV or DuckDB for
  retrieval.

### Milestone M4 — headless browser

- [`cr_use_browser()`](https://strategicprojects.github.io/crawlee/reference/cr_use_browser.md)
  renders JavaScript-heavy pages with a headless Chrome/Chromium via ,
  with `wait` and `wait_selector` controls. Handlers are unchanged
  (`ctx$page`, `enqueue_links()`); the context gains `ctx$screenshot()`,
  saved to the \[KeyValueStore\].
- Fetch backends are now unified behind a normalised internal `fetched`
  object, so handlers behave identically regardless of HTTP vs browser.

### Milestone M3 — documents

- Content-type aware dispatch: each response is classified (`html`,
  `pdf`, `other`) and routed to the matching default handler; explicit
  request labels still take precedence.
- [`cr_on_pdf()`](https://strategicprojects.github.io/crawlee/reference/cr_on_pdf.md)
  registers a PDF handler. Its context adds `pdf_text()` (per-page text
  via ), `body_raw()`/`body_string()` and `save_body()`.
- `KeyValueStore` plus
  [`cr_store()`](https://strategicprojects.github.io/crawlee/reference/cr_store.md)
  and `ctx$save_body()`: persist raw responses (PDFs, images, snapshots)
  on disk alongside the structured dataset.

### Milestone M2 — discovery

- [`cr_from_sitemap()`](https://strategicprojects.github.io/crawlee/reference/cr_from_sitemap.md)
  enqueues URLs from a `sitemap.xml`, recursing into sitemap indexes,
  transparently handling gzipped sitemaps, with glob filters and a
  `since` filter on `<lastmod>` for incremental crawls.
- [`cr_from_rss()`](https://strategicprojects.github.io/crawlee/reference/cr_from_rss.md)
  enqueues items from RSS and Atom feeds, carrying item title and date
  into the request’s `user_data`.
- `robots.txt` is now enforced when `respect_robots = TRUE` (the
  default): a native parser/matcher (User-agent grouping, `*`/`$`
  patterns, longest-match with Allow override, Crawl-delay), cached per
  host. Disallowed URLs are skipped and reported; `Crawl-delay` is
  honoured.

### Milestone M1 — core

- [`crawler()`](https://strategicprojects.github.io/crawlee/reference/crawler.md)
  builds a stateful, pipe-friendly crawler.
- `RequestQueue`: deduplicating (normalised `unique_key`), FIFO,
  resumable request queue with retry rescheduling.
- [`cr_options()`](https://strategicprojects.github.io/crawlee/reference/cr_options.md)
  configures concurrency, depth, delay, retries, user agent and log
  verbosity.
- [`cr_use_http()`](https://strategicprojects.github.io/crawlee/reference/cr_use_http.md)
  HTTP fetch backend (`httr2`);
  [`cr_use_browser()`](https://strategicprojects.github.io/crawlee/reference/cr_use_browser.md)
  reserved.
- [`cr_on_html()`](https://strategicprojects.github.io/crawlee/reference/cr_on_html.md)
  registers content handlers; handler context exposes `push_data()` and
  `enqueue_links()` (with glob/include/exclude and same-domain
  filtering).
- `Dataset` append-only store;
  [`cr_run()`](https://strategicprojects.github.io/crawlee/reference/cr_run.md)
  drives the crawl and
  [`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md)
  returns a tibble.
- Rich console logging via `cli`.

### Possible future work

- Autoscaling within the streaming scheduler (currently fixed
  concurrency); per-host rate-limit pacing in streaming mode.
