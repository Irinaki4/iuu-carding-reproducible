# Input tables in this folder

| File | What it is | Where it comes from |
|---|---|---|
| `carding_decisions.csv` | Every EU carding decision by country and month | European Commission, *Overview of IUU procedures with third countries* (29 May 2024). Rebuilt from that table and verified: it reproduces all 336 hand-coded country-year statuses from the thesis. |
| `control_thesis_version.csv` | Fisheries production (tonnes) per country and year, as used in the thesis | World Bank ER.FSH.PROD.MT for 2017-2021 and most of 2022; OECD-FAO growth projections for 2023-2024 and five 2022 values (Iran, Micronesia, North Korea, South Korea, United Kingdom) |
| `yearly_counts_per_eez.csv` | Number of different blacklisted vessels per country and year | Derived from Global Fishing Watch AIS and SAR data and the Trygg Mat Tracking vessel list (CC BY-NC 4.0, attribution: Global Fishing Watch) |
| `regression_data_thesis.csv` | The finished analysis table used in the thesis | Used only to check that `data.R` reproduces it |
| `eez_to_fishstat_names.csv` | Name matching between EEZ names and FAO country names | Starting point: names are copied as they are; edit where FAO spells a country differently |

## Card decision rules

`decision` is one of: `pre-identification` (yellow card), `pre-identification revoked` (back to green), `identification` and `listing` (red card), `delisting` (back to green). Dates are `YYYY-MM`. Status in a year is the status on 31 December.
