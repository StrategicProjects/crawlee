# Getting started with crawlee

``` r

library(crawlee)
```

## The mental model

crawlee mirrors the architecture of [Crawlee](https://crawlee.dev) in
pure R. A **crawler** owns:

- a **request queue** — a deduplicating, resumable list of URLs to
  visit;
- one or more **handlers** — functions run on each fetched page;
- a **dataset** — the structured records your handlers produce.

You build a crawler with
[`crawler()`](https://strategicprojects.github.io/crawlee/reference/crawler.md)
and configure it with `cr_*` verbs that compose through the native pipe
(`|>`).

## A minimal crawl

``` r

resultado <- crawler("https://example.com") |>
  cr_options(delay = 0.5, max_depth = 2) |>
  cr_use_http() |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(
      url    = ctx$request$url,
      titulo = ctx$page |> rvest::html_element("h1") |> rvest::html_text2()
    ))
    ctx$enqueue_links()
  }) |>
  cr_run() |>
  cr_collect()
```

## The handler context

Every handler receives a context object, conventionally named `ctx`:

| Element | Description |
|----|----|
| `ctx$request` | The current request (`url`, `label`, `depth`, …). |
| `ctx$response` | The raw `httr2` response. |
| `ctx$page` | The parsed page (`xml_document`) for HTML/XML, else `NULL`. |
| `ctx$push_data(data)` | Append a record (list or data frame) to the dataset. |
| `ctx$enqueue_links(...)` | Discover and enqueue links from the page. |
| `ctx$log` | Logging helpers (`info()`, `success()`, `warn()`, `error()`). |

### Controlling link discovery

`enqueue_links()` accepts `glob`, `include`/`exclude` patterns and a
`same_domain` flag (on by default), so you only follow the links you
care about:

``` r

ctx$enqueue_links(
  glob    = "*/blog/*",
  exclude = "*/tag/*",
  label   = "article"
)
```

Requests enqueued with a `label` are routed to the matching handler
registered with `cr_on_html(..., label = "article")`.

## Reproducibility

The request queue deduplicates URLs by a normalised key (see
[`cr_normalize_url()`](https://strategicprojects.github.io/crawlee/reference/cr_normalize_url.md)),
so the same page is never fetched twice and crawls are deterministic.
Persistent, resumable storage backends (DuckDB, Parquet) are on the
roadmap. \`\`\`
