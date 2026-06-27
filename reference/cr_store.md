# Configure the key-value store for binary content

Sets the directory used by `ctx$save_body()` to persist raw responses
(PDFs, images, snapshots).

## Usage

``` r
cr_store(crawler, path)
```

## Arguments

- crawler:

  A
  [Crawler](https://strategicprojects.github.io/crawlee/reference/Crawler-class.md).

- path:

  Target directory. Created if it does not exist.

## Value

The crawler, invisibly.
