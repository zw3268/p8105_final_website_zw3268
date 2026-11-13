# Helpers shared by every page: colours, the ggplot theme, placeholder figures,
# and the function that hands chart data to js/site.js.

site_paper = "#F5F8FB"
site_ink = "#0B1F3A"
site_muted = "#51607A"
site_rule = "#CBD6DF"
site_blue = "#0A5BC4"
site_blue_deep = "#062A5E"
site_blue_tint = "#DCE9F8"
site_teal = "#0E8F8A"

# data colours: lighter = lower, darker = higher (no red, yellow or purple)
site_low = "#A6E0D8"
site_mid = "#4B9CC9"
site_high = "#062A5E"
site_grey_cell = "#DDE3E8"

min_cases = 30

condition_levels = c("Heart failure", "Respiratory infection", "Kidney/UTI", "Stroke", "Sepsis")

theme_site = function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background = element_rect(fill = site_paper, color = NA),
      panel.background = element_rect(fill = site_paper, color = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = site_rule, linewidth = 0.3),
      axis.title = element_text(color = site_muted, size = rel(0.85)),
      axis.text = element_text(color = site_ink),
      plot.title = element_text(face = "bold", color = site_ink),
      plot.subtitle = element_text(color = site_muted),
      plot.caption = element_text(color = site_muted, hjust = 0),
      strip.text = element_text(color = site_ink, face = "bold", hjust = 0),
      legend.position = "bottom"
    )
}

# light mint (low) -> blue (typical) -> navy (high); readable by lightness alone
ratio_colour = function(ratio, limit = 2) {
  position = (log(pmin(pmax(ratio, 1 / limit), limit)) / log(limit) + 1) / 2
  scales::gradient_n_pal(c(site_low, site_mid, site_high))(position)
}

# An empty framed figure that says what will go there.
# TODO (team): replace each call with the real plot.
placeholder_fig = function(title, note = "Placeholder: replace with the real figure") {
  ggplot() +
    annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = "#E8EEF3", color = site_muted, linetype = "dashed", linewidth = 0.4) +
    annotate("text", x = 0.5, y = 0.58, label = title, color = site_ink, size = 5.2, fontface = "bold", lineheight = 1.1) +
    annotate("text", x = 0.5, y = 0.40, label = note, color = site_muted, size = 3.6) +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) +
    theme_void() +
    theme(plot.background = element_rect(fill = site_paper, color = NA))
}

# Writes the data for one scroll-driven chart into the page.
#   marks:  one row per (mark, state) with columns id, label, shape, r, w, h, state, x, y, fill, o
#   states: one row per state with columns readout, labels (list of tibbles), guides (list of tibbles)
scrolly_script = function(marks, states) {
  marks_nested =
    marks |>
    arrange(id, state) |>
    mutate(across(c(x, y), \(v) round(v, 1))) |>
    select(-state) |>
    nest(s = c(x, y, fill, o)) |>
    select(-id)

  json =
    jsonlite::toJSON(
      list(marks = marks_nested, states = states),
      dataframe = "rows",
      auto_unbox = TRUE,
      na = "null"
    )

  cat('<script type="application/json">', json, "</script>", sep = "\n")
}

demo_badge = '<span class="demo-badge">Demo</span>'
