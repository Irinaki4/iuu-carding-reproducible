# Credits, licences and citations

This file lists every data source, its licence (as far as I could verify) and how to cite it.
**Licence terms can change. Check each source's current terms before reusing anything.**

## Data sources

### Global Fishing Watch (AIS and SAR vessel data)

- Licence: Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0). Use is for non-commercial purposes only, and attribution is required where the data or results are presented.
- Citation format used by Global Fishing Watch: *Global Fishing Watch. [year], updated [daily/monthly]. [dataset name and version]. Data set accessed [YYYY-MM-DD] at [link].* For example: *"Global Fishing Watch. 2025, updated monthly. SAR vessel detections v20231026. Data set accessed YYYY-MM-DD."* Fill in the dataset names exactly as they appear on the download portal and the date you downloaded them. Global Fishing Watch also asks for a disclaimer; copy the exact wording from its [terms of use](https://globalfishingwatch.org/terms-of-use/).
- Datasets used: AIS-based files (`mmsi-daily-csvs-10-v3`), 2017-2024, and SAR vessel detections (pipeline versions 20231026 and v3), 2017-2024.
- Raw files are **not** redistributed here. Derived counts in this repository (`boot/initial/data/yearly_counts_per_eez.csv`, `data/`) are shared under the same CC BY-NC 4.0 terms, with attribution to Global Fishing Watch.

### Trygg Mat Tracking (combined IUU vessel list)

- Source: Trygg Mat Tracking, combined IUU vessel list (2022 download). It aggregates vessel lists of regional fisheries management organisations.
- The list file is **not** redistributed here. I could not confirm a reuse licence, so please cite it and download it yourself.

### Marine Regions (EEZ borders)

- Licence: CC BY 4.0.
- Citation: Flanders Marine Institute (2023). *Maritime Boundaries Geodatabase: Maritime Boundaries and Exclusive Economic Zones (200NM), version 12.* Available online at https://www.marineregions.org/. https://doi.org/10.14284/632
- Raw shapefile not redistributed here.

### EU carding decisions

- Source: European Commission, Directorate-General for Maritime Affairs and Fisheries, *Illegal fishing: overview of existing procedures with third countries* (29 May 2024), https://oceans-and-fisheries.ec.europa.eu/international/illegal-fishing_en
- The thesis took the decisions from the EU IUU Fishing Coalition's [map of EU carding decisions](https://www.iuuwatch.eu/map-of-eu-carding-decisions/) (IUU Watch). `carding_decisions.csv` was rebuilt from the Commission's table and matches the thesis coding.
- European Commission content can generally be reused with attribution; check the Commission's current reuse policy.

### Fisheries production (control variable)

- World Bank, World Development Indicators, *Total fisheries production (metric tons)*, indicator ER.FSH.PROD.MT, https://data.worldbank.org/indicator/ER.FSH.PROD.MT. World Bank open data is generally published under CC BY 4.0. State the date you accessed it.
- OECD/FAO, *OECD-FAO Agricultural Outlook* 2022-2031, 2023-2032 and 2024-2033, OECD Publishing, Paris. Check the OECD's current terms of use.
- FAO, *FishStat: Global fisheries and aquaculture production*, March 2026 release (data 1950-2024), Fisheries and Aquaculture Division, Rome, https://www.fao.org/fishery/en/collection/global_production. FAO's dataset page indicates CC BY 4.0 for the 2026 release, while the separate `fishstat` R package carries a different licence (CC BY-NC-SA 4.0); check which applies to the files you use.

## Maps and figures

- Maps made from Global Fishing Watch data must credit Global Fishing Watch and stay non-commercial (CC BY-NC 4.0).
- If a map uses the OpenStreetMap background, add "© OpenStreetMap contributors" on or next to the map.
- Credit Marine Regions for EEZ borders (see citation above).
- Share maps as exported images only. The QGIS project file points to files on my own computer, and the large heatmap `.tif` files are excluded from the repository.

## Thesis text

- The thesis is my own work and I hold its copyright, but its use may be governed by University of Amsterdam rules. Check the university's policy before publishing the full text.
- The thesis cover shows my student number; it is not included here for privacy.
- This repository summarises the thesis rather than reproducing it.

## Code and tools

- Code in this repository: MIT licence (see `LICENSE`).
- R packages (tidyverse, sf, data.table, readxl, fixest, modelsummary, renv) are used under their own open-source licences.
- Scripts were developed with the assistance of an AI assistant (Claude, Anthropic).

## Before making this repository public

- [ ] Fill in the exact Global Fishing Watch citation and disclaimer
- [ ] Add the access date for every downloaded dataset
- [ ] Check the licence terms of the TMT list and the OECD publications
- [ ] Confirm no raw data, personal details or tokens are in any file (see `.gitignore`)
