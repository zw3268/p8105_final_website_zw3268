# Build the whole site. Run from the project root:  source("build.R")
#
# 1. render_site() knits every .Rmd in this folder (files starting with "_" are skipped).
# 2. The dashboard is rendered again on its own, because Build Website
#    replaces its flexdashboard format with the site's html_document.

rmarkdown::render_site()

rmarkdown::render("dashboard.Rmd", output_format = "flexdashboard::flex_dashboard")
