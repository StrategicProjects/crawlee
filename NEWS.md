# crawlee 0.0.0.9000 (development)

First scaffold of the package. Crawlee-inspired, native-R architecture.

## Milestone M4 — headless browser

* `cr_use_browser()` renders JavaScript-heavy pages with a headless
  Chrome/Chromium via \pkg{chromote}, with `wait` and `wait_selector` controls.
  Handlers are unchanged (`ctx$page`, `enqueue_links()`); the context gains
  `ctx$screenshot()`, saved to the [KeyValueStore].
* Fetch backends are now unified behind a normalised internal `fetched`
  object, so handlers behave identically regardless of HTTP vs browser.

## Milestone M3 — documents

* Content-type aware dispatch: each response is classified (`html`, `pdf`,
  `other`) and routed to the matching default handler; explicit request labels
  still take precedence.
* `cr_on_pdf()` registers a PDF handler. Its context adds `pdf_text()`
  (per-page text via \pkg{pdftools}), `body_raw()`/`body_string()` and
  `save_body()`.
* `KeyValueStore` plus `cr_store()` and `ctx$save_body()`: persist raw
  responses (PDFs, images, snapshots) on disk alongside the structured dataset.

## Milestone M2 — discovery

* `cr_from_sitemap()` enqueues URLs from a `sitemap.xml`, recursing into
  sitemap indexes, transparently handling gzipped sitemaps, with glob filters
  and a `since` filter on `<lastmod>` for incremental crawls.
* `cr_from_rss()` enqueues items from RSS and Atom feeds, carrying item title
  and date into the request's `user_data`.
* `robots.txt` is now enforced when `respect_robots = TRUE` (the default): a
  native parser/matcher (User-agent grouping, `*`/`$` patterns, longest-match
  with Allow override, Crawl-delay), cached per host. Disallowed URLs are
  skipped and reported; `Crawl-delay` is honoured.

## Milestone M1 — core

* `crawler()` builds a stateful, pipe-friendly crawler.
* `RequestQueue`: deduplicating (normalised `unique_key`), FIFO, resumable
  request queue with retry rescheduling.
* `cr_options()` configures concurrency, depth, delay, retries, user agent and
  log verbosity.
* `cr_use_http()` HTTP fetch backend (`httr2`); `cr_use_browser()` reserved.
* `cr_on_html()` registers content handlers; handler context exposes
  `push_data()` and `enqueue_links()` (with glob/include/exclude and
  same-domain filtering).
* `Dataset` append-only store; `cr_run()` drives the crawl and `cr_collect()`
  returns a tibble.
* Rich console logging via `cli`.

## Not implemented yet (roadmap)

* Persistent dataset backends (DuckDB, Parquet) — the `backend` argument is
  accepted but currently stores in memory.
* RAG helpers (M5).
