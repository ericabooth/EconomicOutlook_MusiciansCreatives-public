# Sources log — Task 3 (venues & ecosystem)

Retrieval date for every entry: **2026-08-01**. Tooling: `curl` with a desktop Chrome
User-Agent, Python `urllib`, and a server-side fetch service. Times are UTC.

---

## A. Texas Music Office directory

| # | URL | HTTP | Outcome / caveat |
|---|---|---|---|
| A1 | `https://texasmusic.reel-scout.com/crew_directorylist.aspx?type=S` | 403 | Cloudflare managed challenge (`cf-mitigated: challenge`). Body is the "Just a moment..." interstitial. Not bypassed. |
| A2 | `https://texasmusic.reel-scout.com/` | 403 | Same challenge. |
| A3 | Same as A1 via server-side fetch service | 403 | Confirms the block is not specific to one client or IP. |
| A4 | `https://gov.texas.gov/music` | 200 | **Worked.** Source of the three verified directory entry points (`type=S`, `type=B`, `type=M`) and the economic-impact link. |
| A5 | `https://gov.texas.gov/music/directory` | 404 | Path does not exist. |
| A6 | `https://music.texas.gov` | — | Connection failed: TLS certificate could not be verified. No response body. |
| A7 | `https://gov.texas.gov/apps/music/directory/Default.aspx` | 500 | Retired application. |
| A8 | `https://gov.texas.gov/Apps/Music/Directory/results/All/region/austin/p1` | 500 | Retired. |
| A9 | `https://gov.texas.gov/Apps/Music/Directory/results/All/region/dfw/p76` | 500 | Retired. URL came from a live search index, so that index is stale. |
| A10 | `https://gov.texas.gov/Apps/Music/Directory/results/Media/p8` | 500 | Retired. |
| A11 | `https://gov.texas.gov/Apps/Music/Directory/talent/all/genre/all/p334` | 500 | Retired. |
| A12 | `https://gov.texas.gov/Apps/Music/Directory/results/txorganizations/p1` | 500 | Retired. |
| A13 | `https://gov.texas.gov/Apps/Music/Directory/` and `/apps/music/directory` | 500 | Retired. |
| A14 | `http://web.archive.org/cdx/search/cdx?url=texasmusic.reel-scout.com*` | 200 | **Worked.** Only three directory pages archived, all April 2025. No `crew_print.aspx` detail pages archived. |
| A15 | `http://web.archive.org/cdx/search/cdx?url=gov.texas.gov/apps/music/directory*` | 200 | **Worked.** Confirms the legacy app's URL structure and category slugs, 2017–2025. |
| A16 | `https://web.archive.org/web/20250413id_/https://texasmusic.reel-scout.com/crew_directorylist_content.aspx?type=S` | 200 | **Worked.** 188 KB. Source of the 106-option Music Business category list, 32 genres, 35 markets, and 50 listing rows. |
| A17 | Same, `?type=B` (snapshot 20250417) | 200 | **Worked.** 54 categories, 13 markets, 249 cities, 50 rows. |
| A18 | Same, `?type=M` (snapshot 20250417) | 200 | **Worked.** 73 categories, 35 markets, 488 cities, 50 rows. |
| A19 | `https://gov.texas.gov/music/page/economic-impact-study` | 200 | **Worked.** Index of 2015–2025 impact reports. |
| A20 | `https://gov.texas.gov/uploads/files/music/TXP_TX_Music_Impact_Winter_2025.pdf` | 200 | **Worked.** 356 KB, 5 pages. Saved as `TXP_TX_Music_Impact_Winter_2025.pdf`. Full text extracted. |
| A21 | `https://www.austintexasmusicians.org/blog/texas-music-office-launches-the-new-texas-music-industry-database` | 200 | **Worked.** Third-party "15,000+ listings" claim. Not verifiable against the live directory. |

**Caveats for section A**
- No live listing counts were obtained. `tmo_counts.csv` was not created rather than estimated.
- The archived snapshots show the first results page only (50 rows each, 150 total). No venue
  listing appears in the sample because the VENUES category sorts after COMMERCIAL MUSIC.
- Count figures surfaced by web search (6,955 musicians; 1,900 DFW; 1,158 Houston; 1,387 Country;
  522 Media; 446 organizations) trace to pages that now return HTTP 500 and were rejected as stale.
- The directory results grid carries no address, phone, or county. Those live only on per-listing
  detail pages, none of which are archived.

---

## B. City of Austin open data

**Portal migration found.** `api.us.socrata.com/api/catalog/v1?domains=data.austintexas.gov`
returns HTTP 200 with `resultSetSize: 0` for every query. The catalog now indexes Austin assets
under **`datahub.austintexas.gov`**. The legacy host `data.austintexas.gov` still serves
`/api/views/<id>.json` and `/resource/<id>.csv` for the same asset ids, and was used for the
downloads. Anyone reusing this work should query the catalog against `datahub.austintexas.gov`.

| # | Endpoint | HTTP | Outcome |
|---|---|---|---|
| B1 | `http://api.us.socrata.com/api/catalog/v1?...` (as given in the task) | 301 | Plain HTTP redirects; must follow to HTTPS or the body is a 162-byte redirect stub. |
| B2 | `https://api.us.socrata.com/api/catalog/v1?domains=data.austintexas.gov&q=<term>` | 200 | **0 results for all 9 terms.** Stale domain in the catalog index. |
| B3 | `https://api.us.socrata.com/api/catalog/v1?domains=datahub.austintexas.gov&q=<term>` | 200 | **Worked.** Terms run: music (33), venue (4), entertainment (30), live music (6), cultural (93), arts (41), nightlife (0), outdoor music (3), sound permit (4), noise (0), creative (21), special event (15), live music fund (2), music venue (4), elevate (17), nexus grant (0), heritage preservation (2), hotel occupancy (2). 115 unique assets after dedupe. |
| B4 | `https://datahub.austintexas.gov/api/views/<id>.json` | 200 | **Worked** for all 16 ids queried. Field lists and descriptions. |
| B5 | `https://data.austintexas.gov/resource/<id>.json?$select=count(*)` | 200 | **Worked.** Row counts for all 15 downloaded datasets. |
| B6 | `https://data.austintexas.gov/resource/<id>.csv?$limit=200000` | 200 | **Worked.** 15 CSVs downloaded; CSV row counts match API counts exactly in all 15 cases. |

**Caveats for section B**
- Two vintage warnings on the venue registries: `qxfh-ycp7` (Creative Workspaces / Performance
  Venues) was last refreshed **2016-11-11**, and the CAMP directories date to 2017 and 2018. They
  describe the venue stock of roughly a decade ago, not 2026.
- `x6aj-qng8` (Cultural Funding Awards) stores `fiscal_year` as a timestamp and the series has
  gaps (no 1989, 1992, 2022) and three separate 2023 entries (2023-01-30, 2023-07-30, 2023-09-30),
  which look like distinct award cycles rather than fiscal years. It has only 3 columns
  (fiscal_year, contractor, award), so **Live Music Fund awards cannot be separated** from cultural
  arts or heritage awards in this file.
- No dataset named "Live Music Fund" exists on the portal. The `live music fund` query returned
  only `x6aj-qng8` and `r5j2-ynwq`.
- No music-venue *registry* or licensing dataset exists. Sound Ordinance Permits (`ryu3-tuin`) is
  the closest operational substitute.
- `teth-r7k8` (ACE Events, 54,169 rows, 15.6 MB) was downloaded in full; it is the largest file.

---

## C. State of Texas open data (TABC)

| # | Endpoint | HTTP | Outcome |
|---|---|---|---|
| C1 | `https://api.us.socrata.com/api/catalog/v1?domains=data.texas.gov&q=TABC` | 200 | **Worked.** 13 assets. |
| C2 | `https://data.texas.gov/api/views/7hf9-qc9f.json` | 200 | **Worked.** 47 fields. |
| C3 | `https://data.texas.gov/resource/7hf9-qc9f.json?$select=count(*)` | 200 | **125,902 rows.** Not downloaded (size). |
| C4 | `.../7hf9-qc9f.json?$group=license_type` | 200 | **Worked.** 29 license-type codes. |
| C5 | `.../7hf9-qc9f.json?$group=county` | 200 | **Worked.** Travis 6,287; Harris 19,911; Dallas 9,628; Bexar 7,487; Tarrant 7,231. **10,514 rows have a blank county.** |
| C6 | `.../7hf9-qc9f.json?$where=upper(city)='AUSTIN'&$group=license_type` | 200 | **Worked.** Austin: MB 2,086; BG 1,175; BQ 891; NT 614. |
| C7 | `https://data.texas.gov/api/views/kguh-7q9z.json` + count | 200 | **Worked.** 78,187 rows, 11 fields. |

**Caveats for section C**
- **Neither TABC file carries a premise-type or business-type field.** There is no way to isolate
  live-music venues from license data alone. `license_type` distinguishes beverage privileges
  (MB = mixed beverage, BG, BQ, NT and so on), not whether a room books bands.
- The ~10,514 blank-county rows in `7hf9-qc9f` mean county-level filtering undercounts. Filter on
  `city` as well as `county`.
- `naix-2893` (Mixed Beverage Gross Receipts) was identified but not pulled. It reports monthly
  receipts per permitted location and is the strongest candidate for a venue-level revenue time
  series. Recommend a targeted Travis County extract in a follow-up.

---

## D. Files written to this directory

| File | Rows | Note |
|---|---|---|
| `tmo_directory_notes.md` | — | Task A findings, taxonomy, manual-export procedure. |
| `tmo_listings_austin.csv` | 40 | Archived-snapshot sample. **Not a census.** No venues in it. |
| `tmo_listings_archived_sample_all.csv` | 150 | All rows recovered from the three snapshots. |
| `TXP_TX_Music_Impact_Winter_2025.pdf` | — | Primary source for state economic-impact figures. |
| `austin_open_data_catalog.csv` | 47 | Every candidate evaluated, downloaded or not, incl. 4 TABC entries. |
| `austin_*.csv` (15 files) | see catalog | Downloaded Austin datasets. |
| `_sources_task3.md` | — | This file. |

`tmo_counts.csv` was **not** written. No category or geography count could be read off any page,
and inventing one was not acceptable.

**Not authored by this task:** `articles/`, `venue_timeline.csv`, `venue_summary.csv`,
`venue_match_list.csv`, `venue_monthly_receipts_long.csv`, `matched_venues_annual.csv`,
`matched_venues_monthly_agg.csv`. These were already present in the output directory.
