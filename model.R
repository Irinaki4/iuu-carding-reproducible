## model.R -- fit the four regression models from the thesis
##
## Reads:   data/regression_data.csv   (one row per country EEZ and year)
## Writes:  model/models.rds           (two sets of fitted models, see below)
##
## All models use country (EEZ) fixed effects + year fixed effects.
## They differ only in how standard errors are calculated:
##   thesis_as_run : exactly as in the submitted thesis table
##                   (Model 1 clustered by EEZ; Models 2-4 classical "iid" errors)
##   clustered     : all four models clustered by EEZ, which is what the
##                   thesis methods section describes

library(tidyverse)
library(fixest)

dir.create("model", showWarnings = FALSE)

# --- 1. Read the data and set the reference categories ---------------------
reg_data <- read_csv("data/regression_data.csv", show_col_types = FALSE) %>%
  mutate(
    treatment = factor(treatment, levels = c("no card", "same", "increase", "decrease")),
    color     = factor(color,     levels = c("green", "yellow", "red"))
  )

# --- 2. The subset used in Models 2 and 4 -----------------------------------
# Countries that were carded by the EU at some point.
# (The original thesis code listed 16 names; only these 9 exist in the final sample.)
previously_carded <- c("Ecuador", "Ghana", "Kiribati", "Liberia", "Panama",
                       "Senegal", "Thailand", "Tuvalu", "Vietnam")

subset_data <- reg_data %>%
  filter(EEZ %in% previously_carded)

# In the subset every country has a card, so "same", "increase" and "decrease"
# add up to 1 and one of them has to be left out. The thesis left out "same",
# so "same" is the baseline here.
subset_treat <- subset_data %>%
  mutate(treatment = relevel(droplevels(treatment), ref = "same"))

# --- 3. Safety checks: the sample sizes must match the thesis ---------------
stopifnot(nrow(reg_data) == 336)     # 42 EEZs x 8 years
stopifnot(nrow(subset_data) == 72)   # 9 EEZs x 8 years

# --- 4. Fit the models ------------------------------------------------------
# Everything after the "|" are fixed effects.
# vcov = "iid"  -> classical standard errors
# vcov = ~EEZ   -> standard errors clustered by EEZ
# fixest drops variables that cannot be estimated (e.g. "decrease" in Model 1)
# and prints a note saying so. That is expected.
fit_all <- function(vcov_m1, vcov_others) {
  list(
    "Treatment (All)"    = feols(n_boats ~ treatment + control | EEZ + year,
                                 data = reg_data, vcov = vcov_m1),
    "Treatment (Subset)" = feols(n_boats ~ treatment + control | EEZ + year,
                                 data = subset_treat, vcov = vcov_others),
    "Color (All)"        = feols(n_boats ~ color + control | EEZ + year,
                                 data = droplevels(reg_data), vcov = vcov_others),
    "Color (Subset)"     = feols(n_boats ~ color + control | EEZ + year,
                                 data = droplevels(subset_data), vcov = vcov_others)
  )
}

models <- list(
  thesis_as_run = fit_all(vcov_m1 = ~EEZ, vcov_others = "iid"),
  clustered     = fit_all(vcov_m1 = ~EEZ, vcov_others = ~EEZ)
)

saveRDS(models, "model/models.rds")
message("model.R finished: saved model/models.rds")
