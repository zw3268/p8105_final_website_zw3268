# p8105_final_website_zw3268

Website template for the P8105 (Fall 2026) final project, *Same Diagnosis, Different Bills? Variation in Hospital Charges and Estimated Costs for Five Common Conditions in New York, 2023*.

Live preview: https://zw3268.github.io/p8105_final_website_zw3268/

**This is a design template.** Figures and numbers marked "Demo" are simulated, and most text is placeholder. Search the `.Rmd` files for `TODO` to find everything that needs real content.

## Build

Open `p8105_final_website_zw3268.Rproj` in RStudio and run:

```r
source("build.R")
```

This knits every page and then renders the dashboard separately. Packages used: tidyverse, rmarkdown, flexdashboard, plotly, leaflet, jsonlite, scales.

## Layout

| Path | What it is |
|---|---|
| `index.Rmd` | Home page: nine full-screen sections, three with scroll-driven charts |
| `q1_gaps.Rmd`, `q2_adjusted.Rmd`, `q3_consistency.Rmd` | One page per research question |
| `heart_failure.Rmd`, `respiratory.Rmd`, `kidney_uti.Rmd`, `stroke.Rmd`, `sepsis.Rmd` | One page per condition; all five use `_condition.Rmd` |
| `dashboard.Rmd` | flexdashboard: overview, rankings, funnel plot, map, cost estimator |
| `data.Rmd`, `eda.Rmd`, `report.Rmd`, `team.Rmd` | Data and methods, exploratory analysis, full report, team |
| `_site.yml`, `footer.html` | Navigation and footer |
| `styles.css`, `dashboard.css` | All visual styling; colours are variables at the top of `styles.css` |
| `js/site.js` | Scroll behaviour (no libraries). Chart data is written into the page by R |
| `R/site_helpers.R` | Colours, `theme_site()`, `placeholder_fig()`, `scrolly_script()` |
| `R/make_demo_data.R` | Creates the simulated files in `data/` |
| `fonts/` | Open-source fonts (see `fonts/README.md`) |

## Replacing demo content with real results

1. Put the real output files in `data/` and change the `read_csv()` paths at the top of `index.Rmd`, `dashboard.Rmd` and `q1_gaps.Rmd`.
2. Replace each `placeholder_fig("...")` call with the real plot; add `+ theme_site()` so it matches.
3. Replace placeholder text and remove the "Demo" badges.
4. Run `source("build.R")`.
