## run_all.R -- run the whole workflow, in order
##
## How to use: open this file in RStudio and click "Source" (top right of the
## editor), or type  source("run_all.R")  in the Console.
##
## Order of steps:
##   1. data_vessels.R  (only if run_raw_stage = TRUE in config.R; slow)
##   2. data.R          build the analysis table
##   3. model.R         run the regressions
##   4. output.R        make tables and checks

source("config.R")

if (config$run_raw_stage) source("data_vessels.R")

source("data.R")
source("model.R")
source("output.R")
