# Changelog

## crawlee 0.0.0.9000 (development)

First scaffold of the package. Crawlee-inspired, native-R architecture.

### Milestone M1 — core (in progress)

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

### Not implemented yet (roadmap)

- `respect_robots` option is accepted but not yet enforced (planned M2).
- Persistent dataset backends (DuckDB, Parquet) — the `backend` argument
  is accepted but currently stores in memory (planned M1/M2).
- Sitemap and RSS discovery (M2), PDF handlers (M3), headless browser
  (M4), RAG helpers (M5).
