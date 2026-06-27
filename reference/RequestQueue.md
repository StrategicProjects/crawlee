# Request queue

A deduplicating, FIFO-with-priority request queue, the in-memory engine
behind every
[`crawler()`](https://strategicprojects.github.io/crawlee/reference/crawler.md).
Requests are keyed by a normalised `unique_key` (see
[`cr_normalize_url()`](https://strategicprojects.github.io/crawlee/reference/cr_normalize_url.md))
so the same URL is never enqueued twice. The queue tracks which requests
have been handled, which makes a crawl resumable: a serialised queue can
be reloaded and the crawl continued.

This class is exported mainly for advanced use and introspection; most
users interact with it indirectly through the `cr_*` verbs.

## Methods

### Public methods

- [`RequestQueue$new()`](#method-RequestQueue-initialize)

- [`RequestQueue$add()`](#method-RequestQueue-add)

- [`RequestQueue$pop()`](#method-RequestQueue-pop)

- [`RequestQueue$reschedule()`](#method-RequestQueue-reschedule)

- [`RequestQueue$mark_handled()`](#method-RequestQueue-mark_handled)

- [`RequestQueue$pending_count()`](#method-RequestQueue-pending_count)

- [`RequestQueue$handled()`](#method-RequestQueue-handled)

- [`RequestQueue$is_empty()`](#method-RequestQueue-is_empty)

- [`RequestQueue$clone()`](#method-RequestQueue-clone)

------------------------------------------------------------------------

### `RequestQueue$new()`

Create a new, empty request queue.

#### Usage

    RequestQueue$new()

------------------------------------------------------------------------

### `RequestQueue$add()`

Add a request to the queue.

#### Usage

    RequestQueue$add(
      url,
      label = NULL,
      depth = 0L,
      user_data = list(),
      method = "GET",
      force_unique = FALSE
    )

#### Arguments

- `url`:

  Character scalar URL.

- `label`:

  Optional handler label routing this request.

- `depth`:

  Integer crawl depth (distance from a start URL).

- `user_data`:

  Optional named list carried with the request.

- `method`:

  HTTP method, defaults to `"GET"`.

- `force_unique`:

  If `TRUE`, skip deduplication.

#### Returns

Invisibly, `TRUE` if added, `FALSE` if a duplicate.

------------------------------------------------------------------------

### `RequestQueue$pop()`

Pop the next request from the front of the queue.

#### Usage

    RequestQueue$pop()

#### Returns

A request list, or `NULL` when the queue is empty.

------------------------------------------------------------------------

### `RequestQueue$reschedule()`

Re-queue a request for another attempt, incrementing its retry counter.

#### Usage

    RequestQueue$reschedule(request)

#### Arguments

- `request`:

  A request list previously obtained from `pop()`.

------------------------------------------------------------------------

### `RequestQueue$mark_handled()`

Mark a request as successfully handled.

#### Usage

    RequestQueue$mark_handled()

------------------------------------------------------------------------

### `RequestQueue$pending_count()`

Number of requests waiting to be processed.

#### Usage

    RequestQueue$pending_count()

#### Returns

Integer scalar.

------------------------------------------------------------------------

### `RequestQueue$handled()`

Number of requests handled so far.

#### Usage

    RequestQueue$handled()

#### Returns

Integer scalar.

------------------------------------------------------------------------

### `RequestQueue$is_empty()`

Whether the queue has no pending requests.

#### Usage

    RequestQueue$is_empty()

#### Returns

Logical scalar.

------------------------------------------------------------------------

### `RequestQueue$clone()`

The objects of this class are cloneable with this method.

#### Usage

    RequestQueue$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
