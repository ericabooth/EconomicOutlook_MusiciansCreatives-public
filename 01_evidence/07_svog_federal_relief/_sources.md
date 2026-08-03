# Sources — SVOG / Federal Relief Evidence Pack

Retrieval date for all items below: **2026-08-01**

## Task 1 — SVOG award data

1. **SBA SVOG Awards file (full national, all recipients)**
   - URL (working): https://data.sba.gov/sites/default/files/distribution/SBA-ODA-2022-09-001/awards-as-of-7-5-22.xlsx
   - Dataset landing page: https://data.sba.gov/en/dataset/svog
   - Vintage: "Awards as of 07-05-2022" — this is the last file SBA has published to its open-data portal; no newer awards file was found (checked web search for 2023/2024 refreshes, none located as of retrieval date).
   - Caveat / failure encountered: the URL surfaced by web search (`.../dataset/4ad86088-4c7b-4525-9562-ecd9488916c9/resource/.../download/awards-as-of-7-5-22.xlsx`) returned HTTP 404. The working URL above was recovered via WebFetch of the dataset landing page. Use the URL above, not the search-result URL.
   - Contents: 13,011 award records. Fields: Total Awarded (labeled "Initial + Recon + Recon 2.0 + Supplemental" — i.e., a single combined total, not broken out by tranche), Grantee name, Address, City, State, Zip, "Account Venue" (entity type), Awarded Date.
   - Known data-quality issue: the State field has inconsistent casing (e.g., "TX" vs "Tx" vs mixed case appears ~96 distinct string values for what should be ~55 states/territories). All extracts in this folder were built from a **normalized copy** (state upper-cased, trimmed) to avoid undercounting — a naive case-sensitive filter on "TX" alone would miss ~14 Texas records (744 vs. correct 758).
   - USAspending.gov was NOT used as the primary source because the SBA file above was found, is authoritative, and is more complete/detailed than USAspending's assistance-listing 59.075 search interface for this purpose; USAspending was used only as a secondary check path per the task instructions (not queried further once the SBA file was confirmed working).

2. **Raw file retained**: `awards-as-of-7-5-22.xlsx` (scratchpad only, not copied to Drive — see note below on file locations).

## Task 2 — Context PDFs

3. **SBA OIG Report 25-21** — "SBA's Oversight of Shuttered Venue Operators Grant Recipients"
   - URL: https://www.oversight.gov/sites/default/files/documents/reports/2025-07/SBA%20OIG%20Report%2025-21.pdf
   - Also listed at: https://www.sba.gov/document/report-25-21-sbas-oversight-shuttered-venue-operators-grant-recipients (redirects to legacy.sba.gov)
   - Published: July 2025. Most recent official oversight document located.
   - Key figures cited in report: $16.25 billion appropriated (Economic Aid Act, $15B + American Rescue Plan Act, $1.25B); program established Dec 27, 2020; SBA identified $544 million in potential improper payments as of October 2024.
   - Saved to: `context_pdfs/SBA_OIG_Report_25-21.pdf`

4. **CRS Report R46689** — "SBA Shuttered Venue Operators Grant Program (SVOG)" (Congressional Research Service background report)
   - URL: https://www.congress.gov/crs_external_products/R/PDF/R46689/R46689.5.pdf
   - Program background/legislative history, not final-numbers report; kept as context on program design/eligibility.
   - Saved to: `context_pdfs/CRS_R46689_SVOG.pdf`

5. **SBA fact-sheet figure used for cross-check** (not saved as PDF — HTML article only, no PDF version found):
   - "New Report Shows Consequential Impacts of SBA Pandemic Relief" (Jan 15, 2025)
   - URL: https://www.sba.gov/article/2025/01/15/new-report-shows-consequential-impacts-sba-pandemic-relief (redirects to legacy.sba.gov)
   - States: "$14 billion in grant funding went to over 13,000 eligible live performance venues" — this closely matches (within ~4%) the $14.57B sum computed directly from the awards file (13,011 records), which cross-validates the awards file as essentially final/complete despite its July 2022 vintage. The commonly-cited $16.25B figure is the amount **appropriated**, not the amount ultimately **awarded/disbursed** — the gap ($16.25B vs. ~$14.6–14.9B) reflects unawarded/returned funds, admin costs, and possible post-2022 clawbacks per the OIG improper-payments finding above. Flag this distinction explicitly in any report text.
   - No PDF fact sheet/report artifact could be located and downloaded for this specific figure; it exists only as an HTML news article. Documented here per instructions rather than fabricating a saved PDF.

## Task 2 (optional) — PPP subset

6. **SBA PPP FOIA loan-level data** (used to build the optional PPP subset — this WAS attempted and completed, not skipped)
   - Dataset landing page: https://data.sba.gov/dataset/ppp-foia
   - Files used (13 total): `public_150k_plus_240930.csv` (all loans ≥$150k, national, 452MB) + `public_up_to_150k_1_240930.csv` through `..._12_240930.csv` (loans <$150k, split into 12 files, ~400MB each, ~4.8GB combined).
   - Base URL pattern: https://data.sba.gov/sites/default/files/distribution/SBA-OCA-2022-07-001/{filename}
   - Vintage: data as of 2024-09-30 (per filename suffix `_240930`), reflecting loan/forgiveness status as of that date; original loans originated 2020-2021.
   - Method: each file was downloaded in full, streamed row-by-row with Python's `csv` module (NOT naive comma-splitting, to correctly handle quoted fields like `"SUMTER COATINGS, INC."`), filtered to NAICS codes {711130 Musical Groups and Artists, 711310 Promoters of Performing Arts/Sports with Facilities, 722410 Drinking Places (Alcoholic Beverages)} AND (BorrowerState == "TX" OR ProjectState == "TX"), matching rows written out, then the raw multi-hundred-MB file was deleted before moving to the next one (kept disk footprint small; no full national PPP data retained anywhere).
   - Result: 6,546 Texas-linked loan records across the 3 NAICS codes, $345.5M combined `CurrentApprovalAmount`; of those, 816 records / $61.8M are in the Austin-area city list (see below).
   - Important caveat: NAICS self-reported by borrower; 722410 (bars) is a broad category that includes many bars with no live-music programming, and 711130/711310 can include entities only loosely tied to "working musicians" (e.g., symphonies, single-owner LLCs of session musicians, university-affiliated promoters). Treat this PPP subset as a rough upper-bound proxy for the sector, not a precise "musicians" count. Also note some PPP records for the same legal entity appear twice (e.g., separate First Draw and Second Draw loans, or minor name-formatting variants) — these are genuine distinct loan records, not de-duplication errors, but sum with that in mind.
   - BorrowerState field is blank/missing on a meaningful share of PPP rows (confirmed by spot-check of raw file); ProjectState was used as a fallback in the filter to avoid undercounting.

## Austin-area city definition used throughout (both SVOG and PPP extracts)

Applied consistently to both datasets. Core Austin-Round Rock-Georgetown MSA counties (Travis, Williamson, Hays, Bastrop, Caldwell) plus a few unincorporated/exurban place-names that appeared in the raw data and are conventionally treated as "Greater Austin":

Austin, Round Rock, Georgetown, Pflugerville, Leander, San Marcos, Kyle, Buda, Wimberley, Dripping Springs, Driftwood, Manchaca, Bastrop, Dale, Lakeway, Spicewood, Bee Cave (data had a typo "Be Cave," corrected), Cedar Park, Hutto, Taylor, Liberty Hill, Elgin, Lockhart, Luling, Del Valle, Creedmoor.

Not included (judgment call, could be revisited): Marble Falls, Johnson City, Fredericksburg, New Braunfels, Seguin, Kerrville — these are Hill Country/I-35 corridor towns sometimes loosely called "Austin area" in casual usage but are outside the 5-county Census MSA and were excluded to keep the definition defensible. None of them actually appeared as recipients in the Austin-area candidate set anyway (New Braunfels and Kerrville appear in the TX list under non-Austin totals).

## Metro comparison methodology (Houston / Dallas-Fort Worth / Nashville / San Antonio)

These are **city-name string matches within the SVOG file, not official Census MSA definitions** — built quickly for directional comparison only, using an illustrative (non-exhaustive) list of suburb names for Houston and Dallas-Fort Worth. Treat these totals as approximate/lower-bound (some suburbs of each metro are surely missing from the match lists) rather than authoritative MSA totals. Nashville uses "Nashville" city only, which is a reasonably clean proxy because Nashville-Davidson is a consolidated city-county government, so it captures nearly all of Davidson County; it excludes Nashville MSA suburbs (Franklin, Murfreesboro, etc.), meaning the true Nashville-MSA total would be higher than shown here.

## File locations

- Full national raw XLSX + full national normalized CSV + full PPP-filter working files: kept in scratchpad only (`/private/tmp/.../scratchpad/svog/`), NOT copied to the Drive output folder, to keep the Drive folder focused on Texas/Austin extracts + context docs per task instructions. The scratchpad full national CSV (`svog_awards_full_national_normalized.csv`) is available if a reviewer wants the complete underlying file — flagging its existence here in case it's needed later.
- Drive output folder contains: `svog_awards_TEXAS.csv`, `svog_awards_AUSTIN_AREA.csv`, `ppp_TX_music_venues.csv`, `ppp_AUSTIN_music_venues.csv`, `context_pdfs/SBA_OIG_Report_25-21.pdf`, `context_pdfs/CRS_R46689_SVOG.pdf`, this file, and `_findings.md`.
