# Key-value store

A simple on-disk store for binary or text content keyed by an arbitrary
string (typically a URL). It backs `ctx$save_body()`, letting handlers
persist raw responses — PDFs, images, snapshots — alongside the
structured
[Dataset](https://strategicprojects.github.io/crawlee/reference/Dataset.md).
Keys are sanitised into safe file names.

## Public fields

- `dir`:

  Directory backing the store.

## Methods

### Public methods

- [`KeyValueStore$new()`](#method-KeyValueStore-initialize)

- [`KeyValueStore$set_raw()`](#method-KeyValueStore-set_raw)

- [`KeyValueStore$set_text()`](#method-KeyValueStore-set_text)

- [`KeyValueStore$get_raw()`](#method-KeyValueStore-get_raw)

- [`KeyValueStore$path_of()`](#method-KeyValueStore-path_of)

- [`KeyValueStore$keys()`](#method-KeyValueStore-keys)

- [`KeyValueStore$clone()`](#method-KeyValueStore-clone)

------------------------------------------------------------------------

### `KeyValueStore$new()`

Create a store.

#### Usage

    KeyValueStore$new(dir = NULL)

#### Arguments

- `dir`:

  Target directory; defaults to a `crawlee-store` folder in the
  session's temporary directory. Created if it does not exist.

------------------------------------------------------------------------

### `KeyValueStore$set_raw()`

Store raw bytes under `key`.

#### Usage

    KeyValueStore$set_raw(key, raw)

#### Arguments

- `key`:

  Character key.

- `raw`:

  A raw vector.

#### Returns

The file path, invisibly.

------------------------------------------------------------------------

### `KeyValueStore$set_text()`

Store text under `key`.

#### Usage

    KeyValueStore$set_text(key, text)

#### Arguments

- `key`:

  Character key.

- `text`:

  A character vector (written one element per line).

#### Returns

The file path, invisibly.

------------------------------------------------------------------------

### `KeyValueStore$get_raw()`

Retrieve raw bytes for `key`, or `NULL` if absent.

#### Usage

    KeyValueStore$get_raw(key)

#### Arguments

- `key`:

  Character key.

------------------------------------------------------------------------

### `KeyValueStore$path_of()`

Full path for `key` (whether or not it exists).

#### Usage

    KeyValueStore$path_of(key)

#### Arguments

- `key`:

  Character key.

------------------------------------------------------------------------

### `KeyValueStore$keys()`

List stored keys (file names).

#### Usage

    KeyValueStore$keys()

------------------------------------------------------------------------

### `KeyValueStore$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KeyValueStore$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
