# scripts/00_bootstrap.R
# Run from the repo root after cloning medmodr

# 0) Install dev tools once (safe to re-run)
pkgs <- c("usethis","devtools","roxygen2","testthat","pkgdown","styler","lintr","covr","rmarkdown")
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install)) install.packages(to_install)

# 1) create the package skeleton only if it doesn't exist, and silence prompts
if (!file.exists("DESCRIPTION")) {
  usethis::ui_silence({
    usethis::create_package(".", open = FALSE)
  })
}

# 2) Project niceties (idempotent, safe to re-run)
if (!file.exists("medmodr.Rproj")) usethis::use_rstudio()
usethis::use_readme_rmd()
usethis::use_mit_license("Tosin Harold Akingbemisilu")
usethis::use_news_md()
usethis::use_roxygen_md()
usethis::use_testthat(3)
usethis::use_git_ignore(c(".Rhistory", ".Rproj.user", ".DS_Store"))

# 3) Generate docs and run basic checks
devtools::document()
devtools::check()
