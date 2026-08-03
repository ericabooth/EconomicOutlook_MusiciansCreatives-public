# Sources — Creative Economy / BEA ACPSA / NASAA / NEA Evidence
Retrieval date for all items below: **2026-08-01**
Compiled for: Texas 2036 white paper, economics of working musicians in Austin/Texas

---

## TASK 1 — BEA Arts and Cultural Production Satellite Account (ACPSA)

**Landing page:** https://www.bea.gov/data/special-topics/arts-and-culture

**Data vintage: 2023 (most recent available).** Released **April 2, 2025** (BEA news release 25-13).
State-level series cover **2001–2023**; national industry-detail single-year workbooks cover **1998–2023**;
national real (chained 2017 dollar) value-added and gross-output time series cover **1998–2023**.

### IMPORTANT CAVEAT — program status
BEA/NEA posted a notice in **February 2026** stating **BEA will no longer regularly produce ACPSA
statistics** going forward. The April 2025 release (2023 data) therefore appears to be the **final
regular annual release** of this series as of the retrieval date. No 2024-vintage update exists.
This is a material risk factor for any recurring/updatable series in the white paper — flag as a
data-continuity caveat if the report cites ACPSA as an ongoing indicator.
- Confirmed via BEA site text ("BEA will no longer regularly produce these statistics," Feb 2026) and
  cross-check search results (multiple sources citing the FY2023/2025-vintage release as final).

### Files downloaded (raw/bea/)
| File | URL | Contents |
|---|---|---|
| `SAACPSA.zip` | https://apps.bea.gov/regional/zip/SAACPSA.zip | State-level CSVs, 2001–2023, 7 series x 51 areas (50 states + DC) + all-areas rollups |
| `acpsanational.zip` | https://apps.bea.gov/regional/zip/acpsanational.zip | National single-year workbooks (ACPSA_1998.xlsx … ACPSA_2023.xlsx) + 2 real (chained-$) time-series workbooks |
| `acpsa0425.xlsx` | https://www.bea.gov/sites/default/files/2025-03/acpsa0425.xlsx | Release Tables Only (11 tables), FY2023 news release |
| `acpsa0425.pdf` | https://www.bea.gov/sites/default/files/2025-03/acpsa0425.pdf | Full release narrative + tables (15 pp.) |
| `ACPSApdf.zip` | https://apps.bea.gov/regional/zip/ACPSApdf.zip | All-state one-page PDF summary sheets |

Note: the `acpsa0425.xlsx` URL listed on the BEA "Arts and Culture" landing page
(`https://apps.bea.gov/2025-03/acpsa0425.xlsx`) returned an HTML redirect page, not the file. The
working URL is `https://www.bea.gov/sites/default/files/2025-03/acpsa0425.xlsx` (used above).

### State series used (from SAACPSA.zip)
Seven CSV series per state, each with an `_ALL_AREAS_2001_2023.csv` rollup used as primary source:
- `SAACArtsVA` — Value added by industry (thousands of dollars)
- `SAACArtsEmp` — Employment by industry (number of jobs)
- `SAACArtsComp` — Compensation by industry (thousands of dollars)
- `SAACVARatio` — ACPSA value added as a ratio of total state value added (i.e., ACPSA share of state GDP)
- `SAACVALQ`, `SAACCompRatio`, `SAACCompLQ` — location-quotient / ratio variants, downloaded but not
  used in the tidy extracts (available in raw file for further analysis if needed)

LineCode key industries used: 1 = Total state value added (denominator); 10 = Total ACPSA value
added/employment/compensation; 111 = Performing arts companies; 114 = Independent artists, writers,
and performers.

### National totals/industry detail (nominal, current dollars)
Built by looping the 23 yearly `ACPSA_YYYY.xlsx` workbooks (2001–2023) and extracting:
- `Table2_Industry_Output_VA` → Total value added, ACPSA value added, by industry
- `Table4_Employment` → Total/ACPSA employment and compensation, by industry

Music-adjacent industries pulled at national level: Performing Arts Companies; Promoters of
Performing Arts and Similar Events; Independent Artists, Writers, and Performers; Sound Recording;
Musical Instruments Manufacturing.

### National real (inflation-adjusted) time series 1998–2023
- `Real_Value_Added_by_ACPSA_Industry.xlsx` (millions of chained 2017 dollars)
- `Real_Gross_Output_by_ACPSA_Commodity.xlsx` (millions of chained 2017 dollars)
These are **national only** — BEA does not publish a state-level chained-dollar (real) ACPSA series
in the flat-file downloads; state series above are nominal (current dollars) only.

### Tidy CSVs produced (tidy/)
1. `acpsa_state_totals_long_2001_2023.csv` — state x year panel (TX, CA, NY, TN, GA, LA, FL, WA,
   United States), columns: acpsa_value_added_thousands, acpsa_employment_jobs,
   acpsa_compensation_thousands, acpsa_va_share_of_state_gdp, state_total_value_added_thousands.
   US row built from the national single-year workbooks (see above), so units/definitions match the
   state rows exactly (verified: TX 2023 total VA = $65,569,985 thousand, VA share = 0.025, matching
   BEA's public-facing rounding of "$65.6 billion / 2.5%" for Texas in the FY2023 release).
2. `acpsa_state_industry_detail_2001_2023.csv` — same 8 states x year x {Performing arts companies,
   Independent artists/writers/performers}, VA/employment/compensation.
3. `acpsa_national_totals_nominal_2001_2023.csv` — US total VA/employment/compensation/GDP-share,
   2001–2023, nominal.
4. `acpsa_national_industry_detail_nominal_2001_2023.csv` — US industry detail (5 music-adjacent
   industries), 2001–2023, nominal.
5. `acpsa_national_real_value_added_industry_1998_2023.csv` — full industry list, real VA, chained
   2017$, 1998–2023 (long format).
6. `acpsa_national_real_gross_output_commodity_1998_2023.csv` — full commodity list, real gross
   output, chained 2017$, 1998–2023 (long format).

### Cross-checks performed
- TX 2023 totals ($65.6B VA / 2.5% of state GDP / 360,964 jobs / $32.0B compensation) match
  independently-fetched text from the NEA Texas state profile (https://www.arts.gov/impact/state-profiles/texas)
  and the NEA Texas Fact Sheet (Task 3), which round the VA share to "3 percent" rather than 2.5% —
  see caveat in _findings.md.
- No missing/NaN values found in any of the six tidy CSVs (spot-checked with pandas `.isna().sum()`).

---

## TASK 2 — NASAA State Arts Agency Revenues + Texas Commission on the Arts

**NASAA landing pages:**
- https://nasaa-arts.org/research/funding/
- https://nasaa-arts.org/nasaa_research/fy2026-state-arts-agency-revenues-report/

### Reports downloaded (raw/nasaa/)
| File | URL | Published |
|---|---|---|
| `FY2026_State_Arts_Agency_Revenues_Report.pdf` | https://nasaa-arts.org/wp-content/uploads/2026/02/FY2026-State-Arts-Agency-Revenues-Report_final-updated.pdf | 2026-02-11 (PDF metadata); NASAA copyright line dated © 2026 |
| `FY2025_State_Arts_Agency_Revenues_Report.pdf` | https://tsd-wpe-largefs-storage.s3.us-east-1.amazonaws.com/nasaa/fileBucket/2025/02/FY2025-State-Arts-Agency-Revenues-Report_021225.pdf | 2025-02-11 (PDF metadata) |

Both reports are survey-based (NASAA surveys all 56 state/jurisdictional arts agencies each
Oct–Dec for the following fiscal year); FY figures for the "current" year in each report are
enacted/projected, not year-end actuals, and are revised in the companion mid-year report.

### National headline numbers (verbatim from report text)
- FY2026: SAAs received **$646.0 million** in total legislative appropriations (incl. line items),
  a **5.9% decrease** from FY2025 ($694.3M). Excluding line items, $572.9M (+2.6% vs FY2025).
  Per-capita appropriation (incl. line items) fell to **$1.88** (−6% y/y).
- FY2025: $694.3 million total legislative appropriations, an 8.1% decrease from FY2024.
  Per-capita fell to $2.02 (−9% y/y from FY2024).
- Both reports state current funding remains above the pre-pandemic (FY2022) nominal record,
  i.e., the recent year-over-year declines reflect a post-pandemic-surplus normalization rather
  than a funding crisis, per NASAA's own framing — worth treating as an interested-party
  characterization rather than a neutral fact when writing the white paper.

### Tables extracted into tidy CSVs (tidy/), all 56 states/jurisdictions unless noted
1. `nasaa_fy2026_table1_total_legislative_appropriations.csv` — Table 1, FY2025 vs FY2026, incl. line items.
   *Data-cleaning note:* the PDF layout for New Jersey split the state label onto a different text
   line than its dollar figures during extraction; the row was manually reconstructed from the raw
   text ($41,055,000 → $35,455,000, −13.6%) and verified against Table 2's independent New Jersey row.
2. `nasaa_fy2026_table2_appropriations_excl_line_items.csv` — Table 2.
3. `nasaa_fy2026_table5_total_revenue.csv` — Table 5 (all revenue sources).
4. `nasaa_fy2026_table6_per_capita_spending.csv` — **Table 6, the per-capita table** (FY2026): four
   metrics x $/rank pairs — Legislative Appropriation Incl. Line Items, Excl. Line Items, Total State
   Funds, Total Agency Revenue. Ranks are out of 50 states (territories/DC ranked separately, out of 56).
5. `nasaa_fy2025_table6_per_capita_spending.csv` — same table, FY2025, for trend comparison.
6. `nasaa_fy2026_table7_pct_of_state_general_fund.csv` — SAA legislative appropriation as % of each
   state's total general-fund expenditures (NASBO Fiscal Survey of States, Fall 2025 basis); 50 states
   (Pennsylvania general-fund figure marked N/A in source).
7. `nasaa_texas_per_capita_rank_trend_fy2025_fy2026.csv` — Texas-only extract of Table 6, both years,
   for a quick before/after view.

All parsed tables were completeness-checked against the expected 56 (or 50) jurisdiction list with
no missing/duplicate rows after the New Jersey fix above.

### Texas Commission on the Arts (TCA) appropriation history (raw/tca/, tidy/)
- `LAR_2024_2025.pdf` — TCA Legislative Appropriations Request, FY2024–2025 biennium (baseline
  request only; **does not** reflect final enacted supplemental riders/grants, so figures here run
  lower than the actual enacted appropriation — treat as base-funding-level context only).
  https://www.arts.texas.gov/wp-content/uploads/2022/07/2024-2025_LAR_TCA_2022-07-28.pdf
- `FY26_Operating_Budget.pdf` (as of 10/31/2025) — https://www.arts.texas.gov/wp-content/uploads/2026/02/FY26_Operating_Budget_2025-10-31.pdf
- `FY25_Operating_Budget.pdf` (as of 7/31/2025) — https://www.arts.texas.gov/wp-content/uploads/2025/09/FY25_Operating_Budget.pdf
- `tca_appropriation_summary_fy2025_fy2026.csv` — revenue-by-source breakdown for FY2025/FY2026 from
  the two operating budget PDFs above (General Revenue, Federal Funds, Appropriated Receipts, License
  Plate Trust Fund, and totals).
- `tca_nasaa_appropriation_crosscheck.csv` — side-by-side of NASAA's independently-reported TX figures
  vs. TCA's own budget documents. They match closely ($14,319,358 NASAA vs. $14,320,385 TCA enacted GR
  for FY2025; $18,288,573 vs. $18,289,600 for FY2026), a good independent cross-check of both sources.
- Context only (not downloaded as a file): KERA News, "Texas Commission on the Arts Budget Increase,"
  2025-05-30, https://www.keranews.org/arts-culture/2025-05-30/texas-commission-on-the-arts-budget-increase
  — reports the 2026-27 biennium state-funding total rising to **~$39.8 million** (+$5.7M vs. prior
  biennium, against an original $11M ask), and notes TX arts organizations have already lost over $1
  million in NEA support amid federal funding uncertainty.

### Gap / not pursued
A longer (10+ year) TCA appropriation time series from the Legislative Budget Board's biennial
"Fiscal Size-Up" reports (lbb.texas.gov) was **not** pulled — the FY24-25 LAR + two operating budgets
+ NASAA's FY2025/FY2026 series + the KERA article together give a reasonably solid ~2-3 year window
of enacted funding, but a full multi-biennium (e.g., 2012–2026) LBB series would need a separate,
more time-intensive pull if the white paper wants a longer TCA-specific funding history chart.

---

## TASK 3 — NEA Arts and Cultural Industries state profile, Texas

- Page: https://www.arts.gov/impact/state-profiles/texas
- Downloadable fact sheet (raw/nea/texas_fact_sheet_2026produced.pdf):
  https://www.arts.gov/sites/default/files/2025_texas_fact_sheet.pdf
  (filename says "2025" but the PDF's own footer reads "Produced 2026" — treat 2026 as the vintage
  of the document itself; the underlying economic data is the 2023 ACPSA release, same as Task 1.)
- Key figures on the sheet: arts/cultural industries "added 3 percent or $66 billion" to the Texas
  economy and employed 360,964 workers earning $32 billion in wages/benefits (one year, i.e. 2023);
  NEA distributed **$42,484,296** in grants in Texas over the past 5 years; ~40% of TX adults attended
  live music/theater/dance and ~20% visited art exhibits (2022 participation survey).
- **Caveat / discrepancy:** the fact sheet rounds Texas's ACPSA value-added share of state GDP to
  "3 percent," while the underlying BEA ratio table (SAACVARatio, LineCode 10) computes exactly
  **2.5%** for 2023 ($65,569,985K / $2,583,866,227K = 0.02538). Both trace to the same underlying BEA
  release; the difference is presentational rounding on NEA/TCA's part, not a data conflict. Use 2.5%
  as the precise figure and note "~3%" only if quoting NEA/TCA outreach materials directly.
- No separate music-specific or performing-arts-specific breakout appears on the NEA one-pager itself
  (it's a general economic + participation + grant-history summary) — for music-specific national
  industry detail, rely on the BEA-derived files from Task 1 (Sound Recording, Musical Instruments
  Manufacturing, Performing Arts Companies, Independent Artists).

---

## Overall data-quality notes
- All dollar figures in the BEA state/national tidy files are **nominal (current dollars)** unless
  explicitly labeled "real" — do not compare nominal growth rates across years as if inflation-adjusted
  without applying a deflator (e.g., CPI or the BEA chain-type price index) first.
- NASAA figures are **enacted/projected legislative appropriations**, gathered via agency self-report
  survey in Oct–Dec of the preceding calendar year; treat FY "current year" figures as provisional
  until NASAA's companion mid-year report.
- No paywalls or missing-file blockers were encountered; all four BEA downloads, both NASAA PDFs, the
  NEA fact sheet, and three TCA/LAR documents were retrieved successfully on the first or second
  attempt (the BEA release-table XLSX required switching from the `apps.bea.gov` path to the
  `www.bea.gov/sites/default/files` path — see note above).
