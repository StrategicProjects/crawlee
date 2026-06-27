# Attach embeddings to chunks

Adds an `embedding` list-column by applying a user-supplied, provider-
agnostic embedding function in batches. crawlee never calls an external
service itself: you pass `embed_fn`, which receives a character vector
and returns either a numeric matrix (one row per input) or a list of
numeric vectors. This keeps you free to use any provider or a local
model.

## Usage

``` r
cr_embed(data, embed_fn, text_col = "text", batch_size = 32L)
```

## Arguments

- data:

  A data frame with a text column (e.g. from
  [`cr_chunk()`](https://strategicprojects.github.io/crawlee/reference/cr_chunk.md)).

- embed_fn:

  A function mapping a character vector to a numeric matrix (rows =
  inputs) or a list of numeric vectors.

- text_col:

  Name of the text column. Defaults to `"text"`.

- batch_size:

  Number of texts per call to `embed_fn`.

## Value

`data` with an added `embedding` list-column.

## Examples

``` r
chunks <- cr_chunk(c("a b c d", "e f g h"), size = 2, overlap = 0, by = "word")
fake_embed <- function(x) matrix(nchar(x), nrow = length(x), ncol = 1)
cr_embed(chunks, fake_embed)
#> # A tibble: 4 × 6
#>   doc_id chunk_id text  n_chars chunk embedding
#>    <int>    <int> <chr>   <int> <int> <list>   
#> 1      1        1 a b         3     1 <dbl [1]>
#> 2      1        2 c d         3     2 <dbl [1]>
#> 3      2        1 e f         3     3 <dbl [1]>
#> 4      2        2 g h         3     4 <dbl [1]>
```
