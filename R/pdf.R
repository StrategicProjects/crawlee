#' Register a PDF handler
#'
#' Registers a handler invoked for responses classified as PDF — by
#' `Content-Type` (`application/pdf`) or a `.pdf` URL. The handler context adds
#' PDF-specific helpers on top of the usual ones.
#'
#' Requests carrying an explicit `label` are always routed to the handler
#' registered for that label (regardless of content kind); `label = NULL`
#' registers the default PDF handler.
#'
#' @param crawler A [Crawler].
#' @param handler A function of one argument (the context). See **Context**.
#' @param label Optional handler label; `NULL` registers the default PDF
#'   handler.
#'
#' @section Context:
#' In addition to the elements documented in [cr_on_html()], a PDF handler's
#' context provides:
#' \describe{
#'   \item{`kind`}{`"pdf"`.}
#'   \item{`pdf_text()`}{Extract text per page (requires the \pkg{pdftools}
#'     package), returning a character vector.}
#'   \item{`body_raw()`}{The raw PDF bytes.}
#'   \item{`save_body(key, ext)`}{Persist the PDF to the [KeyValueStore].}
#' }
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' crawler("https://www.example.gov/edital.pdf") |>
#'   cr_on_pdf(function(ctx) {
#'     texto <- ctx$pdf_text()
#'     ctx$push_data(list(url = ctx$request$url, n_paginas = length(texto)))
#'     ctx$save_body(ext = "pdf")
#'   }) |>
#'   cr_run()
#' }
cr_on_pdf <- function(crawler, handler, label = NULL) {
  check_crawler(crawler)
  if (!is.function(handler)) {
    cli::cli_abort("{.arg handler} must be a function of one argument.")
  }
  crawler$set_handler(handler, label = label, kind = "pdf")
  invisible(crawler)
}

#' Configure the key-value store for binary content
#'
#' Sets the directory used by `ctx$save_body()` to persist raw responses (PDFs,
#' images, snapshots).
#'
#' @param crawler A [Crawler].
#' @param path Target directory. Created if it does not exist.
#'
#' @return The crawler, invisibly.
#' @export
cr_store <- function(crawler, path) {
  check_crawler(crawler)
  crawler$set_options(store_dir = path)
  crawler$kv <- KeyValueStore$new(path)
  invisible(crawler)
}
