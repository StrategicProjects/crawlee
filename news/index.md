# Changelog

## crawlee 0.0.0.9000 (development)

First scaffold of the package. Crawlee-inspired, native-R architecture.

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

### Not implemented yet (roadmap)

- Persistent dataset backends (DuckDB, Parquet) — the `backend` argument
  is accepted but currently stores in memory.
- PDF handlers (M3), headless browser (M4), RAG helpers (M5).
