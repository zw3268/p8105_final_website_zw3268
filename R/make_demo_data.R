# Simulated data used ONLY to design the site. Nothing here is a result.
# Column names follow data/sparcs_clean.csv from the team's data pipeline
# (hosp_id, facility_name, hospital_service_area, ownership, latitude,
# longitude, condition, charges, costs). The file names mirror the team plan:
#   hospital_medians.csv  (Q1)   hospital_adjusted.csv (Q2)   estimator_grid.csv
# To switch to real data: point the pages at the real files and re-knit.
#
# Run from the project root:  source("R/make_demo_data.R")

library(tidyverse)

set.seed(8105)

service_areas =
  tibble(
    hospital_service_area = c("New York City", "Long Island", "Hudson Valley", "Capital/Adirond",
                              "Central NY", "Finger Lakes", "Western NY", "Southern Tier"),
    lat0 = c(40.74, 40.79, 41.35, 43.20, 43.05, 43.10, 42.90, 42.15),
    lon0 = c(-73.93, -73.20, -73.95, -73.80, -76.10, -77.50, -78.80, -76.20),
    n_hosp = c(52, 22, 26, 22, 18, 16, 22, 14),
    spread = c(0.07, 0.15, 0.20, 0.40, 0.25, 0.25, 0.22, 0.40)
  )

demo_hospitals =
  service_areas |>
  uncount(n_hosp) |>
  mutate(
    hosp_id = 1000 + row_number(),
    facility_name = str_c("Demo Hospital ", row_number()),
    ownership = sample(c("Nonprofit", "Public"), n(), replace = TRUE, prob = c(0.86, 0.14)),
    latitude = lat0 + rnorm(n(), sd = spread),
    longitude = lon0 + rnorm(n(), sd = spread),
    hosp_effect = rnorm(n(), sd = 0.38),
    markup = rlnorm(n(), meanlog = log(3), sdlog = 0.35),
    size = rlnorm(n(), meanlog = 0, sdlog = 0.9)
  ) |>
  select(-lat0, -lon0, -spread)

demo_conditions =
  tibble(
    condition = c("Heart failure", "Respiratory infection", "Kidney/UTI", "Stroke", "Sepsis"),
    base_charges = c(38000, 41000, 27000, 55000, 62000),
    base_n = c(310, 185, 160, 140, 690)
  )

hospital_medians =
  crossing(demo_hospitals, demo_conditions) |>
  mutate(
    n_stays = rpois(n(), lambda = base_n * size),
    cond_effect = rnorm(n(), sd = 0.20),
    median_charges = base_charges * exp(hosp_effect + cond_effect),
    se = 0.9 / sqrt(pmax(n_stays, 1)),
    charges_lo = median_charges * exp(-1.96 * se),
    charges_hi = median_charges * exp(1.96 * se),
    median_costs = median_charges / markup,
    costs_lo = charges_lo / markup,
    costs_hi = charges_hi / markup
  ) |>
  filter(n_stays > 0)

hospital_adjusted =
  hospital_medians |>
  filter(n_stays >= 30) |>
  group_by(condition) |>
  mutate(
    unadjusted_ratio = median_charges / median(median_charges),
    adjusted_ratio = exp(0.85 * hosp_effect + rnorm(n(), sd = 0.16))
  ) |>
  ungroup() |>
  select(hosp_id, condition, unadjusted_ratio, adjusted_ratio)

estimator_grid =
  crossing(
    demo_conditions,
    severity = c("Minor", "Moderate", "Major", "Extreme"),
    age_group = c("18 to 29", "30 to 49", "50 to 69", "70 or Older"),
    los = 1:30
  ) |>
  mutate(
    severity_bump = case_when(
      severity == "Minor" ~ 0.75,
      severity == "Moderate" ~ 1,
      severity == "Major" ~ 1.35,
      severity == "Extreme" ~ 2.1
    ),
    age_bump = case_when(
      age_group == "18 to 29" ~ 0.92,
      age_group == "30 to 49" ~ 0.97,
      age_group == "50 to 69" ~ 1,
      age_group == "70 or Older" ~ 1.04
    ),
    predicted_charges = base_charges * severity_bump * age_bump * (0.35 + 0.13 * los)
  ) |>
  select(condition, severity, age_group, los, predicted_charges)

hospital_medians |>
  mutate(markup = median_charges / median_costs) |>
  select(
    hosp_id, facility_name, hospital_service_area, ownership, latitude, longitude,
    condition, n_stays, median_charges, charges_lo, charges_hi,
    median_costs, costs_lo, costs_hi, markup
  ) |>
  mutate(across(where(is.double), \(x) round(x, 3))) |>
  write_csv("data/demo_hospital_medians.csv")

hospital_adjusted |>
  mutate(across(where(is.double), \(x) round(x, 4))) |>
  write_csv("data/demo_hospital_adjusted.csv")

estimator_grid |>
  mutate(predicted_charges = round(predicted_charges)) |>
  write_csv("data/demo_estimator_grid.csv")
