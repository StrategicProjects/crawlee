# Dataset

An append-only structured store for the records produced by handlers via
`ctx$push_data()`. Three backends are available:

- `"memory"` (default): records accumulate in memory.

- `"jsonl"`: each record is appended as a line of JSON to a file —
  schema-flexible, append-only and resumable across runs.

- `"duckdb"`: records are appended to a table in a DuckDB database,
  ready for SQL analysis.

Collect everything as a single tibble with
[`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md).

## Public fields

- `backend`:

  Name of the storage backend.

- `path`:

  Path for persistent backends.

## Methods

### Public methods

- [`Dataset$new()`](#method-Dataset-initialize)

- [`Dataset$push()`](#method-Dataset-push)

- [`Dataset$collect()`](#method-Dataset-collect)

- [`Dataset$count()`](#method-Dataset-count)

- [`Dataset$close()`](#method-Dataset-close)

- [`Dataset$clone()`](#method-Dataset-clone)

------------------------------------------------------------------------

### `Dataset$new()`

Create a dataset.

#### Usage

    Dataset$new(backend = "memory", path = NULL, table = "dataset")

#### Arguments

- `backend`:

  One of `"memory"`, `"jsonl"`, `"duckdb"`.

- `path`:

  File (jsonl) or database (duckdb) path; required for the persistent
  backends.

- `table`:

  Table name for the `"duckdb"` backend.

------------------------------------------------------------------------

### `Dataset$push()`

Append one or more records.

#### Usage

    Dataset$push(data)

#### Arguments

- `data`:

  A data frame / tibble or a named list (coerced to one row).

------------------------------------------------------------------------

### `Dataset$collect()`

Collect all records as a single tibble.

#### Usage

    Dataset$collect()

#### Returns

A tibble (empty if nothing was stored).

------------------------------------------------------------------------

### `Dataset$count()`

Number of records (rows) stored.

#### Usage

    Dataset$count()

#### Returns

Integer scalar.

------------------------------------------------------------------------

### `Dataset$close()`

Close any open backend resources (e.g. the DuckDB connection). Safe to
call multiple times.

#### Usage

    Dataset$close()

------------------------------------------------------------------------

### `Dataset$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Dataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
