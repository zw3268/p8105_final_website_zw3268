# Build the whole site. Run from the project root:  source("build.R")
#
# 1. render_site() knits every .Rmd in this folder (files starting with "_" are skipped).
# 2. The dashboard is rendered again on its own, because Build Website
#    replaces its flexdashboard format with the site's html_document.

rmarkdown::render_site()

rmarkdown::render("dashboard.Rmd", output_format = "flexdashboard::flex_dashboard")

# 3. Browsers keep styles.css and js/site.js for a while, so a visitor could see
#    new pages with an old stylesheet. Add the files' last-change time to their
#    addresses (styles.css?v=...), so every change is picked up on a normal reload.
stamp = function(file) format(file.mtime(file), "%Y%m%d%H%M%S")

for (page in setdiff(list.files(pattern = "\\.html$"), c("dashboard.html", "footer.html"))) {
  html = readLines(page, warn = FALSE)
  html = gsub('href="styles\\.css(\\?v=[0-9a-z]+)?"', paste0('href="styles.css?v=', stamp("styles.css"), '"'), html)
  html = gsub('src="js/site\\.js(\\?v=[0-9a-z]+)?"', paste0('src="js/site.js?v=', stamp("js/site.js"), '"'), html)
  writeLines(html, page)
}
