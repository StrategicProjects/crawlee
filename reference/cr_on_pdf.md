# Register a PDF handler

Registers a handler invoked for responses classified as PDF — by
`Content-Type` (`application/pdf`) or a `.pdf` URL. The handler context
adds PDF-specific helpers on top of the usual ones.

## Usage

``` r
cr_on_pdf(crawler, handler, label = NULL)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- handler:

  A function of one argument (the context). See **Context**.

- label:

  Optional handler label; `NULL` registers the default PDF handler.

## Value

The crawler, invisibly.

## Details

Requests carrying an explicit `label` are always routed to the handler
registered for that label (regardless of content kind); `label = NULL`
registers the default PDF handler.

## Context

In addition to the elements documented in
[`cr_on_html()`](https://strategicprojects.github.io/crawlee/reference/cr_on_html.md),
a PDF handler's context provides:

- `kind`:

  `"pdf"`.

- `pdf_text()`:

  Extract text per page (requires the pdftools package), returning a
  character vector.

- `body_raw()`:

  The raw PDF bytes.

- `save_body(key, ext)`:

  Persist the PDF to the
  [KeyValueStore](https://strategicprojects.github.io/crawlee/reference/KeyValueStore.md).

## Examples

``` r
if (FALSE) { # \dontrun{
crawler("https://www.example.gov/edital.pdf") |>
  cr_on_pdf(function(ctx) {
    texto <- ctx$pdf_text()
    ctx$push_data(list(url = ctx$request$url, n_paginas = length(texto)))
    ctx$save_body(ext = "pdf")
  }) |>
  cr_run()
} # }
```
