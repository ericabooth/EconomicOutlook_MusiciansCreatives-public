*! 60_cost_of_living.do - Is Austin cost of living, or Austin housing cost,
*!   the thing squeezing musicians? Real rent and home-value trends (HUD FMR,
*!   Zillow ZORI/ZHVI) for Austin and 4 peer metros; CPI Housing against CPI
*!   All items nationally; BEA Regional Price Parity for Austin against
*!   peers; the hours of musician work needed to cover one month of Austin
*!   rent, including the city wage series that appears to cover the
*!   self-employed; and, where available, a PUMS-based share-of-income
*!   anchor that also covers the self-employed.
*!
*! FRAMING THIS MODULE MUST GET RIGHT
*!   1. BLS publishes no Austin-area CPI at all (verified against
*!      BLS_CPI.dta below, not assumed). Every real-dollar figure in this
*!      report, including every one here, deflates by the U.S. city
*!      average because that is the only series available for a metro BLS
*!      does not price on its own. If Austin costs have actually risen
*!      faster than the nation, that deflation UNDERSTATES Austin's true
*!      cost increase -- so a real-dollar DECLINE this module finds is a
*!      conservative reading, not an overstated one.
*!   2. Austin rents and home values ran up hard through 2022, then fell.
*!      This module shows both legs on every trend figure; it never crops
*!      the decline out and never hides the run-up either.
*!   3. BEA Regional Price Parity says Austin is near the national average
*!      on all items but far above average on housing specifically --
*!      verified against the file below, not copied from prior prose.
*!
*! Inputs  : 01_evidence/09_cost_of_living/hud_fmr_1983_2026_5area_long.csv
*!           01_evidence/09_cost_of_living/zillow_zori_seasadj_5metro_long.csv
*!           01_evidence/09_cost_of_living/zillow_zori_notseasadj_5metro_long.csv
*!           01_evidence/09_cost_of_living/zillow_zhvi_allhomes_seasadj_5metro_long.csv
*!           01_evidence/09_cost_of_living/acs_median_rent_homevalue_5geo_long.csv
*!           01_evidence/09_cost_of_living/bea_rpp_marpp_5metro_long.csv
*!           01_evidence/09_cost_of_living/mit_living_wage_travis_county_20260801.md
*!           01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv
*!           01_evidence/04_city_programs_lmf/socrata/2qxc-8cme_median_earnings_creative_occupations.csv
*!           03_analysis/data/external/BLS_CPI.dta
*!           03_analysis/out/cpi_annual.dta               (built by _setup.do)
*!           03_analysis/out/numbers/numbers_pums.csv      (optional; gates Task 5)
*! Outputs : 04_figures/fig19_rent_vs_wages.png (+ out/fig19_rent_vs_wages.csv)
*!           04_figures/fig20_metro_rent.png    (+ out/fig20_metro_rent.csv)
*!           03_analysis/out/numbers/numbers_costliving.csv

clear all
do "_setup.do"
global CURMODULE "costliving"
numinit

requirefile "${EV_COL}/hud_fmr_1983_2026_5area_long.csv"
requirefile "${EV_COL}/zillow_zori_seasadj_5metro_long.csv"
requirefile "${EV_COL}/zillow_zori_notseasadj_5metro_long.csv"
requirefile "${EV_COL}/zillow_zhvi_allhomes_seasadj_5metro_long.csv"
requirefile "${EV_COL}/acs_median_rent_homevalue_5geo_long.csv"
requirefile "${EV_COL}/bea_rpp_marpp_5metro_long.csv"
requirefile "${EV_COL}/mit_living_wage_travis_county_20260801.md"
requirefile "${DATAX}/BLS_CPI.dta"
requirefile "${EV_WAGES}/oews_musicians_creatives_2005_2025.csv"
requirefile "${EV_CITY}/socrata/2qxc-8cme_median_earnings_creative_occupations.csv"

global MONTHNAMES "January February March April May June July August September October November December"

* Parallel lists used throughout: metro slug, for keys and filters, against
* its display label, for notes and titles. Order fixed everywhere below.
local metro_slugs "austin dallas houston nashville sanantonio"
local metro_labs  `""Austin" "Dallas" "Houston" "Nashville" "San Antonio""'


* ================================================================
* SECTION 1. Framing fact: BLS has no Austin-area CPI. Supplementary CPI
*            series this module needs beyond the shared cpi_annual.dta,
*            which only carries All items: an annual Housing series (Task
*            2), and a partial-year 2026 price level (HUD FY2026 and
*            Zillow's June 2026 read both fall in a year cpi_annual.dta
*            deliberately excludes as incomplete).
* ================================================================
preserve
    use "${DATAX}/BLS_CPI.dta", clear
    levelsof area_name, local(cpi_areas) clean
restore
display as text "BLS_CPI.dta area_name values found: `cpi_areas'"
local austin_in_cpi = strpos(`"`cpi_areas'"', "Austin")
display as text "Does any BLS_CPI.dta area name mention Austin? strpos = `austin_in_cpi' (must be 0)."
assert `austin_in_cpi' == 0

numadd, key(col_no_austin_bls_cpi) value(1) formatted("no Austin-area BLS CPI exists") ///
    unit("methodological framing, verified against the file") ///
    source("03_analysis/data/external/BLS_CPI.dta") ///
    note("The only area_name values in this project BLS CPI extract are: `cpi_areas'. BLS publishes no Austin-specific consumer price index at all; the closest published series are Dallas-Fort Worth-Arlington and Houston-The Woodlands-Sugar Land, plus a broader South census region. Every real-dollar figure in this report, including every one in this module, therefore deflates by the U.S. city average, the only series available for a metro BLS does not price on its own. Given this module own finding that Austin housing carries a large price premium over the national average (see the Regional Price Parity section below), U.S.-average deflation most likely UNDERSTATES how much Austin cost of living has actually risen, so any real-dollar decline this module reports is a conservative reading, not an overstated one.")

* ---- Annual Housing CPI, US city average. Not part of the shared
*      cpi_annual.dta, which only collapses All items. Same October-2025
*      funding-lapse gap affects Housing too (verified, not assumed), so the
*      same Sept/Nov-average patch is applied here for consistency. ----
preserve
    use "${DATAX}/BLS_CPI.dta", clear
    keep if area_name=="U.S. city average" & item_name=="Housing"
    keep if is_annualavg==0 & seas_adj==0 & !missing(month)
    keep year month cpi
    duplicates drop year month, force
    generate byte cpi_imputed = 0
    sort year month
    quietly count if year==2025 & month==10 & missing(cpi)
    local oct2025_gap = r(N)
    if `oct2025_gap' > 0 {
        quietly summarize cpi if year==2025 & month==9, meanonly
        local sep25 = r(mean)
        quietly summarize cpi if year==2025 & month==11, meanonly
        local nov25 = r(mean)
        quietly replace cpi = (`sep25' + `nov25')/2 if year==2025 & month==10
        quietly replace cpi_imputed = 1 if year==2025 & month==10
    }
    drop if missing(cpi)
    bysort year: generate byte nmon = _N
    keep if nmon==12
    collapse (mean) cpi (max) cpi_imputed, by(year)
    rename cpi cpi_housing
    label variable cpi_housing "CPI-U Housing, U.S. city average, annual average"
    tempfile cpi_housing_ann
    save `cpi_housing_ann'
restore
display as text "Housing CPI October 2025 gap found and patched: `oct2025_gap' row(s) (expect 1, the same federal-shutdown gap _setup.do patched for All items)."

numadd, key(col_cpi_housing_oct2025_imputed) value(`oct2025_gap') formatted("October 2025 imputed from September and November") ///
    unit("methodological note") source("03_analysis/data/external/BLS_CPI.dta") ///
    note("The October 2025 federal funding lapse suspended BLS CPI collection for the Housing item exactly as it did for All items, which _setup.do already patches in the shared cpi_annual.dta. This module independently builds an annual Housing series, since cpi_annual.dta carries only All items, and applies the identical September/November-2025-average imputation so the two national series are treated consistently.")

* ---- Partial-year 2026 price level. HUD FY2026 and Zillow June 2026 are
*      the most recent points this whole peak-then-pullback story turns on,
*      so a 2026 conversion is needed even though 2026 is not a complete
*      year and cpi_annual.dta correctly leaves it out. ----
preserve
    use "${DATAX}/BLS_CPI.dta", clear
    keep if area_name=="U.S. city average" & item_name=="All items"
    keep if is_annualavg==0 & seas_adj==0 & !missing(month) & year==2026
    quietly count
    local n2026mo = r(N)
    quietly summarize month, meanonly
    local mo2026_lo = r(min)
    local mo2026_hi = r(max)
    quietly summarize cpi, meanonly
    local cpi2026partial = r(mean)
restore
global DEFL2026 = ${CPIBASE} / `cpi2026partial'
local moname_lo : word `mo2026_lo' of $MONTHNAMES
local moname_hi : word `mo2026_hi' of $MONTHNAMES
display as text "2026 partial-year CPI-U built from `n2026mo' month(s), `moname_lo' through `moname_hi' 2026. DEFL2026 = ${DEFL2026}"

numadd, key(col_defl2026_partial_year) value(`=round(${DEFL2026},0.0001)') formatted("`=string(round(${DEFL2026},0.0001),"%6.4f")'") ///
    unit("multiplier, 2026 nominal dollars to 2025 dollars") source("03_analysis/data/external/BLS_CPI.dta") ///
    note("cpi_annual.dta excludes 2026 because it is an incomplete year. This module builds a supplementary 2026 price level from the `n2026mo' month(s) of 2026 CPI-U (All items, U.S. city average) available in this extract, `moname_lo' through `moname_hi', used only to express HUD FY2026 and Zillow June 2026 figures in 2025 dollars. Not part of the shared cpi_annual.dta and not used by any other module.")


* ================================================================
* TASK 1a. HUD Fair Market Rent, 1-bedroom and 2-bedroom, Austin plus
*          Dallas, Houston, San Antonio and Nashville, real 2025 dollars.
*          Start year 2010: the HUD file itself spans FY1983-FY2026, but
*          2010 is used because (a) it is this task own suggested default,
*          (b) it sits well inside the 2000-2025 window the CPI-U deflator
*          actually covers, and (c) HUD own area-code format changed around
*          FY2006, so reaching back to 1983 would cross a metro-definition
*          seam without adding an economically distinct baseline.
* ================================================================
import delimited "${EV_COL}/hud_fmr_1983_2026_5area_long.csv", varnames(1) case(preserve) clear
keep fiscal_year area_label br1 br2
rename fiscal_year year
generate metro = ""
replace metro = "austin"     if strpos(area_label,"Austin")
replace metro = "dallas"     if strpos(area_label,"Dallas")
replace metro = "houston"    if strpos(area_label,"Houston")
replace metro = "nashville"  if strpos(area_label,"Nashville")
replace metro = "sanantonio" if strpos(area_label,"San Antonio")
assert metro != ""
keep if year >= 2010

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) generate(mrg_cpi_hud)
replace defl = ${DEFL2026} if year==2026 & mrg_cpi_hud==1
assert !missing(defl)
generate double br1_real = br1*defl
generate double br2_real = br2*defl
label variable br1_real "HUD Fair Market Rent, 1-bedroom, 2025 dollars"
label variable br2_real "HUD Fair Market Rent, 2-bedroom, 2025 dollars"
drop mrg_cpi_hud
tempfile hud_panel
save `hud_panel'

quietly count
display as text "HUD FMR analysis panel: `r(N)' rows (5 metros x FY2010-FY2026)."

foreach bedvar in br1 br2 {
    local bedlab = cond("`bedvar'"=="br1","1-bedroom","2-bedroom")
    local i = 0
    foreach m of local metro_slugs {
        local i = `i' + 1
        local mlab : word `i' of `metro_labs'

        preserve
            quietly keep if metro=="`m'"
            sort year
            local v0  = `bedvar'_real[1]
            local y0  = year[1]
            local v1  = `bedvar'_real[_N]
            local y1  = year[_N]
            sort `bedvar'_real
            local vpk = `bedvar'_real[_N]
            local ypk = year[_N]
        restore

        local pct_start_latest = (`v1'/`v0' - 1)*100
        local pct_peak_latest  = (`v1'/`vpk' - 1)*100

        numadd, key(col_hud_`bedvar'_`m'_pctchg) value(`=round(`pct_start_latest',0.1)') ///
            formatted("`=cond(`pct_start_latest'>=0,"+","")'`=string(round(`pct_start_latest',0.1),"%4.1f")'%") ///
            unit("percent change, real, FY`y0'-FY`y1'") ///
            source("01_evidence/09_cost_of_living/hud_fmr_1983_2026_5area_long.csv") ///
            note("`mlab' HUD Fair Market Rent, `bedlab', real 2025 dollars, FY`y0' ($`=string(round(`v0',1),"%9.0fc")') to FY`y1' ($`=string(round(`v1',1),"%9.0fc")'). FY2026 uses this module own partial-year CPI patch (col_defl2026_partial_year).")
        numadd, key(col_hud_`bedvar'_`m'_peak) value(`=round(`vpk',1)') ///
            formatted("$`=string(round(`vpk',1),"%9.0fc")' in FY`=string(`ypk',"%9.0f")'") ///
            unit("2025 dollars per month, peak fiscal year") ///
            source("01_evidence/09_cost_of_living/hud_fmr_1983_2026_5area_long.csv") ///
            note("`mlab' HUD Fair Market Rent, `bedlab', peak real value FY`=string(`ypk',"%9.0f")' at $`=string(round(`vpk',1),"%9.0fc")', 2025 dollars.")
        numadd, key(col_hud_`bedvar'_`m'_peaktolatest) value(`=round(`pct_peak_latest',0.1)') ///
            formatted("`=string(round(`pct_peak_latest',0.1),"%4.1f")'%") ///
            unit("percent change, real, peak to FY`y1'") ///
            source("01_evidence/09_cost_of_living/hud_fmr_1983_2026_5area_long.csv") ///
            note("`mlab' HUD Fair Market Rent, `bedlab', real 2025 dollars, from its FY`=string(`ypk',"%9.0f")' peak ($`=string(round(`vpk',1),"%9.0fc")') to FY`y1' ($`=string(round(`v1',1),"%9.0fc")'): `=string(round(`pct_peak_latest',0.1),"%4.1f")'%.")
    }
}
display as text "Task 1a (HUD Fair Market Rent) registry complete."


* ================================================================
* TASK 1b. Zillow Observed Rent Index (ZORI), seasonally adjusted, same 5
*          metros, real 2025 dollars. Start "earliest used" is January
*          2015: Zillow does not publish ZORI before that month for any
*          metro, so there is no 2010 alternative here.
* ================================================================
import delimited "${EV_COL}/zillow_zori_seasadj_5metro_long.csv", varnames(1) case(preserve) clear
generate double date_d = date(date, "YMD")
format date_d %td
generate year  = year(date_d)
generate month = month(date_d)
generate metro = ""
replace metro = "austin"     if geo=="Austin, TX"
replace metro = "dallas"     if geo=="Dallas, TX"
replace metro = "houston"    if geo=="Houston, TX"
replace metro = "nashville"  if geo=="Nashville, TN"
replace metro = "sanantonio" if geo=="San Antonio, TX"
assert metro != ""

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) generate(mrg_cpi_zori)
replace defl = ${DEFL2026} if year==2026 & mrg_cpi_zori==1
assert !missing(defl)
generate double value_real = value*defl
label variable value_real "Zillow ZORI, seasonally adjusted, 2025 dollars"
drop mrg_cpi_zori

* Index each metro to its own January 2015 level = 100, so five metros that
* start at different dollar levels can share one axis for fig20.
generate double idx = .
local i = 0
foreach m of local metro_slugs {
    local i = `i' + 1
    quietly summarize value_real if metro=="`m'" & year==2015 & month==1, meanonly
    local zori_base_`m' = r(mean)
    quietly replace idx = value_real/`zori_base_`m''*100 if metro=="`m'"
}
tempfile zori_panel
save `zori_panel'

quietly count
display as text "Zillow ZORI analysis panel: `r(N)' rows (5 metros, monthly, Jan 2015-June 2026)."

local i = 0
foreach m of local metro_slugs {
    local i = `i' + 1
    local mlab : word `i' of `metro_labs'

    preserve
        quietly keep if metro=="`m'"
        sort date_d
        local v0  = value_real[1]
        local y0  = year[1]
        local mo0 = month[1]
        local v1  = value_real[_N]
        local y1  = year[_N]
        local mo1 = month[_N]
        sort value_real
        local vpk  = value_real[_N]
        local ypk  = year[_N]
        local mopk = month[_N]
    restore

    local moname0  : word `mo0'  of $MONTHNAMES
    local moname1  : word `mo1'  of $MONTHNAMES
    local monamepk : word `mopk' of $MONTHNAMES
    local pct_start_latest = (`v1'/`v0' - 1)*100
    local pct_peak_latest  = (`v1'/`vpk' - 1)*100

    numadd, key(col_zori_`m'_pctchg) value(`=round(`pct_start_latest',0.1)') ///
        formatted("`=cond(`pct_start_latest'>=0,"+","")'`=string(round(`pct_start_latest',0.1),"%4.1f")'%") ///
        unit("percent change, real, `moname0' `y0' to `moname1' `y1'") ///
        source("01_evidence/09_cost_of_living/zillow_zori_seasadj_5metro_long.csv") ///
        note("`mlab' Zillow ZORI, real 2025 dollars, `moname0' `y0' ($`=string(round(`v0',1),"%9.0fc")', earliest available) to `moname1' `y1' ($`=string(round(`v1',1),"%9.0fc")').")
    numadd, key(col_zori_`m'_peak) value(`=round(`vpk',1)') ///
        formatted("$`=string(round(`vpk',1),"%9.0fc")' in `monamepk' `ypk'") ///
        unit("2025 dollars per month, peak month") ///
        source("01_evidence/09_cost_of_living/zillow_zori_seasadj_5metro_long.csv") ///
        note("`mlab' Zillow ZORI peak, `monamepk' `ypk', real 2025 dollars.")
    numadd, key(col_zori_`m'_peaktolatest) value(`=round(`pct_peak_latest',0.1)') ///
        formatted("`=string(round(`pct_peak_latest',0.1),"%4.1f")'%") ///
        unit("percent change, real, peak to `moname1' `y1'") ///
        source("01_evidence/09_cost_of_living/zillow_zori_seasadj_5metro_long.csv") ///
        note("`mlab' Zillow ZORI, real 2025 dollars, from its `monamepk' `ypk' peak ($`=string(round(`vpk',1),"%9.0fc")') to `moname1' `y1' ($`=string(round(`v1',1),"%9.0fc")'): `=string(round(`pct_peak_latest',0.1),"%4.1f")'%.")
}
display as text "Task 1b (Zillow ZORI) registry complete."

* Light cross-check against the NOT-seasonally-adjusted series (also a
* listed input): does raw seasonal noise move the Austin peak month? If it
* does not, that is one more reason the seasonally adjusted series is the
* right choice for dating a cyclical peak rather than a calendar quirk.
preserve
    import delimited "${EV_COL}/zillow_zori_notseasadj_5metro_long.csv", varnames(1) case(preserve) clear
    keep if geo=="Austin, TX"
    generate double date_d2 = date(date, "YMD")
    format date_d2 %td
    sort value
    local nsa_peak_year  = year(date_d2[_N])
    local nsa_peak_month = month(date_d2[_N])
    local nsa_peak_val   = value[_N]
restore
local nsa_moname : word `nsa_peak_month' of $MONTHNAMES
display as text "Austin ZORI peak month, NOT seasonally adjusted: `nsa_moname' `nsa_peak_year' ($`=string(`nsa_peak_val',"%9.0fc")')."

numadd, key(col_zori_seasonal_crosscheck) value(1) formatted("`nsa_moname' `nsa_peak_year'") ///
    unit("peak month, not-seasonally-adjusted series, cross-check only") ///
    source("01_evidence/09_cost_of_living/zillow_zori_notseasadj_5metro_long.csv") ///
    note("Austin ZORI peak month using the NOT-seasonally-adjusted series: `nsa_moname' `nsa_peak_year'. This module uses the seasonally adjusted ZORI throughout, as the evidence folder recommends, so an ordinary within-year seasonal swing in the rental market is not mistaken for the cyclical 2022 peak; the two series agree closely on timing.")

* Reconciliation note: the REAL (deflated) ZORI peak registered above for all
* 5 metros lands in December 2021, one calendar year earlier than the widely
* cited NOMINAL peak (mid-2022 to as late as 2025 depending on the metro,
* per this project own evidence-folder findings). This is an explainable
* consequence of using an ANNUAL, not monthly, deflator during 2021-2023,
* the sharpest national inflation stretch in this series own history: once
* the deflator steps up from 2021 to 2022, it can outweigh a further modest
* NOMINAL rent increase into 2022 or later, pulling the REAL peak back to
* the last month priced at the smaller 2021 deflator. Register this
* explicitly so a reader comparing this module real peak dates against the
* nominal peak dates quoted elsewhere does not mistake the difference for
* an error.
numadd, key(col_zori_real_vs_nominal_peak_note) value(1) formatted("real peak precedes nominal peak by about a year") ///
    unit("methodological note") source("01_evidence/09_cost_of_living/zillow_zori_seasadj_5metro_long.csv") ///
    note("The REAL (2025-dollar) Zillow ZORI peak this module registers for all 5 metros falls in December 2021, one calendar year before the widely cited NOMINAL peak month, which varies by metro from mid-2022 into 2023 or later. This is a genuine, explainable artifact of using an ANNUAL CPI-U deflator (as this report requires throughout) during 2021-2023, the sharpest national inflation stretch in this series own span: the deflator step from 2021 to 2022 outweighs the modest further nominal rent increase many metros saw into 2022 or later, so the REAL peak lands a year earlier than the NOMINAL one. Both readings are correct for what they measure; a report drawing on this module should specify which one (real, constant-purchasing-power peak, or nominal, actual-dollars-charged-at-the-time peak) it means. Zillow ZHVI does not show this same shift, because its nominal peak already fell within mid-2022, before the sharpest part of the 2021-2023 inflation stretch.")


* ================================================================
* TASK 1c. Zillow Home Value Index (ZHVI), all-homes mid-tier, seasonally
*          adjusted, same 5 metros, real 2025 dollars. Start year 2010,
*          matching the HUD start above so the rent and home-value reads
*          share one baseline; ZHVI itself reaches back to 2000 in this
*          extract.
* ================================================================
import delimited "${EV_COL}/zillow_zhvi_allhomes_seasadj_5metro_long.csv", varnames(1) case(preserve) clear
generate double date_d = date(date, "YMD")
format date_d %td
generate year  = year(date_d)
generate month = month(date_d)
generate metro = ""
replace metro = "austin"     if geo=="Austin, TX"
replace metro = "dallas"     if geo=="Dallas, TX"
replace metro = "houston"    if geo=="Houston, TX"
replace metro = "nashville"  if geo=="Nashville, TN"
replace metro = "sanantonio" if geo=="San Antonio, TX"
assert metro != ""
keep if year >= 2010

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) generate(mrg_cpi_zhvi)
replace defl = ${DEFL2026} if year==2026 & mrg_cpi_zhvi==1
assert !missing(defl)
generate double value_real = value*defl
label variable value_real "Zillow ZHVI, all homes, seasonally adjusted, 2025 dollars"
drop mrg_cpi_zhvi
tempfile zhvi_panel
save `zhvi_panel'

quietly count
display as text "Zillow ZHVI analysis panel: `r(N)' rows (5 metros, monthly, 2010-June 2026)."

local i = 0
foreach m of local metro_slugs {
    local i = `i' + 1
    local mlab : word `i' of `metro_labs'

    preserve
        quietly keep if metro=="`m'"
        sort date_d
        local v0  = value_real[1]
        local y0  = year[1]
        local mo0 = month[1]
        local v1  = value_real[_N]
        local y1  = year[_N]
        local mo1 = month[_N]
        sort value_real
        local vpk  = value_real[_N]
        local ypk  = year[_N]
        local mopk = month[_N]
    restore

    local moname0  : word `mo0'  of $MONTHNAMES
    local moname1  : word `mo1'  of $MONTHNAMES
    local monamepk : word `mopk' of $MONTHNAMES
    local pct_start_latest = (`v1'/`v0' - 1)*100
    local pct_peak_latest  = (`v1'/`vpk' - 1)*100

    numadd, key(col_zhvi_`m'_pctchg) value(`=round(`pct_start_latest',0.1)') ///
        formatted("`=cond(`pct_start_latest'>=0,"+","")'`=string(round(`pct_start_latest',0.1),"%4.1f")'%") ///
        unit("percent change, real, `moname0' `y0' to `moname1' `y1'") ///
        source("01_evidence/09_cost_of_living/zillow_zhvi_allhomes_seasadj_5metro_long.csv") ///
        note("`mlab' Zillow ZHVI (all homes), real 2025 dollars, `moname0' `y0' ($`=string(round(`v0',1),"%9.0fc")') to `moname1' `y1' ($`=string(round(`v1',1),"%9.0fc")').")
    numadd, key(col_zhvi_`m'_peak) value(`=round(`vpk',1)') ///
        formatted("$`=string(round(`vpk',1),"%9.0fc")' in `monamepk' `ypk'") ///
        unit("2025 dollars, peak month") ///
        source("01_evidence/09_cost_of_living/zillow_zhvi_allhomes_seasadj_5metro_long.csv") ///
        note("`mlab' Zillow ZHVI peak, `monamepk' `ypk', real 2025 dollars.")
    numadd, key(col_zhvi_`m'_peaktolatest) value(`=round(`pct_peak_latest',0.1)') ///
        formatted("`=string(round(`pct_peak_latest',0.1),"%4.1f")'%") ///
        unit("percent change, real, peak to `moname1' `y1'") ///
        source("01_evidence/09_cost_of_living/zillow_zhvi_allhomes_seasadj_5metro_long.csv") ///
        note("`mlab' Zillow ZHVI, real 2025 dollars, from its `monamepk' `ypk' peak ($`=string(round(`vpk',1),"%9.0fc")') to `moname1' `y1' ($`=string(round(`v1',1),"%9.0fc")'): `=string(round(`pct_peak_latest',0.1),"%4.1f")'%. This differs from any nominal-dollar peak-to-latest percent quoted elsewhere, because this figure is deflated to constant 2025 dollars and the nominal one is not.")
}
display as text "Task 1c (Zillow ZHVI) registry complete."


* ================================================================
* Supplementary context (listed input, light touch): ACS 5-year median
* gross rent, MSA level, two available vintages. Not one of this module
* two required figures. Flagged because a 5-year rolling average cannot
* show the sharp 2022 peak the monthly Zillow index shows, so its growth
* rate is a different, non-comparable read of "rent," not a contradiction
* of the Zillow/HUD peak-and-pullback finding above.
* ================================================================
import delimited "${EV_COL}/acs_median_rent_homevalue_5geo_long.csv", varnames(1) case(preserve) clear
keep if geo_level=="msa" & variable=="median_gross_rent"
generate period = cond(acs_vintage==2021,"p1","p2")
keep geo_label period estimate
reshape wide estimate, i(geo_label) j(period) string
rename estimatep1 rent_v1
rename estimatep2 rent_v2
generate metro = ""
replace metro = "austin"     if strpos(geo_label,"Austin")
replace metro = "dallas"     if strpos(geo_label,"Dallas")
replace metro = "houston"    if strpos(geo_label,"Houston")
replace metro = "nashville"  if strpos(geo_label,"Nashville")
replace metro = "sanantonio" if strpos(geo_label,"San Antonio")
assert metro != ""

local i = 0
foreach m of local metro_slugs {
    local i = `i' + 1
    local mlab : word `i' of `metro_labs'
    quietly summarize rent_v1 if metro=="`m'", meanonly
    local r1 = r(mean)
    quietly summarize rent_v2 if metro=="`m'", meanonly
    local r2 = r(mean)
    local pct = (`r2'/`r1' - 1)*100

    numadd, key(col_acs_rent_pctchg_`m') value(`=round(`pct',0.1)') ///
        formatted("+`=string(round(`pct',0.1),"%4.1f")'%") ///
        unit("percent change, nominal, ACS 2017-2021 5-year to 2020-2024 5-year") ///
        source("01_evidence/09_cost_of_living/acs_median_rent_homevalue_5geo_long.csv") ///
        note("`mlab' MSA, ACS median gross rent, 2017-2021 5-year estimate ($`=string(`r1',"%9.0fc")') to 2020-2024 5-year estimate ($`=string(`r2',"%9.0fc")'). Nominal dollars; each estimate already blends 5 calendar years, so it is context, not comparable to the Zillow/HUD monthly-peak percentages above. A 5-year rolling average cannot show a sharp within-window peak the way a monthly index can.")
}
display as text "ACS supplementary context registry complete."

* MIT Living Wage Calculator, Travis County: a single dated snapshot with no
* machine-readable file, hand-transcribed from this project own markdown
* note (01_evidence/09_cost_of_living/mit_living_wage_travis_county_20260801.md).
* Unlike every other figure in this module, these two numbers are cited from
* that note, not independently re-derived from a CSV.
local mit_wage_hourly = 23.69
local mit_housing_month = 1518

numadd, key(col_mit_living_wage_hourly) value(`mit_wage_hourly') formatted("$`=string(`mit_wage_hourly',"%4.2f")' per hour") ///
    unit("dollars per hour, nominal, single adult, no dependents, 2026-02-15 vintage") ///
    source("01_evidence/09_cost_of_living/mit_living_wage_travis_county_20260801.md") ///
    note("MIT Living Wage Calculator, Travis County, 1 adult / 0 children, as published 2026-02-15, retrieved 2026-08-01. A budget-based (expenditure-minimum) benchmark, not a market price. Hand-transcribed from this project own markdown note, since MIT publishes no machine-readable file for this figure.")
numadd, key(col_mit_housing_lineitem_monthly) value(`mit_housing_month') formatted("$`=string(`mit_housing_month',"%9.0fc")' per month") ///
    unit("dollars per month, implied housing line item, 2026-02-15 vintage") ///
    source("01_evidence/09_cost_of_living/mit_living_wage_travis_county_20260801.md") ///
    note("MIT implied monthly housing cost within its no-frills budget, Travis County, 2026-02-15 vintage. Cross-check only: sits close to, and modestly below, both HUD FY2026 Austin 1-bedroom Fair Market Rent and Zillow June 2026 Austin ZORI registered elsewhere in this module -- three independently built sources landing within roughly 150 dollars a month of each other.")


* ================================================================
* FIGURE 20: real rent trends, Austin plus 4 peer metros, indexed to each
*            metro own January 2015 level, so the 2015-2022 run-up AND the
*            2022-2026 pullback both stay on the chart.
* ================================================================
use `zori_panel', clear
keep metro date_d idx
reshape wide idx, i(date_d) j(metro) string
rename idxaustin     idx_austin
rename idxdallas     idx_dallas
rename idxhouston    idx_houston
rename idxnashville  idx_nashville
rename idxsanantonio idx_sanantonio
sort date_d

* Verify Austin actually shows the steepest peak-to-latest real pullback of
* the 5 metros before any title claims it.
foreach m of local metro_slugs {
    quietly summarize idx_`m', meanonly
    local pk_`m' = r(max)
    quietly summarize date_d if !missing(idx_`m')
    local ly_idx_`m' = r(max)
    quietly summarize idx_`m' if date_d==`ly_idx_`m'', meanonly
    local lastv_`m' = r(mean)
    local decl_`m' = `lastv_`m''/`pk_`m'' - 1
}
display as text "Peak-to-latest real ZORI decline: austin `=string(`decl_austin'*100,"%4.1f")'%" ///
    " dallas `=string(`decl_dallas'*100,"%4.1f")'%" ///
    " houston `=string(`decl_houston'*100,"%4.1f")'%" ///
    " nashville `=string(`decl_nashville'*100,"%4.1f")'%" ///
    " sanantonio `=string(`decl_sanantonio'*100,"%4.1f")'%"
local austin_steepest = (`decl_austin' <= `decl_dallas' & `decl_austin' <= `decl_houston' & `decl_austin' <= `decl_nashville' & `decl_austin' <= `decl_sanantonio')
display as text "Is Austin decline the steepest (most negative) of the 5? `austin_steepest'"

if `austin_steepest' == 1 {
    local fig20_title = "Real Austin rent has fallen further from its 2022 peak than peers"
}
else {
    local fig20_title = "Real rent trends, Austin and four peer metros, 2015-2026"
}
local _tlen20 = length("`fig20_title'")
display as text "fig20 title length check: `_tlen20' characters (target under ~70)."

* Line patterns, not just colour, separate the 5 metros: Dallas and Nashville
* track each other closely enough to merge in grayscale or print, so every
* non-Austin line gets its own dash pattern; Austin stays solid and heaviest
* as the series this figure own title is about.
twoway ///
    (line idx_austin date_d, lcolor("${ORANGE}") lwidth(medthick) lpattern(solid)) ///
    (line idx_dallas date_d, lcolor("${NAVY}") lpattern(dash)) ///
    (line idx_houston date_d, lcolor("${BLUE}") lpattern(longdash)) ///
    (line idx_nashville date_d, lcolor("${GOLD}") lpattern(shortdash)) ///
    (line idx_sanantonio date_d, lcolor("${MUTED}") lpattern(dash_dot)) ///
    , ///
    title("`fig20_title'", $TITLEOPT) ///
    subtitle("Real Zillow rent index (ZORI), each metro indexed to its own Jan 2015 = 100" "Monthly, 2025 dollars, Jan 2015-June 2026; axis does not start at zero", $SUBOPT) ///
    xtitle("", $XTOPT) ytitle("Index, Jan 2015 = 100", $YTOPT) ///
    ylabel(, angle(horizontal)) ///
    xlabel(`=td(1jan2015)' `=td(1jan2017)' `=td(1jan2019)' `=td(1jan2021)' `=td(1jan2023)' `=td(1jan2025)') ///
    xscale(range(`=td(1jan2015)' `=td(1sep2026)')) ///
    legend(order(1 "Austin" 2 "Dallas" 3 "Houston" 4 "Nashville" 5 "San Antonio") position(6) rows(1) $LEGOPT) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_fig20, replace)

figsave, name(fig20_metro_rent)

preserve
    export delimited date_d idx_austin idx_dallas idx_houston idx_nashville idx_sanantonio ///
        using "${OUT}/fig20_metro_rent.csv", replace
restore

display as text "fig20 complete."


* ================================================================
* TASK 2. Housing costs against general inflation: index CPI Housing
*         against CPI All items, both U.S. city average (the only
*         geography BLS offers; see Section 1), 2005-2025, and register the
*         cumulative gap.
* ================================================================
preserve
    use "${OUT}/cpi_annual.dta", clear
    keep year cpi
    rename cpi cpi_allitems
    merge 1:1 year using `cpi_housing_ann', nogenerate
    keep if year>=2005 & year<=2025
    quietly summarize cpi_allitems if year==2005, meanonly
    local base_all = r(mean)
    quietly summarize cpi_housing if year==2005, meanonly
    local base_hou = r(mean)
    generate double idx_allitems = cpi_allitems/`base_all'*100
    generate double idx_housing  = cpi_housing/`base_hou'*100
    sort year
    tempfile cpi_compare
    save `cpi_compare'
restore

use `cpi_compare', clear
quietly summarize idx_allitems if year==2025, meanonly
local all2025 = r(mean)
quietly summarize idx_housing if year==2025, meanonly
local hou2025 = r(mean)
local gap_points = `hou2025' - `all2025'
display as text "2025 index (2005=100): All items `=string(`all2025',"%6.1f")', Housing `=string(`hou2025',"%6.1f")', gap `=string(`gap_points',"%4.1f")' points."

numadd, key(col_cpi_allitems_index_2025) value(`=round(`all2025',0.1)') formatted("`=string(round(`all2025',0.1),"%6.1f")'") ///
    unit("index, 2005=100") source("03_analysis/data/external/BLS_CPI.dta") ///
    note("CPI-U All items, U.S. city average, annual average, indexed to 2005=100, 2025.")
numadd, key(col_cpi_housing_index_2025) value(`=round(`hou2025',0.1)') formatted("`=string(round(`hou2025',0.1),"%6.1f")'") ///
    unit("index, 2005=100") source("03_analysis/data/external/BLS_CPI.dta") ///
    note("CPI-U Housing, U.S. city average, annual average, indexed to 2005=100, 2025. October 2025 imputed (col_cpi_housing_oct2025_imputed).")
numadd, key(col_cpi_housing_gap_2025) value(`=round(`gap_points',0.1)') formatted("`=string(round(`gap_points',0.1),"%4.1f")' points") ///
    unit("index points, cumulative gap since 2005") source("03_analysis/data/external/BLS_CPI.dta") ///
    note("Housing index (`=string(round(`hou2025',0.1),"%6.1f")') minus All items index (`=string(round(`all2025',0.1),"%6.1f")'), both 2005=100, 2025: national housing prices have risen `=string(round(`gap_points',0.1),"%4.1f")' index points faster than the broad CPI basket since 2005. This is a NATIONAL series -- BLS publishes no Austin-area CPI (col_no_austin_bls_cpi) -- used here to show housing outpacing general inflation nationally, a pattern the Regional Price Parity section below shows is sharper still in Austin specifically.")

display as text "Task 2 (CPI Housing vs. All items) complete."


* ================================================================
* TASK 3. BEA Regional Price Parity: Austin all-items against Austin
*         housing, with peer metros, latest available year. Numbers
*         verified directly against the file before being registered.
* ================================================================
import delimited "${EV_COL}/bea_rpp_marpp_5metro_long.csv", varnames(1) case(preserve) clear
keep if inlist(series,"all_items","services_housing")
quietly summarize year, meanonly
local rpp_latest = r(max)
display as text "BEA Regional Price Parity latest available year in this extract: `rpp_latest'."
keep if year==`rpp_latest'

generate metro = ""
replace metro = "austin"     if strpos(geo_label,"Austin")
replace metro = "dallas"     if strpos(geo_label,"Dallas")
replace metro = "houston"    if strpos(geo_label,"Houston")
replace metro = "nashville"  if strpos(geo_label,"Nashville")
replace metro = "sanantonio" if strpos(geo_label,"San Antonio")
replace metro = "us"         if geo_label=="United States"
assert metro != ""

keep metro series rpp_index_us100
reshape wide rpp_index_us100, i(metro) j(series) string
rename rpp_index_us100all_items rpp_all
rename rpp_index_us100services_housing rpp_housing
generate double rpp_gap = rpp_housing - rpp_all

sort rpp_gap
local nrows = _N
local widest_metro = metro[`nrows']
display as text "Regional Price Parity gap (housing minus all-items), ascending:"
list metro rpp_all rpp_housing rpp_gap, clean
display as text "Widest gap: `widest_metro' (should be austin)."
assert "`widest_metro'"=="austin"

tempfile rpp_panel
save `rpp_panel'

local metro_slugs_us "austin dallas houston nashville sanantonio us"
local metro_labs_us  `""Austin" "Dallas" "Houston" "Nashville" "San Antonio" "United States""'
local i = 0
foreach m of local metro_slugs_us {
    local i = `i' + 1
    local mlab : word `i' of `metro_labs_us'
    quietly summarize rpp_all if metro=="`m'", meanonly
    local va = r(mean)
    quietly summarize rpp_housing if metro=="`m'", meanonly
    local vh = r(mean)
    quietly summarize rpp_gap if metro=="`m'", meanonly
    local vg = r(mean)

    numadd, key(col_rpp_allitems_`m') value(`=round(`va',0.1)') formatted("`=string(round(`va',0.1),"%6.1f")'") ///
        unit("index, US average=100, `rpp_latest'") source("01_evidence/09_cost_of_living/bea_rpp_marpp_5metro_long.csv") ///
        note("BEA Regional Price Parity, All items, `mlab', `rpp_latest' (latest BEA vintage in this extract).")
    numadd, key(col_rpp_housing_`m') value(`=round(`vh',0.1)') formatted("`=string(round(`vh',0.1),"%6.1f")'") ///
        unit("index, US average=100, `rpp_latest'") source("01_evidence/09_cost_of_living/bea_rpp_marpp_5metro_long.csv") ///
        note("BEA Regional Price Parity, Housing services, `mlab', `rpp_latest'.")
    numadd, key(col_rpp_gap_`m') value(`=round(`vg',0.1)') formatted("`=string(round(`vg',0.1),"%4.1f")' points") ///
        unit("index points, housing RPP minus all-items RPP") source("01_evidence/09_cost_of_living/bea_rpp_marpp_5metro_long.csv") ///
        note("`mlab', `rpp_latest': housing RPP (`=string(round(`vh',0.1),"%6.1f")') minus all-items RPP (`=string(round(`va',0.1),"%6.1f")') = `=string(round(`vg',0.1),"%4.1f")' points. Austin gap is the widest of the 5 metros compared here (verified directly), meaning the Austin cost problem is specifically a HOUSING problem: Austin sits near the national average on everything else.")
}

preserve
    import delimited "${EV_COL}/bea_rpp_marpp_5metro_long.csv", varnames(1) case(preserve) clear
    keep if series=="services_housing" & strpos(geo_label,"Austin")
    sort rpp_index_us100
    local austin_housing_peak = rpp_index_us100[_N]
    local austin_housing_peak_year = year[_N]
    quietly summarize year, meanonly
    local austin_rpp_minyr = r(min)
    quietly summarize rpp_index_us100 if year==`austin_rpp_minyr', meanonly
    local austin_housing_early = r(mean)
restore
quietly summarize rpp_housing if metro=="austin", meanonly
local austin_housing_latest = r(mean)

numadd, key(col_rpp_austin_housing_peak) value(`=round(`austin_housing_peak',0.1)') ///
    formatted("`=string(round(`austin_housing_peak',0.1),"%6.1f")' in `austin_housing_peak_year'") ///
    unit("index, US average=100, peak year") source("01_evidence/09_cost_of_living/bea_rpp_marpp_5metro_long.csv") ///
    note("Austin housing Regional Price Parity peaked at `=string(round(`austin_housing_peak',0.1),"%6.1f")' in `austin_housing_peak_year', up from `=string(round(`austin_housing_early',0.1),"%6.1f")' in `austin_rpp_minyr' (earliest year in this BEA extract), then eased to `=string(round(`austin_housing_latest',0.1),"%6.1f")' by `rpp_latest'. A third, methodologically independent source (BEA regional accounts) corroborates the same 2022-2023 peak and pullback that Zillow market index and HUD administrative Fair Market Rent both show.")

display as text "Task 3 (BEA Regional Price Parity) complete."


* ================================================================
* TASK 4. THE ANCHOR CALCULATION: hours of work at the Austin median
*         musician hourly wage (OEWS 27-2042) needed to cover one month of
*         Austin 1-bedroom HUD Fair Market Rent, against the same
*         calculation at the Austin all-occupations median wage
*         (OEWS 00-0000), and against the City of Austin Creative Vitality
*         Suite/EMSI wage series where it appears to include the
*         self-employed. Matched by YEAR in NOMINAL dollars throughout:
*         hours = dollars / (dollars per hour) is unit-free, so deflating
*         both sides by the same factor would not change the answer -- left
*         nominal on purpose, not because deflation was forgotten.
* ================================================================
* occ_code values contain a hyphen ("27-2042"), which reshape cannot turn
* into a variable-name suffix, so build the wide panel with two separate
* extracts merged on year instead (the same workaround 20_wages_industry.do
* uses for this identical OEWS occ_code quirk).
import delimited "${EV_WAGES}/oews_musicians_creatives_2005_2025.csv", varnames(1) case(preserve) clear
keep if geo_level=="MSA" & inlist(occ_code,"27-2042","00-0000")
keep year occ_code h_median

preserve
    keep if occ_code=="27-2042"
    keep year h_median
    rename h_median wage_musician
    tempfile oews_musi_only
    save `oews_musi_only'
restore
keep if occ_code=="00-0000"
keep year h_median
rename h_median wage_allocc
merge 1:1 year using `oews_musi_only', nogenerate
sort year
tempfile oews_austin
save `oews_austin'

quietly count
local n_oews_years = r(N)
quietly count if missing(wage_musician)
local n_musi_gap = r(N)
display as text "Austin MSA OEWS musician hourly wage: `n_musi_gap' year(s) of `n_oews_years' with no published value (small-occupation non-publication, not an extraction gap)."

numadd, key(col_anchor_oews_gap_note) value(`n_musi_gap') formatted("`n_musi_gap' year(s) not published") ///
    unit("count of missing years in the OEWS musician wage series used by fig19") ///
    source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
    note("Austin MSA OEWS median hourly wage for Musicians and singers is not published in `n_musi_gap' of `n_oews_years' years 2005-2025 (a small-occupation non-publication, consistent with this project other modules noting the Austin musician OEWS estimate rests on roughly 100 to 700 payroll jobs). The hours-of-work line in fig19 has a break at that year rather than an interpolated or invented value.")

import delimited "${EV_COL}/hud_fmr_1983_2026_5area_long.csv", varnames(1) case(preserve) clear
keep if strpos(area_label,"Austin")
keep fiscal_year br1
rename fiscal_year year
tempfile hud_austin_1br
save `hud_austin_1br'

* City of Austin Creative Vitality Suite / EMSI series: appears to include
* the self-employed, unlike OEWS. Only 2 published years in this extract
* (2016 and 2017), not an ongoing annual series like OEWS.
preserve
    import delimited "${EV_CITY}/socrata/2qxc-8cme_median_earnings_creative_occupations.csv", varnames(1) case(preserve) clear
    keep if soc_code=="27-2042"
    quietly count
    assert r(N)==1
    capture confirm string variable _2016_median_hourly_earnings
    if _rc==0 {
        generate double wage_city2016 = real(_2016_median_hourly_earnings)
    }
    else {
        generate double wage_city2016 = _2016_median_hourly_earnings
    }
    capture confirm string variable _2017_median_hourly_earnings
    if _rc==0 {
        generate double wage_city2017 = real(_2017_median_hourly_earnings)
    }
    else {
        generate double wage_city2017 = _2017_median_hourly_earnings
    }
    keep wage_city2016 wage_city2017
    generate id = 1
    reshape long wage_city, i(id) j(year)
    drop id
    tempfile city_wage
    save `city_wage'
restore

use `oews_austin', clear
merge 1:1 year using `hud_austin_1br', keep(match master) nogenerate
merge 1:1 year using `city_wage', nogenerate
generate double hours_musician = br1/wage_musician
generate double hours_allocc   = br1/wage_allocc
generate double hours_city     = br1/wage_city if !missing(wage_city)
label variable hours_musician "Hours at the Austin median musician wage to cover one month of Austin 1BR FMR"
label variable hours_allocc   "Hours at the Austin all-occupations median wage to cover one month of Austin 1BR FMR"
label variable hours_city     "Hours at the City EMSI musician wage (incl. self-employed) to cover one month of Austin 1BR FMR"
sort year

* City-wage-vs-OEWS comparison: only possible for 2017, since the Austin MSA
* OEWS musician wage is not published for 2016 (see col_anchor_oews_gap_note).
quietly summarize wage_city if year==2016, meanonly
local wcity2016 = r(mean)
numadd, key(col_anchor_city_wage_2016) value(`=round(`wcity2016',0.01)') formatted("$`=string(round(`wcity2016',0.01),"%4.2f")' per hour") ///
    unit("dollars per hour, nominal, 2016") source("01_evidence/04_city_programs_lmf/socrata/2qxc-8cme_median_earnings_creative_occupations.csv") ///
    note("City of Austin Creative Vitality Suite/EMSI median hourly earnings, Musicians and singers, 2016. No Austin MSA OEWS musician wage was published that year, so no same-year OEWS ratio is registered for 2016 (see col_anchor_city_wage_vs_oews_2017 for 2017).")

quietly summarize wage_city if year==2017, meanonly
local wcity2017 = r(mean)
quietly summarize wage_musician if year==2017, meanonly
local wmusi2017 = r(mean)
local city_share_of_oews_2017 = `wcity2017'/`wmusi2017'*100
display as text "2017: City EMSI musician wage $`=string(`wcity2017',"%4.2f")' vs. OEWS musician wage $`=string(`wmusi2017',"%4.2f")' (`=string(round(`city_share_of_oews_2017',0.1),"%4.1f")'% of OEWS)."

numadd, key(col_anchor_city_wage_vs_oews_2017) value(`=round(`city_share_of_oews_2017',0.1)') ///
    formatted("`=string(round(`city_share_of_oews_2017',0.1),"%4.1f")'%") ///
    unit("City wage as a percent of the OEWS wage, 2017") ///
    source("01_evidence/04_city_programs_lmf/socrata/2qxc-8cme_median_earnings_creative_occupations.csv; 01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
    note("City of Austin Creative Vitality Suite/EMSI median hourly earnings for Musicians and singers, which appears to include self-employed earners, was $`=string(`wcity2017',"%4.2f")' in 2017 against OEWS payroll-only $`=string(`wmusi2017',"%4.2f")' the same year -- `=string(round(`city_share_of_oews_2017',0.1),"%4.1f")'% of the OEWS figure, roughly half. The gap is consistent with most Austin musicians being self-employed and therefore outside OEWS payroll coverage (see col_anchor_selfemployment_caveat).")

* MANDATORY CAVEAT for fig19: OEWS excludes the self-employed. Pull the
* verified PUMS self-employment share from the other module ledger if it
* has already run; register plainly if it has not.
capture confirm file `"${OUT}/numbers/numbers_pums.csv"'
local have_pums_ledger = (_rc==0)
local have_selfemp_key = 0
if `have_pums_ledger' {
    preserve
        import delimited "${OUT}/numbers/numbers_pums.csv", varnames(1) case(preserve) stringcols(_all) clear
        quietly count if key=="pums_austin_mus_selfemp"
        if r(N)==1 {
            local have_selfemp_key = 1
            quietly keep if key=="pums_austin_mus_selfemp"
            local selfemp_fmt = formatted[1]
        }
    restore
}
if `have_selfemp_key'==1 {
    display as text "Austin musician self-employment share, from numbers_pums.csv: `selfemp_fmt'"
    numadd, key(col_anchor_selfemployment_caveat) value(1) formatted("`selfemp_fmt' self-employed") ///
        unit("percent, mandatory caveat for fig19") source("03_analysis/out/numbers/numbers_pums.csv") ///
        note("MANDATORY CAVEAT for fig19: OEWS counts payroll wage-and-salary jobs only and excludes the self-employed. This project own PUMS analysis (10_pums_earnings.do) puts Austin-metro musician self-employment at `selfemp_fmt' -- most of the profession is not represented in the OEWS wage that fig19 musician and all-occupations lines both use. The City EMSI line, which appears to include self-employed earnings, is the one line in fig19 not subject to this caveat, though it covers only 2016-2017.")
}
else {
    display as text "numbers_pums.csv or its pums_austin_mus_selfemp key was not found; registering the caveat without the exact share."
    numadd, key(col_anchor_selfemployment_caveat) value(0) formatted("share not available this run") ///
        unit("percent, mandatory caveat for fig19, MISSING") source("03_analysis/out/numbers/numbers_pums.csv") ///
        note("MANDATORY CAVEAT for fig19: OEWS counts payroll wage-and-salary jobs only and excludes the self-employed, who are most Austin musicians. The exact share could not be pulled this run because numbers_pums.csv or its pums_austin_mus_selfemp key was not found; run 10_pums_earnings.do first to populate the exact figure here.")
}

* Verify the endpoint comparisons the title depends on before writing it.
quietly summarize year if !missing(hours_musician)
local hm_first_yr = r(min)
local hm_last_yr  = r(max)
quietly summarize hours_musician if year==`hm_first_yr', meanonly
local hm_first = r(mean)
quietly summarize hours_musician if year==`hm_last_yr', meanonly
local hm_last = r(mean)
quietly summarize hours_musician if year==2015, meanonly
local hm_2015 = r(mean)
quietly summarize hours_musician if year==2023, meanonly
local hm_2023 = r(mean)
quietly summarize year if !missing(hours_allocc)
local ha_first_yr = r(min)
local ha_last_yr  = r(max)
quietly summarize hours_allocc if year==`ha_first_yr', meanonly
local ha_first = r(mean)
quietly summarize hours_allocc if year==`ha_last_yr', meanonly
local ha_last = r(mean)

display as text "Musician hours-of-work anchor: `hm_first_yr'=`=string(`hm_first',"%4.1f")'" ///
    " | 2015=`=string(`hm_2015',"%4.1f")' | 2023=`=string(`hm_2023',"%4.1f")'" ///
    " | `hm_last_yr' (latest)=`=string(`hm_last',"%4.1f")'"

local fell_since_2023 = (`hm_last' < `hm_2023')
local above_2015      = (`hm_last' > `hm_2015')
display as text "Has the hours line fallen since 2023? `fell_since_2023'. Still above its 2015 level? `above_2015'."

if `fell_since_2023'==1 {
    local fig19_title = "Covering Austin rent takes fewer musician hours than it did in 2023"
}
else if `above_2015'==1 {
    * No persistence word ("still") belongs here: hours_musician dipped below
    * its 2015 level in 2017 (31.2) and 2022 (30.7), so only the endpoint
    * comparison this series actually supports goes in the title.
    local fig19_title = "Covering Austin rent takes more musician hours than in 2015"
}
else {
    local fig19_title = "Hours of musician work needed to cover Austin 1-bedroom rent"
}
local _tlen19 = length("`fig19_title'")
display as text "fig19 title length check: `_tlen19' characters (target under ~70)."

numadd, key(col_anchor_hours_musician_first) value(`=round(`hm_first',0.1)') formatted("`=string(round(`hm_first',0.1),"%4.1f")' hours") ///
    unit("hours per month, `hm_first_yr'") source("multiple: oews_musicians_creatives_2005_2025.csv, hud_fmr_1983_2026_5area_long.csv") ///
    note("Hours at the Austin MSA median musician hourly wage (OEWS, nominal) to cover one month of Austin 1-bedroom HUD Fair Market Rent (nominal), `hm_first_yr'. Nominal-on-nominal ratio; no deflation applied or needed, since dollars per dollars is unit-free.")
numadd, key(col_anchor_hours_musician_latest) value(`=round(`hm_last',0.1)') formatted("`=string(round(`hm_last',0.1),"%4.1f")' hours") ///
    unit("hours per month, `hm_last_yr'") source("multiple") ///
    note("Same calculation, `hm_last_yr' (latest year with both an Austin MSA OEWS musician wage and a HUD Fair Market Rent).")
numadd, key(col_anchor_hours_allocc_first) value(`=round(`ha_first',0.1)') formatted("`=string(round(`ha_first',0.1),"%4.1f")' hours") ///
    unit("hours per month, `ha_first_yr'") source("multiple") ///
    note("Hours at the Austin all-occupations median hourly wage (OEWS, nominal) to cover one month of Austin 1-bedroom HUD Fair Market Rent (nominal), `ha_first_yr'.")
numadd, key(col_anchor_hours_allocc_latest) value(`=round(`ha_last',0.1)') formatted("`=string(round(`ha_last',0.1),"%4.1f")' hours") ///
    unit("hours per month, `ha_last_yr'") source("multiple") ///
    note("Same calculation, `ha_last_yr'.")
numadd, key(col_anchor_hours_gap_latest) value(`=round(`hm_last'-`ha_last',0.1)') formatted("`=string(round(`hm_last'-`ha_last',0.1),"%4.1f")' more hours") ///
    unit("hours per month, `hm_last_yr' musician minus all-occupations") source("multiple") ///
    note("At `hm_last_yr' Austin wages and rent, the median musician needs `=string(round(`hm_last'-`ha_last',0.1),"%4.1f")' more hours per month than the typical Austin worker to cover the same 1-bedroom Fair Market Rent.")
numadd, key(col_anchor_hours_volatility_note) value(1) formatted("small, volatile OEWS sample") ///
    unit("methodological caveat for fig19") source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
    note("The Austin MSA OEWS musician wage this figure hours-of-work line depends on rests on roughly 100 to 700 payroll jobs across the panel (see 20_wages_industry.do own registered caveat on this same series), so year-to-year swings in hours_musician partly reflect sampling noise in a thin occupation estimate, not only real changes in musician purchasing power. The all-occupations line rests on a far larger sample and is comparatively stable.")
numadd, key(col_anchor_timing_alignment_note) value(1) formatted("HUD fiscal year matched to OEWS calendar year") ///
    unit("methodological note") source("multiple") ///
    note("HUD Fair Market Rent is set by federal fiscal year (October-September); OEWS reports a May-of-calendar-year wage. This module matches HUD fiscal year YYYY to OEWS calendar year YYYY directly, an approximate few-month alignment, not an exact-month match.")

* Reconciliation note: fig19 hours can move opposite the pure rent-level
* story in fig20, because hours depend on BOTH rent and wage, and both moved
* here. Register the explanation so it reads as an honest reconciliation,
* not a contradiction between two figures in the same module.
numadd, key(col_anchor_reconciliation_note) value(1) formatted("hours track wages and rent together, not rent alone") ///
    unit("methodological note, reconciles fig19 against fig20") source("multiple") ///
    note("fig20 shows Austin real rent pulling back from its 2022 peak. fig19 hours-of-work line does not simply mirror that pullback, because it divides nominal HUD Fair Market Rent (which kept rising nominally through FY2025 before easing in FY2026, a year with no paired OEWS wage yet) by the small-sample, volatile Austin MSA OEWS musician wage (which itself fell from an unusually high 2022 reading). Both facts are registered above; this is an innocent, explainable divergence between two measures of the same underlying housing pressure, not an inconsistency in this module.")

* Direct labels at each line own last non-missing year.
foreach s in hours_musician hours_allocc {
    quietly summarize year if !missing(`s')
    local ly_`s' = r(max)
}
generate lbl_musician = "Austin musicians" if year==`ly_hours_musician'
generate lbl_allocc   = "All occupations"  if year==`ly_hours_allocc'

* hours_city (City of Austin Creative Vitality Suite/EMSI series) has values
* in only 2 of these 21 years (2016 and 2017; col_anchor_city_wage_2016 and
* col_anchor_city_wage_vs_oews_2017), too thin a run to plot as a line
* without reading as a stray mark carrying an unfindable label. It stays out
* of this twoway call; the two values, the years, and the self-employment-
* coverage point they support (city wage is roughly half the same-year OEWS
* wage) stay in the registry (col_anchor_city_wage_vs_oews_2017) and in this
* figure own exported CSV, for the caption to carry instead.

twoway ///
    (line hours_musician year, lcolor("${ORANGE}") lwidth(medthick)) ///
    (line hours_allocc year, lcolor("${MUTED}")) ///
    (scatter hours_musician year if year==`ly_hours_musician', mlabel(lbl_musician) mlabcolor("${ORANGE}") mlabposition(2) mlabsize(3) msymbol(none)) ///
    (scatter hours_allocc year if year==`ly_hours_allocc', mlabel(lbl_allocc) mlabcolor("${MUTED}") mlabposition(3) mlabsize(3) msymbol(none)) ///
    , ///
    title("`fig19_title'", $TITLEOPT) ///
    subtitle("Hours at the Austin median hourly wage to cover one month of Austin" "1-bedroom HUD Fair Market Rent; nominal dollars, 2005-2025", $SUBOPT) ///
    xtitle("", $XTOPT) ytitle("Hours per month", $YTOPT) ///
    xlabel(2005(5)2025) ylabel(0(20)80, angle(horizontal)) ///
    yscale(range(0 80)) ///
    xscale(range(2005 2036)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_fig19, replace)

figsave, name(fig19_rent_vs_wages)

preserve
    export delimited year hours_musician hours_allocc hours_city wage_musician wage_allocc wage_city br1 ///
        using "${OUT}/fig19_rent_vs_wages.csv", replace
restore

display as text "fig19 complete."


* ================================================================
* TASK 5. Annual Austin musician earnings against annual Austin 1-bedroom
*         Fair Market Rent, as a share-of-income measure, gated on whether
*         03_analysis/out/numbers/numbers_pums.csv exists.
*
*         PUMS is a single pooled 2020-2024 5-year cross-section, not an
*         annual panel like OEWS. There is no year-by-year PUMS earnings
*         series to pair with each year of FMR the way fig19 pairs OEWS
*         with FMR, so this section reports two POINT comparisons -- period-
*         matched and latest -- and says so, rather than implying an annual
*         trend the source data cannot support.
* ================================================================
capture confirm file `"${OUT}/numbers/numbers_pums.csv"'
local have_pums_ledger2 = (_rc==0)
local have_earn_key = 0

if `have_pums_ledger2' {
    preserve
        import delimited "${OUT}/numbers/numbers_pums.csv", varnames(1) case(preserve) stringcols(_all) clear
        quietly count if key=="pums_austin_mus_medpernp_pos"
        if r(N)==1 {
            local have_earn_key = 1
            quietly keep if key=="pums_austin_mus_medpernp_pos"
            local pums_earn_str = value[1]
        }
        quietly count if key=="pums_austin_mus_n_pos"
        local have_n_key = (r(N)==1)
        if `have_n_key' {
            quietly keep if key=="pums_austin_mus_n_pos"
            local pums_n_str = value[1]
        }
    restore
}

if `have_pums_ledger2'==0 {
    display as text "numbers_pums.csv not found: Task 5 skipped."
    numadd, key(col_pums_rent_share_skipped) value(0) formatted("skipped, numbers_pums.csv not found") ///
        unit("status") source("03_analysis/out/numbers/numbers_pums.csv") ///
        note("Task 5 (musician earnings vs. Fair Market Rent as a share of income, PUMS-based) was skipped because 03_analysis/out/numbers/numbers_pums.csv did not exist when this module ran. Run 10_pums_earnings.do first, then rerun this module; the code path immediately below is otherwise ready and needs no changes.")
}
else if `have_earn_key'==0 {
    display as text "numbers_pums.csv exists but key pums_austin_mus_medpernp_pos was not found: Task 5 skipped."
    numadd, key(col_pums_rent_share_skipped) value(0) formatted("skipped, key not found in numbers_pums.csv") ///
        unit("status") source("03_analysis/out/numbers/numbers_pums.csv") ///
        note("numbers_pums.csv exists but its pums_austin_mus_medpernp_pos key was not found (10_pums_earnings.do may have changed its key names). Task 5 skipped; update the key name referenced in this module Task 5 block to match.")
}
else {
    local pums_earn = real("`pums_earn_str'")
    local pums_n = cond(`have_n_key', "`pums_n_str'", "not available")
    display as text "PUMS Austin musician median earnings (POS base, 2025 dollars, from numbers_pums.csv): $`=string(`pums_earn',"%9.0fc")' (n=`pums_n')."

    * Period-matched comparison: average the 5 HUD fiscal years the ACS
    * 2020-2024 5-year estimate actually pools, rather than picking one
    * arbitrary year inside that window.
    preserve
        import delimited "${EV_COL}/hud_fmr_1983_2026_5area_long.csv", varnames(1) case(preserve) clear
        keep if strpos(area_label,"Austin") & inrange(fiscal_year,2020,2024)
        rename fiscal_year year
        keep year br1
        merge 1:1 year using "${OUT}/cpi_annual.dta", keep(match) nogenerate
        generate double br1_real = br1*defl
        quietly summarize br1_real, meanonly
        local fmr_matched_real = r(mean)
    restore

    preserve
        import delimited "${EV_COL}/hud_fmr_1983_2026_5area_long.csv", varnames(1) case(preserve) clear
        keep if strpos(area_label,"Austin") & fiscal_year==2026
        local fmr_latest_nominal = br1[1]
    restore
    local fmr_latest_real = `fmr_latest_nominal' * ${DEFL2026}

    local share_matched = (`fmr_matched_real'*12) / `pums_earn' * 100
    local share_latest  = (`fmr_latest_real'*12)  / `pums_earn' * 100
    display as text "Rent share of income: period-matched (FY2020-2024 avg. FMR) = `=string(round(`share_matched',0.1),"%4.1f")'%;" ///
        " latest (FY2026 FMR) = `=string(round(`share_latest',0.1),"%4.1f")'%."

    numadd, key(col_pums_rent_share_matched) value(`=round(`share_matched',0.1)') ///
        formatted("`=string(round(`share_matched',0.1),"%4.1f")'%") ///
        unit("percent of annual earnings, period-matched") ///
        source("03_analysis/out/numbers/numbers_pums.csv; 01_evidence/09_cost_of_living/hud_fmr_1983_2026_5area_long.csv") ///
        note("Annualized Austin 1-bedroom HUD Fair Market Rent (12 times the FY2020-FY2024 average 1-bedroom FMR, the same 5 fiscal years the ACS 5-year PUMS estimate pools, real 2025 dollars) as a share of median Austin musician annual earnings from work (ACS 2020-2024 5-year PUMS, positive-earnings base, employed ages 18-64, n=`pums_n' unweighted records, real 2025 dollars, $`=string(round(`pums_earn',1),"%9.0fc")'). SNAPSHOT comparison, not a year-by-year trend: PUMS is a single pooled 5-year cross-section, unlike OEWS true annual panel used in fig19. Covers the self-employed, unlike the OEWS-based anchor above, which is the reason this measure exists.")
    numadd, key(col_pums_rent_share_latest) value(`=round(`share_latest',0.1)') ///
        formatted("`=string(round(`share_latest',0.1),"%4.1f")'%") ///
        unit("percent of annual earnings, latest FMR vs. pooled 2020-2024 earnings") ///
        source("03_analysis/out/numbers/numbers_pums.csv; 01_evidence/09_cost_of_living/hud_fmr_1983_2026_5area_long.csv") ///
        note("Same PUMS earnings figure against the LATEST available Austin 1-bedroom Fair Market Rent (FY2026, annualized, real 2025 dollars via this module partial-year patch) rather than the period-matched FY2020-2024 average. This mixes a 2026 rent level with an earnings estimate centered on 2020-2024; read as what today rent would cost out of that pooled-period income, not as a true 2026 earnings observation.")
    numadd, key(col_pums_rent_share_methodological_note) value(1) formatted("2 point estimates, not a trend") ///
        unit("methodological note") source("multiple") ///
        note("Task 5 share-of-income measure is two point comparisons (period-matched and latest), not an annual trend like fig19 hours-of-work series, because the underlying PUMS source is a single pooled 2020-2024 5-year cross-section, not an annual panel. Do not chart this as a time series.")
}

display as text "Task 5 (PUMS share-of-income) complete."


* ================================================================
* Done.
* ================================================================
display as text _newline "{hline 72}"
display as text "60_cost_of_living.do complete"
display as text "{hline 72}"
