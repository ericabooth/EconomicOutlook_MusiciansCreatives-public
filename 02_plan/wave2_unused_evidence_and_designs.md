# Wave 2: unused evidence and quasi-experimental designs

Written 2026-08-02, after Eric asked two things: exempt the references appendix
from the page cap but keep it typographically dense, and revisit the material
gathered but not yet used, with attention to designs that isolate patterns
around known shocks.

Framing constraint Eric set: these designs do not need to establish causal
mechanisms, and should not pretend to. The data are too noisy for that. What
they can do is isolate patterns in a regression or difference-in-differences
setting as triangulated evidence, with selection into treatment stated plainly.

## A. Shocks with usable timing and usable treatment groups

| # | Shock | Date | Treated units | Data on hand | Design | Status |
|---|-------|------|---------------|--------------|--------|--------|
| 1 | Federal shuttered-venue relief (SVOG) | awards staggered, mostly mid-2021 | 152 Austin-area recipients, matchable to the venue panel by address and ZIP | award amounts + `awarded_date` per recipient; monthly receipts 2007-2026 | staggered event study, plus a treatment-intensity version scaled by 2019 revenue | **launched** |
| 2 | Red River extended-hours pilot | May to Nov 2017 | 5 named venues (Stubb's, Mohawk, Empire, Beerland, Cheer Up Charlies) | monthly receipts | difference-in-differences with randomization inference, since 5 treated clusters break cluster-robust standard errors | **launched** |
| 3 | Live Music Fund venue grants | FY2024 (~17 venues), FY2026 (~20 venues) | named recipients in the award lists | award lists + monthly receipts | event study around award year, descriptive only (competitive selection) | **launched** |
| 4 | Moody Center opening | April 2022 | venues near downtown | venue coordinates, sound-ordinance geocoded permits | distance-band interaction with post-period, displacement test | **launched** |
| 5 | I-35 expansion venue removals | Oct and Nov 2024 | 2 venues | closure timeline + receipts | descriptive only, too few to estimate; useful as a documented non-market exit | **launched (descriptive)** |
| 6 | COVID closure and reopening | Mar 2020 onward | all venues | monthly receipts + citywide permittees | interrupted series with the citywide bar market as comparison | in module 30 |

Rejected for lack of data: the Texas Music Incubator Rebate (first window Sept
2023) has no public recipient list, so there is no treatment group to build.
The city's musician pay floor (Resolution 20230720-123) binds only
city-commissioned performances, and no venue-level data records those.

## B. Evidence gathered but not yet used

Ranked by what it would add.

1. **2022 Austin Music Census microdata**, 2,227 respondents across 107
   variables, already downloaded to `01_evidence/08_venues_ecosystem/`. The
   single largest unused asset. The census removed income-quantification
   questions, but it retained questions on financial precarity, housing
   stress, intent to remain in Austin, and career stage. Analysing the
   microdata directly would let the report say something current about
   musicians' economic position that no federal series captures, and would
   let the 89% stay-in-music against 64% stay-in-Austin split be broken out by
   subgroup rather than quoted as a headline. **Next to launch.**
2. **Other-city music census incomes**, at least 18 cities on one common
   instrument, ranging from Nashville at $52,000 down to Anchorage at $15,000,
   with Austin absent because it stopped asking. Routed to the state module as
   a possible figure.
3. **PPP loan subsets** for Texas and Austin music venues (6,546 Texas loans
   worth $345.5M; 816 Austin loans worth $61.8M), already filtered from the
   full federal files. Adds a second relief channel alongside SVOG and allows a
   stacked-relief total per venue. NAICS 722410 is a broad drinking-places
   code, so treat it as an upper bound.
4. **HAAM annual reports 2014-2025** and Black Fret grant totals. A continuous
   nonprofit-sector series covering years the city surveys do not, useful as
   an independent read on need. HAAM's own economic-impact block is
   misattributed and must not be cited (see the fact-check).
5. **Cultural Funding Awards, 1982 to FY2023**, 6,476 awards. A long series
   suitable for an interrupted view around the pandemic, though it covers the
   Cultural Arts Fund rather than the Live Music Fund.
6. **Outdoor music venue permits by council district**, 1,751 permits and 595
   venue names, 2009-2026. Already feeding the supply figure; the district
   breakdown (77% in District 9) also supports the displacement work.
7. **Apprenticeship and streaming material**, held for the two boxed sidebars.

## C. Inference cautions carried into every design

- Selection into treatment is real in every case. SVOG required a documented
  revenue loss, so recipients were the hardest hit by construction. Live Music
  Fund grants are competitively awarded. Neither supports a causal reading.
- Treated counts are small (5 venues in 2017, roughly 17 to 21 for the fund
  grants). Cluster-robust standard errors are unreliable with few treated
  clusters, so randomization inference is the primary inference for those
  designs and conventional errors are reported alongside.
- Pre-trends are checked and plotted for every event study. A design whose
  pre-trends diverge gets reported as descriptive or dropped, not rescued.
- A null result is a finding and gets reported. The 2017 pilot in particular
  is an independent check on a circulating claim whose source memo was never
  located, so the answer matters whichever way it lands.
