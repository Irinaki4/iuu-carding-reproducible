## output.R -- turn the fitted models into tables and run the checks
##
## WHAT THIS SCRIPT DOES
##   1. Makes two regression tables (HTML files you can open in a browser).
##   2. Saves correct descriptive statistics of the variable used in the models.
##   3. For the thesis version: compares every number with the thesis table and
##      says "OK" if they match.
##
## READS:  the fitted models (from model.R) and the analysis table (from data.R)
## WRITES: <output folder>/regression_table_thesis_as_run.html
##         <output folder>/regression_table_clustered.html
##         <output folder>/descriptive_statistics.csv
##         <output folder>/check_against_thesis.csv   (thesis version only)

library(tidyverse)
library(fixest)
library(modelsummary)   # builds the formatted tables

source("config.R")

out_dir <- config$paths$output_dir
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

models   <- readRDS(config$paths$models)
reg_data <- read_csv(config$paths$panel, show_col_types = FALSE)

# --- 1. Regression tables -----------------------------------------------------------------
# stars = TRUE adds the significance symbols (+ * ** ***).
# gof_map picks the fit statistics shown at the bottom: observations, R-squared, RMSE
# (RMSE = typical size of the model's prediction error, in number of vessels).
modelsummary(
  models$thesis_as_run,
  stars   = TRUE,
  gof_map = c("nobs", "r.squared", "rmse"),
  notes   = "Country and year fixed effects. Model 1: standard errors clustered by EEZ. Models 2-4: classical standard errors (as in the submitted thesis).",
  output  = file.path(out_dir, "regression_table_thesis_as_run.html")
)

modelsummary(
  models$clustered,
  stars   = TRUE,
  gof_map = c("nobs", "r.squared", "rmse"),
  notes   = "Country and year fixed effects. Standard errors clustered by EEZ in all models.",
  output  = file.path(out_dir, "regression_table_clustered.html")
)

# --- 2. Descriptive statistics of the outcome used in the models ------------------------------
# The outcome is the number of blacklisted vessels per country and year.
desc <- reg_data %>%
  summarise(
    variable = "IUU boat count per EEZ-year",
    mean = mean(n_boats), sd = sd(n_boats),
    min  = min(n_boats),  max = max(n_boats),
    n    = n()
  )
write_csv(desc, file.path(out_dir, "descriptive_statistics.csv"))

# --- 3. Does this reproduce the thesis table? (thesis version only) -----------------------------
if (config$version == "thesis") {

  # Numbers copied from the submitted thesis table: coefficient (est) and standard error (se)
  thesis_values <- tribble(
    ~model,               ~term,               ~est,   ~se,
    "Treatment (All)",    "treatmentsame",     -0.101, 0.120,
    "Treatment (All)",    "treatmentincrease",  0.047, 0.412,
    "Treatment (Subset)", "treatmentincrease",  0.248, 0.368,
    "Treatment (Subset)", "treatmentdecrease",  0.326, 0.496,
    "Color (All)",        "coloryellow",       -0.031, 0.256,
    "Color (Subset)",     "coloryellow",       -0.062, 0.249
  )

  # Look up the same number in our models and compare (allowed difference: 0.002)
  check_terms <- thesis_values %>%
    mutate(
      est_here = map2_dbl(model, term, ~ unname(coef(models$thesis_as_run[[.x]])[.y])),
      se_here  = map2_dbl(model, term, ~ unname(se(models$thesis_as_run[[.x]])[.y])),
      ok = abs(est_here - est) < 0.002 & abs(se_here - se) < 0.002
    )

  # R-squared = share of the variation the model explains. Compare it and RMSE too.
  r2_rmse <- tibble(
    model       = names(models$thesis_as_run),
    r2_thesis   = c(0.721, 0.680, 0.721, 0.675),
    rmse_thesis = c(0.75, 0.66, 0.75, 0.66)
  ) %>%
    mutate(
      r2_here   = map_dbl(models$thesis_as_run, ~ as.numeric(r2(.x, type = "r2"))),
      rmse_here = map_dbl(models$thesis_as_run, ~ sqrt(mean(resid(.x)^2))),
      ok = abs(r2_here - r2_thesis) < 0.002 & abs(rmse_here - rmse_thesis) < 0.006
    )

  write_csv(check_terms, file.path(out_dir, "check_against_thesis.csv"))
  print(check_terms)
  print(r2_rmse)

  if (all(check_terms$ok, r2_rmse$ok)) {
    message("OK: coefficients, standard errors, R-squared and RMSE reproduce the thesis table.")
  } else {
    message("CHECK: some values differ from the thesis table -- see the printed tables above.")
  }
}
