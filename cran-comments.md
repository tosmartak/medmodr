# CRAN submission: medmodr 0.1.0

## Test environments
- Local: Windows 11 x64, R 4.4.3 (ucrt)
- GitHub Actions:
  - macOS 13 (Intel), R release
  - macOS (arm64), R release
  - Ubuntu 22.04, R devel
  - Ubuntu 22.04, R release
  - Ubuntu 22.04, R oldrel-1
- win-builder (R-devel, Windows): OK
- R-hub v2 (GHA backends): OK
  - windows-latest (R release)
  - macos-13 / macos-latest (R release)
  - ubuntu-latest (R release)

## R CMD check results
0 errors | 0 warnings | 1 note

- **NOTE (CRAN incoming feasibility):** New submission.  
  This is the first CRAN release of **medmodr**.

## Package characteristics
- No external system requirements; pure R + listed Imports.
- Examples are fast; any longer ones wrapped in `\donttest{}`.
- Unit tests pass on all platforms; heavier tests use `testthat::skip_on_cran()`.
- No internet access required.
- No files written outside temp directories.
- Vignettes (R Markdown) build cleanly.
- Encoding is UTF-8; no non-ASCII in Title/Description.
- URLs (if any) validated with `urlchecker::url_check()`.

## Reverse dependencies
- None (new package).

## Maintainer
Tosin Harold Akingbemisilu <tosinakingbemisilu@gmail.com>
