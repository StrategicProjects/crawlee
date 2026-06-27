# Package index

## Crawler

Build, configure and run a crawler.

- [`crawler()`](https://strategicprojects.github.io/crawlee/reference/crawler.md)
  : Create a crawler
- [`cr_options()`](https://strategicprojects.github.io/crawlee/reference/cr_options.md)
  : Set crawler options
- [`cr_use_http()`](https://strategicprojects.github.io/crawlee/reference/cr_use_http.md)
  : Use the HTTP fetch backend
- [`cr_use_browser()`](https://strategicprojects.github.io/crawlee/reference/cr_use_browser.md)
  : Use the headless-browser fetch backend
- [`cr_dataset()`](https://strategicprojects.github.io/crawlee/reference/cr_dataset.md)
  : Configure the dataset backend
- [`cr_run()`](https://strategicprojects.github.io/crawlee/reference/cr_run.md)
  : Run a crawl
- [`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md)
  : Collect crawl results

## Discovery

Seed the queue from sitemaps and feeds.

- [`cr_from_sitemap()`](https://strategicprojects.github.io/crawlee/reference/cr_from_sitemap.md)
  : Discover URLs from a sitemap
- [`cr_from_rss()`](https://strategicprojects.github.io/crawlee/reference/cr_from_rss.md)
  : Discover URLs from an RSS or Atom feed

## Handlers

Register handlers and act on fetched content.

- [`cr_on_html()`](https://strategicprojects.github.io/crawlee/reference/cr_on_html.md)
  : Register an HTML handler
- [`cr_on_pdf()`](https://strategicprojects.github.io/crawlee/reference/cr_on_pdf.md)
  : Register a PDF handler

## Storage & queue

Lower-level building blocks.

- [`Crawler-class`](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md)
  [`Crawler`](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md)
  : Crawler
- [`RequestQueue`](https://strategicprojects.github.io/crawlee/reference/RequestQueue.md)
  : Request queue
- [`Dataset`](https://strategicprojects.github.io/crawlee/reference/Dataset.md)
  : Dataset
- [`cr_store()`](https://strategicprojects.github.io/crawlee/reference/cr_store.md)
  : Configure the key-value store for binary content
- [`KeyValueStore`](https://strategicprojects.github.io/crawlee/reference/KeyValueStore.md)
  : Key-value store

## Utilities

- [`cr_normalize_url()`](https://strategicprojects.github.io/crawlee/reference/cr_normalize_url.md)
  : Normalise a URL into a canonical form
