# Crawler

The stateful object at the centre of crawlee. It holds the request
queue, the dataset, the registered handlers and the run configuration.
You will rarely create one with `Crawler$new()` directly; use
[`crawler()`](https://strategicprojects.github.io/crawlee/reference/crawler.md)
and the `cr_*` verbs, which return the crawler invisibly so they compose
with the native pipe (`|>`).

## Public fields

- `options`:

  Named list of run options.

- `queue`:

  The
  [RequestQueue](https://strategicprojects.github.io/crawlee/reference/RequestQueue.md).

- `dataset`:

  The
  [Dataset](https://strategicprojects.github.io/crawlee/reference/Dataset.md).

- `handlers`:

  Named list of label-specific handlers.

- `defaults`:

  Named list of default handlers by content kind (`html`, `pdf`, `any`).

- `kv`:

  Lazily-created
  [KeyValueStore](https://strategicprojects.github.io/crawlee/reference/KeyValueStore.md)
  for binary content.

- `mode`:

  Fetch mode, `"http"` (default) or `"browser"`.

- `stats`:

  Named list of run statistics.

## Methods

### Public methods

- [`Crawler$new()`](#method-Crawler-initialize)

- [`Crawler$set_options()`](#method-Crawler-set_options)

- [`Crawler$set_handler()`](#method-Crawler-set_handler)

- [`Crawler$get_kv()`](#method-Crawler-get_kv)

- [`Crawler$run()`](#method-Crawler-run)

- [`Crawler$clone()`](#method-Crawler-clone)

------------------------------------------------------------------------

### `Crawler$new()`

Create a crawler.

#### Usage

    Crawler$new(start_urls = character(), ...)

#### Arguments

- `start_urls`:

  Character vector of seed URLs.

- `...`:

  Options forwarded to
  [`cr_options()`](https://strategicprojects.github.io/crawlee/reference/cr_options.md).

------------------------------------------------------------------------

### `Crawler$set_options()`

Update one or more options.

#### Usage

    Crawler$set_options(...)

#### Arguments

- `...`:

  Named options to override.

------------------------------------------------------------------------

### `Crawler$set_handler()`

Register a handler for a content label or kind.

#### Usage

    Crawler$set_handler(handler, label = NULL, kind = "html")

#### Arguments

- `handler`:

  A function of one argument, the handler context.

- `label`:

  Optional label; `NULL` registers a default handler.

- `kind`:

  Content kind for the default handler (`"html"`, `"pdf"`, `"any"`).
  Ignored when `label` is given.

------------------------------------------------------------------------

### `Crawler$get_kv()`

Get (lazily creating) the key-value store for binaries.

#### Usage

    Crawler$get_kv()

#### Returns

A
[KeyValueStore](https://strategicprojects.github.io/crawlee/reference/KeyValueStore.md).

------------------------------------------------------------------------

### `Crawler$run()`

Run the crawl until the queue drains or a limit is hit.

#### Usage

    Crawler$run()

------------------------------------------------------------------------

### `Crawler$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Crawler$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
