# Sources — Austin Cost of Living / Housing (09_cost_of_living)

Retrieval date for all entries below (unless noted otherwise): **2026-08-01**
Compiled for: Texas 2036 white paper, economics of working musicians, Austin/Texas.
Agent note: WebSearch unavailable this run; all fetches via direct URL / curl with browser-like User-Agent.

Status key: DONE / PARTIAL / GAP (documented failure, moved on)

---

## 1. Zillow ZORI + ZHVI (metro time series)

Status: DONE

- Landing page https://www.zillow.com/research/data/ is blocked by PerimeterX bot-detection (returned a captcha shell, "Access to this page has been denied") even with a browser User-Agent. Did NOT attempt to solve/bypass the captcha (out of scope / prohibited). Worked around by going directly to the known static CSV endpoints on files.zillowstatic.com, which are NOT behind PerimeterX and returned HTTP 200 immediately.
- Files fetched (retrieved 2026-08-01):
  - ZORI, smoothed, not seasonally adjusted, all-homes-plus-multifamily, metro: `https://files.zillowstatic.com/research/public_csvs/zori/Metro_zori_uc_sfrcondomfr_sm_month.csv`
  - ZORI, smoothed, seasonally adjusted, all-homes-plus-multifamily, metro (bonus/preferred series for trend reading): `https://files.zillowstatic.com/research/public_csvs/zori/Metro_zori_uc_sfrcondomfr_sm_sa_month.csv`
  - ZHVI, all homes (bottom+mid+top tier, i.e. 0.33-0.67 mid-tier is Zillow's standard "all homes" cut), smoothed, seasonally adjusted, metro: `https://files.zillowstatic.com/research/public_csvs/zhvi/Metro_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv`
- Vintage: file headers run through **2026-06-30** (June 2026), consistent with Zillow's typical ~1-month publication lag as of retrieval date 2026-08-01. ZORI series starts 2015-01-31 (Zillow does not publish ZORI before 2015). ZHVI series starts 2000-01-31.
- Geographic identification: Zillow's `RegionName` field uses short metro labels, not full CBSA titles. Confirmed exact strings by grep before extraction: "Austin, TX" (RegionID 394355, SizeRank 29 = the Austin-Round Rock-Georgetown MSA), "Dallas, TX" (394514, rank 4 = DFW metro), "Houston, TX" (394692, rank 5), "San Antonio, TX" (395055, rank 24), "Nashville, TN" (394902, rank 37). These are Zillow's metro-area (not city-proper) series in all cases.
- Output files (tidy long: geo, date, value, series), in this folder:
  - `zillow_zori_notseasadj_5metro_long.csv` (690 rows)
  - `zillow_zori_seasadj_5metro_long.csv` (690 rows) — recommend this as the primary ZORI series for trend charts, since it removes seasonal noise
  - `zillow_zhvi_allhomes_seasadj_5metro_long.csv` (1,589 rows; Austin, Dallas, Houston, San Antonio back to 2000-01; Nashville also back to 2000-01)
- Caveats:
  - ZORI is a repeat-rent index of the *typical* asking/observed rent in the 35th-65th percentile range of the metro rental stock — it is not the same concept as ACS median gross rent (which covers occupied units, all leases, not just currently-listed/turnover units) or HUD FMR (a percentile of gross rent for recent movers). Treat ZORI as a market-rate/asking-rent signal, useful for cyclical turning points, and use ACS/HUD for level comparisons to income.
  - ZHVI file used here is the standard "all homes" mid-tier (0.33-0.67) cut, smoothed and seasonally adjusted — Zillow's most-cited headline series. Raw (non-seasonally-adjusted) ZHVI was not pulled since SA is the standard citation.
  - Full nationwide raw CSVs (multi-MB, ~900+ metros) were downloaded to local scratch only, not copied into this Drive folder, to keep deliverables lean; only the 5-metro tidy extracts are saved here. Raw files can be re-fetched from the URLs above if the full panel is ever needed.

---

## 2. HUD Fair Market Rents (FY1983-FY2026), Austin-Round Rock MSA + 4 comparison metros

Status: DONE (better than requested — got the FULL 1983-2026 history, not just FY2015-2026, and did not need to touch individual per-year files)

- Landing page `https://www.huduser.gov/portal/datasets/fmr.html` loaded cleanly (HTTP 200, no bot-blocking) with a plain curl + browser User-Agent — no PerimeterX-style protection on this HUD USER site.
- Rather than assembling per-fiscal-year files (FY26_FMRs.xlsx, FY25_FMRs.xlsx, ...), the landing page links to a pre-built **all-years-in-one** file, which is far more efficient: `https://www.huduser.gov/portal/datasets/FMR/FMR_All_1983_2026.csv` (also available as `.xlsx` and `.zip` at the same path). Retrieved 2026-08-01, HTTP 200, 8.15 MB, 310 columns, one row per county/HUD-FMR-area.
- Geography: file is keyed by a 10-digit `fips` code = 5-digit county FIPS + 5-digit HUD "cousub" suffix (99999 = whole-county FMR area, which is what all 5 areas used here have — no sub-county split applies to Travis, Dallas, Harris, Bexar, or Davidson counties). Confirmed rows by grep on FIPS:
  - Austin: FIPS `4845399999` = Travis County, HUD metro code `METRO12420M12420`, current (FY2026) area name **"Austin-Round Rock-San Marcos, TX MSA"**
  - Dallas: FIPS `4811399999` = Dallas County, area name "Dallas, TX HUD Metro FMR Area"
  - Houston: FIPS `4820199999` = Harris County, area name "Houston-The Woodlands-Sugar Land, TX HUD Metro FMR Area"
  - San Antonio: FIPS `4802999999` = Bexar County, area name "San Antonio-New Braunfels, TX HUD Metro FMR Area"
  - Nashville: FIPS `4703799999` = Davidson County, area name "Nashville-Davidson--Murfreesboro--Franklin, TN HUD Metro FMR Area"
- Column semantics decoded by inspection (not documented inline in the CSV, so flagging as inferred-but-high-confidence): for each 2-digit fiscal-year suffix YY, `fmrYY_0..4` = FMR for efficiency/studio, 1BR, 2BR, 3BR, 4BR respectively; a bare `fmrYY` column (no bedroom suffix) is NOT a rent dollar amount — it is the **percentile basis** HUD used to set that year's FMR for that area (almost always "40" = 40th percentile standard; a few years show "45" or "50"). Do not confuse this metadata column with a rent value. `areanameYY` columns are populated only for FY2022-2025 in the source file (documenting the pre-FY2026 name); HUD did not retroactively populate area-name-as-published for earlier vintages, so `hud_area_name_as_published` is blank in the tidy output for FY2021 and earlier.
- **Gap, documented and not resolved:** FY1984 has no data — the source file itself has no `fmr84_*` columns at all (confirmed by grepping the header), so this is a genuine hole in HUD's own historical archive, not a parsing error on this end. All other fiscal years 1983, 1985-2026 are present and complete for all 5 areas (43 of 44 possible years).
- **Caveat on metro naming/definition over time:** HUD's own area-name field only documents "Austin-Round Rock, TX MSA" for FY2022-2025 and "Austin-Round Rock-San Marcos, TX MSA" for FY2026. The area code itself changed format from a legacy 3-digit code ("640") through FY2005 to the CBSA-based "METRO12420M12420" from FY2006 onward, which strongly suggests an OMB metro-area redefinition around FY2004-2006 — but the exact pre-2006 official name (possibly "Austin-San Marcos, TX MSA") is **inferred from context, not directly confirmed in this file**, so the tidy CSV leaves `hud_area_name_as_published` blank for FY1983-2021 rather than asserting a name. Travis County itself (the underlying FIPS geography) has not changed, so the FMR level series is continuous and comparable even though the official metro-area label evolved.
- Output file (tidy long: fiscal_year, area_label, county_name, fips_cousub, hud_metro_code, hud_area_name_as_published, percentile_basis, br0, br1, br2, br3, br4), in this folder: `hud_fmr_1983_2026_5area_long.csv` (216 rows = 5 areas x 43 years + header; Austin subset alone is 43 rows, FY1983-2026 excl. FY1984).
- Note: dollar values for FY2026 (`fmr26_*`) arrived in the raw source formatted as text with "$" and thousands-commas (e.g. `"$1,562"`), while all earlier years were plain integers; both were cleaned to plain numbers in the tidy output.

---

## 3. ACS median gross rent (B25064) + median home value (B25077), Travis County + Austin MSA + 4 comparison geos

Status: PARTIAL (good data quality, but time-limited to 2 vintages rather than a full 2010-2026 annual panel — see gap below). Timeboxed to 15 minutes per instructions; came in at ~5 minutes.

- `data.census.gov` (the modern "Explore Census Data" UI) is a pure JavaScript single-page app — fetching the table page URL (e.g. `https://data.census.gov/table/ACSDT5Y2023.B25064?g=050XX00US48453`) returns only an empty HTML shell referencing a JS bundle; there is no server-rendered data or discoverable CSV link in the raw HTML. Two guesses at internal API endpoints (`/api/access/data/table/...`, `/api/explore/table?...`) returned 404 and 403 respectively. Per task instructions, did not attempt api.census.gov (documented as requiring a key we don't have).
- **Worked instead from the ACS "table-based Summary File" bulk product**, a Census Bureau product that (unlike the older sequence-number-based Summary File) ships one plain pipe-delimited `.dat` file per table, with ALL U.S. geographies (state/county/MSA/tract/etc., distinguished by a `GEO_ID` prefix) in a single file. Root: `https://www2.census.gov/programs-surveys/acs/summary_file/`. This path is a plain Apache directory listing (no bot-blocking).
  - Fetched (retrieved 2026-08-01): `.../2024/table-based-SF/data/5YRData/acsdt5y2024-b25064.dat` (median gross rent, 2020-2024 5-year estimates, 543,580 geography rows, 17.3 MB) and the equivalent `b25077.dat` (median home value, 18.5 MB).
  - Also fetched the earliest vintage available in this easy format: `.../2021/table-based-SF/data/5YRData/acsdt5y2021-b25064.dat` and `b25077.dat` (2017-2021 5-year estimates).
  - **Gap: table-based-SF format does not exist before the 2021 vintage** — checked 2010, 2015, 2018, 2019, 2020 directories directly, all returned 404 for this file structure. Pre-2021 ACS data lives only in the old fixed-width, sequence-number-indexed Summary File format, which requires a sequence-to-table crosswalk plus a separate geography file join to decode — assessed as infeasible inside the 15-minute timebox and NOT attempted. **This means the requested "2010-latest" annual time series was not built; only two vintage snapshots exist here: 2017-2021 5-yr and 2020-2024 5-yr.** A fuller historical series (e.g., 2010, 2015 5-yr snapshots) is very likely obtainable later via the data.census.gov UI's own "Download" button (a normal browser session, not curl, can trigger it) or via careful parsing of the legacy Summary File — flagging as follow-up work, not done here.
  - GEO_ID formats decoded by inspection: county = `0500000US` + 5-digit FIPS (e.g., `0500000US48453` = Travis County). MSA = a `310`-prefixed summary-level code, but **the exact middle segment changed between vintages**: 2021-vintage MSA rows use `310M600US` + 5-digit CBSA code, while 2024-vintage MSA rows use `310M700US` + CBSA code (e.g., Austin = CBSA 12420, so `310M600US12420` in the 2021 file vs `310M700US12420` in the 2024 file). This was discovered empirically (grep for the CBSA code, then inspect the matching prefix) since it is not documented inline; flagging as inferred, not from written Census documentation, though the pattern was consistent and unambiguous across all 5 metro codes tested. The change in code plausibly reflects OMB's 2023 metro-area standards revision, which is also when Austin's official metro name gained "-San Marcos" (see HUD section above) — noting this as a plausible but unconfirmed link between the two observations.
  - Value `-666666666` (with MOE `-222222222`) appears as a Census-standard "not available/suppressed" sentinel in these files where sample size is too small — encountered incidentally for an unrelated ZCTA row during exploration, not for any of the 5 target geographies (all 5 counties and 5 MSAs had valid, non-suppressed estimates in both vintages).
- Comparison geographies used: Dallas County (48113) / Dallas-Fort Worth-Arlington MSA (19100); Harris County (48201) / Houston-The Woodlands-Sugar Land MSA (26420); Bexar County (48029) / San Antonio-New Braunfels MSA (41700); Davidson County (47037) / Nashville-Davidson-Murfreesboro-Franklin MSA (34980).
- Output file (tidy long: geo_level, geo_label, geo_code, acs_vintage, acs_period, variable, estimate, moe), in this folder: `acs_median_rent_homevalue_5geo_long.csv` (40 rows = 5 geos x 2 levels x 2 vintages x 2 variables).
- **Caveat — do not directly compare these percent changes to the Zillow ZORI/ZHVI peak-to-trough figures above.** ACS 5-year estimates are rolling averages over their entire 5-year window (e.g., the "2024" vintage blends 2020, 2021, 2022, 2023, and 2024 conditions together), so they substantially smooth out the sharp 2022 peak and 2023-2025 correction that the Zillow monthly index shows directly. The two vintages used here (2017-2021 and 2020-2024) also overlap by zero years but are not adjacent non-overlapping 5-year blocks in a strict sense — treat this as a smoothed multi-year trend check, not a peak/trough read.
- Margins of error (MOE) are carried in the output file for every estimate; county-level home-value MOEs are notably wide relative to the estimate for some geographies (e.g., Travis County 2024 MOE of $6,613 on a $523,000 estimate, roughly 1.3% of the estimate at 90% confidence) — small but not negligible, should be mentioned if these figures are cited with precision in the white paper.

---

## 4. BEA Regional Price Parities (MARPP) + bonus Implicit Regional Price Deflators (MAIRPD)

Status: DONE, first attempt, no issues.

- Direct flat-file zip guessed from the task brief worked exactly as given: `https://apps.bea.gov/regional/zip/MARPP.zip`, retrieved 2026-08-01, HTTP 200, 146 KB, no bot-blocking on apps.bea.gov.
- Zip contains BOTH requested table (MARPP = "Regional price parities by MSA") and a bonus table (MAIRPD = "Implicit regional price deflators by MSA") at no extra fetch cost, each as a ready-to-use CSV, plus footnote/definition XML files.
- Vintage: `MARPP_MSA_2008_2024.csv` and `MAIRPD_MSA_2008_2024.csv`, i.e. annual data **2008-2024** (BEA has not yet released a 2025 RPP vintage as of retrieval date 2026-08-01; BEA regional accounts typically lag ~14 months, so a 2025 release around Dec 2026 is the expected next update — noting this so the white paper doesn't imply 2025-2026 coverage that doesn't exist yet).
- **MARPP (Regional Price Parities)**: an index where the national average = 100.000 in every year (RPPs are a cross-sectional measure of price-level differences across metros in a given year, not a growth index — a value of 120 means "20% more expensive than the US average that year," not "20% higher than some base year"). Five LineCodes decoded from the bundled definition XML: 1 = All items, 2 = Goods, 3 = Services: Housing, 4 = Services: Utilities, 5 = Services: Other. Extracted LineCodes 1 and 3 (as the task requested "all-items and housing/rents") for Austin plus Dallas-Fort Worth, Houston, San Antonio, and Nashville MSAs — output also includes LineCodes 2, 4, 5 since they were free to keep in the same pull.
- **MAIRPD (Implicit Regional Price Deflator)** = RPP x national PCE price index (per BEA's own definition text bundled in the zip); unlike RPP, this DOES vary over time as a true deflator (base year 2017=100 for the whole series), so it is the correct tool if the white paper wants to convert nominal musician income into real, inflation-and-region-adjusted dollars across years. Not explicitly requested in the task brief but included because it was bundled in the same zip at zero extra cost and is directly useful for the wage side of this white paper.
- Output files (tidy long), in this folder:
  - `bea_rpp_marpp_5metro_long.csv` (geo_fips, geo_label, series, year, rpp_index_us100; 510 rows = 6 geos [5 metros + US] x 5 series x 17 years)
  - `bea_irpd_mairpd_5metro_long.csv` (geo_fips, geo_label, year, implicit_regional_price_deflator_us2017base100; 102 rows = 6 geos x 17 years)
- Caveats:
  - RPPs are constructed from a mix of ACS housing-cost microdata (for the housing component) and BLS/other price data (for goods/other services), all benchmarked to national BEA PCE totals — this is a modeled/imputed index, not a direct price collection in every metro every year, per BEA's standard methodology notes (not re-derived here, just flagging the general known limitation of RPPs).
  - Housing RPP specifically is the most volatile and most relevant series for this white paper; all-items RPP for Austin is actually **below** 100 in most years (Austin's broad consumption basket is cheaper than the US average) even though housing RPP is well above 100 — these tell very different stories and should not be conflated. See `_findings.md` for the exact numbers.

---

## 5. MIT Living Wage Calculator, Travis County (optional item — time remained, so completed)

Status: DONE, first attempt.

- `https://livingwage.mit.edu/counties/48453` (48453 = Travis County FIPS) — plain server-rendered HTML, no bot-blocking, retrieved 2026-08-01, HTTP 200.
- Page's own metadata reports a build date of 2026-02-15 (poverty-wage line uses HHS 2026 guidelines; minimum-wage line uses Labor Law Center data as of January 2026) — i.e., this is a current, within-the-year vintage relative to our 2026-08-01 retrieval date, not stale.
- Extracted 1-adult/0-children hourly benchmarks (Living Wage $23.69, Poverty Wage $7.67, Minimum Wage $7.25) and the annual required-income and housing-line-item figures. Full detail and caveats saved as its own dated markdown file per task instructions (not folded into this sources log) at `mit_living_wage_travis_county_20260801.md` in this same folder.
- Caveat: this is a single point-in-time budget-based benchmark, not a market price or a time series; see the dedicated .md file for the full methodological caveat before citing it alongside the market-rate series above.

---

## Overall completeness summary

| # | Source | Status | Time spent (approx) |
|---|---|---|---|
| 1 | Zillow ZORI + ZHVI | DONE | ~10 min |
| 2 | HUD FMR FY1983-2026 | DONE (exceeded scope: got full history, not just FY2015-26) | ~10 min |
| 3 | ACS B25064/B25077 | PARTIAL (2 vintages, not full 2010-2026 annual panel — see gap above) | ~5 min (within 15-min timebox) |
| 4 | BEA RPP + bonus IRPD | DONE | ~2 min |
| 5 | MIT Living Wage | DONE (optional item) | ~3 min |

No source hung. Every attempted fetch either succeeded within a few tries or failed fast (404/403) and was documented rather than retried indefinitely, per task instructions. The only genuine, unresolved gap is the pre-2021 annual ACS panel (item 3) — everything else requested was obtained, several items (full HUD history back to 1983, BEA bonus IRPD table, MIT optional item) exceeded the minimum ask.
