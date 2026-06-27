# Internal logging helpers built on top of {cli}.
#
# All user-facing logging in crawlee flows through these helpers so that
# verbosity can be controlled centrally via the crawler's `log_level` option.
# Levels, from most to least verbose: "debug" < "info" < "warn" < "error" <
# "off".

log_levels <- c(debug = 1L, info = 2L, warn = 3L, error = 4L, off = 5L)

#' Should a message at `level` be emitted given the configured `threshold`?
#' @noRd
log_enabled <- function(level, threshold) {
  log_levels[[level]] >= log_levels[[threshold]]
}

#' Build a logger closure bound to a verbosity threshold
#'
#' @param threshold One of `"debug"`, `"info"`, `"warn"`, `"error"`, `"off"`.
#'
#' @return A list of logging functions used internally and exposed to handlers
#'   via `ctx$log`.
#' @keywords internal
#' @noRd
make_logger <- function(threshold = "info") {
  threshold <- match.arg(threshold, names(log_levels))
  # Each logger forwards `.envir` so that {cli}/{glue} interpolation in the
  # message resolves against the *caller's* environment, not this closure.
  list(
    debug = function(..., .envir = parent.frame()) {
      if (log_enabled("debug", threshold)) {
        cli::cli_text(paste0("{.field [debug]} ", ...), .envir = .envir)
      }
    },
    info = function(..., .envir = parent.frame()) {
      if (log_enabled("info", threshold)) {
        cli::cli_alert_info(paste0(...), .envir = .envir)
      }
    },
    success = function(..., .envir = parent.frame()) {
      if (log_enabled("info", threshold)) {
        cli::cli_alert_success(paste0(...), .envir = .envir)
      }
    },
    warn = function(..., .envir = parent.frame()) {
      if (log_enabled("warn", threshold)) {
        cli::cli_alert_warning(paste0(...), .envir = .envir)
      }
    },
    error = function(..., .envir = parent.frame()) {
      if (log_enabled("error", threshold)) {
        cli::cli_alert_danger(paste0(...), .envir = .envir)
      }
    }
  )
}
