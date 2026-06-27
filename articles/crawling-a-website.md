# Crawling a website

``` r

library(crawlee)
```

This article follows the same path as the [Crawlee](https://crawlee.dev)
fundamentals: start from a single page, then teach the crawler to
**follow links**, **control its scope**, **route** different page types
and **discover URLs from a sitemap**. The examples target
[`books.toscrape.com`](https://books.toscrape.com), a public sandbox
built for practising web scraping.

## The model

A crawler owns three things:

- a **request queue** — a deduplicating, resumable list of URLs to
  visit;
- one or more **handlers** — functions run on each fetched page;
- a **dataset** — the structured records your handlers produce.

You build a crawler with
[`crawler()`](https://strategicprojects.github.io/crawlee/reference/crawler.md)
and configure it with `cr_*` verbs that compose through the native pipe
(`|>`), then run it with
[`cr_run()`](https://strategicprojects.github.io/crawlee/reference/cr_run.md).

## Your first crawler

Fetch a single page and extract a couple of fields. The handler receives
a context object (`ctx`) exposing the parsed page and the action
`push_data()`.

``` r

result <- crawler("https://books.toscrape.com/") |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(
      url   = ctx$request$url,
      title = ctx$page |> rvest::html_element("title") |> rvest::html_text2()
    ))
  }) |>
  cr_run() |>
  cr_collect()

result
```

## Following links

Real crawls discover new URLs as they go. `ctx$enqueue_links()` extracts
links from the current page and adds them to the queue; the crawler
keeps going until the queue drains. Because the queue deduplicates by a
normalised URL, each page is visited at most once.

``` r

crawler("https://books.toscrape.com/") |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(url = ctx$request$url))
    ctx$enqueue_links() # follow every same-domain link
  }) |>
  cr_options(max_requests = 50) |>
  cr_run()
```

`enqueue_links()` only follows same-domain links by default, so a crawl
cannot wander off across the whole web.

## Controlling scope

You rarely want *every* link. `enqueue_links()` takes `glob` (a
shorthand for `include`), `include`/`exclude` patterns and a
`same_domain` flag; the crawler itself enforces `max_depth` and
`max_requests`.

``` r

crawler("https://books.toscrape.com/") |>
  cr_options(max_depth = 3, max_requests = 200) |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(url = ctx$request$url, depth = ctx$request$depth))
    ctx$enqueue_links(
      glob    = "*/catalogue/*", # only follow catalogue pages
      exclude = "*/category/*"
    )
  }) |>
  cr_run() |>
  cr_collect()
```

## Routing different page types

Most sites have a few kinds of page — listings vs. detail pages, say.
Give a `label` when enqueuing and register a handler for that label.
Listing pages enqueue detail pages; detail pages extract the data.

``` r

books <- crawler("https://books.toscrape.com/") |>
  # listing pages: enqueue book detail pages, labelled "book"
  cr_on_html(function(ctx) {
    ctx$enqueue_links(glob = "*/catalogue/*index.html", label = "book")
    ctx$enqueue_links(glob = "*/page-*.html") # pagination, default handler
  }) |>
  # detail pages
  cr_on_html(label = "book", function(ctx) {
    ctx$push_data(list(
      title = ctx$page |> rvest::html_element("h1") |> rvest::html_text2(),
      price = ctx$page |> rvest::html_element(".price_color") |> rvest::html_text2()
    ))
  }) |>
  cr_run() |>
  cr_collect()

books
```

A request’s `label` always wins over the content-kind default, so
labelled routing and
[`cr_on_html()`](https://strategicprojects.github.io/crawlee/reference/cr_on_html.md)/[`cr_on_pdf()`](https://strategicprojects.github.io/crawlee/reference/cr_on_pdf.md)
defaults compose cleanly.

## Crawling from a sitemap

When a site publishes a `sitemap.xml`, you can seed the queue directly
from it instead of discovering links page by page —
[`cr_from_sitemap()`](https://strategicprojects.github.io/crawlee/reference/cr_from_sitemap.md)
handles sitemap indexes and gzipped sitemaps, and can filter by glob or
by `<lastmod>` date.

``` r

crawler() |>
  cr_from_sitemap("https://books.toscrape.com/sitemap.xml", label = "book") |>
  cr_on_html(label = "book", function(ctx) {
    ctx$push_data(list(url = ctx$request$url))
  }) |>
  cr_run() |>
  cr_collect()
```

The companion
[`cr_from_rss()`](https://strategicprojects.github.io/crawlee/reference/cr_from_rss.md)
does the same for RSS and Atom feeds.

## Rendering JavaScript pages

If a page builds its content with JavaScript, the plain HTTP backend
sees an empty shell. Switch to the headless-browser backend with
[`cr_use_browser()`](https://strategicprojects.github.io/crawlee/reference/cr_use_browser.md)
(requires the package and a Chrome/Chromium install). Handlers are
unchanged; you additionally get `ctx$screenshot()`.

``` r

crawler("https://example.com") |>
  cr_use_browser(wait_selector = ".content") |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(url = ctx$request$url))
    ctx$screenshot()
  }) |>
  cr_run()
```

## Where next

- **Politeness & speed** — `robots.txt` is respected by default;
  `cr_options(delay = )` rate-limits, and
  [`cr_parallel()`](https://strategicprojects.github.io/crawlee/reference/cr_parallel.md)
  fetches concurrently.
- **Documents** —
  [`cr_on_pdf()`](https://strategicprojects.github.io/crawlee/reference/cr_on_pdf.md)
  extracts text from PDFs; `ctx$save_body()` stores raw files in a
  key-value store.
- **Reproducible, resumable runs** — `cr_persist(dir)` checkpoints the
  queue and persists the dataset, so an interrupted crawl continues
  where it left off.
- **RAG** —
  [`cr_chunk()`](https://strategicprojects.github.io/crawlee/reference/cr_chunk.md),
  [`cr_embed()`](https://strategicprojects.github.io/crawlee/reference/cr_embed.md)
  and
  [`cr_export()`](https://strategicprojects.github.io/crawlee/reference/cr_export.md)
  turn crawled text into a retrieval-ready table.
