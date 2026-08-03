*! 40_city_money.do - Where Austin’s hotel-tax dollar goes, how the Live Music
*!   Fund has taken in and paid out money since FY2021, what its award cycles
*!   looked like, and how it compares to the city’s other music/creative-space
*!   capital programs.
*!
*! Inputs  : 01_evidence/04_city_programs_lmf/derived_HOT_fund_revenue_expense_FY2021_FY2027.csv
*!           01_evidence/04_city_programs_lmf/derived_LMF_cohort_summary.csv
*!           01_evidence/04_city_programs_lmf/socrata/yeeq-kk6v_expense_open_budget.csv
*!           01_evidence/04_city_programs_lmf/socrata/x6aj-qng8_cultural_funding_awards.csv
*!           01_evidence/04_city_programs_lmf/_findings.md, _sources.md (program
*!             history, applicant counts and award-list caveats with no CSV of
*!             their own)
*!           01_evidence/08_venues_ecosystem/_findings.md (Iconic Venue Fund
*!             proposal/shortlist counts, from Austin Chronicle 2023-08-24)
*!           03_analysis/out/cpi_annual.dta (built by _setup.do)
*!
*! Outputs : 04_figures/fig12_hot_allocation.png (+ out/fig12_hot_allocation.csv)
*!           04_figures/fig13_lmf_flow.png        (+ out/fig13_lmf_flow.csv)
*!           04_figures/fig14_lmf_cohorts.png      (+ out/fig14_lmf_cohorts.csv)
*!           03_analysis/out/numbers/numbers_city.csv
*!           03_analysis/out/tables/city_hot_fund_series_fy2021_2027.csv
*!
*! WHY THE OBJECT-LEVEL EXPENSE FILE IS RE-DERIVED HERE RATHER THAN TAKEN FROM
*! _findings.md AT FACE VALUE: the admin-share figures in the evidence memo
*! (grants vs. consultant vs. advertising) are themselves a hand tally out of
*! the 258,876-row Open Budget expense extract. This module reproduces that
*! tally directly from socrata/yeeq-kk6v so the number in the report ledger
*! traces to a live import, not a copied total. It was checked against the
*! memo’s cumulative figures (grants $17,598,450; consultant $2,338,304;
*! advertising $267,993) before this module was written and matches to the
*! dollar.

clear all
do "_setup.do"                    // run from 03_analysis/stata/
global CURMODULE "city"
numinit

requirefile "${EV_CITY}/derived_HOT_fund_revenue_expense_FY2021_FY2027.csv"
requirefile "${EV_CITY}/derived_LMF_cohort_summary.csv"
requirefile "${EV_CITY}/socrata/yeeq-kk6v_expense_open_budget.csv"
requirefile "${EV_CITY}/socrata/x6aj-qng8_cultural_funding_awards.csv"
requirefile "${OUT}/cpi_annual.dta"


* ===========================================================================
* 0. FISCAL YEAR <-> CALENDAR YEAR, STATED ONCE
* ===========================================================================
* Austin’s fiscal year FY_Y runs 1 Oct (Y-1) - 30 Sep (Y). Nine of its twelve
* months (Jan-Sep) fall in calendar year Y; three (Oct-Dec) fall in Y-1. This
* module deflates every fiscal-year dollar figure with calendar year Y’s CPI-U
* annual average, i.e. merges on year = fiscal year number with no shift. That
* is exact only to the extent prices do not move sharply across the Dec/Jan
* boundary, and no quarterly deflator exists in this project to do better.
local fynote "Fiscal year FY_Y approximated by calendar year Y for CPI deflation (Austin FY_Y runs Oct(Y-1)-Sep(Y); 9 of 12 months fall in calendar Y). No quarterly deflator is available; this is the module-wide convention."

numadd, key(city_fy_calendar_approx) value(9) ///
    formatted("FY_Y matched to calendar year Y (9 of 12 months overlap)") ///
    unit("months of 12 overlapping") source("methodological note, not a data source") ///
    note("`fynote'")


* ===========================================================================
* 1. THE HOT-FUND PANEL: LIVE MUSIC, HISTORIC PRESERVATION, CULTURAL ARTS,
*    TOTAL HOT REVENUE, AND THE ICONIC VENUE FUND, FY2021-FY2027, REAL $
* ===========================================================================
import delimited "${EV_CITY}/derived_HOT_fund_revenue_expense_FY2021_FY2027.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve)

generate str6 slug = ""
replace slug = "_lmf" if fund == "Live Music Fund"
replace slug = "_hp"  if fund == "Historic Preservation Fund"
replace slug = "_caf" if fund == "Cultural Arts Fund"
replace slug = "_hot" if fund == "Hotel Occupancy Tax Fund"
replace slug = "_ivf" if fund == "Iconic Venue Fund"
* Music Venue Assistance Program Fund (effectively wound down by FY2023, per
* the evidence memo) is the only fund this drops; none of the five tasks below
* touch it. Flagged rather than silently dropped, so a future data refresh
* that adds an unrecognized fund name is caught here, not downstream.
quietly count if slug == ""
if r(N) > 0 {
    display as text "  rows outside this module’s five tracked funds (dropped):"
    list fund fiscal_year if slug == "", clean noobs
    drop if slug == ""
}
drop fund
rename fiscal_year year
reshape wide revenue_actual revenue_budget expense_actual expense_budget, ///
    i(year) j(slug) string
isid year

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) ///
    keepusing(defl cpi_imputed) nogenerate
* cpi_annual.dta holds only years with a full published twelve months. FY2026
* is not yet complete (today is 2026-08-02) and FY2027 has not started, so
* both are expected to come back with no deflator. Every real-dollar figure in
* this module therefore stops at FY2025; FY2026-FY2027 carry in nominal terms
* only, and are always labeled as such.
quietly count if missing(defl) & !inlist(year, 2026, 2027)
assert r(N) == 0
quietly count if missing(defl) & inlist(year, 2026, 2027)
display as text "  fiscal years with no CPI deflator (expected: FY2026, FY2027): " r(N)

foreach f in lmf hp caf hot ivf {
    generate double revenue_real_`f' = revenue_actual_`f' * defl
    generate double expense_real_`f'  = expense_actual_`f' * defl
    label variable revenue_real_`f' "`f' revenue, 2025 dollars (missing FY2026-27)"
    label variable expense_real_`f'  "`f' expenditure, 2025 dollars (missing FY2026-27)"
}
sort year
save "${OUT}/city_hot_fund_panel.dta", replace
export delimited using "${TABDIR}/city_hot_fund_series_fy2021_2027.csv", replace
display as text "  table -> out/tables/city_hot_fund_series_fy2021_2027.csv"


* ===========================================================================
* 2. TASK 1 - HOT ALLOCATION: FIG12 AND THE SHARE/RATIO NUMBERS
* ===========================================================================
quietly summarize revenue_actual_lmf if year == 2025, meanonly
local lmf25 = r(mean)
quietly summarize revenue_actual_hp  if year == 2025, meanonly
local hp25  = r(mean)
quietly summarize revenue_actual_caf if year == 2025, meanonly
local caf25 = r(mean)
quietly summarize revenue_actual_hot if year == 2025, meanonly
local hot25 = r(mean)
* "Rest" is total HOT revenue net of the three named carve-outs. It is not a
* single named fund: by the 2019 ordinance it is mainly Convention Center
* expansion, plus whatever else the HOT statute funds. Registered as such so
* no reader mistakes it for a fourth discrete program.
local rest25 = `hot25' - `lmf25' - `hp25' - `caf25'
local lmfshare25 = 100 * `lmf25' / `hot25'
local hpratio25  = `hp25' / `lmf25'

display as text "FY2025 HOT allocation (nominal $): LMF `lmf25' | HP `hp25' | CAF `caf25' | rest `rest25' | total `hot25'"
display as text "  LMF share of total HOT revenue: " %5.2f `lmfshare25' "%"
display as text "  HP-to-LMF ratio: " %5.2f `hpratio25' "x"

local srcHOT "01_evidence/04_city_programs_lmf/derived_HOT_fund_revenue_expense_FY2021_FY2027.csv"
local f : display %12.1fc `=`lmf25'/1e6'
numadd, key(city_lmf_revenue_fy25) value("`lmf25'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars") source("`srcHOT'") ///
    note("Live Music Fund actual revenue, FY2025. Same-year figure; ratios built from it need no deflation.")
local f : display %12.1fc `=`hp25'/1e6'
numadd, key(city_hp_revenue_fy25) value("`hp25'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars") source("`srcHOT'") note("Historic Preservation Fund actual revenue, FY2025.")
local f : display %12.1fc `=`caf25'/1e6'
numadd, key(city_caf_revenue_fy25) value("`caf25'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars") source("`srcHOT'") note("Cultural Arts Fund actual revenue, FY2025.")
local f : display %12.1fc `=`hot25'/1e6'
numadd, key(city_hot_total_revenue_fy25) value("`hot25'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars") source("`srcHOT'") ///
    note("Total Hotel Occupancy Tax Fund actual revenue, FY2025. Denominator for city_lmf_share_of_hot_fy25.")
local f : display %12.1fc `=`rest25'/1e6'
numadd, key(city_hot_rest_fy25) value("`rest25'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars") source("`srcHOT'") ///
    note("Total HOT revenue minus Live Music, Historic Preservation and Cultural Arts fund revenue, FY2025. Mainly Convention Center expansion under the 2019 ordinance’s residual clause; not itself a single named fund.")
local f : display %5.2f `lmfshare25'
numadd, key(city_lmf_share_of_hot_fy25) value("`lmfshare25'") formatted("`=trim("`f'")'%") ///
    unit("percent of total HOT revenue") source("`srcHOT'") ///
    note("Live Music Fund revenue as a share of total Hotel Occupancy Tax Fund revenue, FY2025. Same-year nominal ratio; deflation cancels and was not applied.")
local f : display %5.2f `hpratio25'
numadd, key(city_hp_to_lmf_ratio_fy25) value("`hpratio25'") formatted("`=trim("`f'")'x") ///
    unit("ratio") source("`srcHOT'") ///
    note("Historic Preservation Fund revenue divided by Live Music Fund revenue, FY2025. Same-year nominal ratio; deflation cancels.")

* --- the "flat nominal since FY2024, therefore falling in real terms" point --
quietly summarize revenue_actual_lmf if year == 2024, meanonly
local lmf24n = r(mean)
quietly summarize revenue_real_lmf if year == 2024, meanonly
local lmf24r = r(mean)
quietly summarize revenue_real_lmf if year == 2025, meanonly
local lmf25r = r(mean)
local pctnom = 100 * (`lmf25' / `lmf24n' - 1)
local pctreal = 100 * (`lmf25r' / `lmf24r' - 1)
display as text "  LMF revenue FY2024->FY2025: nominal " %5.2f `pctnom' "%, real " %5.2f `pctreal' "%"

local f : display %6.2f `pctnom'
numadd, key(city_lmf_revenue_pctchg_fy24_fy25_nominal) value("`pctnom'") ///
    formatted("`=trim("`f'")'%") unit("percent change, nominal") source("`srcHOT'") ///
    note("Live Music Fund revenue, FY2024 to FY2025, nominal dollars. `fynote'")
local f : display %6.2f `pctreal'
numadd, key(city_lmf_revenue_pctchg_fy24_fy25_real) value("`pctreal'") ///
    formatted("`=trim("`f'")'%") unit("percent change, 2025 dollars") source("`srcHOT'") ///
    note("Live Music Fund revenue, FY2024 to FY2025, 2025 dollars via out/cpi_annual.dta. FY2025 is the CPI base year so its real and nominal values are identical; the gap between this figure and city_lmf_revenue_pctchg_fy24_fy25_nominal is entirely FY2024’s deflation. `fynote'")

* --- the FY2021-FY2027 series behind the single-year snapshot, registered at
*     a few more points so the multi-year claim in the task is not resting on
*     FY2025 alone --------------------------------------------------------
foreach y in 2021 2026 {
    quietly summarize revenue_actual_lmf if year == `y', meanonly
    local lv = r(mean)
    quietly summarize revenue_actual_hot if year == `y', meanonly
    local hv = r(mean)
    local sh = 100 * `lv' / `hv'
    local f : display %5.2f `sh'
    local partial = cond(`y' == 2026, " FY2026 revenue is a partial-year actual.", "")
    numadd, key(city_lmf_share_of_hot_fy`y') value("`sh'") formatted("`=trim("`f'")'%") ///
        unit("percent of total HOT revenue") source("`srcHOT'") ///
        note("Live Music Fund revenue as a share of total HOT revenue, FY`y'. Same-year nominal ratio.`partial'")
}
numadd, key(city_lmf_revenue_fy2026_budget) value(5051453) formatted("\$5.1M") ///
    unit("nominal dollars, budget") source("`srcHOT'") ///
    note("Live Music Fund FY2027 budgeted revenue (row labeled fiscal_year 2027 in the source; FY2027 has not started, budget only, no actual).")

* --- FIG 12: horizontal bars, shared linear dollar axis, FY2025 -----------
preserve
    clear
    set obs 4
    generate int fiscal_year = 2025
    generate byte ypos = _n
    generate str30 category = ""
    generate double amount = .
    replace category = "Live Music Fund"       in 1
    replace amount   = `lmf25'                 in 1
    replace category = "Cultural Arts Fund"    in 2
    replace amount   = `caf25'                 in 2
    replace category = "Historic Preservation" in 3
    replace amount   = `hp25'                  in 3
    replace category = "Rest of HOT revenue"   in 4
    replace amount   = `rest25'                in 4
    generate double amount_m = amount / 1e6
    generate double share_of_hot = 100 * amount / `hot25'
    export delimited fiscal_year category amount share_of_hot ///
        using "${OUT}/fig12_hot_allocation.csv", replace

    local xmax = 1.14 * `rest25' / 1e6
    local lab1 : display %4.1f `=amount_m[1]'
    local lab2 : display %4.1f `=amount_m[2]'
    local lab3 : display %4.1f `=amount_m[3]'
    local lab4 : display %4.1f `=amount_m[4]'

    twoway ///
      (bar amount_m ypos if ypos == 1, horizontal barwidth(0.62) color("${ORANGE}")) ///
      (bar amount_m ypos if ypos == 2, horizontal barwidth(0.62) color("${BLUE}"))   ///
      (bar amount_m ypos if ypos == 3, horizontal barwidth(0.62) color("${NAVY}"))   ///
      (bar amount_m ypos if ypos == 4, horizontal barwidth(0.62) color("${MUTED}"))  ///
      , xscale(range(0 `xmax')) ///
        xlabel(0(20)140, labsize(2.8)) ///
        xtitle("Fiscal year 2025 revenue, millions of nominal dollars", $XTOPT) ///
        ylabel(1 "Live Music Fund" 2 "Cultural Arts Fund" ///
               3 "Historic Preservation" 4 "Rest of HOT revenue", ///
               angle(0) labsize(3.0)) ///
        yscale(range(0.4 4.6)) ytitle("") ///
        text(1 `=amount_m[1]+5' "\$`=trim("`lab1'")'M", placement(e) size(2.8) color("${TEXTC}")) ///
        text(2 `=amount_m[2]+5' "\$`=trim("`lab2'")'M", placement(e) size(2.8) color("${TEXTC}")) ///
        text(3 `=amount_m[3]+5' "\$`=trim("`lab3'")'M", placement(e) size(2.8) color("${TEXTC}")) ///
        text(4 `=amount_m[4]+5' "\$`=trim("`lab4'")'M", placement(e) size(2.8) color("${TEXTC}")) ///
        legend(off) graphregion(color(white)) plotregion(margin(l=2 r=8)) ///
        title("Historic preservation gets 4.4 times as much hotel tax as live music", $TITLEOPT) ///
        subtitle("City of Austin Hotel Occupancy Tax Fund revenue by destination, fiscal year 2025." ///
                 "Actual collections, nominal dollars; the rest bar nets out the three named funds.", $SUBOPT) ///
        ysize(4.6) xsize(8.2) ///
        name(fig12, replace)
    figsave, name(fig12_hot_allocation)
restore


* ===========================================================================
* 3. TASK 2 - LMF FLOW: FIG13, THE CUMULATIVE GAP, AND THE ADMIN SHARE
* ===========================================================================
use "${OUT}/city_hot_fund_panel.dta", clear
keep if inrange(year, 2021, 2026)
generate double net_nominal_lmf = revenue_actual_lmf - expense_actual_lmf
sort year
generate double cum_net_nominal_lmf = sum(net_nominal_lmf)

quietly summarize cum_net_nominal_lmf if year == 2022, meanonly
local accum22 = r(mean)
quietly summarize cum_net_nominal_lmf if year == 2025, meanonly
local cum25n = r(mean)
quietly summarize cum_net_nominal_lmf if year == 2026, meanonly
local cum26n = r(mean)

display as text "LMF cumulative revenue-minus-expenditure (nominal): FY2022 `accum22' | FY2025 `cum25n' | FY2026 `cum26n'"

local srcHOT "01_evidence/04_city_programs_lmf/derived_HOT_fund_revenue_expense_FY2021_FY2027.csv"
local balnote "This is a cumulative revenue-minus-expenditure PROXY built from Open Budget actuals starting FY2021, not an audited fund balance, and it excludes any opening balance the fund may have carried from its 2019-09-30 creation. Press reporting placed the Live Music Fund balance at approximately \$3.2 million in September 2025 (within FY2025); this proxy does not reconcile with that figure, and the gap is unresolved pending the ACFR fund-balance schedule (see 01_evidence/04_city_programs_lmf/_sources.md, open item 3). Prefer the annual revenue-against-expenditure series over this cumulative figure when a single number is needed."

local f : display %12.1fc `=`accum22'/1e6'
numadd, key(city_lmf_accum_by_fy22_nominal) value("`accum22'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars, cumulative FY2021-FY2022") source("`srcHOT'") ///
    note("Cumulative Live Music Fund revenue minus expenditure, FY2021 through FY2022, nominal. The fund collected for two full years (spending just \$4,284 and \$50,000 respectively against \$1.49M and \$3.70M in revenue) before its first real grant cycle disbursed in FY2023. `balnote'")
local f : display %12.1fc `=`cum25n'/1e6'
numadd, key(city_lmf_cumulative_net_nominal_fy25) value("`cum25n'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars, cumulative FY2021-FY2025") source("`srcHOT'") note("`balnote'")
local f : display %12.1fc `=`cum26n'/1e6'
numadd, key(city_lmf_cumulative_net_nominal_fy26) value("`cum26n'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars, cumulative FY2021-FY2026") source("`srcHOT'") ///
    note("Headline cumulative figure through the latest fiscal year with any actual spending recorded (FY2026 is a partial-year actual). `balnote'")

* --- the same story in 2025 dollars, for FIG13 (kept strictly to FY2021-2025
*     so the image never mixes real and nominal dollars) -------------------
keep if inrange(year, 2021, 2025)
generate double net_real_lmf = revenue_real_lmf - expense_real_lmf
sort year
generate double cum_net_real_lmf = sum(net_real_lmf)
quietly summarize cum_net_real_lmf if year == 2025, meanonly
local cum25r = r(mean)
local f : display %12.1fc `=`cum25r'/1e6'
numadd, key(city_lmf_cumulative_net_real_fy25) value("`cum25r'") formatted("\$`=trim("`f'")'M") ///
    unit("2025 dollars, cumulative FY2021-FY2025") source("`srcHOT'") ///
    note("Same cumulative proxy as city_lmf_cumulative_net_nominal_fy25, rebuilt entirely in 2025 dollars (each year’s revenue and expenditure deflated before summing). Plotted on fig13’s right axis. Differs from the nominal figure only by each year’s CPI factor; both are cash-flow proxies, not audited balances. `fynote'")

export delimited year revenue_real_lmf expense_real_lmf net_real_lmf cum_net_real_lmf ///
    revenue_actual_lmf expense_actual_lmf using "${OUT}/fig13_lmf_flow.csv", replace

quietly summarize revenue_real_lmf
local rmax = r(max)
quietly summarize expense_real_lmf
local emax = r(max)
local barmax = max(`rmax', `emax') / 1e6
quietly summarize cum_net_real_lmf
local cmax = r(max)
local cmin = r(min)

* ONE axis for all three series. Revenue, expenditure and the cumulative net
* are all millions of 2025 dollars, but they used to sit on two axes with
* different ranges (left 0-7, right 0-8), so the gold line invited reading
* against the left axis and came out about 15 percent low when it was. Sharing
* a single axis removes the ambiguity at no cost, because the units already
* match; the legend says which series is a running total and which are annual
* flows.
local yaxismax = max(ceil(`barmax'), ceil(`cmax' / 1e6))
assert `cmin' >= 0    // a negative running total would need the axis below zero

generate double rev_m = revenue_real_lmf / 1e6
generate double exp_m = expense_real_lmf / 1e6
generate double cum_m = cum_net_real_lmf / 1e6
generate double yr_a = year - 0.19
generate double yr_b = year + 0.19

* FY2021 and FY2022 expenditure are $5,093 and $55,040 in 2025 dollars: at this
* scale both draw as a hairline that reads as a missing bar rather than a
* near-zero one, so each carries its own label. The two label strings are
* written out below rather than generated, and asserted against the data here
* so a refresh cannot leave them stale.
quietly summarize exp_m if year == 2021, meanonly
assert r(mean) < 0.01
quietly summarize exp_m if year == 2022, meanonly
assert inrange(r(mean), 0.055, 0.065)

twoway ///
  (bar rev_m yr_a, barwidth(0.36) color("${ORANGE}")) ///
  (bar exp_m yr_b, barwidth(0.36) color("${NAVY}")) ///
  (connected cum_m year, lcolor("${GOLD}") lwidth(medthick) ///
        mcolor("${GOLD}") msymbol(O) msize(small) cmissing(n)) ///
  , ytitle("Millions, 2025 dollars", $YTOPT) ///
    ylabel(0(1)`yaxismax', angle(0) labsize(2.8)) ///
    xtitle("") xlabel(2021(1)2025, labsize(2.8)) xscale(range(2020.5 2025.5)) ///
    text(0.10 2021.19 "<\$0.01M", placement(n) size(2.4) color("${TEXTC}")) ///
    text(0.10 2022.19 "\$0.06M", placement(n) size(2.4) color("${TEXTC}")) ///
    legend(order(1 "Revenue" 2 "Expenditure" 3 "Cumulative net since FY2021") ///
           cols(1) position(6) size(2.7) region(lstyle(none)) symxsize(6)) ///
    title("Live Music Fund revenue outran spending through FY2023, then reversed", $TITLEOPT) ///
    subtitle("Revenue, expenditure and the running net by fiscal year, 2025 dollars, City of Austin." ///
             "FY2021-FY2025 actuals; all three series are drawn against the same axis.", $SUBOPT) ///
    graphregion(color(white)) ysize(5.6) xsize(8.4) ///
    name(fig13, replace)
figsave, name(fig13_lmf_flow)


* --- administration share: grants vs. consultant vs. advertising ----------
* Re-derived directly from the 258,876-row Open Budget expense extract rather
* than typed in from the evidence memo (see file header). obj_cat is always
* "Contractuals" for these three rows; obj_desc carries the category.
preserve
    import delimited "${EV_CITY}/socrata/yeeq-kk6v_expense_open_budget.csv", ///
        clear varnames(1) encoding("utf-8") case(preserve) bindquotes(strict) ///
        stringcols(_all)
    keep if fund_nm == "Live Music Fund"
    destring fy act bud, replace force
    keep fy obj_desc act bud
    quietly count
    display as text "  Live Music Fund object-level expense rows: " r(N) " (expect 19: 3 categories x up to 7 fiscal years)"

    tempfile lmfobj
    save `lmfobj'

    collapse (sum) act_total = act (sum) bud_total = bud, by(obj_desc)
    list, clean noobs
    quietly summarize act_total if obj_desc == "Grants to subrecipients", meanonly
    local grants = r(mean)
    quietly summarize act_total if obj_desc == "Consultant-others", meanonly
    local consult = r(mean)
    quietly summarize act_total if obj_desc == "Advertising/publication", meanonly
    local advert = r(mean)
    local admintot = `grants' + `consult' + `advert'
    local sh_grants = 100 * `grants' / `admintot'
    local sh_consult = 100 * `consult' / `admintot'
    local sh_advert = 100 * `advert' / `admintot'
    display as text "  cumulative FY2021-FY2027: grants `grants' (`sh_grants'%) | consultant `consult' (`sh_consult'%) | advertising `advert' (`sh_advert'%)"

    * First fiscal year a Consultant-others row exists for the Live Music Fund.
    use `lmfobj', clear
    keep if obj_desc == "Consultant-others" & act > 0
    quietly summarize fy
    local firstconsultyr = r(min)
    display as text "  first fiscal year with a positive Consultant-others actual: `firstconsultyr'"
restore

local srcEXP "01_evidence/04_city_programs_lmf/socrata/yeeq-kk6v_expense_open_budget.csv"
local admnote "Object-level actuals FY2021-FY2027 from the City of Austin Open Budget expense extract, fund_nm = Live Music Fund, summed across fiscal years. Cross-checked against the evidence memo’s cumulative figures (grants \$17,598,450; consultant \$2,338,304; advertising \$267,993) and matches to the dollar. No Consultant-others row appears before FY`firstconsultyr': the fund had no third-party administrator cost until it began disbursing real grants, an innocent function of program timing rather than any change in oversight."

local f : display %12.1fc `=`grants'/1e6'
numadd, key(city_lmf_admin_grants_cumulative) value("`grants'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars, cumulative FY2021-FY2027") source("`srcEXP'") note("`admnote'")
local f : display %12.1fc `=`consult'/1e6'
numadd, key(city_lmf_admin_consultant_cumulative) value("`consult'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars, cumulative FY2021-FY2027") source("`srcEXP'") ///
    note("Consultant-others object, the fund’s third-party administrator (the Long Center for the Performing Arts from 2023 onward). `admnote'")
local f : display %9.0fc `advert'
numadd, key(city_lmf_admin_advertising_cumulative) value("`advert'") formatted("\$`=trim("`f'")'") ///
    unit("nominal dollars, cumulative FY2021-FY2027") source("`srcEXP'") note("`admnote'")
local f : display %6.2f `sh_grants'
numadd, key(city_lmf_admin_share_grants) value("`sh_grants'") formatted("`=trim("`f'")'%") ///
    unit("percent of grants+consultant+advertising") source("`srcEXP'") ///
    note("Share of the three tracked expense objects that is grants to subrecipients, cumulative FY2021-FY2027. Denominator is city_lmf_admin_grants_cumulative + city_lmf_admin_consultant_cumulative + city_lmf_admin_advertising_cumulative; excludes any Personnel or other object categories, of which none were found for this fund.")
local f : display %6.2f `sh_consult'
numadd, key(city_lmf_admin_share_consultant) value("`sh_consult'") formatted("`=trim("`f'")'%") ///
    unit("percent of grants+consultant+advertising") source("`srcEXP'") note("`admnote'")
local f : display %6.2f `sh_advert'
numadd, key(city_lmf_admin_share_advertising) value("`sh_advert'") formatted("`=trim("`f'")'%") ///
    unit("percent of grants+consultant+advertising") source("`srcEXP'") note("`admnote'")


* ===========================================================================
* 4. TASK 3 - AWARD COHORTS FY2023-FY2027: FIG14
* ===========================================================================
* derived_LMF_cohort_summary.csv carries the document-stated headline totals
* per the mandatory constraint on the FY2026 list (399 awards, \$7,140,000);
* it is not a re-tally of line items.
import delimited "${EV_CITY}/derived_LMF_cohort_summary.csv", clear ///
    varnames(1) encoding("utf-8") case(preserve) bindquotes(strict)
generate int fy = real(substr(cycle, 3, 4))
list cycle fy awards total tiers, clean noobs

* FY2023 count: the awardee-list tally (369) is what pairs with this file’s
* total and tiers; it appears to include one duplicated printed name. Press
* reporting gives 368. Both are registered; the funded-share calculation
* below uses 368 because it is the figure paired with the 660-applicant count
* in the same press source.
quietly summarize awards if fy == 2023, meanonly
local awd23 = r(mean)
quietly summarize total if fy == 2023, meanonly
local tot23 = r(mean)
local avg23 = `tot23' / `awd23'

quietly summarize awards if fy == 2024, meanonly
local awd24 = r(mean)
quietly summarize total if fy == 2024, meanonly
local tot24 = r(mean)
local avg24 = `tot24' / `awd24'

quietly summarize total if fy == 2025, meanonly
local tot25 = r(mean)

quietly summarize awards if fy == 2026, meanonly
local awd26 = r(mean)
quietly summarize total if fy == 2026, meanonly
local tot26 = r(mean)
local avg26 = `tot26' / `awd26'

quietly summarize total if fy == 2027, meanonly
local bud27 = r(mean)

display as text "Cohorts: FY23 `awd23'/`tot23' (avg `avg23') | FY24 `awd24'/`tot24' (avg `avg24') | FY25 0/`tot25' | FY26 `awd26'/`tot26' (avg `avg26') | FY27 budget `bud27' (open cycle)"

local srcLMFC "01_evidence/04_city_programs_lmf/derived_LMF_cohort_summary.csv"
numadd, key(city_lmf_fy23_awards_list) value("`awd23'") formatted("369") unit("count") ///
    source("01_evidence/04_city_programs_lmf/LMF_FY23_awardee_list.pdf") ///
    note("Line-item tally of the FY2023 Live Music Fund Event Program awardee list (40 x \$5,000 + 329 x \$10,000). Appears to contain one duplicated name (Alejandro Castillo prints twice). Paired with city_lmf_fy23_total and city_lmf_fy23_avg, and plotted in fig14. See city_lmf_fy23_awards_press for the alternative count.")
numadd, key(city_lmf_fy23_awards_press) value(368) formatted("368") unit("count") ///
    source("01_evidence/04_city_programs_lmf/_findings.md") ///
    note("Press-reported FY2023 award count (Austin Chronicle), paired with the 660-applicant figure used in city_lmf_fy23_funded_share. One less than the 369-row tally of the primary award-list PDF; the two do not reconcile and both are reported per the project’s mandatory accuracy constraints.")
local f : display %12.1fc `=`tot23'/1e6'
numadd, key(city_lmf_fy23_total) value("`tot23'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars") source("`srcLMFC'") note("FY2023 Live Music Fund Event Program, total awarded (40 x \$5,000 + 329 x \$10,000).")
local f : display %8.0fc `avg23'
numadd, key(city_lmf_fy23_avg) value("`avg23'") formatted("\$`=trim("`f'")'") unit("nominal dollars per award") ///
    source("`srcLMFC'") note("city_lmf_fy23_total divided by city_lmf_fy23_awards_list (369). Two tiers only: \$5,000 and \$10,000.")

numadd, key(city_lmf_fy24_awards) value("`awd24'") formatted("136") unit("count") source("`srcLMFC'") ///
    note("FY2024 Live Music Fund awardee list: 15 x \$15,000 + 104 x \$30,000 (musicians/promoters) + 17 x \$60,000 (venues, admitted to the fund for the first time this cycle).")
local f : display %12.1fc `=`tot24'/1e6'
numadd, key(city_lmf_fy24_total) value("`tot24'") formatted("\$`=trim("`f'")'M") unit("nominal dollars") ///
    source("`srcLMFC'") note("FY2024 Live Music Fund total awarded.")
local f : display %8.0fc `avg24'
numadd, key(city_lmf_fy24_avg) value("`avg24'") formatted("\$`=trim("`f'")'") unit("nominal dollars per award") ///
    source("`srcLMFC'") note("Average masks a wide tier spread (\$15,000 to \$60,000) and a compositional shift: the number of funded musicians and promoters fell from 369 (FY2023) to 119, even as venues joined the fund.")

numadd, key(city_lmf_fy25_awards) value(0) formatted("0") unit("count") ///
    source("01_evidence/04_city_programs_lmf/page_LMF_program_page.md") ///
    note("No FY2025 Live Music Fund cycle ran; the official program page states “No awards made.” This is a genuine zero, not a missing observation: applications were deferred to fall 2025 and folded into the FY2026 cycle. Plotted in fig14 as a true zero-height bar with no average-award line drawn through it.")

numadd, key(city_lmf_fy26_awards) value("`awd26'") formatted("399") unit("count") ///
    source("01_evidence/04_city_programs_lmf/LMF_FY26_awardee_list.pdf") ///
    note("Document-stated headline count, “399 awards totaling \$7,140,000.00.” Per this project’s mandatory accuracy constraint, the headline is used as authoritative; the list does not reconcile with itself (see city_lmf_fy26_venue_count_gap, city_lmf_fy26_musician_dollar_gap and city_lmf_fy26_subtotal_count_gap).")
local f : display %12.1fc `=`tot26'/1e6'
numadd, key(city_lmf_fy26_total) value("`tot26'") formatted("\$`=trim("`f'")'M") unit("nominal dollars") ///
    source("01_evidence/04_city_programs_lmf/LMF_FY26_awardee_list.pdf") ///
    note("Document-stated headline total. The two section subtotals (\$1,400,000 venues + \$5,740,000 musicians/promoters) sum exactly to this figure even though the itemized musician/promoter rows do not sum to their own stated subtotal (see city_lmf_fy26_musician_dollar_gap).")
local f : display %8.0fc `avg26'
numadd, key(city_lmf_fy26_avg) value("`avg26'") formatted("\$`=trim("`f'")'") unit("nominal dollars per award") ///
    source("01_evidence/04_city_programs_lmf/LMF_FY26_awardee_list.pdf") note("\$7,140,000 divided by the document-stated 399 awards.")

* FY2026 award-list internal inconsistencies, verified directly against the
* text extract of the source PDF (not merely copied from the evidence memo):
* the venue section names 21 venues but its own subtotal reads 20 / \$1,400,000
* (consistent with 20 x \$70,000, not 21); the musician/promoter section states
* "Funded: 377 ... \$5,740,000.00" but the 377 itemized rows (126 x \$5,000 +
* 251 x \$20,000) sum to only \$5,650,000; and the two section counts together
* (20 + 377 = 397, or 21 + 377 = 398) do not equal the document’s own overall
* headline of 399 awards under either reading. All three are registered.
numadd, key(city_lmf_fy26_venue_count_gap) value(1) formatted("21 named vs. 20 in the stated subtotal") ///
    unit("count") source("01_evidence/04_city_programs_lmf/LMF_FY26_awardee_list.pdf") ///
    note("21 venues are individually named in the FY2026 venue section, but the section’s own subtotal line reads “Total Live Music Venues Funded: 20” with \$1,400,000.00 (= 20 x \$70,000, not 21 x \$70,000 = \$1,470,000). Verified directly against the PDF text extract.")
numadd, key(city_lmf_fy26_musician_dollar_gap) value(90000) formatted("\$90,000 short of the stated \$5,740,000") ///
    unit("nominal dollars") source("01_evidence/04_city_programs_lmf/LMF_FY26_awardee_list.pdf") ///
    note("The musician/promoter section states “Funded: 377 ... \$5,740,000.00”; the 377 itemized rows (126 x \$5,000 + 251 x \$20,000 = \$5,650,000) sum \$90,000 short of that stated figure. The row count (377) matches exactly; only the dollar total does not.")
numadd, key(city_lmf_fy26_subtotal_count_gap) value(2) formatted("399 stated vs. 397 (20+377) from the two section subtotals") ///
    unit("count") source("01_evidence/04_city_programs_lmf/LMF_FY26_awardee_list.pdf") ///
    note("Additional inconsistency found while verifying this module (not previously logged in the evidence memo): the document’s overall headline of 399 awards does not equal the sum of its own two section-subtotal counts, 20 (venues) + 377 (musicians/promoters) = 397, nor the sum using the 21 individually named venues (398). The dollar headline (\$7,140,000) does reconcile exactly with the sum of the two stated dollar subtotals (\$1,400,000 + \$5,740,000). This module uses the document’s overall stated headline (399 awards, \$7,140,000) throughout and does not attempt to resolve the count discrepancy.")

numadd, key(city_lmf_fy27_budget) value(6000000) formatted("\$6.0M") unit("nominal dollars, budgeted") ///
    source("01_evidence/04_city_programs_lmf/page_LMF_program_page.md") ///
    note("FY2027 Live Music Fund cycle: \$6,000,000 available, tiers \$5,000 (12-month), \$20,000 (24-month), \$70,000 (venues, at least \$60,000 operating budget), administered by the Long Center for the Performing Arts. Applications open 2026-07-07 and close 2026-08-18 -- still open as of this module’s run date (2026-08-02) -- so no award count, total, or average exists yet. Not plotted in fig14; down from FY2026’s \$7.14M.")

* --- funded share where applicant counts exist -----------------------------
* Hand-entered: no CSV in this project carries applicant counts. Source is
* secondary reporting as compiled in _findings.md bullet 9 (itself citing the
* Austin Chronicle, 2025-03-28, for the FY2024 figure).
local appl23 = 660
local appl24 = 1013
local fundshare23 = 100 * 368 / `appl23'
local fundshare24 = 100 * 120 / `appl24'
display as text "  funded share: FY23 368/`appl23' = " %5.2f `fundshare23' "% | FY24 120/`appl24' = " %5.2f `fundshare24' "%"

numadd, key(city_lmf_fy23_applicants) value(`appl23') formatted("660") unit("count") ///
    source("01_evidence/04_city_programs_lmf/_findings.md") ///
    note("Press-reported FY2023 Live Music Fund applicant count; secondary reporting, no primary applicant tabulation was located (the FY23 summary dashboard is a JavaScript-gated Power BI embed with no static export).")
local f : display %5.2f `fundshare23'
numadd, key(city_lmf_fy23_funded_share) value("`fundshare23'") formatted("`=trim("`f'")'%") ///
    unit("percent of applicants funded") source("01_evidence/04_city_programs_lmf/_findings.md") ///
    note("368 awards (press count) divided by 660 applicants (same press source). Uses the press award count rather than the 369-row list tally so numerator and denominator trace to the same reporting.")
numadd, key(city_lmf_fy24_applicants) value(`appl24') formatted("1,013") unit("count") ///
    source("01_evidence/04_city_programs_lmf/_findings.md") ///
    note("Press-reported FY2024 applicant count requesting over \$23 million (Austin Chronicle, 2025-03-28).")
local f : display %5.2f `fundshare24'
numadd, key(city_lmf_fy24_funded_share) value("`fundshare24'") formatted("`=trim("`f'")'%") ///
    unit("percent of applicants funded") source("01_evidence/04_city_programs_lmf/_findings.md") ///
    note("120 artists selected (press figure) divided by 1,013 applicants. The FY2024 award list itself tallies 119 musician/promoter awards (excluding the 17 venue awards new that cycle); the 1-award gap between the press figure (120) and the primary list (119) is unresolved and both are reported here for transparency.")
numadd, key(city_lmf_fy26_applicants_not_published) value(0) formatted("not published") unit("count, unavailable") ///
    source("01_evidence/04_city_programs_lmf/_sources.md") ///
    note("No applicant count for the FY2026 Live Music Fund specifically has been published. The citywide FY2026 ACME news release reports 1,606 applicants requesting over \$67 million across all four programs (Elevate, Live Music Fund, CSAP, Heritage Preservation) combined, with 731 grants totaling over \$24 million (about 46% of applicants funded, about 36% of requested dollars) -- but this is program-wide, not LMF-specific, and cannot be used to back out an LMF applicant count.")

* --- FIG 14: awards (bars) and average award (line), FY2023-FY2026 --------
preserve
    keep fy awards total
    keep if inrange(fy, 2023, 2026)
    generate double avg_award = total / awards
    replace avg_award = . if awards == 0   // 0 awards means the ratio is undefined, not zero
    sort fy
    export delimited fy awards total avg_award using "${OUT}/fig14_lmf_cohorts.csv", replace

    quietly summarize awards
    local awdmax = ceil(1.15 * r(max) / 50) * 50
    quietly summarize avg_award
    local avgmax = ceil(1.15 * r(max) / 5000) * 5000

    * TITLE. The award count is not monotonic and the missing cycle is in the
    * MIDDLE of the run, not at the end, so the title names all four periods in
    * order and is built from the plotted values rather than typed in. The
    * previous title ("Fewer, larger Live Music Fund awards each cycle, then a
    * skipped year") was contradicted by the chart's own tallest bar: FY2026 is
    * the largest cohort shown (399) and its average award ($17,895) is below
    * FY2024's ($32,096), so neither "fewer" nor "larger" survives the last
    * transition. The three asserts below are what make the wording safe: each
    * one is the claim a word in the title makes.
    assert awards[2] < awards[1]     // "from 369 to 136"
    assert awards[3] == 0            // "to none": FY2025 ran no cycle at all
    assert awards[4] > awards[2]     // "then to 399" is a rebound, not a further fall
    local a1 = awards[1]
    local a2 = awards[2]
    local a4 = awards[4]
    local fig14_title = "Live Music Fund awards swung from `a1' to `a2' to none, then to `a4'"
    local _tlen = length("`fig14_title'")
    display as text "fig14 title length check: `_tlen' characters (target under ~70)."

    * Label y-positions sit just above each bar’s own height (not a fixed
    * height for all four), since awards range from 0 to 399.
    local lab23 = `awd23' + 0.05 * `awdmax'
    local lab24 = `awd24' + 0.05 * `awdmax'
    local lab25 = 0.05 * `awdmax'
    local lab26 = `awd26' + 0.05 * `awdmax'

    * The average-award value at each cycle, printed on the marker. Without
    * these the FY2026 marker was a lone navy dot inside the orange bar, with
    * no line reaching it and no number attached, and read as a print blemish.
    * A white box keeps the two markers that fall inside a bar legible.
    local t : display %9.0fc `=avg_award[1]'
    local avglab23 = strtrim("`t'")
    local t : display %9.0fc `=avg_award[2]'
    local avglab24 = strtrim("`t'")
    local t : display %9.0fc `=avg_award[4]'
    local avglab26 = strtrim("`t'")

    * Dashed bridge across the missing FY2025 so the FY2026 marker reads as
    * part of the navy series. Dashed rather than solid because there is no
    * FY2025 value to interpolate: the segment spans a gap in the cycle
    * calendar, it does not assert an average award inside it.
    generate double avg_bridge = avg_award if inlist(fy, 2024, 2026)

    twoway ///
      (bar awards fy, barwidth(0.6) color("${ORANGE}%80") lcolor("${ORANGE}") yaxis(1)) ///
      (line avg_bridge fy, yaxis(2) lcolor("${NAVY}") lwidth(medium) lpattern(dash)) ///
      (connected avg_award fy, yaxis(2) lcolor("${NAVY}") lwidth(medthick) ///
            mcolor("${NAVY}") msymbol(O) msize(small) cmissing(n)) ///
      , ytitle("Awards", axis(1) $YTOPT) ///
        ylabel(0(100)`awdmax', axis(1) angle(0) labsize(2.8)) ///
        ytitle("Average award, nominal dollars", axis(2) color("${NAVY}") $YTOPT) ///
        ylabel(0(10000)`avgmax', axis(2) angle(0) labsize(2.6) labcolor("${NAVY}") format(%9.0fc)) ///
        xtitle("") xlabel(2023(1)2026, labsize(2.8)) xscale(range(2022.5 2026.5)) ///
        text(`lab23' 2023 "369", placement(n) size(2.6) color("${TEXTC}")) ///
        text(`lab24' 2024 "136", placement(n) size(2.6) color("${TEXTC}")) ///
        text(`lab25' 2025 "0 (no cycle)", placement(n) size(2.6) color("${TEXTC}")) ///
        text(`lab26' 2026 "399", placement(n) size(2.6) color("${TEXTC}")) ///
        text(`=avg_award[1]' 2023 "\$`avglab23'", yaxis(2) placement(n) size(2.5) ///
             color("${NAVY}") box bcolor(white) blcolor(white) bmargin(vsmall)) ///
        text(`=avg_award[2]' 2024 "\$`avglab24'", yaxis(2) placement(n) size(2.5) ///
             color("${NAVY}") box bcolor(white) blcolor(white) bmargin(vsmall)) ///
        text(`=avg_award[4]' 2026 "\$`avglab26'", yaxis(2) placement(n) size(2.5) ///
             color("${NAVY}") box bcolor(white) blcolor(white) bmargin(vsmall)) ///
        legend(order(1 "Awards (left axis)" 3 "Average award (right axis)") ///
               cols(1) position(6) size(2.7) region(lstyle(none)) symxsize(6)) ///
        title("`fig14_title'", $TITLEOPT) ///
        subtitle("Awards made and average award per cycle, City of Austin Live Music Fund, nominal dollars." ///
                 "No FY2025 cycle ran; those applications were deferred into the FY2026 cycle.", $SUBOPT) ///
        graphregion(color(white)) ysize(5.4) xsize(8.2) ///
        name(fig14, replace)
    figsave, name(fig14_lmf_cohorts)
restore


* ===========================================================================
* 5. TASK 4 - CONTEXT: ICONIC VENUE FUND AND CREATIVE SPACE ASSISTANCE
*    PROGRAM, REQUESTED-TO-AWARDED RATIOS AS A MEASURE OF UNMET DEMAND
* ===========================================================================
* --- Iconic Venue Fund: no CSV carries this; hand-entered from the venues-
* ecosystem evidence stream (Austin Chronicle, 2023-08-24), which is where
* this fact was found and verified, not 04_city_programs_lmf. -------------
local ivf_proposals    45
local ivf_requested    300000000    /* stated as "over $300 million," a floor */
local ivf_shortlisted  14
local ivf_awards_2023  1
local ivf_award_amt    1600000
local ivf_ratio  = `ivf_requested' / `ivf_award_amt'
local ivf_share_funded = 100 * `ivf_awards_2023' / `ivf_proposals'
display as text "Iconic Venue Fund: `ivf_proposals' proposals requesting >= \$`ivf_requested', `ivf_shortlisted' shortlisted, `ivf_awards_2023' awarded \$`ivf_award_amt' as of 2023-08-15. Ratio >= " %6.1f `ivf_ratio' "x"

local srcIVF "01_evidence/08_venues_ecosystem/_findings.md"
numadd, key(city_ivf_proposals) value(`ivf_proposals') formatted("45") unit("count") source("`srcIVF'") ///
    note("Proposals received by Austin’s Iconic Venue Fund as of its first award, 15 Aug 2023 (Austin Chronicle, 2023-08-24). This is a capital-preservation fund managed by the Austin Economic Development Corporation, distinct from the Live Music Fund; capitalized from hotel occupancy tax revenue plus a 2018 bond package.")
numadd, key(city_ivf_requested) value(`ivf_requested') formatted("more than \$300M") unit("nominal dollars, requested, floor") ///
    source("`srcIVF'") note("Combined dollar amount requested across the 45 proposals; reported only as “over \$300 million,” a stated floor, not an exact figure.")
numadd, key(city_ivf_shortlisted) value(`ivf_shortlisted') formatted("14") unit("count") source("`srcIVF'") ///
    note("Proposals shortlisted from the 45 received, as of the fund’s first award in August 2023.")
local f : display %9.0fc `ivf_award_amt'
numadd, key(city_ivf_award_2023) value("`ivf_award_amt'") formatted("\$1.6M") unit("nominal dollars") source("`srcIVF'") ///
    note("The fund’s first award: \$1,600,000 to Hole in the Wall, 15 Aug 2023, roughly three years after the fund’s 2020 creation. `srcIVF' tags this secondary (Austin Chronicle); no primary award announcement was located.")
local f : display %6.1f `ivf_ratio'
numadd, key(city_ivf_requested_to_award_ratio) value("`ivf_ratio'") formatted("more than `=trim("`f'")'x") ///
    unit("ratio, dollars requested to dollars awarded") source("`srcIVF'") ///
    note("Dollars requested (floor of \$300M) divided by the single \$1.6M award, as of August 2023. Because the requested figure is itself a stated floor, the true ratio is at least this large. IMPORTANT CAVEAT: this is a snapshot at the fund’s first disbursement, not its current state -- the Open Budget data show \$15,300,000 cumulative Iconic Venue Fund grants to subrecipients FY2021-FY2026 (see city_ivf_cumulative_net_nominal_fy26), meaning substantially more has been awarded since 2023. No updated post-2023 proposal count, shortlist, or award list was located, so this ratio cannot be refreshed to the present with available evidence; it measures unmet demand at the moment the fund made its first award, not unmet demand today.")
local f : display %5.2f `ivf_share_funded'
numadd, key(city_ivf_share_proposals_funded_2023) value("`ivf_share_funded'") formatted("`=trim("`f'")'%") ///
    unit("percent of proposals") source("`srcIVF'") ///
    note("1 of 45 proposals had been funded as of August 2023 (2.2%); 14 of 45 (31.1%) had been shortlisted. Same 2023-snapshot caveat as city_ivf_requested_to_award_ratio.")

* Iconic Venue Fund revenue/expense pattern, from the panel built in section 1.
use "${OUT}/city_hot_fund_panel.dta", clear
keep if inrange(year, 2021, 2026)
generate double net_nominal_ivf = revenue_actual_ivf - expense_actual_ivf
sort year
generate double cum_net_nominal_ivf = sum(net_nominal_ivf)
quietly summarize cum_net_nominal_ivf if year == 2026, meanonly
local ivf_cumnet26 = r(mean)
quietly summarize expense_actual_ivf if year == 2022, meanonly
local ivf_exp22 = r(mean)
quietly summarize revenue_actual_ivf if year == 2022, meanonly
local ivf_rev22 = r(mean)
local srcHOT "01_evidence/04_city_programs_lmf/derived_HOT_fund_revenue_expense_FY2021_FY2027.csv"

local ivf_cumnet26_abs = abs(`ivf_cumnet26')
local f : display %12.1fc `=`ivf_cumnet26_abs'/1e6'
numadd, key(city_ivf_cumulative_net_nominal_fy26) value("`ivf_cumnet26'") formatted("-\$`=trim("`f'")'M") ///
    unit("nominal dollars, cumulative FY2021-FY2026") source("`srcHOT'") ///
    note("Iconic Venue Fund cumulative revenue minus expenditure, FY2021-FY2026, nominal (cash-flow proxy, not an audited balance, same caveat as the Live Music Fund figure). The fund is drawing down: FY2026 alone spent \$2,900,000 against \$4,614 in recorded revenue.")
local ivfrev22fmt : display %9.0fc `ivf_rev22'
numadd, key(city_ivf_fy22_zero_spend) value("`ivf_exp22'") formatted("\$0 spent vs. \$2.5M collected") ///
    unit("nominal dollars") source("`srcHOT'") ///
    note("Iconic Venue Fund spent \$0 in FY2022 despite collecting \$`=trim("`ivfrev22fmt'")' that year -- consistent with the Chronicle’s account of a roughly three-year lag between the fund’s creation and its first disbursement (August 2023), i.e. an early-implementation lag rather than an ongoing pattern.")

* --- Creative Space Assistance Program: the 2020 Disaster Relief round is the
* only CSAP round with both a requested and an awarded dollar figure. FY19,
* FY23 and FY26 have award totals but no published applicant or request count.
local csap_applicants_2020 = 65
local csap_funded_2020 = 32
local csap_requested_2020 = 3700000
local csap_available_2020 = 1000000
local csap_awarded_2020 = 987943
local csap_oversub_avail = `csap_requested_2020' / `csap_available_2020'
local csap_oversub_award = `csap_requested_2020' / `csap_awarded_2020'
local csap_fundshare_2020 = 100 * `csap_funded_2020' / `csap_applicants_2020'
display as text "CSAP 2020 Disaster Relief: `csap_applicants_2020' applicants, `csap_funded_2020' funded (" %5.1f `csap_fundshare_2020' "%), requested \$`csap_requested_2020' vs. awarded \$`csap_awarded_2020' (" %4.2f `csap_oversub_award' "x)"

local srcCSAP "01_evidence/04_city_programs_lmf/page_CSAP_program_page.md"
numadd, key(city_csap_2020_applicants) value(`csap_applicants_2020') formatted("65") unit("count") source("`srcCSAP'") ///
    note("2020 Austin Creative Space Disaster Relief Program applicants. This is the only CSAP round with a published applicant count; FY19, FY23 and FY26 award lists carry no applicant or request figures.")
local f : display %5.1f `csap_fundshare_2020'
numadd, key(city_csap_2020_funded_share) value("`csap_fundshare_2020'") formatted("`=trim("`f'")'%") ///
    unit("percent of applicants funded") source("`srcCSAP'") note("32 of 65 2020 Disaster Relief applicants funded.")
local f : display %4.2f `csap_oversub_avail'
numadd, key(city_csap_2020_oversub_vs_available) value("`csap_oversub_avail'") formatted("`=trim("`f'")'x") ///
    unit("ratio, dollars requested to dollars available") source("`srcCSAP'") ///
    note("\$3.7 million requested against \$1 million available in the 2020 Disaster Relief round -- the program page’s own framing (“nearly four times”).")
local f : display %4.2f `csap_oversub_award'
numadd, key(city_csap_2020_oversub_vs_awarded) value("`csap_oversub_award'") formatted("`=trim("`f'")'x") ///
    unit("ratio, dollars requested to dollars awarded") source("`srcCSAP'") ///
    note("\$3.7 million requested divided by the \$987,943 actually disbursed to 32 of 65 applicants.")

* CSAP award totals by cycle (no request/applicant data for these three).
numadd, key(city_csap_fy19_awards) value(19) formatted("19 awards, \$590,874") unit("count and nominal dollars") ///
    source("01_evidence/04_city_programs_lmf/CSAP_FY19_awards.pdf") ///
    note("FY2019 Creative Space Assistance Program, range \$6,248-\$50,000, average \$31,099. No applicant or request count published.")
numadd, key(city_csap_fy23_awards) value(64) formatted("64 awards, \$1,481,126") unit("count and nominal dollars") ///
    source("01_evidence/04_city_programs_lmf/CSAP_FY23_awards.pdf") ///
    note("FY2023 CSAP, range \$5,000-\$50,000, average \$23,143. No applicant or request count published.")
numadd, key(city_csap_fy26_awards) value(22) formatted("22 awards, \$1,320,000") unit("count and nominal dollars") ///
    source("01_evidence/04_city_programs_lmf/CSAP_FY26_awards.pdf") ///
    note("FY2026 CSAP, a flat \$60,000 per award (22 x \$60,000 = \$1,320,000 exactly). No applicant or request count published; this is one of ACME’s four FY2026 programs (Elevate, Live Music Fund, CSAP, Heritage Preservation) whose combined applicant pool was 1,606 (see city_lmf_fy26_applicants_not_published).")


* ===========================================================================
* 6. TASK 5 - LONG-RUN CULTURAL FUNDING AWARDS, 1982-FY2023, REAL 2025$
*    (Cultural Arts Fund. NOT the Live Music Fund. Missing FY2022. Ends FY2023.)
* ===========================================================================
import delimited "${EV_CITY}/socrata/x6aj-qng8_cultural_funding_awards.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve) bindquotes(strict)
quietly count
local nrows = r(N)
display as text "Cultural Funding Awards rows imported: `nrows' (expect 6,476)"
assert `nrows' == 6476

* fiscal_year is an end-of-fiscal-year date string, e.g. "2005-09-30T00:00:00.000".
* Austin’s FY is named for its ending year, so the leading 4 digits are the FY
* number directly -- no shift needed (contrast with the calendar-year
* deflator approximation used elsewhere in this module, which is a different
* question: this step reads the FY number off the label; the deflator step
* separately approximates which calendar year’s CPI to apply to it).
quietly count if substr(fiscal_year, 6, 5) != "09-30"
if r(N) > 0 {
    display as error "  WARNING: `r(N)' rows have a fiscal_year date not ending 09-30; check before trusting the FY extraction."
}
generate int fy = real(substr(fiscal_year, 1, 4))
quietly summarize fy
display as text "  FY range: " r(min) "-" r(max)
assert r(min) == 1982

collapse (sum) award_nominal = award (count) n_awards = award, by(fy)
quietly count if fy == 2022
display as text "  rows for FY2022: " r(N) " (expect 0 -- the dataset skips this year entirely)"
assert r(N) == 0

tsset fy
tsfill, full
* tsfill inserts a true FY2022 row with award_nominal and n_awards missing.
* Replaced with an explicit zero and flagged, per the same "genuine zero, not
* a silent gap" standard applied to the Live Music Fund’s FY2025.
replace n_awards = 0 if fy == 2022 & missing(n_awards)
replace award_nominal = 0 if fy == 2022 & missing(award_nominal)
generate byte fy2022_gap = (fy == 2022)

rename fy year
merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) keepusing(defl) nogenerate
rename year fy
generate double award_real = award_nominal * defl
* BLS_CPI.dta, as staged in this project, covers 2000 forward only, so
* cpi_annual.dta has no row before 2000. Real dollars cannot be built for
* FY1982-FY1999 with data available in this project; registered explicitly
* rather than left as an unexplained run of missing values.
quietly count if fy < 2000
local npre2000 = r(N)
quietly summarize n_awards if fy < 2000, meanonly
local awards_pre2000 = r(sum)
quietly summarize award_nominal if fy < 2000, meanonly
local dollars_pre2000 = r(sum)
display as text "  FY1982-FY1999: `awards_pre2000' awards, \$`dollars_pre2000' nominal, not deflatable (no CPI coverage before 2000 in this project)."

sort fy
list fy n_awards award_nominal award_real if inlist(fy,1982,2005,2019,2021,2022,2023), clean noobs

* --- validation against the evidence memo’s already-cited figures ---------
foreach y in 2005 2019 2021 2023 {
    quietly summarize n_awards if fy == `y', meanonly
    local n_`y' = r(mean)
    quietly summarize award_nominal if fy == `y', meanonly
    local d_`y' = r(mean)
}
display as text "  FY2005: `n_2005' awards, \$`d_2005' (memo: 192, \$2.64M)"
display as text "  FY2019: `n_2019' awards, \$`d_2019' (memo: 401, \$11.51M, pre-pandemic peak)"
display as text "  FY2021: \$`d_2021' (memo: \$5.75M)"
display as text "  FY2023: `n_2023' awards, \$`d_2023' (memo: 288, \$10.43M)"

quietly summarize n_awards, meanonly
local ntotal = r(sum)
quietly summarize award_nominal, meanonly
local dollartotal_nominal = r(sum)
quietly summarize award_real if fy >= 2000, meanonly
local dollartotal_real_2000plus = r(sum)
quietly summarize award_nominal if fy >= 2000, meanonly
local dollartotal_nominal_2000plus = r(sum)

export delimited fy n_awards award_nominal award_real fy2022_gap ///
    using "${TABDIR}/city_cultural_funding_awards_by_fy.csv", replace
display as text "  table -> out/tables/city_cultural_funding_awards_by_fy.csv"

local srcCFA "01_evidence/04_city_programs_lmf/socrata/x6aj-qng8_cultural_funding_awards.csv"
local cfanote "Cultural Funding Awards dataset: this covers the Cultural Arts Fund, NOT the Live Music Fund, and must not be read as music-program spending. Missing FY2022 entirely (confirmed: 0 rows); ends at FY2023 with nothing published since."

numadd, key(city_cfa_total_awards_count) value(`ntotal') formatted("6,476") unit("count, 1982-FY2023") ///
    source("`srcCFA'") note("Total individual cultural funding awards, all fiscal years in the dataset. `cfanote'")
local f : display %12.1fc `=`dollartotal_nominal'/1e6'
numadd, key(city_cfa_total_nominal) value("`dollartotal_nominal'") formatted("\$`=trim("`f'")'M") ///
    unit("nominal dollars, 1982-FY2023, not deflated") source("`srcCFA'") ///
    note("Sum of all 6,476 awards in the dollars originally recorded each year (mixed vintages, not comparable across decades without deflation). `cfanote'")
local dpre2000fmt : display %12.0fc `dollars_pre2000'
local d2000plusfmt : display %12.0fc `dollartotal_nominal_2000plus'
local apre2000fmt : display %6.0fc `awards_pre2000'
* NOTE: npre2000 (from "count if fy < 2000" on the fy-collapsed data) counts
* pre-2000 FISCAL YEARS (18), not awards. The award count is awards_pre2000
* (sum of n_awards), a different and much larger number (1,055). Caught by
* comparing this section's registered figures against its own display-line
* output before treating the run as clean; the two must not be confused.
local n2000plus = 6476 - `awards_pre2000'

local f : display %12.1fc `=`dollartotal_real_2000plus'/1e6'
numadd, key(city_cfa_total_real_fy2000_2023) value("`dollartotal_real_2000plus'") formatted("\$`=trim("`f'")'M") ///
    unit("2025 dollars, FY2000-FY2023 only") source("`srcCFA'") ///
    note("Real-dollar total restricted to FY2000-FY2023 (`n2000plus' of 6,476 awards; \$`=trim("`d2000plusfmt'")' nominal dollars), because BLS_CPI.dta as staged in this project carries no CPI data before calendar year 2000. FY1982-FY1999 (`=trim("`apre2000fmt'")' awards over `npre2000' fiscal years, \$`=trim("`dpre2000fmt'")' nominal) cannot be deflated to 2025 dollars with data available in this project and are EXCLUDED from this real-dollar total; see city_cfa_pre2000_awards for their nominal-only size. `fynote'")
numadd, key(city_cfa_pre2000_awards) value(`awards_pre2000') formatted("`=trim("`apre2000fmt'")' awards, \$`=trim("`dpre2000fmt'")' nominal, not deflatable") ///
    unit("count and nominal dollars, FY1982-FY1999 (18 fiscal years)") source("`srcCFA'") ///
    note("Portion of the 6,476-award series with no available CPI deflator in this project (BLS_CPI.dta starts calendar year 2000). Could not be converted to 2025 dollars; reported nominal only. This is the one figure in this module the task’s real-2025-dollars instruction could not be fully met for.")

local f : display %6.1fc `=`d_2005'/1e6'
numadd, key(city_cfa_fy2005) value("`d_2005'") formatted("`n_2005' awards, \$`=trim("`f'")'M nominal") unit("count and nominal dollars") ///
    source("`srcCFA'") note("`cfanote'")
local f : display %6.1fc `=`d_2019'/1e6'
numadd, key(city_cfa_fy2019_peak) value("`d_2019'") formatted("`n_2019' awards, \$`=trim("`f'")'M nominal, pre-pandemic peak") ///
    unit("count and nominal dollars") source("`srcCFA'") note("`cfanote'")
local f : display %6.1fc `=`d_2021'/1e6'
numadd, key(city_cfa_fy2021) value("`d_2021'") formatted("\$`=trim("`f'")'M nominal") unit("nominal dollars") ///
    source("`srcCFA'") note("Pandemic-year trough. `cfanote'")
local f : display %6.1fc `=`d_2023'/1e6'
numadd, key(city_cfa_fy2023_last) value("`d_2023'") formatted("`n_2023' awards, \$`=trim("`f'")'M nominal, last year in the dataset") ///
    unit("count and nominal dollars") source("`srcCFA'") note("`cfanote'")


display as text _newline "40_city_money.do complete"
