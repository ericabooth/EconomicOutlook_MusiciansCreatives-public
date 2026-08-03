*! 30_venues.do - Are Austin's live-music rooms shrinking while the bar market
*!                around them grows? Receipts, attrition, closures, and a
*!                two-way fixed-effects decoupling test.
*!
*! Inputs  : 01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv
*!           01_evidence/08_venues_ecosystem/venue_summary.csv
*!           01_evidence/08_venues_ecosystem/venue_timeline.csv
*!           01_evidence/08_venues_ecosystem/closure_crossvalidation.csv
*!           01_evidence/08_venues_ecosystem/austin_outdoor_music_venue_permits_by_year.csv
*!           01_evidence/08_venues_ecosystem/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv
*!           03_analysis/data/external/TX_MB_receipts_travis_austin.dta   (staged, see below)
*!           03_analysis/data/external/geo/austin_council_districts.shp   (staged, see below)
*!           03_analysis/out/cpi_annual.dta                               (built by _setup.do)
*!
*! Outputs : 04_figures/fig09_venue_receipts_index.png  (+ out/fig09_venue_receipts_index.csv)
*!           04_figures/fig10_venue_map.png             (+ out/fig10_venue_map.csv,
*!               out/fig10_venue_change_by_district.csv, out/fig10_venue_largest_declines.csv)
*!               NOTE: figure 10 is no longer a map. The PNG and CSV keep the
*!               fig10_venue_map slug so the LaTeX \includegraphics does not
*!               break; section 9 explains why the point map was dropped. The
*!               map that replaces it is fig10b below.
*!           04_figures/fig10b_district_map.png         (+ out/fig10b_district_map.csv)
*!           04_figures/fig11_venue_supply.png          (+ out/fig11_venue_supply.csv)
*!           03_analysis/out/tables/table_venue_did.csv
*!           03_analysis/out/numbers/numbers_venues.csv
*!
*! STAGED EXTERNAL INPUTS - how they were built (one time, 2026-08-02)
*!   (a) TX_MB_receipts_travis_austin.dta - the full mixed-beverage universe the
*!       curated venue panel sits inside, so the decoupling test has a real
*!       comparison group instead of a within-panel contrast. Texas Comptroller
*!       Mixed Beverage Gross Receipts, Socrata dataset naix-2893, same filter
*!       the evidence memo used (location_county 227 OR location_city AUSTIN).
*!       Pulled in six pages of 50,000 rows with:
*!         curl -G "https://data.texas.gov/resource/naix-2893.csv" \
*!           --data-urlencode '$select=taxpayer_number,location_number,location_name,location_address,obligation_end_date_yyyymmdd,sum(total_receipts) as tot' \
*!           --data-urlencode '$group=taxpayer_number,location_number,location_name,location_address,obligation_end_date_yyyymmdd' \
*!           --data-urlencode "\$where=location_county='227' OR upper(location_city)='AUSTIN'" \
*!           --data-urlencode '$order=taxpayer_number,location_number,obligation_end_date_yyyymmdd' \
*!           --data-urlencode '$limit=50000' --data-urlencode "\$offset=<0..250000>"
*!       267,707 permit-location-months, 3,643 distinct permit locations,
*!       2007-01 to 2026-06. All 145 permit pairs in the curated venue panel
*!       match into it on upper(location_name)|upper(location_address).
*!   (b) geo/travis_county_outline.dta and geo/cb_2023_48_place_500k.* - Census
*!       TIGER cartographic boundary files for Travis County (GEOID 48453) and
*!       Texas places (Austin city limits are GEOID 4805000), from
*!       https://www2.census.gov/geo/tiger/GENZ2023/shp/ on 2026-08-02.
*!       NO LONGER READ. They drew the outlines on the old figure 10 point map,
*!       which was replaced on 2026-08-02 (see section 9). They are left in
*!       place, unused, so the map can be rebuilt without a fresh download.
*!   (c) geo/austin_council_districts.* - City of Austin single-member council
*!       district boundaries, dataset w3v2-cj58 on data.austintexas.gov,
*!       exported as a Shapefile on 2026-08-02 from
*!       https://data.austintexas.gov/api/geospatial/w3v2-cj58?method=export&format=Shapefile
*!       (315 KB zip; 10 polygons; WGS84, EPSG 4326). Copied whole into the
*!       project so the folder still travels.
*!       ONE EDIT WAS NEEDED. Socrata writes a non-zero "field data address" in
*!       bytes 12-15 of every dBASE field descriptor. shp2dta reads five bytes
*!       starting at the type byte, so it sees "D!" instead of "D" and exits
*!       with r(610) "invalid dBASE data type". Those four bytes are ignored by
*!       every reader, so they were zeroed. The untouched original is kept
*!       alongside as geo/austin_council_districts_socrata_raw.dbf; diffing the
*!       two shows the only changes are those four bytes per field.
*!       No online tile service is used anywhere in this module.

clear all
do "_setup.do"                    // run from 03_analysis/stata/
global CURMODULE "venues"
numinit

* Fail early and legibly on a missing input. This does the job of _setup.do's
* requirefile, which cannot be used here: it parses its argument with
* syntax anything, which strips the quotes, so any path containing a space
* fails. The project root on this machine sits under "My Drive".
foreach f in "${EV_VENUE}/venue_monthly_receipts_long.csv" ///
             "${EV_VENUE}/venue_summary.csv" ///
             "${EV_VENUE}/venue_timeline.csv" ///
             "${EV_VENUE}/closure_crossvalidation.csv" ///
             "${EV_VENUE}/austin_outdoor_music_venue_permits_by_year.csv" ///
             "${EV_VENUE}/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv" ///
             "${DATAX}/geo/austin_council_districts.shp" ///
             "${OUT}/cpi_annual.dta" {
    capture confirm file "`f'"
    if _rc != 0 {
        display as error "Required input not found: `f'"
        exit 601
    }
}

* Whether the citywide comparison universe is present decides which version of
* the decoupling test section 7 can run.
capture confirm file "${DATAX}/TX_MB_receipts_travis_austin.dta"
global HAVECITY = cond(_rc == 0, 1, 0)

* The panel is a curated tracking list, not a census. Registered once here so
* no downstream reader mistakes it for one.
numadd, key(venue_panel_is_curated) value(114) formatted("114 venues") ///
    unit("count") source("01_evidence/08_venues_ecosystem/venue_match_list.csv") ///
    note("Curated tracking panel of named Austin live-music rooms, 145 permit entities, not a census. The mixed-beverage file structurally omits beer-and-wine-only rooms (Carousel Lounge, Meanwhile Brewing, Whip In), venues without a separable alcohol permit (Cactus Cafe, Bass Concert Hall, Central Presbyterian) and venues folded into a hotel permit (Geraldine's). The panel over-represents Red River, East Austin and South Congress.")


* ===========================================================================
* 1. THE VENUE PANEL, REBUILT IN 2025 DOLLARS
* ===========================================================================
* Two traps are handled here and nowhere else in this module.
*
* Festival aggregation. C3 Presents files Austin City Limits bar receipts
* through concession LLCs permitted at a small venue's address, so a $12.5M
* month lands on Scoot Inn against a $38k median month. Ten venue-months carry
* extreme_outlier_flag; they are dropped before anything is summed. Left in,
* Scoot Inn alone would appear to have grown 1,358% since 2019.
*
* Dollar base. The input carries total_receipts_real_2026_06usd, a June-2026
* base that would put this module on different footing from the rest of the
* report. It is ignored. Real dollars here are rebuilt from nominal receipts
* using ${OUT}/cpi_annual.dta, the shared 2025 base, whose 2025 annual average
* rests on an interpolated October 2025 because the federal funding lapse
* stopped BLS publishing that month. October is the ACL month and carries
* outsized receipts, so that gap is not a rounding issue.

import delimited using "${EV_VENUE}/venue_monthly_receipts_long.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve)

quietly count if extreme_outlier_flag == 1
local nfest = r(N)
quietly summarize total_receipts if extreme_outlier_flag == 1, detail
local festmax = r(max)
local festsum = r(sum)
drop if extreme_outlier_flag == 1

generate int year = real(substr(obligation_month, 1, 4))
generate int mo   = real(substr(obligation_month, 6, 2))
generate int ym   = ym(year, mo)
format ym %tm

* A venue can hold several permit entities at once (Stubb's changed taxpayer in
* 2012; some rooms run a second permit for a patio), so a venue-month is the sum
* across its permits.
collapse (sum) total_receipts cover_charge_receipts ///
         (max) cpi_imputed_month = cpi_imputed ///
         (firstnm) venue_name district tier location_name location_address, ///
         by(venue_key year mo ym)
rename total_receipts       receipts_nominal
rename cover_charge_receipts cover_nominal
isid venue_key ym

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) ///
    keepusing(defl cpi_imputed) nogenerate
generate double receipts_real2025 = receipts_nominal * defl
label variable receipts_real2025 "Monthly mixed-beverage receipts, 2025 dollars"

* cpi_annual.dta only holds years with twelve published months, so 2026 has no
* deflator. Every real series below therefore ends in 2025; 2026 Jan-Jun is
* carried in nominal terms only and never compared to a full year.
quietly count if missing(defl) & year < 2026
assert r(N) == 0

tempfile venuemonth
save `venuemonth'

numadd, key(venue_festival_rows_excluded) value("`nfest'") ///
    formatted("10 venue-months") unit("count") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Rows with extreme_outlier_flag = 1 (month exceeds 20x the venue's own median and \$500k). Festival concession LLCs permitted at a venue address, almost certainly Austin City Limits bar receipts. Excluded from every receipts figure in this module.")

local fs : display %15.0fc `festsum'
numadd, key(venue_festival_dollars_excluded) value("`festsum'") ///
    formatted("\$`=trim("`fs'")'") unit("nominal dollars") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Sum of the 10 excluded festival-aggregation venue-months, nominal. Largest single month \$12,540,139 at Historic Scoot Inn, Oct 2025, against a Scoot Inn median month of \$38,434.")


* ===========================================================================
* 2. THE CITYWIDE MIXED-BEVERAGE MARKET (COMPARISON UNIVERSE)
* ===========================================================================
* Every mixed-beverage permit location in Travis County or the City of Austin,
* which is the market the curated panel sits inside. Built as a unit-month
* panel where a "unit" is the canonical venue for the 114 tracked rooms and the
* permit location for everyone else, so a venue that changed taxpayer is one
* unit rather than two.

if $HAVECITY {

    use "${DATAX}/TX_MB_receipts_travis_austin.dta", clear
    rename yr year
    keep mbkey year mo ym total_receipts_nominal

    * Attach the curated panel's identity to the citywide file on the exact
    * (location_name, location_address) crosswalk the evidence memo documents.
    preserve
        use `venuemonth', clear
        generate str200 mbkey = upper(trim(itrim(location_name))) + "|" + ///
                                upper(trim(itrim(location_address)))
        contract mbkey venue_key tier
        drop _freq
        duplicates drop mbkey, force
        tempfile xwalk
        save `xwalk'
    restore
    merge m:1 mbkey using `xwalk', keep(master match) nogenerate
    generate byte in_panel = !missing(venue_key)

    * The ten festival concession months are flagged, not deleted, because the
    * two uses pull in opposite directions. For a venue-level claim the money
    * is misattributed and has to go. For the citywide market total it is
    * genuine licensed-beverage activity in Austin and only its venue label is
    * wrong, so removing it would understate the market the panel is being
    * compared against. Below: the citywide aggregate keeps it, every
    * venue-level and regression series drops it.
    preserve
        import delimited using "${EV_VENUE}/venue_monthly_receipts_long.csv", ///
            clear varnames(1) encoding("utf-8") case(preserve)
        keep if extreme_outlier_flag == 1
        generate str200 mbkey = upper(trim(itrim(location_name))) + "|" + ///
                                upper(trim(itrim(location_address)))
        generate int year = real(substr(obligation_month, 1, 4))
        generate int mo   = real(substr(obligation_month, 6, 2))
        generate int ym   = ym(year, mo)
        keep mbkey ym
        generate byte festival_month = 1
        duplicates drop mbkey ym, force
        tempfile festdrop
        save `festdrop'
    restore
    * m:1 rather than 1:1 because a handful of location_name/location_address
    * pairs in the citywide file are held by more than one taxpayer number.
    merge m:1 mbkey ym using `festdrop', keep(master match) nogenerate
    quietly count if festival_month == 1
    display as text "  festival concession months located in citywide file: " r(N)
    assert r(N) == `nfest'
    replace festival_month = 0 if missing(festival_month)
    generate double nominal_exfest = total_receipts_nominal * (festival_month == 0)

    generate str200 unit_str = cond(in_panel, "V:" + venue_key, "P:" + mbkey)
    collapse (sum) total_receipts_nominal nominal_exfest (max) in_panel (firstnm) venue_key tier, ///
        by(unit_str year mo ym)
    isid unit_str ym

    merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) ///
        keepusing(defl) nogenerate
    generate double receipts_real2025_all = total_receipts_nominal * defl
    generate double receipts_real2025     = nominal_exfest * defl
    label variable receipts_real2025_all "Real receipts including festival concession months"
    label variable receipts_real2025     "Real receipts excluding festival concession months"

    generate byte corelm = (tier == "core_live_music")
    label variable corelm "Core live-music tier of the curated panel"
    label variable in_panel "In the 114-venue curated live-music panel"

    compress
    tempfile citymonth
    save `citymonth'

    preserve
        contract unit_str in_panel
        quietly count if in_panel == 0
        display as text "  non-panel comparison permit locations: " r(N)
        quietly count if in_panel == 1
        display as text "  panel venues carried into the citywide file: " r(N)
    restore
}
else {
    display as error "NOTE: the citywide mixed-beverage universe is not staged."
    display as error "      Section 7 will fall back to a within-panel contrast."
}


* ===========================================================================
* 3. HEADLINE ANNUAL SERIES, REAL 2025 DOLLARS
* ===========================================================================
* Four receipts series and one count:
*   (a) the full 114-venue curated panel
*   (b) the balanced panel, venues filing in both 2019 and 2025
*   (c) the core live-music tier
*   (d) every mixed-beverage permittee in Travis County / Austin
*   (e) the citywide count of permit locations that reported receipts

use `venuemonth', clear
quietly summarize receipts_nominal if year == 2019, meanonly
* Balanced set: filed positive receipts in both endpoint years.
preserve
    collapse (sum) receipts_nominal, by(venue_key year)
    keep if inlist(year, 2019, 2025)
    keep if receipts_nominal > 0
    bysort venue_key: generate byte nyr = _N
    keep if nyr == 2
    duplicates drop venue_key, force
    keep venue_key
    generate byte balanced1925 = 1
    tempfile bal
    save `bal'
    quietly count
    local nbal = r(N)
restore
merge m:1 venue_key using `bal', keep(master match) nogenerate
replace balanced1925 = 0 if missing(balanced1925)

preserve
    collapse (sum) receipts_nominal, by(venue_key tier year balanced1925)
    keep if inlist(year, 2019, 2025) & receipts_nominal > 0 & balanced1925 == 1 & tier == "core_live_music"
    duplicates drop venue_key, force
    quietly count
    local nbalcore = r(N)
restore

generate double rec_core     = receipts_real2025 * (tier == "core_live_music")
generate double rec_balanced = receipts_real2025 * balanced1925
generate byte   any_receipts = receipts_nominal > 0

collapse (sum) panel_real = receipts_real2025 core_real = rec_core ///
               balanced_real = rec_balanced cover_nominal ///
               nvenues = any_receipts, ///
         by(year)
tempfile panelyear
save `panelyear'

if $HAVECITY {
    use `citymonth', clear
    generate byte active = total_receipts_nominal > 0
    * A permit location counts as active in a year if it reported any receipts
    * in that year. This is a distinct-locations-per-year count, which sits
    * above the average monthly count in the evidence memo.
    preserve
        keep if active
        contract unit_str year
        drop _freq
        contract year
        rename _freq citywide_permits
        tempfile permcount
        save `permcount'
    restore
    * panelcheck_real reruns the panel total out of the citywide file. It must
    * reproduce the panel total built from the evidence CSV; if the crosswalk
    * ever drifts, this assert catches it rather than a reader catching it.
    generate double rec_panel_exf = receipts_real2025 * in_panel
    collapse (sum) citywide_real = receipts_real2025_all ///
                   citywide_real_exf = receipts_real2025 ///
                   panelcheck_real = rec_panel_exf, by(year)
    merge 1:1 year using `permcount', nogenerate
    tempfile cityyear
    save `cityyear'

    use `panelyear', clear
    merge 1:1 year using `cityyear', keep(master match) nogenerate
    generate double reldiff = abs(panelcheck_real - panel_real) / panel_real
    assert reldiff < 0.001 if !missing(reldiff)
    drop reldiff panelcheck_real
    generate double panel_share = 100 * panel_real / citywide_real
}
else {
    use `panelyear', clear
    generate double citywide_real     = .
    generate double citywide_real_exf = .
    generate double citywide_permits  = .
    generate double panel_share       = .
}

sort year
list year panel_real core_real balanced_real citywide_real citywide_permits panel_share nvenues, ///
    sep(0) noobs

* --- percentage changes 2019 to 2025 ---------------------------------------
foreach s in panel core balanced citywide {
    quietly summarize `s'_real if year == 2019, meanonly
    local v19_`s' = r(mean)
    quietly summarize `s'_real if year == 2025, meanonly
    local v25_`s' = r(mean)
    local pc_`s' = 100 * (`v25_`s'' / `v19_`s'' - 1)
}
quietly summarize citywide_permits if year == 2019, meanonly
local perm19 = r(mean)
quietly summarize citywide_permits if year == 2025, meanonly
local perm25 = r(mean)
local pc_perm = 100 * (`perm25' / `perm19' - 1)

local srcRC "01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv"
local srcCity "03_analysis/data/external/TX_MB_receipts_travis_austin.dta (Comptroller naix-2893, retrieved 2026-08-02)"
local defnote "Nominal mixed-beverage receipts deflated with CPI-U annual averages to 2025 dollars via out/cpi_annual.dta; the 2025 average uses an interpolated October 2025 (cpi_imputed = 1) because BLS did not publish that month. Ten festival concession venue-months are excluded from every venue-level series; they stay in the citywide market total, where the money is real Austin licensed-beverage activity and only its venue label is wrong."

local f : display %12.1fc `=`v19_panel'/1e6'
numadd, key(venue_panel_real_2019) value("`v19_panel'") formatted("\$`=trim("`f'")'M") ///
    unit("millions of 2025 dollars") source("`srcRC'") ///
    note("Full 114-venue curated panel, calendar 2019. `defnote'")
local f : display %12.1fc `=`v25_panel'/1e6'
numadd, key(venue_panel_real_2025) value("`v25_panel'") formatted("\$`=trim("`f'")'M") ///
    unit("millions of 2025 dollars") source("`srcRC'") ///
    note("Full 114-venue curated panel, calendar 2025. `defnote'")
local f : display %6.1f `pc_panel'
numadd, key(venue_panel_pct_2019_2025) value("`pc_panel'") formatted("`=trim("`f'")'%") ///
    unit("percent change, real") source("`srcRC'") ///
    note("Full 114-venue curated panel, real receipts 2019 to 2025. `defnote'")

local f : display %12.1fc `=`v19_core'/1e6'
numadd, key(venue_core_real_2019) value("`v19_core'") formatted("\$`=trim("`f'")'M") ///
    unit("millions of 2025 dollars") source("`srcRC'") ///
    note("Core live-music tier (78 venues classified as primarily live music), calendar 2019. `defnote'")
local f : display %12.1fc `=`v25_core'/1e6'
numadd, key(venue_core_real_2025) value("`v25_core'") formatted("\$`=trim("`f'")'M") ///
    unit("millions of 2025 dollars") source("`srcRC'") ///
    note("Core live-music tier, calendar 2025. `defnote'")
local f : display %6.1f `pc_core'
numadd, key(venue_core_pct_2019_2025) value("`pc_core'") formatted("`=trim("`f'")'%") ///
    unit("percent change, real") source("`srcRC'") ///
    note("Core live-music tier, real receipts 2019 to 2025. `defnote'")

numadd, key(venue_balanced_n) value("`nbal'") formatted("`nbal' venues") unit("count") ///
    source("`srcRC'") ///
    note("Venues with positive receipts in both 2019 and 2025; denominator for the balanced-panel change. Of these, `nbalcore' are core live-music rooms.")
local f : display %6.1f `pc_balanced'
numadd, key(venue_balanced_pct_2019_2025) value("`pc_balanced'") formatted("`=trim("`f'")'%") ///
    unit("percent change, real") source("`srcRC'") ///
    note("Balanced panel of `nbal' venues filing in both 2019 and 2025, real receipts. `defnote'")

if $HAVECITY {
    local f : display %12.0fc `=`v19_citywide'/1e6'
    numadd, key(venue_citywide_real_2019) value("`v19_citywide'") formatted("\$`=trim("`f'")'M") ///
        unit("millions of 2025 dollars") source("`srcCity'") ///
        note("All mixed-beverage permit locations in Travis County or the City of Austin, calendar 2019. `defnote'")
    local f : display %12.0fc `=`v25_citywide'/1e6'
    numadd, key(venue_citywide_real_2025) value("`v25_citywide'") formatted("\$`=trim("`f'")'M") ///
        unit("millions of 2025 dollars") source("`srcCity'") ///
        note("All mixed-beverage permit locations in Travis County or the City of Austin, calendar 2025. `defnote'")
    local f : display %6.1f `pc_citywide'
    numadd, key(venue_citywide_pct_2019_2025) value("`pc_citywide'") formatted("+`=trim("`f'")'%") ///
        unit("percent change, real") source("`srcCity'") ///
        note("All Travis/Austin mixed-beverage permittees, real receipts 2019 to 2025. This is the market comparison for the panel decline. `defnote'")

    local f : display %8.0fc `perm19'
    numadd, key(venue_citywide_permits_2019) value("`perm19'") formatted("`=trim("`f'")'") ///
        unit("count of permit locations") source("`srcCity'") ///
        note("Distinct mixed-beverage permit locations reporting any receipts during calendar 2019, Travis County or City of Austin. A distinct-locations-per-year count, so it runs above the average monthly count of active permits.")
    local f : display %8.0fc `perm25'
    numadd, key(venue_citywide_permits_2025) value("`perm25'") formatted("`=trim("`f'")'") ///
        unit("count of permit locations") source("`srcCity'") ///
        note("Distinct mixed-beverage permit locations reporting any receipts during calendar 2025, Travis County or City of Austin.")
    local f : display %6.1f `pc_perm'
    numadd, key(venue_citywide_permits_pct_2019_2025) value("`pc_perm'") formatted("+`=trim("`f'")'%") ///
        unit("percent change") source("`srcCity'") ///
        note("Growth in the count of active mixed-beverage permit locations, 2019 to 2025. Austin kept adding licensed rooms while the tracked music rooms contracted.")

    foreach y in 2013 2019 2025 {
        quietly summarize panel_share if year == `y', meanonly
        local sh = r(mean)
        local f : display %4.1f `sh'
        numadd, key(venue_panel_share_`y') value("`sh'") formatted("`=trim("`f'")'%") ///
            unit("percent of citywide receipts") source("`srcCity'") ///
            note("Curated panel receipts as a share of all Travis/Austin mixed-beverage receipts in `y'. The share is stable across the period, which is why the panel-versus-citywide divergence is not a coverage artifact. Deflation cancels in a same-year ratio, so this share is identical nominal or real.")
    }
}

save "${OUT}/venue_annual_series.dta", replace


* ===========================================================================
* 4. VENUE-LEVEL CHANGE DISTRIBUTION, 2019 TO 2025
* ===========================================================================
use `venuemonth', clear
keep if inlist(year, 2019, 2025)
collapse (sum) receipts_real2025 (firstnm) venue_name district tier, by(venue_key year)
reshape wide receipts_real2025, i(venue_key venue_name district tier) j(year)
rename receipts_real20252019 real2019
rename receipts_real20252025 real2025
foreach v in real2019 real2025 {
    replace `v' = 0 if missing(`v')
}

* Two denominators, kept separate on purpose. The "filed in 2019" set counts a
* venue that stopped filing as a total loss, which is the right frame for the
* stock of rooms. The balanced set answers a narrower question about survivors.
generate byte filed2019 = real2019 > 0
generate byte balanced  = real2019 > 0 & real2025 > 0
generate double pctchg  = 100 * (real2025 / real2019 - 1) if filed2019

quietly count if filed2019
local n19 = r(N)
quietly count if filed2019 & real2025 < real2019
local nshrank = r(N)
quietly count if balanced
local nbal2 = r(N)
quietly count if balanced & real2025 < real2019
local nshrank_bal = r(N)
quietly summarize pctchg if balanced, detail
local med_bal = r(p50)
quietly summarize pctchg if filed2019, detail
local med_all = r(p50)

* The evidence memo's "three in four" claim uses a size floor, so reproduce it.
quietly count if real2019 > 250000
local n250 = r(N)
quietly count if real2019 > 250000 & real2025 < real2019
local n250shrank = r(N)

gsort pctchg
list venue_name tier real2019 real2025 pctchg if balanced in 1/10, sep(0) noobs abbreviate(20)
gsort -pctchg
list venue_name tier real2019 real2025 pctchg if balanced in 1/10, sep(0) noobs abbreviate(20)

* Where do the aggregate gains sit? Sum the dollar gain among growers and ask
* how much of it belongs to the large ticketed rooms.
generate double gain = real2025 - real2019
quietly summarize gain if gain > 0 & balanced, meanonly
local totgain = r(sum)
quietly summarize gain if gain > 0 & balanced & tier == "large_venue", meanonly
local biggain = r(sum)
local nbiggain = r(N)
local sharegain = 100 * `biggain' / `totgain'

gsort pctchg
local worst1n = venue_name[1]
local worst1p = pctchg[1]
local worst2n = venue_name[2]
local worst2p = pctchg[2]
gsort -gain
local best1n = venue_name[1]
local best1g = gain[1]

local srcRC "01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv"
numadd, key(venue_shrank_n) value("`nshrank'") formatted("`nshrank' of `n19'") unit("count") ///
    source("`srcRC'") ///
    note("Venues with lower real receipts in 2025 than 2019, among the `n19' panel venues that filed any receipts in 2019. Venues that stopped filing count as zero in 2025, which is the intended treatment.")
numadd, key(venue_shrank_denom) value("`n19'") formatted("`n19' venues") unit("count") ///
    source("`srcRC'") note("Denominator: panel venues with positive receipts in calendar 2019.")
numadd, key(venue_shrank_balanced_n) value("`nshrank_bal'") formatted("`nshrank_bal' of `nbal2'") ///
    unit("count") source("`srcRC'") ///
    note("Among the `nbal2' venues filing in both years, the number smaller in real terms in 2025.")
local f : display %6.1f `med_bal'
numadd, key(venue_median_pct_change) value("`med_bal'") formatted("`=trim("`f'")'%") ///
    unit("percent change, real, median venue") source("`srcRC'") ///
    note("Median venue-level real change 2019 to 2025 among the `nbal2' venues filing in both years. Unweighted across venues, so it is not the aggregate change.")
local f : display %6.1f `med_all'
numadd, key(venue_median_pct_change_incl_exits) value("`med_all'") formatted("`=trim("`f'")'%") ///
    unit("percent change, real, median venue") source("`srcRC'") ///
    note("Median venue-level real change 2019 to 2025 across all `n19' venues filing in 2019, counting non-filers in 2025 as zero.")
numadd, key(venue_shrank_over250k) value("`n250shrank'") formatted("`n250shrank' of `n250'") ///
    unit("count") source("`srcRC'") ///
    note("Venues with more than \$250,000 of real 2019 receipts that were smaller in real terms by 2025.")
local f : display %6.1f `worst1p'
numadd, key(venue_worst_decline_name) value("`worst1p'") formatted("`worst1n', `=trim("`f'")'%") ///
    unit("percent change, real") source("`srcRC'") ///
    note("Steepest real decline 2019 to 2025 among venues filing in both years.")
local f : display %6.1f `sharegain'
numadd, key(venue_gain_share_large_rooms) value("`sharegain'") formatted("`=trim("`f'")'%") ///
    unit("percent of aggregate dollar gain") source("`srcRC'") ///
    note("Share of the total real dollar gain among growing balanced-panel venues that accrues to the `nbiggain' venues classified large_venue - large ticketed rooms that opened or expanded after 2021 (ACL Live at Moody Theater/3TEN, Moody Amphitheater, The Concourse). Gains are concentrated in these rooms, not in small clubs.")

export delimited venue_key venue_name district tier real2019 real2025 pctchg ///
    using "${OUT}/venue_change_2019_2025.csv", replace


* ===========================================================================
* 5. ATTRITION: WHO STOPPED FILING, AND WHEN
* ===========================================================================
import delimited using "${EV_VENUE}/venue_summary.csv", clear varnames(1) ///
    encoding("utf-8") case(preserve) bindquotes(strict)
generate int first_year = real(substr(first_month, 1, 4))
generate int last_year  = real(substr(last_month, 1, 4))
generate byte exited    = (still_reporting_2026_06 == "no")
generate byte core      = (tier == "core_live_music")
generate int exit_year  = last_year if exited

quietly count
local nven = r(N)
quietly count if exited
local nexit = r(N)
quietly count if exited & inrange(exit_year, 2010, 2019)
local nexit_pre = r(N)
quietly count if exited & exit_year >= 2020
local nexit_post = r(N)
quietly count if exited & exit_year >= 2020 & core
local nexit_post_core = r(N)
quietly count if exited & inrange(exit_year, 2010, 2019) & core
local nexit_pre_core = r(N)

table (exit_year) (core) if exited, statistic(frequency) nototals
tabulate exit_year core if exited

* Entries in 2007 are left-censored: the receipts file itself starts 2007-01,
* so a venue already trading then registers as an entry. The era totals below
* say so rather than quietly inflating the early period.
preserve
    contract first_year
    rename _freq entries
    rename first_year yearx
    tempfile ent
    save `ent'
restore
preserve
    keep if exited
    contract exit_year
    rename _freq exits
    rename exit_year yearx
    tempfile ex
    save `ex'
restore
clear
set obs 20
generate int yearx = 2006 + _n
merge 1:1 yearx using `ent', nogenerate
merge 1:1 yearx using `ex',  nogenerate
foreach v in entries exits {
    replace `v' = 0 if missing(`v')
}
generate int netadds = entries - exits
quietly summarize netadds if inrange(yearx, 2007, 2015), meanonly
local net0715 = r(sum)
quietly summarize netadds if inrange(yearx, 2008, 2015), meanonly
local net0815 = r(sum)
quietly summarize netadds if inrange(yearx, 2016, 2026), meanonly
local net1626 = r(sum)
list yearx entries exits netadds, sep(0) noobs
tempfile netadds
save `netadds'

local srcVS "01_evidence/08_venues_ecosystem/venue_summary.csv"
numadd, key(venue_exits_total) value("`nexit'") formatted("`nexit' of `nven'") unit("count") ///
    source("`srcVS'") ///
    note("Panel venues whose permit had stopped filing by 2026-06. Ceasing to file usually means closure but can also mean a permit transfer, an entity restructuring, or a switch to a beer-and-wine permit, so this is 'stopped reporting', not a verified closure count.")
numadd, key(venue_exits_2010_2019) value("`nexit_pre'") formatted("`nexit_pre' exits") unit("count") ///
    source("`srcVS'") note("Venues whose last filing month falls in 2010-2019; `nexit_pre_core' of them core live-music rooms.")
numadd, key(venue_exits_2020_2026) value("`nexit_post'") formatted("`nexit_post' exits") unit("count") ///
    source("`srcVS'") note("Venues whose last filing month falls in 2020-2026 (through 2026-06); `nexit_post_core' of them core live-music rooms.")
numadd, key(venue_exits_2020_2026_core) value("`nexit_post_core'") ///
    formatted("`nexit_post_core' of `nexit_post'") unit("count") source("`srcVS'") ///
    note("Post-2020 exits that are core live-music rooms. Exits split roughly evenly across eras, but the composition shifted: the post-2020 cohort is overwhelmingly live-music rooms rather than adjacent bars.")
numadd, key(venue_net_adds_2007_2015) value("`net0715'") formatted("+`net0715'") unit("net venues") ///
    source("`srcVS'") ///
    note("Entries minus exits, 2007-2015. Left-censored: the receipts file begins 2007-01, so the 44 venues already trading then all register as 2007 entries. Excluding 2007 entirely, the 2008-2015 net is +`net0815'.")
numadd, key(venue_net_adds_2016_2026) value("`net1626'") formatted("`net1626'") unit("net venues") ///
    source("`srcVS'") ///
    note("Entries minus exits, 2016 through 2026-06. The panel stopped net-adding rooms around 2016. Not left-censored, but right-truncated at 2026-06.")


* ===========================================================================
* 6. CLOSURE CAUSES FROM THE NEWS TIMELINE
* ===========================================================================
* These reasons are journalist-cited, not audited, and the timeline is not a
* register: about 37 venues on the target list have no row at all, so absence
* means "not found", never "nothing happened".
import delimited using "${EV_VENUE}/venue_timeline.csv", clear varnames(1) ///
    encoding("utf-8") case(preserve) bindquotes(strict)
quietly count
local ntl = r(N)
generate byte dated_closure = !missing(closed_year) & ///
    (status == "closed" | status == "closed_relocated")
quietly count if dated_closure
local ndated = r(N)
quietly count if dated_closure & (missing(reason_category) | reason_category == "")
local noreason = r(N)

tabulate reason_category if dated_closure, sort
preserve
    keep if dated_closure
    replace reason_category = "not_stated" if missing(reason_category) | reason_category == ""
    contract reason_category
    gsort -_freq
    rename _freq n_closures
    generate double pct_of_dated = 100 * n_closures / `ndated'
    list, sep(0) noobs
    export delimited using "${OUT}/venue_closure_reasons.csv", replace
    foreach r in covid rent_increase sale_of_property redevelopment financial permit_regulatory lease_expiration {
        quietly summarize n_closures if reason_category == "`r'", meanonly
        local n_`r' = cond(r(N) == 0, 0, r(mean))
    }
restore

local srcTL "01_evidence/08_venues_ecosystem/venue_timeline.csv"
numadd, key(venue_closures_dated_n) value("`ndated'") formatted("`ndated' closures") unit("count") ///
    source("`srcTL'") ///
    note("Rows in the 71-row news timeline coded closed or closed_relocated with a closure year. This is the denominator for every closure-reason share. The timeline is a news-derived record, not a register: roughly 37 venues on the target list have no row, and absence means the research did not find coverage, not that nothing happened.")
numadd, key(venue_timeline_rows) value("`ntl'") formatted("`ntl' rows") unit("count") ///
    source("`srcTL'") ///
    note("Total timeline rows, including still-open, at-risk, reopened and opening events as well as closures.")
numadd, key(venue_closures_no_reason) value("`noreason'") formatted("`noreason' of `ndated'") unit("count") ///
    source("`srcTL'") note("Dated closures with no reason category coded.")
numadd, key(venue_closures_covid) value("`n_covid'") formatted("`n_covid' of `ndated'") unit("count") ///
    source("`srcTL'") ///
    note("Dated closures citing COVID. Journalist-cited, not audited; a venue can have more than one cause and only the primary one is coded.")
local n_prop = `n_rent_increase' + `n_sale_of_property' + `n_redevelopment' + `n_lease_expiration'
numadd, key(venue_closures_property) value("`n_prop'") formatted("`n_prop' of `ndated'") unit("count") ///
    source("`srcTL'") ///
    note("Dated closures citing a property cause: rent increase (`n_rent_increase'), sale of property (`n_sale_of_property'), redevelopment (`n_redevelopment') or lease expiration (`n_lease_expiration'). Property causes together outnumber COVID (`n_covid').")

* Cross-validation of the news record against permit filings.
import delimited using "${EV_VENUE}/closure_crossvalidation.csv", clear varnames(1) ///
    encoding("utf-8") case(preserve) bindquotes(strict)
tabulate agreement
quietly count if agreement == "agrees"
local cv_agree = r(N)
quietly count if agreement == "receipts_continue_later"
local cv_later = r(N)
quietly count if agreement == "no_receipts_match"
local cv_none = r(N)
numadd, key(venue_closure_crossval_continue) value("`cv_later'") ///
    formatted("`cv_later' of `ndated'") unit("count") ///
    source("01_evidence/08_venues_ecosystem/closure_crossvalidation.csv") ///
    note("Reported closures where the permit kept filing receipts past the reported closure year (`cv_agree' agree with the receipts record, `cv_none' never appear in the mixed-beverage file). A venue-level closure date marks the death of a programming operation, which can precede the death of the business by years.")


* ===========================================================================
* 7. THE DECOUPLING TEST (TWO-WAY FIXED EFFECTS)
* ===========================================================================
* Question: once every venue's own level and every calendar month's shock are
* absorbed, do live-music rooms track the rest of the licensed bar market?
*
* This is a descriptive divergence test, not a policy evaluation. Nothing here
* is randomised and no policy switches on at a date.

eststo clear
if $HAVECITY {
    use `citymonth', clear
    keep if inrange(year, 2013, 2026)
    * Zero-receipt months drop out of a log specification. That is a real
    * limitation during 2020, when a closed room reports zero rather than a
    * small number, so the log estimates describe venues conditional on
    * trading. Column 4 uses inverse hyperbolic sine to keep the zeros.
    generate double lnreal = ln(receipts_real2025) if receipts_real2025 > 0
    generate double ihsreal = asinh(receipts_real2025)
    quietly count
    local n_all = r(N)
    quietly count if missing(lnreal)
    local n_zero = r(N)
    display as text "  unit-months with zero or missing receipts (dropped from log models): `n_zero' of `n_all'"

    egen long unit_id = group(unit_str)
    generate byte post = (ym >= ym(2020,3))
    label variable post "March 2020 onward"

    * cpi_annual has no 2026 deflator, so 2026 months have missing real
    * receipts and leave the estimation sample automatically.
    label variable in_panel "Curated live-music panel"
    label variable corelm   "Core live-music tier"

    generate byte did_panel = post * in_panel
    label variable did_panel "Post-March-2020 x curated live-music panel"
    eststo m1: reghdfe lnreal did_panel, ///
        absorb(unit_id ym) vce(cluster unit_id)
    estadd local samp "Panel vs all others"
    estadd local dvar "log real receipts"

    generate byte did_core = post * corelm
    label variable did_core "Post-March-2020 x core live-music tier"
    eststo m2: reghdfe lnreal did_core if in_panel == 0 | corelm == 1, ///
        absorb(unit_id ym) vce(cluster unit_id)
    estadd local samp "Core tier vs all others"
    estadd local dvar "log real receipts"
    local did_b  = _b[did_core]
    local did_se = _se[did_core]
    local did_p  = 2 * ttail(e(df_r), abs(`did_b'/`did_se'))
    local did_n  = e(N)
    local did_u  = e(N_clust)

    * Event study. 2019 is the omitted base year, so each coefficient is the
    * gap between core live-music rooms and the rest of the market in that year
    * relative to their 2019 gap.
    * Build the year-by-core interactions by hand, omitting 2019, rather than
    * relying on ib2019. With venue and year-month fixed effects absorbed, the
    * full set of year-by-core terms is identified only up to one normalisation,
    * and reghdfe resolved that by dropping 2025 while leaving 2019 estimated.
    * The coefficients then read against 2025 instead of the intended pre-COVID
    * base, and the extraction picked up the omitted 2025 term as a literal
    * zero. Constructing the dummies explicitly fixes the base year.
    capture drop coreX*
    quietly levelsof year, local(esyears)
    local esterms ""
    foreach y of local esyears {
        if `y' != 2019 {
            quietly generate byte coreX`y' = (year == `y') * corelm
            label variable coreX`y' "`y' x core live-music tier"
            local esterms "`esterms' coreX`y'"
        }
    }
    eststo m3: reghdfe lnreal `esterms' if in_panel == 0 | corelm == 1, ///
        absorb(unit_id ym) vce(cluster unit_id)
    estadd local samp "Core tier vs all others"
    estadd local dvar "log real receipts, 2019 base"
    local es25_b  = _b[coreX2025]
    local es25_se = _se[coreX2025]
    local es24_b  = _b[coreX2024]
    local es22_b  = _b[coreX2022]
    local es15_b  = _b[coreX2015]
    local es17_b  = _b[coreX2017]

    eststo m4: reghdfe ihsreal did_core if in_panel == 0 | corelm == 1, ///
        absorb(unit_id ym) vce(cluster unit_id)
    estadd local samp "Core tier vs all others"
    estadd local dvar "asinh real receipts"

    local didlabel "Travis/Austin mixed-beverage universe"
}
else {
    * Fallback documented in the module brief: with no citywide universe the
    * only available contrast is within the curated panel, which is a weaker
    * design because both groups are live-music-adjacent.
    display as error "FALLBACK: estimating a WITHIN-PANEL contrast only."
    use `venuemonth', clear
    keep if inrange(year, 2013, 2026)
    generate double lnreal = ln(receipts_real2025) if receipts_real2025 > 0
    generate double ihsreal = asinh(receipts_real2025)
    egen long unit_id = group(venue_key)
    generate byte post   = (ym >= ym(2020,3))
    generate byte corelm = (tier == "core_live_music")
    generate byte in_panel = 1
    label variable post   "March 2020 onward"
    label variable corelm "Core live-music tier"
    capture drop did_core
    generate byte did_core = post * corelm
    label variable did_core "Post-March-2020 x core live-music tier"
    eststo m2: reghdfe lnreal did_core if tier != "live_music_adjacent", ///
        absorb(unit_id ym) vce(cluster unit_id)
    estadd local samp "Core tier vs large ticketed rooms (WITHIN PANEL)"
    estadd local dvar "log real receipts"
    local did_b  = _b[did_core]
    local did_se = _se[did_core]
    local did_p  = 2 * ttail(e(df_r), abs(`did_b'/`did_se'))
    local did_n  = e(N)
    local did_u  = e(N_clust)
    eststo m3: reghdfe lnreal ib2019.year#c.corelm if tier != "live_music_adjacent", ///
        absorb(unit_id ym) vce(cluster unit_id)
    estadd local samp "Core tier vs large ticketed rooms (WITHIN PANEL)"
    estadd local dvar "log real receipts"
    local es25_b  = _b[2025.year#c.corelm]
    local es25_se = _se[2025.year#c.corelm]
    local didlabel "WITHIN-PANEL contrast only; citywide universe unavailable"
}

esttab * using "${TABDIR}/table_venue_did.csv", replace ///
    csv se star(* 0.10 ** 0.05 *** 0.01) label b(4) se(4) ///
    scalars("samp Comparison group" "dvar Dependent variable") ///
    title("Live-music rooms against the rest of the Austin mixed-beverage market") ///
    addnotes("Two-way fixed effects: venue or permit location, and calendar month." ///
             "Standard errors clustered by venue or permit location." ///
             "Real receipts in 2025 dollars; ten festival concession venue-months excluded." ///
             "Descriptive divergence test, not a causal estimate of any policy.")
display as text "  table -> out/tables/table_venue_did.csv"

local pctdid = 100 * (exp(`did_b') - 1)
local f  : display %6.3f `did_b'
local fs : display %6.3f `did_se'
local fp : display %6.1f `pctdid'
numadd, key(venue_did_coef) value("`did_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcCity'") ///
    note("reghdfe lnreal did_core (did_core = post x core tier), absorb(unit_id ym) vce(cluster unit_id). Sample: `didlabel', 2013-01 to 2025-12, monthly. post = March 2020 onward. Core live-music rooms' log real receipts relative to the comparison group, after venue and month fixed effects. Approximately `=trim("`fp'")' percent. Descriptive divergence, not a causal policy estimate.")
numadd, key(venue_did_se) value("`did_se'") formatted("`=trim("`fs'")'") ///
    unit("log points, clustered SE") source("`srcCity'") ///
    note("Standard error on venue_did_coef, clustered by venue or permit location; `did_u' clusters, `did_n' unit-months.")
local fpv : display %6.4f `did_p'
numadd, key(venue_did_p) value("`did_p'") formatted("`=trim("`fpv'")'") unit("p-value") ///
    source("`srcCity'") note("Two-sided p-value for venue_did_coef.")
numadd, key(venue_did_pct) value("`pctdid'") formatted("`=trim("`fp'")'%") ///
    unit("percent") source("`srcCity'") ///
    note("exp(coefficient) - 1, the proportional gap implied by venue_did_coef. Conditional on a venue trading in the month, because zero-receipt months leave a log specification.")
numadd, key(venue_did_n) value("`did_n'") formatted("`did_n' unit-months") unit("count") ///
    source("`srcCity'") note("Estimation sample for venue_did_coef; `did_u' clusters.")
local f  : display %6.3f `es25_b'
local fs : display %6.3f `es25_se'
numadd, key(venue_es_2025_coef) value("`es25_b'") formatted("`=trim("`f'")'") ///
    unit("log points, 2019 base") source("`srcCity'") ///
    note("Event-study coefficient on 2025 x core live-music, 2019 omitted. Clustered SE `=trim("`fs'")'. Reads as the 2025 gap between core live-music rooms and the rest of the market relative to their 2019 gap.")


* ===========================================================================
* 8. FIGURE 9 - THE SIGNATURE FIGURE
* ===========================================================================
use "${OUT}/venue_annual_series.dta", clear
keep if inrange(year, 2013, 2025)
foreach s in core panel citywide {
    quietly summarize `s'_real if year == 2019, meanonly
    generate double idx_`s' = 100 * `s'_real / r(mean)
}
label variable idx_core     "Core live-music tier"
label variable idx_panel    "Full 114-venue panel"
label variable idx_citywide "All Austin mixed-beverage permittees"

export delimited year core_real panel_real balanced_real citywide_real citywide_real_exf ///
    idx_core idx_panel idx_citywide citywide_permits panel_share nvenues ///
    using "${OUT}/fig09_venue_receipts_index.csv", replace

quietly summarize idx_core if year == 2025, meanonly
local lab_core = r(mean)
quietly summarize idx_panel if year == 2025, meanonly
local lab_panel = r(mean)
quietly summarize idx_citywide if year == 2025, meanonly
local lab_city = r(mean)

* Horizontal gridlines run behind the three right-hand direct labels and add
* visible noise under the text. A white box behind each label masks the line
* without dropping gridlines from the plot itself.
local halo `"box fcolor(white) lcolor(none) margin(l=0.6 r=0.6 t=0.4 b=0.4)"'

twoway ///
  (line idx_citywide year, lcolor("${MUTED}") lwidth(medthick) lpattern(shortdash)) ///
  (line idx_panel    year, lcolor("${NAVY}")  lwidth(medthick)) ///
  (line idx_core     year, lcolor("${ORANGE}") lwidth(thick)) ///
  , yline(100, lcolor("${BORDER}") lwidth(thin)) ///
    ytitle("Index, 2019 = 100", $YTOPT) ///
    ylabel(20(20)140, angle(0) labsize(2.8)) ///
    xtitle("") xlabel(2013 2015 2017 2019 2021 2023 2025, labsize(2.8) nolabels) ///
    xscale(range(2013 2030.4)) ///
    text(`lab_city'  2025.4 "All Austin mixed-beverage permittees", color("${MUTED}")  size(2.7) placement(e) justification(left) `halo') ///
    text(`lab_panel' 2025.4 "Full 114-venue panel", color("${NAVY}")   size(2.7) placement(e) justification(left) `halo') ///
    text(`lab_core'  2025.4 "Core live-music tier", color("${ORANGE}") size(2.7) placement(e) justification(left) `halo') ///
    legend(off) graphregion(color(white)) plotregion(margin(l=0 r=0)) ///
    name(g09a, replace) nodraw

twoway ///
  (line citywide_permits year, lcolor("${MUTED}") lwidth(medthick) ///
        mcolor("${MUTED}") msymbol(none)) ///
  , ytitle("Active permit locations", $YTOPT) ///
    ylabel(1000(250)1750, angle(0) labsize(2.6)) ///
    xtitle("") xlabel(2013 2015 2017 2019 2021 2023 2025, labsize(2.6)) ///
    xscale(range(2013 2030.4)) ///
    legend(off) graphregion(color(white)) plotregion(margin(l=0 r=0)) ///
    name(g09b, replace) nodraw

* The two panels share one x axis, so the tick labels are drawn once, under the
* lower panel. Both vertical axes start above zero, which the subtitle says.
graph combine g09a g09b, cols(1) imargin(0 0 2 0) ///
    xcommon graphregion(color(white)) ///
    ysize(6.4) xsize(8.4) ///
    title("Austin's live-music rooms shrank as the bar market grew", $TITLEOPT) ///
    subtitle("Real mixed-beverage receipts in 2025 dollars, indexed to 2019 = 100, and the count of" ///
             "active permit locations. Travis County and Austin, 2013-2025; no axis starts at zero.", $SUBOPT) ///
    name(fig09, replace)
figsave, name(fig09_venue_receipts_index)


* ===========================================================================
* 9. FIGURE 10 - WHERE RECEIPTS FELL, AND THE LARGEST DECLINES
* ===========================================================================
* WHY THIS IS NOT A MAP ANY MORE (2026-08-02).
* Through three drafts this figure was a point map of the panel venues. It was
* rebuilt as two bar panels after the rendered PNG was checked at the 6.5 inch
* width the report prints at. Four things kill the point map, and only the last
* two are fixable by redrawing it:
*   1. Coverage. Only 67 of the 114 panel venues geocode, and only 53 of those
*      also have a 2019-to-2025 change to colour, so fewer than half the panel
*      could ever be drawn. A reader takes the map for the panel.
*   2. Density. Half the geocoded venues sit inside roughly one square
*      kilometre of downtown and Red River. At 6.5 inches that cluster is about
*      one inch across and the markers merge into a single blob.
*   3. Marker area. twoway scatter with [aweight=] renormalises the weights
*      WITHIN each plot, so a $6M venue in the orange layer and a $0.3M venue
*      in the navy layer render at the same size. The old subtitle claim that
*      marker area was 2019 receipts was therefore not true across categories.
*   4. Grayscale. Two of the five categories were separated by colour alone.
* The bar version below carries the same finding on all 79 venues that filed in
* 2019 rather than the 53 that could be plotted, keeps the geography as named
* parts of Austin, and reads at print size.
*
* The geocoding block is kept because the coordinate count and the frame
* diagnostic are registered numbers the report already quotes.
*
* Coordinates come from the City of Austin geocoded sound-ordinance permit file
* (g3rj-dfgm), matched to the receipts panel on a normalised street address and,
* failing that, on a normalised venue name. Every sub-type of sound permit is
* used, not just Outdoor Music Venue, because any permit at an address supplies
* the same point.

capture program drop addrkey
program define addrkey
    * Build a comparable address key: house number plus street name, with
    * directionals, street types and suite tails removed. Austin's permit file
    * writes 611 E 7th St as "611 7TH ST" and 300 S Lamar as "300 SB LAMAR
    * BLVD", so a literal string match fails on a large share of central-city
    * addresses.
    syntax varname(string), GENerate(name)
    quietly {
        tempvar a hnum rest
        generate str100 `a' = upper(itrim(trim(`varlist')))
        replace `a' = ustrregexra(`a', " (STE|SUITE|UNIT|APT|BLDG|FL|#).*$", "")
        replace `a' = ustrregexra(`a', "[^A-Z0-9 ]", " ")
        replace `a' = itrim(trim(`a'))
        generate str12  `hnum' = word(`a', 1)
        generate str100 `rest' = trim(subinstr(`a', `hnum', "", 1))
        foreach t in N S E W NE NW SE SW NB SB EB WB NORTH SOUTH EAST WEST {
            replace `rest' = itrim(trim(subinstr(" " + `rest' + " ", " `t' ", " ", .)))
        }
        foreach t in ST STREET AVE AVENUE BLVD BOULEVARD DR DRIVE RD ROAD LN LANE {
            replace `rest' = itrim(trim(subinstr(" " + `rest' + " ", " `t' ", " ", .)))
        }
        foreach t in WAY PKWY PARKWAY HWY HIGHWAY CIR CT TRL LOOP EXPY FWY PL PLZ {
            replace `rest' = itrim(trim(subinstr(" " + `rest' + " ", " `t' ", " ", .)))
        }
        generate str100 `generate' = `hnum' + subinstr(`rest', " ", "", .)
        replace `generate' = "" if `hnum' == "" | `rest' == ""
    }
end

capture program drop namekey
program define namekey
    syntax varname(string), GENerate(name)
    quietly {
        tempvar b
        generate str100 `b' = upper(trim(`varlist'))
        * Panel names carry qualifiers the City file never uses.
        replace `b' = ustrregexra(`b', "\(.*\)", " ")
        replace `b' = subinstr(`b', "/", " ", .)
        replace `b' = ustrregexra(`b', "[^A-Z0-9]", "")
        replace `b' = subinstr(`b', "THE", "", .)
        generate str100 `generate' = `b'
    }
end

* --- coordinate lookup from the sound-ordinance permits --------------------
import delimited using "${EV_VENUE}/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv", ///
    clear varnames(1) encoding("utf-8") bindquotes(strict) stringcols(_all)
destring latitude longitude, replace force
keep if inrange(latitude, 29.9, 30.8) & inrange(longitude, -98.3, -97.3)
addrkey street_address, generate(akey)
namekey folder_name, generate(nkey)
quietly count
display as text "  geocoded sound-ordinance permit rows usable: " r(N)

preserve
    keep if akey != ""
    collapse (mean) lat_a = latitude lon_a = longitude (count) n_a = longitude, by(akey)
    tempfile geoaddr
    save `geoaddr'
restore
keep if nkey != ""
collapse (mean) lat_n = latitude lon_n = longitude (count) n_n = longitude, by(nkey)
tempfile geoname
save `geoname'

* --- venue attributes for the map ------------------------------------------
use `venuemonth', clear
keep if inlist(year, 2019, 2025)
collapse (sum) receipts_real2025, by(venue_key year)
reshape wide receipts_real2025, i(venue_key) j(year)
rename receipts_real20252019 real2019
rename receipts_real20252025 real2025
foreach v in real2019 real2025 {
    replace `v' = 0 if missing(`v')
}
tempfile v1925
save `v1925'

use `venuemonth', clear
collapse (firstnm) venue_name district tier location_address (max) lastym = ym, by(venue_key)
merge 1:1 venue_key using `v1925', nogenerate
generate byte stopped = (lastym < ym(2026,6))
addrkey location_address, generate(akey)
namekey venue_name,       generate(nkey)

merge m:1 akey using `geoaddr', keep(master match) nogenerate
merge m:1 nkey using `geoname', keep(master match) nogenerate
generate double lat = lat_a
generate double lon = lon_a
generate str12 geosrc = "address"
replace lat = lat_n if missing(lat) & !missing(lat_n)
replace lon = lon_n if missing(lon) & !missing(lon_n)
replace geosrc = "name" if geosrc == "address" & missing(lat_a) & !missing(lat_n)
replace geosrc = "none" if missing(lat)

quietly count
local nvenue_all = r(N)
quietly count if !missing(lat)
local nvenue_geo = r(N)
quietly count if geosrc == "address"
local ngeo_addr = r(N)
quietly count if geosrc == "name"
local ngeo_name = r(N)
display as text "  venues geocoded: `nvenue_geo' of `nvenue_all' (`ngeo_addr' by address, `ngeo_name' by name)"

generate double pctchg = 100 * (real2025 / real2019 - 1) if real2019 > 0
generate byte changecat = .
replace changecat = 1 if real2019 > 0 & real2025 == 0            // stopped filing
replace changecat = 2 if real2019 > 0 & pctchg <  -25 & real2025 > 0
replace changecat = 3 if real2019 > 0 & inrange(pctchg, -25, 10)
replace changecat = 4 if real2019 > 0 & pctchg > 10 & !missing(pctchg)
replace changecat = 5 if real2019 == 0                            // opened after 2019
label define chg 1 "Stopped filing by 2025" 2 "Real receipts down >25%" ///
                 3 "Roughly flat (-25% to +10%)" 4 "Real receipts up >10%" ///
                 5 "Opened after 2019"
label values changecat chg
tabulate changecat, missing

* The venue-level file behind both panels below. Coordinates stay in it: they
* are still the evidence for how concentrated the panel is, they feed the
* Moody-distance design in 70_quasi_experiments.do, and a reader who wants the
* map can build it from this file.
export delimited venue_key venue_name district tier lat lon geosrc ///
    real2019 real2025 pctchg changecat stopped ///
    using "${OUT}/fig10_venue_map.csv", replace

tempfile venuechange
save `venuechange'

preserve
keep if !missing(lat)
* Retained diagnostic, not a plotting step. venue_map_offframe is a registered
* number the report quotes: how many geocoded venues sat outside the 2nd-to-98th
* percentile box the earlier map versions were framed on.
quietly centile lon, centile(2 98)
local x0 = r(c_1) - 0.015
local x1 = r(c_2) + 0.015
quietly centile lat, centile(2 98)
local y0 = r(c_1) - 0.012
local y1 = r(c_2) + 0.012

local midlat = (`y0' + `y1') / 2
local coslat = cos(`midlat' * _pi / 180)
local wid = (`x1' - `x0') * `coslat'
local hei = (`y1' - `y0')
if `wid' < `hei' * 1.35 {
    local need = (`hei' * 1.35 / `coslat') - (`x1' - `x0')
    local x0 = `x0' - `need' / 2
    local x1 = `x1' + `need' / 2
}

quietly count if !inrange(lon, `x0', `x1') | !inrange(lat, `y0', `y1')
local n_offframe = r(N)
* Half the geocoded venues fall inside roughly one square kilometre of downtown
* and Red River. That is the concentration figure 10 used to try to draw.
quietly centile lon, centile(25 75)
local iqrlon = (r(c_2) - r(c_1)) * 111.32 * `coslat'
quietly centile lat, centile(25 75)
local iqrlat = (r(c_2) - r(c_1)) * 110.57
display as text "  venue coordinate box: lon `x0' to `x1', lat `y0' to `y1'"
display as text "  venues outside that box: `n_offframe'"
display as text "  middle half of geocoded venues span " %4.2f `iqrlon' " km east-west by " %4.2f `iqrlat' " km north-south"
numadd, key(venue_map_offframe) value("`n_offframe'") ///
    formatted("`n_offframe'") unit("venues") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Geocoded panel venues falling outside the 2nd-98th percentile box of venue coordinates. Kept as a concentration diagnostic: the middle half of the geocoded venues sit inside about one square kilometre of downtown and Red River, which is why a point map of this panel cannot be read at print size and figure 10 is drawn as bars instead.")
restore

* --- the two panels --------------------------------------------------------
* Denominator is the 79 panel venues with positive real receipts in 2019, the
* same set behind venue_shrank_n. A venue that stopped filing counts as zero in
* 2025 and therefore counts as shrinking, which is the intended treatment and
* is stated in that registry note.
use `venuechange', clear
generate byte filed2019 = (real2019 > 0) & !missing(real2019)
generate byte shrank    = filed2019 & (real2025 < real2019)
generate double lossusd = real2019 - real2025 if filed2019

* Venue names carry ASCII apostrophes (Maggie Mae's, Stubb's). Any of those
* inside a local macro breaks macro expansion, and the axis labels below are
* built through locals, so swap in the typographic right single quote first.
replace venue_name = subinstr(venue_name, char(39), uchar(8217), .)

keep if filed2019
quietly count
local n_f19 = r(N)
quietly count if shrank
local n_shr = r(N)
display as text "  figure 10: `n_shr' of `n_f19' venues filing in 2019 had lower real receipts in 2025"

* Districts with fewer than three venues filing in 2019 are pooled. A row built
* on one or two venues is noise, and eleven single-venue rows would crowd out
* the parts of Austin the figure is about.
generate str40 dgrp = district
bysort district: generate int ndist = _N
replace dgrp = "Elsewhere in Austin" if ndist < 3
replace dgrp = "Red River district"   if dgrp == "Red River Cultural District"
replace dgrp = "Downtown, 6th Street" if dgrp == "Downtown/6th"

preserve
    collapse (sum) nshrank = shrank (count) nfiled = filed2019, by(dgrp)
    generate byte iselse = (dgrp == "Elsewhere in Austin")
    gsort iselse -nshrank -nfiled
    generate byte ordd = _n
    quietly count
    local nrows = r(N)
    quietly summarize nshrank, meanonly
    assert r(sum) == `n_shr'
    label define ordlbl 1 "placeholder", replace
    forvalues i = 1/`nrows' {
        local dn = dgrp[`i']
        local a  = nshrank[`i']
        local b  = nfiled[`i']
        label define ordlbl `i' "`dn'  (`a' of `b')", modify
    }
    label values ordd ordlbl
    list ordd dgrp nshrank nfiled, noobs sep(0)
    export delimited dgrp nshrank nfiled using "${OUT}/fig10_venue_change_by_district.csv", replace

    graph hbar (asis) nshrank, over(ordd, sort(ordd) label(labsize(2.5))) ///
        bar(1, color("${ORANGE}")) ///
        blabel(bar, format(%3.0f) size(2.5) color("${TEXTC}")) ///
        ytitle("Venues with lower real receipts", $YTOPT) ///
        ylabel(0(2)14, angle(horizontal) labsize(2.5)) ///
        yscale(range(0 15)) legend(off) ///
        graphregion(color(white)) name(g10a, replace) nodraw
restore

preserve
    keep if lossusd > 0 & !missing(lossusd)
    gsort -lossusd
    keep in 1/10
    generate double lossm = lossusd / 1e6
    generate byte ordv = _n
    label define ordvlbl 1 "placeholder", replace
    forvalues i = 1/10 {
        local vn = venue_name[`i']
        label define ordvlbl `i' "`vn'", modify
    }
    label values ordv ordvlbl
    list ordv venue_name district lossm pctchg, noobs sep(0) abbreviate(20)
    export delimited venue_name district real2019 real2025 lossm pctchg ///
        using "${OUT}/fig10_venue_largest_declines.csv", replace

    graph hbar (asis) lossm, over(ordv, sort(ordv) label(labsize(2.5))) ///
        bar(1, color("${NAVY}")) ///
        blabel(bar, format(%4.1f) size(2.5) color("${TEXTC}")) ///
        ytitle("Real receipts lost, millions of 2025 dollars", $YTOPT) ///
        ylabel(0(1)6, angle(horizontal) labsize(2.5)) ///
        yscale(range(0 6.6)) legend(off) ///
        graphregion(color(white)) name(g10b, replace) nodraw
restore

graph combine g10a g10b, cols(2) imargin(0 2 0 0) graphregion(color(white)) ///
    ysize(5.6) xsize(9.4) ///
    title("Real receipts fell at `n_shr' of the `n_f19' tracked venues that filed in 2019", $TITLEOPT) ///
    subtitle("Left: by part of Austin; each row gives the number that shrank of the number filing." ///
             "Right: the ten largest declines in real receipts, millions of 2025 dollars.", $SUBOPT) ///
    name(fig10, replace)
figsave, name(fig10_venue_map)

numadd, key(venue_map_geocoded) value("`nvenue_geo'") formatted("`nvenue_geo' of `nvenue_all'") ///
    unit("count") source("01_evidence/08_venues_ecosystem/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv") ///
    note("Panel venues carrying a coordinate. From the City of Austin geocoded sound-ordinance permit file, matched on a normalised street address (`ngeo_addr') then on a normalised venue name (`ngeo_name'). Venues never permitted for amplified sound have no coordinate. This coverage is one reason figure 10 is drawn as bars rather than as a point map: fewer than half the panel could be placed and coloured. The coordinates are still used by the Moody Center distance design in 70_quasi_experiments.do. The address field in venue_timeline.csv was not used; the evidence memo flags it as unreliable.")


* ===========================================================================
* 9b. FIGURE 10b - OUTDOOR MUSIC VENUE PERMITS BY COUNCIL DISTRICT
* ===========================================================================
* The one genuine map in this report. It works where the venue point map did
* not, because the unit is an area rather than an overplotted dot: ten polygons
* covering the whole city, each with one number attached.
*
* UNIVERSE. Outdoor Music Venue sub-type rows in the City of Austin geocoded
* sound-ordinance permit file, restricted to 2009-2018. That file carries only
* 13 rows for 2019 against the 99 the City's own by-year count reports, so 2019
* is a partial extract and is left out rather than mapped as a real year. For
* 2009-2018 the two sources agree exactly, year by year, which is the check
* that the geocoded extract is the same series figure 11 plots.
*
* A permit is issued per venue per year, so a room that ran outdoor music for a
* decade contributes ten permits. This counts permitted outdoor operations over
* the decade, not distinct rooms; the subtitle says so.

capture confirm file "${OUT}/geo_cd_xy.dta"
if _rc != 0 {
    shp2dta using "${DATAX}/geo/austin_council_districts.shp", ///
        database("${OUT}/geo_cd_db") coordinates("${OUT}/geo_cd_xy") ///
        genid(cdid) replace
}

import delimited using "${EV_VENUE}/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv", ///
    clear varnames(1) encoding("utf-8") bindquotes(strict) stringcols(_all)
keep if strpos(sub_type, "Outdoor Music") > 0
destring calendar_year_folder_created, generate(permit_year) force
keep if inrange(permit_year, 2009, 2018)
destring council_district, generate(cdnum) force
quietly count if missing(cdnum)
assert r(N) == 0
contract cdnum
rename _freq permits
tempfile cdcount
save `cdcount'

use "${OUT}/geo_cd_db", clear
generate int cdnum = round(district_n)
merge 1:1 cdnum using `cdcount', nogenerate
assert !missing(permits)
quietly count
local n_cd = r(N)
assert `n_cd' == 10
quietly summarize permits, meanonly
local omvgeo_tot = r(sum)
quietly summarize permits if cdnum == 9, meanonly
local omvgeo_d9 = r(mean)
local omvgeo_d9sh = 100 * `omvgeo_d9' / `omvgeo_tot'
display as text "  OMV permits 2009-2018: `omvgeo_tot'; District 9 `omvgeo_d9' = " %4.1f `omvgeo_d9sh' "%"
gsort -permits
list cdnum permits, noobs sep(0)

* Label anchor: the mean vertex of each district's LARGEST part. Averaging every
* vertex of every part puts District 5, a long strip with seven small outliers,
* onto its own boundary. Checked: this anchor falls inside the district for all
* ten. An area centroid does not; District 2 is concave enough to push it out.
preserve
    use "${OUT}/geo_cd_xy", clear
    generate long rowid = _n
    generate byte brk = missing(_X)
    bysort _ID (rowid): generate int part = sum(brk)
    drop if missing(_X)
    bysort _ID part: generate long nv = _N
    bysort _ID: egen long maxnv = max(nv)
    keep if nv == maxnv
    collapse (mean) cx = _X cy = _Y, by(_ID)
    rename _ID cdid
    tempfile cdcent
    save `cdcent'
restore
merge 1:1 cdid using `cdcent', nogenerate
generate str3 dlab = string(cdnum)

sort cdnum
export delimited cdnum permits using "${OUT}/fig10b_district_map.csv", replace

* District numerals go in through twoway text() rather than spmap's own label()
* option, so each one can carry a white halo. spmap accepts only one label()
* and gives it a single colour, which leaves a white numeral half lost against
* the white district boundary wherever the polygon is narrow.
local cdtxt ""
forvalues i = 1/10 {
    local ty = cy[`i']
    local tx = cx[`i']
    local tl = dlab[`i']
    local cdtxt `"`cdtxt' text(`ty' `tx' "`tl'", size(3.2) color("${TEXTC}") placement(c) box fcolor(white) lcolor(none) margin(l=0.7 r=0.7 t=0.1 b=0.1))"'
}

* Sequential single hue, light to the report navy, so the ramp survives a
* monochrome print. Class breaks are set by hand because the distribution is
* extremely skewed and quantile or equal-interval breaks put nine districts in
* one class.
sort cdid
spmap permits using "${OUT}/geo_cd_xy.dta", id(cdid) ///
    clmethod(custom) clbreaks(0 5 20 50 150 `omvgeo_d9') ///
    fcolor("232 237 244" "186 199 219" "133 156 193" "74 104 155" "27 45 85") ///
    ocolor(white white white white white) ///
    osize(medthin medthin medthin medthin medthin) ///
    legstyle(2) legjunction(" to ") legorder(hilo) ///
    legend(pos(11) ring(0) size(2.6) region(lstyle(none)) symxsize(4) symysize(3) rowgap(0.5)) ///
    legtitle("Permits issued") ///
    `cdtxt' ///
    title("Three in four Austin outdoor music venue permits sit in District 9", $TITLEOPT) ///
    subtitle("City of Austin Outdoor Music Venue sound permits issued 2009-2018, by council district." ///
             "District 9 has `omvgeo_d9' of the 1,029. All ten districts shown; annual renewals count separately.", $SUBOPT) ///
    graphregion(color(white)) ysize(6.6) xsize(8.4) ///
    name(fig10b, replace)
figsave, name(fig10b_district_map)

local srcSOP "01_evidence/08_venues_ecosystem/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv"
local f : display %8.0fc `omvgeo_tot'
numadd, key(venue_omv_permits_geo_2009_2018) value("`omvgeo_tot'") ///
    formatted("`=trim("`f'")' permits") unit("count") source("`srcSOP'") ///
    note("Outdoor Music Venue sound permits in the City of Austin geocoded sound-ordinance permit file, calendar 2009 through 2018. Restricted to complete years: the geocoded file holds only 13 rows for 2019 against the 99 the City by-year count reports, so 2019 is a partial extract. For 2009-2018 the two sources agree exactly year by year, which confirms the geocoded extract is the same series as venue_omv_peak.")
local f : display %4.1f `omvgeo_d9sh'
numadd, key(venue_omv_permits_district9_share) value("`omvgeo_d9sh'") ///
    formatted("`=trim("`f'")'%") unit("percent of permits") source("`srcSOP'") ///
    note("District 9, which covers downtown, Red River and the University area, holds `omvgeo_d9' of the `omvgeo_tot' Outdoor Music Venue permits issued 2009-2018. All ten council districts appear in the file, so this share is bounded by the full city. Permits are issued per venue per year, so a long-running room contributes one permit a year; this is not a count of distinct rooms.")


* ===========================================================================
* 10. FIGURE 11 - SUPPLY
* ===========================================================================
import delimited using "${EV_VENUE}/austin_outdoor_music_venue_permits_by_year.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve)
rename calendar_year yearx
merge 1:1 yearx using `netadds', keep(master match) nogenerate
generate byte partial = (coverage != "full_year")

quietly summarize omv_permits if !partial, meanonly
local omvpeak = r(max)
quietly summarize yearx if omv_permits == `omvpeak' & !partial, meanonly
local omvpeakyr1 = r(min)
local omvpeakyr2 = r(max)
quietly summarize omv_permits if yearx == 2025, meanonly
local omv25 = r(mean)
quietly summarize omv_permits if yearx == 2019, meanonly
local omv19 = r(mean)
local omvdrop = 100 * (`omv25' / `omvpeak' - 1)

export delimited yearx omv_permits distinct_venue_names entries exits netadds coverage ///
    using "${OUT}/fig11_venue_supply.csv", replace

* THE TWO AXES ARE PINNED TO A COMMON ZERO. Left runs -37.5 to 150 and right
* runs -4 to 16, so zero sits one fifth of the way up on both and the orange
* line crosses the bar baseline exactly where net adds turn negative. With the
* earlier ranges the right-hand zero landed at about 50 on the permits axis, so
* the line read as if it were tracking bar heights. The bottom axis line is
* switched off and the bars rest on the shared zero line instead, which is why
* the left axis carries no labels below zero.
twoway ///
  (bar omv_permits yearx if !partial, barwidth(0.7) color("${NAVY}%75") lcolor("${NAVY}") lwidth(vthin) yaxis(1)) ///
  (bar omv_permits yearx if  partial, barwidth(0.7) color(none) lcolor("${NAVY}%75") lwidth(medthin) lpattern(dash) yaxis(1)) ///
  (connected netadds yearx, lcolor("${ORANGE}") lwidth(medthick) ///
        mcolor("${ORANGE}") msymbol(O) msize(small) mlcolor(white) mlwidth(vthin) yaxis(2)) ///
  , yline(0, axis(2) lcolor("${MUTED}") lwidth(thin) lpattern(solid)) ///
    ytitle("Outdoor music venue permits issued", axis(1) $YTOPT) ///
    ylabel(0(25)150, axis(1) angle(0) labsize(2.8)) ///
    yscale(range(-37.5 150) axis(1)) ///
    ytitle("Net venue entries minus exits", axis(2) color("${ORANGE}") $YTOPT) ///
    ylabel(-4(4)16, axis(2) angle(0) labcolor("${ORANGE}") labsize(2.8)) ///
    yscale(range(-4 16) axis(2)) ///
    xtitle("") xlabel(2009(2)2025, labsize(2.8)) xscale(range(2008.3 2027.4) noline) ///
    text(139 2014 "peak", color("${NAVY}") size(2.5) placement(n)) ///
    text(139 2017 "peak", color("${NAVY}") size(2.5) placement(n)) ///
    text(118 2025.7 "2026 is" "Jan-Jul only", color("${MUTED}") size(2.4) ///
         placement(n) justification(center) ///
         box fcolor(white) lcolor(none) margin(l=0.6 r=0.6 t=0.4 b=0.4)) ///
    legend(order(1 "Outdoor music venue permits issued (left)" ///
                 2 "2026, Jan-Jul only" ///
                 3 "Net venue entries minus exits, tracked panel (right)") ///
           cols(1) position(6) size(2.7) region(lstyle(none)) symxsize(6)) ///
    title("Outdoor music venue permits are a third below Austin's 2014 and 2017 peak", $TITLEOPT) ///
    subtitle("City of Austin outdoor music venue permits issued per calendar year, with net entries" ///
             "minus exits in the 114-venue receipts panel on the right axis, 2009-2026.", $SUBOPT) ///
    graphregion(color(white)) ysize(5.6) xsize(8.6) ///
    name(fig11, replace)
figsave, name(fig11_venue_supply)

local srcOMV "01_evidence/08_venues_ecosystem/austin_outdoor_music_venue_permits_by_year.csv"
numadd, key(venue_omv_peak) value("`omvpeak'") formatted("`omvpeak' permits") unit("count") ///
    source("`srcOMV'") ///
    note("Peak annual count of City of Austin Outdoor Music Venue permits, reached in both `omvpeakyr1' and `omvpeakyr2'. A City administrative series, independent of the Comptroller receipts data, and it moves the same direction.")
numadd, key(venue_omv_2025) value("`omv25'") formatted("`omv25' permits") unit("count") ///
    source("`srcOMV'") note("Outdoor Music Venue permits issued in calendar 2025. 2026 is partial (Jan-Jul) and is not compared to a full year.")
local f : display %6.1f `omvdrop'
numadd, key(venue_omv_pct_from_peak) value("`omvdrop'") formatted("`=trim("`f'")'%") ///
    unit("percent change") source("`srcOMV'") ///
    note("Change in Outdoor Music Venue permits from the `omvpeakyr1'/`omvpeakyr2' peak to 2025. Permits are issued per venue per year, so this counts permitted outdoor operations, not stages.")

* Cover charge is deliberately never plotted. Registered so the omission reads
* as a decision rather than an oversight.
use `venuemonth', clear
quietly summarize cover_nominal if year == 2019, meanonly
local cov19 = r(sum)
quietly summarize cover_nominal if year == 2024, meanonly
local cov24 = r(sum)
local f19 : display %12.0fc `cov19'
local f24 : display %12.0fc `cov24'
numadd, key(venue_cover_charge_unusable) value("`cov19'") ///
    formatted("\$`=trim("`f19'")' in 2019 vs \$`=trim("`f24'")' in 2024") ///
    unit("nominal dollars") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Cover charge reported across the whole panel. The jump is a reporting-compliance change around 2022, not growth in ticketed shows, so cover_charge_receipts is not plotted as a trend anywhere in this report and no ticketing conclusion rests on it.")

display as text "30_venues.do complete"
