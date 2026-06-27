# Normalise a URL into a canonical form

Produces a canonical representation of a URL used as the deduplication
key (`unique_key`) of a request. Normalisation lower-cases the scheme
and host, removes a trailing slash from the path, drops default ports
and sorts the query parameters so that semantically identical URLs
collapse to the same key.

## Usage

``` r
cr_normalize_url(url)
```

## Arguments

- url:

  A character vector of URLs.

## Value

A character vector of normalised URLs.

## Examples

``` r
cr_normalize_url("HTTPS://Example.com:443/a/?b=2&a=1")
#> [1] "https://example.com/a?a=1&b=2"
```
