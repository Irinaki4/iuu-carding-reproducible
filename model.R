## model.R -- run the four regression models
##
## THE QUESTION
##   Is a change in a country's EU card status (or its card colour) linked to a
##   change in the number of blacklisted vessels detected in its waters?
##
## THE FOUR MODELS
##   Model 1 "Treatment (All)":    does a stricter/looser card relate to vessel numbers?  All countries.
##   Model 2 "Treatment (Subset)": same question, but only the countries whose card changed.
##   Model 3 "Color (All)":        does the card colour (yellow vs green) relate to vessel numbers?  All countries.
##   Model 4 "Color (Subset)":     same, only the countries whose card changed.
##
## TWO IDEAS YOU NEED TO EXPLAIN IN AN INTERVIEW
##   Fixed effects: "| EEZ + year" gives every country its own baseline level and
##     every year its own baseline level. So the models compare a country with
##     ITSELF over time, and remove effects that hit all countries in one year.
##   Standard errors: they measure how uncertain each estimate is.
##     "classical"  assumes all observations are independent (simple, optimistic).
##     "clustered"  allows observations of the SAME country to be related to each
##                  other (more cautious, usually preferred for panel data).
##
## WHY TWO SETS OF MODELS?
##   thesis_as_run : exactly the thesis table. Model 1 used clustered errors, Models 2-4
##                   used classical errors (the thesis text says all were clustered;
##                   the submitted table shows otherwise).
##   clustered     : all four models with clustered errors, as the thesis text describes.
##
## READS:  the analysis table (config$paths$panel, from data.R)
## WRITES: the fitted models (config$paths$models)

library(tidyverse)
library(fixest)   # runs regressions with fixed effects quickly

source("config.R")

dir.create(dirname(config$paths$models), showWarnings = FALSE, recursive = TRUE)

# --- 1. Read the data and choose the comparison categories -----------------------------
# factor(..., levels = ...) fixes the ORDER of the categories. The first level is the
# "baseline" that the others are compared with.
reg_data <- read_csv(config$paths$panel, show_col_types = FALSE) %>%
  mutate(
    treatment = factor(treatment, levels = c("no card", "same", "increase", "decrease")),
    color     = factor(color,     levels = c("green", "yellow", "red"))
  )

# --- 2. The subset used in Models 2 and 4 -----------------------------------------------
# Countries whose card status changed at least once in the study period.
# (The thesis text calls them "previously carded countries", but the code used
# exactly these countries.)
changed_card <- reg_data %>%
  filter(treatment %in% c("increase", "decrease")) %>%
  distinct(EEZ) %>%
  pull(EEZ)

subset_data <- reg_data %>% filter(EEZ %in% changed_card)

# In this subset every country has a card, so "same", "increase" and "decrease"
# add up to 1 for every row and one of them cannot be estimated. The thesis left
# out "same", so "same" is the baseline here: the results read as
# "compared with years in which the card did not change".
subset_treat <- subset_data %>%
  mutate(treatment = relevel(droplevels(treatment), ref = "same"))

# --- 3. Safety check: sample sizes must match the thesis (thesis version only) --------
if (config$version == "thesis") {
  stopifnot(nrow(reg_data) == 336)     # 42 countries x 8 years
  stopifnot(nrow(subset_data) == 72)   # 9 countries x 8 years
}

# --- 4. Fit the models --------------------------------------------------------------------
# Formula: number of vessels ~ card variable + fishing sector size | country + year
# fixest drops variables it cannot estimate (for example "decrease" in Model 1) and
# prints a note. That is expected.
#   vcov = "iid"  -> classical standard errors
#   vcov = ~EEZ   -> standard errors clustered by country
fit_all <- function(vcov_model1, vcov_others) {
  list(
    "Treatment (All)"    = feols(n_boats ~ treatment + control | EEZ + year,
                                 data = reg_data,                vcov = vcov_model1),
    "Treatment (Subset)" = feols(n_boats ~ treatment + control | EEZ + year,
                                 data = subset_treat,            vcov = vcov_others),
    "Color (All)"        = feols(n_boats ~ color + control | EEZ + year,
                                 data = droplevels(reg_data),    vcov = vcov_others),
    "Color (Subset)"     = feols(n_boats ~ color + control | EEZ + year,
                                 data = droplevels(subset_data), vcov = vcov_others)
  )
}

models <- list(
  thesis_as_run = fit_all(vcov_model1 = ~EEZ, vcov_others = "iid"),
  clustered     = fit_all(vcov_model1 = ~EEZ, vcov_others = ~EEZ)
)

saveRDS(models, config$paths$models)
message("model.R finished: saved ", config$paths$models)
