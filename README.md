# Does EU IUU carding deter illegal fishing? A reproducible workflow

A reproducible re-analysis of my Bachelor's thesis, *"Trawling the Data: Does EU Carding Deter Illegal, Unreported and Unregulated Fishing?"* (University of Amsterdam, Political Science, completed June 2025).

The EU "carding" system warns (yellow card) or sanctions (red card) countries that do not do enough against illegal, unreported and unregulated (IUU) fishing. This project asks whether carding decisions are associated with changes in the number of blacklisted IUU vessels detected in a country's Exclusive Economic Zone (EEZ), using satellite and radio vessel-tracking data from 2017 to 2024.

**Short answer:** no carding variable is statistically significant in any of the four models, under either standard-error specification. With only 9 changes in card status in the sample, the data are too thin to say whether carding works. See [Limitations](#limitations).

## Status

| Stage | Script | State |
|---|---|---|
| Raw files to vessel counts per country and year | `data_vessels.R` | Written from the thesis logic; the counting and merging steps are tested against the thesis files; **not yet run on the full raw data** |
| Counts, EU card status and production data to analysis table | `data.R` | Done; reproduces the thesis table exactly |
| Regression models | `model.R` | Done |
| Tables and checks | `output.R` | Done; reproduces the thesis results |
| Updated fishing-sector control variable | `control_updated.R` | Written; needs a FAO FishStat extract (see below) |
| Maps | none yet | Planned |

## Quick start

You need R and RStudio.

1. Download or clone this repository.
2. Open `iuu-carding-reproducible.Rproj` in RStudio.
3. In the R console, run `renv::restore()`. This installs the exact package versions listed in `renv.lock`.
4. Run `source("run_all.R")`.

By default (`version = "thesis"` in `config.R`) the workflow uses the frozen thesis inputs in `boot/initial/data/` and should end with two messages:

- `OK: the rebuilt analysis table is identical to the table used in the thesis.`
- `OK: coefficients, standard errors, R-squared and RMSE reproduce the thesis table.`

## How the workflow fits together

```
raw Global Fishing Watch files + TMT vessel list + EEZ borders
        |  data_vessels.R   (slow; only for new data)
        v
vessel counts per country and year
        |  data.R   + EU carding decisions + fishing-sector size
        v
analysis table (data/regression_data.csv)
        |  model.R
        v
fitted models
        |  output.R
        v
tables and checks (output/)
```

`config.R` holds every setting (years, folders, which version to run). The script layout follows the four-step convention used by ICES's Transparent Assessment Framework (data, model, output, report).

## Files

| File | Purpose |
|---|---|
| `config.R` | All settings in one place |
| `data_vessels.R` | Raw AIS and SAR files to vessel counts (blacklisted vessels only) |
| `data.R` | Builds the analysis table: sample rule, card status, control variable |
| `model.R` | Four regression models (country and year fixed effects) |
| `output.R` | Tables, descriptive statistics, check against the thesis |
| `control_updated.R` | Builds a control variable from observed FAO FishStat data |
| `run_all.R` | Runs everything in order |
| `boot/initial/data/` | Small input tables with their sources (see `SOURCES.md` there) |
| `CREDITS.md` | Data sources, licences and citations |

## Data

Raw data are **not** stored in this repository because of their size and licence terms. See [`CREDITS.md`](CREDITS.md) for licences and the required citations.

| Data | Source | Used for |
|---|---|---|
| Vessel positions (AIS), daily files 2017-2024 | [Global Fishing Watch data download portal](https://globalfishingwatch.org/data-download/) | Where vessels broadcasting a signal were |
| Vessel detections from satellite radar (SAR), monthly files 2017-2024 | Global Fishing Watch (pipeline versions 20231026 and v3) | Detecting vessels that switch off their signal |
| IUU vessel list (365 listed vessels, 2022 download) | [Trygg Mat Tracking](https://www.tm-tracking.org/) combined IUU vessel list | Identifying blacklisted vessels by MMSI |
| EEZ borders | [Marine Regions](https://www.marineregions.org/), World EEZ v12 ([doi:10.14284/632](https://doi.org/10.14284/632)) | Assigning detections to countries |
| EU carding decisions with dates | [European Commission, overview of IUU procedures](https://oceans-and-fisheries.ec.europa.eu/international/illegal-fishing_en) (29 May 2024); the thesis used the [IUU Watch map](https://www.iuuwatch.eu/map-of-eu-carding-decisions/) | Card status and treatment variables |
| Total fisheries production (control) | [World Bank ER.FSH.PROD.MT](https://data.worldbank.org/indicator/ER.FSH.PROD.MT) | Size of the national fishing sector, 2017-2022 |
| Growth projections for 2022-2024 gaps | [OECD-FAO Agricultural Outlook](https://www.oecd.org/agriculture/agricultural-outlook/) 2022-2031, 2023-2032, 2024-2033 | Thesis version of the control, 2023-2024 |
| Observed production 1950-2024 | [FAO FishStat global production](https://www.fao.org/fishery/en/collection/global_production), March 2026 release | Updated control variable |

The analysis dataset contains only counts per country and year, not vessel positions.

## Method in brief

- **Unit of analysis:** EEZ (country) and year, 42 EEZs, 336 observations.
- **Outcome:** number of unique blacklisted vessels (by MMSI) detected in a country's EEZ in a year, from AIS and SAR combined.
- **Treatment:** (a) change in card status between 31 December of the previous year and 31 December of this year (same, increase, decrease); (b) card colour (green or yellow).
- **Control:** total annual fisheries production.
- **Models:** four linear models with EEZ and year fixed effects. Models 1 and 3 use all 42 EEZs; Models 2 and 4 use the 9 EEZs whose card changed during 2017-2024.

## Updating with new data

1. **New vessel data.** Download new daily AIS or monthly SAR files from Global Fishing Watch and add them to `data_raw/AIS/` or `data_raw/SAR/`. Only new files are processed; results of earlier files are cached.
2. **New blacklist.** Replace `data_raw/TMT_IUU_list.xls` with the new download (keep the sheet name `IUUList`). A new list starts a fresh cache, so all files are processed again.
3. **New carding decisions.** Add rows to `boot/initial/data/carding_decisions.csv` (country, decision, date as `YYYY-MM`, source). Decision names must be one of: `pre-identification`, `pre-identification revoked`, `identification`, `listing`, `delisting`.
4. **New control variable.** Prepare `data_raw/fishstat_production.csv` (columns `country`, `year`, `tonnes`) and run `control_updated.R`.
5. In `config.R`, set `version = "updated"` and `run_raw_stage = TRUE`, adjust `years` if needed, then run `source("run_all.R")`. Results go to `output/updated/`.

The thesis check is skipped for the updated version, because the numbers are expected to change.

## Reproduction notes and corrections

Rebuilding the analysis as a scripted workflow and checking it against my thesis surfaced several points where the thesis description differs from the code. The thesis itself is unchanged; this list is the corrected record.

1. **Descriptive statistics.** The thesis table (mean 17.3, maximum 74) describes a different variable from the one in the regressions. The regression outcome has a mean of 1.68, a standard deviation of 1.42, a minimum of 0 and a maximum of 8. `output/descriptive_statistics.csv` reports the correct figures.
2. **Standard errors.** The thesis methods describe errors clustered by country. In the submitted table, only Model 1 is clustered; Models 2-4 use classical standard errors. Both versions are reproduced here, and no carding coefficient is significant under either.
3. **Baseline categories.** In Model 2 the three treatment categories add up to one for every country, so one must be left out. The thesis left out "same", so coefficients are relative to years without a card change.
4. **Sample rule.** The thesis describes keeping EEZs with at least five unique IUU vessel detections. The code kept EEZs present in the data in at least 5 of the 8 years. Four more EEZs (Maldives, Sao Tome and Principe, Taiwan, High Seas) drop out because production data are missing, leaving 42.
5. **The subset in Models 2 and 4.** The thesis calls it "previously carded countries". The code used the 9 countries whose card status changed in 2017-2024 (Ecuador, Ghana, Kiribati, Liberia, Panama, Senegal, Thailand, Tuvalu, Vietnam). Five other countries in the sample were carded earlier (before 2017) but are not in the subset.
6. **Carding data verified.** The thesis card statuses were coded by hand. Rebuilding them from the Commission's dated decisions (status on 31 December of each year) reproduces all 336 country-year values exactly.

## Limitations

- **Few treatment events.** The sample has 6 increases and 3 decreases in card stringency. A non-significant result here is better read as inconclusive than as "no effect".
- **Blacklist coverage.** Only 62 of the 365 vessels on the IUU list have an MMSI, the identifier needed to match them to tracking data. The outcome therefore counts only a trackable minority of listed vessels. Vessels no longer on the list were also counted, and I did not filter on listing date.
- **No red cards in the sample.** After the sample rule, only green and yellow cards remain, so the colour models compare yellow with green only.
- **Card data end in May 2024.** The Commission overview used is dated 29 May 2024. Decisions after that date still need to be added and verified.
- **Tracking gaps.** Vessels that switch off AIS or operate outside satellite coverage may be missed, and activity just outside EEZ boundaries is excluded.
- **Pipeline versions.** The last two SAR months (November and December 2024) come from a newer Global Fishing Watch pipeline version than the other 94. 2024 may not be perfectly comparable.
- **Projected control values.** In the thesis version, production for 2023-2024 and five 2022 values are projections; the updated control uses observed values.

## Roadmap

- [ ] Run `data_vessels.R` on the full raw data and compare with the thesis vessel table
- [ ] Build the updated control variable from FAO FishStat and rerun the models
- [ ] Add card decisions after May 2024
- [ ] Reproduce the thesis maps in R
- [ ] Add data validation checks (missing values, duplicates, ranges)
- [ ] Extension: look up the 117 listed vessels that have an IMO number but no MMSI, to widen vessel coverage

## Acknowledgements and licence

Scripts were developed with the assistance of an AI assistant (Claude, Anthropic). I ran them and checked their results against my thesis table.

Code is released under the MIT licence. Data sources keep their own licences and terms; see [`CREDITS.md`](CREDITS.md).

Author: Irina-Elena Chicuş
