# Does EU IUU carding deter illegal fishing? A reproducible workflow

A reproducible re-analysis of my Bachelor's thesis, *"Trawling the Data: Does EU Carding Deter Illegal, Unreported and Unregulated Fishing?"* (University of Amsterdam, Political Science, completed June 2025).

The EU "carding" system warns (yellow card) or sanctions (red card) countries that do not do enough against illegal, unreported and unregulated (IUU) fishing. This project asks whether carding decisions are associated with changes in the number of blacklisted IUU vessels detected in a country's Exclusive Economic Zone (EEZ), using satellite and radio vessel-tracking data from 2017 to 2024.

**Short answer:** no carding variable is statistically significant in any of the four models, under either standard-error specification. With only 9 changes in card status in the sample, the data are too thin to say whether carding works. See [Limitations](#limitations).

## Status

| Stage | State |
|---|---|
| Analysis: panel data to models to tables, with an automatic check against the thesis | Done, runs end to end |
| Raw data processing: AIS and SAR files to EEZ assignment to panel | Not yet scripted here (done in R and QGIS for the thesis) |
| Maps (QGIS in the thesis) | Not yet reproduced here |

This is a work in progress. The [Roadmap](#roadmap) lists what comes next.

## Quick start

You need R and RStudio.

1. Download or clone this repository.
2. Open `iuu-carding-reproducible.Rproj` in RStudio.
3. In the R console, run `renv::restore()`. This installs the exact package versions listed in `renv.lock`.
4. Run `source("run_all.R")`.

The run should end with `OK: coefficients, standard errors, R-squared and RMSE reproduce the thesis table.`

## What the scripts do

| File | Purpose |
|---|---|
| `model.R` | Fits the four regression models (country and year fixed effects) |
| `output.R` | Builds the tables, descriptive statistics and the check against the thesis |
| `run_all.R` | Runs both scripts in order |
| `data/regression_data.csv` | The analysis dataset: one row per EEZ and year (42 EEZs, 2017-2024, 336 rows) |
| `output/regression_table_thesis_as_run.html` | Reproduces the thesis table exactly |
| `output/regression_table_clustered.html` | Same models with standard errors clustered by EEZ in all four |
| `output/descriptive_statistics.csv` | Descriptive statistics of the variable actually used in the regressions |
| `output/check_against_thesis.csv` | Comparison with the published thesis values |

## Data

Raw data are **not** stored in this repository because of their size and licence terms. Please check each source's current terms before reuse.

| Data | Source | Used for |
|---|---|---|
| Vessel positions (AIS), daily files 2017-2024 | Global Fishing Watch | Where vessels broadcasting a signal were |
| Vessel detections from satellite radar (SAR), monthly files 2017-2024 | Global Fishing Watch (pipeline versions 20231026 and v3) | Detecting vessels that switch off their signal |
| IUU vessel list (365 listed vessels, 2022 download) | Trygg Mat Tracking combined IUU vessel list | Identifying blacklisted vessels by MMSI |
| EEZ boundaries | Marine Regions, World EEZ v12 (2023-10-25) | Assigning detections to countries |
| EU carding status by country and year | EU IUU Fishing Coalition | Treatment variables |
| Total fisheries production (control) | World Bank indicator ER.FSH.PROD.MT | Size of the national fishing sector |
| Growth projections for 2022-2024 gaps | OECD-FAO Agricultural Outlook 2022-2031, 2023-2032, 2024-2033 | Filling missing production values |

The analysis dataset in `data/` contains only counts per EEZ and year, not vessel positions.

## Method in brief

- **Unit of analysis:** EEZ and year (42 EEZs, 336 observations).
- **Outcome:** number of unique blacklisted vessels (by MMSI) detected in an EEZ in a year, from AIS and SAR combined.
- **Treatment:** (a) change in card stringency compared with the previous year (same, increase, decrease); (b) card colour (green or yellow).
- **Control:** total annual fisheries production. World Bank values for 2017-2021 and most of 2022; gaps and 2023-2024 filled with OECD-FAO growth projections.
- **Models:** four linear models with EEZ and year fixed effects. Models 1 and 3 use all 42 EEZs; Models 2 and 4 use the 9 EEZs that were ever carded.

## Reproduction notes

1. **Standard errors.** The thesis methods describe errors clustered by country. In the submitted table, only Model 1 is clustered; Models 2-4 use classical standard errors. Both versions are reproduced here, and no carding coefficient is significant under either.
2. **Baseline categories.** In Model 2 the three treatment categories add up to one for every country, so one must be left out. The thesis left out "same", so coefficients are relative to "same".
3. **Sample rule.** The code kept EEZs present in the data in at least 5 of the 8 years. Four more EEZs (Maldives, Sao Tome and Principe, Taiwan, High Seas) drop out because production data are missing, leaving 42.

## Limitations

- **Few treatment events.** The sample has 6 increases and 3 decreases in card stringency. A non-significant result here is better read as inconclusive than as "no effect".
- **Blacklist coverage.** Only 62 of the 365 vessels on the IUU list have an MMSI, the identifier needed to match them to tracking data. The outcome therefore counts only a trackable minority of listed vessels. Vessels no longer on the list were also counted, and I did not filter on listing date.
- **No red cards in the sample.** After the sample rule, only green and yellow cards remain, so the colour models compare yellow with green only.
- **Tracking gaps.** Vessels that switch off AIS or operate outside satellite coverage may be missed, and activity just outside EEZ boundaries is excluded.
- **Pipeline versions.** The last two SAR months (November and December 2024) come from a newer Global Fishing Watch pipeline version than the other 94. 2024 may not be perfectly comparable.

## Roadmap

- [ ] Script the raw-data stage (AIS and SAR files to EEZ assignment to panel) and test it against the original thesis outputs
- [ ] Reproduce the thesis maps in R
- [ ] Add data validation checks (missing values, duplicates, ranges)
- [ ] Extension: look up the 117 listed vessels that have an IMO number but no MMSI, to widen vessel coverage

## Repository layout

```
.
├── README.md
├── run_all.R
├── model.R
├── output.R
├── data/
│   └── regression_data.csv
├── model/            (created when scripts run)
├── output/           (tables and checks)
├── renv.lock         (exact package versions)
└── iuu-carding-reproducible.Rproj
```

## Acknowledgements and licence

Scripts were developed with the assistance of an AI assistant (Claude, Anthropic). I ran them and checked their results against my thesis table.

Code is released under the MIT licence. Data sources keep their own licences and terms (see Data).

Author: Irina-Elena Chicuş
