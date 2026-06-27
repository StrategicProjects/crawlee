# crawlee <img src="man/figures/logo.svg" align="right" height="139" alt="crawlee logo" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/StrategicProjects/crawlee/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/StrategicProjects/crawlee/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/StrategicProjects/crawlee/actions/workflows/pkgdown.yaml/badge.svg)](https://strategicprojects.github.io/crawlee/)
[![Project Status: Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit)
[![R \>= 4.1](https://img.shields.io/badge/R-%3E%3D%204.1-1f6feb.svg)](https://cran.r-project.org/)
<!-- badges: end -->

> A tidy R interface for reproducible web crawling — inspired by the
> architecture of [Crawlee](https://crawlee.dev), implemented in pure R.

**crawlee** brings the unified-crawler idea to R: a deduplicating, resumable
request queue, content-type aware handlers, structured storage and rich
console logging via [cli](https://cli.r-lib.org). It can crawl HTML pages,
sitemaps, RSS and Atom feeds and PDF documents — with reproducibility as a
first-class concern.

It is built entirely on the R web-scraping ecosystem
([httr2](https://httr2.r-lib.org), [rvest](https://rvest.tidyverse.org),
[xml2](https://xml2.r-lib.org), [chromote](https://rstudio.github.io/chromote/))
— no Node.js runtime required.

## How it works

A crawl is a loop: requests flow through a deduplicating queue to a fetch
engine; each response is dispatched to a handler that extracts data
(`push_data()`) and discovers more links (`enqueue_links()`), which flow back
into the queue until it drains.

<img src="man/figures/crawl-flow.svg" alt="crawlee request lifecycle" width="100%" />

## Architecture

<img src="man/figures/architecture.svg" alt="crawlee architecture" width="100%" />

## Installation

``` r
# install.packages("pak")
pak::pak("StrategicProjects/crawlee")
```

## Usage

``` r
library(crawlee)

resultado <- crawler("https://example.com") |>
  cr_options(delay = 0.5, max_depth = 2, respect_robots = TRUE) |>
  cr_use_http() |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(
      url    = ctx$request$url,
      titulo = ctx$page |> rvest::html_element("h1") |> rvest::html_text2()
    ))
    ctx$enqueue_links(glob = "*/blog/*")
  }) |>
  cr_run() |>
  cr_collect()

resultado
#> # A tibble: 1 × 2
#>   url                 titulo
#>   <chr>               <chr>
#> 1 https://example.com Example Domain
```

## Design principles

- **Reproducibility first** — deduplicating, resumable request queue; runs are
  meant to be deterministic and re-runnable.
- **No heavy mandatory dependencies** — DuckDB, chromote and pdftools are
  optional (`Suggests`), loaded only when used.
- **Tidy & predictable** — `cr_*` verbs compose with the native pipe and always
  return tibbles.
- **A polite web citizen** — rate limiting and `robots.txt` awareness by
  default.

## Roadmap

| Milestone | Scope | Status |
|-----------|-------|--------|
| **M1** | Core: queue, HTTP, HTML handlers, dataset, cli logs | ✅ |
| **M2** | Sitemap & RSS discovery, robots.txt enforcement | ✅ |
| **M3** | PDF / document handlers (`pdftools`) | ✅ |
| **M4** | Headless browser backend (`chromote`) | ✅ |
| **M5** | RAG helpers (chunking, embeddings, export) | ✅ |

Next: persistent/resumable dataset backends (DuckDB, Parquet) and
parallel/autoscaled fetching.

## License

MIT © crawlee authors.
