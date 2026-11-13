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

## Data files the site reads

The analysis code lives in `analysis/` in the main repository and only writes CSV files; the pages here only read those files. Simulated versions (`data/demo_*.csv`) are used until the real ones are ready. Column names follow the team's analysis files (`_low` / `_high` for intervals, `region` for the hospital service area); `latitude` and `longitude` come from `sparcs_clean.csv` and are needed for the map only:

| File | One row per | Columns |
|---|---|---|
| `hospital_medians.csv` | hospital and condition | `hosp_id`, `facility_name`, `region`, `ownership`, `latitude`, `longitude`, `condition`, `n_stays`, `median_charges`, `charges_low`, `charges_high`, `median_costs`, `costs_low`, `costs_high` (cost interval optional), `markup` |
| `hospital_adjusted.csv` | hospital and condition | `hosp_id`, `condition`, `unadjusted_ratio`, `adjusted_ratio` |
| `estimator_grid.csv` | hospital, condition and patient profile | `hosp_id`, `facility_name`, `region`, `ownership`, `condition`, `profile`, `severity`, `age_group`, `los`, `predicted_charges` |

Conditions appear everywhere in this order: Heart failure, Respiratory infection, Stroke, Sepsis, Kidney/UTI (set once in `R/site_helpers.R`).

"The typical hospital" on the site means the median of the hospital medians for a condition, not the median of all stays.

## Replacing demo content with real results

1. Put the real output files in `data/` and change the `read_csv()` paths at the top of `index.Rmd`, `dashboard.Rmd` and `q1_gaps.Rmd`.
2. Replace each `placeholder_fig("...")` call with the real plot; add `+ theme_site()` so it matches.
3. Replace placeholder text and remove the "Demo" badges.
4. Run `source("build.R")`.
