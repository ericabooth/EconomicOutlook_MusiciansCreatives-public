*! 70_quasi_experiments.do - What do Austin venue receipts do around four known
*!                           shocks? Federal shuttered-venue relief, the 2017
*!                           Red River extended-hours pilot, the city Live Music
*!                           Fund venue grants, and the Moody Center opening.
*!
*! FRAMING, WHICH MATTERS AS MUCH AS THE ESTIMATES
*!   Nothing in this module is a causal estimate of a program. Every design here
*!   isolates the pattern around a dated shock so it can be triangulated against
*!   the descriptive evidence in 30_venues.do. Selection into treatment is
*!   severe and is documented design by design:
*!     - SVOG eligibility REQUIRED a documented revenue drop, so recipients are
*!       selected on shock severity by construction.
*!     - Live Music Fund venue grants are competitively scored.
*!     - The five Red River pilot venues were named, not drawn.
*!     - Distance from an arena is not random.
*!   Read every coefficient below as a conditional association and every figure
*!   as a descriptive event study.
*!
*! Inputs  : 01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv
*!           01_evidence/08_venues_ecosystem/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv
*!           01_evidence/07_svog_federal_relief/svog_awards_AUSTIN_AREA.csv
*!           01_evidence/04_city_programs_lmf/_txt/LMF_FY24_awardee_list.txt
*!           01_evidence/04_city_programs_lmf/_txt/LMF_FY26_awardee_list.txt
*!           03_analysis/out/cpi_annual.dta                     (built by _setup.do)
*!
*! Outputs : 04_figures/fig22_svog_event_study.png    (+ out/fig22_svog_event_study.csv)
*!           04_figures/fig23_redriver_did.png        (+ out/fig23_redriver_did.csv)
*!           04_figures/fig24_lmf_venue_grants.png    (+ out/fig24_lmf_venue_grants.csv)
*!           03_analysis/out/tables/svog_venue_crosswalk.csv
*!           03_analysis/out/tables/lmf_venue_crosswalk.csv
*!           03_analysis/out/tables/table_svog_event_study.csv
*!           03_analysis/out/tables/table_redriver_did.csv
*!           03_analysis/out/tables/table_lmf_venue_grants.csv
*!           03_analysis/out/tables/table_moody_distance.csv
*!           03_analysis/out/numbers/numbers_quasi.csv
*!
*! NOTE ON PUNCTUATION. Prose in this file uses the typographic right single
*! quote, never the ASCII apostrophe. An ASCII apostrophe inside a local macro
*! or inside text that Stata re-tokenises silently breaks macro expansion.

clear all
do "_setup.do"                    // run from 03_analysis/stata/
global CURMODULE "quasi"
numinit

set seed 20260802

* Permutation draws. Randomization inference is the PRIMARY inference for the
* Red River pilot, which has five treated units, and a secondary check for the
* Live Music Fund.
global RI_RR  5000
global RI_LMF 2000

* Fail early and legibly on a missing input. requirefile in _setup.do parses its
* argument with syntax, which strips the quotes, so a path containing a space
* fails there. The project root on this machine sits under "My Drive".
foreach f in "${EV_VENUE}/venue_monthly_receipts_long.csv" ///
             "${EV_VENUE}/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv" ///
             "${EV_SVOG}/svog_awards_AUSTIN_AREA.csv" ///
             "${EV_CITY}/_txt/LMF_FY24_awardee_list.txt" ///
             "${EV_CITY}/_txt/LMF_FY26_awardee_list.txt" ///
             "${OUT}/cpi_annual.dta" {
    capture confirm file "`f'"
    if _rc != 0 {
        display as error "Required input not found: `f'"
        exit 601
    }
}


* ===========================================================================
* 0. HELPERS
* ===========================================================================
* Address and name normalisers, carried over from 30_venues.do so the two
* modules resolve the same string to the same key. Two additions here: STATE is
* dropped alongside HIGHWAY, because the Comptroller writes Poodie’s as
* "22308 STATE HIGHWAY 71 W" while the federal award file writes
* "22308 Highway 71 W"; and BUILDING joins the suite-tail list.

capture program drop addrkey
program define addrkey
    syntax varname(string), GENerate(name)
    quietly {
        tempvar a hnum rest
        generate str100 `a' = upper(itrim(trim(`varlist')))
        replace `a' = ustrregexra(`a', " (STE|SUITE|UNIT|APT|BLDG|BUILDING|FL|FLOOR|#).*$", "")
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
        foreach t in WAY PKWY PARKWAY HWY HIGHWAY STATE CIR CT TRL LOOP EXPY FWY PL PLZ {
            replace `rest' = itrim(trim(subinstr(" " + `rest' + " ", " `t' ", " ", .)))
        }
        generate str100 `generate' = `hnum' + subinstr(`rest', " ", "", .)
        replace `generate' = "" if `hnum' == "" | `rest' == ""
    }
end

capture program drop namekey
program define namekey
    * Strip parentheticals, punctuation, the leading article and the trailing
    * legal-entity suffixes, so ANTONE-S NIGHTCLUB, INC. and Antone-s land on the
    * same key. Legal names and trading names differ throughout both the federal
    * award file and the city award lists.
    syntax varname(string), GENerate(name)
    quietly {
        tempvar b
        generate str244 `b' = upper(trim(`varlist'))
        replace `b' = ustrregexra(`b', "\(.*\)", " ")
        replace `b' = subinstr(`b', "/", " ", .)
        replace `b' = subinstr(`b', "&", " AND ", .)
        replace `b' = ustrregexra(`b', "[^A-Z0-9 ]", " ")
        replace `b' = itrim(trim(`b'))
        foreach t in LLC LLP LP LTD INC INCORPORATED CORP CORPORATION CO COMPANY {
            replace `b' = itrim(trim(ustrregexra(`b', " `t'$", " ")))
        }
        replace `b' = ustrregexra(`b', "[^A-Z0-9]", "")
        replace `b' = ustrregexra(`b', "^THE", "")
        generate str244 `generate' = `b'
    }
end

* Randomization inference: draw R sets of nt units without replacement from the
* pool held in the Stata matrix POOL, and leave them in the Mata external DR.
* Kept in Mata because rejection sampling several thousand draws in pure Stata
* is slow, and kept out of a Stata matrix so no matsize limit can bite.
capture mata: mata drop ridraws()
mata:
void ridraws(real scalar R, real scalar nt)
{
    external real matrix DR
    real matrix P
    real scalar r, np
    real colvector o
    P  = st_matrix("POOL")
    np = rows(P)
    DR = J(R, nt, .)
    for (r = 1; r <= R; r++) {
        o = order(runiform(np, 1), 1)
        DR[r, .] = P[o[1::nt], 1]'
    }
}
end


* ===========================================================================
* 1. THE VENUE PANEL, REBUILT IN 2025 DOLLARS
* ===========================================================================
* Two mandatory data-handling choices, both documented in
* 01_evidence/08_venues_ecosystem/_findings.md section J.
*
* (a) Festival aggregation. C3 Presents files Austin City Limits bar receipts
*     through concession LLCs permitted at a small venue address, so a $12.5M
*     month lands on Scoot Inn against a $38k median month. This module drops
*     every row carrying festival_spike_flag. That is a WIDER exclusion than
*     30_venues.do, which drops the ten rows carrying extreme_outlier_flag; the
*     flagged rows here are a superset of those ten. The wider rule is used
*     because a regression is far more sensitive to a mislabelled outlier than
*     an annual sum is, and because several of the extra rows sit inside the
*     estimation windows below.
*
* (b) Dollar base. The input carries total_receipts_real_2026_06usd, a June-2026
*     base. It is ignored. Real dollars are rebuilt from nominal receipts with
*     ${OUT}/cpi_annual.dta, the shared 2025 base every other module uses.
*     cpi_annual.dta holds only years with twelve published months, so there is
*     no 2026 deflator and every real series here ends 2025-12.

import delimited using "${EV_VENUE}/venue_monthly_receipts_long.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve) bindquotes(strict)

quietly count
local n_rows_raw = r(N)
quietly count if festival_spike_flag == 1
local n_fest = r(N)
quietly count if extreme_outlier_flag == 1
local n_extreme = r(N)
drop if festival_spike_flag == 1

generate int year = real(substr(obligation_month, 1, 4))
generate int mo   = real(substr(obligation_month, 6, 2))
generate int ym   = ym(year, mo)
format ym %tm

* A venue can hold several permit entities at once, so a venue-month is the sum
* across its permits.
collapse (sum) total_receipts ///
         (firstnm) venue_name district tier location_name location_address location_zip, ///
         by(venue_key year mo ym)
rename total_receipts receipts_nominal
isid venue_key ym

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) ///
    keepusing(defl) nogenerate
generate double receipts_real2025 = receipts_nominal * defl
label variable receipts_real2025 "Monthly mixed-beverage receipts, 2025 dollars"
quietly count if missing(defl) & year < 2026
assert r(N) == 0

generate double lnreal = ln(receipts_real2025) if receipts_real2025 > 0
label variable lnreal "Log real monthly receipts, 2025 dollars"
egen long vid = group(venue_key)
label variable vid "Venue identifier"

* Large ticketed rooms are held out of every estimation sample below. Three of
* the eight opened or reopened mid-window (Moody Center 2022, Moody Amphitheater
* 2022, The Concourse 2021), so they would enter a two-way fixed-effects model
* as entry rather than as a response to any shock studied here.
generate byte large_room = (tier == "large_venue")
label variable large_room "Large ticketed room, held out of estimation samples"

quietly levelsof venue_key, local(allvenues)
local n_venues : word count `allvenues'
quietly count
local n_venuemonths = r(N)
display as text "  panel: `n_venues' venues, `n_venuemonths' venue-months after the festival exclusion"

compress
tempfile panel
save `panel'

preserve
    contract venue_key venue_name district tier
    drop _freq
    duplicates drop venue_key, force
    isid venue_key
    tempfile venueattr
    save `venueattr'
restore

numadd, key(quasi_festival_rows_excluded) value("`n_fest'") ///
    formatted("`n_fest' permit-months") unit("count") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Rows carrying festival_spike_flag, dropped before every estimate in this module. Festival concession LLCs permitted at a venue address, almost certainly Austin City Limits bar receipts. This is a wider exclusion than 30_venues.do, which drops the `n_extreme' rows carrying extreme_outlier_flag; the wider rule is used because a regression is more sensitive to a mislabelled outlier than an annual sum is.")

numadd, key(quasi_panel_venue_months) value("`n_venuemonths'") ///
    formatted("`n_venuemonths' venue-months") unit("count") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Venue-months available to this module after collapsing `n_rows_raw' permit-months onto `n_venues' venues and dropping festival-flagged rows. Real-dollar series end 2025-12 because out/cpi_annual.dta carries no 2026 deflator.")


* ===========================================================================
* 2. COORDINATES FOR THE PANEL VENUES
* ===========================================================================
* Same source and same two-step match as figure 10 in 30_venues.do: the City of
* Austin geocoded sound-ordinance permit file, joined on a normalised street
* address and then on a normalised venue name. Venues never permitted for
* amplified sound have no coordinate and drop out of the distance design only.

import delimited using "${EV_VENUE}/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv", ///
    clear varnames(1) encoding("utf-8") bindquotes(strict) stringcols(_all)
destring latitude longitude, replace force
keep if inrange(latitude, 29.9, 30.8) & inrange(longitude, -98.3, -97.3)
addrkey street_address, generate(akey)
namekey folder_name,    generate(gnkey)

preserve
    keep if akey != ""
    collapse (mean) lat_a = latitude lon_a = longitude, by(akey)
    tempfile geoaddr
    save `geoaddr'
restore
keep if gnkey != ""
collapse (mean) lat_n = latitude lon_n = longitude, by(gnkey)
tempfile geoname
save `geoname'

use `panel', clear
collapse (firstnm) venue_name location_address, by(venue_key)
addrkey location_address, generate(akey)
namekey venue_name,       generate(gnkey)
merge m:1 akey  using `geoaddr', keep(master match) nogenerate
merge m:1 gnkey using `geoname', keep(master match) nogenerate
generate double lat = lat_a
generate double lon = lon_a
replace lat = lat_n if missing(lat) & !missing(lat_n)
replace lon = lon_n if missing(lon) & !missing(lon_n)
keep venue_key lat lon
quietly count if !missing(lat)
local n_geo = r(N)
display as text "  venues geocoded: `n_geo' of `n_venues'"
tempfile venuegeo
save `venuegeo'


* ===========================================================================
* 3. LOOKUP KEYS FOR AWARD MATCHING
* ===========================================================================
* Four key files, each mapping a normalised string to exactly one panel venue.
* Keys that resolve to more than one venue are dropped rather than guessed at,
* which is what forces the three shared addresses (606 E 7th, 900 Red River,
* 617 E 7th) down to the taxpayer-name step.

use `panel', clear
addrkey location_address, generate(akey)
keep if akey != ""
contract akey venue_key
drop _freq
bysort akey: generate byte naddr = _N
keep if naddr == 1
keep akey venue_key
rename venue_key vk_addr
tempfile keyaddr
save `keyaddr'

* Taxpayer names are not carried into the collapsed panel, so they are re-read
* from the source. A venue can hold several taxpayer entities over time and each
* one is a valid key.
import delimited using "${EV_VENUE}/venue_monthly_receipts_long.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve) bindquotes(strict)
namekey taxpayer_name, generate(tkey)
keep if tkey != ""
contract tkey venue_key
drop _freq
bysort tkey: generate byte ntax = _N
keep if ntax == 1
keep tkey venue_key
rename venue_key vk_tax
tempfile keytax
save `keytax'

use `panel', clear
namekey location_name, generate(lkey)
keep if lkey != ""
contract lkey venue_key
drop _freq
bysort lkey: generate byte nloc = _N
keep if nloc == 1
keep lkey venue_key
rename venue_key vk_loc
tempfile keyloc
save `keyloc'

use `panel', clear
namekey venue_name, generate(vnkey)
keep if vnkey != ""
contract vnkey venue_key
drop _freq
bysort vnkey: generate byte nvn = _N
keep if nvn == 1
keep vnkey venue_key
rename venue_key vk_vn
tempfile keyvn
save `keyvn'


* ===========================================================================
* 4. SVOG CROSSWALK: 152 FEDERAL AWARDS AGAINST 114 PANEL VENUES
* ===========================================================================
* Matching runs in a fixed priority order and every match was then read against
* the venue roster by hand:
*   1. normalised street address, when that address belongs to exactly one
*      panel venue
*   2. normalised legal name against the Comptroller taxpayer name, which is
*      what resolves the addresses shared by two panel venues and what catches
*      operators whose award address differs from their permit address
*   3. normalised legal name against the Comptroller trading name
*   4. a short hand-verified override block
* The crosswalk is written out with all 152 award rows, matched or not, so a
* reader can audit the misses as well as the hits.

import delimited using "${EV_SVOG}/svog_awards_AUSTIN_AREA.csv", ///
    clear varnames(1) encoding("utf-8") bindquotes(strict) case(preserve)
quietly count
local n_svog = r(N)
generate int awarded_dt = date(awarded_date, "YMD")
format awarded_dt %td
generate int award_ym = ym(year(awarded_dt), month(awarded_dt))
format award_ym %tm
* Zip arrives numeric from one file and string from the other, so both sides are
* forced to a trimmed string before they are ever compared.
capture confirm numeric variable zip
if _rc == 0 {
    generate str8 svog_zip = trim(string(zip, "%8.0f"))
}
else {
    generate str8 svog_zip = trim(zip)
}

addrkey address,        generate(akey)
namekey recipient_name, generate(rnkey)
generate str244 tkey = rnkey
generate str244 lkey = rnkey

merge m:1 akey using `keyaddr', keep(master match) nogenerate
merge m:1 tkey using `keytax',  keep(master match) nogenerate
merge m:1 lkey using `keyloc',  keep(master match) nogenerate

generate str32 venue_key    = ""
generate str32 match_method = "unmatched"
replace venue_key = vk_addr if venue_key == "" & !missing(vk_addr)
replace match_method = "address" if venue_key != "" & match_method == "unmatched"
replace venue_key = vk_tax  if venue_key == "" & !missing(vk_tax)
replace match_method = "taxpayer_name" if venue_key != "" & match_method == "unmatched"
replace venue_key = vk_loc  if venue_key == "" & !missing(vk_loc)
replace match_method = "trading_name" if venue_key != "" & match_method == "unmatched"

* Where the address and the legal name point at different panel venues the
* automated rule is not trusted. One award does this and it is handled below.
generate byte key_conflict = !missing(vk_addr) & !missing(vk_tax) & (vk_addr != vk_tax)
quietly count if key_conflict
local n_conflict = r(N)
display as text "  SVOG rows where address and legal name disagree: `n_conflict'"

generate byte uncertain_match = 0
generate str244 match_note = ""

* --- hand-verified overrides ----------------------------------------------
* Matching is keyed on the normalised legal name rather than the raw one, so no
* ASCII apostrophe ever enters a macro.
*
* The Parish. The legal name "The Parish Austin, LLC" is the Comptroller
* taxpayer for the 501 N IH-35 room; the address on the federal award, 214 E
* 6th, is the older Parish Room, whose permit stopped filing in 2017-12, four
* years before the award. The operating venue on the award date is the IH-35
* room, so the award is assigned there and flagged uncertain.
replace venue_key       = "parish_ih35"          if rnkey == "PARISHAUSTIN"
replace match_method    = "taxpayer_over_address" if rnkey == "PARISHAUSTIN"
replace uncertain_match = 1                       if rnkey == "PARISHAUSTIN"
replace match_note = "Award address is the former 214 E 6th room, which stopped filing 2017-12. Legal name is the taxpayer for the 501 N IH-35 room, which was the operating Parish on the award date." ///
    if rnkey == "PARISHAUSTIN"

* Austin Theatre Alliance operates both the Paramount and the Stateside, which
* are two separate permits and two separate rows in the panel. One award covers
* both, so attributing it to the Paramount alone overstates that venue.
replace uncertain_match = 1 if rnkey == "AUSTINTHEATREALLIANCE"
replace match_note = "One award covering both the Paramount and the Stateside, which file as two separate permits in the panel. Held out of the estimation sample." ///
    if rnkey == "AUSTINTHEATREALLIANCE"

* The Long Center grant went to the venue nonprofit; the mixed-beverage permit
* at that address is held by the food-service concessionaire, so the grantee and
* the entity whose receipts we observe are different legal persons.
replace uncertain_match = 1 if rnkey == "GREATERAUSTINPERFORMINGARTSCENTER"
replace match_note = "Grantee is the venue nonprofit. The mixed-beverage permit at 701 W Riverside is held by the food-service concessionaire, so grantee and permit holder differ." ///
    if rnkey == "GREATERAUSTINPERFORMINGARTSCENTER"

* BlancoNegro, LLC is the Comptroller taxpayer for The North Door, and the award
* name states the trading name outright. Neither key catches it: the award
* address writes IH where the permit writes INTERSTATE, and that address is
* shared by three panel venues in any case.
replace venue_key       = "northdoor"     if rnkey == "BLANCONEGROLLCDBATHENORTHDOOR"
replace match_method    = "dba_hand_verified" if rnkey == "BLANCONEGROLLCDBATHENORTHDOOR"
replace match_note = "Award names the trading name outright. The address key fails because the award writes 501 N IH 35 where the permit writes 501 N INTERSTATE 35, and that address is shared by three panel venues." ///
    if rnkey == "BLANCONEGROLLCDBATHENORTHDOOR"

* An award to a natural person at 22308 Highway 71 W. That is the Poodie’s
* address; the permit is held by Hilltop Bar and Grill, Inc., so only the street
* address ties them together.
replace match_note = "Recipient is a natural person. Only the street address ties the award to the permit, which is held by Hilltop Bar and Grill, Inc." ///
    if rnkey == "SHARONBURKE"

* Documented near-miss, deliberately left unmatched. Come And Take It
* Productions, LLC filed from a Kyle address; the venue of the same trading name
* already matches through Constant Saturday, LLC. Adding the promoter arm would
* inflate the award intensity for that venue on a guess.
replace match_note = "Promoter arm of the same trading name, filed from a Kyle address. Left unmatched on purpose; the venue itself matches through Constant Saturday, LLC." ///
    if rnkey == "COMEANDTAKEITPRODUCTIONS"

* --- zip agreement, reported not enforced ----------------------------------
preserve
    use `panel', clear
    contract venue_key location_zip
    bysort venue_key: keep if _n == 1
    rename location_zip panel_zip
    capture confirm numeric variable panel_zip
    if _rc == 0 {
        quietly tostring panel_zip, replace force
    }
    quietly replace panel_zip = trim(panel_zip)
    keep venue_key panel_zip
    tempfile zipx
    save `zipx'
restore
merge m:1 venue_key using `zipx', keep(master match) nogenerate
generate byte zip_agree = .
replace zip_agree = (svog_zip == panel_zip) if venue_key != ""
quietly count if venue_key != "" & zip_agree == 0
local n_zipdiff = r(N)
quietly count if venue_key != ""
local n_match = r(N)
display as text "  SVOG awards matched to a panel venue: `n_match' of `n_svog'"
display as text "  matched rows whose zip differs from the permit zip: `n_zipdiff'"

* --- write the crosswalk ---------------------------------------------------
preserve
    merge m:1 venue_key using `venueattr', keep(master match) nogenerate
    gsort -total_awarded_usd
    keep  recipient_name address city svog_zip entity_type total_awarded_usd ///
          awarded_date venue_key venue_name tier district match_method ///
          uncertain_match zip_agree key_conflict match_note
    order recipient_name address city svog_zip entity_type total_awarded_usd ///
          awarded_date venue_key venue_name tier district match_method ///
          uncertain_match zip_agree key_conflict match_note
    export delimited using "${TABDIR}/svog_venue_crosswalk.csv", replace
    display as text "  crosswalk -> out/tables/svog_venue_crosswalk.csv"
restore

* One row per venue. If a venue drew more than one matched award the dollars are
* summed and the earliest award month is used.
keep if venue_key != ""
keep venue_key total_awarded_usd award_ym uncertain_match
rename total_awarded_usd svog_usd
bysort venue_key: generate byte nawards = _N
quietly count if nawards > 1
local n_multi = r(N)
collapse (sum) svog_usd (min) award_ym (max) uncertain_match, by(venue_key)
isid venue_key
tempfile svogx
save `svogx'
display as text "  matched venues drawing more than one award: `n_multi'"

quietly count if uncertain_match == 0
local n_svog_use = r(N)
quietly summarize award_ym if uncertain_match == 0
local aw_lo = string(r(min), "%tmCCYY-NN")
local aw_hi = string(r(max), "%tmCCYY-NN")
quietly summarize svog_usd if uncertain_match == 0, detail
local sv_med = r(p50)
local sv_sum = r(sum)

local srcSV "01_evidence/07_svog_federal_relief/svog_awards_AUSTIN_AREA.csv"
numadd, key(quasi_svog_awards_total) value("`n_svog'") formatted("`n_svog' awards") ///
    unit("count") source("`srcSV'") ///
    note("Shuttered Venue Operators Grant awards in the Austin area. Recipients include cinemas, talent agencies, festivals, symphonies and theatres as well as bars holding a music permit, so most of them can never appear in a mixed-beverage receipts panel.")
numadd, key(quasi_svog_matched_venues) value("`n_match'") formatted("`n_match' of `n_svog'") ///
    unit("count") source("`srcSV'") ///
    note("SVOG awards matched to one of the `n_venues' venues in the curated receipts panel. Matched on normalised street address first, then the normalised legal name against the Comptroller taxpayer name, then against the Comptroller trading name, then five hand-verified overrides. Every match was read against the venue roster by hand. The full crosswalk, including the `=`n_svog'-`n_match'' unmatched awards, is at out/tables/svog_venue_crosswalk.csv.")
numadd, key(quasi_svog_used_venues) value("`n_svog_use'") formatted("`n_svog_use' venues") ///
    unit("count") source("`srcSV'") ///
    note("Matched venues carried into the event study. Three matches are flagged uncertain and held out of the sample entirely: the Paramount, where one award covers two separately permitted rooms; the Long Center, where the grantee is the nonprofit and the permit holder is the concessionaire; and The Parish, where the award address is the former room and the legal name is the current one.")
local f : display %14.0fc `sv_sum'
numadd, key(quasi_svog_dollars_matched) value("`sv_sum'") formatted("\textdollar{}`=trim("`f'")'") ///
    unit("nominal dollars") source("`srcSV'") ///
    note("Federal relief flowing to the `n_svog_use' panel venues used in the event study, as awarded. Award dollars are nominal and are not deflated; they are used only to scale treatment intensity against pre-pandemic revenue at the same venue.")
local f : display %12.0fc `sv_med'
numadd, key(quasi_svog_median_award) value("`sv_med'") formatted("\textdollar{}`=trim("`f'")'") ///
    unit("nominal dollars") source("`srcSV'") ///
    note("Median award among the `n_svog_use' panel venues used in the event study.")
numadd, key(quasi_svog_award_window) value("`aw_lo' to `aw_hi'") formatted("`aw_lo' to `aw_hi'") ///
    unit("award months") source("`srcSV'") ///
    note("Range of award months among the venues used. The awards are barely staggered: they all land inside a three-month window in 2021, so this is close to a single-cohort design and the relative-time axis is nearly a relabelling of calendar time.")


* ===========================================================================
* 5. DESIGN 1 - FEDERAL SHUTTERED-VENUE RELIEF, STAGGERED EVENT STUDY
* ===========================================================================
* Specification: log real monthly receipts on half-year blocks of time relative
* to the SVOG award month of that same venue, with venue and calendar-month
* effects, standard errors clustered by venue, and a comparison group of every
* other panel venue that never received a matched award.
*
* WHY THIS IS NOT A PROGRAM EVALUATION. SVOG eligibility required the applicant
* to document a revenue drop of at least 25 percent against the same quarter of
* 2019. Recipients are therefore selected on the severity of their own shock, by
* construction. The pre-award path is the selection rule made visible rather
* than a threat to identification that could be argued away, and it is plotted
* for exactly that reason.
*
* The omitted block is 30 to 25 months before the award, which for the typical
* award month of 2021-07 is the first half of 2019. The conventional base of the
* month before treatment would sit in the deepest part of the pandemic and would
* make every other coefficient unreadable.

use `panel', clear
merge m:1 venue_key using `svogx', keep(master match) nogenerate
generate byte svog = (!missing(award_ym) & uncertain_match == 0)
label variable svog "Matched SVOG recipient, certain matches only"

* Uncertain matches leave the sample entirely rather than sit in the comparison
* group, where they would contaminate it.
drop if !missing(award_ym) & uncertain_match == 1
drop if large_room
keep if inrange(ym, ym(2017,1), ym(2025,12))
keep if !missing(lnreal)

* Event time in half-year blocks, clipped at four and a half years before and
* four years after. The window starts 2017-01 so that the endpoint block is a
* genuine bin containing several months for every award cohort rather than one
* thin sliver of a month, which is what an unclipped endpoint produces.
generate int k  = ym - award_ym if svog
generate int hb = floor(k/6)
replace hb = -9 if svog & hb < -9
replace hb =  8 if svog & hb >  8
replace hb = -5 if !svog                  // base block; multiplied by svog = 0
generate int binid = hb + 9
label variable binid "Half-year block relative to the award, base = block -5"

quietly levelsof venue_key if svog, local(svglist)
local n_tr_svog : word count `svglist'
quietly levelsof venue_key if !svog, local(ctlist)
local n_ct_svog : word count `ctlist'
display as text "  SVOG design: `n_tr_svog' treated venues, `n_ct_svog' comparison venues"

* Treatment intensity: award dollars expressed in months of pre-pandemic
* revenue at the same venue. A venue with no 2019 receipts has no intensity and leaves that
* specification only.
preserve
    use `panel', clear
    keep if year == 2019 & receipts_real2025 > 0
    collapse (mean) base2019 = receipts_real2025, by(venue_key)
    tempfile b19
    save `b19'
restore
merge m:1 venue_key using `b19', keep(master match) nogenerate
generate double intens = svog_usd / base2019 if svog
replace intens = 0 if !svog
generate byte postaw = (k >= 0) if svog
replace postaw = 0 if !svog
generate double post_x_svog   = postaw * svog
generate double post_x_intens = postaw * intens
label variable post_x_svog   "Award month onward x SVOG recipient"
label variable post_x_intens "Award month onward x award in months of 2019 revenue"

quietly levelsof venue_key if svog & missing(intens), local(nointens)
local n_nointens : word count `nointens'
quietly summarize intens if svog & !missing(intens), detail
local int_med = r(p50)
display as text "  SVOG intensity: median award = " %5.1f `int_med' " months of 2019 revenue; `n_nointens' treated venue(s) have no 2019 base"

eststo clear

eststo svog1: reghdfe lnreal post_x_svog, absorb(vid ym) vce(cluster vid)
estadd local dsn "Pooled post-award"
estadd local samp "Panel venues, large rooms excluded"
local sv_did_b  = _b[post_x_svog]
local sv_did_se = _se[post_x_svog]
local sv_did_p  = 2 * ttail(e(df_r), abs(`sv_did_b'/`sv_did_se'))
local sv_did_n  = e(N)
local sv_did_u  = e(N_clust)

eststo svog2: reghdfe lnreal post_x_intens, absorb(vid ym) vce(cluster vid)
estadd local dsn "Pooled post-award, intensity"
estadd local samp "Panel venues, large rooms excluded"
local sv_int_b  = _b[post_x_intens]
local sv_int_se = _se[post_x_intens]
local sv_int_p  = 2 * ttail(e(df_r), abs(`sv_int_b'/`sv_int_se'))
local sv_int_n  = e(N)

* Event-study dummies are built by hand rather than with factor-variable
* notation. With ib3.binid#c.svog, reghdfe expands all seventeen levels and then
* drops one for collinearity, which silently renormalises the whole event study
* onto the last block instead of the intended base. Building the dummies and
* omitting block -5 explicitly leaves no room for that.
local esvars ""
local eivars ""
forvalues b = 0/17 {
    local hbv = `b' - 9
    quietly generate byte  es`b' = (binid == `b') * svog
    quietly generate double ei`b' = (binid == `b') * intens
    label variable es`b' "SVOG recipient x half-year block `hbv'"
    label variable ei`b' "Award months of 2019 revenue x half-year block `hbv'"
    if `b' != 4 {
        local esvars "`esvars' es`b'"
        local eivars "`eivars' ei`b'"
    }
}

eststo svog3: reghdfe lnreal `esvars', absorb(vid ym) vce(cluster vid)
estadd local dsn "Event study, half-year blocks"
estadd local samp "Panel venues, large rooms excluded"
local sv_es_n = e(N)
local sv_es_u = e(N_clust)

* Two pre-trend tests, built from the blocks that actually estimated. The first
* uses every pre-award block and is expected to fail, because it spans the 2020
* collapse that made these venues eligible. The second uses only blocks that
* close before 2020-01 for every award month in the data, and is the test of
* whether the two groups were on parallel paths BEFORE the shock.
local pre_all ""
local pre_pre ""
forvalues b = 0/8 {
    if `b' != 4 {
        capture local sse = _se[es`b']
        if _rc == 0 {
            if `sse' > 0 {
                local pre_all "`pre_all' es`b'"
                if `b' <= 3 local pre_pre "`pre_pre' es`b'"
            }
        }
    }
}
local sv_prea_F = .
local sv_prea_p = .
local sv_prec_F = .
local sv_prec_p = .
capture testparm `pre_all'
if _rc == 0 {
    local sv_prea_F = r(F)
    local sv_prea_p = r(p)
}
capture testparm `pre_pre'
if _rc == 0 {
    local sv_prec_F = r(F)
    local sv_prec_p = r(p)
}
display as text "  SVOG pre-award joint test, all pre blocks:        F = " %7.2f `sv_prea_F' ", p = " %6.4f `sv_prea_p'
display as text "  SVOG pre-pandemic joint test, blocks before 2020: F = " %7.2f `sv_prec_F' ", p = " %6.4f `sv_prec_p'

eststo svog4: reghdfe lnreal `eivars', absorb(vid ym) vce(cluster vid)
estadd local dsn "Event study, intensity"
estadd local samp "Panel venues, large rooms excluded"

* How far apart are the two groups once the recovery has run its course? The
* pooled coefficient above is hard to read because its pre-period contains the
* 2020 collapse. This one keeps only the pre-pandemic blocks and the blocks two
* or more years after the award, so it reads as the gap that remains.
generate byte latepost = (hb >= 4) if svog
replace latepost = 0 if !svog
generate double late_x_svog = latepost * svog
label variable late_x_svog "Two or more years after the award x SVOG recipient"
generate byte insample5 = !svog | (hb <= -5) | (hb >= 4)
eststo svog5: reghdfe lnreal late_x_svog if insample5, absorb(vid ym) vce(cluster vid)
estadd local dsn "Late post vs pre-pandemic only"
estadd local samp "Panel venues, large rooms excluded"
local sv_late_b  = _b[late_x_svog]
local sv_late_se = _se[late_x_svog]
local sv_late_p  = 2 * ttail(e(df_r), abs(`sv_late_b'/`sv_late_se'))
local sv_late_n  = e(N)

* Collect the level event study for the figure.
estimates restore svog3
tempname PES
tempfile svogES
postfile `PES' int hb double(b se lo hi) using `svogES', replace
forvalues bb = 0/17 {
    capture local bcoef = _b[es`bb']
    if _rc == 0 {
        local scoef = _se[es`bb']
        if `scoef' > 0 {
            post `PES' (`bb' - 9) (`bcoef') (`scoef') ///
                       (`bcoef' - 1.96*`scoef') (`bcoef' + 1.96*`scoef')
        }
    }
}
* The omitted block is a coefficient of exactly zero and belongs on the chart.
post `PES' (-5) (0) (0) (0) (0)
postclose `PES'

esttab svog1 svog5 svog2 svog3 svog4 using "${TABDIR}/table_svog_event_study.csv", replace ///
    csv se star(* 0.10 ** 0.05 *** 0.01) label b(4) se(4) ///
    scalars("dsn Specification" "samp Sample") ///
    title("Receipts around a federal shuttered-venue relief award, Austin panel venues") ///
    addnotes("Outcome is log real monthly receipts in 2025 dollars, 2017-01 to 2025-12." ///
             "Venue and calendar-month fixed effects; standard errors clustered by venue." ///
             "Event-study blocks are six months wide; the omitted block is 30 to 25 months before the award." ///
             "SVOG eligibility required a documented revenue drop, so recipients are selected on shock severity." ///
             "Descriptive event study. Not a causal estimate of the program.")
display as text "  table -> out/tables/table_svog_event_study.csv"

local f  : display %6.3f `sv_did_b'
local fs : display %6.3f `sv_did_se'
local fp : display %6.4f `sv_did_p'
numadd, key(quasi_svog_post_coef) value("`sv_did_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcSV'") ///
    note("reghdfe lnreal post_x_svog, absorb(venue month) vce(cluster venue). Sample: `n_tr_svog' matched SVOG venues against `n_ct_svog' other panel venues, 2017-01 to 2025-12, large ticketed rooms excluded, `sv_did_n' venue-months in `sv_did_u' clusters. Reads as the average gap in log real receipts from the award month onward, after venue and calendar-month effects. Clustered SE `=trim("`fs'")', p `=trim("`fp'")'. Conditional association only: SVOG eligibility required a documented revenue drop, so recipients are selected on the severity of their own shock.")
numadd, key(quasi_svog_post_se) value("`sv_did_se'") formatted("`=trim("`fs'")'") ///
    unit("log points, clustered SE") source("`srcSV'") ///
    note("Standard error on quasi_svog_post_coef, clustered by venue, `sv_did_u' clusters.")
numadd, key(quasi_svog_post_p) value("`sv_did_p'") formatted("`=trim("`fp'")'") ///
    unit("p-value") source("`srcSV'") note("Two-sided p-value for quasi_svog_post_coef.")

* The formatting macros are reset here on purpose. Every numadd below reads
* whichever f, fs and fp were set last, so a block inserted above a numadd that
* still needs the old values silently reformats it.
local f   : display %6.3f `sv_late_b'
local fs  : display %6.3f `sv_late_se'
local fp  : display %6.4f `sv_late_p'
local fpc : display %5.1f `=100*(exp(`sv_late_b')-1)'
numadd, key(quasi_svog_latepost_coef) value("`sv_late_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcSV'") ///
    note("The gap that remains once the recovery has run. Same fixed effects, but the sample keeps only the pre-pandemic blocks and the blocks two or more years after the award, so the pandemic collapse is out of both sides of the comparison. `sv_late_n' venue-months, clustered SE `=trim("`fs'")', p `=trim("`fp'")', approximately `=trim("`fpc'")' percent. This is the cleaner headline number, because the pooled coefficient quasi_svog_post_coef carries the 2020 collapse inside its own pre-period and is hard to read for that reason.")

local f  : display %7.4f `sv_int_b'
local fs : display %7.4f `sv_int_se'
local fp : display %6.4f `sv_int_p'
local fm : display %5.1f `int_med'
numadd, key(quasi_svog_intensity_coef) value("`sv_int_b'") formatted("`=trim("`f'")'") ///
    unit("log points per month of 2019 revenue") source("`srcSV'") ///
    note("reghdfe lnreal post_x_intens, absorb(venue month) vce(cluster venue). Intensity is the award divided by mean monthly real receipts at the same venue in 2019, so one unit is one month of pre-pandemic revenue. Median award among treated venues is `=trim("`fm'")' months of 2019 revenue. Clustered SE `=trim("`fs'")', p `=trim("`fp'")', `sv_int_n' venue-months. `n_nointens' treated venue has no 2019 base and leaves this specification.")
local f  : display %7.2f `sv_prea_F'
local fp : display %6.4f `sv_prea_p'
numadd, key(quasi_svog_pretrend_p_all) value("`sv_prea_p'") formatted("`=trim("`fp'")'") ///
    unit("p-value") source("`srcSV'") ///
    note("Joint test that every pre-award block coefficient is zero, F = `=trim("`f'")'. This test spans the 2020 collapse that made these venues eligible, so a rejection is the selection rule showing up rather than a specification failure that could be argued away.")
local f  : display %7.2f `sv_prec_F'
local fp : display %6.4f `sv_prec_p'
numadd, key(quasi_svog_pretrend_p_prepandemic) value("`sv_prec_p'") formatted("`=trim("`fp'")'") ///
    unit("p-value") source("`srcSV'") ///
    note("Joint test that the pre-pandemic block coefficients are zero, F = `=trim("`f'")'. These are the blocks that close before 2020-01 for every award month in the data. This is the test of whether recipients and non-recipients were on parallel paths before the shock, and it is the diagnostic that decides whether the design is reported as anything more than descriptive.")


* ===========================================================================
* 6. DESIGN 2 - RED RIVER EXTENDED-HOURS PILOT, 2017
* ===========================================================================
* Five named venues ran later outdoor music hours during the pilot: Stubb’s,
* Mohawk, Empire Control Room and Garage, Beerland, Cheer Up Charlies.
*
* A DATE DISCREPANCY THE REPORT SHOULD CARRY. The programme brief and the city
* programmes evidence memo both give the pilot as May to November 2017. The only
* primary document in hand, the Law Department draft ordinance amending Chapter
* 9-2, dated 2018-03-30, recites a different chronology: Ordinance 20170126-019
* created a six-month pilot and Ordinance 20171019-007 extended it to
* 2018-04-30. The evaluation memo behind the widely repeated claim of a 22
* percent rise in payments to local musicians was never located, so the
* May-to-November window may be the window the evaluation measured rather than
* the window the ordinance set. Both windows are estimated below.
*
* INFERENCE. Five treated units. Cluster-robust standard errors are unreliable
* with a treated group this small and will understate the true sampling
* variability, so randomization inference is the primary inference here and the
* clustered errors are reported only as a secondary reference.

use `panel', clear
drop if large_room
keep if inrange(ym, ym(2015,1), ym(2019,12))
keep if !missing(lnreal)

generate byte rr5 = inlist(venue_key, "stubbs", "mohawk", "empire", "beerland", "cheerup")
label variable rr5 "Named 2017 Red River extended-hours pilot venue"
generate byte rrdist = (district == "Red River Cultural District")
label variable rrdist "Venue sits in the Red River Cultural District"

generate byte pilot_a = inrange(ym, ym(2017,5), ym(2017,11))
generate byte pilot_b = inrange(ym, ym(2017,2), ym(2018,4))
label variable pilot_a "Pilot window as reported, 2017-05 to 2017-11"
label variable pilot_b "Pilot window per the ordinance record, 2017-02 to 2018-04"
generate byte d_a = rr5 * pilot_a
generate byte d_b = rr5 * pilot_b
label variable d_a "Pilot venue x reported pilot window"
label variable d_b "Pilot venue x ordinance pilot window"

quietly levelsof venue_key if rr5, local(rrnames)
local n_rr5 : word count `rrnames'
assert `n_rr5' == 5

* A venue enters the randomization-inference pool only if it files receipts in
* at least 54 of the 60 months in the window, so a placebo assignment lands on
* the same kind of unit as the real one. All five pilot venues clear that bar.
bysort venue_key: generate int nmon = _N
generate byte ripool = (nmon >= 54)
quietly levelsof venue_key if ripool & rr5, local(rrpool5)
local n_rr5pool : word count `rrpool5'
assert `n_rr5pool' == 5
preserve
    contract venue_key ripool rrdist tier
    quietly count if ripool
    local n_pool = r(N)
    quietly count if ripool & tier == "core_live_music"
    local n_pool_core = r(N)
    quietly count if ripool & rrdist
    local n_pool_rr = r(N)
restore
display as text "  Red River RI pool: `n_pool' venues, `n_pool_core' core live-music, `n_pool_rr' in the district"

eststo clear
eststo rr1: reghdfe lnreal d_a, absorb(vid ym) vce(cluster vid)
estadd local dsn "Reported window, all comparison venues"
estadd local samp "Panel venues 2015-2019, large rooms excluded"
local rr_b  = _b[d_a]
local rr_se = _se[d_a]
local rr_p  = 2 * ttail(e(df_r), abs(`rr_b'/`rr_se'))
local rr_n  = e(N)
local rr_u  = e(N_clust)

eststo rr2: reghdfe lnreal d_b, absorb(vid ym) vce(cluster vid)
estadd local dsn "Ordinance window, all comparison venues"
estadd local samp "Panel venues 2015-2019, large rooms excluded"
local rrb_b  = _b[d_b]
local rrb_se = _se[d_b]

eststo rr3: reghdfe lnreal d_a if rrdist, absorb(vid ym) vce(cluster vid)
estadd local dsn "Reported window, Red River comparison only"
estadd local samp "Red River Cultural District venues only"
local rrd_b  = _b[d_a]
local rrd_se = _se[d_a]
local rrd_n  = e(N)
local rrd_u  = e(N_clust)

* Half-year event study, to see whether anything moves at all. 2016H2 is the
* omitted block, the half-year before the earliest date the ordinance record
* allows.
generate int hy = 2 * (year - 2015) + (mo > 6)
label variable hy "Half-year index, 0 = 2015H1"
local hyvars ""
forvalues h = 0/9 {
    local hyr = 2015 + floor(`h'/2)
    local hhf = cond(mod(`h',2) == 0, "H1", "H2")
    quietly generate byte hyb`h' = (hy == `h') * rr5
    label variable hyb`h' "Pilot venue x `hyr'`hhf'"
    if `h' != 3 local hyvars "`hyvars' hyb`h'"
}
eststo rr4: reghdfe lnreal `hyvars', absorb(vid ym) vce(cluster vid)
estadd local dsn "Half-year event study, base 2016H2"
estadd local samp "Panel venues 2015-2019, large rooms excluded"
local rr_pre_F = .
local rr_pre_p = .
capture testparm hyb0 hyb1 hyb2
if _rc == 0 {
    local rr_pre_F = r(F)
    local rr_pre_p = r(p)
}
display as text "  Red River pre-pilot joint test, 2015H1 to 2016H1: F = " %7.2f `rr_pre_F' ", p = " %6.4f `rr_pre_p'

* WHAT THE PRE-PILOT TEST IS ACTUALLY PICKING UP. The half-year event study puts
* every first-half block above every second-half block for the pilot venues
* relative to the comparison group, in the pre-period as much as after. That is
* differential seasonality, not a trend: Red River rooms lean harder on the
* spring festival season than the rest of the panel does, and calendar-month
* fixed effects only remove the seasonality the two groups share. Venue-by-
* month-of-year effects remove the part they do not share, and the two
* specifications below repeat the difference-in-differences and the pre-pilot
* test with that added. This matters for the sign as well as the diagnostic: the
* reported pilot window runs May to November, six of its seven months in the
* second half, so an unadjusted estimate carries the seasonal deficit of the
* treated group as if it were a pilot effect.
eststo rr5: reghdfe lnreal d_a, absorb(vid ym vid#mo) vce(cluster vid)
estadd local dsn "Reported window, venue seasonality absorbed"
estadd local samp "Panel venues 2015-2019, large rooms excluded"
local rrs_b  = _b[d_a]
local rrs_se = _se[d_a]
local rrs_p  = 2 * ttail(e(df_r), abs(`rrs_b'/`rrs_se'))

eststo rr6: reghdfe lnreal `hyvars', absorb(vid ym vid#mo) vce(cluster vid)
estadd local dsn "Event study, venue seasonality absorbed"
estadd local samp "Panel venues 2015-2019, large rooms excluded"
local rrs_pre_F = .
local rrs_pre_p = .
capture testparm hyb0 hyb1 hyb2
if _rc == 0 {
    local rrs_pre_F = r(F)
    local rrs_pre_p = r(p)
}
display as text "  Red River pre-pilot joint test with venue seasonality absorbed: F = " %7.2f `rrs_pre_F' ", p = " %6.4f `rrs_pre_p'

* --- randomization inference ----------------------------------------------
* The treatment dates are held fixed and only the assignment is permuted. The
* exact p-value counts how often a placebo set of five venues produces a
* difference-in-differences coefficient at least as large in absolute value.
preserve
    contract venue_key vid ripool
    keep if ripool
    mkmat vid, matrix(POOL)
restore
local R = ${RI_RR}
mata: ridraws(`R', 5)

generate byte tsim = 0
generate byte dsim = 0
tempname RIRR
tempfile ridistRR
postfile `RIRR' double(bsim) using `ridistRR', replace
local nge = 0
quietly {
    forvalues r = 1/`R' {
        mata: st_local("picks", invtokens(strofreal(DR[`r', .])))
        replace tsim = 0
        foreach vv of local picks {
            replace tsim = 1 if vid == `vv'
        }
        replace dsim = tsim * pilot_a
        reghdfe lnreal dsim, absorb(vid ym)
        local bs = _b[dsim]
        post `RIRR' (`bs')
        if abs(`bs') >= abs(`rr_b') - 1e-12 {
            local nge = `nge' + 1
        }
    }
}
postclose `RIRR'
local rr_ri_p = (`nge' + 1) / (`R' + 1)
display as text "  Red River randomization inference: `nge' of `R' placebo draws at least as large; exact p = " %6.4f `rr_ri_p'

preserve
    use `ridistRR', clear
    quietly summarize bsim, detail
    local ri_sd  = r(sd)
    local ri_p5  = r(p5)
    local ri_p95 = r(p95)
restore
display as text "  placebo distribution: sd = " %6.4f `ri_sd' ", 5th to 95th percentile " %6.3f `ri_p5' " to " %6.3f `ri_p95'

* Second pool, core live-music rooms only, so the placebo venues are the same
* kind of business as the pilot venues.
preserve
    contract venue_key vid ripool tier
    keep if ripool & tier == "core_live_music"
    mkmat vid, matrix(POOL)
restore
mata: ridraws(`R', 5)
local nge2 = 0
quietly {
    forvalues r = 1/`R' {
        mata: st_local("picks", invtokens(strofreal(DR[`r', .])))
        replace tsim = 0
        foreach vv of local picks {
            replace tsim = 1 if vid == `vv'
        }
        replace dsim = tsim * pilot_a
        reghdfe lnreal dsim, absorb(vid ym)
        local bs = _b[dsim]
        if abs(`bs') >= abs(`rr_b') - 1e-12 {
            local nge2 = `nge2' + 1
        }
    }
}
local rr_ri_p2 = (`nge2' + 1) / (`R' + 1)
display as text "  Red River randomization inference, core live-music pool: exact p = " %6.4f `rr_ri_p2'

esttab rr1 rr2 rr3 rr4 rr5 rr6 using "${TABDIR}/table_redriver_did.csv", replace ///
    csv se star(* 0.10 ** 0.05 *** 0.01) label b(4) se(4) ///
    scalars("dsn Specification" "samp Sample") ///
    title("Receipts at the five Red River extended-hours pilot venues, 2015 to 2019") ///
    addnotes("Outcome is log real monthly receipts in 2025 dollars." ///
             "Venue and calendar-month fixed effects; standard errors clustered by venue." ///
             "Columns 5 and 6 add venue-by-month-of-year effects, which absorb differential seasonality." ///
             "Five treated units, so the clustered errors are unreliable and are secondary." ///
             "Primary inference is randomization inference over ${RI_RR} permutations of the five treated venues." ///
             "Descriptive event study. Venues were named into the pilot, not drawn.")
display as text "  table -> out/tables/table_redriver_did.csv"

local srcRR "01_evidence/04_city_programs_lmf/_txt/red_river_pilot_law_dept_2018_296553.txt with 01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv"
local f   : display %6.3f `rr_b'
local fs  : display %6.3f `rr_se'
local fp  : display %6.4f `rr_ri_p'
local fc  : display %6.4f `rr_p'
local fpc : display %5.1f `=100*(exp(`rr_b')-1)'
numadd, key(quasi_redriver_did_coef) value("`rr_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcRR'") ///
    note("reghdfe lnreal d_a, absorb(venue month) vce(cluster venue), where d_a is pilot venue times the 2017-05 to 2017-11 window. Sample: the 5 named pilot venues against the other panel venues, 2015-01 to 2019-12, large ticketed rooms excluded, `rr_n' venue-months in `rr_u' clusters. Point estimate `=trim("`fpc'")' percent. Randomization-inference exact p = `=trim("`fp'")' over ${RI_RR} permutations; clustered SE `=trim("`fs'")' with nominal p `=trim("`fc'")', reported only as a secondary reference because five treated units make cluster-robust inference unreliable.")
numadd, key(quasi_redriver_ri_p) value("`rr_ri_p'") formatted("`=trim("`fp'")'") ///
    unit("exact p-value") source("`srcRR'") ///
    note("Randomization-inference p-value for quasi_redriver_did_coef. ${RI_RR} draws of five venues without replacement from the `n_pool' panel venues filing in at least 54 of the 60 months in the window; the treatment dates are held fixed and only the assignment is permuted. Two-sided, counting placebo coefficients at least as large in absolute value, with the observed assignment included in the count.")
local fp2 : display %6.4f `rr_ri_p2'
numadd, key(quasi_redriver_ri_p_corepool) value("`rr_ri_p2'") formatted("`=trim("`fp2'")'") ///
    unit("exact p-value") source("`srcRR'") ///
    note("Randomization inference restricted to a pool of `n_pool_core' core live-music rooms, so the placebo venues are the same kind of business as the pilot venues.")
local f  : display %6.3f `rrd_b'
local fs : display %6.3f `rrd_se'
numadd, key(quasi_redriver_did_rronly) value("`rrd_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcRR'") ///
    note("Same specification restricted to Red River Cultural District venues, so the comparison group is the neighbouring rooms that did not run extended hours. `rrd_n' venue-months in `rrd_u' clusters, clustered SE `=trim("`fs'")'. With this few clusters the clustered SE is not trustworthy.")
local f  : display %6.3f `rrb_b'
local fs : display %6.3f `rrb_se'
numadd, key(quasi_redriver_did_ordwindow) value("`rrb_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcRR'") ///
    note("Same specification using the window the ordinance record implies, 2017-02 to 2018-04, rather than the May-to-November window the city evaluation is reported to have used. Clustered SE `=trim("`fs'")'. The two windows disagree because the evaluation memo itself was never located; only the Law Department draft ordinance is in hand.")
local f  : display %6.3f `rrs_b'
local fs : display %6.3f `rrs_se'
local fp : display %6.4f `rrs_p'
numadd, key(quasi_redriver_did_seasonadj) value("`rrs_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcRR'") ///
    note("Same difference-in-differences with venue-by-month-of-year fixed effects added, which absorb the part of seasonality the two groups do not share. Clustered SE `=trim("`fs'")', nominal p `=trim("`fp'")'. This is the preferred point estimate, because the reported pilot window runs May to November and six of its seven months fall in the second half of the year, where the pilot venues are seasonally weaker than the comparison group.")
local f  : display %7.2f `rr_pre_F'
local fp : display %6.4f `rr_pre_p'
numadd, key(quasi_redriver_pretrend_p) value("`rr_pre_p'") formatted("`=trim("`fp'")'") ///
    unit("p-value") source("`srcRR'") ///
    note("Joint test that the three pre-pilot half-year coefficients are zero against a 2016H2 base, F = `=trim("`f'")'. It rejects. Reading the coefficients shows why: every first-half block sits above every second-half block for the pilot venues relative to the comparison group, before the pilot as much as after, so the rejection is differential seasonality rather than a diverging trend.")
local f  : display %7.2f `rrs_pre_F'
local fp : display %6.4f `rrs_pre_p'
numadd, key(quasi_redriver_pretrend_p_seasonadj) value("`rrs_pre_p'") formatted("`=trim("`fp'")'") ///
    unit("p-value") source("`srcRR'") ///
    note("The same pre-pilot joint test once venue-by-month-of-year effects absorb differential seasonality, F = `=trim("`f'")'. This is the diagnostic that decides whether the design is reportable: the raw test rejects on seasonality, and this one asks whether anything is left.")
numadd, key(quasi_redriver_claim_unverified) value("22") formatted("22%") ///
    unit("percent, claimed") ///
    source("01_evidence/04_city_programs_lmf/_findings.md finding 21") ///
    note("The reported city evaluation of the 2017 pilot claimed a 22 percent rise in payments to local musicians, alongside 10 percent more local and regional acts booked and 13 percent fewer total tickets sold. The evaluation memo was never located and nobody has independently checked it. Mixed-beverage receipts cannot test that claim directly, because they measure alcohol sales and not the door split, so the estimate here bounds whether anything visible happened to venue revenue, not whether musician pay moved.")


* ===========================================================================
* 7. DESIGN 3 - LIVE MUSIC FUND VENUE GRANTS
* ===========================================================================
* The Live Music Fund admitted venues for the first time in FY2024, at $30,000
* or $60,000 depending on operating budget; the FY2026 cycle paid a flat
* $70,000. Awards are competitively scored against published criteria, so
* recipients are selected on whatever the scoring rewards. Descriptive only.

* --- extract the FY2024 venue awardees -------------------------------------
* Venue lines are the only ones in the FY2024 list carrying $60,000; musicians
* and promoters took $15,000 or $30,000. The dollar sign is located with
* char(36) so no string literal can be read as a global macro reference.
import delimited using "${EV_CITY}/_txt/LMF_FY24_awardee_list.txt", ///
    clear delimiter("~") varnames(nonames) stringcols(_all) ///
    bindquotes(nobind) encoding("utf-8")
keep if ustrregexm(v1, "60,000")
generate str120 award_name = trim(itrim(substr(v1, 1, strpos(v1, char(36)) - 1)))
generate double lmf_usd = 60000
generate int lmf_fy = 2024
keep award_name lmf_usd lmf_fy
quietly count
local n_lmf24 = r(N)
assert `n_lmf24' == 17
tempfile lmf24
save `lmf24'

* --- extract the FY2026 venue awardees -------------------------------------
import delimited using "${EV_CITY}/_txt/LMF_FY26_awardee_list.txt", ///
    clear delimiter("~") varnames(nonames) stringcols(_all) ///
    bindquotes(nobind) encoding("utf-8")
keep if ustrregexm(v1, "Live Music Venue") & ustrregexm(v1, "70,000")
drop if ustrregexm(v1, "(?i)total")
generate str120 award_name = trim(itrim(substr(v1, 1, strpos(v1, "Live Music Venue") - 1)))
generate double lmf_usd = 70000
generate int lmf_fy = 2026
keep award_name lmf_usd lmf_fy
quietly count
local n_lmf26 = r(N)
tempfile lmf26
save `lmf26'
display as text "  FY2026 venue award lines extracted: `n_lmf26'"

* --- match award names to the panel ----------------------------------------
use `lmf24', clear
append using `lmf26'
namekey award_name, generate(akname)

generate str244 lkey = akname
merge m:1 lkey using `keyloc', keep(master match) nogenerate
drop lkey
generate str244 vnkey = akname
merge m:1 vnkey using `keyvn', keep(master match) nogenerate
drop vnkey
generate str244 tkey = akname
merge m:1 tkey using `keytax', keep(master match) nogenerate
drop tkey

generate str32 venue_key    = ""
generate str32 match_method = "unmatched"
replace venue_key = vk_loc if venue_key == "" & !missing(vk_loc)
replace match_method = "trading_name" if venue_key != "" & match_method == "unmatched"
replace venue_key = vk_vn  if venue_key == "" & !missing(vk_vn)
replace match_method = "venue_name" if venue_key != "" & match_method == "unmatched"
replace venue_key = vk_tax if venue_key == "" & !missing(vk_tax)
replace match_method = "taxpayer_name" if venue_key != "" & match_method == "unmatched"

generate byte uncertain_match = 0
generate str244 match_note = ""

* Hand-verified overrides, keyed on the normalised award name so no ASCII
* apostrophe enters a macro. Where the automated rule already found the same
* venue, the method is stamped as confirmed rather than overwritten, so the
* crosswalk records how each row was really resolved.
capture program drop lmffix
program define lmffix
    syntax , KEYN(string) VKEY(string) [UNC(integer 0) NOTE(string)]
    quietly {
        replace match_note = "`note'" if akname == "`keyn'"
        replace uncertain_match = `unc' if akname == "`keyn'"
        replace match_method = cond(venue_key == "", "hand_verified", ///
            cond(venue_key == "`vkey'", match_method + "_confirmed", "hand_override")) ///
            if akname == "`keyn'"
        replace venue_key = "`vkey'" if akname == "`keyn'"
    }
end

lmffix, keyn("ANTONESNIGHTCLUB") vkey("antones") ///
    note("Comptroller trading name is ANTONES; the award list uses the full club name.")
lmffix, keyn("CORALSNAKE") vkey("coralsnake") ///
    note("Comptroller records the room under two trading names, THE CORAL SNAKE and STEELYS LODGE.")
lmffix, keyn("FAROUTLOUNGEANDSTAGE") vkey("farout") ///
    note("Comptroller trading name is THE FAR OUT.")
lmffix, keyn("SKYLARKLOUNGE") vkey("skylark") ///
    note("Comptroller trading name is SKYLARK LOUNGE.")
lmffix, keyn("MOHAWKAUSTIN") vkey("mohawk") ///
    note("Comptroller trading name is THE MOHAWK; the permit is held by Austin Hawk, LP.")
lmffix, keyn("SAGEBRUSH") vkey("sagebrush") ///
    note("Comptroller trading name is SAGEBRUSH BAR.")
lmffix, keyn("PARISH") vkey("parish_ih35") ///
    note("The operating Parish room on the award date is 501 N IH-35; the older 214 E 6th permit stopped filing in 2017.")
lmffix, keyn("CONCOURSEPROJECT") vkey("concourse") ///
    note("Comptroller trading name is THE CONCOURSE.")
lmffix, keyn("CHESSCLUBAUSTIN") vkey("chessclub") ///
    note("Comptroller trading name is CHESS CLUB.")
lmffix, keyn("CHESSCLUB") vkey("chessclub") ///
    note("Comptroller trading name is CHESS CLUB; Flying Houses LLC also held the Barracuda permit.")
lmffix, keyn("HEARDENTERTAINMENTTEXAS") vkey("empire") ///
    note("Heard Entertainment Texas, LLC is the Comptroller taxpayer for Empire Control Room and Garage at 606 E 7th.")
lmffix, keyn("THREES") vkey("hotelvegas") ///
    note("Threes Company LLC is the Comptroller taxpayer for the Hotel Vegas and Volstead Lounge permit.")
lmffix, keyn("CBOYSHEARTANDSOUL") vkey("cboys") ///
    note("Comptroller trading name carries an apostrophe the award list omits.")
lmffix, keyn("ELEPHANTROOM") vkey("elephantroom") note("Trading name matches exactly.")
lmffix, keyn("FLAMINGOCANTINA") vkey("flamingo") note("Trading name matches once the legal suffix is stripped.")
lmffix, keyn("SAHARALOUNGE") vkey("sahara") note("Trading name matches once the leading article is stripped.")
lmffix, keyn("SPEAKEASY") vkey("speakeasy") note("Trading name matches exactly.")
lmffix, keyn("04CENTER") vkey("o4center") note("Trading name matches once the leading article is stripped.")
lmffix, keyn("LOSTWELL") vkey("lostwell") note("Trading name matches once the leading article is stripped.")
lmffix, keyn("VALHALLA") vkey("valhalla") note("Trading name matches exactly.")
lmffix, keyn("ELYSIUM") vkey("elysium") note("Trading name matches exactly.")
lmffix, keyn("KICKBUTTCOFFEE") vkey("kickbutt") note("Trading name matches exactly.")
lmffix, keyn("KINGDOMNIGHTCLUB") vkey("kingdom") note("Trading name matches exactly.")
lmffix, keyn("PARKERJAZZCLUB") vkey("parker") note("Panel venue name matches; the Comptroller trading name is only PARKER.")
lmffix, keyn("SAMSTOWNPOINT") vkey("samstown") note("Trading name matches exactly.")

* The 13th Floor is the current operation at 711 Red River, an address that has
* run Beerland, then Green Jay, then 13th Floor. The panel carries the current
* permit under the trading name RED RIVER HOSPITALITY, held by Block89, LLC, so
* no name key can confirm it and the address history is the only tie.
lmffix, keyn("13THFLOOR") vkey("redriverhosp") unc(1) ///
    note("Matched on address history only: 711 Red River ran Beerland, then Green Jay, then 13th Floor. The current permit files under the trading name RED RIVER HOSPITALITY, so no name key can confirm it.")

quietly count if venue_key == ""
local n_lmf_unmatched = r(N)
quietly count if venue_key == "" & lmf_fy == 2024
local n_lmf24_unmatched = r(N)
assert `n_lmf24_unmatched' == 0
display as text "  LMF award rows not matched to a panel venue: `n_lmf_unmatched', all FY2026"

preserve
    merge m:1 venue_key using `venueattr', keep(master match) nogenerate
    sort lmf_fy award_name
    keep  lmf_fy award_name lmf_usd venue_key venue_name tier district ///
          match_method uncertain_match match_note
    order lmf_fy award_name lmf_usd venue_key venue_name tier district ///
          match_method uncertain_match match_note
    export delimited using "${TABDIR}/lmf_venue_crosswalk.csv", replace
    display as text "  crosswalk -> out/tables/lmf_venue_crosswalk.csv"
restore

keep if lmf_fy == 2024 & venue_key != ""
keep venue_key lmf_usd uncertain_match
rename uncertain_match lmf_uncertain
duplicates drop venue_key, force
isid venue_key
quietly count
local n_lmf24_matched = r(N)
tempfile lmfx
save `lmfx'

* --- FY2026 is not evaluable, and saying so is the finding ------------------
* The FY2026 venue awards were announced in March 2026. The receipts panel runs
* to 2026-06 and out/cpi_annual.dta carries no 2026 deflator, so there are at
* most three post-award months and none of them can be stated in real dollars.
numadd, key(quasi_lmf_fy26_not_evaluable) value("`n_lmf26'") ///
    formatted("`n_lmf26' venue awards") unit("count") ///
    source("01_evidence/04_city_programs_lmf/_txt/LMF_FY26_awardee_list.txt") ///
    note("FY2026 Live Music Fund venue awards extracted from the published list. They cannot be evaluated here: the awards were announced in March 2026, the receipts panel ends 2026-06, and no 2026 CPI annual average exists, so there are at most three post-award months and no way to state them in real dollars. Note also that the published list totals 20 venues and \textdollar{}1,400,000 while the itemised lines number `n_lmf26'; that discrepancy is in the source document and is not resolved here.")

* --- the FY2024 event study ------------------------------------------------
use `panel', clear
merge m:1 venue_key using `lmfx', keep(master match) nogenerate
generate byte lmf24 = !missing(lmf_usd)
quietly levelsof venue_key if lmf24 & large_room, local(lmfbig)
local n_lmf_big : word count `lmfbig'
drop if large_room
keep if inrange(ym, ym(2018,1), ym(2025,12))
keep if !missing(lnreal)

* A treated venue with no receipts in the base year has no pre-period and is
* dropped rather than allowed to enter the model as an opening.
preserve
    keep if year == 2023
    contract venue_key
    rename _freq n2023
    tempfile has23
    save `has23'
restore
merge m:1 venue_key using `has23', keep(master match) nogenerate
replace n2023 = 0 if missing(n2023)
preserve
    keep if inrange(year, 2024, 2025)
    contract venue_key
    rename _freq npost
    tempfile haspost
    save `haspost'
restore
merge m:1 venue_key using `haspost', keep(master match) nogenerate
replace npost = 0 if missing(npost)

drop if lmf24 & (n2023 < 10 | npost < 6)
quietly levelsof venue_key if lmf24, local(lmfuse)
local n_lmf_used : word count `lmfuse'
local n_lmf_nopre = `n_lmf24_matched' - `n_lmf_big' - `n_lmf_used'
quietly levelsof venue_key if lmf24 & year == 2019, local(lmfpre19)
local n_lmf_pre19 : word count `lmfpre19'
display as text "  LMF FY2024: `n_lmf24_matched' matched, `n_lmf_big' large room(s) excluded, `n_lmf_nopre' with no pre-period, `n_lmf_used' used"
display as text "  of the `n_lmf_used' used, `n_lmf_pre19' were already filing in 2019"

generate byte post24 = (year >= 2024)
generate byte d_lmf  = post24 * lmf24
label variable d_lmf "FY2024 venue grantee x 2024 onward"
label variable lmf24 "FY2024 Live Music Fund venue grantee"

* Comparison pool for randomization inference: venues meeting the same filing
* coverage requirement imposed on the treated group.
generate byte ripool = (n2023 >= 10 & npost >= 6)
quietly count if ripool & lmf24
preserve
    contract venue_key ripool
    quietly count if ripool
    local n_lmfpool = r(N)
restore
display as text "  LMF RI pool: `n_lmfpool' venues"

eststo clear
eststo lmf1: reghdfe lnreal d_lmf, absorb(vid ym) vce(cluster vid)
estadd local dsn "Pooled 2024-2025"
estadd local samp "Panel venues 2018-2025, large rooms excluded"
local lmf_b  = _b[d_lmf]
local lmf_se = _se[d_lmf]
local lmf_p  = 2 * ttail(e(df_r), abs(`lmf_b'/`lmf_se'))
local lmf_n  = e(N)
local lmf_u  = e(N_clust)

* Annual event-study dummies built by hand, for the same reason as the SVOG
* blocks: factor-variable notation lets reghdfe choose which level to drop.
local lyvars ""
forvalues yy = 2018/2025 {
    quietly generate byte ly`yy' = (year == `yy') * lmf24
    label variable ly`yy' "FY2024 venue grantee x `yy'"
    if `yy' != 2023 local lyvars "`lyvars' ly`yy'"
}
eststo lmf2: reghdfe lnreal `lyvars', absorb(vid ym) vce(cluster vid)
estadd local dsn "Annual event study, base 2023"
estadd local samp "Panel venues 2018-2025, large rooms excluded"
local lmf_es_n = e(N)
local lmf_pre_F = .
local lmf_pre_p = .
local lmf_pre2_F = .
local lmf_pre2_p = .
capture testparm ly2018 ly2019 ly2020 ly2021 ly2022
if _rc == 0 {
    local lmf_pre_F = r(F)
    local lmf_pre_p = r(p)
}
capture testparm ly2018 ly2019
if _rc == 0 {
    local lmf_pre2_F = r(F)
    local lmf_pre2_p = r(p)
}
display as text "  LMF pre-trend joint test, 2018-2022 vs 2023: F = " %7.2f `lmf_pre_F' ", p = " %6.4f `lmf_pre_p'
display as text "  LMF pre-trend joint test, 2018-2019 only:    F = " %7.2f `lmf_pre2_F' ", p = " %6.4f `lmf_pre2_p'

tempname PLS
tempfile lmfES
postfile `PLS' int yr double(b se lo hi) using `lmfES', replace
forvalues yy = 2018/2025 {
    if `yy' == 2023 {
        post `PLS' (`yy') (0) (0) (0) (0)
    }
    else {
        capture local bcoef = _b[ly`yy']
        if _rc == 0 {
            local scoef = _se[ly`yy']
            if `scoef' > 0 {
                post `PLS' (`yy') (`bcoef') (`scoef') ///
                           (`bcoef' - 1.96*`scoef') (`bcoef' + 1.96*`scoef')
            }
        }
    }
}
postclose `PLS'

* --- randomization inference for the LMF design ----------------------------
preserve
    contract venue_key vid ripool
    keep if ripool
    mkmat vid, matrix(POOL)
restore
local R = ${RI_LMF}
mata: ridraws(`R', `n_lmf_used')

generate byte tsim = 0
generate byte dsim = 0
local nge = 0
quietly {
    forvalues r = 1/`R' {
        mata: st_local("picks", invtokens(strofreal(DR[`r', .])))
        replace tsim = 0
        foreach vv of local picks {
            replace tsim = 1 if vid == `vv'
        }
        replace dsim = tsim * post24
        reghdfe lnreal dsim, absorb(vid ym)
        local bs = _b[dsim]
        if abs(`bs') >= abs(`lmf_b') - 1e-12 {
            local nge = `nge' + 1
        }
    }
}
local lmf_ri_p = (`nge' + 1) / (`R' + 1)
display as text "  LMF randomization inference: exact p = " %6.4f `lmf_ri_p' " over `R' draws"

esttab lmf1 lmf2 using "${TABDIR}/table_lmf_venue_grants.csv", replace ///
    csv se star(* 0.10 ** 0.05 *** 0.01) label b(4) se(4) ///
    scalars("dsn Specification" "samp Sample") ///
    title("Receipts around a FY2024 Live Music Fund venue grant, Austin panel venues") ///
    addnotes("Outcome is log real monthly receipts in 2025 dollars, 2018-01 to 2025-12." ///
             "Venue and calendar-month fixed effects; standard errors clustered by venue." ///
             "The annual event study omits 2023, the last full year before the FY2024 awards." ///
             "Grants are competitively scored, so recipients are selected on the scoring criteria." ///
             "Descriptive event study. Not a causal estimate of the program.")
display as text "  table -> out/tables/table_lmf_venue_grants.csv"

local srcLMF "01_evidence/04_city_programs_lmf/_txt/LMF_FY24_awardee_list.txt"
numadd, key(quasi_lmf24_venue_awards) value("`n_lmf24'") formatted("`n_lmf24' venues") ///
    unit("count") source("`srcLMF'") ///
    note("FY2024 Live Music Fund venue awards, all at \textdollar{}60,000, extracted from the published awardee list. All `n_lmf24' matched to the receipts panel. `n_lmf_big' of them is a large ticketed room and is held out on the same rule applied to every design here; `n_lmf_nopre' has no pre-period, having first filed in 2024-09; the remaining `n_lmf_used' enter the event study, of which `n_lmf_pre19' were already filing in 2019, so the 2018 and 2019 coefficients rest on a smaller treated group than the later ones. The crosswalk is at out/tables/lmf_venue_crosswalk.csv.")
local f   : display %6.3f `lmf_b'
local fs  : display %6.3f `lmf_se'
local fp  : display %6.4f `lmf_ri_p'
local fc  : display %6.4f `lmf_p'
local fpc : display %5.1f `=100*(exp(`lmf_b')-1)'
numadd, key(quasi_lmf24_post_coef) value("`lmf_b'") formatted("`=trim("`f'")'") ///
    unit("log points") source("`srcLMF'") ///
    note("reghdfe lnreal d_lmf, absorb(venue month) vce(cluster venue), where d_lmf is FY2024 venue grantee times 2024 onward. Sample: `n_lmf_used' grantee venues against the rest of the panel, 2018-01 to 2025-12, large ticketed rooms excluded, `lmf_n' venue-months in `lmf_u' clusters. Point estimate `=trim("`fpc'")' percent. Clustered SE `=trim("`fs'")' with nominal p `=trim("`fc'")'; randomization-inference exact p = `=trim("`fp'")' over ${RI_LMF} permutations of the grantee set across `n_lmfpool' eligible venues. Grants are competitively scored, so this is a conditional association, not a program effect.")
numadd, key(quasi_lmf24_ri_p) value("`lmf_ri_p'") formatted("`=trim("`fp'")'") ///
    unit("exact p-value") source("`srcLMF'") ///
    note("Randomization-inference p-value for quasi_lmf24_post_coef. ${RI_LMF} draws of `n_lmf_used' venues without replacement from the `n_lmfpool' panel venues meeting the same filing-coverage requirement as the treated group.")
local f  : display %7.2f `lmf_pre_F'
local fp : display %6.4f `lmf_pre_p'
numadd, key(quasi_lmf24_pretrend_p) value("`lmf_pre_p'") formatted("`=trim("`fp'")'") ///
    unit("p-value") source("`srcLMF'") ///
    note("Joint test that the 2018 to 2022 annual event-study coefficients are zero against a 2023 base, F = `=trim("`f'")'. This covers the pandemic years, so a rejection can reflect a different pandemic path rather than a different trend.")
local f  : display %7.2f `lmf_pre2_F'
local fp : display %6.4f `lmf_pre2_p'
numadd, key(quasi_lmf24_pretrend_p_prepandemic) value("`lmf_pre2_p'") formatted("`=trim("`fp'")'") ///
    unit("p-value") source("`srcLMF'") ///
    note("Joint test restricted to 2018 and 2019 against the 2023 base, F = `=trim("`f'")'. This is the pre-pandemic parallel-paths check, and it rests on the `n_lmf_pre19' of `n_lmf_used' grantee venues that were already filing in 2019.")


* ===========================================================================
* 8. DESIGN 4 - MOODY CENTER OPENING, APRIL 2022, DISPLACEMENT TEST
* ===========================================================================
* Question: did receipts at nearby small rooms move differently from receipts at
* distant ones after a 15,000-seat arena opened on the University of Texas
* campus in April 2022?
*
* DISTANCE IS NOT RANDOM, and nothing about this design makes it so. Venues near
* the arena are central-city rooms: older, smaller, more exposed to downtown
* rents and to the Red River contraction documented in 30_venues.do. Any post
* difference by distance band is therefore a comparison of central rooms with
* suburban ones during a period when the central rooms were already diverging.
* Read the coefficients as a description of where the divergence sits.
*
* The pandemic window is dropped rather than modelled. Keeping 2020 and 2021 in
* the pre-period would load the estimate with the differential collapse and
* recovery of central versus suburban rooms, which is a different question.
*
* WHAT ELSE IS MOVING IN THE SAME POST WINDOW. Two findings from other modules
* bear on how any distance pattern here should be read. The 2022 Austin Music
* Census presenter block ranks property tax as the top business pressure, with
* 44.1 percent of venue respondents placing it in their top three and 20.3
* percent placing it first, ahead of talent and labour costs; and the closure
* timeline attributes 13 of 36 dated closures to real-estate causes, the same
* count as the pandemic. Property cost exposure rises steeply toward the centre,
* so it moves with the distance bands and is a live alternative explanation for
* anything the innermost band does. Separately, Austin real market rent peaked
* in December 2021 and has fallen 23.5 percent since, so the post window here
* sits in a period of easing residential rents rather than tightening ones.

use `panel', clear
merge m:1 venue_key using `venuegeo', keep(master match) nogenerate

* Moody Center, 2001 Robert Dedman Drive. The arena holds no outdoor sound
* permit to geocode from, so the coordinate is entered directly. A hundred
* metres either way is immaterial against one-mile bands.
local mlat =  30.2814
local mlon = -97.7325
generate double dist_mi = 3958.8 * 2 * asin(sqrt( ///
    (sin((lat - `mlat') * _pi/180 / 2))^2 + ///
    cos(lat * _pi/180) * cos(`mlat' * _pi/180) * ///
    (sin((lon - `mlon') * _pi/180 / 2))^2 ))
label variable dist_mi "Straight-line miles from the Moody Center"

drop if large_room                       // removes the arena itself and the other big rooms
keep if !missing(dist_mi) & !missing(lnreal)
keep if inrange(ym, ym(2018,1), ym(2019,12)) | inrange(ym, ym(2022,7), ym(2025,12))

generate byte band = .
replace band = 1 if dist_mi < 1
replace band = 2 if inrange(dist_mi, 1, 2)
replace band = 3 if dist_mi > 2 & dist_mi <= 4
replace band = 4 if dist_mi > 4 & !missing(dist_mi)
label define bandl 1 "Under 1 mile" 2 "1 to 2 miles" 3 "2 to 4 miles" 4 "More than 4 miles"
label values band bandl
label variable band "Straight-line distance band from the Moody Center"

preserve
    contract venue_key band
    tabulate band
    forvalues b = 1/4 {
        quietly count if band == `b'
        local nb`b' = r(N)
    }
restore
display as text "  venues by band: under 1mi `nb1', 1-2mi `nb2', 2-4mi `nb3', over 4mi `nb4'"

generate byte post22 = (ym >= ym(2022,4))
label variable post22 "Arena open, 2022-07 onward in this sample"
forvalues b = 1/3 {
    generate byte d_b`b' = post22 * (band == `b')
}
label variable d_b1 "Post-opening x under 1 mile"
label variable d_b2 "Post-opening x 1 to 2 miles"
label variable d_b3 "Post-opening x 2 to 4 miles"

eststo clear
if (`nb1' >= 3) & (`nb2' >= 3) & (`nb3' >= 3) & (`nb4' >= 3) {
    global MOODYOK 1
    eststo md1: reghdfe lnreal d_b1 d_b2 d_b3, absorb(vid ym) vce(cluster vid)
    estadd local dsn "Distance bands, over 4 miles omitted"
    estadd local samp "2018-2019 and 2022H2-2025, large rooms excluded"
    local md_b1  = _b[d_b1]
    local md_se1 = _se[d_b1]
    local md_p1  = 2 * ttail(e(df_r), abs(`md_b1'/`md_se1'))
    local md_b2  = _b[d_b2]
    local md_se2 = _se[d_b2]
    local md_b3  = _b[d_b3]
    local md_se3 = _se[d_b3]
    local md_n   = e(N)
    local md_u   = e(N_clust)
    test d_b1 = d_b2 = d_b3
    local md_jointp = r(p)

    * Continuous version, so nothing rests on where the band cuts fall.
    generate double post_x_lndist = post22 * ln(dist_mi + 0.1)
    label variable post_x_lndist "Post-opening x log distance in miles"
    eststo md2: reghdfe lnreal post_x_lndist, absorb(vid ym) vce(cluster vid)
    estadd local dsn "Continuous log distance"
    estadd local samp "2018-2019 and 2022H2-2025, large rooms excluded"
    local md_cb  = _b[post_x_lndist]
    local md_cse = _se[post_x_lndist]

    esttab md1 md2 using "${TABDIR}/table_moody_distance.csv", replace ///
        csv se star(* 0.10 ** 0.05 *** 0.01) label b(4) se(4) ///
        scalars("dsn Specification" "samp Sample") ///
        title("Receipts by distance from the Moody Center, before and after its April 2022 opening") ///
        addnotes("Outcome is log real monthly receipts in 2025 dollars." ///
                 "Pre-period 2018-01 to 2019-12; post-period 2022-07 to 2025-12; the pandemic window is dropped." ///
                 "Venue and calendar-month fixed effects; standard errors clustered by venue." ///
                 "Distance is not random: near venues are central-city rooms and differ from far ones in many ways." ///
                 "Descriptive comparison by distance band. Not a displacement estimate.")
    display as text "  table -> out/tables/table_moody_distance.csv"

    local srcMD "01_evidence/08_venues_ecosystem/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv with venue_monthly_receipts_long.csv"
    local f  : display %6.3f `md_b1'
    local fs : display %6.3f `md_se1'
    local fp : display %6.4f `md_p1'
    local fj : display %6.4f `md_jointp'
    numadd, key(quasi_moody_band1_coef) value("`md_b1'") formatted("`=trim("`f'")'") ///
        unit("log points") source("`srcMD'") ///
        note("reghdfe lnreal d_b1 d_b2 d_b3, absorb(venue month) vce(cluster venue). Coefficient on the innermost band, venues within one mile of the Moody Center, after 2022-04, relative to venues more than four miles away. `nb1' venues in the band; `md_n' venue-months in `md_u' clusters; clustered SE `=trim("`fs'")', p `=trim("`fp'")'. The joint test that the three band coefficients are equal has p = `=trim("`fj'")'. Sample is 2018-01 to 2019-12 and 2022-07 to 2025-12, so the pandemic window is excluded. Distance is not random; these are central-city rooms compared with suburban ones.")
    local f  : display %6.3f `md_b2'
    local fs : display %6.3f `md_se2'
    numadd, key(quasi_moody_band2_coef) value("`md_b2'") formatted("`=trim("`f'")'") ///
        unit("log points") source("`srcMD'") ///
        note("Same specification, venues one to two miles from the arena, `nb2' venues, clustered SE `=trim("`fs'")'.")
    local f  : display %6.3f `md_b3'
    local fs : display %6.3f `md_se3'
    numadd, key(quasi_moody_band3_coef) value("`md_b3'") formatted("`=trim("`f'")'") ///
        unit("log points") source("`srcMD'") ///
        note("Same specification, venues two to four miles from the arena, `nb3' venues, clustered SE `=trim("`fs'")'. The reference group is the `nb4' venues more than four miles away.")
    local f  : display %6.3f `md_cb'
    local fs : display %6.3f `md_cse'
    numadd, key(quasi_moody_logdist_coef) value("`md_cb'") formatted("`=trim("`f'")'") ///
        unit("log points per log mile") source("`srcMD'") ///
        note("Continuous version of the same comparison: post-opening interacted with log distance in miles, so nothing rests on where the band cuts fall. Clustered SE `=trim("`fs'")'.")
    numadd, key(quasi_moody_joint_p) value("`md_jointp'") formatted("`=trim("`fj'")'") ///
        unit("p-value") source("`srcMD'") ///
        note("Joint test that the three distance-band coefficients equal one another, which is the test of whether the post-opening pattern varies with distance at all. It does not reject anywhere near conventional levels, and none of the three band coefficients is individually distinguishable from zero either, so what the design finds is a flat profile rather than a proximity effect. The reference group is only `nb4' venues, which is thin, and that is part of why every band standard error is large.")
}
else {
    global MOODYOK 0
    display as error "MOODY DESIGN DROPPED: at least one distance band holds fewer than three venues."
    numadd, key(quasi_moody_dropped) value("0") formatted("not estimated") unit("flag") ///
        source("01_evidence/08_venues_ecosystem/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv") ///
        note("The Moody Center distance design was not estimated because at least one distance band held fewer than three geocoded venues.")
}
numadd, key(quasi_moody_geocoded) value("`n_geo'") formatted("`n_geo' of `n_venues'") ///
    unit("count") ///
    source("01_evidence/08_venues_ecosystem/austin_sound_ordinance_permits_geo_g3rj-dfgm.csv") ///
    note("Panel venues carrying a coordinate, from the City of Austin geocoded sound-ordinance permit file matched on a normalised street address then on a normalised venue name. Venues never permitted for amplified sound have no coordinate and are absent from the distance design only.")


* ===========================================================================
* 9. DESIGN 5 - I-35 CONSTRUCTION, DESCRIPTIVE ONLY
* ===========================================================================
* Two venues closed to the highway expansion within fifteen days: The Lost Well
* on 2024-10-27 and Stars Cafe on 2024-11-10, the latter after more than fifty
* years. Two units cannot support a design, so this is reported as what it is: a
* documented non-market exit, where the closure was decided by a highway project
* rather than by demand, rent or a licensing dispute.

use `panel', clear
quietly count if lower(venue_name) == "stars cafe"
local stars_n = r(N)
keep if venue_key == "lostwell"
quietly summarize receipts_real2025 if inrange(ym, ym(2023,11), ym(2024,10)), meanonly
local lw_pre  = r(sum)
local lw_prem = r(N)
quietly summarize receipts_real2025 if inrange(ym, ym(2024,11), ym(2025,12)), meanonly
local lw_post  = r(sum)
local lw_postm = r(N)
quietly summarize ym if receipts_real2025 > 0 & ym > ym(2024,10), meanonly
local lw_res = string(r(min), "%tmCCYY-NN")

display as text "  Lost Well, 12 months to closure: " %14.0fc `lw_pre' " in `lw_prem' filings"
display as text "  Lost Well, 14 months after:      " %14.0fc `lw_post' " in `lw_postm' filings"
display as text "  Lost Well first month with receipts after the closure: `lw_res'"
display as text "  Stars Cafe rows in the panel: `stars_n'"

local f19 : display %14.0fc `lw_pre'
local f25 : display %14.0fc `lw_post'
numadd, key(quasi_i35_lostwell_pre) value("`lw_pre'") formatted("\textdollar{}`=trim("`f19'")'") ///
    unit("2025 dollars") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Real receipts at The Lost Well over the twelve months ending with its 2024-10-27 closure to the I-35 expansion, `lw_prem' months of filings. The permit resumed filing in `lw_res' from a new address on Airport Boulevard, so this venue relocated rather than disappeared.")
numadd, key(quasi_i35_lostwell_post) value("`lw_post'") formatted("\textdollar{}`=trim("`f25'")'") ///
    unit("2025 dollars") ///
    source("01_evidence/08_venues_ecosystem/venue_monthly_receipts_long.csv") ///
    note("Real receipts at The Lost Well over the fourteen months after the closure, `lw_postm' months of filings, spanning both the closed period and the relocated operation.")
* Cross-cutting interpretation note, registered once so every design carries it.
numadd, key(quasi_rent_environment_context) value("-23.5") formatted("-23.5%") ///
    unit("percent change in real market rent") ///
    source("09_cost_of_living cost-of-living module, Zillow observed rent index deflated to 2025 dollars") ///
    note("Austin real market rent peaked in December 2021 and has fallen 23.5 percent since, the steepest decline among five comparison metros. Every post-shock window in this module sits inside that decline: the SVOG awards land mid-2021, the Moody Center opens April 2022, and the Live Music Fund venue grants land in 2024. A reader should not assume the later part of the panel is a tightening rent environment for venues. It is not, at least not in the residential market that the Zillow series measures. Commercial rent for venue space is not measured anywhere in this evidence base, which is a real gap, and the 2022 Austin Music Census puts property tax rather than rent at the top of the venue cost list.")

numadd, key(quasi_i35_venues) value("2") formatted("2 venues") unit("count") ///
    source("01_evidence/08_venues_ecosystem/_findings.md finding 23") ///
    note("Venues removed by the I-35 expansion within fifteen days: The Lost Well on 2024-10-27 and Stars Cafe on 2024-11-10. Stars Cafe has `stars_n' rows in the mixed-beverage panel, so only one of the two can be observed in receipts at all. Two units cannot support a design; this is reported as a documented non-market exit, where the closure was decided by a highway project rather than by demand, rent or licensing.")


* ===========================================================================
* 10. FIGURE 22 - SVOG EVENT STUDY
* ===========================================================================
use `svogES', clear
sort hb
generate double yrs = hb / 2
label variable hb "Half-year blocks relative to the award"
export delimited hb yrs b se lo hi using "${OUT}/fig22_svog_event_study.csv", replace

* The y axis is set by hand to just contain the bands (-1.22 to +0.26). Stata's
* default choice ran -1.5 to +0.5 and left about a third of the plot empty.
* The title says the gap "narrowed" rather than "closed": the last block is
* -0.10 with a band from -0.39 to +0.19, which does not establish a closed gap.
twoway ///
  (rarea lo hi hb, color("${ORANGE}%18") lwidth(none)) ///
  (line b hb, lcolor("${ORANGE}") lwidth(medthick)) ///
  (scatter b hb, mcolor("${ORANGE}") msymbol(O) msize(small)) ///
  , yline(0, lcolor("${BORDER}") lwidth(thin)) ///
    xline(-0.5, lcolor("${NAVY}") lwidth(thin) lpattern(dash)) ///
    ytitle("Log points vs 2.5 years before the award", $YTOPT) ///
    ylabel(-1.2(0.3)0.3, angle(0) labsize(2.8)) ///
    yscale(range(-1.25 0.3)) ///
    xtitle("Half-years relative to each venue’s own award month", $XTOPT) ///
    xlabel(-8 "-4y" -6 "-3y" -4 "-2y" -2 "-1y" 0 "award" 2 "+1y" 4 "+2y" 6 "+3y" 8 "+4y", labsize(2.8)) ///
    legend(off) graphregion(color(white)) ysize(5.2) xsize(8.6) ///
    title("Relief arrived at the trough, and the gap to other venues narrowed", $TITLEOPT) ///
    subtitle("Log real monthly receipts at `n_tr_svog' Austin venues that won a shuttered-venue grant," ///
             "against other panel venues. Venue and month fixed effects, 95% bands, 2025 dollars.", $SUBOPT) ///
    name(fig22, replace)
figsave, name(fig22_svog_event_study)


* ===========================================================================
* 11. FIGURE 23 - RED RIVER 2017 PILOT
* ===========================================================================
* The plotted series is the ratio of pilot-venue receipts to comparison-venue
* receipts, with the recurring month-of-year pattern taken out. Taking the ratio
* removes the seasonality the two groups share; taking out the month-of-year
* mean removes the seasonality they do not share, which is the pattern the event
* study above exposes and the thing that makes the raw ratio unreadable. The
* month-of-year means are computed outside the pilot window so the adjustment
* cannot absorb the very months it is meant to display. Both the raw and the
* adjusted series go into the exported CSV.

use `panel', clear
drop if large_room
keep if inrange(ym, ym(2015,1), ym(2019,12))
generate byte rr5 = inlist(venue_key, "stubbs", "mohawk", "empire", "beerland", "cheerup")
generate double rec_t = receipts_real2025 * rr5
generate double rec_c = receipts_real2025 * (1 - rr5)
collapse (sum) rec_t rec_c, by(ym mo)
generate double ratio  = rec_t / rec_c
generate double lratio = ln(ratio)
generate byte pil = inrange(ym, ym(2017,5), ym(2017,11))
generate double lr_nonpilot = lratio if !pil
bysort mo: egen double moavg = mean(lr_nonpilot)
generate double adj = lratio - moavg
quietly summarize adj if inrange(ym, ym(2015,1), ym(2016,12)), meanonly
generate double idx = 100 * exp(adj - r(mean))
quietly summarize ratio if inrange(ym, ym(2015,1), ym(2016,12)), meanonly
generate double idx_raw = 100 * ratio / r(mean)
label variable idx     "Pilot venues relative to comparison venues, seasonally adjusted, 2015-2016 = 100"
label variable idx_raw "Same ratio with no seasonal adjustment"
generate str7 month = string(ym, "%tmCCYY-NN")

* bysort mo left the data in month-of-year order. twoway line connects points in
* dataset order, not x order, so an unsorted dataset draws a scribble.
sort ym

* A centred three-month mean is drawn over the monthly series. Sixty monthly
* points compress into an unreadable zigzag at 6.5 inches, and the smoothing is
* display only: it changes nothing in the estimates, and both series are
* exported so the chart stays checkable against the numbers. The endpoints have
* no centred window and keep their own value.
tsset ym
generate double idx_ma3 = (L1.idx + idx + F1.idx) / 3
replace idx_ma3 = idx if missing(idx_ma3)
label variable idx_ma3 "Centred three-month mean of idx"

quietly summarize idx, meanonly
local ylo = floor(r(min)/10)*10
local yhi = ceil(r(max)/10)*10
generate double shade_lo = `ylo' if pil
generate double shade_hi = `yhi' if pil
local xmid = ym(2017,8)

export delimited month rec_t rec_c ratio idx idx_ma3 idx_raw ///
    using "${OUT}/fig23_redriver_did.csv", replace
format ym %tmCCYY

* Title states what the chart can show, a level break, rather than the null the
* chart alone cannot establish. The interval and the randomization-inference
* p-value carry that claim in the text.
twoway ///
  (rarea shade_lo shade_hi ym, color("${GOLD}%16") lwidth(none)) ///
  (line idx     ym, lcolor("${ORANGE}%40") lwidth(thin)) ///
  (line idx_ma3 ym, lcolor("${ORANGE}") lwidth(thick)) ///
  , yline(100, lcolor("${BORDER}") lwidth(thin)) ///
    ytitle("Index, 2015-2016 average = 100", $YTOPT) ///
    ylabel(`ylo'(10)`yhi', angle(0) labsize(2.8)) ///
    yscale(range(`ylo' `yhi')) ///
    xtitle("") xlabel(#6, labsize(2.8)) ///
    text(`yhi' `xmid' "pilot window", color("${MUTED}") size(2.6) placement(s)) ///
    legend(order(2 "Monthly" 3 "Three-month average") ///
           cols(2) position(6) size(2.6) region(lstyle(none)) symxsize(7)) ///
    graphregion(color(white)) ysize(5.0) xsize(8.6) ///
    title("No step change in pilot-venue receipts when Austin extended hours in 2017", $TITLEOPT) ///
    subtitle("Receipts at the five named 2017 pilot venues divided by receipts at all other panel" ///
             "venues, seasonal pattern removed. Shading is the pilot window; the axis starts at `ylo'.", $SUBOPT) ///
    name(fig23, replace)
figsave, name(fig23_redriver_did)


* ===========================================================================
* 12. FIGURE 24 - LIVE MUSIC FUND VENUE GRANTS
* ===========================================================================
use `lmfES', clear
sort yr
export delimited yr b se lo hi using "${OUT}/fig24_lmf_venue_grants.csv", replace

* Drawn in orange, matching figure 22 two pages earlier. Both panels are the
* same object, an event study of Austin venue receipts around a grant, and the
* earlier blue invited a reader to look for a distinction that is not there.
twoway ///
  (rarea lo hi yr, color("${ORANGE}%18") lwidth(none)) ///
  (line b yr, lcolor("${ORANGE}") lwidth(medthick)) ///
  (scatter b yr, mcolor("${ORANGE}") msymbol(O) msize(small)) ///
  , yline(0, lcolor("${BORDER}") lwidth(thin)) ///
    xline(2023.5, lcolor("${NAVY}") lwidth(thin) lpattern(dash)) ///
    ytitle("Log points vs the same venues in 2023", $YTOPT) ///
    ylabel(, angle(0) labsize(2.8)) ///
    xtitle("") xlabel(2018(1)2025, labsize(2.8)) ///
    legend(off) graphregion(color(white)) ysize(5.0) xsize(8.6) ///
    title("Live Music Fund venue grantees show no receipts gap, before or after", $TITLEOPT) ///
    subtitle("Log real monthly receipts at `n_lmf_used' FY2024 Live Music Fund venue grantees against other" ///
             "panel venues. Venue and month fixed effects, 95% bands, 2023 omitted, 2025 dollars.", $SUBOPT) ///
    name(fig24, replace)
figsave, name(fig24_lmf_venue_grants)


display as text "70_quasi_experiments.do complete"
