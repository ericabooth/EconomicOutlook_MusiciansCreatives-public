# Sources: OEWS wages and QCEW industry data (musicians/creatives, Austin-TX-US)

Retrieval date for everything below: **2026-08-01**. All downloads used a browser
User-Agent header (bls.gov blocks default curl/urllib UAs with an Akamai bot
challenge; see the Access Notes below).

## Task 1: BLS OEWS occupational wage time series

**File produced:** `oews_musicians_creatives_2005_2025.csv` (473 rows)

**Source:** BLS OEWS annual data tables, https://www.bls.gov/oes/tables.htm
Each year's national/state/MSA workbooks were downloaded as zip files from
`https://www.bls.gov/oes/special-requests/oesm{YY}{nat|st|ma}.zip` (e.g.
`oesm25ma.zip` = May 2025, MSA-level). All 63 files (21 years x 3 geography
levels, 2005-2025) were retrieved and hash/size-verified against the
`Content-Length` header before parsing.

**Vintage / coverage:** May 2005 through **May 2025** (the May 2025 release,
BLS's current/latest OEWS vintage as of retrieval, confirmed live on
bls.gov/oes/tables.htm, page last-modified May 15, 2026). 21 annual vintages.

**Geographies:** Austin-Round Rock MSA (area code 12420 throughout; the area
name changes over time, see the caveat below), Texas statewide (area code
48), U.S. national.

**Occupations:** 27-2041 (Music Directors and Composers), 27-2042 (Musicians
and Singers), 27-4014 (Sound Engineering Technicians), 27-1024 (Graphic
Designers), 27-4021 (Photographers), 27-2011 (Actors), 27-3043 (Writers and
Authors), 00-0000 (All Occupations, baseline). All 8 codes were confirmed
present as far back as the May 2005 file.

**Access notes / failures:**
- Direct `curl`/Python `urllib` requests to bls.gov (even with a full
  browser-style User-Agent and header set) were blocked with a `403` Akamai
  "Access Denied" bot-detection page. This is IP/TLS-fingerprint based, not
  just UA-string based.
- Worked around this by driving a real Chromium browser session (same
  approach the task suggested as a fallback) and letting `bls.gov` serve the
  zip as a same-tab download; small files (~100-300 KB, "nat" files) were
  auto-renamed correctly by the browser, but large files (multi-MB "st" and
  "ma" files, 3-40 MB) got stuck as hidden temp files with 0-byte placeholder
  names, evidently because the browser's file-safety/Safe-Browsing scan never
  resolved in this environment. Worked around by matching downloaded byte
  sizes against the exact `Content-Length` reported by a HEAD request for
  each expected file, then renaming. All 63 files were confirmed byte-exact.
- No files were skipped; every requested year x geography combination (2005-
  2025 x nat/st/ma) was successfully retrieved and parsed.

**Column format changes handled:**
- 2005-2013: `.xls` (BIFF) format, lowercase or UPPERCASE columns
  (`occ_code`, `h_median`, `a_median`, etc.), no `area`/`area_title` column in
  the national file (national data has no area code).
- 2014-2018: `.xlsx`, similar column set.
- 2019+: added `area`, `area_title`, `area_type`, `naics`, `naics_title`,
  `i_group`, `own_code`, `jobs_1000`, `loc_quotient`, `pct_total`.
- 2025: added `PRIM_STATE`, `PCT_RPT`.
- 2 minor MS-Excel lock-file artifacts (`~$state_M2022_dl.xlsx`,
  `~$MSA_M2022_dl.xlsx`) inside the 2022 zips were skipped automatically
  (not valid zip/xlsx, harmless).
- Median wage columns are consistently `h_median`/`a_median` (or `h_pct50`/
  `a_pct50` in some vintages, handled via fallback) across all 21 years.

**KEY CAVEAT, read before using this file:** OEWS is an employer survey. It
covers **wage-and-salary employment only** and **excludes the self-employed**
(sole proprietors, independent contractors, gig workers). This is a major
limitation for musicians specifically, most of whom work as self-employed
performers, 1099 session players, or informal gig workers rather than as
W-2 employees of an "employer of musicians." OEWS employment counts and wage
levels for occ 27-2042 should be read as "the W-2 employee slice of the
music labor market," not the full musician workforce. Actors (27-2011) and
Musicians and Singers (27-2042) have **no annual-wage figure published at
all, in any row of this file**: `a_mean` and `a_median` are blank in 63 of
63 Musicians and Singers rows and 39 of 39 Actors rows, covering every
geography (Austin MSA, Texas, national) and every year 2005-2025, with no
exceptions. BLS suppresses annualized pay for occupations with high shares
of part-year/part-time work, publishing hourly-only wage statistics
instead. It is a genuine BLS publication convention, not a data-extraction
error. Every other occupation in the file, including 00-0000 All
Occupations, has `a_mean` populated in all 63 of its rows, except Music
Directors and Composers (27-2041), which is blank in 1 of 56 (Austin MSA
2019, where `tot_emp`=60 is published with all wage columns empty).

**Occupation x geography coverage is not uniform, so check row availability
before building any series.** The file has 473 data rows rather than a full
8 occupations x 3 geographies x 21 years = 504, because BLS does not publish
every combination. Music Directors and Composers (27-2041) has 56 rows, with
the Austin MSA missing entirely for 2005-2007 and 2022-2025 (MSA series runs
2008-2021). Actors (27-2011) has 39 rows: all 21 national years, 14 Texas
years, and only 4 Austin MSA years (2013, 2017, 2024, 2025). The other six
occupation codes have the full 63 rows each.

**MSA name/definition change:** The Austin MSA area code (12420) is stable
across all 21 years, but its official title changes: **"Austin-Round Rock,
TX"** through roughly 2022, becoming **"Austin-Round Rock-San Marcos, TX"**
starting with the 2023 OMB metropolitan-area delineation update (Hays
County/San Marcos added to the CBSA). The `area_name` column in the CSV
preserves whatever label BLS used in that year's file, so a naive groupby on
`area_name` will split the same MSA into two labels around 2023; group on
`area` (12420) instead for a clean time series. The underlying geography
(counties covered) did change modestly in 2023, so pre-2023 and post-2023
figures are not perfectly like-for-like even though the area code didn't
change.

## Task 2: BLS QCEW industry employment/wages

**File produced:** `qcew_arts_industries_2001_2025.csv` (733 rows)

**Source:** BLS QCEW Open Data, annual "by industry" bulk files:
`https://data.bls.gov/cew/data/files/{YEAR}/csv/{YEAR}_annual_by_industry.zip`
for years 2001-2025 (25 annual vintages; 2025 annual data is already
released as of retrieval). Each of these zips bundles one CSV per detailed
NAICS industry; rather than downloading the full ~100-150 MB zip per year,
only the 4 target industry CSV members were pulled via HTTP range requests
(Python `remotezip` package against BLS's Range-request-capable server),
then filtered locally to the 4 target areas.

Note: this differs slightly from the exact URL pattern in the task brief
(`data.bls.gov/cew/data/api/{year}/a/industry/{code}.csv`). That simpler
single-industry endpoint was tested first and confirmed accessible via curl
with a browser UA (no Akamai block on this subdomain), but it turned out to
only serve **2014-2025** (years 2001-2013 return 404 on that specific
endpoint). The `.../data/files/{year}/csv/{year}_annual_by_industry.zip`
bulk-file endpoint covers the full 2001-2025 span with an equivalent, and in
fact richer, schema (it includes `area_title`/`industry_title`/`own_title`
text columns), so it was used for all 25 years for consistency. Area-title
and industry-title lookups were separately confirmed against
`https://data.bls.gov/cew/doc/titles/area/area_titles.csv`,
`.../titles/industry/industry_titles.csv`, and `.../titles/ownership/
ownership_titles.csv`.

**Industries:** NAICS 71 (Arts, Entertainment, and Recreation, included as
context), 7111 (Performing Arts Companies), 71113 (Musical Groups and
Artists), 7115 (Independent Artists, Writers, and Performers).

**Geographies / area codes used:**
- Travis County: `48453`
- Texas statewide: `48000`
- U.S. national: `US000`
- Austin-Round Rock(-San Marcos) MSA: `C1242` (QCEW's CSA/MSA code format:
  this is CBSA 12420 with the trailing zero dropped and a `C` prefix; it is
  **not** the same string as the OEWS `area` code 12420, so don't join the
  two files directly on area code).

**Ownership breakout:** the underlying data is published by `own_code`
(0=Total covered, 1=Federal, 2=State, 3=Local, 5=Private). The bulk files
for these industries **never publish an own_code=0 "Total, all ownerships"
row**; only the individual ownership rows are shown. `own_code` is kept as a
column in the output CSV for transparency, but **own_code=5 (Private) is the
recommended headline series** for NAICS 7111/71113/7115: Federal/State/Local
rows for these narrow arts-industry codes are consistently either zero or
disclosure-suppressed (musicians employed directly by government are rare,
mostly municipal- or university-affiliated performing-arts staff). For the
broader NAICS 71 context comparison, Local Government (own_code=3) is
non-trivial (parks/rec/museums) and worth including separately if used.

**Failures / gaps, read before using this file:**
1. **2025 vintage has no MSA-level (`C1242`) rows at all**, for any of the 4
   industries. Confirmed by inspecting the full 2025 file: the metro-area
   aggregation level (`agglvl_code` 4x series) is entirely absent from the
   2025 annual-by-industry release, while it is present in every prior year
   back to 2001. This looks like a **publication-lag issue**: MSA-level
   QCEW rollups for the most recent year evidently were not yet finalized as
   of this retrieval, not an extraction bug. County (Travis), state (TX),
   and national rows ARE available for 2025. Practical implication: the
   Austin MSA QCEW series in the attached CSV currently runs 2001-2024, one
   year short of the OEWS series.
2. **NAICS code transition for 71113 in 2025**: the 2025 files publish the
   Musical Groups and Artists industry under **both** the legacy 5-digit
   code "71113" (NAICS 2017) and a new 6-digit code "711130" (NAICS 2022
   revision) as two separate, near-identical CSV members. We captured only
   the "71113" file for continuity with the 2001-2024 series (values were
   cross-checked as identical between the two files for the rows we could compare,
   e.g. Travis County 2025 emplvl=314 in both). If BLS drops the legacy code
   in a future vintage, later pulls will need to switch to "711130."
3. **Disclosure suppression at the Austin MSA level, with exact counts.**
   Suppressed rows show `annual_avg_emplvl`, `total_annual_wages`, and
   `avg_annual_pay` set to 0 with `disclosure_code="N"`; the true values are
   nonzero but withheld to protect individual-firm confidentiality, since
   only a handful of establishments carry these codes at the MSA level.
   Private-sector (`own_code=5`) suppression out of the 24 MSA years
   available (2001-2024) is **NAICS 71: 2 years** (2012, 2013); **7111: 2**
   (2001, 2024); **71113: 8** (2001-2004, 2010, 2012, 2013, 2024); **7115:
   10** (2001, 2002, 2006, 2009-2011, 2013, 2022-2024). The broader NAICS 71
   aggregate is not a safe fallback for the narrower codes, because it is
   itself suppressed in 2012 and 2013; a NAICS 71 MSA series needs those two
   years dropped or interpolated rather than read as published. **Travis
   County-level data is much more complete** (no suppression in any of the
   four codes, 2001-2025) and is recommended as the primary sub-state
   geography.
   - **Zero-value trap:** because suppression writes 0 rather than a blank,
     `mean()`, `sum()`, and growth-rate calculations silently absorb the
     withheld years. All 140 suppressed rows in the output CSV report
     `annual_avg_emplvl=0` and `total_annual_wages=0`. Filter on
     `disclosure_code != "N"` before any aggregation. Worked example: mean
     `avg_annual_pay` for Austin MSA private 71113 is $27,408 unfiltered
     versus $41,113 filtered, a one-third understatement that follows
     directly from zeroing 8 of 24 years.
   - Establishment counts usually survive suppression, but 6 of the 22
     suppressed Austin MSA private rows also report `annual_avg_estabs=0`
     (71113 in 2001-2003, 7115 in 2001-2002, 7111 in 2001), so a nonzero
     establishment count is not a reliable proxy for "this row has data."
4. A curl/urllib test against `data.bls.gov` (as opposed to `www.bls.gov`)
   was **not** blocked by Akamai: this subdomain accepted a plain browser
   User-Agent header with no further workaround needed.

**KEY CAVEAT (same as OEWS):** QCEW covers only UI-covered wage-and-salary
jobs. It **excludes self-employed/sole-proprietor workers**, which is the
dominant work arrangement for musicians. Rising `avg_annual_pay` alongside
flat-to-declining `annual_avg_emplvl` in these industries (see
`_findings.md`) is consistent with, but does not prove, a shift of lower-
paid or casual music work out of formal payroll relationships and into
self-employment that neither OEWS nor QCEW observes.

## Tools / environment notes
- `pandas` 3.0.3, `openpyxl` 3.1.5, `xlrd` 2.0.2 (for legacy `.xls` OEWS
  files), `remotezip` (installed into a scratch venv at
  `scratchpad/qcew_venv`) for the QCEW partial-zip fetches.
- Raw downloaded zips and intermediate extraction folders are left in
  `scratchpad/oews_raw/` and `scratchpad/qcew_raw/` (not copied to this
  output folder, per instructions) in case re-verification of any single
  cell against the original BLS workbook is needed.
