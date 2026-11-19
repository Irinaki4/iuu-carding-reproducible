## data_vessels.R -- from raw Global Fishing Watch files to vessel counts
##
## WHAT THIS SCRIPT DOES (in plain words)
##   1. Reads the list of blacklisted vessels (Trygg Mat Tracking) and keeps
##      their identification numbers (MMSI).
##   2. Goes through every AIS file (daily radio positions) and every SAR file
##      (monthly satellite detections) and keeps ONLY the rows that belong to
##      those blacklisted vessels.
##   3. For each kept position, finds which country's sea area (EEZ) it lies in.
##      A position outside every EEZ is labelled "High Seas".
##   4. Merges AIS and SAR, removes duplicates (one row per vessel, month and
##      country) and counts the different vessels per country and year.
##
## WHY IT IS DONE THIS WAY
##   The raw files are huge, so we filter first and only then do the slow
##   map step. Each file's result is saved in a "cache" folder, so if the
##   script stops, or you add new monthly files later, it only processes
##   files it has not seen before.
##
## READS:  the raw files named in config.R
## WRITES: data/yearly_counts_updated.csv   (small; this is what data.R uses)
##         data_raw/derived/vessel_eez_month.csv   (vessel-level; stays on your computer)
##
## NOTE: written from the logic of the original thesis code and tested step by
## step on the thesis intermediate files, but this script itself has not yet
## been run on the full raw data. Compare its output with the thesis (see the
## check at the end) before trusting it.

library(tidyverse)
library(data.table)   # fast reading of big files
library(sf)           # maps: points and polygons
library(readxl)       # reading the Excel vessel list

source("config.R")

# Use flat (planar) geometry. This is faster and avoids errors that the
# default "spherical" mode throws on the world EEZ file.
sf_use_s2(FALSE)

# --- helpers ---------------------------------------------------------------
# Stop with a clear message when something is missing
must_exist <- function(path) {
  if (!file.exists(path)) {
    stop("Cannot find: ", path, "\nCheck config.R and the README section ",
         "'Updating with new data'.", call. = FALSE)
  }
}

# Check that a file has the columns we need (Global Fishing Watch could change
# its file format in future releases)
check_columns <- function(path, needed) {
  found   <- names(fread(path, nrows = 0))
  missing <- setdiff(needed, found)
  if (length(missing) > 0) {
    stop("File ", basename(path), " is missing column(s): ",
         paste(missing, collapse = ", "),
         ". The data format may have changed.", call. = FALSE)
  }
}

for (p in c(config$ais_dir, config$sar_dir, config$tmt_file, config$eez_file)) must_exist(p)

# --- 1. Blacklisted vessels (MMSI numbers) -----------------------------------
tmt        <- read_excel(config$tmt_file, sheet = "IUUList")
mmsi_cells <- as.character(tmt$MMSI[!is.na(tmt$MMSI)])

bad_mmsi <- if (config$split_multi_mmsi) {
  unlist(str_split(mmsi_cells, "[,;/ ]+"))
} else {
  mmsi_cells
}
bad_mmsi <- unique(str_trim(bad_mmsi))
bad_mmsi <- bad_mmsi[bad_mmsi != ""]
message("Blacklisted vessels with an MMSI number: ", length(bad_mmsi))

# --- 2. Country sea borders (EEZ) --------------------------------------------
# SOVEREIGN1 = the country that owns the sea area. This is the "EEZ" name used
# in the analysis. st_make_valid() repairs any broken shapes in the file.
eez <- st_read(config$eez_file, quiet = TRUE) %>%
  st_make_valid() %>%
  select(SOVEREIGN1)

# --- 3. Cache folder -----------------------------------------------------------
# The folder name depends on the vessel list and the EEZ file. If either changes
# (for example a newer TMT list), a new cache is started automatically, so old
# results are never reused by mistake.
cache_dir <- file.path("data_raw", "cache",
                       rlang::hash(list(sort(bad_mmsi), basename(config$eez_file))))
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

# --- 4. Process one file ------------------------------------------------------
# Each function returns one row per vessel, month and country for ONE file.

process_ais <- function(path) {
  needed <- c("date", "cell_ll_lat", "cell_ll_lon", "mmsi")
  check_columns(path, needed)
  dt <- fread(path, select = needed)
  dt <- dt[as.character(mmsi) %in% bad_mmsi]      # keep blacklisted vessels only
  if (nrow(dt) == 0) return(NULL)
  dt  <- unique(dt)
  pts <- st_as_sf(as.data.frame(dt), coords = c("cell_ll_lon", "cell_ll_lat"),
                  crs = 4326, remove = FALSE)
  # Attach the country to every position. A position inside two overlapping
  # areas gets two rows; one outside all areas gets NA.
  joined <- st_join(pts, eez, join = st_intersects, left = TRUE)
  joined %>%
    st_drop_geometry() %>%
    transmute(
      mmsi   = as.character(mmsi),
      year   = as.integer(substr(as.character(date), 1, 4)),
      month  = as.integer(substr(as.character(date), 6, 7)),
      EEZ    = coalesce(SOVEREIGN1, "High Seas"),
      source = "AIS"
    ) %>%
    distinct()
}

process_sar <- function(path) {
  needed <- c("timestamp", "lat", "lon", "mmsi")
  check_columns(path, needed)
  dt <- fread(path, select = needed)
  dt <- dt[!is.na(lat) & !is.na(lon) & as.character(mmsi) %in% bad_mmsi]
  if (nrow(dt) == 0) return(NULL)
  pts <- st_as_sf(as.data.frame(dt), coords = c("lon", "lat"),
                  crs = 4326, remove = FALSE)
  joined <- st_join(pts, eez, join = st_intersects, left = TRUE)
  joined %>%
    st_drop_geometry() %>%
    transmute(
      mmsi   = as.character(mmsi),
      year   = as.integer(substr(timestamp, 1, 4)),
      month  = as.integer(substr(timestamp, 6, 7)),
      EEZ    = coalesce(SOVEREIGN1, "High Seas"),
      source = "SAR"
    ) %>%
    distinct()
}

# --- 5. Process all files, with the cache --------------------------------------
run_files <- function(files, fn, label) {
  results <- vector("list", length(files))
  for (i in seq_along(files)) {
    cache_file <- file.path(cache_dir, paste0(label, "_",
                            tools::file_path_sans_ext(basename(files[i])), ".rds"))
    if (file.exists(cache_file)) {
      results[i] <- list(readRDS(cache_file))     # already done earlier
    } else {
      out <- fn(files[i])
      saveRDS(out, cache_file)
      results[i] <- list(out)                     # list() keeps empty results in place
    }
    if (i %% 50 == 0) message(label, ": ", i, " of ", length(files), " files done")
  }
  bind_rows(results)
}

ais_files <- list.files(config$ais_dir, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
sar_files <- list.files(config$sar_dir, pattern = "^sar.*\\.csv$", full.names = TRUE)
message("AIS files found: ", length(ais_files), " | SAR files found: ", length(sar_files))

ais <- run_files(ais_files, process_ais, "AIS")
sar <- run_files(sar_files, process_sar, "SAR")

# --- 6. Merge AIS and SAR, remove duplicates -------------------------------------
# One row per vessel, month and country. "source" says whether the sighting came
# from AIS, SAR, or both.
vessels <- bind_rows(ais, sar) %>%
  group_by(mmsi, year, month, EEZ) %>%
  summarise(source = if_else(n_distinct(source) > 1, "both", first(source)),
            .groups = "drop") %>%
  filter(year %in% config$years) %>%
  arrange(year, month, EEZ)

dir.create("data_raw/derived", recursive = TRUE, showWarnings = FALSE)
write_csv(vessels, "data_raw/derived/vessel_eez_month.csv")

# --- 7. Count different vessels per country and year ------------------------------
yearly_counts <- vessels %>%
  group_by(year, EEZ) %>%
  summarise(n_boats = n_distinct(mmsi), .groups = "drop") %>%
  arrange(EEZ, year)

dir.create("data", showWarnings = FALSE)
write_csv(yearly_counts, "data/yearly_counts_updated.csv")
message("Saved data/yearly_counts_updated.csv (", nrow(yearly_counts), " rows)")

# --- 8. Optional check against the thesis ------------------------------------------
# Only meaningful if you ran this script on the SAME raw files as the thesis.
if (file.exists(config$vessel_answer_key)) {
  key <- read_csv(config$vessel_answer_key, show_col_types = FALSE) %>%
    transmute(mmsi = as.character(mmsi), year, month, EEZ)
  mine_only <- anti_join(vessels, key, by = c("mmsi", "year", "month", "EEZ"))
  key_only  <- anti_join(key, vessels, by = c("mmsi", "year", "month", "EEZ"))
  message("Check against thesis table: ", nrow(mine_only), " rows only in the new result, ",
          nrow(key_only), " rows only in the thesis table.")
}
