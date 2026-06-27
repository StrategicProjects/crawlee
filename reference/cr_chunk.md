# Chunk text for retrieval-augmented generation

Splits documents into overlapping chunks suitable for embedding and
retrieval. Works on a character vector (one element per document) or on
a data frame, in which case the chunked column is replaced by `text` and
all other columns are carried along as per-chunk metadata.

## Usage

``` r
cr_chunk(
  data,
  text = NULL,
  size = 1000L,
  overlap = 200L,
  by = c("char", "word")
)
```

## Arguments

- data:

  A character vector or a data frame (e.g. the result of
  [`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md)).

- text:

  When `data` is a data frame, the (unquoted) column holding the text to
  chunk.

- size:

  Target chunk size, in characters (`by = "char"`) or words
  (`by = "word"`).

- overlap:

  Overlap between consecutive chunks, in the same unit as `size`. Must
  be smaller than `size`.

- by:

  `"char"` (default) or `"word"`.

## Value

A tibble with columns `doc_id`, `chunk_id` (within document), `chunk`
(global index), `text`, `n_chars`, plus any carried metadata.

## Examples

``` r
cr_chunk(c("um texto longo ...", "outro documento ..."),
         size = 10, overlap = 2, by = "word")
#> # A tibble: 2 × 5
#>   doc_id chunk_id text                n_chars chunk
#>    <int>    <int> <chr>                 <int> <int>
#> 1      1        1 um texto longo ...       18     1
#> 2      2        1 outro documento ...      19     2
```
