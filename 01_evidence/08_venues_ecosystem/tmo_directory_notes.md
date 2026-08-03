# Texas Music Office (TMO) Industry Directory — access notes

Retrieval date: 2026-08-01. All statements below are labeled **VERIFIED** (observed directly in an HTTP response this session) or **INFERRED / UNVERIFIED** (reasoned or third-party).

---

## 1. Bottom line

The live TMO directory could not be read programmatically. The current directory host
(`texasmusic.reel-scout.com`) sits behind a Cloudflare managed bot challenge and returns
HTTP 403 to every automated request. The previous directory application
(`gov.texas.gov/Apps/Music/Directory/`) is retired and returns HTTP 500 on every path tested.

What was recovered instead: the complete directory **taxonomy** (categories, genres, regions,
cities) and a 150-row listing sample, both parsed out of Internet Archive snapshots of the
live site taken in April 2025. No live listing counts were obtainable.

---

## 2. URLs attempted and HTTP results (VERIFIED)

| URL | Result | Notes |
|---|---|---|
| `https://texasmusic.reel-scout.com/crew_directorylist.aspx?type=S` | **403** | `cf-mitigated: challenge`, `server: cloudflare`, body titled "Just a moment..." |
| `https://texasmusic.reel-scout.com/` | **403** | Same Cloudflare challenge |
| `https://gov.texas.gov/music` | **200** | TMO landing page; served the directory links below |
| `https://gov.texas.gov/music/directory` | **404** | Not a valid path |
| `https://music.texas.gov` | **connection failed** | TLS certificate could not be verified; no usable response |
| `https://gov.texas.gov/apps/music/directory/Default.aspx` | **500** | "500 - Internal server error." |
| `https://gov.texas.gov/Apps/Music/Directory/results/All/region/austin/p1` | **500** | Same |
| `https://gov.texas.gov/Apps/Music/Directory/results/All/region/dfw/p76` | **500** | Same (URL taken from a live search index, so the index is stale) |
| `https://gov.texas.gov/Apps/Music/Directory/talent/all/genre/all/p334` | **500** | Same |
| `https://gov.texas.gov/Apps/Music/Directory/results/txorganizations/p1` | **500** | Same |
| `https://gov.texas.gov/music/page/economic-impact-study` | **200** | Economic impact reports index |
| `https://gov.texas.gov/uploads/files/music/TXP_TX_Music_Impact_Winter_2025.pdf` | **200** | 356 KB, 5 pages; saved locally |

Requests used a standard desktop Chrome User-Agent via `curl -sL -A ...`, and were also retried
through a separate fetching service. Both paths returned the same 403.

### Why the 403 was not worked around
The response carries `cf-mitigated: challenge` and loads `challenges.cloudflare.com`. This is
bot detection. Solving or evading it is out of scope, so the live directory is treated as gated.

---

## 3. Is the directory server-rendered or postback-gated? (VERIFIED)

Both. The archived page source shows a classic ASP.NET WebForms page:

- A single `<form name="form1" method="post" action="./crew_directorylist_content.aspx?type=S">`.
- `__doPostBack(eventTarget, eventArgument)` present, with `__VIEWSTATE` / `__EVENTTARGET` fields.
- Results render **server-side into the initial HTML** inside `<table id="example">`. The first
  page of results is present in the markup on load, so no separate AJAX/JSON call is needed.
- No `.ashx`, `.asmx`, or JSON endpoint appears anywhere in the page. The only form action is the
  page posting back to itself. **There is no hidden API to call.**

Practical consequence: the data is not JavaScript-gated, it is *Cloudflare*-gated. A human with a
browser sees fully rendered HTML tables. Filtering and paging past page 1 require form posts that
carry a valid `__VIEWSTATE` plus a Cloudflare clearance cookie.

The results table has these columns (VERIFIED from archived markup):

`Name` | (unlabeled: website link) | (unlabeled: city) | `MSA Region` | `Actions`

Rows are grouped under bold category headers, and each name links to
`crew_print.aspx?id=<id>&cid=<id>&type=<S|B|M>`, which is the per-listing detail/print view.

---

## 4. Directory structure: the three entry points (VERIFIED)

Confirmed from `https://gov.texas.gov/music` (HTTP 200), the directory has exactly three search
types, not the wider set of `type=` values that were guessed:

| Parameter | What it searches | Link on gov.texas.gov |
|---|---|---|
| `type=S` | **Music Business** | `crew_directorylist.aspx?type=S` |
| `type=B` | **Radio Stations** | `crew_directorylist.aspx?type=B` |
| `type=M` | **Musicians** | `crew_directorylist.aspx?type=M` |

Listing registration/login is `crew_login.aspx?cl=M`. Values `type=V` and `type=A` were guesses
and are **not** referenced anywhere on the TMO site.

---

## 5. Full directory categories (VERIFIED)

Parsed from the `search$lstCategories` dropdown in the archived April 2025 snapshots. A `*` entry
is the "all subcategories" roll-up for its parent group. Machine-readable copy of every dropdown
is in the scratch file `tmo_taxonomy.json`.

### 5a. Music Business (`type=S`) — 106 options across 11 top-level groups

**COMMERCIAL MUSIC** — Advertising agencies; Arrangers/Composers; Environmental/Business music;
Film/Industrial scoring; Jingles and advertising soundtracks; Sound effects libraries

**EDUCATION** — Community and technical college music programs; Music archives; Music camps;
Music instruction materials; Performing arts elementary/secondary schools; Private music schools
or instruction; University and college music programs

**INDUSTRY SERVICES** — Accountants; App developers/Mobile apps/Software; Artist management;
Attorneys; Financial Institutions/Banks; Graphic design/Artist/Creative studios; Insurance;
Merchandisers; Mobile disc jockeys/Karaoke; Music administration/Clearance; Music business
consultants; Music Engraving; Music publishers; Music therapy; Organizations/Associations;
Photographers; Physicians/Music medicine; Publicists; Unions

**MEDIA** — College newspapers; Daily Newspapers; Freelance journalists; Monthly publications;
Music blogs/Publications online only; Publications/Journals; Radio promotion/consultants; Radio
stations online only; Television programming; Weekly publications

**MUSIC VIDEO** — Soundstages; Video Distribution; Video post-production and duplication;
Video production

**MUSICAL INSTRUMENTS & EQUIPMENT** — Electrical equipment-Manufacturers; Instrument and touring
cases; Musical instruments-Manufacturers; -Rental; -Repair; -Retail; -Used;
-Wholesale/Distribution; Sheet music suppliers-Retail/Wholesale

**RECORD PRODUCTION & DISTRIBUTION** — CD/DVD duplicators and manufacturers; Jukeboxes; Record
distributors; Record jacket, CD booklet; Record labels; Record labels/Publishers–Private; Record
pressing plants; Record producers; Record promotion and record pools; Record stores; Record
stores online only/Digital music distributors; Retail marketing

**RECORDING SERVICES** — Audio engineers; Audiotape-Manufacturers/Retail; Mastering; Mobile
recording studios; Recording producers; Recording studios; Rehearsal studios; Studio and audio
design/construction/consultation; Studio equipment manufacturers/sales/rental

**TOUR SERVICES** — Annual events; Booking agents; Concert and event production; Concert
Promoters; Lighting-Manufacturers; Lighting-Services; PA systems/Sound reinforcement; PA/Staging
equipment-Sales/Rental; Security; Staging/Stage construction/Stage labor; Ticket printing; Ticket
sales outlets; Tour buses/Transportation; Tour management and personnel

**UNASSIGNED** — TBD

**VENUES** — the four subcategories that matter most for this white paper:
- `S823887` Auditoriums/Arenas
- `S823888` Clubs/Dancehalls/Small Venues
- `S823889` Concert halls/Performing arts centers
- `S823890` Stadiums/Amphitheaters/Fairgrounds

Note the taxonomy consequence: TMO classifies venues by **seating/format**, not by whether a room
books live original music. "Clubs/Dancehalls/Small Venues" is the closest available proxy for the
grassroots venue tier, and it will also sweep in dancehalls and bars that are not live-music rooms.

### 5b. Musicians (`type=M`) — 73 options
Genre-organized, not occupation-organized: BLUEGRASS, BLUES, CHRISTIAN, CLASSICAL, COUNTRY,
DANCE, ELECTRONIC, FOLK, FUNK, GOSPEL, HIP-HOP, JAZZ, LATIN, PERFORMANCE, POPULAR, RAP, REGGAE,
REGISTERED SESSION PROFESSIONAL, RHYTHM & BLUES - R&B, ROCK (each with subgenres).
"REGISTERED SESSION PROFESSIONAL" is the only category that identifies working session players
rather than a genre.

### 5c. Radio Stations (`type=B`) — 54 options
Format/genre roll-ups only: ALTERNATIVE, AMERICANA, BIG BAND, BLUEGRASS, BLUES, CHILDRENS,
CHRISTIAN, CLASSICAL, COLLEGE/COMMUNITY, CONJUNTO, COUNTRY, DANCE/ELECTRONIC, FOLK/ACOUSTIC,
GOSPEL, JAZZ, LATIN/SPANISH, NEW AGE, OTHER, POLKA, POP, RAP/HIP HOP, REGIONAL MEXICAN, ROCK,
ROCKABILLY, SOUL/R&B, TEJANO, WESTERN SWING.

### 5d. Geography filters (VERIFIED)
- `search$selMajorMarket` on `type=S` and `type=M`: 35 options. Austin appears **twice**, as
  `Austin` (id 41 on S, 42 on M) and as `Austin Area` (id 13 on S, 1 on M). Anyone filtering to
  Austin has to select both or they will undercount.
- `type=B` uses a shorter 13-option market list where only `Austin Area` exists.
- `search$selArtistCity`: 488 city options on `type=M`, 249 on `type=B`.
- `search$lstGenre` on `type=S`: 32 genres.

---

## 6. Result counts read off the page

**None were obtainable.** The archived pages contain no total-results or "showing X of Y" text
(searched for records/results/listings/found/total adjacent to digits: zero matches). Each
archived snapshot shows only the first page, capped at 50 rows, so no category total can be
derived from what was retrieved.

For this reason **`tmo_counts.csv` was deliberately not created.** Any per-category or per-region
count would have been invented.

### Third-party count claims (UNVERIFIED)
- "15,000+ listings" across artists, venues, studios, publishers, legal and tour services, and
  radio stations. Source: Austin Texas Musicians (an advocacy nonprofit, not TMO),
  https://www.austintexasmusicians.org/blog/texas-music-office-launches-the-new-texas-music-industry-database
  (article dated December 10, year not stated on the page). This is a secondary claim and could
  not be checked against the live directory.
- A web search summary surfaced figures such as 6,955 musician listings, 1,900 DFW businesses,
  1,158 Houston/Galveston businesses, 1,387 Country-genre listings, 522 Media businesses, and 446
  music organizations. These came from a search engine's rendering of
  `gov.texas.gov/Apps/Music/Directory/...` pages that **now return HTTP 500**. They are stale
  index artifacts from the retired application. **Do not cite them.** They are recorded here only
  so a later reader knows they were seen and rejected.

---

## 7. TMO's own published statistics (VERIFIED from the primary PDF)

Source: *The 2024 Economic Impact of Music in Texas*, TXP, Inc., January 2025. PDF saved as
`TXP_TX_Music_Impact_Winter_2025.pdf`.
URL: https://gov.texas.gov/uploads/files/music/TXP_TX_Music_Impact_Winter_2025.pdf
Index page: https://gov.texas.gov/music/page/economic-impact-study (prior editions: 2023, 2021,
2019, 2017, 2015).

**Table 1 — 2024 direct footprint**

| Segment | Jobs | Earnings | Revenue/Sales |
|---|---|---|---|
| Music-Related Business | 71,385 | $4.039B | $11.327B |
| Music-Related Education | 15,447 | $0.842B | N.A. |
| Music-Related Tourism | N.A. | N.A. | $1.206B |

**Table 2 — 2024 total impact (direct + indirect + induced)**

| Segment | Jobs | Earnings | Revenue/Sales | TX Tax Rev. |
|---|---|---|---|---|
| Music-Related Business | 145,855 | $8.121B | $24.706B | $0.407B |
| Music-Related Education | 24,476 | $1.510B | $4.132B | $0.076B |
| Music-Related Tourism | 25,648 | $0.853B | $2.827B | $0.081B |
| **Total Annual** | **195,979** | **$10.484B** | **$31.655B** | **$0.564B** |

**Methodology points worth flagging for the white paper (quoted/paraphrased from pp. 1–2):**
- The study **uses the TMO Texas Music Directory itself as the data source for job estimates** on
  the music-business side. Directory coverage therefore drives the headline jobs number, and the
  directory is self-registered. Consider treating 71,385 direct business jobs as a
  registration-dependent estimate rather than a census.
- Directory jobs are combined with Texas Workforce Commission QCEW wage data to estimate annual
  wages, then crossed against the **2017 Economic Census** to derive revenue. The revenue figures
  rest on a 2017 revenue-per-worker structure.
- 2024 is the first edition to include music-related tourism, so tourism figures are not
  comparable to earlier editions.
- The report's own framing: the number of direct music jobs "has stagnated, albeit with the jobs
  that remain paying higher wages." That is a useful, sourced counterweight to the growth headline.
- No count of directory listings or registered businesses appears anywhere in the report.

---

## 8. How a human would manually export Austin venue and musician listings

Steps 1–6 are **VERIFIED** against archived page structure and the live gov.texas.gov links.
Step 7 onward is **INFERRED**, because the results grid past page 1 could not be exercised.

**For venues:**
1. Open `https://texasmusic.reel-scout.com/crew_directorylist.aspx?type=S` in a normal desktop
   browser and let the Cloudflare interstitial clear on its own (a few seconds).
2. The page renders a search panel with three dropdowns and a keyword box: **Categories**
   (`search$lstCategories`), **Genre** (`search$lstGenre`), **Major Market**
   (`search$selMajorMarket`), and **Keyword** (`search$txtKeyword`).
3. In Categories, select `VENUES - *` for all venues, or one of the four venue subcategories
   listed in §5a to narrow to, for example, `VENUES - Clubs/Dancehalls/Small Venues`.
4. In Major Market, select `Austin`. **Then repeat the whole search with `Austin Area` selected.**
   These are two separate options and a single pass misses part of the metro.
5. Leave Genre unset so no venue is dropped for missing a genre tag.
6. Click the green **Search** button (`search$btnSearch`).
7. Results come back in a table grouped by category with columns Name, website link, city, MSA
   Region, and an Actions column. There is no visible export or CSV button in the archived markup,
   so collection is manual: copy the rendered table into a spreadsheet, or use the browser's
   save-as-HTML and parse it offline.
8. Page through the result set. The grid is a DataTables-style widget (`reelscout-table.js`,
   `id="example"`), so a page-length selector may allow raising rows per page, which would cut the
   number of copy passes.
9. For address and phone, open each listing's `crew_print.aspx?id=...&cid=...&type=S` detail view.
   The results grid itself does **not** carry street address, phone, or county. A full
   name/category/city/address/phone export requires one detail-page visit per listing.

**For musicians:** identical flow at `crew_directorylist.aspx?type=M`, except Categories is a
genre tree (§5b) rather than a business taxonomy, and there is an additional **City** dropdown
(`search$selArtistCity`, 488 options) that can be set to `Austin` directly. To capture all Austin
musicians regardless of genre you would iterate over every top-level genre `*` roll-up, or set
Major Market to `Austin` and `Austin Area` and leave Categories unset.

**Effort estimate (INFERRED):** at 50 rows per page and 4 venue subcategories x 2 Austin market
values, venue collection is a small number of passes and is realistic to do by hand in under an
hour. Musician collection across 20 genre groups x 2 market values is substantially larger, and
address/phone enrichment at one page-load per listing is the binding constraint.

**Lower-friction alternative (recommended):** the TMO publishes a staff contact point at
`https://gov.texas.gov/music`. Requesting a directory extract directly from the Texas Music Office,
or asking the Texas State Library's Texas Digital Archive (which holds an archived TMID collection
at `https://tsl.access.preservica.com/uncategorized/SO_90d3f803-e848-4ed9-8f14-599c045fdc10/`),
will likely be faster and more complete than screen-scraping, and avoids the Cloudflare gate
entirely.

---

## 9. What was actually retrieved: `tmo_listings_austin.csv`

Because the live site is gated, the only listings obtained came from Internet Archive snapshots.
**Read the scope limits before using this file.**

- Source snapshots: `crew_directorylist_content.aspx?type=S` (captured 2025-04-13),
  `?type=B` and `?type=M` (captured 2025-04-17). These are the **only** archived captures of these
  pages; the CDX index holds no other snapshot and no `crew_print.aspx` detail pages at all.
- Each snapshot is the **unfiltered default view, first page only, 50 rows**. Rows are ordered by
  category, so the sample is whatever falls alphabetically first, not a random or Austin-targeted
  draw.
- 150 rows retrieved in total. `tmo_listings_archived_sample_all.csv` holds all 150;
  `tmo_listings_austin.csv` holds the **40** rows whose city or MSA region contains "Austin".
- Those 40 Austin rows break down as: 17 Music Business under `COMMERCIAL MUSIC - Advertising
  agencies`, 17 Musicians under `BLUEGRASS - Traditional Bluegrass`, 3 Radio under `ALTERNATIVE`,
  3 Radio under `AMERICANA`.
- **There are zero venue listings in the sample**, because the VENUES group sorts after
  COMMERCIAL MUSIC and never appeared on page 1.
- `county`, `address`, and `phone` are empty in every row. Those fields do not exist in the
  results grid (see §3) and the detail pages were never archived.

This file is evidence that the directory exists and demonstrates its record shape. It is **not**
an Austin venue or musician census and must not be counted or aggregated.
