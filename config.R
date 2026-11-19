## config.R -- all settings in one place
##
## WHAT THIS FILE IS
##   A list of settings ("config") that the other scripts read.
##   If you want to change something (the years, a file location), change it
##   here and every script picks it up. In R, config$years means
##   "the item called years inside the list called config".

config <- list(

  # Which version of the analysis to run:
  #   "thesis"  = the frozen inputs from the thesis (default; runs in minutes)
  #   "updated" = your own new downloads (new vessel files, new production data)
  version = "thesis",

  # Run the slow step that turns raw Global Fishing Watch files into vessel
  # counts (data_vessels.R)? Only needed for the "updated" version, and it can
  # take hours. TRUE = run it, FALSE = skip it.
  run_raw_stage = FALSE,

  # Years included in the analysis
  years = 2017:2024,

  # A country only enters the sample if blacklisted vessels were detected in
  # its waters in at least this many different years
  min_years_present = 5,

  # Raw data: these big files stay on your own computer (they are NOT on GitHub).
  # Put each download in the folder named here, or change the path.
  ais_dir  = "data_raw/AIS",                  # daily AIS files (one folder per year is fine)
  sar_dir  = "data_raw/SAR",                  # monthly SAR files (names start with "sar")
  tmt_file = "data_raw/TMT_IUU_list.xls",     # Trygg Mat Tracking vessel list
  eez_file = "data_raw/World_EEZ_v12_20231025/eez_v12.shp",  # country sea borders

  # Some rows of the TMT list hold two vessel numbers in one cell
  # (for example "412676460, 412321992"). The thesis matched whole cells only.
  # TRUE = split such cells so that every number is used (more complete).
  split_multi_mmsi = FALSE,

  # Small input tables that live in this repository
  carding_file   = "boot/initial/data/carding_decisions.csv",
  reference_file = "boot/initial/data/regression_data_thesis.csv",

  # Optional: the thesis's combined vessel table, used to double-check
  # data_vessels.R when you run it on the thesis data (keep it in data_raw/)
  vessel_answer_key = "data_raw/answer_key/combined_ais_sar.csv"
)

# Which files belong to which version
paths_by_version <- list(
  thesis = list(
    counts     = "boot/initial/data/yearly_counts_per_eez.csv",   # vessels per country and year
    control    = "boot/initial/data/control_thesis_version.csv",  # fisheries production
    panel      = "data/regression_data.csv",                      # finished analysis table
    models     = "model/models.rds",
    output_dir = "output"
  ),
  updated = list(
    counts     = "data/yearly_counts_updated.csv",
    control    = "boot/initial/data/control_updated.csv",
    panel      = "data/regression_data_updated.csv",
    models     = "model/models_updated.rds",
    output_dir = "output/updated"
  )
)

stopifnot(config$version %in% names(paths_by_version))
config$paths <- paths_by_version[[config$version]]
