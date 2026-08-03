# Sources, retrieval log, and caveats
**Project:** Texas 2036 economics-of-working-musicians white paper — ACS PUMS + Nonemployer Statistics evidence
**Retrieval date (all files below):** 2026-08-01
**Retrieved by:** automated data-collection pass, on behalf of Eric Booth / Texas 2036

---

## 0. IMPORTANT BLOCKER — Census API requires a key; no key was available

The task asked for pulls "via the Census API." As of 2026-08-01, **every Census Data API data-query endpoint now requires an API key** (metadata/variable-list endpoints, e.g. `.../variables.json`, still work without one). Confirmed directly:

```
curl -i "https://api.census.gov/data/2024/acs/acs5/pums?get=SEX,PWGTP,MAR&for=state:48&SCHL=24"
-> HTTP/1.1 302, header "X-DataWebAPI-KeyError: 1", redirect to https://api.census.gov/data/missing_key.html
```
Same result for `/data/2023/acs/acs5/pums` and `/data/2022/nonemp`. No `CENSUS_API_KEY` was found in this environment (checked shell env vars and project-adjacent config; did not do an unrestricted filesystem credential search). Getting a key requires submitting an email at https://api.census.gov/data/key_signup.html — I did not do this myself since it is account/registration-adjacent; **Eric, if you want live API access for future refreshes, request a free key there (arrives by email in minutes) and store it as `CENSUS_API_KEY`.**

**Workaround used (no key needed, same underlying data, arguably more reliable for full-state bulk pulls):** downloaded the bulk CSV files directly from the Census FTP-style file server (`www2.census.gov`) for both PUMS and Nonemployer Statistics. This is a documented Census-supported alternative and is what the task instructions anticipated ("if too large for API... pull a documented alternative"). All figures below come from these bulk files, not the API.

---

## 1. ACS PUMS — data dictionary + occupation code verification

- **Data dictionary (downloaded, saved in this folder):** `PUMS_Data_Dictionary_2020-2024.pdf`
  URL: https://www2.census.gov/programs-surveys/acs/tech_docs/pums/data_dict/PUMS_Data_Dictionary_2020-2024.pdf
  Vintage: 2020-2024 ACS 5-Year PUMS (released by Census 2026-03-05; this is the newest 5-year PUMS available as of 2026-08-01, superseding 2019-2023).
- **User guide (referenced, not saved):** https://www2.census.gov/programs-surveys/acs/tech_docs/pums/2020_2024ACS_PUMS_User_Guide.pdf

### Verified OCCP codes (2018 Census occupation recode, used 2018+ vintages)

All 9 target OCCP codes were verified directly against the data dictionary (search terms "Musician", "Composer", "ENT-"). The two music codes are easy to transpose, so read them off this table rather than from memory:

| OCCP | Label (verbatim from dictionary) | Notes |
|---|---|---|
| 2751 | ENT-Music Directors and Composers | easily transposed with 2752; check before use |
| 2752 | ENT-Musicians and Singers | easily transposed with 2751; check before use |
| 2905 | ENT-Other Media and Communication Equipment Workers | closest available proxy for sound engineers; see caveat below |
| 2634 | ENT-Graphic Designers | |
| 2910 | ENT-Photographers | |
| 2700 | ENT-Actors | |
| 2850 | ENT-Writers And Authors | 2840 = Technical Writers is a separate, narrower code, not pulled |
| 2710 | ENT-Producers And Directors | |
| 2740 | ENT-Dancers And Choreographers | |

**Caveat on "Broadcast/Sound Engineering Technicians":** PUMS does **not** publish a standalone code for sound engineers. At the OCCP level, code 2905 "Other Media and Communication Equipment Workers" is an aggregate bucket. Cross-checked against the SOCP (6-digit Standard Occupational Classification) code list in the same dictionary: the detailed SOC codes for Audio and Video Technicians (27-4011), Broadcast Technicians (27-4012), Sound Engineering Technicians (27-4014), and Lighting Technicians (27-4015) are all collapsed into a single aggregate SOCP code "2740XX" for disclosure-avoidance/sample-size reasons — even the more detailed SOCP variable cannot isolate "sound engineer" alone. OCCP 2905 is the closest available proxy and is what was pulled; treat it as broadcast+AV+sound+lighting techs combined, not sound engineers specifically.

Other nearby ENT codes that exist but were **not** pulled (task didn't request them, noting for completeness): 2755 Disc Jockeys Except Radio; 2770 Entertainers/Performers Sports and Related NEC; 2805 Broadcast Announcers and Radio Disc Jockeys; 2840 Technical Writers.

### Person-file variables
Confirmed all requested variables exist in `psam_p48.csv` (2020-2024 5-Year, Texas): `SERIALNO, SPORDER, PUMA, STATE, OCCP, COW, ESR, WAGP, SEMP, PERNP, PINCP, WKHP, WKWN, AGEP, SEX, RAC1P, HISP, SCHL, HICOV, PRIVCOV, PUBCOV, MAR, PWGTP, ADJINC`.
- **Naming note:** the state FIPS variable is named `STATE` in 2017+ vintage PUMS files, not `ST` (that was the pre-2017 name). Renamed to `ST` in the output CSVs to match the task spec / older convention.
- **WKWN vs WKW:** `WKWN` (numeric weeks worked past 12 months) exists directly in 2020+ vintage files and was used; `WKW` (the older categorical version) is not in this vintage.
- **ADJINC caveat (important for downstream analysis, not applied here):** dollar variables (WAGP, SEMP, PERNP, PINCP) are reported in the nominal dollars of whichever of the 5 sample years (2020-2024) each record was collected in. Census supplies `ADJINC` (income/earnings adjustment factor, 6 implied decimals) to convert everyone to constant dollars before pooling/comparing across years: adjusted $ = raw $ × ADJINC / 1,000,000. Factors from the dictionary: 2020=1.222017, 2021=1.193241, 2022=1.117193, 2023=1.049470, 2024=1.015250 (all rebased to 2024 dollars). **`ADJINC` is included in the extract but the medians reported in `_findings.md` are UNADJUSTED / nominal** — this is a data-collection pass only; apply ADJINC before any real earnings comparison. Same logic applies to housing dollars via `ADJHSG`.

### Newest vintage confirmation
2020-2024 5-Year PUMS Texas files, downloaded 2026-08-01:
- Person: https://www2.census.gov/programs-surveys/acs/data/pums/2024/5-Year/csv_ptx.zip (190.7 MB zipped; `psam_p48.csv`, 864,333,883 bytes, 1,326,296 lines incl. header)
- Housing: https://www2.census.gov/programs-surveys/acs/data/pums/2024/5-Year/csv_htx.zip (76.3 MB zipped; `psam_h48.csv`, 335,408,393 bytes, 606,115 lines incl. header)
- Note the URL path uses the **end year only** (`/pums/2024/5-Year/`), not the year-range folder name — `/pums/2020-2024/5-Year/` (which appears in some documentation prose) 404s; the real FTP directory is keyed by end year, confirmed via directory listing.
- No fallback to 2019-2023 was needed; 2020-2024 was available and used throughout.

### Output files
1. `pums_musicians_creatives_TX_2020_2024_5yr.csv` — person-level records for the 9 target OCCP codes above, Texas, 2020-2024 5-yr PUMS. 5,694 unweighted rows (header + 5,695 lines). Includes an `occp_label` column. **This extract applies no age or labor-force filter:** it spans ages 16 to 92 and includes people not in the labor force and unemployed people (for Musicians and Singers, OCCP 2752: 206 records with `ESR=6` and 32 with `ESR=3` out of 885). ACS assigns OCCP from a respondent's current *or most recent* job, so a retired or non-working person keeps a musician occupation code.
2. `pums_baseline_TX_workers18to64_2020_2024_5yr.csv` — comparison baseline: all Texas person records with `AGEP` 18-64 and `ESR` in {1,2,4,5} (civilian or armed-forces employed, at work or with a job but not at work, confirmed against the ESR code list in the dictionary). 555,102 unweighted rows. This was feasible as a direct bulk-file subset (no API size constraint applied since we bypassed the API entirely).

   > **Base matching is required before comparing file 1 against file 2.** The two files cover different populations as saved: file 1 is unrestricted, file 2 is restricted to employed persons aged 18 to 64. Taking a median or share from file 1 and setting it against file 2 without applying the same `ESR` and `AGEP` filters to file 1 mixes populations and biases the occupation figures downward, because records for people who are not working stay in the numerator with zero or negative earnings. In the occupation extract, 126 of the 885 Musicians and Singers records (14.2%) report `PERNP` of zero or less, and 109 of those 126 are people not in the labor force. Apply `ESR` in {1,2,4,5} and `AGEP` between 18 and 64 to file 1 before any comparison against file 2; the figures in items 3 through 7 of `_findings.md` use that restriction. The variables most sensitive to it are `PERNP`, the self-employment share, and `WKHP`.
3. `pums_housing_costburden_TX_2020_2024_5yr.csv` — housing-file subset: `SERIALNO, PUMA, ST, ADJHSG, WGTP, TEN, GRNTP, GRPIP, OCPIP` for all 606,114 Texas housing records. **Join key: `SERIALNO`** (household ID) matches between the person file and housing file 1:1 per household (all persons in a household share one SERIALNO; join person-level records to this file on SERIALNO to attach household cost-burden/tenure). `GRPIP` = gross rent as % of household income (renters), `OCPIP` = selected monthly owner costs as % of household income (owners), `TEN` = tenure (own/rent), `GRNTP` = gross rent dollar amount. Not subset to any occupation — full Texas households, to be joined downstream.
4. `puma_austin_msa_crosswalk_2020.csv` — 2020-vintage PUMA-to-county crosswalk for the Austin MSA, built from the Census Bureau's official 2020 Census Tract-to-2020-PUMA relationship file (https://www2.census.gov/geo/docs/maps-data/data/rel2020/2020_Census_Tract_to_2020_PUMA.txt, downloaded 2026-08-01), filtered to Texas (STATEFP=48) and the 5 target counties, then de-duplicated to unique (county, PUMA) pairs. County FIPS confirmed against Census's national county gazetteer (`_datashare/County_Crosswalks/01_raw/census_national_county2020.txt`): Bastrop=021, Caldwell=055, Hays=209, Travis=453, Williamson=491.
   - **MSA definition double-checked, not just assumed:** cross-referenced against the current (2023) OMB Core-Based Statistical Area delineation file, https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2023/delineation-files/list1_2023.xlsx (downloaded 2026-08-01). Confirms these exact 5 counties make up the metro area — current official OMB title is **"Austin-Round Rock-San Marcos, TX"** (renamed from the older "Austin-Round Rock" / "Austin-Round Rock-Georgetown" titles Eric may have seen in older sources; same 5 counties, no boundary change).
   - Result: 16 distinct 2020-PUMA codes cover the 5-county MSA. Bastrop and Caldwell counties **share one combined PUMA (05100)** — both are individually below the ~100k population threshold needed to form a standalone PUMA, so Census grouped them. Hays has 2 PUMAs (05401-05402), Williamson has 4 (05201-05204), Travis has 9 (05301-05309).
   - **Usage caveat:** because Bastrop and Caldwell share a PUMA, PUMS microdata cannot distinguish between these two counties on its own — any Austin-MSA subset is clean, but a Bastrop-only or Caldwell-only subset is not possible from PUMS geography.

---

## 2. Census Nonemployer Statistics (NES)

- **API also blocked without a key** (same `X-DataWebAPI-KeyError` on `/data/2022/nonemp` and `/data/2023/nonemp`; metadata endpoints like `/data/2022/nonemp/variables.json` did work without a key and were used only to confirm variable names, not to pull data).
- **Bulk files used instead** (Census-published historical-datasets ZIPs, no key required), downloaded 2026-08-01:
  - County-level: `https://www2.census.gov/programs-surveys/nonemployer-statistics/datasets/{YEAR}/historical-datasets/nonemp{YY}co.zip` for YEAR = 2012...2023 (all 12 confirmed to exist and downloaded; 2024 NES is **not yet released** — checked `.../2024/historical-datasets/nonemp24co.zip` → 404, and the 2024 landing page `https://www.census.gov/data/datasets/2024/econ/nonemployer-statistics/2024-ns.html` → 404. 2023 is the latest available vintage as of 2026-08-01.)
  - State-level (for true Texas statewide totals, not a sum of possibly-suppressed counties): `https://www2.census.gov/programs-surveys/nonemployer-statistics/datasets/{YEAR}/historical-datasets/nonemp{YY}st.zip`, same year range. State file has an extra `LFO` (legal form of organization) field; filtered to `LFO="-"` (all legal forms combined) to match the county file's structure (county file has no LFO breakdown).
- **Record layout** (both files): `ST, CTY (county file only), NAICS, ESTAB_F, ESTAB, RCPTOT_N_F, RCPTOT_F, RCPTOT` (state file adds `LFO` between CTY-position and NAICS). `RCPTOT` = total receipts in **thousands of nominal dollars**, not inflation-adjusted across years — no deflator applied here (documenting only, not modeling). `ESTAB_F`/`RCPTOT_F`/`RCPTOT_N_F` are Census data-quality/suppression flags; blank = not suppressed, `G`/`H`/other letters = various disclosure-avoidance flags — spot-checked and most rows for our target NAICS/counties are unflagged, but a few small-county/small-NAICS cells may carry flags (not scrubbed out, left in the file for transparency — check the flag columns before treating a 0-row absence as a true zero).
- **NAICS detail actually available at the county level** (verified by direct inspection of Travis County 2023 rows, not assumed): 71, 711, 7111, 7112, 71121, 7113, 7114, 71141, **7115, 71151** (71151 = 711510 Independent Artists, Writers, and Performers is the only 6-digit child of 7115, i.e. 7115 and 71151 are numerically identical in this table — both pulled for clarity/redundancy but they will match exactly), 712, 7121, 713, 7131, 7132, 7139. The codes this project uses (711, 7111, 7115/71151) are all available at county level.
- Counties pulled: Travis (453), Williamson (491), Hays (209), Bastrop (021), Caldwell (055) [Austin MSA]; Harris (201), Dallas (113), Tarrant (439), Bexar (029) [comparison metro cores]; plus Texas statewide (from the state file). Years: 2012-2023 (12 years, annual).
- **Output file:** `nes_independent_artists_long.csv` — long panel, 1,073 rows, columns: `year, geo_level (county/state), st_fips, cty_fips, county_name, naics, estab_flag, estab, rcptot_not_avail_flag, rcptot_flag, rcptot_thousands`.

---

## 3. What was NOT done / deferred (honest gaps)

- **No live Census API pull was made for anything** — see blocker #0. Everything is from bulk downloadable files instead. Functionally equivalent data, same vintages, but if the white paper methodology section says "via Census API" that would be inaccurate; recommend describing the source as "Census Bureau PUMS/NES bulk data files."
- **No inflation/dollar-year adjustment applied anywhere** (ADJINC/ADJHSG for PUMS; no deflator for NES receipts). Raw/nominal dollars only, as instructed (data collection, not modeling).
- **Housing file pulled as full Texas** (606,114 households), not pre-joined to the occupation extract or subset to Austin. SERIALNO join documented above; left for the analysis phase.
- **PUMS is current/primary occupation only.** ACS OCCP reflects a respondent's current or most recent job; someone who gigs as a musician on the side of a day job, or between engagements, generally will not show up under OCCP=2752 unless music is their primary/most-recent job. This is a first-order limitation for a "working musicians" paper and should be flagged prominently in the write-up (the PUMS counts are a lower bound on people who perform music for pay).
- **Sample sizes for the target occupations are small** even pooling 5 years of ACS (e.g., Musicians and Singers = 885 unweighted TX records, 129 in the Austin MSA). Standard errors on any Austin-only cross-tab (e.g., by race, by age band) will be wide; recommend checking PUMS replicate weights (PWGTP1-80, present in the raw file but dropped from these curated extracts to keep file size down) if the paper needs a formal margin of error — **the 80 replicate-weight columns were dropped from the curated CSVs to save space; re-pull from `psam_p48.csv`/`psam_h48.csv` (still in the scratchpad-referenced raw download, not committed to Drive) if variance estimation is needed later.**
- **Nonemployer Statistics counts establishments, not people** — a self-employed musician who also nonemployer-registers a side LLC could appear differently than one who doesn't formalize at all; NES is a good proxy for gig-economy formalization trends, not a person count. Also excludes anyone who is nonemployer AND has no receipts reported to IRS (informal/cash gig work is likely undercounted).
- Did not attempt Census API key signup (borderline "create an account" action) — flagged to Eric above as a quick thing he could do himself for future live-refresh workflows.
