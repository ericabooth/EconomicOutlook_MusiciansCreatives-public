# Sources — Austin live-music venue ecosystem (supply, revenue, attrition)

Beat: venues. Compiled 2026-08-01 for the Texas 2036 economics-of-working-musicians white paper.
All retrieval dates below are **2026-08-01** unless noted.

Companion source files written by the two parallel research streams:
- `_sources_task2.md` — news coverage, closure timeline, Red River / Bring Music Home / NIVA
- `_sources_task3.md` — Texas Music Office directory, City of Austin open data, TABC datasets

---

## 1. Texas Comptroller — Mixed Beverage Gross Receipts (primary quantitative source)

| Field | Value |
|---|---|
| Publisher | Texas Comptroller of Public Accounts, via the Texas Open Data Portal (Socrata) |
| Dataset | Mixed Beverage Gross Receipts |
| Dataset ID | `naix-2893` — **verified**, not assumed |
| Landing page | https://data.texas.gov/dataset/Mixed-Beverage-Gross-Receipts/naix-2893 |
| API endpoint | https://data.texas.gov/resource/naix-2893.csv |
| Metadata endpoint | https://data.texas.gov/api/views/naix-2893.json |
| Vintage / last refresh | `rowsUpdatedAt` = 2026-08-01 10:16:03 UTC (checked at retrieval) |
| Full dataset size | 3,802,638 rows, statewide |
| Period available | obligation end dates 2007-01-31 through 2026-08-31 |
| Authentication | None. No app token needed at this request volume. |

### Extract taken
- Filter: `location_county = 227 OR upper(location_city) = 'AUSTIN'` (227 = Travis County)
- Paged with `$limit=50000` + `$offset`, ordered by taxpayer/location/obligation date
- **267,708 rows** retrieved across 6 pages
- Collapsed to **3,814 distinct location-permit records** (location_name x location_address x taxpayer x permit)

### Columns used
`taxpayer_name`, `taxpayer_number`, `location_name`, `location_address`, `location_zip`,
`location_county`, `location_number`, `tabc_permit_number`, `responsibility_begin_date_yyyymmdd`,
`responsibility_end_date_yyyymmdd`, `obligation_end_date_yyyymmdd`, `liquor_receipts`,
`wine_receipts`, `beer_receipts`, `cover_charge_receipts`, `total_receipts`

### Matching method (reproducible)
Venue identification was done in two passes and is fully auditable:
1. **Keyword pass** over `location_name` and `taxpayer_name` for ~200 venue-name fragments.
2. **Address pass** — for every target venue, a lookup on the street address, which catches
   legal-name changes, ownership turnover, and successor tenants at the same premises.

Matches are recorded as **exact `(location_name, location_address)` pairs**, so one canonical venue
can span several permit-holders over time (e.g., Stubb's = `SARC INC` 2007-2012 then
`STUBB'S BAR-B-Q` 2012-2026). Result: **114 canonical venues / 145 permit-entity pairs / 16,346
venue-months**. Every one of the 145 pairs matched at least one row (zero dangling definitions).

The crosswalk is embedded in `venue_match_list.csv` (columns `matched_location_names`,
`matched_addresses`, `taxpayers`), so any match can be re-derived from the raw Socrata file.

---

## 2. BLS CPI-U — deflator for real-dollar comparisons

| Field | Value |
|---|---|
| Series | `CUUR0000SA0` — CPI-U, U.S. city average, all items, not seasonally adjusted |
| Source | BLS Public Data API v2 (no registration key), https://api.bls.gov/publicAPI/v2/timeseries/data/ |
| Coverage retrieved | 2007-01 through 2026-06 |
| Base period for real dollars | **2026-06 (CPI-U = 333.952)** — all "real" figures are 2026-06 dollars |

**Imputation, flagged:** BLS did not publish a CPI-U value for **October 2025** (the federal
government shutdown interrupted collection and BLS did not release that month). The value used here
is the linear midpoint of Sep 2025 (324.800) and Nov 2025 (324.122) = **324.461**. Every affected
row carries `cpi_imputed = 1` in `venue_monthly_receipts_long.csv`, and the column `cpi_imputed`
appears in `matched_venues_monthly_agg.csv`. This matters because October is the ACL Festival month
and carries unusually large receipts; an unhandled gap silently zeroed out roughly $22M of 2025 real
receipts in an earlier draft of these tables.

*Caveat:* CPI-U U.S. city average is a national deflator. Austin-area inflation, especially in
commercial rent, has run above the national average, so real declines reported here are, if
anything, conservative.

---

## 3. Files produced in this folder (venue beat)

| File | Contents |
|---|---|
| `venue_match_list.csv` | 127 rows: 114 matched canonical venues (with every permit entity, address, and taxpayer) + 13 documented non-matches with the reason |
| `venue_monthly_receipts_long.csv` | 16,346 venue-months, 2007-01 to 2026-06. Long panel: venue x month, with liquor/wine/beer/cover/total, real-dollar column, CPI column, and two outlier flags |
| `venue_summary.csv` | One row per venue: first/last month, still-reporting flag, real receipts for 2013/2019/2024/2025, and real % change 2019→2024 and 2019→2025 |
| `matched_venues_annual.csv` | Annual totals, nominal and real, all-rows and festival-adjusted, plus a core-live-music-only series |
| `matched_venues_monthly_agg.csv` | 234 months. Matched-panel totals alongside the **all-permit Travis/Austin denominator**, so the panel can be benchmarked against the whole bar market |
| `venue_timeline.csv` | Venue closure/opening timeline from news coverage (see `_sources_task2.md`) |
| `articles/*.md` | Archived article summaries with URL and publication date |
| `red_river_and_studies.md` | Red River Cultural District, Bring Music Home, NIVA, City of Austin venue programs |
| `tmo_directory_notes.md`, `tmo_listings_*.csv` | Texas Music Office directory (see `_sources_task3.md`) |
| `austin_open_data_catalog.csv`, `austin_*.csv` | City of Austin open datasets evaluated and downloaded |

---

## 4. Caveats and known failures — read before citing any number

### 4.1 What the mixed-beverage file does and does not cover
- It covers **Mixed Beverage (MB) permittees only**. Venues holding a **beer-and-wine (BG) permit**
  never appear. Confirmed absences that matter for a music paper: **Carousel Lounge, Meanwhile
  Brewing, Whip In**. Their absence is a permit-type artifact, not a closure.
- **Alcohol sales are a proxy for venue activity, not a measure of music revenue.** They exclude
  ticket sales, merchandise, and the door split that actually pays musicians. Cover charge is
  reported separately but is very sparsely used (see 4.4).
- Non-alcohol venues are structurally invisible: **Cactus Cafe** (rolled into the UT Texas Union
  permit), **Bass Concert Hall / Texas Performing Arts**, **Central Presbyterian Church**.
- Venues inside hotels are not separable: **Geraldine's** receipts sit inside the Hotel Van Zandt
  permit.
- Geography: the extract is Travis County + City of Austin. **Haute Spot** (Cedar Park, Williamson),
  **Cheatham Street Warehouse** (San Marcos, Hays), and **Gruene Hall** (Comal) are outside it by
  design.

### 4.2 Festival concession aggregation — the largest single analytic hazard
C3 Presents files festival bar receipts through concession LLCs that are **named after, and
permitted at, a small venue address**. Two entities do this:
- `EMOS CONCESSION COMPANY, LLC` (2015 E Riverside) — e.g. **Oct 2024 = $14,567,301**, versus an
  Emo's East median month of $116,344 (**125x**).
- `SCOOT INN CONCESSION COMPANY, LLC` (1308 E 4th) — e.g. **Oct 2025 = $12,540,139**, versus a Scoot
  Inn median month of $38,434 (**326x**).

These are almost certainly Austin City Limits Festival receipts, not venue receipts. Taking them at
face value would have shown Scoot Inn "growing 1,358%" from 2019 to 2025.

Handling: two flags in the long panel.
- `festival_spike_flag` = 1 when a month exceeds **6x** the venue's own median month **and** $500k (39 rows). Broad; it also catches genuine regime changes such as Block 21's expansion.
- `extreme_outlier_flag` = 1 when a month exceeds **20x** median **and** $500k (**10 rows**). This is the near-certain off-premise/festival set and is what the `*_ex_festival` columns exclude.

**Use the `_ex_festival` series for any venue-health claim.** The 10 excluded rows are listed in
`_findings.md`.

### 4.3 Reporting timing
- `obligation_end_date_yyyymmdd` is the **end of the monthly reporting period**, not a transaction
  date. Receipts are filed the following month.
- The panel is truncated at **2026-06**, the last complete month. 2026-07 had only 6 Travis permits
  and $49,656 filed at retrieval time — effectively unfiled. **2026 figures cover Jan–Jun only** and
  are labelled `partial_Jan-Jun`.

### 4.4 Cover charge is not a usable live-music series before ~2022
`cover_charge_receipts` was essentially unreported for most of the period: **$5,488 across the whole
matched panel in 2019 (0.01% of receipts)** versus **$2,085,610 in 2024 (1.62%)**. This is a
reporting/compliance change, not a real change in how venues charge at the door. Do **not** read the
increase as growth in ticketed shows.

### 4.5 "Ceased reporting" is not the same as "closed"
A venue exits this panel when its permit stops filing. That usually means closure, but it can also
mean a permit transfer, an entity restructuring, or a switch to a beer-and-wine permit. Every
closure claim in `_findings.md` that is stated as a closure is cross-checked against the news
timeline in `venue_timeline.csv`; ones that are not cross-checked are described only as "stopped
reporting."

### 4.6 Panel construction
- The 114-venue list is **curated, not exhaustive**. It over-represents venues that were nameable
  from the target list and from Red River / East Austin / South Congress coverage. It is a
  defensible tracking panel, not a census of Austin live music.
- Some entries are **successor tenants at the same address** rather than independent venues
  (Chess Club at Plush's 617 Red River; Scratchouse at Holy Mountain's 617 E 7th; The Creek and the
  Cave at Red 7 / Barracuda's 611 E 7th). They are kept separate on purpose so that turnover at a
  given address is visible. Do not sum them as if they were distinct new supply.
- **Stay Gold** could not be verified. The address 1910 E Cesar Chavez matches permits for
  `THE CORAL SNAKE` and `STEELY'S LODGE`; whether these are the same room under new names was not
  confirmed, so they are carried as their own venue and Stay Gold is listed as `ambiguous`.
- **Beerland** matched on taxpayer `BEERLAND, LLC` but the file records its location address as
  1717 E 38th 1/2 St, which is not the Red River premises. The 2007-2018 date range and the 2018
  handoff to `AUSTIN JUKEBOX HOLDINGS, LLC` at 711 1/2 Red River both fit the known history, so the
  match is retained with this caveat.

### 4.7 Denominator
`matched_venues_monthly_agg.csv` carries `travis_austin_all_MB_permits_total` and
`..._n` for every month, so the panel can be expressed as a share of the whole Travis/Austin mixed
beverage market. The matched panel is a stable **~9% of citywide MB receipts** (9.3% in 2013, 8.9%
in 2019, 9.2% in 2025), which makes the divergence between panel and citywide trends interpretable
rather than a coverage artifact.

---

## 5. Retrieval log

| URL / endpoint | Retrieved | Result |
|---|---|---|
| `https://data.texas.gov/api/views/naix-2893.json` | 2026-08-01 | OK — dataset id and 24-column schema confirmed |
| `https://data.texas.gov/resource/naix-2893.json?$select=count(1)` | 2026-08-01 | OK — 3,802,638 statewide rows |
| `https://data.texas.gov/resource/naix-2893.json?$select=count(1)&location_city=AUSTIN` | 2026-08-01 | OK — 241,050 |
| `https://data.texas.gov/resource/naix-2893.json?$select=count(1)&location_county=227` | 2026-08-01 | OK — 255,050 |
| `https://data.texas.gov/resource/naix-2893.csv?$where=...` (6 paged calls) | 2026-08-01 | OK — 267,708 rows |
| `https://api.bls.gov/publicAPI/v2/timeseries/data/` (CUUR0000SA0, 2 calls) | 2026-08-01 | OK — 233 of 234 months; Oct 2025 not published by BLS |

No paywalls, logins, or rate limits were hit on the Comptroller or BLS endpoints.
