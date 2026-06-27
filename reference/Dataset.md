# Dataset

An append-only structured store for the records produced by handlers via
`ctx$push_data()`. Records accumulate in memory and can be collected as
a single tibble with
[`cr_collect()`](https://strategicprojects.github.io/crawlee/reference/cr_collect.md).
Persistent backends (DuckDB, Parquet) are planned for a future release;
the `backend` argument is accepted now so that calling code remains
forward-compatible.

## Public fields

- `backend`:

  Name of the storage backend.

- `path`:

  Optional path for persistent backends.

## Methods

### Public methods

- [`Dataset$new()`](#method-Dataset-initialize)

- [`Dataset$push()`](#method-Dataset-push)

- [`Dataset$collect()`](#method-Dataset-collect)

- [`Dataset$count()`](#method-Dataset-count)

- [`Dataset$clone()`](#method-Dataset-clone)

------------------------------------------------------------------------

### `Dataset$new()`

Create a dataset.

#### Usage

    Dataset$new(backend = "memory", path = NULL)

#### Arguments

- `backend`:

  One of `"memory"`, `"duckdb"`, `"parquet"`.

- `path`:

  Optional path for persistent backends.

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

A tibble (empty if nothing was pushed).

------------------------------------------------------------------------

### `Dataset$count()`

Number of records (rows) stored.

#### Usage

    Dataset$count()

#### Returns

Integer scalar.

------------------------------------------------------------------------

### `Dataset$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Dataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
