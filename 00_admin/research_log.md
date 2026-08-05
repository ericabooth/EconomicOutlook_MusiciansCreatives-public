# Research Log

## 2026-08-01 — Kickoff
- Created project folder + 11 evidence workstreams under `01_evidence/`.
- Launched 11 parallel evidence-gathering agents (Sonnet for structured data
  downloads, Opus for judgment-heavy policy/news scraping). Fable used only
  for orchestration/planning per Eric's instruction.
- Each agent instructed to produce raw files + `_sources.md` (URL, retrieval
  date, vintage, caveats) + `_findings.md` (key facts with numbers) in its
  subfolder, with no fabrication and honest logging of blockers.

### Workstream assignments
| # | Workstream | Model | Core sources |
|---|-----------|-------|--------------|
| 01 | OEWS + QCEW wages/employment | sonnet | BLS OEWS 2005–May 2025 (Austin MSA/TX/US, music + comparison SOCs); QCEW NAICS 7111/71113/7115 |
| 02 | ACS PUMS + Nonemployer Statistics | sonnet | Census API PUMS 5-yr (musician OCCPs, TX), NES county series, Austin PUMA map |
| 03 | BEA ACPSA + NASAA | sonnet | State arts value-added/employment/compensation; state arts appropriations per capita |
| 04 | Austin city programs / Live Music Fund | opus | LMF cohorts + financials, CSAP, audits, division budget, artist-pay resolutions |
| 05 | Music censuses + pay surveys + news | opus | 2014 TXP census, 2022 Sound Music Cities census, HAAM/SIMS/Black Fret, 15–25 news items |
| 06 | State policy benchmark | opus | TMO + TX Music Incubator Rebate vs TN/GA/LA/NY programs, NCSL/NASAA |
| 07 | SVOG federal relief | sonnet | SBA SVOG awards (TX + Austin extracts), program fact sheets |
| 08 | Venues ecosystem | opus | Comptroller mixed-beverage receipts for ~30–50 venues, closure timeline CSV, TMO directory |
| 09 | Cost of living | sonnet | HUD FMR FY2010–26, Zillow ZORI/ZHVI, ACS rents, BEA RPP |
| 10 | Apprenticeship (sidebar) | sonnet | RAPIDS TX data, apprenticeable-occupation check, precedents |
| 11 | Streaming royalties (sidebar) | sonnet | MLC, SoundExchange, RIAA, Loud & Clear, per-stream sources |

### _datashare linkage (checked 2026-08-01, per Eric)
Existing panels at `Shared drives/Data and Research Team/_datashare` that this
project should LINK (by global, per datashare conventions) instead of re-cleaning:
- `BLS/02_cleaned/BLS_OEWS_TX.dta` — TX statewide OEWS 2005–2024, includes
  27-2042 Musicians/Singers + all comparison SOCs (occ_code, tot_emp, a_mean,
  a_median). **Gap:** no Austin MSA detail, no US baseline → workstream 01's
  Austin MSA/US pull still needed; TX rows double as a cross-check.
- `BLS/02_cleaned/BLS_QCEW_TX.dta` — TX county × industry 2000–2024, but only
  sector level (NAICS 71 max detail) → workstream 01's NAICS 7111/71113/7115
  pull still needed. Travis County NAICS 71 rows usable for context.
- `BLS/02_cleaned/BLS_CPI.dta`, `BLS_LAUS_TX.dta`, `BLS_TX_Annual_Summary.dta` —
  available for deflators/context.
- `DallasFed/02_cleaned/DallasFed_Wages.dta`, `DallasFed_Employment_Metro.dta` —
  Austin metro employment/wage context if needed.
- `Census/02_cleaned` is currently empty; PEP population (for per-capita math)
  lives in the Census PEP datashare — check `Census/` structure at plan stage.

### Next steps (pending agent returns)
1. Review all `_findings.md`/`_sources.md`; verify no fabricated numbers; log gaps.
2. Draft `02_plan/whitepaper_plan.md`: outline (≤15 pp LaTeX, tx2036/docmaker style),
   figure list, analysis plan, data inventory with vintages, open questions.
3. CHECK IN WITH ERIC before any analysis or writing.

## 2026-08-01 — Agent returns
- **[11 streaming]** DONE. 7 PDFs (MLC 2024/2025 ARs, RIAA 2025/2024/2015, SoundExchange 2024 audited, TMO/TXP 2024 impact study) + 6 notes files. Key: streaming 82-84% of US recorded revenue (2024-25) vs 34.3% (2015); RIAA retail→wholesale basis switch flagged; MLC black-box ~$400M, ~56-57% matched; SoundExchange $1.054B (2024). NO Texas-share figure exists anywhere — sidebar must be proxy-based (TMO ~2,509 Austin talent listings; AFM Local 433 ~350 members). Open: MLC black-box discrepancy ($561M vs $397-424M), SoundExchange 2015-2023 series incomplete.
- **[10 apprenticeship]** DONE. 11 files. Key: "Musician" IS on DOL's apprenticeable-occupations list (RAPIDS 2080CB, O*NET 27-2042.02, competency-based) but NO active registered program found anywhere (TX or national); 16/1,440 national titles are arts-adjacent (recording engineer, sound tech, stagehand). TX overall: 945 programs, 35,500+ active apprentices (TWC, Nov 2024). TX arts-occupation cross-tab UNOBTAINABLE publicly (Tableau-only dashboards; RAPIDS microdata non-public) — needs DOL data request (apprenticeship-public-data@dol.gov) if hard number required. UK apprentices production/tech roles only, not performers. Framing: model formally available, essentially unused — fits crews with employer-sponsors, not freelance performers (inference, flagged as such). NOTE: agent hit a web-search cap near end; a few confirmatory searches unrun.
- **[07 SVOG/relief]** DONE. SVOG national file (13,011 awards, vintage 2022-07-05, last SBA published; state-casing bug fixed) → TX extract (758 awards) + Austin-area (152 awards, $238.4M — exceeds Houston $215.0M and Nashville-city $159.9M, trails DFW $410.9M; city-name match, directional not official MSA). Top-10 Austin recipients = 39% of Austin $; five at the $10M cap; UT-Austin $10M as "live venue operator" (verify before citing); SXSW stacked SVOG $8.0M + PPP $5.0M. National sum $14.57B ($16.25B = appropriation, not disbursement). BONUS: PPP FOIA files filtered → TX music-venue NAICS subset (6,546 loans/$345.5M; Austin 816/$61.8M; 722410 bars = loose upper bound). Raw national files kept in scratchpad for re-cuts.
- **[03 BEA ACPSA/NASAA]** DONE. 16 tidy CSVs + raw workbooks (ACPSA 2001-2023 state series; NASAA FY2025/26 revenue tables incl. per-capita Table 6; TCA budgets cross-checked to within $1k; NEA TX fact sheet). Key: TX arts value-added $65.6B = 2.5% of GDP (2023), LOWEST of 8 benchmark states (WA 9.8, NY 7.6, CA 7.5, US 4.2, TN 4.0, GA 3.8, FL 3.2, LA 2.1), 36th/51 nationally. Within TX, independent artists ($1.64B) OVERTOOK performing-arts companies ($876M) — reversal from 2001 → structural gig shift. TX 39th/50 per-capita state arts funding FY2026 (up from 46th; approp +27.7% to $18.29M). National sound recording U-curve: $18.0B (2001) → $13.3B (2019) → $21.1B (2023). CRITICAL: BEA discontinued ACPSA Feb 2026 — 2023 data likely final vintage (paper should note series ends). Caveats: state series nominal-only; WA #1 rank driven by design-services mix; use 2.5% not "~3%".
- **[02 PUMS/NES]** DONE. TX creative-occ PUMS extract (5,694 unweighted recs, 2020-2024 5yr) + 555k baseline workers + 606k housing recs (SERIALNO join verified 100%) + 16-PUMA Austin MSA crosswalk + NES 2012-2023 panel (9 counties+TX). Key (eyeball, unweighted-ish, nominal): musicians 44.4% self-employed vs 9.8% all TX workers (~4.5x); median PINCP $22,800 (~half of $45,000 baseline; median earnings $12,800); Austin MSA has 17.3% of TX musicians vs 9.4% of workforce (~1.8x over-representation); NES 7115 nonemployers +61.6% Travis 2012-2023 vs +48.2% Harris. CODE CORRECTION: OCCP 2751 = Music Directors/Composers, 2752 = Musicians and Singers (brief had them reversed — verified vs dictionary). Caveats: primary-occupation only (undercounts side-gig musicians); no clean sound-engineer OCCP (2905 combined bucket); ADJINC/ADJHSG not yet applied. Blocker note: Census API now key-required; agent used bulk file server instead — get a free API key for refreshes.
- **[04 City programs/LMF]** DONE. 111MB: 21 primary PDFs (ordinance, resolutions, guidelines, all awardee lists, 2 audits), 13 CSVs, 4 .md pages, txt extracts. Key: LMF banked $5.13M unspent through end-FY2022 (expenditures $4,284 FY21 / $50k FY22) — first real disbursement FY2023; avg award swung $9,458 (FY23) → $32,096 (FY24) → $17,895 (FY26), success rate ~56% → ~13%, FY2025 cycle SKIPPED entirely; HOT split FY2025: Historic Pres $21.1M vs Cultural Arts $16.4M vs Live Music $4.8M (= 2.9% of $164.6M HOT), LMF nominally flat since FY24; NO audit of LMF exists (Oct-2024 auditor report explicitly excluded music); 60 recipients non-compliant mid-2025 freezing $550k; ~13% of spend = admin ($2.34M) + ads ($268k) vs $17.6M grants. DATA-QUALITY FLAGS: FY26 award list self-contradicts ($90k gap; 21 named vs 20 subtotaled — use stated headline 399/$7.14M + note); fund balance = cash-flow proxy, needs ACFR. GAPS: applicant demographics locked in Power BI (records request); M&E Division budget series needs printed budget volumes FY19-25 (+ 2025-02-24 EDD→ACME reorg breaks series); Agent of Change final status unconfirmed; Music Disaster Relief $1.5M approp but no disbursement figures. TECH NOTE for future pulls: data.austintexas.gov not on api.us.socrata.com — use domain catalog endpoint w/ search_context; Widen PDFs need window.viewerPdfUrl.
- **[08 Venues]** DONE. Core asset: mixed-beverage panel — 114 canonical venues / 145 permit entities, 16,346 venue-months 2007-01→2026-06 (name+address matching survives ownership changes; 13 unmatched targets documented). Plus 71-row closure timeline (2011-2026, 14 archived articles), 15 datahub.austintexas.gov datasets incl. Outdoor Music Venue permits. Key: real receipts of 114-venue panel -6.9% 2019→2025 (core 37 rooms -16.9%, 18.6% below 2019, worst since 2013; peak 2022 then 3 straight declines) WHILE citywide receipts +2.8% and permits +27.8% — decoupling, not coverage artifact (panel steady ~9% share); apparent recovery = post-2021 big ticketed rooms (Moody Center etc.); Sept-2015 rent evidence: Holy Mountain +45% ($5.5k→$8k) & Red 7 +56% ($9k→$14k) closed together inside RRCD; Iconic Venue Fund: 45 proposals/$300M+ asked, ONE award ($1.6M Hole in the Wall); outdoor venue permits -31.9% from 2014/17 peak (138→94). TRAPS NEUTRALIZED: C3 festival receipts through venue shells (Scoot Inn $12.5M month = 326x median; _ex_festival cols); BLS Oct-2025 CPI gap (shutdown) interpolated; cover_charge var unusable pre-2022; DO NOT cite "90% venues will close" or any TMO directory count (unverifiable). TMO directory Cloudflare-gated → manual export path documented. Caveat: receipts proxy venue activity NOT musician pay (door splits must come from census/survey beat).
- **[06 State policy]** DONE. 59 files, 47 sources, 27 findings, 30 computed figures arithmetic-checked. Key: (1) GA Music Investment Act = $15M/yr cap, $0 EVER paid (6 apps, all denied; DOAA/CBAER Dec-2023 eval) — statutory cap ≠ support; (2) TX film gets $300M/biennium (SB 22, 89R) vs TMIR $20.2M = 15x gap, same office, + $30M film-workforce pilot w/ no music counterpart; (3) TMIR enacted 2021 (SB 609, 87R — NOT HB 2806/2019 as briefed; that died in Senate) but unfunded until 2023, first window Sept-2023; (4) TMIR scales with alcohol tax remitted not artist pay (no compensation threshold; festival test = county <100k, excluding all big-metro festivals); (5) TMIR is the only operating-venue subsidy in the peer set — NY/IL/PA/etc credits fund touring/Broadway productions (head-to-head $ comparisons need this caveat). Per-capita (V2025 pop): TX TMIR $0.32 disbursed · GA $0.00 · LA $0.013-$0.46 · NY ~$4.40 · TN $1.46 (music not separable); NASAA baseline TX $0.58 (39th). CORRECTIONS: NY credit = Tax Law §24-c (not 24-a); TN incentive = film-scoring subsidy (2018), music videos ineligible. GAPS: no public TMIR recipient list (no LBB rider parallel to film; PIA request needed); round-1 TMIR internally inconsistent (156×$53k=$8.27M vs "~$10M" claim — unverified); WA empty; GA HB 353 low-reliability. CAUTION: TXP/TMO 195,979-jobs/$31.7B figure = self-listed directory + 2017 Econ Census anchor + tourism first added 2024 (jump partly definitional); TXP itself: direct music employment "has stagnated". Follow-up idea: Oxford Economics live-entertainment report for consistent cross-state benchmark.
- **[05 Census/surveys/news]** DONE. 106 files/467MB, 52 PDFs validated: 2015 Austin Music Census (235pp), 2022 Greater Austin Music Census + both appendices (image-only, read visually), TXP 2016 impact update, 42 articles 2015-2026 w/ per-number provenance tables, 13 other-city censuses, MIRA 2018, FMC, AEP6, Citigroup, HAAM ARs 2014-2025, SIMS, Black Fret/Sonic Guild, 4 IRS 990 extracts. Key: 68.4% of Austin musicians earned <$10k from music in 2013 (n=1,883); 2010-2014 music tourism +3,780 jobs (+37%) while music jobs -1,205 (inside same "$1.8B" headline); 2022: 89% plan to stay in music, only 64% in greater Austin; HAAM food insecurity 29% pre-COVID → 74% post; famous "$15,475 musician income" = ONE saxophonist's 1981 salary ($47,865 in 2022$). CORRECTIONS: 2014 census = Titan Music Group (not TXP; TXP did impact series; Nikki Rowling ran both censuses); "$150/gig since the 1980s" DOES NOT HOLD (merges $50-100/gig market rate w/ City booking rate $150/HOUR 2016, $200 2022 — units differ; defensible wording in _findings #17); HAAM publishes NO median income/poverty share (400% FPL = eligibility ceiling only). STRUCTURAL BLOCKER: no measurement of Austin musician earnings after 2013 — 2022 census dropped income questions; all circulating income figures trace to 2013 → PUMS/OEWS must be the quantitative spine; censuses qualitative. Charlotte 2019 median <$10k independently echoes Austin 2014. Gaps: 2 KVUE 403 stubs, AFTA COVID figures secondary-only, 6 relief items uncollected (search cap).
- **[01 OEWS/QCEW]** DONE. oews_musicians_creatives_2005_2025.csv (473 rows: May 2005–May 2025, 8 occs × Austin MSA/TX/US) + qcew_arts_industries_2001_2025.csv (733 rows: 4 NAICS × Travis/TX/US/Austin MSA). Key: national Musicians & Singers W-2 employment -28% 2005-2025 (50,410→36,180) while mean hourly wage +140% ($25.16→$60.46) — only occ besides Actors to shed jobs; Austin MSA musician median $31.49/hr (May 2025) ABOVE all-occ median $27.38 — but on 120 W-2 jobs (vs 1,880 graphic designers); Travis Co NAICS 71113: estabs +44% (39→56) w/ flat employment (320→314) and avg pay ~2x ($27,142→$56,461). Interpretation spine: OEWS/QCEW exclude self-employed → "fewer but better-paid formal jobs" = work shifting into invisible gig layer. Caveats: 2025 QCEW has no MSA rows yet (Austin MSA stops 2024); musician annual wages suppressed in most OEWS rows (hourly only); narrow-code QCEW suppressed ~1/3 of years sub-state (Travis Co = most reliable series); NAICS 71113→711130 transition documented. bls.gov Akamai-blocked → browser-driven download; QCEW pulled via HTTP range requests.
- **[05b National/benchmark surveys]** DONE (supplemental to workstream 05; `national_and_benchmark_surveys.md` + 64 verified PDFs). National musician income benchmarks (nominal): MIRA 2017 median $21,300 (n=1,227); FMC/DiCola 2011 median $18,000, mean $34,456; ACS 2012-16 $20-25k total income. Income mix: live 28-42%, teaching 12-22%, recordings 3.6-6%, streaming 1.5% (median $100/yr, MIRA); DiCola: only 12% of revenue directly copyright-related. Health insurance: 57% (2013) → 85-88% (2018) ≈ all-worker rate. 19 other-city censuses: SMC publishes MEANS never medians (per-gig medians $100-180 vs means $233-553 = 2-3x skew); Austin 64% 3-yr retention LOWEST among same-measure cities (DC 76, Sacramento 78, Nashville 80, Minneapolis 86, Greensboro 90) — Tulsa/Charlotte/NWA/Detroit use stricter non-comparable bar. CORRECTIONS: SMC founded by Don Pitts (not Rowling); no Seattle/Chicago/Denver/etc census exists (but AFM Seattle 2015 survey: median $15k); Sound Royalties/UMAW/MWA never fielded earnings surveys. WOULD-FAIL-REVIEW flags: Citi "12%" cited backwards (share ROSE from 7%; ex-advertising ~19%); "penny per stream" NOT in Living Wage for Musicians Act (50% surcharge + $4-10 floor/cap); ALL advocacy per-stream figures trace to one non-audited blog (Trichordist). Could not obtain: AFTA primaries (403; $22k figure unverified), Goldman Music in the Air (client-only), AFM Local 433 scale (unpublished — phone call closes it), Austin not in AEP6.

## 2026-08-01 (afternoon) — Build phase
Eric approved execution: LaTeX white paper, max 35pp incl. appendices+refs, 20-25pp narrative.
Audience Austin city / TX policymakers, general (not funder). Austin-centric + metro comparisons.
Honest not advocacy; explicitly NOT adjudicating the musician-pay-fairness debate. No PIRs
(one footnote mentions the need). Author: Eric A. Booth, eric.a.booth@gmail.com, no affiliation.

### Infrastructure built
- `03_analysis/src/common.py` — portable paths from __file__, CPI-U deflator (BASE_YEAR=2025,
  Oct-2025 gap interpolated + flagged), palette matching LaTeX, `finish()` figure helper
  (title+subtitle IN png, source notes NOT), parallel-safe `Registry` (one ledger CSV per module).
- `03_analysis/src/stats_utils.py` — numpy-only WLS with HC1 + cluster-robust SEs, two-way FE
  absorption via alternating projections, ACS successive-difference replicate-weight SEs.
  WHY: statsmodels is NOT installable (PEP 668 externally-managed system Python; did not override).
  Self-test recovers planted coef 2.000 as 1.998 w/ correct clustering.
- `03_analysis/src/build_numbers.py` — merges module ledgers into `05_report/canonical_numbers.tex`
  LaTeX macros, so no number is hand-typed into prose. Fails loudly on duplicate macro names.
- `03_analysis/run_all.py`, `requirements.txt`, `05_report/Makefile`.
- `05_report/style/austinmusic.sty` — self-contained (no T2036 branding/logo), 10pt, 0.85in
  margins, tight floats, tcolorbox banner/sidebar/keyfinding, P/B/C column types. Smoke test
  compiles clean, zero font warnings. Skeleton compiles.
- Datashare copies (NOT symlinks, per portability requirement) in `03_analysis/data/external/`:
  BLS_CPI.dta (deflator), BLS_OEWS_TX.dta + BLS_QCEW_TX.dta (cross-checks), BLS_LAUS_TX.dta.
- KEY DEFLATOR FACT: $1 (2013) = $1.383 (2025). So the 2013 census "$10,000" threshold is
  ~$13,830 in 2025 dollars — matters for every census comparison.

### Agent waves
First launch of 7 analysis agents ALL died on a session token limit (reset 3:40pm CT).
Relaunched: PUMS(opus), venues(opus), wages(sonnet), factcheck(opus), city(sonnet),
state(sonnet), references(sonnet). Cost-of-living module still to relaunch.
Intel salvaged from the dead run: PUMS curated extracts LACK replicate weights PWGTP1-80,
so the rerun downloads the raw Census 5-yr TX person file (timeboxed, with a documented
point-estimates-only fallback).

## 2026-08-02 — FACT-CHECK RESULTS (workstream 05 supplement)
Full write-up: `01_evidence/05_music_census_pay_surveys/FACTCHECK_income_measurement.md` (~13k words).

**C1 VERIFIED in the PRIMARY document** (2022 Greater Austin Music Census Summary Report,
printed p.2 / PDF p.3, "A Community Effort"; PDF has no text layer, rendered to read).
Verbatim: "removed questions from the 2014 survey that aimed to quantify the income of music
people in a way that turned off many respondents." TWO WORDING FIXES: sentence opens "With the
guidance of the community" (community-advised, NOT a unilateral analyst call), and what was
removed is income-QUANTIFICATION questions, not all income questions. Rival explanations
("pandemic", "too sensitive") do NOT survive checking.

**C2 NOT DEFENSIBLE AS WRITTEN — Eric was right.** Missed measurement attempts since 2014:
- **THE CITY OF AUSTIN PUBLISHED ITS OWN MUSICIAN WAGE**: median hourly earnings for musicians
  and singers $17.49 (2016) and $17.68 (2017), open data portal, bought from Creative Vitality
  Suite/EMSI — roughly HALF the OEWS figure for the same occupation-year, consistent with
  counting self-employed earnings. This is a major find and belongs in the report.
- UT Austin study (~60 interviews; $15k-$120k range, $30-35k most common)
- HAAM annual income statistics 2014-2025 (half of members under $24,000 in 2025; income-screened pop)
- HOME 2023 grantee data (half of grantees 55+ earn under $1,500/month)
- KUT 2022 canvass (~$100/gig)
FAIR LINE TO USE: "Austin's own music census has not asked a musician what they earn since 2013."

**C3 CONFIRMED w/ 3 CORRECTIONS**: OEWS publishes NO annual wage for musicians AT ALL (blank in
63 of 63 rows, every year/geography — not "sometimes suppressed"). BEA ACPSA does NOT reach
metro level. Nonemployer Statistics publishes no MSA table. ACS codes are 2751/2752 (confirmed).
CPS unusable for Austin (<1 Austin musician per monthly sample; labeled inference).

**C4 VERIFIED VERBATIM at live source**: KUT 90.5/KUTX, Elizabeth McQueen & Miles Bloxson,
2022-02-15. Marcia Ball: "And if you had worked for me for a full year as my sax player did, you
would have made $15,475." Entered circulation via KUT's own next sentence ("many Austin musicians
are still only making $15,475 a year"). Full string search: the figure appears in NO other source
document and is in NEITHER census.

**C5 TOO STRONG + MIS-DIAGNOSED.** Of 2 items dated 2026: ZERO cite a musician income figure.
Across 13 items 2023+: only 3 earnings figures, only ONE traces to 2013 (Austin Chronicle Feb 2023,
under the subhead "No Data on Dollars" — i.e. flagging its own staleness). THE REAL FINDING:
earnings figures were not replaced by newer earnings figures, they were replaced by PROGRAM
SPENDING figures (grant dollars 7 items, pay rates 5, housing 2). That is a better and more
defensible story than the original claim.

**BONUS FINDINGS**
- HAAM's "$2B / 18,148 jobs / $38M" block is MISATTRIBUTED BY HAAM ITSELF — labeled "Source: The
  Austin Music Census, 2015" but none of those numbers is in the 235-page census; they are TXP's
  **2010** estimates, republished as late as 2024 without TXP's own 2014 revision. "8,000+ working
  musicians" untraceable, silently raised to "9,000+" in 2024. DO NOT cite these uncritically.
- **The Live Music Fund already collects scored economic-status data from every applicant
  (1,000+ musicians/yr) and publishes none of it.** Best public-information-request target in the
  entire inventory — use in the PIR footnote.
- CORRECTIONS to earlier notes: Don Pitts founded Sound Music Cities (Rowling founded Titan Music
  Group) — census-to-census continuity is the commissioning official, not the analyst. Retention
  pair is 89%/64%, NOT the 84% KUT reported.
- **DATA ERROR CAUGHT**: the "$12,800 median musician earnings" figure came from UNMATCHED
  comparison bases; with matched bases it is ~$21,000. PUMS Stata module alerted to define one
  explicit population, apply it to both sides, and register N + denominator with every median.

## 2026-08-02 — References appendix
294 distinct sources compiled from all 11 workstreams + 8 companion citation docs
(resolved NY/TN statute URLs the top-level logs cited only by folder).
Breakdown: federal statistical 24 | State of Texas 26 | City of Austin 43 |
other states' programs+evaluations 31 | surveys/studies/industry 77 | news+trade 93.
Zero duplicate URLs. Machine-readable companion: `03_analysis/out/source_inventory.csv`.
10 entries flagged "URL not recorded" rather than guessed (incl. GA O.C.G.A. 48-7-40.33,
La. R.S. 47:6034 full text, Austin Ord. 20200423-067, Oxford Economics live-entertainment
report, Pittsburgh SMC study 404).
Excluded deliberately: "do-not-cite" items flagged by evidence teams (GA HB 353 aggregator,
403-blocked stubs with zero recovered content), NCSL negative finding, out-of-scope peer states.
Compiled clean at 14 pages -> SENT BACK for compression to 6-7pp (two-column + denser dataset
tables + retrieval-date folded into one blanket line), since total budget is 35pp with 20-25
for narrative. Full 294-item record stays in the CSV.

### Page budget (working)
title/scope 0.7 | exec summary 1 | S1 measurement 2 | S2 earnings 3.5 | S3 costs 1.5 |
S4 payroll->gig 2.5 | S5 venues 3.5 | S6 city money 3 | S7 state/national 3.5 |
S8 lessons 1 | S9 next steps 1  == ~23pp narrative
A1 technical appendix ~4 | A2 references ~7  == ~34pp total. Tight; trim if it runs over.

## 2026-08-02 — References compressed
Eric exempted the references appendix from the 35pp cap but asked for density.
Result: 14pp -> 9pp with ALL 294 entries intact (verified: 265 \item + 29 dataset table
rows = 294, matching source_inventory.csv). Techniques: two-column multicols at \scriptsize,
dataset tables cut 4 cols -> 2 (vintage folded into row, retrieval date stated once per
category), zero itemsep/parskip, baselinestretch 0.88 inside reference blocks only,
raggedright for URL wrapping. Nothing collapsed or deleted. Clean compile, 0 overfull boxes.

## 2026-08-02 — PUMS module complete (486 registered numbers, 0 errors)
Ran with svyset sdrweight(PWGTP1-PWGTP80) vce(sdr); every estimate carries a 90% MOE.
Matched base throughout: employed, 18-64, positive earnings, applied identically to
musicians and to the comparison baseline (this is the fix for the $12,800 artifact).

**Texas (2025 dollars):** Musicians/singers median earnings from work $25,100 vs all-worker
$50,000 (= 50.2%, hence the figure title). Median total personal income $28,000 vs $51,500.
Self-employed 51.5% (+/-4.9) vs all workers 9.8% (+/-0.1).

**Austin metro (n=77 unweighted, 2,126 weighted — thin, wide MOEs, no further breakdowns):**
- median earnings from work $28,700 (+/-9,400); median total personal income $36,900 (+/-10,600)
- Austin all workers: earnings $62,500 (+/-1,500); income $63,100 (+/-700)
  => Austin musicians earn ~46% of the Austin all-worker median from their work
- **THE INCOME-EARNINGS GAP IS THE FINDING**: musicians $36,900 income vs $28,700 earnings
  = +$8,200 (~29% of what work pays comes from elsewhere). All workers: $63,100 vs $62,500
  = +$600. The gap is ~14x larger for musicians. Non-work income is doing real work here.
- **self-employed 72.2% (+/-10.3)** vs 9.8% statewide baseline => ~7x, not the 4.5x first reported
- **median usual hours 40, median weeks 52** — SAME as all workers. The low earnings are NOT
  explained by part-time or seasonal work. This kills an obvious objection.
- earnings below thresholds: <$10k 23.3%, <$25k 43.6%, <$50k 68.5%
- 28.1% fall below the inflation-adjusted 2013 census $10,000 threshold ($13,830 in 2025$)
- health coverage 90.1% (+/-8.5); private 77.9%, public 26.4% — HIGHER than expected;
  counters a "musicians are uninsured" narrative and should be reported as such
- musician households pay MORE rent than worker households: $1,700/mo vs $1,500/mo median

**METRO COMPARISON (median earnings, music occupations):** Austin $31,400 < DFW $36,700 <
Houston $43,900. Austin musicians earn LESS than Houston or Dallas musicians. Austin-specific
and directly relevant to the "is Austin friendly to musicians" question.

**REGRESSION:** log(PERNP) on music-occupation indicator + age, age^2, sex, education, usual
hours, weeks worked, metro FE; employed TX 18-64 with positive earnings; SDR SEs.
coef = -0.290 (SE 0.054) => **-25.2% conditional gap, 95% CI [-32.7, -16.8]**.
So a quarter of the raw gap survives controls for hours, schooling, age and place.
Descriptive conditional gap, NOT causal — framed that way in the module and the caption.

fig02 rebuilt with a TRUE title (the earlier "least of any creative occupation" claim was
contradicted by its own chart; dancers and actors plot lower).

## 2026-08-02 — Census microdata module complete (139 numbers, 4 figures, 0 errors)
First analysis of the 2022 Greater Austin Music Census respondent file (2,227 rows x 107 vars),
which had sat unused in the evidence folder. SEVEN replication checks against the published
Data Appendix all pass (local-live any-income 92.4 vs pub 92.0; zero gigs 14.0 vs 14; >3 gigs
34.9 vs 35; guarantee 54.3 vs 54; local spend share 60.5 vs 60; distance mean 10.6 / median 8).

**RETENTION, verified on identical bases (n=1,900 of 2,227, so it is a within-person gap):**
88.8% expect to continue music work; 64.1% expect to still live in greater Austin; gap 24.7 pts.
The 36% is mostly uncertainty, not stated exit: unsure 25.6, maybe no 6.7, definitely no 3.6.

**WHO THE 36% ARE — the answer is HOUSING TENURE, and it was not on my list of breakouts:**
- owners 75.5% stay (n=758) vs **RENTERS 52.3%** (n=688), chi2(2)=84.2, p<0.001
- renting carries **OR 0.39** (p<0.001, n=1,607) net of sector, experience and insurance;
  OR 0.50 among creatives only with income concentration and work space added
- uninsured 53.1% vs insured 66.1% (chi2=15.7, p<0.001)
- experience 6-10 yrs lowest at 49.7% (but that effect vanishes in the creatives-only model)
- **primary sector (p=0.535) and work space status (p=0.181) do NOT discriminate** — two of the
  four breakouts I asked for are null, and that is worth reporting as such
This links the housing section to the retention section directly: it is renters, not any
particular kind of musician, who do not expect to still be here.

**COST-OF-WORKING CORRECTION:** the published "~$10,500 annual spending" is a SUM OF EIGHT
CATEGORY MEANS COMPUTED ON EIGHT DIFFERENT BASES (611-742 each), not a per-respondent total.
Among the 501 who answered every category (2025 dollars): mean $10,288, **median $5,394**,
p25 $1,816, p75 $11,834, p90 $22,016. Median is the figure to quote. Largest category is new
recordings (mean $3,917 / median $1,651); accounting and legal has a median of $0.
Registered as NON-differenceable against NES gross receipts (different populations/years/units).

**SOURCE CONFLICT RESOLVED (my call):** Data Appendix slide 41 transposes four income-source
labels. Slide 40 + the Socrata column dictionary both match the microdata exactly, so two
independent sources beat slide 41 alone. Corrected 2022 any-income shares: local live 92.4,
touring 75.3, recordings/royalties 70.7, studio 57.8, merch 56.1, songwriting 51.0, teaching 41.0.
`05_music_census_pay_surveys/_findings.md` item 14 followed slide 41 and has been CORRECTED in
place with the reasoning recorded. NO 2014->2022 delta may be reported for these items, because
the 2014 values exist only on the bad slide.

**MY BRIEF WAS WRONG about one variable:** `creatives_work_also_as_gig` is "work also as gig
PRESENTER" (47.2% of n=1,151 present or promote others' gigs), not "works outside music". The
outside-work statistic (38% non-creative industry, 24% other creative, 32% none, 22% call the
outside job primary) exists only in the Data Appendix, not the microdata; cite with the
appendix denominator or not at all. Registered as `census_no_outside_work_item`.

**VENUE PRESSURES (n=177, presenter-activity population, not a venue census — only 77 are
primary presenters):** property tax ranks top-three for 44.1% and first for 20.3%, ahead of
talent costs 38.4% and labor 35.6%; marketing last at 19.2%. Cross-validates the receipts panel,
where real-estate causes explain 13 of 36 dated closures, the same count as the pandemic.

Caveats registered: self-selected online convenience sample, NO weights, so point estimates
only and no standard errors; single 2022 snapshot; NOT comparable to ACS/PUMS; microdata
release is 2,227 rows against a headline of 2,260 (33-row difference undocumented);
operator-vs-promoter pressure split suppressed at n=42 (below the 50 floor); the ZIP file has
no respondent key so no respondent-level map is possible.

## 2026-08-02 — Cost-of-living module complete (109 numbers, 2 figures, 0 errors)
**CITY EMSI WAGE SERIES FOUND AND PLOTTED** at `04_city_programs_lmf/socrata/2qxc-8cme`.
SOC 27-2042, $17.49 (2016), $17.68 (2017). In 2017 it puts musician pay at **57% of the OEWS
figure** for the same occupation-year — confirming the hypothesis that a series including
self-employed earnings lands at roughly half the payroll-only wage. Plotted as fig19's third
line. This is the cleanest single illustration of the measurement problem in the whole report.

**BEA Regional Price Parity, verified from file (2024):** Austin all-items **98.1**, housing
**120.4**, gap **22.3 points** — widest of the five metros (Dallas 14.8, Nashville 8.3,
Houston 5.9, San Antonio -0.1). Austin housing RPP peaked 126.4 in 2023. So Austin is an
average-cost city with an above-average HOUSING cost, which is the precise framing to use.

**Rent levels (real 2025 dollars):**
- HUD 1BR FMR +31.8% (2010 -> latest); peak $1,679 FY2024; -9.2% from peak
- Zillow ZORI -3.3% since 2015; real peak Dec 2021 $2,108; **-23.5% from peak, steepest of 5**
- Zillow ZHVI +36.1% since 2010; peak $640,261 Jun 2022; **-34.9% from peak, steepest of 5**
- CPI Housing vs All Items (2005=100 -> 2025): 168.0 vs 155.7, 12.3-pt cumulative gap
- PUMS rent-share: FMR 1BR = **61.6%** of pooled musician earnings (63.8% vs FY2026 FMR).
  Two snapshots, NOT a trend (PUMS is one pooled 5-year cross-section) — registered as such.

**WRITING-CRITICAL RECONCILIATION (do not let these two look contradictory):**
fig19 shows hours-to-cover-rent ROSE 2023->2025 (40.8 -> 52.4) while fig20 shows real rent FELL
23.5% from peak. Both are correct and they measure different things:
 (a) fig19 uses NOMINAL HUD Fair Market Rent, an administrative benchmark that lagged the market
     and kept climbing through FY2025, divided by a volatile small-sample OEWS wage that fell
     from an unusually high 2022 reading;
 (b) fig20 uses REAL market rent (Zillow ZORI).
The report must state which measure it means each time, and should note that the administrative
benchmark lags the market. Registered as `col_anchor_reconciliation_note`.
SECOND RECONCILIATION: the REAL ZORI peak (Dec 2021) precedes the widely cited NOMINAL peak
(mid-2022 onward) by about a year — an artifact of annual CPI deflation during 2021-2023's sharp
inflation. Both readings are right; always say which. Registered as
`col_zori_real_vs_nominal_peak_note`.

fig19 title chosen programmatically AFTER checking endpoints (2025 = 52.4 hrs vs 2015 = 39.9):
"Covering Austin rent still takes more musician hours than in 2015". fig20 superlative verified
before use.

**Two more silent Stata bugs found and added to CONVENTIONS.md section 4b:**
- `reshape wide ..., j(var) string` fails on hyphenated values (SOC "27-2042")
- `local x : word N of "$GLOBAL"` with the global QUOTED silently returns garbage (first call
  returns the whole list, later calls blank). Drop the quotes.

Integration check run: **1,020 registered numbers across 7 modules, no macro-name collisions.**

## 2026-08-02 — City money module complete (66 numbers, 3 figures, 0 errors)
Re-derived the headline figures from source rather than trusting the evidence memo; the
258,876-row expense extract reproduces the memo's admin split to the dollar (grants 87.1%,
consultant/administrator 11.6%, advertising 1.3%).

**HOT allocation FY2025:** Live Music Fund $4.8M = **2.90%** of HOT revenue; Historic
Preservation **4.42x** the Live Music Fund. LMF revenue FY24->FY25: **-0.89% nominal but
-3.49% REAL** — this is the number that turns "flat since FY2024" into a measured real decline.

**THREE CORRECTIONS TO WHAT I HAD BEEN CARRYING:**
1. "Revenue outran spending through FY2022" is imprecise. FY2023 also shows revenue > expenditure,
   narrowly. The true crossover is **FY2023 -> FY2024**. Figure title corrected accordingly.
2. **The Iconic Venue Fund "45 proposals, $300M requested, ONE award" is a 2023 SNAPSHOT, not a
   current fact.** Cumulative Open Budget data show **$15.3M in grants paid FY2021-FY2026**, so
   more awards have been made since; no updated proposal/award list was found. I had been
   repeating "has made one award" as current. The report must date the claim to 2023 and note
   the cumulative payments, or drop the "one award" framing entirely.
3. A THIRD internal inconsistency in the FY2026 award list, beyond the two already known: the
   stated 399 total does not equal the sum of the document's own venue and musician/promoter
   subtotals (397). Registered as `city_lmf_fy26_subtotal_count_gap`.

**A visual trap caught before it shipped:** Stata's `connected` plot draws a continuous line
straight THROUGH a missing middle observation, which would have implied a smooth decline in
average award size across the skipped FY2025 cycle — exactly the false-trend reading the brief
forbade. Fixed with `cmissing(n)`; FY2025 now renders as a true zero bar labelled "0 (no cycle)".

**Agent self-caught a real error in its own output** before reporting: it had conflated a count
of pre-2000 fiscal years (18) with a count of pre-2000 awards (1,055), found it by cross-checking
registered numbers against its own diagnostic log line, and re-verified 5,421 + 1,055 = 6,476.

**Documented limitation:** the staged BLS_CPI.dta starts at calendar 2000, so Cultural Funding
Awards FY1982-1999 (1,055 awards, $19.2M) are reported NOMINAL ONLY; FY2000-2023 are real.
Acceptable, since that series is context rather than a core finding, but the report must label it.

Also unavailable: no FY2026 Live Music Fund applicant count (only the ACME-wide 1,606 across all
four programs); no applicant/request counts for CSAP FY19/FY23/FY26 (only the 2020 disaster round).

Two more Stata traps recorded: `reshape wide` needs an explicit `string` option for a
string-typed j-variable; `meanonly` does NOT populate r(max)/r(min).

## 2026-08-02 — State/national module complete (63 numbers, 5 figures, 0 errors)

**CORRECTION, and I had this wrong in every prior summary: TEXAS IS NOT THE LOWEST ARTS SHARE
OF STATE GDP.** Verified directly against `acpsa_state_totals_long_2001_2023.csv`:
**Louisiana 2.1% is lowest; Texas 2.5% is SECOND-lowest of the eight benchmark states** (US
average 4.2%). The evidence memo's headline sentence said "lowest" while its own supporting
numbers two lines later listed Louisiana below Texas. Registered as
`bea_gdp_share_correction_tx_not_lowest`; figure title fixed; the do-file emits a display-as-error
flagging the source memo. NEVER write "lowest of the eight." Texas's 36th-of-51 national rank is
cited from the memo, NOT independently re-derived (our BEA extract holds only 8 states + US).

**ACPSA DISCONTINUATION IS VERIFIED, so the report may state it.** Live fetch of bea.gov's
Arts and Culture page returned the exact sentence "BEA will no longer regularly produce these
statistics," dated February 2026. Follow-up: archive a copy to the evidence folder; only the
live fetch supports it right now.

**Per-capita, disbursed (2025 real $/capita)** — and this one cuts FOR Texas, so it gets equal
prominence: NY $4.52 >> TN $1.07 (film+TV+music-scoring, not music-only, upper bound) >
LA $0.48 > **TX $0.32** > GA $0.00. BUT **Texas is the only state in the set where authorized
equals disbursed** — the FY2026 rebate round drew down its full $10.1M dedication. Georgia's
$15M/yr cap paid $0 across its entire 2018-2022 life. So Texas spends little and spends all of
it; Georgia authorized a lot and spent none.
Caveats registered: NY "authorized" is our own proxy from the FY2027 budget's cap increase, not
a flat annual cap; TN has no music-only breakout; GA's cap deflated using 2022 as its nominal year.

**Film vs music: 14.9x** (not "15x"). $300.0M film (SB 22) vs $20.2M music (SB 609) for 2026-27,
same Governor's office. The $30M film-workforce line is a ONE-TIME FY2026 grant per Rider 45,
NOT an ongoing per-biennium dedication — do not present it as recurring.

**BEA crossover, corrected:** independent artists first edged ahead of performing-arts companies
in Texas in **2007**, reverted 2009-2010, then **overtook for good in 2011**. Not a clean
"reversal since 2001."

**SVOG:** Austin $238.4M / 152 awards (~20% of the $1.17B Texas total, 758 recipients);
DFW $415.0M; Houston $224.8M; Nashville $159.9M (city-only). Austin top-10 = 38.8% of Austin
dollars; 5 of 152 hit the $10M cap. All metro figures are hand-built city-name matches, not MSA
boundaries, and will differ from anyone else's list — registered as inherent to the method.

Three more silent Stata graph bugs (added to CONVENTIONS 4b):
- `over(strvar, sort(numvar) descending)` silently falls back to ALPHABETICAL order
- `graph hbar` with `asyvars` + a single variable + per-category `bar()` colors silently DROPS
  all axis category labels
- `graph combine ..., rows(1)` silently truncates a sub-panel title and clips mlabels

## 2026-08-02 — Venue difference-in-differences FIXED, and it changes the interpretation
The DiD had registered coef/se/p as exactly 0.000/0.000/missing. Cause: a full factorial
`i.post#i.corelm` under two-way fixed effects, where reghdfe dropped the 1#1 interaction as
collinear and the code extracted a structural zero. Rebuilt as an explicit product term.
The event study had the same class of bug: `ib2019.year#c.corelm` was not honored, reghdfe
dropped 2025 instead, so coefficients read against 2025 and the extraction grabbed the omitted
term. Rebuilt with hand-constructed year-by-core dummies omitting 2019.

**RESULT (now real):** DiD coefficient **0.003 (SE 0.077, p=0.97)** on log real monthly receipts,
171,724 unit-months. A precise null.
Event study against a 2019 base: 2013 -0.176, 2015 -0.086, 2017 -0.013, 2018 +0.011,
**2020 -0.541 (p<0.001)**, 2021 -0.195, 2022 +0.011, 2023 +0.073, 2024 +0.012, 2025 +0.095 (n.s.).

**THE INTERPRETATION THIS FORCES, and it is better than the naive reading:** among venues that
stayed open and kept trading, core live-music rooms did NOT diverge from the rest of the Austin
bar market after 2020. They took a far deeper COVID hit (-54 log points in 2020) and then
recovered to par. So the aggregate gap (core tier -18.6% against citywide +2.8%) is a
COMPOSITION AND ATTRITION story, not a story about surviving venues performing worse: core rooms
closed at higher rates (16 of 20 post-2020 exits were core) and were not replaced, while the
wider market added 30.5% more permit holders.
Policy implication differs accordingly: the binding problem is room survival and replacement,
not the operating margins of the rooms that remain.
HONESTY CAVEAT: pre-2019 coefficients trend upward (-0.176 in 2013 to +0.011 in 2018), so
parallel pre-trends do NOT hold cleanly. The design is descriptive, and the report must say so.

## 2026-08-02 — Quasi-experimental module complete (40 numbers, 3 figures, 0 errors)
All four designs survived; none dropped.
1. **SVOG staggered event study.** 29 of 152 Austin awards matched to panel venues (21 by
   address, 6 by taxpayer name, 1 DBA, 1 taxpayer-over-address); 3 dropped as uncertain with
   reasons (Paramount covers two permits; Long Center grantee != permit holder; The Parish
   address/legal-name conflict). 26 used vs 65 comparison. **Pre-trends parallel (F=0.26,
   p=0.905).** Trough -0.559 and -0.495 in the year before award (about 43% and 39% below
   comparison) then convergence: late-post gap -0.043 (SE 0.150, p=0.77). Awards all landed
   2021-06 to 2021-08, so this is effectively single-cohort, close to a relabelling of calendar
   time. NOT a program effect: eligibility required a documented revenue drop, so the pre-award
   trough IS the selection rule made visible. Report as descriptive.
2. **Red River 2017 pilot: a well-powered NULL.** RI p=0.668 (5,000 permutations). Design can
   rule out receipts effects larger than about +/-14%. Pre-trends fail as specified (p=0.0003)
   but the cause is DIFFERENTIAL SEASONALITY, not divergence: the reported window is
   six-sevenths second-half months. Adding venue x month-of-year FE clears the pre-trend
   (p=0.355) and the estimate becomes +0.006 (+0.6%), SE 0.098.
   TWO THINGS THE REPORT MUST CARRY: (a) the May-November window conflicts with the only primary
   document in hand (Ord. 20170126-019 created a six-month pilot; Ord. 20171019-007 extended it
   to 2018-04-30), so May-November may be the measurement window, not the legal one; both
   estimated. (b) **Mixed-beverage receipts CANNOT test the "+22% paid to local musicians"
   claim** — they measure alcohol sales, not the door split. A 22% rise in artist payments with
   no visible receipts change is arithmetically possible. State this plainly.
3. **LMF venue grants: NULL.** 17 FY2024 $60k awards, all matched; 15 used. Pooled 2024-25
   +9.2%, RI p=0.451. Pre-trends parallel (2018-2022 p=0.259). **FY2026 is not evaluable and
   that is itself the finding**: awards landed March 2026, the panel ends June 2026, and there is
   no 2026 deflator. Competitively scored, so conditional association only.
4. **Moody Center displacement: flat profile, no displacement.** Under 1 mile -0.295, 1-2 mi
   -0.385, 2-4 mi -0.288, reference >4 mi; joint equality p=0.911; none individually
   distinguishable. 53 venues in sample; the >4-mile reference is only 6 venues.
5. I-35 descriptive: The Lost Well -80.7% real receipts in the 14 months after closure, reopened
   at a new address 2025-10. Stars Cafe has ZERO rows in the mixed-beverage panel, so only one of
   the two closures is observable at all.

### Two cross-module inconsistencies raised by the agent, both now resolved
- **Dollar escaping.** quasi pre-escaped to `\textdollar{}`, venues wrote a bare `$`.
  `build_numbers.do` is now IDEMPOTENT: it normalises any pre-escaped form back to a bare dollar
  before escaping once. 1,175 macros, zero double-escapes, zero bare dollars outside comments.
- **Festival exclusion.** quasi drops 39 rows (`festival_spike_flag`), venues drops 10
  (`extreme_outlier_flag`). **Tested: it does not matter.** Only 2 and 7 of those rows fall in
  2019 or 2025, and none is in the core tier, so the core-tier headline is IDENTICAL under both
  rules: 2019 $52,779,703, 2025 $42,954,041, **-18.6% either way**. Documented rather than forced
  to match; the technical appendix will state both rules and this sensitivity check.

## 2026-08-02 — Figure QA + fix round
Independent visual QA over all 27 PNGs: 5 PASS, 8 MINOR, 14 FIX. Report at
`00_admin/figure_qa_20260802.md`. Fixes dispatched to four agents by module.

**Highest-risk defect, now fixed:** fig14's title claimed "fewer, larger awards each cycle"
while the plotted sequence was 369 -> 136 -> no cycle -> **399**. The last and tallest bar had
MORE awards than any other and a SMALLER average award, so both halves of the claim failed on
the final transition. New title is generated FROM the plotted values at run time and guarded by
three asserts encoding each claim, so it cannot silently drift again. Orphan FY2026 marker fixed
with a dashed bridge across the skipped year plus value labels on all three markers.

**Root cause found for a defect class, not just patched:** fig18's metro labels were misaligned
with their bars in both directions (a reader could read DFW's $415.0M against the wrong city).
Cause: `graph hbar var1-var4, over(g) asyvars` gives every group four bar slots, three empty, so
each metro's bar sat in a different slot within its group. Rebuilt as twoway horizontal bars at
explicit y positions. **The same bug was then found in fig17 panel A**, which the QA had not
flagged: every muted bar sat half a row above its label while the highlighted Texas bar sat
below its own, displacing Texas opposite to all others.

**An agent correctly refused the QA's recommended fix and verified why.** For fig16 the QA
proposed building the top panel at a taller ysize before `graph combine`. That cannot work:
`graph combine` gives every cell equal height and ignores a component's declared ysize, and
Stata sizes text against min(xsize,ysize), so enlarging the canvas scales labels by the same
factor. Rebuilt as twoway at explicit y positions instead; Texas now prints one label
("0.32 on both") and Georgia's 0.00 anchors to its own bar.

Other fixes: fig26's gap label was a genuine ROUNDING ARTIFACT (true gap 16.49 rounds to 16, but
endpoints round to 75 and 92 whose difference is 17) — now derived from the same rounded
endpoints, all four rows verified self-consistent. fig19 dropped the city EMSI series entirely
(2 of 21 years rendered as a stray stub); the finding moved to prose and caption, and the two
report passages referencing the plotted line were rewritten to cite the 57% figure directly.
fig10's point map replaced by a two-panel breakdown (venues with falling receipts by area +
ten largest declines by name) after three failed attempts at legibility; a council-district
choropleth requested separately so the report still carries a real map. fig17's y-axis
nominal/real contradiction resolved to nominal ON EVIDENCE (BEA publishes no state-level
chained-dollar ACPSA series). fig13 dual axis removed (all three series share units).
fig20 given line patterns for grayscale; fig07 given a distinct colour + patterns.

**Pre-existing warning flagged, does NOT reach the report:** `40_city_money.do` section 6 emits
"235 rows have a fiscal_year date not ending 09-30" for the Cultural Arts Fund 1982-FY2023
series. Verified that NO CityCfa macro is cited anywhere in the prose, so no published number
depends on it. Worth confirming the FY extraction before that series is used in future work.

Style sweep over all written sections: 3 hits, all fixed (two filler hedges, one banned
intensifier). Zero em-dashes. Report compiles at 34 pages, 0 overfull boxes, 0 undefined
macros or references.

## 2026-08-02 — Correction: Austin share of Texas musicians is 17.6%, not 17.3%
The 17.3% figure carried through every earlier summary came from the evidence-round eyeball on an
UNRESTRICTED base (the same unmatched-base problem that produced the $12,800 median artifact).
The final matched-base analysis gives **17.6%**: 2,126 of 12,047 weighted, employed 18-64 with
positive earnings, OCCP 2752, PWGTP-weighted (`pums_austin_share_of_tx_musicians` = 17.5979).
Against a 9.4% share of employed Texans, that is close to TWICE the workforce share, not the
"1.8 times" previously stated. No macro exists for the ratio itself, so the report states it in
words rather than typing an unregistered number.

ALSO: two different occupation groups appear in the new orientation table and are labelled apart,
which prevents an apples-to-oranges read:
 - `pums_austin_share_of_tx_musicians` = musicians and singers only (OCCP 2752), Austin weighted 2,126
 - `pums_metro_*_music_medpernp` = music occupations pooled (OCCP 2751 + 2752), Austin weighted 2,553

## 2026-08-05 — Full-paper editorial pass (clarity, de-caveat, partner care)
- Sentence-level clarity edit across 00_title and sections 01–10, A1, A2:
  fixed elliptical/truncated sentences (e.g. title abstract "The report reads
  mainly musicians" -> "is mainly about musicians"; summary "the author makes
  no claim beyond that..." rewritten), split three overlong summary
  paragraphs, removed metaphorical-location verbs (sit/carry/live) per
  clearwriter, glossed the event-study log-point figure (-54 log points ≈
  -42%).
- Corrections found during the pass: 065_census spending footnote listed
  "travel" as an instrument category; the computed ledger and fig27 use "web
  and social media" — fixed. 03_earnings said "2013 Austin Music Census" for
  the 2014 fielding's $10,000 line — fixed. 08_state "5 of 152 recipients
  recipients" macro duplication — fixed. UT Support Austin Musicians
  attribution: dropped "Prof. Eric Drott et al." (project's own team page
  names no lead; body + A2 now cite institutionally).
- A2 references de-caveated: removed access/verification parentheticals
  (paywalled, image-only, "URL not recorded", Cloudflare/403, search-summary,
  "verify before use"); kept substantive scope notes (excludes self-employed,
  participation gaps, basis changes). Filled congress.gov URLs for H.R.
  7763/5664. Full provenance detail remains in
  03_analysis/out/source_inventory.csv.
- Partner-care additions (SMC + UT): new cohort paragraph in 02_measurement
  printing the 15 registered NCitycensusIncome* macros (first use) with a
  comparability footnote; cohort framing sentence in 065 intro; open-microdata
  credit line after the spending rebuild; complement-not-replace passage after
  the three-source paragraph in 02; "adoption not design" line in
  10_next_steps; 09_lessons now cross-references the fifteen-city list.
- Rebuilt: 59 pp (was 60), zero LaTeX errors, zero overfull boxes; visual QA
  on pp. 1–8, 27–34, 40–44, 52–59.
