## control_updated.R -- build an UPDATED fishing-sector control variable
##
## WHY
##   The thesis control for 2023-2024 (and a few 2022 values) was projected from
##   OECD-FAO growth rates, because observed data did not exist yet. FAO's March
##   2026 FishStat release contains OBSERVED production for 1950-2024, so no
##   projections are needed any more. (Newer OECD-FAO Outlooks do not help here:
##   they project the FUTURE, not 2023-2024.)
##
## WHAT YOU NEED TO PREPARE (not on GitHub)
##   data_raw/fishstat_production.csv  with three columns:
##       country, year, tonnes
##   = total production of aquatic animals (capture + aquaculture) per country
##   and year, in tonnes live weight, from FAO FishStat (global production).
##   The FAO download has its own layout; reshape it to these three columns first.
##
## WHAT THE SCRIPT DOES
##   1. Matches FAO country names to the EEZ names used in this project
##      (boot/initial/data/eez_to_fishstat_names.csv -- edit this if names differ).
##   2. Adds up production per EEZ and year.
##   3. Saves boot/initial/data/control_updated.csv, used when config version = "updated".
##   4. Writes a table comparing the new values with the thesis values for 2017-2022,
##      so you can see how much the numbers were revised.

library(tidyverse)

source("config.R")

prod_file <- "data_raw/fishstat_production.csv"
if (!file.exists(prod_file)) stop("Cannot find ", prod_file, call. = FALSE)

production <- read_csv(prod_file, show_col_types = FALSE)
names_map  <- read_csv("boot/initial/data/eez_to_fishstat_names.csv", show_col_types = FALSE)

# Report names that could not be matched, so you can fix the name table
unmatched <- names_map %>% filter(!fishstat_country %in% production$country)
if (nrow(unmatched) > 0) {
  message("No FAO data found for: ", paste(unmatched$EEZ, collapse = ", "),
          "\nEdit boot/initial/data/eez_to_fishstat_names.csv if the FAO name is spelled differently.")
}

control_updated <- names_map %>%
  inner_join(production, by = c("fishstat_country" = "country")) %>%
  filter(year %in% config$years) %>%
  group_by(EEZ, year) %>%
  summarise(control = sum(tonnes, na.rm = TRUE), .groups = "drop")

write_csv(control_updated, "boot/initial/data/control_updated.csv")

# Compare with the thesis version
thesis_control <- read_csv("boot/initial/data/control_thesis_version.csv", show_col_types = FALSE)
revisions <- inner_join(thesis_control, control_updated, by = c("EEZ", "year"),
                        suffix = c("_thesis", "_updated")) %>%
  mutate(percent_difference = 100 * (control_updated - control_thesis) / control_thesis)

dir.create("output/updated", recursive = TRUE, showWarnings = FALSE)
write_csv(revisions, "output/updated/control_revisions.csv")
message("Saved control_updated.csv. Largest absolute difference vs thesis values: ",
        round(max(abs(revisions$percent_difference), na.rm = TRUE), 1), "%")
