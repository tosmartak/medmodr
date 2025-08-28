# CRAN submission: medmodr 0.1.0

## Test environments
- Local Windows 11 x64, R 4.4.3 (ucrt)
- GitHub Actions:
  - macOS 13, R release
  - macOS (arm64), R release
  - Ubuntu 22.04, R devel (release UA)
  - Ubuntu 22.04, R release
  - Ubuntu 22.04, R oldrel-1
- win-builder (R-devel, Windows): OK (see note below)
- R-hub v2 (GitHub Actions): OK on windows-latest, macos-13 / macos-latest, ubuntu-latest (release)

## R CMD check results
0 errors | 0 warnings | 1 note

- **NOTE (CRAN incoming feasibility):** *New submission*.  
  This is the first CRAN release of **medmodr**.

## Package characteristics
- Examples are fast and deterministic; longer examples wrapped in `\donttest{}` where needed.
- Tests pass on all platforms; any potentially long tests use `testthat::skip_on_cran()`.
- No internet access required.
- No files are written outside temporary directories.
- Vignettes are R Markdown (`.Rmd`) and build cleanly.

## Maintainer
Tosin Harold Akingbemisilu <tosinakingbemisilu@gmail.com>
