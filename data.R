## data.R -- build the analysis table (one row per country and year)
##
## WHAT THIS SCRIPT DOES (in plain words)
##   1. Reads how many blacklisted vessels were seen in each country each year.
##   2. Keeps countries with vessels in at least 5 different years (the sample rule).
##   3. Adds the EU card status for every country and year, worked out from the
##      list of official Commission decisions (boot/initial/data/carding_decisions.csv).
##   4. Adds the size of each country's fishing sector (the "control variable").
##   5. Saves the finished table and, for the thesis version, checks that it is
##      identical to the table used in the thesis.
##
## HOW CARD STATUS IS DECIDED
##   For each country and year we look at the last decision taken up to 31 December:
##     pre-identification (yellow card)  -> yellow
##     pre-identification revoked        -> green
##     identification / listing          -> red
##     delisting                         -> green
##   A country with no decisions is green. "Treatment" compares this year's status
##   with last year's: increase (stricter), decrease (less strict) or same.
##   Countries never carded get "no card".
##
## READS:  files named in config.R
## WRITES: config$paths$panel   (data/regression_data.csv for the thesis version)

library(tidyverse)
library(lubridate)

source("config.R")

for (p in c(config$paths$counts, config$paths$control, config$carding_file)) {
  if (!file.exists(p)) stop("Cannot find: ", p, ". See README, 'Updating with new data'.", call. = FALSE)
}

# --- 1. Vessel counts per country and year -------------------------------------------
counts <- read_csv(config$paths$counts, show_col_types = FALSE)   # EEZ, year, n_boats

# --- 2. Sample rule: vessels seen in at least `min_years_present` years --------------
eez_in_rule <- counts %>%
  count(EEZ, name = "years_present") %>%
  filter(years_present >= config$min_years_present) %>%
  pull(EEZ)

# A complete table: every country in every year. Years with no sighting get 0.
panel <- expand_grid(EEZ = eez_in_rule, year = config$years) %>%
  left_join(counts, by = c("EEZ", "year")) %>%
  mutate(n_boats = replace_na(n_boats, 0))

# --- 3. EU card status -----------------------------------------------------------------
decisions <- read_csv(config$carding_file, show_col_types = FALSE) %>%
  mutate(date = ym(date))                      # "2012-11" becomes 1 November 2012

status_after <- c("pre-identification"         = "yellow",
                  "pre-identification revoked" = "green",
                  "identification"             = "red",
                  "listing"                    = "red",
                  "delisting"                  = "green")
status_rank  <- c(green = 0, yellow = 1, red = 2)

# Status of one country on 31 December of one year
status_at_year_end <- function(ctry, yr) {
  events <- decisions %>%
    filter(country == ctry, date <= ymd(paste0(yr, "-12-31"))) %>%
    arrange(date)
  if (nrow(events) == 0) return("green")
  unname(status_after[tail(events$decision, 1)])
}

panel <- panel %>%
  mutate(
    ever_carded = EEZ %in% decisions$country,
    color       = map2_chr(EEZ, year,     status_at_year_end),
    color_prev  = map2_chr(EEZ, year - 1, status_at_year_end),
    treatment   = case_when(
      !ever_carded                                           ~ "no card",
      unname(status_rank[color]) > unname(status_rank[color_prev]) ~ "increase",
      unname(status_rank[color]) < unname(status_rank[color_prev]) ~ "decrease",
      TRUE                                                   ~ "same"
    )
  ) %>%
  select(-ever_carded, -color_prev)

# --- 4. Control variable: size of the fishing sector (tonnes per year) ---------------------
control <- read_csv(config$paths$control, show_col_types = FALSE)   # EEZ, year, control

panel <- panel %>% left_join(control, by = c("EEZ", "year"))

# Keep only countries with a complete, positive production series for ALL years.
# (Countries without production data, such as Taiwan or the High Seas, drop out.)
panel_final <- panel %>%
  group_by(EEZ) %>%
  filter(all(!is.na(control) & control > 0)) %>%
  ungroup() %>%
  select(EEZ, year, n_boats, treatment, color, control) %>%
  arrange(EEZ, year)

dropped <- setdiff(eez_in_rule, unique(panel_final$EEZ))
message("Countries passing the sample rule: ", length(eez_in_rule))
message("Dropped for missing production data: ", paste(dropped, collapse = ", "))
message("Final sample: ", n_distinct(panel_final$EEZ), " countries, ", nrow(panel_final), " rows")

dir.create(dirname(config$paths$panel), showWarnings = FALSE, recursive = TRUE)
write_csv(panel_final, config$paths$panel)

# --- 5. Check against the thesis (thesis version only) ----------------------------------------
if (config$version == "thesis") {
  ref <- read_csv(config$reference_file, show_col_types = FALSE) %>%
    select(EEZ, year, n_boats, treatment, color, control)
  cmp <- full_join(panel_final, ref, by = c("EEZ", "year"), suffix = c("_new", "_ref"))
  n_diff <- sum(
    is.na(cmp$n_boats_new) | is.na(cmp$n_boats_ref) |
    cmp$n_boats_new != cmp$n_boats_ref |
    cmp$treatment_new != cmp$treatment_ref |
    cmp$color_new != cmp$color_ref |
    abs(cmp$control_new - cmp$control_ref) > 1e-6,
    na.rm = TRUE
  )
  if (n_diff == 0) {
    message("OK: the rebuilt analysis table is identical to the table used in the thesis.")
  } else {
    warning(n_diff, " rows differ from the thesis table. Inspect 'cmp' to see which.")
  }
}
