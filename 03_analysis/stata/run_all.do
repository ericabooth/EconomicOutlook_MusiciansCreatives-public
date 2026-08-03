*! run_all.do - reproduce every figure, table and number in the report.
*!
*! HOW TO RUN
*!   The project folder is self-contained. After unzipping it on another
*!   machine, open Stata, change directory to this folder, and run this file:
*!
*!       cd "<wherever>/EconomicOutlook_MusiciansCreatives_20260801/03_analysis/stata"
*!       do run_all.do
*!
*!   Or from a terminal:
*!       cd "<...>/03_analysis/stata" && stata-mp -b do run_all.do
*!
*!   Then build the PDF:
*!       cd ../../05_report && make
*!
*! No package installation is needed. Every user-written command this project
*! uses (reghdfe, ftools, gtools, estout, spmap, shp2dta, palettes, colrspace,
*! grstyle, require) is bundled in 03_analysis/stata/ado and put on the ado
*! path by _setup.do.
*!
*! Modules are independent and each writes its own number ledger, so a failure
*! in one does not corrupt the others. build_numbers.do runs last and merges
*! whatever ledgers exist, so a partial run still produces a compilable report.

clear all
set more off

* Confirm we can find the project before doing anything else.
do "_setup.do"

local modules ///
    "10_pums_earnings"   ///
    "20_wages_industry"  ///
    "30_venues"          ///
    "40_city_money"      ///
    "50_state_national"  ///
    "60_cost_of_living"  ///
    "80_census_microdata"

display as text _newline "{hline 72}"
display as text "Austin musicians and creative workers: full analysis"
display as text "{hline 72}"

local failed ""
local skipped ""

foreach m of local modules {
    capture confirm file "`m'.do"
    if _rc != 0 {
        display as text "[skip] `m' (not present)"
        local skipped "`skipped' `m'"
        continue
    }
    display as text _newline "[run ] `m'"
    * Run each module in its own capture so one crash does not stop the rest.
    capture noisily do "`m'.do"
    if _rc != 0 {
        display as error "[FAIL] `m' returned _rc = " _rc
        local failed "`failed' `m'"
    }
    else {
        display as text "[done] `m'"
    }
    clear all
    quietly do "_setup.do"
}

display as text _newline "[run ] build_numbers"
capture noisily do "build_numbers.do"
if _rc != 0 {
    local failed "`failed' build_numbers"
}

display as text _newline "{hline 72}"
if "`skipped'" != "" {
    display as text "Skipped (not written yet):`skipped'"
}
if "`failed'" != "" {
    display as error "FAILED:`failed'"
    exit 1
}
display as text "All requested modules completed."
display as text "Next: cd ../../05_report && make"
display as text "{hline 72}"
