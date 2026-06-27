# Register an HTML handler

Registers a function called for each successfully fetched page whose
request carries the given `label` (or for all pages when
`label = NULL`). The handler receives a context object exposing the
parsed page and the actions `push_data()` and `enqueue_links()`.

## Usage

``` r
cr_on_html(crawler, handler, label = NULL)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- handler:

  A function of one argument (the context). See **Context**.

- label:

  Optional handler label. Requests enqueued with the same label are
  routed here; `NULL` registers the default handler.

## Value

The crawler, invisibly.

## Context

The `ctx` passed to a handler contains:

- `request`:

  The request list (`url`, `label`, `depth`, ...).

- `response`:

  The `httr2` response object.

- `page`:

  The parsed page (an `xml_document`) or `NULL`.

- `push_data(data)`:

  Append a record to the dataset.

- `enqueue_links(...)`:

  Discover and enqueue links from the page.

- `log`:

  Logging functions (`info`, `success`, `warn`, `error`).

## Examples

``` r
crawler("https://example.com") |>
  cr_on_html(function(ctx) {
    ctx$push_data(list(url = ctx$request$url))
    ctx$enqueue_links()
  })
```
