*! 20_wages_industry.do - musician wages against comparison creative occupations,
*!   the payroll-to-gig substitution, QCEW industry detail, and a four-metro
*!   nonemployer comparison.
*! Inputs  : 01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv
*!           01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv
*!           01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv
*!           03_analysis/data/external/Census_PEP_TX_County_Components.dta
*!           03_analysis/data/external/BLS_OEWS_TX.dta (cross-check only)
*!           03_analysis/out/cpi_annual.dta (built by _setup.do)
*! Outputs : 04_figures/fig06_payroll_vs_nonemployer.png (+ .csv)
*!           04_figures/fig07_real_wage_trend.png (+ .csv)
*!           04_figures/fig08_metro_nonemployer.png (+ .csv)
*!           03_analysis/out/numbers/numbers_wages.csv
*!           03_analysis/out/tables/qcew_industry_detail.csv
*!           03_analysis/out/tables/nes_metro_detail.csv

clear all
do "_setup.do"
global CURMODULE "wages"
numinit

requirefile "${EV_WAGES}/oews_musicians_creatives_2005_2025.csv"
requirefile "${EV_WAGES}/qcew_arts_industries_2001_2025.csv"
requirefile "${EV_PUMS}/nes_independent_artists_long.csv"
requirefile "${DATAX}/Census_PEP_TX_County_Components.dta"
requirefile "${DATAX}/BLS_OEWS_TX.dta"

* Occupation codes analyzed throughout, with short slugs for registry keys.
* Order fixed across all loops below so occ-code and slug stay aligned.
local occ_codes "27-2042 27-2041 27-4014 27-1024 27-3043 27-2011 00-0000"
local occ_slugs "musicians musicdirectors soundeng graphicdesign writers actors allocc"
local occ_labs  `""Musicians and Singers" "Music Directors and Composers" "Sound Engineering Technicians" "Graphic Designers" "Writers and Authors" "Actors" "All Occupations""'

local geo_levels "MSA State National"
local geo_slugs  "austin tx us"
local geo_labs   `""Austin MSA" "Texas" "United States""'


* ================================================================
* SECTION 1. Build the OEWS analysis panel: real hourly/annual wages
*            and payroll employment, 2005-2025, 7 occupations x 3 geos.
* ================================================================
import delimited "${EV_WAGES}/oews_musicians_creatives_2005_2025.csv", ///
    varnames(1) case(preserve) clear
keep if inlist(occ_code, "27-2042","27-2041","27-4014","27-1024","27-3043","27-2011","00-0000")
keep year geo_level occ_code occ_title tot_emp h_mean h_median a_mean a_median

* Real dollars: merge the shared CPI-U deflator and multiply. Every wage
* variable below carries a _real suffix; the nominal columns are left alone
* so nothing is ambiguous about which is which.
merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) nogenerate
foreach v in h_mean h_median a_mean a_median {
    generate double `v'_real = `v' * defl
    label variable `v'_real "`v', 2025 dollars"
}
label variable tot_emp "Wage-and-salary employment (OEWS), payroll jobs only"

quietly count
display as text "OEWS analysis panel: `r(N)' rows (7 occupations x up to 3 geographies x up to 21 years)."
tempfile oews_panel
save `oews_panel'


* ================================================================
* SECTION 2. Cross-check: Texas OEWS figures in the evidence CSV against
*            BLS_OEWS_TX.dta, an independently maintained Texas OEWS panel.
* ================================================================
use `oews_panel', clear
keep if geo_level == "State"
keep year occ_code occ_title tot_emp a_mean a_median
rename (tot_emp a_mean a_median) (tot_emp_ev a_mean_ev a_median_ev)
tempfile ev_tx
save `ev_tx'

use "${DATAX}/BLS_OEWS_TX.dta", clear
keep if inlist(occ_code, "27-2042","27-2041","27-4014","27-1024","27-3043","27-2011","00-0000")
rename (tot_emp a_mean a_median) (tot_emp_chk a_mean_chk a_median_chk)
merge 1:1 occ_code year using `ev_tx', keep(match master using) generate(mrg_check)

display as text _newline "{hline 72}"
display as text "CROSS-CHECK: evidence CSV (Texas rows) vs BLS_OEWS_TX.dta, 2005-2024 overlap"
display as text "{hline 72}"
tabulate mrg_check
* mrg_check==3 is the only comparable set (present in both files); 1=evidence-only
* (2025, since the cross-check library stops at 2024), 2=cross-check-only (occupations
* outside this module's 7-code list, dropped above by the keep).

generate diff_emp    = tot_emp_ev    - tot_emp_chk    if mrg_check==3
generate diff_amean  = a_mean_ev     - a_mean_chk      if mrg_check==3
generate diff_amedian= a_median_ev   - a_median_chk    if mrg_check==3

quietly count if mrg_check==3
local n_comparable = r(N)
quietly count if mrg_check==3 & diff_emp==0
local n_emp_exact = r(N)
quietly count if mrg_check==3 & !missing(diff_emp) & diff_emp!=0
local n_emp_diff = r(N)
quietly summarize diff_emp if mrg_check==3, detail
local emp_maxabsdiff = max(abs(r(min)), abs(r(max)))

quietly count if mrg_check==3 & !missing(a_median_ev) & !missing(a_median_chk)
local n_amedian_both = r(N)
quietly count if mrg_check==3 & !missing(a_median_ev) & !missing(a_median_chk) & diff_amedian==0
local n_amedian_exact = r(N)

display as text "Comparable occupation-year cells (both files, 7 target occ codes, 2005-2024): `n_comparable'"
display as text "  Employment (tot_emp): exact match `n_emp_exact' of `n_comparable'; " ///
    "max abs diff = `emp_maxabsdiff' jobs"
display as text "  Annual median wage, cells where BOTH files publish a value: " ///
    "`n_amedian_exact' of `n_amedian_both' exact"
list occ_code year tot_emp_ev tot_emp_chk diff_emp a_median_ev a_median_chk diff_amedian ///
    if mrg_check==3 & (diff_emp!=0 & !missing(diff_emp)), clean

numadd, key(crosscheck_emp_exact_share) value(`=cond(`n_comparable'>0, round(100*`n_emp_exact'/`n_comparable',0.1), .)') ///
    formatted("`=string(round(100*`n_emp_exact'/`n_comparable',0.1),"%4.1f")'%") unit("percent of comparable cells") ///
    source("03_analysis/data/external/BLS_OEWS_TX.dta") ///
    note("Cross-check of evidence CSV Texas OEWS employment against the author's independent BLS_OEWS_TX.dta panel, 7 target occ codes, 2005-2024 overlap (n=`n_comparable' cells). `n_emp_exact' cells match exactly; max abs diff `emp_maxabsdiff' jobs. See module return notes for any discrepancy detail.")

drop mrg_check
tempfile crosscheck_result
save `crosscheck_result'


* ================================================================
* TASK 1. Real hourly wage trends, 2005-2025, and TASK 2. payroll employment
*         trends + pct change 2005-2025, for each of the 7 occupations x 3
*         geographies. BLS does not publish an annual wage for Musicians and
*         Actors in most rows (a standing BLS convention for occupations with
*         heavy part-year work, not an extraction gap), so hourly wages are
*         the only series comparable across all 7 occupations; this module
*         uses the hourly median throughout and records the reason here.
* ================================================================
use `oews_panel', clear

* Verify directly, rather than assume, how absolute the annual-wage gap is.
quietly count if occ_code=="27-2042"
local n_musi_rows = r(N)
quietly count if occ_code=="27-2042" & missing(a_median)
local n_musi_blank = r(N)
quietly count if occ_code=="27-2011"
local n_act_rows = r(N)
quietly count if occ_code=="27-2011" & missing(a_median)
local n_act_blank = r(N)
display as text "Annual median wage (a_median) blank: Musicians `n_musi_blank' of `n_musi_rows' rows; Actors `n_act_blank' of `n_act_rows' rows (expect both ratios to be 100%, an absolute non-publication, not partial suppression)."
assert `n_musi_blank' == `n_musi_rows'
assert `n_act_blank'  == `n_act_rows'

numadd, key(wage_series_choice_hourly) value(1) formatted("hourly, not annual") ///
    unit("methodological note") ///
    source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
    note("BLS does not publish an annual wage for Musicians and Singers (a_median blank in all `n_musi_rows' of `n_musi_rows' occupation-geography-year rows in this extract) or for Actors (blank in all `n_act_rows' of `n_act_rows' rows). This is an absolute, standing BLS non-publication for occupations with too much part-year/irregular work to annualize meaningfully, not disclosure suppression and not a data-collection gap. This module therefore uses the median HOURLY wage (h_median) as the one series comparable across all 7 occupations and 3 geographies, and at no point constructs an annual figure for musicians or actors by multiplying an hourly wage by assumed hours; annual figures are used only for the other 5 occupations, where BLS publishes them directly.")

display as text _newline "{hline 72}"
display as text "TASK 1/2: real hourly wage and payroll employment, by occupation x geography"
display as text "{hline 72}"

local i = 0
foreach oc of local occ_codes {
    local i = `i' + 1
    local os : word `i' of `occ_slugs'
    local ol : word `i' of `occ_labs'
    local j = 0
    foreach gl of local geo_levels {
        local j = `j' + 1
        local gs : word `j' of `geo_slugs'
        local gll : word `j' of `geo_labs'

        * ---- wage: median hourly, real 2025$ ----
        quietly count if occ_code=="`oc'" & geo_level=="`gl'" & !missing(h_median_real)
        local nvalid = r(N)
        if `nvalid' >= 2 {
            quietly summarize year if occ_code=="`oc'" & geo_level=="`gl'" & !missing(h_median_real)
            local fy = r(min)
            local ly = r(max)
            quietly summarize h_median_real if occ_code=="`oc'" & geo_level=="`gl'" & year==`fy', meanonly
            local v0 = r(mean)
            quietly summarize h_median_real if occ_code=="`oc'" & geo_level=="`gl'" & year==`ly', meanonly
            local v1 = r(mean)
            local pct = (`v1'/`v0' - 1)*100
            local yrnote = ""
            if `fy'!=2005 | `ly'!=2025 {
                local yrnote " Actual window `fy'-`ly', not 2005-2025: BLS did not publish an Austin MSA hourly wage for `ol' in every year of the full series."
            }
            numadd, key(wage_hourly_real_`os'_`gs'_first) value(`=round(`v0',0.01)') ///
                formatted("$`=string(round(`v0',0.01),"%9.2f")'") unit("2025 dollars per hour") ///
                source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
                note("`ol', `gll', median hourly wage, `fy', OEWS. Deflated from nominal `fy' dollars using ${OUT}/cpi_annual.dta.")
            numadd, key(wage_hourly_real_`os'_`gs'_last) value(`=round(`v1',0.01)') ///
                formatted("$`=string(round(`v1',0.01),"%9.2f")'") unit("2025 dollars per hour") ///
                source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
                note("`ol', `gll', median hourly wage, `ly', OEWS. 2025 dollars.")
            numadd, key(wage_hourly_pctchg_`os'_`gs') value(`=round(`pct',0.1)') ///
                formatted("`=cond(`pct'>=0,"+","")'`=string(round(`pct',0.1),"%4.1f")'%") unit("percent change, real hourly median wage") ///
                source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
                note("`ol', `gll', real median hourly wage change `fy' to `ly': $`=string(round(`v0',0.01),"%9.2f")' to $`=string(round(`v1',0.01),"%9.2f")', 2025 dollars.`yrnote'")
        }
        else {
            display as text "  [skip wage] `os' `gs': fewer than 2 non-missing years"
        }

        * ---- employment: payroll jobs, no deflation (a count, not a dollar figure) ----
        quietly count if occ_code=="`oc'" & geo_level=="`gl'" & !missing(tot_emp)
        local nvalid2 = r(N)
        if `nvalid2' >= 2 {
            quietly summarize year if occ_code=="`oc'" & geo_level=="`gl'" & !missing(tot_emp)
            local fy2 = r(min)
            local ly2 = r(max)
            quietly summarize tot_emp if occ_code=="`oc'" & geo_level=="`gl'" & year==`fy2', meanonly
            local e0 = r(mean)
            quietly summarize tot_emp if occ_code=="`oc'" & geo_level=="`gl'" & year==`ly2', meanonly
            local e1 = r(mean)
            local pcte = (`e1'/`e0' - 1)*100
            local yrnote2 = ""
            if `fy2'!=2005 | `ly2'!=2025 {
                local yrnote2 " Actual window `fy2'-`ly2', not 2005-2025: BLS did not publish Austin MSA payroll employment for `ol' in every year (occupation too small/volatile at the metro level to clear OEWS publication thresholds in every year)."
            }
            numadd, key(emp_payroll_`os'_`gs'_first) value(`=round(`e0',1)') ///
                formatted("`=string(`e0',"%9.0fc")'") unit("wage-and-salary jobs") ///
                source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
                note("`ol', `gll', OEWS payroll employment, `fy2'. Excludes the self-employed.")
            numadd, key(emp_payroll_`os'_`gs'_last) value(`=round(`e1',1)') ///
                formatted("`=string(`e1',"%9.0fc")'") unit("wage-and-salary jobs") ///
                source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
                note("`ol', `gll', OEWS payroll employment, `ly2'. Excludes the self-employed.")
            numadd, key(emp_payroll_pctchg_`os'_`gs') value(`=round(`pcte',0.1)') ///
                formatted("`=cond(`pcte'>=0,"+","")'`=string(round(`pcte',0.1),"%4.1f")'%") unit("percent change, payroll employment") ///
                source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
                note("`ol', `gll', payroll employment change `fy2' to `ly2': `=string(`e0',"%9.0fc")' to `=string(`e1',"%9.0fc")' jobs.`yrnote2'")
            display as text "  `os'/`gs': wage n=`nvalid' (`fy'-`ly'), emp n=`nvalid2' (`fy2'-`ly2') change=`=string(round(`pcte',0.1),"%4.1f")'%"
        }
        else {
            display as text "  [skip emp] `os' `gs': fewer than 2 non-missing years"
        }
    }
}

* Key Austin-specific comparison for 2025: does the musician's real hourly
* wage actually beat the metro's typical worker and Graphic Designers, as
* the underlying findings note? Verify directly rather than assume.
quietly summarize h_median_real if occ_code=="27-2042" & geo_level=="MSA" & year==2025, meanonly
local musi25 = r(mean)
quietly summarize h_median_real if occ_code=="00-0000" & geo_level=="MSA" & year==2025, meanonly
local allo25 = r(mean)
quietly summarize h_median_real if occ_code=="27-1024" & geo_level=="MSA" & year==2025, meanonly
local graf25 = r(mean)
quietly summarize h_median_real if occ_code=="27-2042" & geo_level=="MSA" & year==2005, meanonly
local musi05 = r(mean)
quietly summarize h_median_real if occ_code=="00-0000" & geo_level=="MSA" & year==2005, meanonly
local allo05 = r(mean)

display as text _newline "Austin MSA, 2025: musicians $`=string(`musi25',"%4.2f")' vs all-occ $`=string(`allo25',"%4.2f")' vs graphic designers $`=string(`graf25',"%4.2f")' (real hourly median)"
display as text "Austin MSA, 2005: musicians $`=string(`musi05',"%4.2f")' vs all-occ $`=string(`allo05',"%4.2f")'"
local musi_above_allocc_2025 = (`musi25' > `allo25')
local musi_above_allocc_2005 = (`musi05' > `allo05')
display as text "Musicians above all-occ median? 2005: `musi_above_allocc_2005'  2025: `musi_above_allocc_2025'"

numadd, key(wage_austin_musicians_vs_allocc_2025) value(`=round(`musi25'-`allo25',0.01)') ///
    formatted("$`=string(round(`musi25',0.01),"%4.2f")' vs $`=string(round(`allo25',0.01),"%4.2f")'") ///
    unit("2025 dollars per hour, real median") ///
    source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
    note("Austin MSA, May 2025: median hourly wage for Musicians and Singers ($`=string(round(`musi25',0.01),"%4.2f")') against the MSA all-occupation median ($`=string(round(`allo25',0.01),"%4.2f")'). MSA musician employment is only ~120 wage-and-salary jobs in 2025, so this is a small and volatile estimate, not a claim about the far larger self-employed/gig musician population.")

* Build the wide, year-indexed series used by fig07 (Austin MSA is the report's
* core geography; Texas Musicians and Singers is the one context line, per the
* figure spec "Austin MSA with Texas ... as context").
preserve
    keep if occ_code=="27-2042" & geo_level=="MSA"
    keep year h_median_real
    rename h_median_real msa_musicians
    tempfile f7_a
    save `f7_a'
restore
preserve
    keep if occ_code=="00-0000" & geo_level=="MSA"
    keep year h_median_real
    rename h_median_real msa_allocc
    tempfile f7_b
    save `f7_b'
restore
preserve
    keep if occ_code=="27-1024" & geo_level=="MSA"
    keep year h_median_real
    rename h_median_real msa_graphic
    tempfile f7_c
    save `f7_c'
restore
preserve
    keep if occ_code=="27-2042" & geo_level=="State"
    keep year h_median_real
    rename h_median_real tx_musicians
    tempfile f7_d
    save `f7_d'
restore

clear
use `f7_a'
merge 1:1 year using `f7_b', nogenerate
merge 1:1 year using `f7_c', nogenerate
merge 1:1 year using `f7_d', nogenerate
sort year
tempfile fig07_wide
save `fig07_wide'


* ================================================================
* FIGURE 7: real hourly wage trend, Austin MSA, 2005-2025.
* ================================================================
use `fig07_wide', clear

* Direct labels at each line's own last non-missing year (a line can end
* early if a series has a gap; label it where it actually stops).
foreach s in msa_musicians msa_allocc msa_graphic tx_musicians {
    quietly summarize year if !missing(`s')
    local ly_`s' = r(max)
}
* Title check against the plotted data: the "overtook" framing is only used
* if musicians are actually above the all-occupation median in the LAST
* plotted year (verified above against the loaded panel, not assumed), since
* that is what a reader can check by eye against the chart as drawn.
local ttl_ok = (`musi_above_allocc_2025'==1)
display as text "fig07 title check: musicians above Austin all-occ median in 2025 = `ttl_ok' (must be 1 to use the overtake framing)"

local fig7_title  = "Austin’s payroll musician wage now sits above the area median"
local fig7_sub1   = "Real median hourly wage, 2025 dollars, OEWS May 2005 to May 2025."
local fig7_sub2   = "OEWS counts payroll jobs only and excludes the self-employed;"
local fig7_sub3   = "the Austin line rests on about 120 jobs; axis does not start at zero."
if `ttl_ok'==0 {
    local fig7_title = "Austin payroll musician wages against comparison occupations"
}
local _tlen = length("`fig7_title'")
display as text "fig07 title length check: `_tlen' characters (target under ~70)."

* Direct-label y-coordinates are anchored to each line's own true 2025 (or
* last-available) value rather than left to Stata's automatic mlabel
* placement, which had nudged the two orange lines' labels away from their
* real endpoints to dodge a collision and left neither encoding solid vs
* dashed. Austin musicians and Graphic designers end within 0.2 of each
* other (both near 31 dollars/hour), so those two still need a small manual
* offset to stay legible; every offset below is under 3 dollars.
quietly summarize msa_musicians if year==`ly_msa_musicians', meanonly
local y_austin = r(mean)
quietly summarize msa_allocc if year==`ly_msa_allocc', meanonly
local y_allocc = r(mean)
quietly summarize msa_graphic if year==`ly_msa_graphic', meanonly
local y_graphic = r(mean)
quietly summarize tx_musicians if year==`ly_tx_musicians', meanonly
local y_txmusi = r(mean)
display as text "fig07 2025 endpoints: Austin musicians `y_austin', Texas musicians `y_txmusi', Graphic designers `y_graphic', All occupations `y_allocc'"
local lab_allocc  = `y_allocc'
local lab_graphic = `y_graphic' - 1
local lab_austin  = `y_austin'  + 2
local lab_txmusi  = `y_txmusi'  + 3

* Texas musicians gets its own colour (gold, not orange), so the two
* musician lines no longer share a colour. All four lines also carry a
* distinct line pattern, so the figure still separates once colour is
* removed. ygrid is dropped so no gridline can print through a label.
twoway ///
    (line msa_musicians year, lcolor("${ORANGE}") lpattern(solid) lwidth(medthick)) ///
    (line msa_allocc year, lcolor("${MUTED}") lpattern(dash)) ///
    (line msa_graphic year, lcolor("${NAVY}") lpattern(dash_dot)) ///
    (line tx_musicians year, lcolor("${GOLD}") lpattern(shortdash)) ///
    , ///
    title("`fig7_title'", $TITLEOPT) ///
    subtitle("`fig7_sub1'" "`fig7_sub2'" "`fig7_sub3'", $SUBOPT) ///
    xtitle("", $XTOPT) ytitle("2025 dollars per hour", $YTOPT) ///
    xlabel(2005(5)2025) ylabel(, angle(horizontal) nogrid) ///
    xscale(range(2005 2034)) ///
    text(`lab_austin' `ly_msa_musicians' "Austin musicians", color("${ORANGE}") size(3) placement(e)) ///
    text(`lab_txmusi' `ly_tx_musicians' "Texas musicians", color("${GOLD}") size(3) placement(e)) ///
    text(`lab_graphic' `ly_msa_graphic' "Graphic designers", color("${NAVY}") size(3) placement(e)) ///
    text(`lab_allocc' `ly_msa_allocc' "All occupations", color("${MUTED}") size(3) placement(e)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_fig07, replace)

figsave, name(fig07_real_wage_trend)

preserve
    export delimited year msa_musicians msa_allocc msa_graphic tx_musicians ///
        using "${OUT}/fig07_real_wage_trend.csv", replace
restore

display as text "fig07 complete."


* ================================================================
* SECTION 3. Build the QCEW analysis panel (real average annual pay) and
*            answer TASK 4: industry detail for NAICS 71113 and 7115.
* ================================================================
import delimited "${EV_WAGES}/qcew_arts_industries_2001_2025.csv", ///
    varnames(1) case(preserve) clear

* Correction check before doing anything else: 01_evidence/01_wages_oews_qcew's
* own documentation claims the broader NAICS 71 aggregate is never disclosure-
* suppressed at the Austin MSA level. Verify rather than repeat that claim.
quietly count if geography=="Austin_RoundRock_MSA" & industry_code==71 & own_code==5 & disclosure_code=="N"
local naics71_msa_supp = r(N)
if `naics71_msa_supp' > 0 {
    quietly levelsof year if geography=="Austin_RoundRock_MSA" & industry_code==71 & own_code==5 & disclosure_code=="N", local(naics71_supp_years)
    display as error "CORRECTION to 01_evidence/01_wages_oews_qcew/_findings.md and _sources.md: both state NAICS 71 (the broad Arts/Entertainment/Recreation aggregate) is never disclosure-suppressed at the Austin MSA level. That claim does not hold: `naics71_msa_supp' area-year(s) (`naics71_supp_years') are suppressed for NAICS 71, own_code=5, Austin MSA. This module does not use NAICS 71 in any figure or registered number, so the error does not propagate into this module's outputs, but the evidence folder's documentation should be corrected at the source."
}
numadd, key(naics71_msa_suppression_correction) value(`naics71_msa_supp') ///
    formatted("`naics71_msa_supp' area-year(s) suppressed") ///
    unit("correction to evidence-folder documentation, not used in this module") ///
    source("01_evidence/01_wages_oews_qcew/_findings.md") ///
    note("_findings.md and _sources.md in 01_evidence/01_wages_oews_qcew state NAICS 71 is not disclosure-suppressed at the Austin MSA level. Direct inspection of disclosure_code on the underlying CSV found `naics71_msa_supp' suppressed area-year(s) (`naics71_supp_years', own_code=5). This module does not use NAICS 71 for any figure or number, so the error does not affect anything registered here, but the evidence folder's own documentation should be corrected.")

* This module's own industries: NAICS 71113 and 7115, private sector.
keep if inlist(industry_code, 71113, 7115) & own_code==5
keep year geography industry_code industry_title annual_avg_estabs annual_avg_emplvl avg_annual_pay disclosure_code

* Disclosure-suppressed rows do NOT arrive as missing: BLS zeroes out
* annual_avg_emplvl and avg_annual_pay (establishment counts still show) and
* flags disclosure_code=="N". Averaging or plotting without checking that flag
* would silently pull real zeros into the series and understate every affected
* year, so count suppression per code first, then null the affected cells
* explicitly before any computation touches them.
quietly count if geography=="Austin_RoundRock_MSA" & industry_code==71113
local msa_n_71113 = r(N)
quietly count if geography=="Austin_RoundRock_MSA" & industry_code==71113 & disclosure_code=="N"
local msa_supp_71113 = r(N)
quietly count if geography=="Austin_RoundRock_MSA" & industry_code==7115
local msa_n_7115 = r(N)
quietly count if geography=="Austin_RoundRock_MSA" & industry_code==7115 & disclosure_code=="N"
local msa_supp_7115 = r(N)
display as text _newline "QCEW Austin MSA suppression (own_code=5): NAICS 71113 = `msa_supp_71113' of `msa_n_71113' area-years; NAICS 7115 = `msa_supp_7115' of `msa_n_7115' area-years. No MSA-level rows exist at all for 2025 (BLS metro rollups not yet finalized for that vintage), so the MSA series stops at 2024 regardless of suppression."

replace annual_avg_emplvl = . if disclosure_code=="N"
replace avg_annual_pay    = . if disclosure_code=="N"

numadd, key(qcew_suppression_handling_note) value(1) formatted("zeros nulled where disclosure_code equals N") ///
    unit("methodological note") ///
    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
    note("QCEW disclosure-suppressed rows do not arrive as missing: BLS records annual_avg_emplvl and avg_annual_pay as 0 in those rows (establishment counts still shown) and flags disclosure_code=N. This module explicitly replaces annual_avg_emplvl and avg_annual_pay with missing wherever disclosure_code=N before any average, trend, or registered figure, so a suppressed zero is never averaged into a real series. Travis County, Texas, and U.S. rows (own_code=5), this module's 3 headline geographies, carry no suppressed years for NAICS 71113 or 7115 across 2001-2025; suppression is confined to the Austin MSA level.")

numadd, key(qcew_msa_suppression_71113) value(`msa_supp_71113') formatted("`msa_supp_71113' of `msa_n_71113' years") ///
    unit("count of suppressed area-years") ///
    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
    note("NAICS 71113 (Musical Groups and Artists), private sector, Austin-Round Rock(-San Marcos) MSA: `msa_supp_71113' of `msa_n_71113' area-years (2001-2024; no 2025 MSA rows exist yet) have annual_avg_emplvl/avg_annual_pay withheld (disclosure_code=N; establishment counts still shown). Travis County has no suppressed years for this code and is used as the primary sub-state geography throughout this module for that reason.")

numadd, key(qcew_msa_suppression_7115) value(`msa_supp_7115') formatted("`msa_supp_7115' of `msa_n_7115' years") ///
    unit("count of suppressed area-years") ///
    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
    note("NAICS 7115 (Independent Artists, Writers, and Performers), private sector, Austin-Round Rock(-San Marcos) MSA: `msa_supp_7115' of `msa_n_7115' area-years (2001-2024) have annual_avg_emplvl/avg_annual_pay withheld (disclosure_code=N). Travis County has no suppressed years for this code.")

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) nogenerate
generate double avg_annual_pay_real = avg_annual_pay * defl
label variable avg_annual_pay_real "Average annual pay per private-sector worker, 2025 dollars"

* Keep the 3 headline geographies for the report; Austin MSA stays in the
* saved table (for the suppression note) but Travis County stands in for the
* metro throughout this module's figures and registry entries.
tempfile qcew_full
save `qcew_full'

preserve
    export delimited using "${TABDIR}/qcew_industry_detail.csv", replace
restore

display as text _newline "{hline 72}"
display as text "TASK 4: QCEW industry detail, NAICS 71113 and 7115, Travis/Texas/US"
display as text "{hline 72}"

use `qcew_full', clear
keep if inlist(geography, "Travis_County","TX_state","US_national")

local ind_codes "71113 7115"
local ind_slugs "musicalgroups indepartists"
local geoq_codes "Travis_County TX_state US_national"
local geoq_slugs "travis tx us"
local geoq_labs  `""Travis County" "Texas" "United States""'

local i = 0
foreach ic of local ind_codes {
    local i = `i' + 1
    local is : word `i' of `ind_slugs'
    local j = 0
    foreach gc of local geoq_codes {
        local j = `j' + 1
        local gqs : word `j' of `geoq_slugs'
        local gql : word `j' of `geoq_labs'

        quietly count if industry_code==`ic' & geography=="`gc'" & !missing(annual_avg_estabs)
        if r(N) < 2 {
            display as text "  [skip] naics `ic' `gqs': insufficient years"
            continue
        }
        quietly summarize year if industry_code==`ic' & geography=="`gc'" & !missing(annual_avg_estabs)
        local fy = r(min)
        local ly = r(max)

        foreach metric in annual_avg_estabs annual_avg_emplvl avg_annual_pay_real {
            quietly summarize `metric' if industry_code==`ic' & geography=="`gc'" & year==`fy', meanonly
            local v0 = r(mean)
            quietly summarize `metric' if industry_code==`ic' & geography=="`gc'" & year==`ly', meanonly
            local v1 = r(mean)
            if !missing(`v0') & !missing(`v1') & `v0'!=0 {
                local pct = (`v1'/`v0' - 1)*100
                local mslug = cond("`metric'"=="annual_avg_estabs","estabs", cond("`metric'"=="annual_avg_emplvl","emplvl","paynreal"))
                local munit = cond("`metric'"=="annual_avg_estabs","establishments", cond("`metric'"=="annual_avg_emplvl","private-sector jobs","2025 dollars, average annual pay"))
                local fmt0 = cond("`metric'"=="avg_annual_pay_real", "$"+string(round(`v0',1),"%9.0fc"), string(round(`v0',1),"%9.0fc"))
                local fmt1 = cond("`metric'"=="avg_annual_pay_real", "$"+string(round(`v1',1),"%9.0fc"), string(round(`v1',1),"%9.0fc"))
                numadd, key(qcew_`mslug'_`is'_`gqs'_first) value(`=round(`v0',1)') formatted("`fmt0'") unit("`munit'") ///
                    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
                    note("NAICS `ic', `gql', private sector, `fy'.")
                numadd, key(qcew_`mslug'_`is'_`gqs'_last) value(`=round(`v1',1)') formatted("`fmt1'") unit("`munit'") ///
                    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
                    note("NAICS `ic', `gql', private sector, `ly'.")
                numadd, key(qcew_`mslug'_pctchg_`is'_`gqs') value(`=round(`pct',0.1)') ///
                    formatted("`=cond(`pct'>=0,"+","")'`=string(round(`pct',0.1),"%4.1f")'%") unit("percent change") ///
                    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
                    note("NAICS `ic' (`is'), `gql', `munit' change `fy' to `ly': `fmt0' to `fmt1'.")
            }
        }
    }
}

* Registered caveats specific to Task 4's honesty requirements.
quietly summarize avg_annual_pay_real if industry_code==71113 & geography=="TX_state" & year==2024, meanonly
local tx71113_2024 = r(mean)
quietly summarize avg_annual_pay_real if industry_code==71113 & geography=="TX_state" & year==2025, meanonly
local tx71113_2025 = r(mean)
quietly summarize avg_annual_pay_real if industry_code==71113 & geography=="US_national" & year==2024, meanonly
local us71113_2024 = r(mean)
quietly summarize avg_annual_pay_real if industry_code==71113 & geography=="US_national" & year==2025, meanonly
local us71113_2025 = r(mean)
display as text "71113 avg pay real: TX 2024=`tx71113_2024' 2025=`tx71113_2025' | US 2024=`us71113_2024' 2025=`us71113_2025'"

numadd, key(qcew_71113_2025_provisional_caveat) value(1) ///
    formatted("TX $`=string(round(`tx71113_2024',1),"%9.0fc")' to $`=string(round(`tx71113_2025',1),"%9.0fc")'; US $`=string(round(`us71113_2024',1),"%9.0fc")' to $`=string(round(`us71113_2025',1),"%9.0fc")'") ///
    unit("2025 dollars, average annual pay, methodological caveat") ///
    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
    note("NAICS 71113 (Musical Groups and Artists) average annual pay fell 2024-to-2025 in both Texas and the U.S. even as establishment counts kept growing. One year of data cannot confirm a reversal of the two-decade upward trend; it may be ordinary year-to-year noise in a small industry code, or the concurrent transition to the NAICS 2022 six-digit code (711130), which BLS published in parallel with the legacy five-digit code for 2025 only. This project's evidence extract captured only the legacy 71113 series, not the parallel 711130 file, so no direct cross-check between the two was possible here; if the 2025 figure looks anomalous, the code transition is a plausible but unconfirmed explanation. Treat the 2025 figure as provisional until a second year confirms the direction.")

quietly summarize avg_annual_pay_real if industry_code==7115 & geography=="Travis_County", meanonly
local travis7115_min = r(min)
local travis7115_max = r(max)
numadd, key(qcew_7115_travis_pay_volatility) value(`=round(`travis7115_max'-`travis7115_min',1)') ///
    formatted("$`=string(round(`travis7115_min',1),"%9.0fc")' to $`=string(round(`travis7115_max',1),"%9.0fc")'") ///
    unit("2025 dollars, range across 2001-2025") ///
    source("01_evidence/01_wages_oews_qcew/qcew_arts_industries_2001_2025.csv") ///
    note("NAICS 7115 (Independent Artists, Writers, and Performers) average annual pay in Travis County, private sector, real 2025 dollars, 2001-2025 range. This code covers independent contractors and loan-out corporations; a handful of high-earning individuals who incorporate can swing the county average sharply. Read this as sensitive to a small number of outliers, not as a typical independent artist's income.")

display as text "20_wages_industry.do: Task 4 (QCEW) registry complete."


* ================================================================
* SECTION 4. Build the NES analysis panel (independent-artist nonemployer
*            establishments, NAICS 7115) and answer TASK 3 (substitution)
*            and part of TASK 5 (metro comparison).
* ================================================================
import delimited "${EV_PUMS}/nes_independent_artists_long.csv", ///
    varnames(1) case(preserve) clear
keep if naics==7115
* True Census disclosure suppression is flagged "D" on estab_flag/rcptot_flag;
* confirm none of the target cells for this module are suppressed before use.
quietly count if estab_flag=="D" | rcptot_flag=="D"
display as text "NES naics=7115 rows with true suppression (D flag): `r(N)' of `=_N' (expect 0 for this module's counties)."
assert estab_flag!="D" & rcptot_flag!="D"

merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) nogenerate
generate double rcptot_real_thousands = rcptot_thousands * defl
generate double receipts_per_estab_real = rcptot_real_thousands*1000/estab
label variable rcptot_real_thousands "Total receipts, 2025 dollars (thousands)"
label variable receipts_per_estab_real "Real receipts per establishment, 2025 dollars"

* Other flag columns (rcptot_not_avail_flag: G/H/J for most rows) are Census's
* standard disclosure-avoidance/noise-infusion annotations, not suppression;
* register that once here rather than repeating it at every number below.
numadd, key(nes_noise_infusion_note) value(1) formatted("noise-infused, not suppressed") ///
    unit("methodological note") ///
    source("01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv") ///
    note("Nearly every NES row in this module carries a non-blank rcptot_not_avail_flag (G, H, or J), which is Census's standard disclosure-avoidance/noise-infusion annotation on receipts, not a suppression marker; true suppression is flagged D on estab_flag/rcptot_flag and none of that occurs in the county-industry cells this module uses. Small year-to-year swings in receipts may partly reflect injected statistical noise rather than only real change.")

tempfile nes_panel
save `nes_panel'


* ================================================================
* TASK 3: the substitution story. Payroll music jobs (OEWS 27-2042, Texas
*         and Austin MSA) against independent-artist nonemployer
*         establishments (NES 7115, Texas and Travis County), each indexed
*         to its own first available year. These count different things —
*         jobs against businesses, over different universes (musicians
*         specifically against all independent artists, writers, and
*         performers) — so this is a comparison of DIRECTION, never levels,
*         and never a combined headcount.
* ================================================================
display as text _newline "{hline 72}"
display as text "TASK 3: substitution story (payroll jobs index vs nonemployer index)"
display as text "{hline 72}"

* ---- OEWS payroll jobs, Musicians and Singers, indexed to 2005=100 ----
use `oews_panel', clear
keep if occ_code=="27-2042" & inlist(geo_level,"State","MSA")
keep year geo_level tot_emp
reshape wide tot_emp, i(year) j(geo_level) string
rename tot_empState emp_tx
rename tot_empMSA emp_austin
quietly summarize emp_tx if year==2005, meanonly
local base_tx = r(mean)
quietly summarize emp_austin if year==2005, meanonly
local base_austin = r(mean)
generate double idx_payroll_tx = emp_tx/`base_tx'*100
generate double idx_payroll_austin = emp_austin/`base_austin'*100
sort year
tempfile payroll_idx
save `payroll_idx'

quietly summarize emp_tx if year==2025, meanonly
local tx_2025 = r(mean)
local tx_pct = (`tx_2025'/`base_tx'-1)*100
numadd, key(substitution_payroll_tx_pctchg) value(`=round(`tx_pct',0.1)') ///
    formatted("`=string(round(`tx_pct',0.1),"%4.1f")'%") unit("percent change, payroll jobs, 2005-2025") ///
    source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
    note("OEWS Musicians and Singers (27-2042), Texas, payroll employment 2005 (`=string(`base_tx',"%9.0fc")') to 2025 (`=string(`tx_2025',"%9.0fc")'). Indexed 2005=100 for fig06.")

quietly count if !missing(emp_austin)
local n_austin_valid = r(N)
display as text "Austin MSA musician payroll employment: `n_austin_valid' non-missing years out of 21; series ranges from `=string(emp_austin[1],"%9.0f")' in 2005 and is highly volatile (small base, BLS min-threshold occupation at the metro level). Registered but not charted in fig06 for that reason; Texas is the OEWS geography used in the figure."
numadd, key(substitution_payroll_austin_note) value(`n_austin_valid') formatted("`n_austin_valid' of 21 years published") ///
    unit("count of non-missing years") ///
    source("01_evidence/01_wages_oews_qcew/oews_musicians_creatives_2005_2025.csv") ///
    note("Austin MSA OEWS payroll employment for Musicians and Singers is small (roughly 100-700 jobs) and volatile, with 2 years (2014, 2015) entirely unpublished. Because an index built on such a thin, volatile base could itself mislead, fig06 uses Texas (not Austin MSA) as the payroll-jobs geography; the Austin MSA series is registered here for the record instead of charted.")

* ---- NES nonemployer establishments, NAICS 7115, indexed to 2012=100 ----
use `nes_panel', clear
keep if (geo_level=="county" & county_name=="Travis") | (geo_level=="state")
keep year geo_level estab
reshape wide estab, i(year) j(geo_level) string
rename estabcounty estab_travis
rename estabstate estab_tx
quietly summarize estab_travis if year==2012, meanonly
local base_travis = r(mean)
quietly summarize estab_tx if year==2012, meanonly
local base_tx_nes = r(mean)
generate double idx_nonemployer_travis = estab_travis/`base_travis'*100
generate double idx_nonemployer_tx = estab_tx/`base_tx_nes'*100
sort year
tempfile nonemployer_idx
save `nonemployer_idx'

quietly summarize estab_travis if year==2023, meanonly
local travis_2023 = r(mean)
local travis_pct = (`travis_2023'/`base_travis'-1)*100
quietly summarize estab_tx if year==2023, meanonly
local tx_nes_2023 = r(mean)
local tx_nes_pct = (`tx_nes_2023'/`base_tx_nes'-1)*100

numadd, key(substitution_nonemployer_travis_pctchg) value(`=round(`travis_pct',0.1)') ///
    formatted("+`=string(round(`travis_pct',0.1),"%4.1f")'%") unit("percent change, nonemployer establishments, 2012-2023") ///
    source("01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv") ///
    note("NES NAICS 7115 (Independent Artists, Writers, and Performers), Travis County, establishments 2012 (`=string(`base_travis',"%9.0fc")') to 2023 (`=string(`travis_2023',"%9.0fc")'). Indexed 2012=100 for fig06. Counts businesses, not people; excludes anyone with no reported receipts.")
numadd, key(substitution_nonemployer_tx_pctchg) value(`=round(`tx_nes_pct',0.1)') ///
    formatted("+`=string(round(`tx_nes_pct',0.1),"%4.1f")'%") unit("percent change, nonemployer establishments, 2012-2023") ///
    source("01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv") ///
    note("NES NAICS 7115, Texas statewide, establishments 2012 (`=string(`base_tx_nes',"%9.0fc")') to 2023 (`=string(`tx_nes_2023',"%9.0fc")'). Indexed 2012=100, registered for context; not charted (fig06 uses Travis County as the sub-state nonemployer geography, pairing with Texas on the payroll side).")

numadd, key(substitution_honesty_note) value(1) formatted("directions only, not levels") ///
    unit("methodological note") ///
    source("multiple") ///
    note("OEWS payroll employment counts wage-and-salary JOBS in one occupation (Musicians and Singers). NES nonemployer establishments counts BUSINESSES across a broader occupational universe (all independent artists, writers, and performers, NAICS 7115). The two series are never summed or presented as one workforce total; fig06 plots each as its own index (own first available year = 100) in its own panel so only the direction of each trend is compared.")

display as text "Task 3 complete: payroll index (Texas, 2005=100) and nonemployer index (Travis, 2012=100) built."


* ================================================================
* FIGURE 6: the substitution story, two stacked panels sharing an index
*           scale. Two DIFFERENT quantities (payroll jobs; nonemployer
*           businesses) are never drawn as one line implying one total.
* ================================================================
use `payroll_idx', clear
merge 1:1 year using `nonemployer_idx', nogenerate
sort year

* A shared y-axis range across both panels, computed from the data rather
* than assumed, so "sharing an index axis" is literally true of the export.
quietly summarize idx_payroll_tx
local ymax1 = r(max)
quietly summarize idx_nonemployer_travis
local ymax2 = r(max)
local ymax_shared = 20*ceil(max(`ymax1',`ymax2')/20) + 10

twoway (line idx_payroll_tx year, lcolor("${NAVY}") lwidth(medthick)), ///
    title("Payroll jobs (OEWS 27-2042, Texas)", size(3) color("${NAVY}")) ///
    xtitle("") ytitle("Index, 2005 = 100", size(3)) ///
    yscale(range(0 `ymax_shared')) ylabel(0(50)`ymax_shared', angle(horizontal)) ///
    xlabel(2005(5)2025) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_payroll, replace)

twoway (line idx_nonemployer_travis year, lcolor("${ORANGE}") lwidth(medthick)), ///
    title("Nonemployer businesses (NES 7115, Travis County)", size(3) color("${ORANGE}")) ///
    xtitle("") ytitle("Index, 2012 = 100", size(3)) ///
    yscale(range(0 `ymax_shared')) ylabel(0(50)`ymax_shared', angle(horizontal)) ///
    xlabel(2005(5)2025) xscale(range(2005 2025)) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_nonemployer, replace)

* Title states direction for BOTH series without implying they are the same
* quantity or that one outnumbers the other (they measure different things).
* "Austin-area" (not "Texas") on the second clause, because the nonemployer
* panel is Travis County only, not a statewide series. "Grew" (not
* "multiplied") because the index rises from 100 to about 162, roughly 60
* percent, which a reader would not call a multiplication.
local fig6_title = "Music payroll jobs fell in Texas as Austin-area gig businesses grew"
local _tlen = length("`fig6_title'")
display as text "fig06 title length check: `_tlen' characters (target under ~70)."

* Subtitle states the actual size of that rise so "grew" is not read as
* understating it either; pulled from the same travis_pct local the
* registry number above was built from, so the two can never disagree.
local fig6_pctlab = strtrim(string(round(`travis_pct',1), "%3.0f"))
local fig6_sub2 = "Travis County nonemployer establishments rose about `fig6_pctlab'% from 2012 to 2023."

graph combine g_payroll g_nonemployer, rows(2) ycommon ///
    title("`fig6_title'", $TITLEOPT) ///
    subtitle("Each series indexed to its own first available year = 100." ///
        "`fig6_sub2'", $SUBOPT) ///
    graphregion(color(white)) ///
    name(g_fig06, replace)

figsave, name(fig06_payroll_vs_nonemployer)

preserve
    export delimited year idx_payroll_tx idx_nonemployer_travis emp_tx estab_travis ///
        using "${OUT}/fig06_payroll_vs_nonemployer.csv", replace
restore

display as text "fig06 complete."


* ================================================================
* SECTION 5. Population denominators (Census PEP Vintage 2025) for TASK 5.
*            NOTE: this file covers 2020-2025 only (post-2020-Census
*            vintage). The NES panel runs 2012-2023. The true overlap for a
*            population-denominated rate is 2020-2023, not the full
*            2012-2023 NES window; this module computes the per-10,000-
*            residents series honestly over that overlap and says so in the
*            figure subtitle and registry rather than inventing pre-2020
*            populations or holding population constant across the decade.
* ================================================================
use "${DATAX}/Census_PEP_TX_County_Components.dta", clear
generate county_name = subinstr(ctyname, " County", "", .)
keep county_name year population
quietly summarize year
display as text _newline "Census_PEP_TX_County_Components.dta year range: `r(min)'-`r(max)' (`=r(max)-r(min)+1' years). NES establishment panel runs 2012-2023; per-capita overlap is limited to `r(min)'-2023."
local pep_min = r(min)
local pep_max = r(max)
keep if inlist(county_name,"Travis","Harris","Dallas","Bexar")
tempfile pep_panel
save `pep_panel'

numadd, key(pep_population_coverage_gap) value(1) formatted("PEP covers `pep_min'-`pep_max' only") ///
    unit("methodological limitation") ///
    source("03_analysis/data/external/Census_PEP_TX_County_Components.dta") ///
    note("This project's Census PEP extract is Vintage 2025, which covers county population only for `pep_min'-`pep_max' (the post-2020-Census series; splicing in an older vintage's 2012-2019 estimates would introduce a vintage-methodology discontinuity at the seam rather than a clean series). The NES nonemployer panel runs 2012-2023. Establishments-per-10,000-residents in fig08 and its registry entries therefore cover `pep_min'-2023, the true overlap, not the full 2012-2023 NES window; raw establishment counts and real receipts per establishment (which need no population denominator) are reported for the full 2012-2023 span instead.")


* ================================================================
* TASK 5: metro comparison of nonemployer growth. Travis against Harris,
*         Dallas, and Bexar, NAICS 7115, 2012-2023: establishments per
*         10,000 residents (2020-2023, see the coverage-gap note above) and
*         real receipts per establishment (full 2012-2023).
* ================================================================
display as text _newline "{hline 72}"
display as text "TASK 5: metro nonemployer comparison, Travis/Harris/Dallas/Bexar"
display as text "{hline 72}"

use `nes_panel', clear
keep if geo_level=="county" & inlist(county_name,"Travis","Harris","Dallas","Bexar")
keep year county_name estab rcptot_real_thousands receipts_per_estab_real

preserve
    export delimited using "${TABDIR}/nes_metro_detail.csv", replace
restore

* ---- real receipts per establishment, full 2012-2023, all 4 counties ----
foreach c in Travis Harris Dallas Bexar {
    quietly summarize year if county_name=="`c'"
    local fy = r(min)
    local ly = r(max)
    quietly summarize receipts_per_estab_real if county_name=="`c'" & year==`fy', meanonly
    local r0 = r(mean)
    quietly summarize receipts_per_estab_real if county_name=="`c'" & year==`ly', meanonly
    local r1 = r(mean)
    local rpct = (`r1'/`r0'-1)*100
    local cl = lower("`c'")
    numadd, key(nes_receipts_per_estab_`cl'_first) value(`=round(`r0',1)') formatted("$`=string(round(`r0',1),"%9.0fc")'") ///
        unit("2025 dollars per establishment") source("01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv") ///
        note("NES NAICS 7115, `c' County, real receipts per establishment, `fy'.")
    numadd, key(nes_receipts_per_estab_`cl'_last) value(`=round(`r1',1)') formatted("$`=string(round(`r1',1),"%9.0fc")'") ///
        unit("2025 dollars per establishment") source("01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv") ///
        note("NES NAICS 7115, `c' County, real receipts per establishment, `ly'.")
    numadd, key(nes_receipts_per_estab_pctchg_`cl') value(`=round(`rpct',0.1)') ///
        formatted("`=cond(`rpct'>=0,"+","")'`=string(round(`rpct',0.1),"%4.1f")'%") unit("percent change, real receipts per establishment") ///
        source("01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv") ///
        note("NES NAICS 7115, `c' County, real receipts per establishment change `fy' to `ly': $`=string(round(`r0',1),"%9.0fc")' to $`=string(round(`r1',1),"%9.0fc")', 2025 dollars.")

    quietly summarize estab if county_name=="`c'" & year==`fy', meanonly
    local e0 = r(mean)
    quietly summarize estab if county_name=="`c'" & year==`ly', meanonly
    local e1 = r(mean)
    local epct = (`e1'/`e0'-1)*100
    numadd, key(nes_estab_pctchg_`cl') value(`=round(`epct',0.1)') ///
        formatted("+`=string(round(`epct',0.1),"%4.1f")'%") unit("percent change, nonemployer establishments, 2012-2023") ///
        source("01_evidence/02_pums_nes_microdata/nes_independent_artists_long.csv") ///
        note("NES NAICS 7115, `c' County, establishments `fy' (`=string(`e0',"%9.0fc")') to `ly' (`=string(`e1',"%9.0fc")').")
}

* ---- establishments per 10,000 residents, 2020-2023 overlap only ----
merge m:1 county_name year using `pep_panel', keep(match master) generate(mrg_pep)
quietly count if mrg_pep==1
display as text "NES county-years without a PEP population match (expected outside 2020-2023): `r(N)'"
generate double estab_per10k = estab*10000/population if mrg_pep==3

foreach c in Travis Harris Dallas Bexar {
    local cl = lower("`c'")
    quietly summarize estab_per10k if county_name=="`c'" & year==2020, meanonly
    local p0 = r(mean)
    quietly summarize estab_per10k if county_name=="`c'" & year==2023, meanonly
    local p1 = r(mean)
    if !missing(`p0') & !missing(`p1') {
        numadd, key(nes_estab_per10k_`cl'_2020) value(`=round(`p0',0.01)') formatted("`=string(round(`p0',0.01),"%4.2f")'") ///
            unit("nonemployer establishments per 10,000 residents") source("multiple") ///
            note("NES NAICS 7115 establishments in `c' County per 10,000 residents, 2020. Population: Census PEP Vintage 2025.")
        numadd, key(nes_estab_per10k_`cl'_2023) value(`=round(`p1',0.01)') formatted("`=string(round(`p1',0.01),"%4.2f")'") ///
            unit("nonemployer establishments per 10,000 residents") source("multiple") ///
            note("NES NAICS 7115 establishments in `c' County per 10,000 residents, 2023. Population: Census PEP Vintage 2025.")
    }
}

* Rank Travis among the 4 for 2023 (needed to write a title that is literally
* true; verify rather than assume which county actually ranks highest).
preserve
    keep if year==2023 & !missing(estab_per10k)
    sort estab_per10k
    display as text _newline "2023 establishments per 10,000 residents, ascending:"
    list county_name estab_per10k, clean
    local nrows = _N
    local top_county = county_name[`nrows']
restore
display as text "Highest per-10,000 rate in 2023: `top_county'"

tempfile fig08_data
save `fig08_data'


* ================================================================
* FIGURE 8: independent-artist nonemployer establishments per 10,000
*           residents, Travis/Harris/Dallas/Bexar. Population data available
*           only 2020-2023 in this project's extract (see the registered
*           coverage-gap note); the subtitle states the true window.
*           Travis's rate (57-65 per 10,000) sits far above the other three
*           (19-29 per 10,000): one shared axis leaves roughly half the plot
*           height empty in the middle and flattens Harris's 2020 point
*           against the floor. Two panels, each scaled to its own cluster,
*           read like a broken axis instead: every point clears its own
*           floor and the empty middle band disappears.
* ================================================================
use `fig08_data', clear
keep if !missing(estab_per10k)
keep year county_name estab_per10k
reshape wide estab_per10k, i(year) j(county_name) string
rename estab_per10kTravis pc_travis
rename estab_per10kHarris pc_harris
rename estab_per10kDallas pc_dallas
rename estab_per10kBexar pc_bexar
sort year

foreach s in pc_travis pc_harris pc_dallas pc_bexar {
    quietly summarize year if !missing(`s')
    local ly_`s' = r(max)
}
generate lbl_harris = "Harris" if year==`ly_pc_harris'
generate lbl_dallas = "Dallas" if year==`ly_pc_dallas'
generate lbl_bexar  = "Bexar"  if year==`ly_pc_bexar'

* Verify the title against the actual last-year ranking before writing it.
local r_travis = pc_travis[_N]
local r_harris = pc_harris[_N]
local r_dallas = pc_dallas[_N]
local r_bexar  = pc_bexar[_N]
display as text "2023 per-10,000 rates: Travis `r_travis' Harris `r_harris' Dallas `r_dallas' Bexar `r_bexar'"
local travis_is_max = (`r_travis' >= `r_harris' & `r_travis' >= `r_dallas' & `r_travis' >= `r_bexar')

* Bounded to the 4 counties actually plotted here: only 4 of Texas's 254
* counties appear on this chart, so the title never claims a statewide
* "most," only what these four show.
if `travis_is_max' {
    local fig8_title = "Among 4 Texas counties, Travis leads in independent-artist businesses"
}
else {
    local fig8_title = "Among 4 Texas counties, Travis trails in independent-artist businesses"
}
local _tlen = length("`fig8_title'")
display as text "fig08 title length check: `_tlen' characters."

* Panel y-ranges come from the data actually plotted (rounded out to the
* nearest multiple of 4), not a shared round number, so Harris's 2020 point
* -- the tightest case, about 19.5 -- clears its panel's floor with room to
* spare instead of sitting flat against it.
quietly summarize pc_travis
local hi_min = r(min)
local hi_max = r(max)
local hi_floor = 4*floor((`hi_min'-3)/4)
local hi_ceil  = 4*ceil((`hi_max'+3)/4)

quietly summarize pc_harris
local lo_min = r(min)
local lo_max = r(max)
foreach v in pc_dallas pc_bexar {
    quietly summarize `v'
    if r(min) < `lo_min' local lo_min = r(min)
    if r(max) > `lo_max' local lo_max = r(max)
}
local lo_floor = 4*floor((`lo_min'-3)/4)
local lo_ceil  = 4*ceil((`lo_max'+3)/4)
display as text "fig08 panel ranges: Travis `hi_floor' to `hi_ceil'; other 3 counties `lo_floor' to `lo_ceil'"

twoway (line pc_travis year, lcolor("${ORANGE}") lpattern(solid) lwidth(medthick)) ///
    , ///
    title("Travis County", size(3) color("${ORANGE}")) ///
    xtitle("") ytitle("Per 10,000 residents", size(3)) ///
    xlabel(2020(1)2023) xscale(range(2020 2023.6)) ///
    ylabel(`hi_floor'(4)`hi_ceil', angle(horizontal) labsize(2.6)) ///
    yscale(range(`hi_floor' `hi_ceil')) ///
    legend(off) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_fig08_hi, replace)

twoway (line pc_harris year, lcolor("${NAVY}") lpattern(solid)) ///
    (line pc_dallas year, lcolor("${BLUE}") lpattern(dash)) ///
    (line pc_bexar year, lcolor("${MUTED}") lpattern(shortdash)) ///
    (scatter pc_harris year if year==`ly_pc_harris', mlabel(lbl_harris) mlabcolor("${NAVY}") mlabposition(3) mlabsize(3) msymbol(none)) ///
    (scatter pc_dallas year if year==`ly_pc_dallas', mlabel(lbl_dallas) mlabcolor("${BLUE}") mlabposition(3) mlabsize(3) msymbol(none)) ///
    (scatter pc_bexar year if year==`ly_pc_bexar', mlabel(lbl_bexar) mlabcolor("${MUTED}") mlabposition(3) mlabsize(3) msymbol(none)) ///
    , ///
    title("Harris, Dallas, and Bexar Counties", size(3) color("${TEXTC}")) ///
    xtitle("") ytitle("Per 10,000 residents", size(3)) ///
    xlabel(2020(1)2023) xscale(range(2020 2023.6)) ///
    ylabel(`lo_floor'(4)`lo_ceil', angle(horizontal) labsize(2.6)) ///
    yscale(range(`lo_floor' `lo_ceil')) ///
    legend(off) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_fig08_lo, replace)

graph combine g_fig08_hi g_fig08_lo, rows(2) ///
    title("`fig8_title'", $TITLEOPT) ///
    subtitle("Nonemployer establishments (NAICS 7115) per 10,000 residents, 2020-2023." ///
        "Travis’s rate is far above the other three;" ///
        "each panel keeps its own y-axis, and neither starts at zero.", $SUBOPT) ///
    graphregion(color(white)) ///
    name(g_fig08, replace)

figsave, name(fig08_metro_nonemployer)

preserve
    export delimited year pc_travis pc_harris pc_dallas pc_bexar ///
        using "${OUT}/fig08_metro_nonemployer.csv", replace
restore

display as text "fig08 complete."

numadd, key(fig08_year_range_caveat) value(1) formatted("2020-2023, not 2012-2023") ///
    unit("methodological limitation") ///
    source("03_analysis/data/external/Census_PEP_TX_County_Components.dta") ///
    note("fig08 plots 2020-2023 (the years with a real Census PEP Vintage 2025 population match), not the full 2012-2023 NES window, because this project's population extract does not reach back to 2012. Raw establishment growth for the full 2012-2023 window is registered separately (nes_estab_pctchg_* keys) and is not population-denominated.")


* ================================================================
* Done.
* ================================================================
display as text _newline "{hline 72}"
display as text "20_wages_industry.do complete"
display as text "{hline 72}"
