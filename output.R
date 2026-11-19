## output.R -- tables and checks
##
## Reads:   model/models.rds, data/regression_data.csv
## Writes:  output/regression_table_thesis_as_run.html
##          output/regression_table_clustered.html
##          output/descriptive_statistics.csv
##          output/check_against_thesis.csv

library(tidyverse)
library(fixest)
library(modelsummary)

dir.create("output", showWarnings = FALSE)

models   <- readRDS("model/models.rds")
reg_data <- read_csv("data/regression_data.csv", show_col_types = FALSE)

# --- 1. Regression tables ---------------------------------------------------
modelsummary(
  models$thesis_as_run,
  stars   = TRUE,
  gof_map = c("nobs", "r.squared", "rmse"),
  notes   = "Country and year fixed effects. Model 1: standard errors clustered by EEZ. Models 2-4: classical standard errors (as in the submitted thesis).",
  output  = "output/regression_table_thesis_as_run.html"
)

modelsummary(
  models$clustered,
  stars   = TRUE,
  gof_map = c("nobs", "r.squared", "rmse"),
  notes   = "Country and year fixed effects. Standard errors clustered by EEZ in all models.",
  output  = "output/regression_table_clustered.html"
)

# --- 2. Descriptive statistics of the variable used in the regressions ------
# (the outcome: number of IUU vessels per EEZ and year)
desc <- reg_data %>%
  summarise(
    variable = "IUU boat count per EEZ-year",
    mean = mean(n_boats), sd = sd(n_boats),
    min  = min(n_boats),  max = max(n_boats),
    n    = n()
  )
write_csv(desc, "output/descriptive_statistics.csv")

# --- 3. Does this reproduce the thesis table? -------------------------------
# Values copied from the submitted thesis table (coefficient and standard error).
thesis_values <- tribble(
  ~model,               ~term,               ~est,   ~se,
  "Treatment (All)",    "treatmentsame",     -0.101, 0.120,
  "Treatment (All)",    "treatmentincrease",  0.047, 0.412,
  "Treatment (Subset)", "treatmentincrease",  0.248, 0.368,
  "Treatment (Subset)", "treatmentdecrease",  0.326, 0.496,
  "Color (All)",        "coloryellow",       -0.031, 0.256,
  "Color (Subset)",     "coloryellow",       -0.062, 0.249
)

check_terms <- thesis_values %>%
  mutate(
    est_here = map2_dbl(model, term, ~ unname(coef(models$thesis_as_run[[.x]])[.y])),
    se_here  = map2_dbl(model, term, ~ unname(se(models$thesis_as_run[[.x]])[.y])),
    ok = abs(est_here - est) < 0.002 & abs(se_here - se) < 0.002
  )

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

write_csv(check_terms, "output/check_against_thesis.csv")
print(check_terms)
print(r2_rmse)

if (all(check_terms$ok, r2_rmse$ok)) {
  message("OK: coefficients, standard errors, R-squared and RMSE reproduce the thesis table.")
} else {
  message("CHECK: some values differ from the thesis table -- see the printed tables above.")
}
