# Simulated data used ONLY to design the site. Nothing here is a result.
# Column names follow data/sparcs_clean.csv from the team's data pipeline
# (hosp_id, facility_name, region, ownership, latitude,
# longitude, condition, charges, costs). The file names mirror the team plan:
#   hospital_medians.csv  (Q1)   hospital_adjusted.csv (Q2)   estimator_grid.csv
# estimator_grid has one row per hospital, condition and patient profile.
# To switch to real data: point the pages at the real files and re-knit.
#
# Run from the project root:  source("R/make_demo_data.R")

library(tidyverse)

set.seed(8105)

service_areas =
  tibble(
    region = c("New York City", "Long Island", "Hudson Valley", "Capital/Adirond",
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
    condition = c("Heart failure", "Respiratory infection", "Stroke", "Sepsis", "Kidney/UTI"),
    base_charges = c(38000, 41000, 55000, 62000, 27000),
    base_n = c(310, 185, 140, 690, 160)
  )

hospital_medians =
  crossing(demo_hospitals, demo_conditions) |>
  mutate(
    n_stays = rpois(n(), lambda = base_n * size),
    cond_effect = rnorm(n(), sd = 0.20),
    median_charges = base_charges * exp(hosp_effect + cond_effect),
    se = 0.9 / sqrt(pmax(n_stays, 1)),
    charges_low = median_charges * exp(-1.96 * se),
    charges_high = median_charges * exp(1.96 * se),
    median_costs = median_charges / markup,
    costs_low = charges_low / markup,
    costs_high = charges_high / markup
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

# The estimator: what each hospital would charge the SAME typical patient.
# One row per hospital x condition x patient profile.
patient_profiles =
  tibble(
    severity = c("Moderate", "Major", "Extreme", "Moderate"),
    age_group = c("70 or Older", "70 or Older", "70 or Older", "50 to 69"),
    los = c(4, 6, 10, 4),
    severity_bump = c(1, 1.35, 2.1, 1),
    age_bump = c(1.04, 1.04, 1.04, 1)
  ) |>
  mutate(profile = str_c(severity, " severity, ", str_to_lower(age_group), ", ", los, "-day stay"))

estimator_grid =
  hospital_medians |>
  filter(n_stays >= 30) |>
  select(hosp_id, facility_name, region, ownership, condition, base_charges, hosp_effect) |>
  crossing(patient_profiles) |>
  mutate(
    predicted_charges =
      base_charges * severity_bump * age_bump * (0.35 + 0.13 * los) *
      exp(1.25 * hosp_effect + rnorm(n(), sd = 0.12))
  ) |>
  select(hosp_id, facility_name, region, ownership, condition, profile, severity, age_group, los, predicted_charges)

hospital_medians |>
  mutate(markup = median_charges / median_costs) |>
  select(
    hosp_id, facility_name, region, ownership, latitude, longitude,
    condition, n_stays, median_charges, charges_low, charges_high,
    median_costs, costs_low, costs_high, markup
  ) |>
  mutate(across(where(is.double), \(x) round(x, 3))) |>
  write_csv("data/demo_hospital_medians.csv")

hospital_adjusted |>
  mutate(across(where(is.double), \(x) round(x, 4))) |>
  write_csv("data/demo_hospital_adjusted.csv")

estimator_grid |>
  mutate(predicted_charges = round(predicted_charges)) |>
  write_csv("data/demo_estimator_grid.csv")
