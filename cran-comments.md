## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Test environments

* local macOS, R 4.6.0
* GitHub Actions: ubuntu-latest (devel, release, oldrel-1),
  windows-latest (release), macOS-latest (release)

## Notes

* Possibly mis-spelled words flagged by the spell checker are technical terms
  (e.g. "Crawlee", "chromote", "DuckDB", "JSONL") and are listed in
  inst/WORDLIST.
* Functions that require network access, a headless browser (chromote) or
  optional packages are wrapped in \dontrun{} and the corresponding tests are
  skipped on CRAN / when offline / when the dependency is unavailable.
