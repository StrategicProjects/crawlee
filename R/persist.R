#' Persist a crawl to a run directory (and resume it)
#'
#' Wires a crawler to a directory on disk so a crawl is **reproducible and
#' resumable**. It persists:
#'
#' * the request queue state (`queue.rds`) — pending requests, seen keys and
#'   handled count, checkpointed during [cr_run()];
#' * the dataset, via a persistent [Dataset] backend (`dataset.jsonl` or
#'   `dataset.duckdb`);
#' * binary content saved by `ctx$save_body()` (under `kv/`);
#' * a run manifest (`manifest.rds`, plus `manifest.json` when \pkg{jsonlite}
#'   is available).
#'
#' If a queue state already exists in `dir`, the crawl **resumes**: the saved
#' pending/seen/handled state is restored, so [cr_run()] continues where it left
#' off and already-fetched URLs are not fetched again.
#'
#' Call [cr_persist()] before [cr_run()]. For the `"duckdb"` backend, collect
#' results with [cr_collect()] before [cr_close()].
#'
#' @param crawler A [Crawler].
#' @param dir Run directory (created if needed).
#' @param dataset Dataset backend to use: `"jsonl"` (default), `"duckdb"` or
#'   `"memory"` (not persisted).
#'
#' @return The crawler, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' crawler("https://www.example.gov") |>
#'   cr_persist("runs/exemplo", dataset = "duckdb") |>
#'   cr_on_html(\(ctx) ctx$push_data(list(url = ctx$request$url))) |>
#'   cr_run() |>
#'   cr_collect()
#' # Re-running the same pipeline resumes from runs/exemplo.
#' }
cr_persist <- function(crawler, dir, dataset = c("jsonl", "duckdb", "memory")) {
  check_crawler(crawler)
  dataset <- match.arg(dataset)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  crawler$queue$set_path(file.path(dir, "queue.rds"))
  resumed <- crawler$queue$has_saved_state()
  if (resumed) crawler$queue$restore()

  if (dataset != "memory") {
    fname <- if (dataset == "jsonl") "dataset.jsonl" else "dataset.duckdb"
    crawler$dataset <- Dataset$new(backend = dataset, path = file.path(dir, fname))
  }

  crawler$set_options(store_dir = file.path(dir, "kv"))
  crawler$kv <- NULL
  crawler$set_persist_dir(dir)

  if (resumed) {
    cli::cli_alert_info(
      "Resuming from {.path {dir}}: {crawler$queue$pending_count()} pending, {crawler$queue$handled()} handled."
    )
  } else {
    cli::cli_alert_success("Persisting crawl to {.path {dir}}.")
  }
  invisible(crawler)
}

#' Release a crawler's resources
#'
#' Closes the headless browser session (if any) and the DuckDB connection (if
#' the dataset uses the duckdb backend). Collect results with [cr_collect()]
#' before closing a duckdb-backed crawl.
#'
#' @param crawler A [Crawler].
#'
#' @return The crawler, invisibly.
#' @export
cr_close <- function(crawler) {
  check_crawler(crawler)
  crawler$close()
  invisible(crawler)
}
