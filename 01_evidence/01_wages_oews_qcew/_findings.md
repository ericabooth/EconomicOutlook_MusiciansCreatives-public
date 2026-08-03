# Key findings: OEWS wages and QCEW industry data

Retrieved 2026-08-01. Every figure below traces to
`oews_musicians_creatives_2005_2025.csv` or `qcew_arts_industries_2001_2025.csv`
in this folder; see `_sources.md` for URLs, vintages, and caveats. All OEWS
employment figures cover wage-and-salary jobs only and exclude the
self-employed; all QCEW figures cover UI-covered payroll jobs only and
exclude the self-employed. Musicians work self-employed more often than
almost any other occupation in this set, so both datasets likely undercount
the true size of Austin's music workforce even where they show it growing.

- **National employment for Musicians and Singers (SOC 27-2042) fell 28% from
  2005 to 2025** (50,410 wage-and-salary jobs in May 2005 to 36,180 in May
  2025), the largest employment decline of the seven occupations in this
  comparison set. Over the same period the mean hourly wage for the
  occupation rose 140% ($25.16 to $60.46). (`oews_musicians_creatives_
  2005_2025.csv`, rows with `occ_code=27-2042`, `geo_level=National`.)

- **Texas statewide, Musicians and Singers employment roughly halved** from
  2,870 wage-and-salary jobs in May 2005 to 1,430 in May 2025, while the
  median hourly wage rose from $13.08 to $33.59 (+157%). The occupation's
  Texas employment count is noisy year to year (it ranged from 1,020 to
  2,870 across the 21 years), consistent with a small, survey-based estimate
  rather than a smooth trend. (Same file, `geo_level=State`.)

- **In the Austin-Round Rock-San Marcos MSA, the May 2025 median hourly wage
  for Musicians and Singers ($31.49) is higher than both the MSA's
  all-occupation median ($27.38) and the median for Graphic Designers
  ($31.28).** This is a small and volatile estimate: OEWS puts Austin-area
  wage-and-salary musician employment at only 120 jobs in 2025, versus 1,880
  for Graphic Designers in the same MSA, so a handful of higher-paid
  orchestra, church, or venue-staff positions can move the median
  substantially, and the figure says nothing about the far larger population
  of self-employed and gig musicians. (Same file, `geo_level=MSA`, year 2025.)

- **BLS publishes no annual-wage figure for Musicians and Singers or Actors
  anywhere in this file.** The `a_mean` and `a_median` columns are blank in
  **63 of 63** Musicians and Singers rows (SOC 27-2042) and **39 of 39**
  Actors rows (SOC 27-2011), across every geography (Austin MSA, Texas
  statewide, national) and every year 2005-2025, with no exceptions. This is
  a standing BLS convention for occupations with a high share of part-year or
  part-time work, not a gap in this extraction: BLS judges that annualizing
  an hourly wage would overstate earnings for workers who do not work
  full-year, full-time. Any comparison of full-year earnings across
  occupations in this dataset needs to account for this asymmetry, since
  Graphic Designers, Photographers, Writers and Authors, and Sound
  Engineering Technicians have annual figures in all 63 of their rows.
  (`oews_musicians_creatives_2005_2025.csv`; count null `a_mean` by
  `occ_code`.)

- **Austin MSA coverage has holes for two comparison occupations, so a
  2005-2025 window is not available for all of them.** OEWS publishes no
  Music Directors and Composers (SOC 27-2041) row for the Austin MSA in
  2005-2007 or in 2022-2025, leaving that MSA series covering 2008-2021
  only; the 2019 Austin row reports employment (60 jobs) with every wage
  column blank, so only 13 of those 14 years have a usable wage. Actors appear
  in the Austin MSA in just 4 of 21 years (2013, 2017, 2024, 2025) and in
  Texas statewide rows in 14 of 21. Musicians and Singers, by contrast,
  appear in all 21 years for all three geographies. Any Austin
  occupation-versus-occupation comparison should state the years actually
  available for each occupation rather than implying a common window.
  (Same file; cross-tabulate `year` by `geography` within `occ_code`.)

- **Nationally, Actors (SOC 27-2011) employment fell 7.7% from 2005 to 2025**
  (59,590 to 55,000 jobs) while the mean hourly wage rose 146% ($23.73 to
  $58.29). Musicians and Actors are the only two occupations in this
  comparison set that lost wage-and-salary jobs over the two decades; every
  other comparison creative occupation (Graphic Designers, Writers and
  Authors, Sound Engineering Technicians, Music Directors and Composers)
  gained jobs over the same period. (Same file, `geo_level=National`.)

- **In Travis County, establishments in NAICS 71113 (Musical Groups and
  Artists, private-sector) grew 44% from 2001 to 2025** (39 to 56
  establishments) while private-sector employment stayed close to flat (320
  jobs in 2001, 314 in 2025) and average annual pay per worker roughly
  doubled, from $27,142 to $56,461 (nominal dollars, not inflation-adjusted).
  More, and apparently smaller, formally-employing music businesses are
  paying their W-2 workers more per head, without net job growth in this
  narrow slice. (`qcew_arts_industries_2001_2025.csv`, `industry_code=71113`,
  `geography=Travis_County`, `own_code=5`.)

- **Austin MSA QCEW suppression varies widely by industry code, and the
  broader NAICS 71 aggregate is not exempt.** Counting private-sector
  (`own_code=5`) rows flagged `disclosure_code="N"` out of the 24 MSA years
  available (2001-2024): NAICS 71 is suppressed in **2** years (2012, 2013),
  7111 in **2** (2001, 2024), 71113 in **8** (2001-2004, 2010, 2012, 2013,
  2024), and 7115 in **10** (2001, 2002, 2006, 2009-2011, 2013, 2022-2024).
  Only 71113 loses about a third of its years (8 of 24, 33%); 7115 is worse
  at 42%, while 7111 loses just 8%. The broader NAICS 71 aggregate is not a
  safe fallback: in 2012 and 2013 BLS shows the establishment count (638 and
  687) and withholds employment and wages, so a NAICS 71 MSA series needs
  those two years dropped or interpolated rather than read as published.
  Travis County data for all four codes is unsuppressed in every year
  2001-2025 and is the more reliable sub-state series.
  (Same file; tabulate `disclosure_code` by `industry_code` for
  `geography=Austin_RoundRock_MSA`, `own_code=5`.)

- **Suppressed QCEW rows report zeros rather than blanks, so any average over
  these series has to filter on `disclosure_code` first.** All 140 suppressed
  rows in `qcew_arts_industries_2001_2025.csv` report
  `annual_avg_emplvl=0`, `total_annual_wages=0`, and `avg_annual_pay=0`.
  These are withheld values, not true zeros, and nothing in the numeric
  columns distinguishes them from a real zero. Averaging without excluding
  them pulls a series toward zero: mean `avg_annual_pay` for Austin MSA
  private 71113 is $27,408 across all 24 years but **$41,113** after dropping
  the 8 suppressed years, and mean employment is 175 against **262**. Both
  naive means understate the true one by exactly a third, which is the
  arithmetic you would expect: zeroing 8 of 24 years leaves two-thirds of the
  correct average. Establishment counts usually survive suppression but not
  always, so `annual_avg_estabs` is not a safe filter either: 6 of the 22
  suppressed Austin MSA private rows report `annual_avg_estabs=0` as well
  (71113 in 2001-2003, 7115 in 2001-2002, 7111 in 2001), which leaves those
  6 rows with no usable information at all. Filter on
  `disclosure_code != "N"` before computing any mean, trend, or growth rate
  from this file.

- **The 2025 QCEW release has no metropolitan-area rows at all for any of the
  four target industries**, evidently because BLS had not yet finalized
  metro-area rollups for that vintage as of this retrieval. County (Travis),
  state (Texas), and national rows are available for 2025, so the Austin MSA
  QCEW series in this folder currently runs 2001-2024, one year behind the
  OEWS series, which does have a full 2025 Austin MSA vintage. (Same file;
  absence confirmed by checking `agglvl_code` values in the underlying 2025
  BLS bulk file, which omits the MSA aggregation level entirely.)

- **NAICS 7115 (Independent Artists, Writers, and Performers) in Travis
  County shows the widest swings of any series pulled here**: private-sector
  establishments grew more than fivefold, from 44 in 2001 to 233 in 2025,
  while average annual pay per worker ranged from $31,083 (2003) to $238,889
  (2025) across the period, with no clear monotonic trend. This industry
  code covers independent contractors and loan-out corporations, so a
  handful of high-earning individuals (for example, well-known
  performers who incorporate) can swing the county-level average sharply;
  the average-pay figure for this code should be read as sensitive to a
  small number of outliers, not as a typical independent artist's income.
  (Same file, `industry_code=7115`, `geography=Travis_County`, `own_code=5`.)

- **Texas and national average annual pay for NAICS 71113 (Musical Groups and
  Artists, private) both declined from 2024 to 2025**: Texas fell from
  $100,467 to $71,744, and the U.S. fell from $96,027 to $81,260, even as
  establishment counts kept growing in both geographies. One year of data is
  not enough to call this a reversal of the two-decade upward trend in
  average pay; it may reflect the small sample size in this narrow industry
  code, ordinary year-to-year noise, or the transition to the new NAICS 2022
  six-digit code (711130) that BLS is publishing in parallel with the legacy
  five-digit code for 2025 (see `_sources.md`). Consider treating the 2025
  QCEW pay figures for this code as provisional until a second year of data
  is available to confirm the direction.

- **The Austin MSA's official name changes mid-series, from
  "Austin-Round Rock, TX" to "Austin-Round Rock-San Marcos, TX," starting
  with the 2023 vintage** in both the OEWS and QCEW files, following a 2023
  OMB update to the metropolitan-area delineation that added Hays County
  (San Marcos). The area code is stable across the change (OEWS area 12420,
  QCEW area C1242), so the time series in both files is continuous by code,
  but the underlying county composition shifted slightly, so figures from
  before and after 2023 are not perfectly like-for-like even under the same
  code.

- **QCEW's underlying data never publishes a combined "all ownership types"
  row for these four industry codes**; every area-year only has separate
  Federal/State/Local/Private rows. Private-sector employment (own_code 5)
  accounts for nearly all of the activity in NAICS 7111, 71113, and 7115 in
  every geography (government rows are consistently zero or suppressed for
  these codes), so the `own_code=5` rows are the recommended headline series
  for those three; for the broader NAICS 71 context comparison, Local
  Government employment is meaningful (parks, recreation, and museums) and
  worth including if that broader code is used in the report.
