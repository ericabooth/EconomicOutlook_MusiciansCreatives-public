*! 50_state_national.do - Texas music policy against peer states, Texas film
*!   vs. music appropriations, the BEA arts-economy satellite account, SVOG
*!   federal pandemic relief, and (optional) other cities' self-reported
*!   music-census income against Austin's data gap.
*! Inputs  : 01_evidence/06_state_policy_benchmark/_findings.md (hand-entered
*!             state policy dollar figures; no machine-readable cross-state
*!             file exists for these -- each program is a different statute)
*!           01_evidence/06_state_policy_benchmark/trackers/Census_NST-EST2025-ALLDATA.csv
*!           01_evidence/03_creative_economy_bea/tidy/acpsa_state_totals_long_2001_2023.csv
*!           01_evidence/03_creative_economy_bea/tidy/acpsa_state_industry_detail_2001_2023.csv
*!           01_evidence/03_creative_economy_bea/tidy/nasaa_fy2026_table6_per_capita_spending.csv
*!           01_evidence/07_svog_federal_relief/svog_awards_TEXAS.csv
*!           01_evidence/07_svog_federal_relief/svog_awards_AUSTIN_AREA.csv
*!           03_analysis/data/external/SVOG_awards_full_national.dta (staged
*!             this module -- see note before SECTION 4 -- from the same SBA
*!             "awards as of 07-05-2022" vintage as the two evidence CSVs
*!             above; needed only for Nashville, TN, which sits outside the
*!             two Texas-scoped evidence extracts)
*!           01_evidence/05_music_census_pay_surveys/national_and_benchmark_surveys.md
*!             (hand-entered city-census income figures, verified against
*!             that file before use; no tidy CSV exists for this table either)
*! Outputs : 04_figures/fig15_film_vs_music.png (+ .csv)
*!           04_figures/fig16_state_percapita.png (+ .csv)
*!           04_figures/fig17_bea_arts.png (+ 2 csvs, one per panel)
*!           04_figures/fig18_svog_metro.png (+ .csv)
*!           04_figures/fig21_city_census_income.png (+ .csv)
*!           03_analysis/out/numbers/numbers_state.csv

clear all
do "_setup.do"
global CURMODULE "state"
numinit

requirefile "${EV_STATE}/_findings.md"
requirefile "${EV_STATE}/trackers/Census_NST-EST2025-ALLDATA.csv"
requirefile "${EV_BEA}/tidy/acpsa_state_totals_long_2001_2023.csv"
requirefile "${EV_BEA}/tidy/acpsa_state_industry_detail_2001_2023.csv"
requirefile "${EV_BEA}/tidy/nasaa_fy2026_table6_per_capita_spending.csv"
requirefile "${EV_SVOG}/svog_awards_TEXAS.csv"
requirefile "${EV_SVOG}/svog_awards_AUSTIN_AREA.csv"
requirefile "${EV_SURVEY}/national_and_benchmark_surveys.md"


* ================================================================
* SECTION 1. TASK 2 / FIGURE 15: Texas film vs. music per biennium, plus the
*            film-workforce line. All three dollar figures were dedicated by
*            the SAME 2025 legislative session for the SAME 2026-27 biennium
*            (SB 22 for film; Rider 39/40 of the 2026-27 GAA for music and
*            for the workforce pilot), so this is a same-nominal-year
*            comparison. Per CONVENTIONS.md section 3, a ratio of two
*            same-year nominal quantities needs no CPI deflation; that is
*            registered explicitly below rather than left for a reader to
*            wonder whether it was forgotten.
* ================================================================
clear
set obs 3
generate byte ord = _n
generate str40 lever_label = ""
generate double amount_usd = .
replace lever_label = "Music (TMIR)"                 in 1
replace amount_usd  = 20200000                        in 1
replace lever_label = "Film (moving image)"           in 2
replace amount_usd  = 300000000                       in 2
replace lever_label = "Film workforce (one-time)"     in 3
replace amount_usd  = 30000000                        in 3
generate double amount_millions = amount_usd/1000000

local tmir_biennium      = amount_usd[1]
local film_biennium      = amount_usd[2]
local workforce_onetime  = amount_usd[3]
local film_music_ratio   = `film_biennium' / `tmir_biennium'
local film_music_ratio_r = round(`film_music_ratio',0.1)
local film_music_ratio_s = string(`film_music_ratio_r',"%4.1f")

display as text _newline "{hline 72}"
display as text "TASK 2 / FIGURE 15: Texas film vs. music per biennium"
display as text "{hline 72}"
display as text "Music (TMIR) $`=string(`tmir_biennium',"%12.0fc")'/biennium; Film $`=string(`film_biennium',"%12.0fc")'/biennium; ratio `film_music_ratio_s' to 1"

numadd, key(tx_music_tmir_biennium) value(`tmir_biennium') formatted("\$20.2 million") ///
    unit("2026-27 biennium, nominal") ///
    source("01_evidence/06_state_policy_benchmark/_findings.md") ///
    note("Texas Music Incubator Rebate: \$10,100,000/year statutory dedication (Tax Code sec 183.023(c) \$10,000,000 + sec 151.801(f) \$100,000), SB 609, 87th Legislature (2021), funded starting the 2024-25 biennium. \$20,200,000 for the 2026-27 biennium (Rider 39/40 of the 2024-25 and 2026-27 GAAs). Ongoing statutory dedication, not a one-time appropriation.")

numadd, key(tx_film_incentive_biennium) value(`film_biennium') formatted("\$300.0 million") ///
    unit("2026-27 biennium, nominal") ///
    source("01_evidence/06_state_policy_benchmark/_findings.md") ///
    note("Texas moving image industry incentive fund, SB 22, 89th Legislature (2025), Tax Code sec 151.801(g): comptroller deposits \$300,000,000 per biennium, sunsets September 1, 2035. Same Gov’t Code ch. 485 office as the music rebate (Music, Film, Television, and Multimedia Office); ratio to TMIR is 14.9 to 1.")

numadd, key(tx_film_workforce_pilot_onetime) value(`workforce_onetime') formatted("\$30.0 million, one-time") ///
    unit("FY2026 only, nominal -- NOT a per-biennium recurring dedication like the other two lines") ///
    source("01_evidence/06_state_policy_benchmark/_findings.md") ///
    note("Higher Education Film Workforce Pilot Program, Rider 45 of the 2026-27 GAA, verbatim: \$30,000,000 General Revenue in fiscal year 2026 to eligible general academic teaching institutions, film/media workforce only, no music counterpart, funds may not be spent for any other purpose. Funded once for FY2026, not a recurring per-biennium amount like TMIR or the moving-image fund -- shown for context, never summed with the other two bars as if all three were on the same time basis.")

numadd, key(tx_film_music_ratio) value(`film_music_ratio_r') formatted("`film_music_ratio_s' to 1") ///
    unit("ratio, both same 2026-27 biennium, nominal") ///
    source("01_evidence/06_state_policy_benchmark/_findings.md") ///
    note("Texas moving-image incentive (\$300.0M/biennium) against the music rebate (\$20.2M/biennium), both dedicated by the 89th/88th Legislatures for the 2026-27 biennium and administered by the same office (Gov’t Code ch. 485). Same nominal year on both sides of this ratio, so no CPI deflation applies -- recorded here so the omission reads as deliberate, not forgotten (CONVENTIONS.md section 3).")

local fig15_title = "Texas dedicates far more to film incentives than to live music"
local _tlen = length("`fig15_title'")
display as text "fig15 title length check: `_tlen' characters (target under ~70)."

generate str20 vlabel = ""
replace vlabel = "$20.2M"  in 1
replace vlabel = "$300.0M" in 2
replace vlabel = "$30.0M"  in 3
generate double vlabel_y = amount_millions + 12

twoway ///
    (bar amount_millions ord if ord==1, barwidth(0.6) color("${ORANGE}")) ///
    (bar amount_millions ord if ord==2, barwidth(0.6) color("${NAVY}")) ///
    (bar amount_millions ord if ord==3, barwidth(0.6) color("${MUTED}")) ///
    (scatter vlabel_y ord, mlabel(vlabel) mlabcolor("${TEXTC}") mlabsize(2.6) mlabpos(12) msymbol(none)) ///
    , ///
    title("`fig15_title'", $TITLEOPT) ///
    subtitle("Dollars dedicated for the 2026-27 biennium, nominal (same biennium both sides, no deflation needed)." ///
             "The film-workforce line is a one-time FY2026 grant, not an ongoing per-biennium dedication.", $SUBOPT) ///
    xtitle("") ytitle("$ millions, 2026-27 biennium", $YTOPT) ///
    xlabel(1 "Music (TMIR)" 2 "Film (moving image)" 3 "Film workforce (one-time)", noticks labsize(2.6)) ///
    xscale(range(0.5 3.5)) ///
    ylabel(0(50)300, angle(horizontal)) ///
    yscale(range(0 320)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_fig15, replace)

figsave, name(fig15_film_vs_music)

preserve
    export delimited ord lever_label amount_usd amount_millions using "${OUT}/fig15_film_vs_music.csv", replace
restore

display as text "fig15 complete."


* ================================================================
* SECTION 2. TASK 1 / FIGURE 16: state music-specific support per capita,
*            distinguishing dollars AUTHORIZED (statutory cap or ongoing
*            dedication) from dollars ACTUALLY DISBURSED, plus NASAA general
*            state-arts-agency per-capita spending as a separate, clearly
*            labeled baseline. No machine-readable cross-state file exists
*            for the music-specific programs -- each is a different statute
*            with a different reporting regime -- so every dollar figure
*            below is hand-entered from 01_evidence/06_state_policy_
*            benchmark/_findings.md, with the source statute/report and the
*            nominal-year assumption stated in that row's note. Every dollar
*            is then run through the shared CPI-U deflator to 2025 real
*            dollars, same as every other figure in this report.
* ================================================================
clear
set obs 5
generate byte staten = _n
generate str20 state_name = ""
generate double auth_nominal = .
generate int    auth_year = .
generate double disb_nominal = .
generate int    disb_year = .

* ---- 1. Texas: Texas Music Incubator Rebate (TMIR) ----
replace state_name   = "Texas"     in 1
replace auth_nominal  = 10100000   in 1
replace auth_year     = 2025       in 1
replace disb_nominal  = 10100000   in 1
replace disb_year     = 2025       in 1

* ---- 2. Georgia: Musical Tax Credit (O.C.G.A. sec 48-7-40.33), ran 2018-2022 ----
replace state_name   = "Georgia"   in 2
replace auth_nominal  = 15000000   in 2
replace auth_year     = 2022       in 2
replace disb_nominal  = 0          in 2
replace disb_year     = 2022       in 2

* ---- 3. Louisiana: 2 music credits combined ----
replace state_name   = "Louisiana" in 3
replace auth_nominal  = 12160000   in 3
replace auth_year     = 2025       in 3
replace disb_nominal  = 2203906    in 3
replace disb_year     = 2025       in 3

* ---- 4. New York: NYC Musical & Theatrical Production Credit (Tax Law sec 24-c) ----
replace state_name   = "New York"  in 4
replace auth_nominal  = 150000000  in 4
replace auth_year     = 2025       in 4
replace disb_nominal  = 88000000   in 4
replace disb_year     = 2024       in 4

* ---- 5. Tennessee: budget line 330.17, film+TV+music SCORING combined ----
replace state_name   = "Tennessee" in 5
replace auth_nominal  = 10686500   in 5
replace auth_year     = 2025       in 5
replace disb_nominal  = 7620200    in 5
replace disb_year     = 2024       in 5

* Vintage 2025 populations (Census Bureau, July 1, 2025), held fixed across
* BOTH the authorized and disbursed bars for every state -- including
* Tennessee, whose disbursed figure is FY2024-25 -- so every bar in this
* figure shares one population vintage rather than mixing vintages within
* one chart.
generate double population = .
replace population = 31709821 in 1
replace population = 11302748 in 2
replace population = 4618189  in 3
replace population = 20002427 in 4
replace population = 7315076  in 5

display as text _newline "{hline 72}"
display as text "TASK 1 / FIGURE 16: state per-capita music support, authorized vs. disbursed"
display as text "{hline 72}"
list state_name auth_nominal auth_year disb_nominal disb_year population, clean

* ---- Real 2025 dollars: two merges, because authorized and disbursed can
*      carry different nominal years for the same state (e.g. Tennessee). ----
generate year = auth_year
merge m:1 year using "${OUT}/cpi_annual.dta", keepusing(defl) keep(master match) nogenerate
rename defl defl_auth
drop year

generate year = disb_year
merge m:1 year using "${OUT}/cpi_annual.dta", keepusing(defl) keep(master match) nogenerate
rename defl defl_disb
drop year

assert !missing(defl_auth) & !missing(defl_disb)

generate double auth_real = auth_nominal * defl_auth
generate double disb_real = disb_nominal * defl_disb
generate double auth_percapita = auth_real / population
generate double disb_percapita = disb_real / population
label variable auth_percapita "Authorized (statutory cap/dedication), 2025 real dollars per capita"
label variable disb_percapita "Disbursed (actual), 2025 real dollars per capita"

list state_name auth_percapita disb_percapita, clean

* ---- NASAA general state-arts-agency baseline, FY2026, per capita -- a
*      real machine-readable file, not hand-entered like the rows above. ----
preserve
    import delimited "${EV_BEA}/tidy/nasaa_fy2026_table6_per_capita_spending.csv", varnames(1) case(preserve) clear
    keep if inlist(state,"Texas","Georgia","Louisiana","New York","Tennessee")
    keep state incl_lineitems_percapita
    rename state state_name
    rename incl_lineitems_percapita nasaa_percapita
    tempfile nasaa5
    save `nasaa5'
restore
merge 1:1 state_name using `nasaa5', assert(match) nogenerate

quietly count
assert r(N)==5

* Rank check for the title: verify Texas's position on AUTHORIZED per capita
* directly rather than assume it, since the two "cap is not spending" states
* (Georgia, and now Louisiana/Tennessee too) turn out to rank close together.
gsort -auth_percapita
list state_name auth_percapita disb_percapita nasaa_percapita, clean
quietly summarize disb_percapita if state_name=="Georgia", meanonly
local ga_disb = r(mean)
assert `ga_disb'==0

quietly summarize disb_percapita if state_name=="Texas", meanonly
local tx_disb_pc = r(mean)
quietly summarize auth_percapita if state_name=="Texas", meanonly
local tx_auth_pc = r(mean)
local tx_fully_drawn = (abs(`tx_disb_pc' - `tx_auth_pc') < 0.001)
display as text "Texas authorized == disbursed (fully drawn down)? `tx_fully_drawn'"

* Build an explicit numeric display order, descending by authorized per capita,
* and carry it into BOTH fig16 panels so the two can be compared row by row.
* Sorting by the state-name string does not work: over(state_name,
* sort(auth_percapita) descending) looks right but silently falls back to
* ALPHABETICAL order for a string over() variable (confirmed by inspecting the
* rendered PNG: panel A came out Georgia, Louisiana, New York, Tennessee,
* Texas), and panel B, built the same way, landed on yet a THIRD order. Both
* panels now key their row positions off ord5 directly.
gsort -auth_percapita
generate byte ord5 = _n
label define ord5lbl 1 "placeholder", replace
quietly forvalues i = 1/5 {
    local thislbl = state_name[`i']
    label define ord5lbl `i' "`thislbl'", modify
}
label values ord5 ord5lbl

tempfile percapita_final
save `percapita_final'

* ---- Registry: one row per state per stage, plus the NASAA baseline. ----
foreach s in Texas Georgia Louisiana "New York" Tennessee {
    local sl = lower(subinstr("`s'"," ","",.))
    quietly summarize auth_nominal if state_name=="`s'", meanonly
    local an = r(mean)
    quietly summarize disb_nominal if state_name=="`s'", meanonly
    local dn = r(mean)
    quietly summarize auth_percapita if state_name=="`s'", meanonly
    local apc = r(mean)
    quietly summarize disb_percapita if state_name=="`s'", meanonly
    local dpc = r(mean)
    quietly summarize nasaa_percapita if state_name=="`s'", meanonly
    local npc = r(mean)
    quietly summarize population if state_name=="`s'", meanonly
    local pop = r(mean)

    numadd, key(percapita_pop_2025_`sl') value(`pop') formatted("`=string(`pop',"%12.0fc")'") ///
        unit("residents, Census Vintage 2025, July 1 2025") ///
        source("01_evidence/06_state_policy_benchmark/trackers/Census_NST-EST2025-ALLDATA.csv") ///
        note("`s' resident population, Census Bureau Vintage 2025 state estimate, July 1, 2025 (SUMLEV 040). Used as the single population denominator for both the authorized and disbursed bars for `s' in fig16.")

    numadd, key(music_authorized_percapita_`sl') value(`=round(`apc',0.01)') formatted("\$`=string(round(`apc',0.01),"%4.2f")'") ///
        unit("2025 real dollars per capita, primary music-specific program") ///
        source("01_evidence/06_state_policy_benchmark/_findings.md") ///
        note("`s': statutory cap or ongoing dedication for its primary music-specific incentive, deflated to 2025 dollars and divided by Vintage-2025 population. See fig16 caption/registry for the specific program and nominal-year assumption used for `s'.")

    numadd, key(music_disbursed_percapita_`sl') value(`=round(`dpc',0.01)') formatted("\$`=string(round(`dpc',0.01),"%4.2f")'") ///
        unit("2025 real dollars per capita, primary music-specific program") ///
        source("01_evidence/06_state_policy_benchmark/_findings.md") ///
        note("`s': actual disbursed/claimed/awarded amount for its primary music-specific incentive, deflated to 2025 dollars and divided by Vintage-2025 population.")

    numadd, key(nasaa_baseline_percapita_`sl') value(`npc') formatted("\$`=string(`npc',"%4.2f")'") ///
        unit("FY2026 nominal dollars per capita, state arts agency (general arts, NOT music-specific)") ///
        source("01_evidence/03_creative_economy_bea/tidy/nasaa_fy2026_table6_per_capita_spending.csv") ///
        note("`s' state arts agency legislative appropriation including line items, FY2026, per capita (NASAA Table 6). This is a GENERAL arts baseline, not a music-specific figure -- it excludes Texas’s TMIR, Louisiana’s and Tennessee’s music-adjacent economic-development incentives entirely, because those sit outside the state arts agency in all three states.")
}

numadd, key(ga_credit_zero_disbursed_note) value(1) formatted("statutory cap is not a measure of support") ///
    unit("methodological/analytical point") ///
    source("01_evidence/06_state_policy_benchmark/peer_GA/GA_DOAA_Musical_Tax_Credit_eval.txt") ///
    note("Georgia Musical Tax Credit (O.C.G.A. sec 48-7-40.33): \$15,000,000/year statutory cap, in effect 2018-2022 (expired Jan 1 2023). Georgia Department of Audits and Accounts evaluation states, verbatim, that throughout the credit’s active period no tax credits were awarded; six applications were received, none approved (all lacked GDEcD pre-certification). Disbursed = \$0 in every year of the program’s life. Verified directly against the source PDF text in this session, not taken on the evidence memo’s word alone.")

numadd, key(fig16_nominal_year_methodology) value(1) formatted("see note") unit("methodological note") ///
    source("01_evidence/06_state_policy_benchmark/_findings.md") ///
    note("fig16 nominal-year assignments, all deflated to 2025 real dollars via this project’s shared CPI-U lookup: Texas TMIR authorized+disbursed, nominal 2025 (FY2026 award year treated as coincident with the 2025 base year). Georgia cap, nominal 2022 (last year the flat \$15M/yr cap was in effect before the credit expired); disbursed is a real \$0 in any year. Louisiana’s 2 combined credits (Sound Recording Investor + Musical & Theatrical Production), both authorized and disbursed, nominal 2025 (FYE 6/2025, current law before both credits closed to new applications 6/30/2025). New York NYC Musical & Theatrical (sec 24-c): this credit uses an escalating multi-year LIFETIME aggregate cap (\$100M to \$550M since Aug 2022), not a flat annual cap like the other 4 states, so the authorized figure here is this module’s own proxy -- the most recent one-year increase to that cap (\$400M to \$550M, enacted in the FY2027 budget, May 2026, versus the FY2026 budget, May 2025 -- one year apart), nominal 2025. New York disbursed is the evidence memo’s own annualized actual (\$308M awarded Aug 2022-Feb 2026, 3.5 years, ~\$88M/yr), nominal year approximated as 2024, the rough midpoint of that window. Tennessee budget line 330.17 (film+TV+music-scoring combined, no music-only breakout exists): authorized = FY2025-26 estimated appropriation, nominal 2025; disbursed = FY2024-25 actual, nominal 2024. NASAA baseline figures are FY2026 nominal, treated as approximately 2025-real given proximity to the base year, consistent with the Texas TMIR treatment. New York’s authorized figure and the Tennessee bars (not music-specific) should be read with more caution than Texas, Georgia, and Louisiana’s cleaner flat-annual-cap figures.")

* ---- FIGURE 16, panel A: authorized vs. disbursed, per capita. ----
use `percapita_final', clear
sort ord5
isid ord5

local fig16a_title = "What states authorize for music support differs from what they spend"
local _tlen = length("`fig16a_title'")
display as text "fig16 panel A title length check: `_tlen' characters (target under ~70)."

* WHY THIS PANEL IS A twoway AND NOT A graph hbar. The hbar version put 5
* states x 2 series into 10 evenly spaced slots and labeled them with
* blabel(bar), which offers no per-observation control. That produced two
* defects a reader could not recover from:
*   (1) Texas's authorized and disbursed figures are identical (the rebate is
*       fully drawn down), so two "0.32" labels printed on top of each other
*       and read as struck-through text;
*   (2) Georgia's disbursed bar has zero length, so its "0.00" label sat in the
*       gap between rows and looked as though it belonged to Texas.
* Building the panel at a taller ysize does NOT fix either one: graph combine
* gives every cell the same height and ignores a component's declared ysize
* (verified by rendering), and Stata sizes text against min(xsize,ysize), so a
* taller combined canvas enlarges the labels by the same factor it enlarges the
* panel and the ratio of row height to text height does not move. Explicit y
* positions -- the pattern fig12 already uses -- fix both: each state's pair of
* bars sits closer to itself than to its neighbours, and every label is placed
* individually.
generate double ypos   = 6 - ord5          // New York at the top, Texas at the bottom
generate double y_auth = ypos + 0.16
generate double y_disb = ypos - 0.16

generate str24 lab_auth = string(auth_percapita, "%4.2f")
generate str24 lab_disb = string(disb_percapita, "%4.2f")
* Where the two figures round to the same printed value the bars are the same
* length, so one label serves both and saying "on both" keeps the fact that
* they are equal, which is itself the Texas finding.
generate byte same_rounded = (lab_auth == lab_disb)
replace lab_disb = lab_disb + " on both" if same_rounded
replace lab_auth = "" if same_rounded
quietly count if same_rounded
display as text "  fig16 panel A: states whose authorized and disbursed round alike (one label printed): " r(N)

* Row labels come from the data, so the tick position and the bar position are
* the same coordinate by construction and cannot drift apart.
local ylab16 ""
forvalues i = 1/5 {
    local nm = state_name[`i']
    local yp = 6 - `i'
    local ylab16 `"`ylab16' `yp' "`nm'""'
}

quietly summarize auth_percapita
local xmax16 = 1.15 * r(max)

twoway ///
    (bar auth_percapita y_auth, horizontal barwidth(0.28) color("${MUTED}")) ///
    (bar disb_percapita y_disb, horizontal barwidth(0.28) color("${ORANGE}")) ///
    (scatter y_auth auth_percapita, msymbol(none) mlabel(lab_auth) ///
        mlabposition(3) mlabgap(1) mlabcolor("${TEXTC}") mlabsize(2.5)) ///
    (scatter y_disb disb_percapita, msymbol(none) mlabel(lab_disb) ///
        mlabposition(3) mlabgap(1) mlabcolor("${TEXTC}") mlabsize(2.5)) ///
    , ylabel(`ylab16', angle(0) labsize(2.6) noticks) ///
      yscale(range(0.45 5.55)) ytitle("") ///
      xtitle("2025 real dollars per capita", size(2.8)) ///
      xlabel(0(2)8, labsize(2.6)) xscale(range(0 `xmax16')) ///
      title("Authorized versus disbursed, primary music-specific incentive", size(3.2) color("${NAVY}")) ///
      legend(order(1 "Authorized (cap or dedication)" 2 "Disbursed (actual)") ///
             cols(1) position(4) ring(0) size(2.4) symxsize(5) ///
             region(lstyle(none) fcolor(white))) ///
      graphregion(color(white)) ///
      name(g_fig16a, replace)

* ---- FIGURE 16, panel B: NASAA general-arts baseline, same states, same
*      per-capita units, same state order -- a separate, clearly labeled
*      comparison, not mixed into panel A's music-specific bars. Built the same
*      twoway way as panel A so the two panels' rows line up exactly. ----
generate str24 lab_nasaa = string(nasaa_percapita, "%4.2f")
quietly summarize nasaa_percapita
local xmax16b = 1.15 * r(max)

twoway ///
    (bar nasaa_percapita ypos, horizontal barwidth(0.5) color("${NAVY}")) ///
    (scatter ypos nasaa_percapita, msymbol(none) mlabel(lab_nasaa) ///
        mlabposition(3) mlabgap(1) mlabcolor("${TEXTC}") mlabsize(2.5)) ///
    , ylabel(`ylab16', angle(0) labsize(2.6) noticks) ///
      yscale(range(0.45 5.55)) ytitle("") ///
      xtitle("FY2026 dollars per capita", size(2.8)) ///
      xlabel(0(1)4, labsize(2.6)) xscale(range(0 `xmax16b')) ///
      title("Separate baseline: state arts agency (general arts, not music)", size(3.2) color("${NAVY}")) ///
      legend(off) ///
      graphregion(color(white)) ///
      name(g_fig16b, replace)

graph combine g_fig16a g_fig16b, rows(2) ///
    title("`fig16a_title'", $TITLEOPT) ///
    subtitle("Five states, primary music-specific incentive per state; NASAA general-arts baseline is a separate measure." ///
             "Georgia’s credit paid \$0 across its whole 2018-2022 life; its cap was never spending.", $SUBOPT) ///
    graphregion(color(white)) ///
    name(g_fig16, replace)

figsave, name(fig16_state_percapita)

preserve
    export delimited state_name auth_nominal auth_year disb_nominal disb_year population ///
        auth_percapita disb_percapita nasaa_percapita using "${OUT}/fig16_state_percapita.csv", replace
restore

display as text "fig16 complete."


* ================================================================
* SECTION 3. TASK 3 / FIGURE 17: BEA Arts and Cultural Production Satellite
*            Account (ACPSA). Panel A checks, directly against the tidy CSV,
*            whether Texas really is the LOWEST of the 8 benchmark states on
*            arts value added as a share of state GDP -- the evidence memo's
*            headline sentence says so, but its own supporting table lists
*            Louisiana lower. Panel B shows the Texas performing-arts-
*            companies-vs-independent-artists crossover.
* ================================================================
import delimited "${EV_BEA}/tidy/acpsa_state_totals_long_2001_2023.csv", varnames(1) case(preserve) clear
keep if year==2023
generate double share_pct = acpsa_va_share_of_state_gdp*100

quietly summarize share_pct if state=="United States", meanonly
local us_avg_share = r(mean)
local us_avg_s = string(round(`us_avg_share',0.1),"%3.1f")

* The 8 benchmark states are every row here EXCEPT the "United States"
* national-average row -- verify the count directly rather than assume it.
drop if state=="United States"
quietly count
local n_benchmark = r(N)
display as text _newline "{hline 72}"
display as text "TASK 3 / FIGURE 17 panel A: arts value-added share of state GDP, 2023"
display as text "{hline 72}"
display as text "Benchmark states in this file (expect 8): `n_benchmark'"
assert `n_benchmark'==8

quietly summarize share_pct, meanonly
local min_share = r(min)
local max_share = r(max)

* acpsa_va_share_of_state_gdp arrives as float, so share_pct carries float
* rounding noise (3.2000002, 9.7999997, ...); an exact `==` match against
* r(min)/r(max) silently finds nothing and leaves minstate/maxstate blank.
* rank8 (an integer built from gsort, below) is exact, so derive the
* lowest/highest STATE NAMES from rank8==1 and rank8==n_benchmark instead of
* from a floating-point equality test.
gsort share_pct
generate byte rank8 = _n
levelsof state if rank8==1, local(minstate) clean
levelsof state if rank8==`n_benchmark', local(maxstate) clean
quietly summarize rank8 if state=="Texas", meanonly
local tx_rank8 = r(mean)
quietly summarize share_pct if state=="Texas", meanonly
local tx_share = r(mean)
quietly summarize share_pct if state=="Louisiana", meanonly
local la_share = r(mean)

* Pre-format every share as a string ONCE, here, so no display or numadd call
* below nests a `=string(round(...))' expression inside a longer string that
* also carries other macro references (CONVENTIONS trap #2).
local _minshare_s = string(round(`min_share',0.1),"%3.1f")
local _maxshare_s = string(round(`max_share',0.1),"%3.1f")
local _txshare_s  = string(round(`tx_share',0.1),"%3.1f")
local _lashare_s  = string(round(`la_share',0.1),"%3.1f")

display as text "Lowest of the 8: `minstate' at `_minshare_s'%. Highest: `maxstate' at `_maxshare_s'%."
display as text "Texas: `_txshare_s'%, rank `tx_rank8' of `n_benchmark' (1=lowest). Louisiana: `_lashare_s'%."
list state share_pct rank8, clean

* CORRECTION to 01_evidence/03_creative_economy_bea/_findings.md bullet 2:
* that file's headline sentence claims Texas is the lowest of the 8; its own
* supporting numbers (quoted two lines later in the same bullet) list
* Louisiana lower. Direct inspection of the tidy CSV confirms the supporting
* numbers, not the headline sentence: Louisiana is lowest, Texas is 2nd-lowest.
local tx_is_lowest = ("`minstate'"=="Texas")
if `tx_is_lowest'==0 {
    display as error "CORRECTION to 01_evidence/03_creative_economy_bea/_findings.md bullet 2: that bullet’s headline sentence states Texas has the lowest arts/culture GDP share of the 8 benchmark states. Direct inspection of acpsa_state_totals_long_2001_2023.csv shows `minstate' (`_minshare_s'%) is lower than Texas (`_txshare_s'%, rank `tx_rank8' of 8). The bullet’s own supporting table two lines later lists `minstate' below Texas and is correct; only the headline sentence is wrong. This module uses rank `tx_rank8' of 8 (2nd-lowest), not lowest, and titles fig17 panel A accordingly. The evidence folder’s _findings.md should be corrected at the source."
}

numadd, key(bea_gdp_share_correction_tx_not_lowest) value(`tx_rank8') formatted("rank `tx_rank8' of `n_benchmark' (1=lowest), not lowest") ///
    unit("correction to 01_evidence/03_creative_economy_bea/_findings.md bullet 2") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_totals_long_2001_2023.csv") ///
    note("The evidence memo’s bullet 2 headline sentence says Texas has the lowest arts/culture value-added share of state GDP among the 8 benchmark states; its own supporting numbers, quoted in the same bullet, list Louisiana (2.1%) below Texas (2.5%). Direct inspection of the tidy CSV here confirms the supporting numbers: Louisiana is lowest of the 8 at `_lashare_s'%, Texas is 2nd-lowest at `_txshare_s'% (rank `tx_rank8' of `n_benchmark', 1=lowest). Fixed in this module’s figure and registry; the source memo’s headline sentence should be corrected.")

numadd, key(bea_gdp_share_tx_2023) value(`=round(`tx_share',0.1)') formatted("`_txshare_s'%") ///
    unit("percent of state GDP, arts/culture value added, 2023") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_totals_long_2001_2023.csv") ///
    note("Texas arts and cultural production value added as a share of Texas state GDP, 2023, BEA ACPSA. Among the 8 benchmark states (CA, FL, GA, LA, NY, TN, TX, WA) Texas ranks `tx_rank8' of 8, 1=lowest -- 2nd-lowest, not lowest.")

numadd, key(bea_gdp_share_la_2023) value(`=round(`la_share',0.1)') formatted("`_lashare_s'%") ///
    unit("percent of state GDP, arts/culture value added, 2023") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_totals_long_2001_2023.csv") ///
    note("Louisiana arts and cultural production value added as a share of state GDP, 2023 -- the lowest of the 8 benchmark states, below Texas.")

numadd, key(bea_gdp_share_us_avg_2023) value(`=round(`us_avg_share',0.1)') formatted("`us_avg_s'%") ///
    unit("percent of GDP, US total, 2023") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_totals_long_2001_2023.csv") ///
    note("US arts/culture value added as a share of US GDP, 2023. Reference line on fig17 panel A; the United States row is the national average, not a 9th benchmark state, and is excluded from the 8-state bar count and from the rank8 calculation above.")

* This module's own tidy extract covers only the 8 benchmark states plus the
* US average -- it cannot independently verify a full 50-state-plus-DC rank.
* The national-rank claim below is therefore cited to the evidence memo's own
* reading of the full BEA release, not re-derived from a file in this
* project; registered as a DIFFERENT and WEAKER claim than the 8-state rank
* above, per this module's tasking.
numadd, key(bea_gdp_share_tx_national_rank) value(36) formatted("36th of 51 (50 states + DC)") ///
    unit("national rank, arts/culture value-added share of state GDP, 2023 -- NOT independently re-derived here") ///
    source("01_evidence/03_creative_economy_bea/_findings.md") ///
    note("Texas ranks 36th of 51 (50 states + DC) nationally on arts/culture value-added share of state GDP, 2023, per the evidence memo’s reading of the full BEA ACPSA release. This project’s own tidy CSV extract (acpsa_state_totals_long_2001_2023.csv) contains only the 8 benchmark states plus the US average, so this 36th-of-51 figure is cited from the evidence memo, not independently recomputed from a file in this project. It is a different and weaker claim than the rank `tx_rank8' of 8 benchmark states figure above -- keep the two separate and always name which comparison set a given rank refers to.")

sort share_pct
tempfile fig17a_data
save `fig17a_data'

* Panel A's own title is a descriptive panel label, not a finding: the finding
* it used to carry (Texas 2nd-lowest of the 8) is promoted to the combined
* figure's main title below, which previously named the data source instead of
* saying anything. Same division of labour as fig16, where the panel titles
* describe and the main title states the finding.
local fig17a_title = "Arts and culture value added as a share of state GDP, 2023"
local _tlen = length("`fig17a_title'")
display as text "fig17 panel A title length check: `_tlen' characters (target under ~70)."

* Highlight color: Texas orange, every other state a shared muted navy so the
* single comparison of interest (Texas against the pack) reads at a glance.
generate double bar_tx        = share_pct if state=="Texas"
generate double bar_other     = share_pct if state!="Texas"

* Built as a twoway with explicit y positions rather than
* graph hbar bar_other bar_tx, over(rank8) asyvars. That hbar form gives every
* over() group TWO bar slots and leaves one of them empty in every group, so
* the seven muted bars landed in the upper slot of their group while the orange
* Texas bar landed in the lower slot -- each about half a row away from its own
* tick label, in opposite directions. It is the same defect fig18 had in a
* larger form. With explicit y positions the tick and the bar are the same
* coordinate by construction.
sort rank8
generate double ypos = `n_benchmark' + 1 - rank8    // lowest share at the top
local ylab17 ""
forvalues i = 1/`n_benchmark' {
    local nm = state[`i']
    local yp = `n_benchmark' + 1 - `i'
    local ylab17 `"`ylab17' `yp' "`nm'""'
}
generate str8 lab_share = string(share_pct, "%3.1f")
local ytop17 = `n_benchmark' + 0.55
local xmax17 = 1.12 * `max_share'

twoway ///
    (bar bar_other ypos, horizontal barwidth(0.55) color("${MUTED}")) ///
    (bar bar_tx ypos, horizontal barwidth(0.55) color("${ORANGE}")) ///
    (scatter ypos share_pct, msymbol(none) mlabel(lab_share) ///
        mlabposition(3) mlabgap(1) mlabcolor("${TEXTC}") mlabsize(2.6)) ///
    , xline(`us_avg_share', lcolor("${NAVY}") lpattern(dash) lwidth(thin)) ///
      ylabel(`ylab17', angle(0) labsize(2.6) noticks) ///
      yscale(range(0.45 `ytop17')) ytitle("") ///
      xtitle("Percent of state GDP, arts/culture value added, 2023", size(2.6)) ///
      xlabel(0(2)10, labsize(2.6)) xscale(range(0 `xmax17')) ///
      title("`fig17a_title'", size(3.1) color("${NAVY}")) ///
      legend(off) ///
      graphregion(color(white)) ///
      name(g_fig17a, replace)


* ---- Panel B: Texas, performing arts companies vs. independent artists,
*      2001-2023, showing the crossover. ----
import delimited "${EV_BEA}/tidy/acpsa_state_industry_detail_2001_2023.csv", varnames(1) case(preserve) clear
keep if state=="Texas"
keep year industry acpsa_value_added_thousands

preserve
    keep if industry=="Performing arts companies"
    keep year acpsa_value_added_thousands
    rename acpsa_value_added_thousands performing_va
    tempfile perf
    save `perf'
restore
preserve
    keep if strpos(industry,"ndependent")>0
    keep year acpsa_value_added_thousands
    rename acpsa_value_added_thousands indep_va
    tempfile indep
    save `indep'
restore

clear
use `perf'
merge 1:1 year using `indep', nogenerate
sort year
generate double performing_va_m = performing_va/1000
generate double indep_va_m      = indep_va/1000
generate double diff_va         = indep_va - performing_va
generate byte   indep_ahead     = (diff_va>0)

display as text _newline "{hline 72}"
display as text "TASK 3 / FIGURE 17 panel B: Texas performing-arts vs. independent-artist VA"
display as text "{hline 72}"
list year performing_va_m indep_va_m indep_ahead, clean

* The FIRST year independent artists' VA exceeds performing-arts companies'
* VA is not the same as a LASTING crossover: this series has an earlier,
* temporary blip (verify below) before the change holds for good. The title
* must describe whichever one is actually true of the chart as drawn, so
* both are computed and checked explicitly rather than assumed.
quietly summarize year if indep_ahead==1, meanonly
local first_crossover_year = r(min)
quietly count if year>=`first_crossover_year' & indep_ahead==0
local n_reversals_from_first = r(N)
display as text "First year independent artists' VA exceeds performing-arts-companies' VA: `first_crossover_year'. Reversal years after that point: `n_reversals_from_first' (0 = clean, uninterrupted crossover from that year on)."

* Stable crossover: the EARLIEST year Y such that independent artists' VA
* exceeds performing-arts companies' VA in every year from Y through the end
* of the series (2023), i.e. the start of the run that is still unbroken at
* the last observed year. Found by scanning candidate years in order and
* stopping at the first one with zero reversal years after it.
quietly summarize year, meanonly
local first_year = r(min)
local last_year  = r(max)
local stable_crossover_year = .
local y = `first_year'
while missing(`stable_crossover_year') & `y'<=`last_year' {
    quietly count if year>=`y' & indep_ahead==0
    if r(N)==0 {
        local stable_crossover_year = `y'
    }
    local y = `y' + 1
}
quietly count if year>=`stable_crossover_year' & indep_ahead==0
local n_reversals_from_stable = r(N)
local n_blip_years = `n_reversals_from_first'
display as text "Stable (lasting-through-2023) crossover year: `stable_crossover_year'. Reversal years after THAT point: `n_reversals_from_stable' (must be 0 by construction)."
assert `n_reversals_from_stable'==0
display as text "Years between the first (`first_crossover_year') and stable (`stable_crossover_year') crossover where performing arts companies pulled back ahead: `n_blip_years'."

quietly summarize indep_va_m if year==2023, meanonly
local indep_2023 = r(mean)
quietly summarize performing_va_m if year==2023, meanonly
local perf_2023 = r(mean)
local gap_2023 = `indep_2023' - `perf_2023'

* This module reports and titles fig17 panel B using the STABLE crossover
* year, not the first (transient) one, since "independent artists overtook
* performing arts companies in `first_crossover_year'" would be true only
* for 2 years before reverting -- a claim a reader could check against the
* chart and find contradicted by 2009-2010.
numadd, key(bea_crossover_year_tx) value(`stable_crossover_year') formatted("`stable_crossover_year'") ///
    unit("first year of the UNBROKEN run through 2023, calendar") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_industry_detail_2001_2023.csv") ///
    note("Texas independent-artists-writers-and-performers value added has exceeded performing-arts-companies value added in every year from `stable_crossover_year' through 2023, BEA ACPSA state industry detail. There was an earlier, temporary crossover starting in `first_crossover_year' that reversed after 2 years (performing arts companies pulled back ahead in 2009-2010) before the change took hold for good in `stable_crossover_year' -- the earlier blip is registered separately (bea_first_crossover_year_tx) so the paper does not overstate the `first_crossover_year' date as the durable change.")

numadd, key(bea_first_crossover_year_tx) value(`first_crossover_year') formatted("`first_crossover_year' (temporary, reversed)") ///
    unit("first year, calendar -- NOT the lasting crossover, see bea_crossover_year_tx") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_industry_detail_2001_2023.csv") ///
    note("First year independent-artists VA exceeded performing-arts-companies VA in Texas was `first_crossover_year', but performing arts companies pulled back ahead for 2009 and 2010 before independent artists retook and held the lead from `stable_crossover_year' onward. Registered so the earlier date is not mistaken for the durable change.")

numadd, key(bea_indep_artists_va_tx_2023) value(`=round(`indep_2023',0.1)') formatted("\$`=string(round(`indep_2023',0.1),"%6.1f")'M") ///
    unit("2023 nominal dollars, millions") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_industry_detail_2001_2023.csv") ///
    note("Texas independent-artists-writers-and-performers value added, 2023, BEA ACPSA, nominal dollars (this is a same-year level comparison against performing arts companies below, so no deflation is applied here).")

numadd, key(bea_performing_arts_va_tx_2023) value(`=round(`perf_2023',0.1)') formatted("\$`=string(round(`perf_2023',0.1),"%6.1f")'M") ///
    unit("2023 nominal dollars, millions") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_industry_detail_2001_2023.csv") ///
    note("Texas performing-arts-companies value added, 2023, BEA ACPSA, nominal dollars.")

numadd, key(bea_indep_vs_performing_gap_tx_2023) value(`=round(`gap_2023',0.1)') formatted("\$`=string(round(`gap_2023',0.1),"%6.1f")'M") ///
    unit("2023 nominal dollars, millions, gap") ///
    source("01_evidence/03_creative_economy_bea/tidy/acpsa_state_industry_detail_2001_2023.csv") ///
    note("2023 gap between Texas independent-artist value added and performing-arts-company value added (independent minus performing), nominal dollars, same-year comparison so no deflation applies.")

quietly summarize year if !missing(indep_va_m)
local ly_indep = r(max)
quietly summarize year if !missing(performing_va_m)
local ly_perf = r(max)
generate lbl_indep = "Independent artists, writers, performers" if year==`ly_indep'
generate lbl_perf  = "Performing arts companies" if year==`ly_perf'

local fig17b_title = "Independent artists overtook arts companies in Texas in `stable_crossover_year'"
local _tlen = length("`fig17b_title'")
display as text "fig17 panel B title length check: `_tlen' characters (target under ~70)."

* The crossover year used to be printed directly above its own marker, where
* the two series meet -- so the orange line ran straight through the digits.
* It now sits at the top of the plot on a dashed vertical rule that points at
* the same year, in the report's dark text colour rather than light gray.
quietly summarize indep_va_m
local vamax = r(max)
local yaxis17b = ceil(`vamax' / 500) * 500
if (`yaxis17b' - `vamax') < 200 local yaxis17b = `yaxis17b' + 500
local ycross17b = 0.94 * `yaxis17b'
display as text "fig17 panel B: y-axis 0 to `yaxis17b' (series max `vamax'); crossover label at `ycross17b'."

* AXIS UNITS. BEA publishes the STATE-level ACPSA series in current dollars
* only -- there is no state chained-dollar file (01_evidence/03_creative_
* economy_bea/_sources.md). So these are nominal dollars of each year, and the
* old axis title "2023 nominal dollars, millions" was self-contradictory for a
* 2001-2023 series: it read as constant 2023 dollars AND as nominal at once.
twoway ///
    (line indep_va_m year, lcolor("${ORANGE}") lwidth(medthick)) ///
    (line performing_va_m year, lcolor("${NAVY}")) ///
    (scatter indep_va_m year if year==`ly_indep', mlabel(lbl_indep) mlabcolor("${ORANGE}") mlabposition(1) mlabsize(2.4) msymbol(none)) ///
    (scatter performing_va_m year if year==`ly_perf', mlabel(lbl_perf) mlabcolor("${NAVY}") mlabposition(3) mlabsize(2.4) msymbol(none)) ///
    (scatter performing_va_m year if year==`stable_crossover_year', mlabcolor("${MUTED}") msymbol(O) mcolor("${MUTED}") msize(small)) ///
    , ///
    xline(`stable_crossover_year', lcolor("${MUTED}") lpattern(shortdash) lwidth(thin)) ///
    text(`ycross17b' `stable_crossover_year' "`stable_crossover_year'", placement(e) size(2.5) color("${TEXTC}")) ///
    title("`fig17b_title'", size(3.1) color("${NAVY}")) ///
    xtitle("") ytitle("Value added, millions of nominal dollars", size(2.6)) ///
    xlabel(2001(4)2023) xscale(range(2001 2032)) ///
    ylabel(0(500)`yaxis17b', angle(horizontal) labsize(2.6)) ///
    yscale(range(0 `yaxis17b')) ///
    legend(off) ///
    graphregion(color(white)) plotregion(margin(zero)) ///
    name(g_fig17b, replace)

* rows(1) (side by side) squeezes each panel to half the canvas width, and
* Stata does not wrap a long title() or an mlabel() that runs past the edge
* -- it silently truncates (confirmed: panel A's own title clipped to "...8
* benchmark stat" and panel B's line label clipped to "...writers, p" when
* this was rows(1)). rows(2) (stacked) gives each panel the FULL canvas
* width, the same layout that already worked cleanly for fig16.
* MAIN TITLE. This was the one title in the set that named its data source
* ("Texas's arts economy: BEA satellite-account data, 2001-2023") and the one
* that stated no finding. The source belongs in the LaTeX caption, so the
* verified panel A finding is promoted here instead. It is bounded to the 8
* states the figure actually draws, and rebuilt from the computed rank rather
* than typed, so it cannot drift from the chart.
local fig17_title = "Texas has the 2nd-lowest arts share of GDP among `n_benchmark' benchmark states"
assert `tx_rank8'==2
local _tlen = length("`fig17_title'")
display as text "fig17 main title length check: `_tlen' characters (target under ~70)."

graph combine g_fig17a g_fig17b, rows(2) ///
    title("`fig17_title'", $TITLEOPT) ///
    subtitle("Top: 8-state comparison for 2023, Texas highlighted; dashed line is the US average." ///
             "Bottom: Texas value added, nominal dollars of each year, not adjusted for inflation.", $SUBOPT) ///
    graphregion(color(white)) ///
    name(g_fig17, replace)

figsave, name(fig17_bea_arts)

preserve
    use `fig17a_data', clear
    export delimited state share_pct rank8 using "${OUT}/fig17_bea_arts_panelA_states2023.csv", replace
restore
export delimited year performing_va_m indep_va_m indep_ahead using "${OUT}/fig17_bea_arts_panelB_tx_timeseries.csv", replace

display as text "fig17 complete."


* ================================================================
* NOTE BEFORE SECTION 4: staging the full-national SVOG file.
*
* This module's declared inputs are svog_awards_TEXAS.csv and
* svog_awards_AUSTIN_AREA.csv, both scoped to Texas. Task 4 also asks for
* Nashville, TN, which lies outside both files. The same SBA "awards as of
* 07-05-2022" file that produced those two Texas extracts also exists in
* full-national form; per CONVENTIONS.md #1 (external inputs are copied into
* data/external, never read from an absolute/scratch path inside a numbered
* module), that full file was copied in once, ahead of this run, as
* ${DATAX}/SVOG_awards_full_national.dta (13,011 rows; state field arrives
* upper-cased/trimmed at source, city field does not -- a city_norm =
* upper(trim(itrim(city))) variable is included precisely because an exact
* string match on the raw city field silently drops case-variant rows, e.g.
* "NASHVILLE" rows sit alongside "Nashville" rows in the source data). Its
* Texas subset was cross-checked row-for-row and dollar-for-dollar against
* svog_awards_TEXAS.csv at staging time (758 rows, $1,167,322,216, exact
* match). If SVOG_awards_full_national.dta is ever missing, rebuild it by
* re-importing the SBA awards-as-of-7-5-22 file with import delimited,
* bindquote(strict), and the same city_norm/state_norm construction.
* ================================================================
requirefile "${DATAX}/SVOG_awards_full_national.dta"


* ================================================================
* SECTION 4. TASK 4 / FIGURE 18: SVOG federal pandemic relief, Texas and the
*            Austin area, with Austin against Houston, Dallas-Fort Worth, and
*            Nashville. The Houston-area and Dallas-Fort Worth-area totals
*            use a hand-built city-name list against Census place names, NOT
*            official CBSA/MSA boundaries -- approximate and non-exhaustive
*            by construction, exactly like the Austin-area and Nashville
*            city-only matches this evidence folder's own _sources.md
*            documents. That method is registered explicitly below.
* ================================================================
import delimited "${EV_SVOG}/svog_awards_TEXAS.csv", varnames(1) case(preserve) clear
generate double amt = total_awarded_usd
generate str60 city_norm = upper(trim(itrim(city)))

quietly count
local tx_n = r(N)
quietly summarize amt
local tx_total = r(sum)

gsort -amt
quietly summarize amt
local tx_total2 = r(sum)
quietly summarize amt in 1/10
local tx_top10 = r(sum)
local tx_top10_share = 100*`tx_top10'/`tx_total2'
quietly count if amt>=9999999.5
local tx_cap_hits = r(N)

display as text _newline "{hline 72}"
display as text "TASK 4 / FIGURE 18: SVOG federal relief, Texas + metro comparison"
display as text "{hline 72}"
display as text "Texas: N=`tx_n', total=$`=string(`tx_total',"%12.0fc")', top10 share=`=string(round(`tx_top10_share',0.1),"%4.1f")'%, recipients at \$10M cap=`tx_cap_hits'"

* ---- Hand-built Houston-area and Dallas-Fort Worth-area city lists,
*      applied to this Texas-only file (both metros sit fully in Texas, so
*      no state filter beyond "this file is Texas already" is needed). ----
generate byte houston_area = 0
foreach c in "HOUSTON" "SUGAR LAND" "THE WOODLANDS" "KATY" "PEARLAND" "BAYTOWN" "CONROE" ///
    "LEAGUE CITY" "MISSOURI CITY" "PASADENA" "SPRING" "HUMBLE" "FRIENDSWOOD" "TEXAS CITY" ///
    "WEBSTER" "LA PORTE" "TOMBALL" "ROSENBERG" "CYPRESS" "GALVESTON" "DEER PARK" ///
    "CHANNELVIEW" "RICHMOND" "STAFFORD" "BELLAIRE" "KINGWOOD" "ALVIN" "ANGLETON" ///
    "MANVEL" "KLEIN" {
    replace houston_area = 1 if city_norm=="`c'"
}
generate byte dfw_area = 0
foreach c in "DALLAS" "FORT WORTH" "ARLINGTON" "PLANO" "IRVING" "GARLAND" "MCKINNEY" "FRISCO" ///
    "DENTON" "GRAPEVINE" "GRAND PRAIRIE" "MESQUITE" "CARROLLTON" "RICHARDSON" "LEWISVILLE" ///
    "ALLEN" "FLOWER MOUND" "NORTH RICHLAND HILLS" "MANSFIELD" "EULESS" "DESOTO" "CEDAR HILL" ///
    "ROWLETT" "WYLIE" "KELLER" "COPPELL" "SOUTHLAKE" "BURLESON" "BEDFORD" "HALTOM CITY" ///
    "WAXAHACHIE" "ROCKWALL" "WEATHERFORD" "PROSPER" "CELINA" "LITTLE ELM" "THE COLONY" ///
    "FARMERS BRANCH" "UNIVERSITY PARK" "HIGHLAND PARK" "DUNCANVILLE" "LANCASTER" "SACHSE" ///
    "MURPHY" "ADDISON" "HURST" "WATAUGA" "COLLEYVILLE" "BENBROOK" "FATE" "FORNEY" "ROYSE CITY" {
    replace dfw_area = 1 if city_norm=="`c'"
}
generate byte san_antonio = (city_norm=="SAN ANTONIO")

quietly summarize amt if houston_area==1
local houston_total = r(sum)
quietly count if houston_area==1
local houston_n = r(N)
quietly summarize amt if dfw_area==1
local dfw_total = r(sum)
quietly count if dfw_area==1
local dfw_n = r(N)
quietly summarize amt if san_antonio==1
local sa_total = r(sum)
quietly count if san_antonio==1
local sa_n = r(N)

display as text "Houston-area: N=`houston_n', $`=string(`houston_total',"%12.0fc")'"
display as text "Dallas-Fort Worth-area: N=`dfw_n', $`=string(`dfw_total',"%12.0fc")'"
display as text "San Antonio (city only, bonus context): N=`sa_n', $`=string(`sa_total',"%12.0fc")'"

* ---- Austin-area: the evidence folder's own pre-built extract. ----
preserve
    import delimited "${EV_SVOG}/svog_awards_AUSTIN_AREA.csv", varnames(1) case(preserve) clear
    generate double amt = total_awarded_usd
    quietly count
    local austin_n = r(N)
    gsort -amt
    quietly summarize amt
    local austin_total = r(sum)
    quietly summarize amt in 1/10
    local austin_top10 = r(sum)
    local austin_top10_share = 100*`austin_top10'/`austin_total'
    quietly count if amt>=9999999.5
    local austin_cap_hits = r(N)
    display as text "Austin-area: N=`austin_n', $`=string(`austin_total',"%12.0fc")', top10 share=`=string(round(`austin_top10_share',0.1),"%4.1f")'%, recipients at \$10M cap=`austin_cap_hits'"
restore

* ---- Nashville, TN: needs the full-national file (staged above). ----
preserve
    use "${DATAX}/SVOG_awards_full_national.dta", clear
    quietly summarize total_awarded_usd_nominal if state_norm=="TN" & city_norm=="NASHVILLE"
    local nashville_total = r(sum)
    quietly count if state_norm=="TN" & city_norm=="NASHVILLE"
    local nashville_n = r(N)
    display as text "Nashville (TN, city only): N=`nashville_n', $`=string(`nashville_total',"%12.0fc")'"
restore

numadd, key(svog_metro_method_note) value(1) formatted("hand-built city-name list, not official MSA boundaries") ///
    unit("methodological note") ///
    source("01_evidence/07_svog_federal_relief/_sources.md") ///
    note("Austin-area figure uses the evidence folder's own pre-built 26-place city list (svog_awards_AUSTIN_AREA.csv). Houston-area (`houston_n' recipients) and Dallas-Fort Worth-area (`dfw_n' recipients) figures were built in this module from svog_awards_TEXAS.csv using this module's own hand-built city-name lists (29 and 49 place names respectively; full lists are in this do-file's SECTION 4 source), matched on a case/whitespace-normalized city field. Nashville (`nashville_n' recipients) and San Antonio (`sa_n' recipients) use a single-city, case-normalized match against the full national SVOG file, following the same convention the evidence folder used for those two cities. None of the four metro figures corresponds to an official Census CBSA/MSA boundary; treat all four as approximate, directional comparisons, not authoritative metro totals, and expect them to differ somewhat from any other hand-built city list covering the same metro.")

numadd, key(svog_tx_total) value(`tx_total') formatted("\$`=string(`tx_total'/1000000000,"%4.2f")' billion") ///
    unit("nominal dollars, 758 recipients") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_TEXAS.csv") ///
    note("Total SVOG awards to Texas recipients, SBA awards-as-of-7-5-22 file, `tx_n' recipients. Shown for context; not plotted on fig18's metro-comparison bars because it is a whole-state total, not a metro figure, and dwarfs all four metro bars on the same axis.")

numadd, key(svog_tx_top10_share) value(`=round(`tx_top10_share',0.1)') formatted("`=string(round(`tx_top10_share',0.1),"%4.1f")'%") ///
    unit("percent of Texas SVOG dollars, top 10 of 758 recipients") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_TEXAS.csv") ///
    note("Share of all Texas SVOG dollars captured by the 10 largest of 758 Texas recipients.")

numadd, key(svog_tx_cap_hits) value(`tx_cap_hits') formatted("`tx_cap_hits' of 758 recipients") ///
    unit("count at/above the \$10,000,000 per-entity cap") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_TEXAS.csv") ///
    note("Number of Texas SVOG recipients whose total award is at or above the program’s \$10,000,000 per-entity cap.")

numadd, key(svog_austin_total) value(`austin_total') formatted("\$`=string(round(`austin_total'/1000000,0.1),"%6.1f")' million") ///
    unit("nominal dollars, `austin_n' recipients") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_AUSTIN_AREA.csv") ///
    note("Total SVOG awards to Austin-area recipients (Austin, Round Rock, San Marcos, Pflugerville, and other nearby places -- see _sources.md's city list), `austin_n' recipients, about `=string(round(100*`austin_total'/`tx_total',0.1),"%4.1f")'% of the Texas total.")

numadd, key(svog_austin_top10_share) value(`=round(`austin_top10_share',0.1)') formatted("`=string(round(`austin_top10_share',0.1),"%4.1f")'%") ///
    unit("percent of Austin-area SVOG dollars, top 10 of `austin_n' recipients") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_AUSTIN_AREA.csv") ///
    note("Share of all Austin-area SVOG dollars captured by the 10 largest of `austin_n' Austin-area recipients.")

numadd, key(svog_austin_cap_hits) value(`austin_cap_hits') formatted("`austin_cap_hits' of `austin_n' recipients") ///
    unit("count at/above the \$10,000,000 per-entity cap") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_AUSTIN_AREA.csv") ///
    note("Number of Austin-area SVOG recipients whose total award is at or above the program’s \$10,000,000 per-entity cap: Alamo South Lamar LP, Circuit of the Americas LLC dba Germania Insurance Amphitheater, Flix Entertainment LLC (Round Rock), The University of Texas at Austin, and Messina Touring Group LLC.")

numadd, key(svog_houston_area_total) value(`houston_total') formatted("\$`=string(round(`houston_total'/1000000,0.1),"%6.1f")' million") ///
    unit("nominal dollars, `houston_n' recipients, hand-built city list") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_TEXAS.csv") ///
    note("Houston-area SVOG total, this module’s own hand-built 29-place city list matched against svog_awards_TEXAS.csv, case/whitespace-normalized. Not an official MSA total.")

numadd, key(svog_dfw_area_total) value(`dfw_total') formatted("\$`=string(round(`dfw_total'/1000000,0.1),"%6.1f")' million") ///
    unit("nominal dollars, `dfw_n' recipients, hand-built city list") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_TEXAS.csv") ///
    note("Dallas-Fort Worth-area SVOG total, this module’s own hand-built 49-place city list matched against svog_awards_TEXAS.csv, case/whitespace-normalized. Not an official MSA total.")

numadd, key(svog_nashville_total) value(`nashville_total') formatted("\$`=string(round(`nashville_total'/1000000,0.1),"%6.1f")' million") ///
    unit("nominal dollars, `nashville_n' recipients, city of Nashville only") ///
    source("03_analysis/data/external/SVOG_awards_full_national.dta") ///
    note("Nashville, TN city only (Nashville-Davidson is a consolidated city-county government, so this captures nearly all of Davidson County but excludes MSA suburbs like Franklin and Murfreesboro -- the true Nashville-MSA total would be higher). Not an official MSA total.")

numadd, key(svog_san_antonio_total_bonus) value(`sa_total') formatted("\$`=string(round(`sa_total'/1000000,0.1),"%6.1f")' million") ///
    unit("nominal dollars, `sa_n' recipients, city of San Antonio only, bonus context (not one of the 3 required comparators)") ///
    source("01_evidence/07_svog_federal_relief/svog_awards_TEXAS.csv") ///
    note("San Antonio city-only SVOG total, provided as bonus context alongside the Houston/Dallas-Fort Worth/Nashville comparators the tasking required; not plotted on fig18.")

* ---- Build the 4-geography comparison dataset for fig18. ----
clear
set obs 4
generate str24 geo = ""
generate double total_usd = .
replace geo = "Dallas-Fort Worth"  in 1
replace total_usd = `dfw_total'    in 1
replace geo = "Austin"             in 2
replace total_usd = `austin_total' in 2
replace geo = "Houston"            in 3
replace total_usd = `houston_total' in 3
replace geo = "Nashville"          in 4
replace total_usd = `nashville_total' in 4
generate double total_millions = total_usd/1000000

local austin_beats_houston = (`austin_total' > `houston_total')
local austin_beats_nashville = (`austin_total' > `nashville_total')
local austin_beats_dfw = (`austin_total' > `dfw_total')
display as text "Austin > Houston? `austin_beats_houston'. Austin > Nashville? `austin_beats_nashville'. Austin > DFW? `austin_beats_dfw'."

local fig18_title = "Austin’s SVOG total beat Houston and Nashville, trailed DFW"
local _tlen = length("`fig18_title'")
display as text "fig18 title length check: `_tlen' characters (target under ~70)."

gsort -total_millions
generate byte ordg = _n
* Confirm Austin really is 2nd by dollars in this sorted order before coloring
* its bar orange -- if Austin's rank ever changes, this assert stops the module
* rather than silently coloring the wrong bar.
quietly summarize ordg if geo=="Austin", meanonly
assert r(mean)==2

* WHY THIS IS A twoway AND NOT A graph hbar. The previous version was
* graph hbar bar_g1 bar_g2 bar_g3 bar_g4, over(ordg) asyvars -- one masked copy
* of the series per metro, which was the only way to get both per-metro colors
* and visible axis labels out of graph hbar. But four variables give every
* over() group FOUR bar slots and three of them are empty in every group, so
* each metro's bar sat in a different slot within its own group: Dallas-Fort
* Worth's bar at the top of its group (label below it), Nashville's at the
* bottom of its group (label well above it). Reading across, a metro could be
* matched to the wrong dollar figure. Explicit y positions make the tick and
* the bar the same coordinate, so they cannot drift.
generate double ypos = 5 - ordg          // largest total at the top
generate double bar_other  = total_millions if geo!="Austin"
generate double bar_austin = total_millions if geo=="Austin"
generate str12 lab_g = strtrim(string(total_millions, "%6.1f"))

local ylab18 ""
forvalues i = 1/4 {
    local nm = geo[`i']
    local yp = 5 - `i'
    local ylab18 `"`ylab18' `yp' "`nm'""'
}
quietly summarize total_millions
local xmax18 = 1.13 * r(max)

twoway ///
    (bar bar_other ypos, horizontal barwidth(0.58) color("${MUTED}")) ///
    (bar bar_austin ypos, horizontal barwidth(0.58) color("${ORANGE}")) ///
    (scatter ypos total_millions, msymbol(none) mlabel(lab_g) ///
        mlabposition(3) mlabgap(1.5) mlabcolor("${TEXTC}") mlabsize(2.8)) ///
    , ylabel(`ylab18', angle(0) labsize(3.0) noticks) ///
      yscale(range(0.42 4.58)) ytitle("") ///
      xtitle("\$ millions, nominal", $XTOPT) ///
      xlabel(0(100)400, labsize(2.8)) xscale(range(0 `xmax18')) ///
      title("`fig18_title'", $TITLEOPT) ///
      subtitle("SVOG awards by metro area, \$ millions; hand-built city-name matches, not official MSA boundaries." ///
               "The three Texas bars sit inside a \$1.17 billion Texas total; Nashville, Tennessee, does not.", $SUBOPT) ///
      legend(off) ///
      graphregion(color(white)) plotregion(margin(l=2 r=4)) ///
      name(g_fig18, replace)

figsave, name(fig18_svog_metro)

preserve
    export delimited geo total_usd total_millions using "${OUT}/fig18_svog_metro.csv", replace
restore

display as text "fig18 complete."


* ================================================================
* SECTION 5. OPTIONAL / FIGURE 21: other cities' self-reported average music
*            income (Sound Music Cities censuses) against Austin's data gap.
*            Every figure below was verified directly against
*            01_evidence/05_music_census_pay_surveys/national_and_benchmark_
*            surveys.md before use (see that file's SS 6c comparison table).
*            These are self-selected SURVEY AVERAGES, not medians, and are
*            NOT comparable to this report's ACS PUMS median-earnings
*            figures used elsewhere -- stated in the subtitle and caption,
*            not smoothed over.
* ================================================================
clear
set obs 16
generate byte ord = _n
generate str20 city = ""
generate double income_usd = .
generate int    n_resp = .
generate int    census_year = .

replace city = "Nashville"     in 1
replace income_usd = 52000     in 1
replace n_resp = 4256          in 1
replace census_year = 2024     in 1

replace city = "Baltimore"     in 2
replace income_usd = 35000     in 2
replace census_year = 2024     in 2

replace city = "Charlotte"     in 3
replace income_usd = 29000     in 3
replace n_resp = 1046          in 3
replace census_year = 2025     in 3

replace city = "Minneapolis"   in 4
replace income_usd = 28000     in 4
replace census_year = 2024     in 4

replace city = "NW Arkansas"   in 5
replace income_usd = 26000     in 5
replace census_year = 2024     in 5

replace city = "Baton Rouge"   in 6
replace income_usd = 25000     in 6
replace census_year = 2025     in 6

replace city = "New Orleans"   in 7
replace income_usd = 23000     in 7
replace n_resp = 1504          in 7
replace census_year = 2024     in 7

replace city = "Washington DC" in 8
replace income_usd = 23000     in 8
replace n_resp = 2738          in 8
replace census_year = 2024     in 8

replace city = "Cleveland"     in 9
replace income_usd = 21000     in 9
replace n_resp = 2768          in 9
replace census_year = 2023     in 9

replace city = "Detroit"       in 10
replace income_usd = 20000     in 10
replace n_resp = 2518          in 10
replace census_year = 2026     in 10

replace city = "Columbus"      in 11
replace income_usd = 19390     in 11
replace n_resp = 1555          in 11
replace census_year = 2023     in 11

replace city = "Greensboro"    in 12
replace income_usd = 18000     in 12
replace n_resp = 1126          in 12
replace census_year = 2024     in 12

replace city = "Tulsa"         in 13
replace income_usd = 18000     in 13
replace n_resp = 1003          in 13
replace census_year = 2024     in 13

replace city = "Lawrence"      in 14
replace income_usd = 16000     in 14
replace n_resp = 826           in 14
replace census_year = 2024     in 14

replace city = "Anchorage"     in 15
replace income_usd = 15000     in 15
replace n_resp = 377           in 15
replace census_year = 2024     in 15

* Austin: an explicit gap, not a bar. The city's own 2022 Greater Austin
* Music Census removed the income-quantification questions the 2014 census
* had used, on its community partners' advice (verified directly against the
* census PDF's own front matter in this project's evidence folder); no
* dollar figure exists for any year after 2013. income_usd is left MISSING
* (not zero -- a zero would misstate "no data" as "musicians earn nothing")
* deliberately, and the category label itself says so, so the row still
* appears on the axis with no bar drawn under it, self-explanatory without
* relying on blabel (which has no value to print for a missing observation).
replace city = "Austin (no data)" in 16
replace census_year = 2022        in 16

display as text _newline "{hline 72}"
display as text "OPTIONAL FIGURE 21: city music-census self-reported average income"
display as text "{hline 72}"
list city income_usd n_resp census_year, clean

foreach c in Nashville Baltimore Charlotte Minneapolis "NW Arkansas" "Baton Rouge" ///
    "New Orleans" "Washington DC" Cleveland Detroit Columbus Greensboro Tulsa Lawrence Anchorage {
    local cl = lower(subinstr(subinstr("`c'"," ","_",.),"NW_Arkansas","nwarkansas",.))
    quietly summarize income_usd if city=="`c'", meanonly
    local inc = r(mean)
    quietly summarize census_year if city=="`c'", meanonly
    local yr = r(mean)
    numadd, key(citycensus_income_`cl') value(`inc') formatted("\$`=string(`inc',"%9.0fc")'") ///
        unit("self-selected survey AVERAGE (not median), music-related annual income") ///
        source("01_evidence/05_music_census_pay_surveys/national_and_benchmark_surveys.md") ///
        note("`c' Sound Music Cities-style music census, `yr'. Self-selected online survey average music-related income, NOT a median and not comparable to this report's ACS PUMS median-earnings figures for Austin/Texas musicians used elsewhere. Verified against national_and_benchmark_surveys.md SS6c before use.")
}

numadd, key(citycensus_austin_no_data) value(1) formatted("no data since 2013") ///
    unit("data gap, methodological finding") ///
    source("01_evidence/05_music_census_pay_surveys/austin_music_census_2014_vs_2022_extracted_numbers.md") ///
    note("Austin’s own 2022 Greater Austin Music Census removed the income-quantification questions the 2014 census had used, on the stated advice of its community engagement partners (the census Summary Report says these questions turned off many respondents). No Austin figure comparable to the other 15 cities’ 2023-2026 self-reported averages exists; the last Austin dollar figure is the 2014 census, measuring calendar-2013 income, reported as a distribution (68.4% earned under \$10,000 from music) rather than an average or median. Shown in fig21 as an explicit gap, not a bar.")

sort income_usd
tempfile fig21_data
save `fig21_data'

local fig21_title = "Austin dropped the income question every peer city still asks"
local _tlen = length("`fig21_title'")
display as text "fig21 title length check: `_tlen' characters (target under ~70)."

local sub1 = "Self-selected survey averages, not medians; not comparable to this report’s ACS figures."
local sub2 = "Each city ran its own census in a different year; sample sizes and methods differ."
local _s1len = length("`sub1'")
local _s2len = length("`sub2'")
display as text "fig21 subtitle length check: line1=`_s1len', line2=`_s2len' (target under ~95 each)."

* over(city, sort(income_usd) descending) looks right but a STRING over()
* variable silently falls back to alphabetical order regardless of sort()
* (confirmed on fig16/fig17a/fig18 -- see the notes there); build an explicit
* value-labeled numeric ordering variable instead. Austin's income_usd is
* missing, and gsort places its row last here (confirmed by rendering: it
* lands at the bottom of the descending list, below Anchorage) -- still a
* clean, unambiguous position for an explicit gap, just not the top as a
* naive "missing sorts as +infinity" expectation would suggest.
gsort -income_usd
generate byte ordc = _n
label define ordclbl 1 "placeholder", replace
quietly forvalues i = 1/16 {
    local thislbl = city[`i']
    label define ordclbl `i' "`thislbl'", modify
}
label values ordc ordclbl

* Comparison cities in navy, not orange -- orange marks Austin/the report's
* own subject throughout this project, and Austin has no bar here at all
* (an explicit gap), so coloring the 15 comparison bars orange would invert
* that convention rather than follow it.
graph hbar income_usd, over(ordc) ///
    bar(1, color("${NAVY}")) ///
    blabel(bar, format(%9.0fc) size(2.6)) ///
    title("`fig21_title'", $TITLEOPT) ///
    subtitle("`sub1'" "`sub2'", $SUBOPT) ///
    ytitle("Self-reported average annual music income (US$)", $YTOPT) ///
    ylabel(0(10000)50000, angle(horizontal) labsize(2.6)) ///
    yscale(range(0 65000)) ///
    legend(off) ///
    graphregion(color(white)) ///
    name(g_fig21, replace)

figsave, name(fig21_city_census_income)

preserve
    export delimited city income_usd n_resp census_year using "${OUT}/fig21_city_census_income.csv", replace
restore

display as text "fig21 complete."


* ================================================================
* Done.
* ================================================================
display as text _newline "{hline 72}"
display as text "50_state_national.do complete"
display as text "{hline 72}"
