*! _setup.do - shared foundation for the Austin musician/creative-worker analysis.
*! Every module do-file starts with:  do "_setup.do"
*!
*! WHAT THIS DOES
*!   1. Finds the project root by searching upward for a sentinel file, so the
*!      whole folder can be zipped, moved to another machine, and run without
*!      editing a single path.
*!   2. Points Stata at the project-local ado library, so reghdfe, estout,
*!      spmap and the rest travel with the folder. No ssc install needed on a
*!      new machine.
*!   3. Builds a CPI-U deflator once and stores it, so every dollar figure in
*!      the report sits in the same base year (2025).
*!   4. Defines the report palette and graph styling, matched to the LaTeX file.
*!   5. Defines two helper programs: numadd (register a number the report will
*!      quote) and figsave (export a figure at consistent size).
*!
*! CONVENTIONS FOR MODULE AUTHORS
*!   - Set  global CURMODULE "<name>"  then call  numinit  before registering.
*!   - Figure titles state the FINDING; subtitles qualify it. Source notes and
*!     caveats do NOT go in the image; they go in the LaTeX caption.
*!   - All dollars real, 2025 base, via the cpi_annual lookup.

version 17
set more off
set varabbrev off

* ---------------------------------------------------------------- 1. ROOT --
* Search the working directory and its parents for a file that only exists in
* this project. Whichever candidate contains it is the project root.
local sentinel "01_evidence/01_wages_oews_qcew/_sources.md"
local found 0
foreach cand in "`c(pwd)'" "`c(pwd)'/.." "`c(pwd)'/../.." "`c(pwd)'/../../.." {
    capture confirm file "`cand'/`sentinel'"
    if (_rc == 0) & (`found' == 0) {
        global PROJ "`cand'"
        local found 1
    }
}
if `found' == 0 {
    display as error "_setup.do could not locate the project root."
    display as error "Run Stata from 03_analysis/stata/ (or the project root) and try again."
    display as error "Current directory: `c(pwd)'"
    exit 601
}

global EVID     "${PROJ}/01_evidence"
global ANALYSIS "${PROJ}/03_analysis"
global DATAX    "${ANALYSIS}/data/external"
global OUT      "${ANALYSIS}/out"
global NUMDIR   "${OUT}/numbers"
global TABDIR   "${OUT}/tables"
global FIGS     "${PROJ}/04_figures"
global STATADIR "${ANALYSIS}/stata"

* Evidence subfolders, named for the workstream each one came from.
global EV_WAGES  "${EVID}/01_wages_oews_qcew"
global EV_PUMS   "${EVID}/02_pums_nes_microdata"
global EV_BEA    "${EVID}/03_creative_economy_bea"
global EV_CITY   "${EVID}/04_city_programs_lmf"
global EV_SURVEY "${EVID}/05_music_census_pay_surveys"
global EV_STATE  "${EVID}/06_state_policy_benchmark"
global EV_SVOG   "${EVID}/07_svog_federal_relief"
global EV_VENUE  "${EVID}/08_venues_ecosystem"
global EV_COL    "${EVID}/09_cost_of_living"
global EV_APP    "${EVID}/10_apprenticeship_workforce"
global EV_STREAM "${EVID}/11_streaming_royalties"

capture mkdir "${OUT}"
capture mkdir "${NUMDIR}"
capture mkdir "${TABDIR}"
capture mkdir "${FIGS}"

* ------------------------------------------------------------- 2. ADO PATH --
* Prepend the project-local library. Using adopath rather than sysdir set PLUS
* keeps any packages already installed on this machine visible as a fallback,
* while guaranteeing the bundled copies win.
adopath ++ "${STATADIR}/ado/s"
adopath ++ "${STATADIR}/ado/plus"
adopath ++ "${STATADIR}/ado"

* --------------------------------------------------------- 3. CPI DEFLATOR --
* Base year for every real-dollar figure in the report.
global BASEYEAR 2025

* Build the annual CPI lookup once. Rebuilt only if missing, so modules that
* run in sequence do not each redo it.
capture confirm file "${OUT}/cpi_annual.dta"
if _rc != 0 {
    preserve
    use "${DATAX}/BLS_CPI.dta", clear
    keep if area_name == "U.S. city average" & item_name == "All items"
    keep if is_annualavg == 0 & seas_adj == 0 & !missing(month)
    keep year month cpi
    duplicates drop year month, force

    * BLS never published a CPI-U value for October 2025 because the federal
    * funding lapse suspended collection. Fill that single month by averaging
    * September and November and flag it. October matters here because it is
    * the month of the Austin City Limits festival, so leaving a hole would
    * distort the venue-receipts series specifically.
    generate byte cpi_imputed = 0
    sort year month
    quietly count if year == 2025 & month == 10 & missing(cpi)
    if r(N) > 0 {
        quietly summarize cpi if year == 2025 & month == 9, meanonly
        local sep = r(mean)
        quietly summarize cpi if year == 2025 & month == 11, meanonly
        local nov = r(mean)
        quietly replace cpi = (`sep' + `nov') / 2 if year == 2025 & month == 10
        quietly replace cpi_imputed = 1 if year == 2025 & month == 10
    }
    drop if missing(cpi)

    * Keep only years with a full twelve months, so a partial year (2026 at the
    * time of writing) never masquerades as an annual average.
    bysort year: generate byte nmon = _N
    keep if nmon == 12
    collapse (mean) cpi (max) cpi_imputed, by(year)

    quietly summarize cpi if year == ${BASEYEAR}, meanonly
    local base = r(mean)
    generate double defl = `base' / cpi
    label variable defl "Multiply nominal dollars of `year' by this to get ${BASEYEAR} dollars"
    label variable cpi_imputed "1 = annual average uses an imputed month"
    sort year
    save "${OUT}/cpi_annual.dta", replace
    restore
}

* Convenience: put the base-year CPI in a global for ad hoc use.
preserve
use "${OUT}/cpi_annual.dta", clear
quietly summarize cpi if year == ${BASEYEAR}, meanonly
global CPIBASE = r(mean)
restore

* ------------------------------------------------------------- 4. PALETTE --
* RGB triples matching 05_report/style/austinmusic.sty, so figures and document
* agree without anyone re-typing hex codes.
global NAVY    "27 45 85"
global ORANGE  "212 69 0"
global BLUE    "43 108 176"
global MUTED   "108 122 141"
global LIGHTBG "245 247 250"
global BORDER  "222 226 230"
global GREEN   "46 125 87"
global GOLD    "200 137 27"
global RED     "192 57 43"
global TEXTC   "26 26 46"

* Orange marks the musician or Austin series throughout; navy and muted mark
* comparison series. Keeping that constant across figures means a reader learns
* the convention once.
global SERIES1 "${NAVY}"
global SERIES2 "${ORANGE}"
global SERIES3 "${BLUE}"
global SERIES4 "${GREEN}"
global SERIES5 "${GOLD}"
global SERIES6 "${MUTED}"

* Standard title and subtitle options. Modules pass these straight through:
*   twoway ... , title("Finding", $TITLEOPT) subtitle("Qualifier", $SUBOPT)
global TITLEOPT `"size(4.1) color("${NAVY}") justification(left) position(11) span margin(b=1)"'
global SUBOPT   `"size(3.0) color("${MUTED}") justification(left) position(11) span margin(b=3)"'
global XTOPT    `"size(3.0)"'
global YTOPT    `"size(3.0)"'
global LEGOPT   `"size(3.0) region(lstyle(none)) symxsize(6)"'

capture grstyle init
capture grstyle set plain, horizontal
capture grstyle set color "${TEXTC}": p1lineplot
capture grstyle set legend 6, nobox

* ------------------------------------------------------------ 5. PROGRAMS --
capture program drop numinit
program define numinit
    * Start (or restart) this module's number ledger. Called once per module so
    * re-running a module replaces its own rows rather than appending duplicates.
    if "$CURMODULE" == "" {
        display as error "numinit: set  global CURMODULE  first"
        exit 198
    }
    quietly {
        local f "${NUMDIR}/numbers_${CURMODULE}.csv"
        capture erase "`f'"
        file open nh using "`f'", write text replace
        file write nh "key,value,formatted,unit,source,note,module" _n
        file close nh
    }
    display as text "  ledger started: numbers_${CURMODULE}.csv"
end

capture program drop numadd
program define numadd
    * Register one number the written report will quote.
    *
    *   numadd, key(pums_median_earnings_tx) value(22800) ///
    *           formatted("\$22,800") unit("2025 dollars") ///
    *           source("01_evidence/02_pums.../pums_...csv") ///
    *           note("ACS PUMS 2020-2024 5-yr, OCCP 2752, PWGTP-weighted median")
    *
    * key becomes a LaTeX macro, so use letters, digits and underscores only.
    * note must let a reader reproduce the number: population, filter, weight,
    * vintage, and any caveat.
    syntax , KEY(string) VALUE(string) [FORMATTED(string) UNIT(string) ///
             SOURCE(string) NOTE(string)]
    if "$CURMODULE" == "" {
        display as error "numadd: set  global CURMODULE  and call numinit first"
        exit 198
    }
    if "`formatted'" == "" {
        local formatted "`value'"
    }
    * Replace any embedded double quote with an apostrophe. These fields are
    * descriptive text, never data, so substituting is safer than escaping and
    * keeps the ledger readable by any CSV parser.
    foreach v in formatted unit source note {
        local `v' : subinstr local `v' `"""' "'", all
    }
    quietly {
        file open nh using "${NUMDIR}/numbers_${CURMODULE}.csv", write text append
        file write nh `""`key'","`value'","`formatted'","`unit'","`source'","`note'","${CURMODULE}""' _n
        file close nh
    }
end

capture program drop figsave
program define figsave
    * Export the current graph to 04_figures at a consistent size.
    * Width 2000px at the report's 6.5 inch text width is about 300 dpi.
    syntax , NAME(string) [WIDTH(integer 2000)]
    quietly graph export "${FIGS}/`name'.png", replace width(`width')
    display as text "  figure -> 04_figures/`name'.png"
end

capture program drop requirefile
program define requirefile
    * Fail early and legibly when an expected input is absent, rather than
    * producing a confusing error deeper in a module.
    *
    * This project's paths contain spaces ("My Drive", the Google Drive mount
    * point), so the argument is taken from `0' as a whole rather than parsed
    * into tokens, stripped of any quotes the caller supplied, and then
    * compound-quoted for `confirm'. Passing an unquoted path with spaces to
    * `confirm file' is what makes this fail with a misleading r(601).
    local fn `0'
    local fn : subinstr local fn `"""' "", all
    local fn = trim("`fn'")
    capture confirm file `"`fn'"'
    if _rc != 0 {
        display as error "Required input not found: `fn'"
        exit 601
    }
end

display as text "_setup.do ready. Root: ${PROJ}"
display as text "  base year ${BASEYEAR}, CPI ${CPIBASE}"
