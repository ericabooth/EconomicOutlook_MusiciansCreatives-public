*! 10_pums_earnings.do - what ACS microdata say about what music work pays in
*! Texas and in the Austin metro, against other creative occupations and against
*! the state's whole 18-64 workforce.
*!
*! Inputs  : 01_evidence/02_pums_nes_microdata/pums_musicians_creatives_TX_2020_2024_5yr.csv
*!           01_evidence/02_pums_nes_microdata/pums_baseline_TX_workers18to64_2020_2024_5yr.csv
*!           01_evidence/02_pums_nes_microdata/pums_housing_costburden_TX_2020_2024_5yr.csv
*!           03_analysis/data/external/pums_person_repweights_TX_2020_2024_5yr.csv.gz
*!           03_analysis/data/external/pums_housing_repweights_TX_2020_2024_5yr.csv.gz
*!           03_analysis/data/external/puma20_to_tx_metro_crosswalk_2023cbsa.csv
*!           03_analysis/out/cpi_annual.dta
*! Outputs : 04_figures/fig02_earnings_gap.png
*!           04_figures/fig03_selfemp_share.png
*!           04_figures/fig04_earnings_distribution.png
*!           04_figures/fig05_housing_burden.png
*!           03_analysis/out/fig0[2-5]_*.csv        (the plotted numbers)
*!           03_analysis/out/tables/table_earnings_regression.csv
*!           03_analysis/out/numbers/numbers_pums.csv
*!
*! ------------------------------------------------------------------------
*! ANALYSIS POPULATION - read this before quoting any number from this module
*! ------------------------------------------------------------------------
*! An earlier evidence pass circulated "median personal earnings for Texas
*! musicians = $12,800" against an all-worker baseline of $43,700. Those two
*! numbers came from different populations. The musician figure pooled all 885
*! Texas records with OCCP 2752 regardless of age or employment status - 385 of
*! them (43%) were unemployed or out of the labor force, and an out-of-work
*! musician's earnings are near zero by construction. The baseline counted only
*! employed 18-64 workers. Matching the two bases moves the musician median to
*! $21,000 nominal / $25,100 in 2025 dollars. This module never mixes bases.
*!
*! Two populations are used, both applied identically to musicians, to every
*! comparison occupation, and to the all-worker baseline, and both named in the
*! registry note of every number:
*!
*!   EMP ("employed base")  Texas residents ages 18-64 with ESR in {1,2,4,5}
*!                          (employed, civilian or armed forces). 555,102
*!                          unweighted records, 13,595,139 weighted. Used for
*!                          self-employment, hours, weeks, insurance, total
*!                          personal income, and the earnings-threshold shares
*!                          (which must keep zero earners in the denominator or
*!                          they understate hardship).
*!   POS ("positive-earnings base")  EMP and PERNP > 0. 554,672 unweighted.
*!                          Used for the headline earnings comparison, because
*!                          a median of log-able earnings is the quantity the
*!                          regression models and the quantity a reader means
*!                          by "what the work pays".
*!
*! For musicians the two bases barely differ (498 of 500 records have positive
*! earnings), so the choice is not what moved the number - the age and
*! employment restriction is. Both are registered so a reader can see that.
*!
*! Every median and every share is registered with its unweighted record count
*! and its weighted denominator.

clear all
do "_setup.do"                    // run from 03_analysis/stata/
global CURMODULE "pums"
numinit

local SRCP "01_evidence/02_pums_nes_microdata/pums_baseline_TX_workers18to64_2020_2024_5yr.csv + pums_person_repweights_TX_2020_2024_5yr.csv.gz"
local SRCH "01_evidence/02_pums_nes_microdata/pums_housing_costburden_TX_2020_2024_5yr.csv + pums_housing_repweights_TX_2020_2024_5yr.csv.gz"

requirefile "${EV_PUMS}/pums_baseline_TX_workers18to64_2020_2024_5yr.csv"
requirefile "${EV_PUMS}/pums_musicians_creatives_TX_2020_2024_5yr.csv"
requirefile "${EV_PUMS}/pums_housing_costburden_TX_2020_2024_5yr.csv"
requirefile "${DATAX}/pums_person_repweights_TX_2020_2024_5yr.csv.gz"
requirefile "${DATAX}/pums_housing_repweights_TX_2020_2024_5yr.csv.gz"
requirefile "${DATAX}/puma20_to_tx_metro_crosswalk_2023cbsa.csv"
requirefile "${OUT}/cpi_annual.dta"


* ============================================================== 0. HELPERS ==

capture program drop sdrmed
program define sdrmed, rclass
    * Weighted median (or any percentile) with a successive-difference
    * replication standard error.
    *
    * Stata has no svy-aware quantile estimator, so the replicate loop is done
    * by hand exactly as the Census Bureau's PUMS documentation specifies:
    * recompute the statistic under each of the 80 replicate weights and take
    *     Var = (4/80) * sum_r (theta_r - theta_full)^2 .
    * Centring on the full-sample estimate rather than on the mean of the
    * replicates is the "mse" convention, matching the mse option on svyset so
    * medians and means in this module carry comparable uncertainty.
    *
    * About 800 of the 44.5 million replicate-weight cells in the person file
    * are slightly negative (Census allows this; it is an artefact of the
    * successive-difference construction). A weighted median is undefined when
    * weights can be negative, so the weight is floored at zero inside the
    * percentile call only. Means, shares and regressions below use the raw
    * replicate weights through svy, which handles negatives correctly.
    syntax varname(numeric), Sample(varname numeric) [WSTUB(name) P(real 50)]
    if "`wstub'" == "" local wstub PWGTP
    local x `varlist'

    quietly count if `sample' == 1 & !missing(`x')
    return scalar n = r(N)
    if r(N) == 0 {
        return scalar b = .
        return scalar se = .
        return scalar moe = .
        return scalar wtd = .
        exit
    }
    quietly total `wstub' if `sample' == 1 & !missing(`x')
    tempname W
    matrix `W' = e(b)
    return scalar wtd = `W'[1,1]

    quietly _pctile `x' [pw=`wstub'] if `sample' == 1, p(`p')
    local th = r(r1)
    local ss = 0
    local nbad = 0
    forvalues r = 1/80 {
        capture quietly _pctile `x' [pw=max(`wstub'`r',0)] if `sample' == 1, p(`p')
        if _rc == 0 {
            local ss = `ss' + (r(r1) - `th')^2
        }
        else {
            local nbad = `nbad' + 1
        }
    }
    return scalar b   = `th'
    return scalar se  = sqrt((4/80)*`ss')
    return scalar moe = 1.645*sqrt((4/80)*`ss')
    return scalar nbad = `nbad'
end

capture program drop pullest
program define pullest, rclass
    * Lift one estimate and its SDR standard error out of the last svy result.
    syntax , VARiable(string)
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local i = colnumb(`b', "`variable'")
    return scalar b   = `b'[1,`i']
    return scalar se  = sqrt(`V'[`i',`i'])
    return scalar moe = 1.645*sqrt(`V'[`i',`i'])
end

capture program drop numusd
program define numusd
    * Register a 2025-dollar figure, and its 90 percent margin of error when one
    * is supplied. char(36) is a dollar sign; writing it literally would let
    * Stata try to expand it as a global macro.
    syntax , KEY(string) VALUE(real) [MOE(real -1) SOURCE(string) NOTE(string)]
    local shown = round(`value', 100)
    local f = char(36) + strtrim(string(`shown', "%15.0fc"))
    numadd, key(`key') value(`=string(`value',"%18.0g")') formatted("`f'") ///
            unit("2025 dollars") source("`source'") note("`note'")
    if `moe' >= 0 {
        local mf = "+/- " + char(36) + strtrim(string(round(`moe',100), "%15.0fc"))
        numadd, key(`key'_moe) value(`=string(`moe',"%18.0g")') formatted("`mf'") ///
                unit("2025 dollars, 90 percent margin of error") source("`source'") ///
                note("90 percent MOE = 1.645 x SDR standard error from the 80 PUMS replicate weights. `note'")
    }
end

capture program drop numpct
program define numpct
    * Register a share. Value arrives as a proportion and is stored as a percent.
    syntax , KEY(string) VALUE(real) [MOE(real -1) SOURCE(string) NOTE(string)]
    local p = 100*`value'
    numadd, key(`key') value(`=string(`p',"%18.0g")') ///
            formatted("`=strtrim(string(`p',"%9.1f"))'%") unit("percent") ///
            source("`source'") note("`note'")
    if `moe' >= 0 {
        local m = 100*`moe'
        numadd, key(`key'_moe) value(`=string(`m',"%18.0g")') ///
                formatted("+/- `=strtrim(string(`m',"%9.1f"))' points") ///
                unit("percentage points, 90 percent margin of error") source("`source'") ///
                note("90 percent MOE = 1.645 x SDR standard error from the 80 PUMS replicate weights. `note'")
    }
end

capture program drop numcnt
program define numcnt
    syntax , KEY(string) VALUE(real) [UNIT(string) SOURCE(string) NOTE(string)]
    if "`unit'" == "" local unit "count"
    numadd, key(`key') value(`=string(`value',"%18.0g")') ///
            formatted("`=strtrim(string(round(`value'),"%15.0fc"))'") unit("`unit'") ///
            source("`source'") note("`note'")
end


* ========================================================== 1. DEFLATOR ==
* ADJINC and ADJHSG put all five survey years on a common 2024 basis. The CPI-U
* factor for 2024 then carries 2024 dollars to the report's 2025 base. Applying
* a survey-year deflator instead would double-count the within-window inflation
* that ADJINC has already removed, which is why there is no merge on year here.
preserve
    use "${OUT}/cpi_annual.dta", clear
    quietly summarize defl if year == 2024, meanonly
    global DEFL2024 = r(mean)
    quietly summarize defl if year == 2013, meanonly
    global DEFL2013 = r(mean)
    quietly summarize cpi_imputed if year == ${BASEYEAR}, meanonly
    global BASEIMPUTED = r(mean)
restore
display as text "  2024 -> 2025 factor: ${DEFL2024}"
display as text "  2013 -> 2025 factor: ${DEFL2013}"

* The 2013 Austin Music Census asked musicians whether they earned under
* $10,000 a year. That threshold is worth this much in 2025 dollars, and it is
* the only fair way to compare the two surveys.
local mc2025 = 10000 * ${DEFL2013}
numusd, key(pums_musiccensus_tenk_2025usd) value(`mc2025') ///
    source("03_analysis/out/cpi_annual.dta") ///
    note("The 2013 Austin Music Census used a 10,000 dollar annual-earnings threshold. Converted with the CPI-U all-items annual average, factor `=string(${DEFL2013},"%6.4f")'. The 2025 annual average uses an imputed October 2025 value because the federal funding lapse suspended CPI collection that month.")
numadd, key(pums_defl_2013_to_2025) value(`=string(${DEFL2013},"%18.0g")') ///
    formatted("`=strtrim(string(${DEFL2013},"%6.4f"))'") unit("multiplier") ///
    source("03_analysis/out/cpi_annual.dta") ///
    note("CPI-U all items, U.S. city average, annual average 2025 divided by annual average 2013.")
numadd, key(pums_defl_2024_to_2025) value(`=string(${DEFL2024},"%18.0g")') ///
    formatted("`=strtrim(string(${DEFL2024},"%6.4f"))'") unit("multiplier") ///
    source("03_analysis/out/cpi_annual.dta") ///
    note("Applied after ADJINC or ADJHSG, which already restate all five PUMS years in 2024 dollars.")


* ==================================================== 2. BUILD THE PERSONS ==
* Stata cannot read a gzipped CSV. The decompressed person replicate-weight file
* is about 430 MB, which has no business sitting in a Drive-synced project
* folder, so it is expanded into Stata's own temporary directory. c(tmpdir)
* resolves on any machine, so this still runs after the project is zipped and
* moved. gunzip is present on macOS and Linux; on Windows, decompress the two
* .gz files by hand first and point the two locals below at the results.
local tmpp "`c(tmpdir)'pums_person_repweights_tx.csv"
local tmph "`c(tmpdir)'pums_housing_repweights_tx.csv"
shell gunzip -c "${DATAX}/pums_person_repweights_TX_2020_2024_5yr.csv.gz" > "`tmpp'"
shell gunzip -c "${DATAX}/pums_housing_repweights_TX_2020_2024_5yr.csv.gz" > "`tmph'"
requirefile "`tmpp'"
requirefile "`tmph'"

* PUMA-to-metro crosswalk. assigned==0 marks PUMAs that straddle a metro
* boundary without enough of their tracts inside it to be called part of that
* metro; those fall into "Other Texas" with everything else outside the four.
import delimited "${DATAX}/puma20_to_tx_metro_crosswalk_2023cbsa.csv", ///
    varnames(1) case(preserve) clear
keep if assigned == 1
keep puma20_5ce metro_short
rename puma20_5ce PUMA
isid PUMA
tempfile cw
save `cw'

import delimited "`tmpp'", varnames(1) case(preserve) clear
rename PWGTP PWGTP_check
tempfile prep
save `prep'

import delimited "${EV_PUMS}/pums_baseline_TX_workers18to64_2020_2024_5yr.csv", ///
    varnames(1) case(preserve) clear
isid SERIALNO SPORDER
local n_base = _N

merge 1:1 SERIALNO SPORDER using `prep', keep(master match) nogenerate
quietly count if PWGTP != PWGTP_check
if r(N) > 0 {
    display as error "Replicate-weight file disagrees with the extract on PWGTP for `r(N)' records."
    exit 459
}
drop PWGTP_check

merge m:1 PUMA using `cw', keep(master match) nogenerate
replace metro_short = "Other Texas" if missing(metro_short)
encode metro_short, generate(metro)

* Real dollars. ADJINC carries six implied decimals.
foreach v in PERNP PINCP WAGP SEMP {
    generate double `v'_2025usd = `v' * (ADJINC/1000000) * ${DEFL2024}
}
label variable PERNP_2025usd "Personal earnings from work, 2025 dollars"
label variable PINCP_2025usd "Total personal income, 2025 dollars"

* Occupation groups. 2905 is not "sound engineers": PUMS collapses audio and
* video technicians, broadcast technicians, sound engineering technicians and
* lighting technicians into one code, and even SOCP cannot separate them.
generate byte g_mus      = (OCCP == 2752)
generate byte g_musdir   = (OCCP == 2751)
generate byte g_music    = inlist(OCCP, 2751, 2752)
generate byte g_creative = inlist(OCCP, 2634, 2700, 2710, 2740, 2751) | ///
                           inlist(OCCP, 2752, 2850, 2905, 2910)
generate byte g_allwork  = 1

generate byte geo_tx     = 1
generate byte geo_austin = (metro_short == "Austin")

* The two analysis bases described in the header.
generate byte base_emp = 1
generate byte base_pos = (PERNP > 0) & !missing(PERNP)

generate byte selfemp = inlist(COW, 6, 7)
label variable selfemp "Self-employed, incorporated or not (COW 6 or 7)"
generate byte hicov_any  = (HICOV == 1)
generate byte hicov_priv = (PRIVCOV == 1)
generate byte hicov_pub  = (PUBCOV == 1)
generate byte earn_lt10k = (PERNP_2025usd <  10000)
generate byte earn_lt25k = (PERNP_2025usd <  25000)
generate byte earn_lt50k = (PERNP_2025usd <  50000)
generate byte earn_ltmc  = (PERNP_2025usd < `mc2025')
generate byte earn_nonpos = (PERNP_2025usd <= 0)
label variable earn_ltmc "Earnings below the 2013 Music Census 10,000 dollar line, in 2025 dollars"

* Regression covariates.
generate double agesq = AGEP^2
generate byte female = (SEX == 2)
generate byte schlbin = 1
replace schlbin = 2 if inlist(SCHL, 16, 17)
replace schlbin = 3 if inrange(SCHL, 18, 20)
replace schlbin = 4 if SCHL == 21
replace schlbin = 5 if inrange(SCHL, 22, 24)
label define schlbin 1 "Less than high school" 2 "High school or GED" ///
                     3 "Some college or associate" 4 "Bachelor's" ///
                     5 "Graduate or professional"
label values schlbin schlbin
generate double ln_pernp = ln(PERNP_2025usd) if PERNP_2025usd > 0

svyset [pw=PWGTP], sdrweight(PWGTP1-PWGTP80) vce(sdr) mse

tempfile persons
save `persons'

* Provenance the report should be able to state.
numcnt, key(pums_base_records) value(`n_base') unit("unweighted person records") ///
    source("`SRCP'") ///
    note("ACS 2020-2024 5-year PUMS, Texas. Employed base: ages 18-64, ESR in 1/2/4/5.")
quietly total PWGTP
matrix TT = e(b)
numcnt, key(pums_base_weighted) value(`=TT[1,1]') unit("people") ///
    source("`SRCP'") ///
    note("PWGTP-weighted count of the employed base, ACS 2020-2024 5-year PUMS, Texas.")
quietly count if base_pos == 1
numcnt, key(pums_pos_records) value(`=r(N)') unit("unweighted person records") ///
    source("`SRCP'") ///
    note("Positive-earnings base: employed base with PERNP > 0. PERNP can be zero or negative because it nets self-employment losses.")
quietly count if PERNP <= 0
numcnt, key(pums_nonpos_earn_records) value(`=r(N)') unit("unweighted person records") ///
    source("`SRCP'") ///
    note("Employed Texans 18-64 reporting zero or negative earnings from work; PERNP nets business losses, so it can go below zero.")


* ========================= 3. GROUP BY GEOGRAPHY ESTIMATES (registry only) ==

capture program drop pumscell
program define pumscell
    * Every headline statistic for one occupation group in one geography, on
    * both analysis bases, written straight into the module ledger.
    syntax , GEO(string) GRP(string) GEOLAB(string) GRPLAB(string) SRC(string)

    tempvar s_emp s_pos
    quietly generate byte `s_emp' = (geo_`geo' == 1) & (g_`grp' == 1) & (base_emp == 1)
    quietly generate byte `s_pos' = (geo_`geo' == 1) & (g_`grp' == 1) & (base_pos == 1)

    quietly count if `s_emp' == 1
    local n_emp = r(N)
    quietly count if `s_pos' == 1
    local n_pos = r(N)

    * Suppression rule from CONVENTIONS section 6: nothing rests on fewer than
    * 50 unweighted records.
    if `n_emp' < 50 {
        numadd, key(pums_`geo'_`grp'_suppressed) value(`n_emp') ///
            formatted("suppressed") unit("unweighted records") source("`src'") ///
            note("`grplab', `geolab': only `n_emp' unweighted ACS records, below the 50-record floor this project uses, so no estimate is published for this cell.")
        display as text "  [suppressed] `geo' x `grp' : n = `n_emp'"
        exit
    }

    local base_emp_note "Base EMP = `grplab', `geolab', ages 18-64, employed (ESR 1/2/4/5), ACS 2020-2024 5-year PUMS, PWGTP-weighted; `n_emp' unweighted records."
    local base_pos_note "Base POS = `grplab', `geolab', ages 18-64, employed (ESR 1/2/4/5) with positive earnings, ACS 2020-2024 5-year PUMS, PWGTP-weighted; `n_pos' unweighted records."
    local adj "Dollars adjusted with ADJINC to 2024 then by the CPI-U 2024 factor to 2025 dollars."

    numcnt, key(pums_`geo'_`grp'_n_emp) value(`n_emp') unit("unweighted person records") ///
        source("`src'") note("`base_emp_note'")
    numcnt, key(pums_`geo'_`grp'_n_pos) value(`n_pos') unit("unweighted person records") ///
        source("`src'") note("`base_pos_note'")

    * ---- means and shares on the employed base -----------------------------
    quietly svy, subpop(`s_emp'): mean PINCP_2025usd PERNP_2025usd selfemp ///
        hicov_any hicov_priv hicov_pub earn_lt10k earn_lt25k earn_lt50k ///
        earn_ltmc earn_nonpos
    numcnt, key(pums_`geo'_`grp'_wtd_emp) value(`=e(N_subpop)') unit("people") ///
        source("`src'") note("Weighted denominator for every EMP-base figure in this cell. `base_emp_note'")

    pullest, variable(PINCP_2025usd)
    numusd, key(pums_`geo'_`grp'_meanpincp_emp) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Mean total personal income. `base_emp_note' `adj'")
    pullest, variable(PERNP_2025usd)
    numusd, key(pums_`geo'_`grp'_meanpernp_emp) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Mean personal earnings from work, zero and negative earners included. `base_emp_note' `adj'")
    pullest, variable(selfemp)
    numpct, key(pums_`geo'_`grp'_selfemp) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share self-employed, COW 6 (unincorporated) or 7 (incorporated). `base_emp_note'")
    pullest, variable(hicov_any)
    numpct, key(pums_`geo'_`grp'_hicov) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share with any health insurance (HICOV = 1). `base_emp_note'")
    pullest, variable(hicov_priv)
    numpct, key(pums_`geo'_`grp'_privcov) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share with private coverage (PRIVCOV = 1). Private and public overlap, so the two shares do not sum to the any-coverage share. `base_emp_note'")
    pullest, variable(hicov_pub)
    numpct, key(pums_`geo'_`grp'_pubcov) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share with public coverage (PUBCOV = 1). Private and public overlap. `base_emp_note'")
    pullest, variable(earn_lt10k)
    numpct, key(pums_`geo'_`grp'_lt10k) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share earning under 10,000 dollars from work in 2025 dollars. `base_emp_note' `adj'")
    pullest, variable(earn_lt25k)
    numpct, key(pums_`geo'_`grp'_lt25k) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share earning under 25,000 dollars from work in 2025 dollars. `base_emp_note' `adj'")
    pullest, variable(earn_lt50k)
    numpct, key(pums_`geo'_`grp'_lt50k) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share earning under 50,000 dollars from work in 2025 dollars. `base_emp_note' `adj'")
    pullest, variable(earn_ltmc)
    numpct, key(pums_`geo'_`grp'_ltmusiccensus) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share earning less than the 2013 Austin Music Census 10,000 dollar line restated in 2025 dollars. `base_emp_note' `adj'")
    pullest, variable(earn_nonpos)
    numpct, key(pums_`geo'_`grp'_nonposearn) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Share of employed people reporting zero or negative earnings from work. `base_emp_note'")

    * ---- means on the positive-earnings base -------------------------------
    quietly svy, subpop(`s_pos'): mean PERNP_2025usd PINCP_2025usd
    numcnt, key(pums_`geo'_`grp'_wtd_pos) value(`=e(N_subpop)') unit("people") ///
        source("`src'") note("Weighted denominator for every POS-base figure in this cell. `base_pos_note'")
    pullest, variable(PERNP_2025usd)
    numusd, key(pums_`geo'_`grp'_meanpernp_pos) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Mean personal earnings from work. `base_pos_note' `adj'")
    pullest, variable(PINCP_2025usd)
    numusd, key(pums_`geo'_`grp'_meanpincp_pos) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Mean total personal income. `base_pos_note' `adj'")

    * ---- medians -----------------------------------------------------------
    sdrmed PINCP_2025usd, sample(`s_emp')
    numusd, key(pums_`geo'_`grp'_medpincp_emp) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Median total personal income. `base_emp_note' `adj'")
    sdrmed PERNP_2025usd, sample(`s_emp')
    numusd, key(pums_`geo'_`grp'_medpernp_emp) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Median personal earnings from work, zero and negative earners included. `base_emp_note' `adj'")
    sdrmed PERNP_2025usd, sample(`s_pos')
    numusd, key(pums_`geo'_`grp'_medpernp_pos) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("HEADLINE earnings figure. Median personal earnings from work. `base_pos_note' `adj'")
    sdrmed PINCP_2025usd, sample(`s_pos')
    numusd, key(pums_`geo'_`grp'_medpincp_pos) value(`=r(b)') moe(`=r(moe)') ///
        source("`src'") note("Median total personal income on the same base as the headline earnings figure, so the earnings-to-income gap is not a base artefact. `base_pos_note' `adj'")
    sdrmed WKHP, sample(`s_emp')
    numadd, key(pums_`geo'_`grp'_medwkhp) value(`=string(r(b),"%18.0g")') ///
        formatted("`=strtrim(string(r(b),"%9.0f"))'") unit("usual hours per week") ///
        source("`src'") note("Median usual hours worked per week (WKHP). `base_emp_note'")
    sdrmed WKWN, sample(`s_emp')
    numadd, key(pums_`geo'_`grp'_medwkwn) value(`=string(r(b),"%18.0g")') ///
        formatted("`=strtrim(string(r(b),"%9.0f"))'") unit("weeks worked in past 12 months") ///
        source("`src'") note("Median weeks worked in the past 12 months (WKWN). `base_emp_note'")

    display as text "  [done] `geo' x `grp' : n_emp = `n_emp', n_pos = `n_pos'"
end

use `persons', clear
foreach geo in tx austin {
    if "`geo'" == "tx"     local geolab "Texas"
    if "`geo'" == "austin" local geolab "Austin-Round Rock-San Marcos metro"
    foreach grp in mus musdir music creative allwork {
        if "`grp'" == "mus"      local grplab "Musicians and singers (OCCP 2752)"
        if "`grp'" == "musdir"   local grplab "Music directors and composers (OCCP 2751)"
        if "`grp'" == "music"    local grplab "Musicians, singers, music directors and composers (OCCP 2751 and 2752)"
        if "`grp'" == "creative" local grplab "Nine creative occupations pooled (OCCP 2634, 2700, 2710, 2740, 2751, 2752, 2850, 2905, 2910)"
        if "`grp'" == "allwork"  local grplab "All workers"
        pumscell, geo(`geo') grp(`grp') geolab("`geolab'") grplab("`grplab'") src("`SRCP'")
    }
}

* Austin's share of the state's musicians, the claim the report leans on when it
* says Austin is over-represented. Both the ratio and its two parts are
* registered so the arithmetic is checkable.
quietly total PWGTP if g_mus == 1
matrix A = e(b)
quietly total PWGTP if g_mus == 1 & geo_austin == 1
matrix B = e(b)
numpct, key(pums_austin_share_of_tx_musicians) value(`=B[1,1]/A[1,1]') ///
    source("`SRCP'") ///
    note("Austin metro share of Texas musicians and singers (OCCP 2752), employed base, PWGTP-weighted. Ratio of two same-vintage weighted counts, so no deflation applies.")
quietly total PWGTP
matrix A = e(b)
quietly total PWGTP if geo_austin == 1
matrix B = e(b)
numpct, key(pums_austin_share_of_tx_workers) value(`=B[1,1]/A[1,1]') ///
    source("`SRCP'") ///
    note("Austin metro share of all employed Texans 18-64, PWGTP-weighted. Ratio of two same-vintage weighted counts, so no deflation applies.")

* How much of the old $12,800 figure was the base and how much was inflation.
* Registering the reconciliation means the correction is documented, not buried.
quietly _pctile PERNP [pw=PWGTP] if g_mus == 1 & base_emp == 1, p(50)
numadd, key(pums_tx_mus_medpernp_nominal) value(`=string(r(r1),"%18.0g")') ///
    formatted("`=char(36)'`=strtrim(string(round(r(r1),100),"%15.0fc"))'") ///
    unit("nominal dollars of the survey year") source("`SRCP'") ///
    note("Median personal earnings for musicians and singers on the matched employed base, WITHOUT ADJINC or the CPI factor. Reported only to reconcile with the earlier evidence pass; never quote a nominal PUMS figure in the report.")
quietly _pctile PINCP [pw=PWGTP] if g_mus == 1 & base_emp == 1, p(50)
numadd, key(pums_tx_mus_medpincp_nominal) value(`=string(r(r1),"%18.0g")') ///
    formatted("`=char(36)'`=strtrim(string(round(r(r1),100),"%15.0fc"))'") ///
    unit("nominal dollars of the survey year") source("`SRCP'") ///
    note("Median total personal income for musicians and singers on the matched employed base, unadjusted. Reconciliation only.")
quietly _pctile PERNP [pw=PWGTP] if base_emp == 1, p(50)
numadd, key(pums_tx_allwork_medpernp_nominal) value(`=string(r(r1),"%18.0g")') ///
    formatted("`=char(36)'`=strtrim(string(round(r(r1),100),"%15.0fc"))'") ///
    unit("nominal dollars of the survey year") source("`SRCP'") ///
    note("Median personal earnings for all employed Texans 18-64, unadjusted. Reconciliation only; the report quotes the 2025-dollar version.")
quietly _pctile PINCP [pw=PWGTP] if base_emp == 1, p(50)
numadd, key(pums_tx_allwork_medpincp_nominal) value(`=string(r(r1),"%18.0g")') ///
    formatted("`=char(36)'`=strtrim(string(round(r(r1),100),"%15.0fc"))'") ///
    unit("nominal dollars of the survey year") source("`SRCP'") ///
    note("Median total personal income for all employed Texans 18-64, unadjusted. Reconciliation only.")

* The superseded figures, registered so the report can explain the correction
* instead of quietly publishing a different number than the evidence memo.
preserve
    import delimited "${EV_PUMS}/pums_musicians_creatives_TX_2020_2024_5yr.csv", ///
        varnames(1) case(preserve) clear
    quietly count if OCCP == 2752
    local n_allages = r(N)
    quietly count if OCCP == 2752 & !inlist(ESR, 1, 2, 4, 5)
    local n_notworking = r(N)
    quietly _pctile PERNP [pw=PWGTP] if OCCP == 2752, p(50)
    local old_pernp = r(r1)
    quietly _pctile PINCP [pw=PWGTP] if OCCP == 2752, p(50)
    local old_pincp = r(r1)
restore
numcnt, key(pums_tx_mus_allages_n) value(`n_allages') unit("unweighted person records") ///
    source("01_evidence/02_pums_nes_microdata/pums_musicians_creatives_TX_2020_2024_5yr.csv") ///
    note("All Texas records with OCCP 2752, any age, any employment status. `n_notworking' of them were unemployed or out of the labour force, which is why this population cannot be compared with an employed-only baseline.")
numadd, key(pums_tx_mus_allages_medpernp_nominal) value(`=string(`old_pernp',"%18.0g")') ///
    formatted("`=char(36)'`=strtrim(string(round(`old_pernp',100),"%15.0fc"))'") ///
    unit("nominal dollars of the survey year") ///
    source("01_evidence/02_pums_nes_microdata/pums_musicians_creatives_TX_2020_2024_5yr.csv") ///
    note("SUPERSEDED. The unrestricted all-ages, any-employment-status median that the 2026-08-01 evidence memo compared against an employed-only baseline. Registered only so the correction can be described; do not quote it as a musician earnings figure.")
numadd, key(pums_tx_mus_allages_medpincp_nominal) value(`=string(`old_pincp',"%18.0g")') ///
    formatted("`=char(36)'`=strtrim(string(round(`old_pincp',100),"%15.0fc"))'") ///
    unit("nominal dollars of the survey year") ///
    source("01_evidence/02_pums_nes_microdata/pums_musicians_creatives_TX_2020_2024_5yr.csv") ///
    note("SUPERSEDED companion to the earnings figure above, same unrestricted population. Do not quote.")


* ================================================= 4. THE OCCUPATION PANEL ==
* One row per creative occupation plus the all-worker baseline, feeding figures
* 02 and 03. Everything here is on the two bases defined at the top.

tempfile occpanel
tempname pf
postfile `pf' int occ str44 lab int(nunw_pos nunw_emp) ///
    double(wtd_emp medpernp mp_moe medpincp mi_moe selfemp se_moe) ///
    using `occpanel', replace

foreach o in 2634 2700 2710 2740 2751 2752 2850 2905 2910 9999 {
    if `o' == 2634 local lab "Graphic designers"
    if `o' == 2700 local lab "Actors"
    if `o' == 2710 local lab "Producers and directors"
    if `o' == 2740 local lab "Dancers and choreographers"
    if `o' == 2751 local lab "Music directors and composers"
    if `o' == 2752 local lab "Musicians and singers"
    if `o' == 2850 local lab "Writers and authors"
    if `o' == 2905 local lab "Media, AV and sound equipment workers"
    if `o' == 2910 local lab "Photographers"
    if `o' == 9999 local lab "All Texas workers 18-64"

    capture drop occ_emp occ_pos
    if `o' == 9999 {
        generate byte occ_emp = (base_emp == 1)
        generate byte occ_pos = (base_pos == 1)
    }
    else {
        generate byte occ_emp = (OCCP == `o') & (base_emp == 1)
        generate byte occ_pos = (OCCP == `o') & (base_pos == 1)
    }
    quietly count if occ_emp == 1
    local nemp = r(N)
    quietly count if occ_pos == 1
    local npos = r(N)
    if `nemp' < 50 {
        numadd, key(pums_occ`o'_suppressed) value(`nemp') formatted("suppressed") ///
            unit("unweighted records") source("`SRCP'") ///
            note("`lab' (OCCP `o'), Texas employed base: only `nemp' unweighted records, below the 50-record floor, so the occupation is left out of figures 02 and 03.")
        continue
    }

    sdrmed PERNP_2025usd, sample(occ_pos)
    local mp = r(b)
    local mpm = r(moe)
    sdrmed PINCP_2025usd, sample(occ_pos)
    local mi = r(b)
    local mim = r(moe)
    quietly svy, subpop(occ_emp): mean selfemp
    local wemp = e(N_subpop)
    pullest, variable(selfemp)
    local se = r(b)
    local sem = r(moe)

    post `pf' (`o') ("`lab'") (`npos') (`nemp') (`wemp') (`mp') (`mpm') (`mi') (`mim') (`se') (`sem')

    * Occupation-level numbers the report may quote outside the figures.
    if `o' != 9999 {
        numusd, key(pums_occ`o'_medpernp_pos) value(`mp') moe(`mpm') ///
            source("`SRCP'") ///
            note("`lab' (OCCP `o'), Texas, ages 18-64, employed with positive earnings; `npos' unweighted records. Median personal earnings, ADJINC then CPI-U to 2025 dollars.")
        numpct, key(pums_occ`o'_selfemp) value(`se') moe(`sem') ///
            source("`SRCP'") ///
            note("`lab' (OCCP `o'), Texas, ages 18-64, employed; `nemp' unweighted records, `=strtrim(string(round(`wemp'),"%15.0fc"))' weighted. Share with COW 6 or 7.")
    }
}
postclose `pf'
capture drop occ_emp occ_pos


* =============================================== 5. METRO COMPARISON (T3) ==
* Musicians, singers, music directors and composers pooled, because splitting
* 2751 from 2752 inside a single metro drops most cells under the 50-record
* floor. Suppression is registered rather than printed as a number.

tempfile metropanel
tempname mf
postfile `mf' str20 metro int(nunw_emp nunw_pos) double(wtd_emp medpernp mp_moe selfemp se_moe) ///
    using `metropanel', replace

foreach m in Austin Houston "Dallas-Fort Worth" "San Antonio" {
    if "`m'" == "Austin"            local mk "austin"
    if "`m'" == "Houston"           local mk "houston"
    if "`m'" == "Dallas-Fort Worth" local mk "dfw"
    if "`m'" == "San Antonio"       local mk "sanantonio"

    capture drop met_emp met_pos
    generate byte met_emp = (metro_short == "`m'") & (g_music == 1) & (base_emp == 1)
    generate byte met_pos = (metro_short == "`m'") & (g_music == 1) & (base_pos == 1)
    quietly count if met_emp == 1
    local nemp = r(N)
    quietly count if met_pos == 1
    local npos = r(N)

    if (`nemp' < 50) | (`npos' < 50) {
        numadd, key(pums_metro_`mk'_music_suppressed) value(`nemp') ///
            formatted("suppressed") unit("unweighted records") source("`SRCP'") ///
            note("`m' metro, musicians and music directors (OCCP 2751 and 2752), employed base: `nemp' unweighted records and `npos' with positive earnings. Below the 50-record floor, so no metro estimate is published.")
        display as text "  [suppressed] metro `m' : n_emp = `nemp', n_pos = `npos'"
        continue
    }

    sdrmed PERNP_2025usd, sample(met_pos)
    local mp = r(b)
    local mpm = r(moe)
    quietly svy, subpop(met_emp): mean selfemp
    local wemp = e(N_subpop)
    pullest, variable(selfemp)
    local se = r(b)
    local sem = r(moe)

    post `mf' ("`m'") (`nemp') (`npos') (`wemp') (`mp') (`mpm') (`se') (`sem')

    numcnt, key(pums_metro_`mk'_music_n) value(`nemp') unit("unweighted person records") ///
        source("`SRCP'") note("`m' metro, OCCP 2751 and 2752 pooled, employed base.")
    numcnt, key(pums_metro_`mk'_music_wtd) value(`wemp') unit("people") ///
        source("`SRCP'") note("`m' metro, OCCP 2751 and 2752 pooled, employed base, PWGTP-weighted.")
    numusd, key(pums_metro_`mk'_music_medpernp) value(`mp') moe(`mpm') ///
        source("`SRCP'") ///
        note("`m' metro, OCCP 2751 and 2752 pooled, ages 18-64, employed with positive earnings; `npos' unweighted records. Median personal earnings, ADJINC then CPI-U to 2025 dollars.")
    numpct, key(pums_metro_`mk'_music_selfemp) value(`se') moe(`sem') ///
        source("`SRCP'") ///
        note("`m' metro, OCCP 2751 and 2752 pooled, ages 18-64, employed; `nemp' unweighted records. Share with COW 6 or 7.")
    display as text "  [done] metro `m' : n_emp = `nemp', n_pos = `npos'"
}
postclose `mf'
capture drop met_emp met_pos


* ==================================================== 6. REGRESSION (T4) ==
* A descriptive conditional earnings gap, not a causal estimate.
*
* WHAT THIS DOES ESTABLISH. Among employed Texans 18-64 with positive earnings,
* people whose current job is musician, singer, music director or composer
* report lower annual earnings than otherwise-similar workers, and the gap
* survives controls for age, sex, education, usual hours, weeks worked and
* metro area. So the shortfall is not simply that musicians are younger, less
* credentialled, concentrated in cheaper metros, or working fewer hours and
* weeks; comparing a musician with a non-musician who matches on all of those
* still leaves a gap.
*
* WHAT IT DOES NOT ESTABLISH. It is not the earnings penalty a given person
* would pay for choosing music. People sort into music on traits the ACS never
* records - talent, family wealth that makes low pay survivable, a spouse's
* income, willingness to trade money for the work itself - and any of those can
* produce this gap with no causal effect of the occupation at all. Hours and
* weeks are themselves outcomes of the occupation, so controlling for them
* removes part of the very thing being measured and the controlled coefficient
* understates the total earnings difference. ACS records one current or most
* recent job, so people who play for pay alongside a day job sit in the
* comparison group, which pushes the estimated gap toward zero. And the 620
* music records carry a wide confidence interval.

use `persons', clear
svyset [pw=PWGTP], sdrweight(PWGTP1-PWGTP80) vce(sdr) mse

eststo clear
quietly svy: regress ln_pernp g_music i.metro
eststo r1
quietly svy: regress ln_pernp g_music c.AGEP c.agesq i.female i.schlbin i.metro
eststo r2
quietly svy: regress ln_pernp g_music c.AGEP c.agesq i.female i.schlbin ///
    c.WKHP c.WKWN i.metro
eststo r3

esttab r1 r2 r3, se b(4) stats(N N_pop r2) ///
    mtitles("Metro FE only" "Plus demographics" "Plus hours and weeks")
esttab r1 r2 r3 using "${TABDIR}/table_earnings_regression.csv", replace csv ///
    se b(4) stats(N N_pop r2, labels("Unweighted observations" "Weighted population" "R-squared")) ///
    mtitles("Metro FE only" "Plus demographics" "Plus hours and weeks") ///
    varlabels(g_music "Musician, singer, music director or composer" ///
              AGEP "Age" agesq "Age squared" 1.female "Female" ///
              WKHP "Usual hours per week" WKWN "Weeks worked past 12 months") ///
    title("Conditional earnings gap for music occupations, Texas workers 18-64 with positive earnings, ACS 2020-2024 5-year PUMS, SDR standard errors")
display as text "  table -> 03_analysis/out/tables/table_earnings_regression.csv"

estimates restore r3
matrix b = e(b)
matrix V = e(V)
local i = colnumb(b, "g_music")
local coef = b[1,`i']
local cse  = sqrt(V[`i',`i'])
local pct  = 100*(exp(`coef') - 1)
local pctlo = 100*(exp(`coef' - 1.96*`cse') - 1)
local pcthi = 100*(exp(`coef' + 1.96*`cse') - 1)
display as text "  music coefficient = " %6.4f `coef' " (SE " %6.4f `cse' "), " ///
    %5.1f `pct' "% gap, 95% CI [" %5.1f `pctlo' ", " %5.1f `pcthi' "]"

numadd, key(pums_reg_music_coef) value(`=string(`coef',"%18.0g")') ///
    formatted("`=strtrim(string(`coef',"%6.3f"))'") unit("log points") ///
    source("`SRCP'") ///
    note("Coefficient on a music-occupation indicator (OCCP 2751 or 2752) in a survey-weighted OLS of log personal earnings, Texas workers 18-64 with positive earnings, controlling for age, age squared, sex, five education bins, usual hours, weeks worked and metro fixed effects. SDR standard errors from PWGTP1-PWGTP80. Descriptive conditional gap, not a causal estimate.")
numadd, key(pums_reg_music_se) value(`=string(`cse',"%18.0g")') ///
    formatted("`=strtrim(string(`cse',"%6.3f"))'") unit("log points") ///
    source("`SRCP'") note("SDR standard error of the music coefficient.")
numpct, key(pums_reg_music_pctgap) value(`=`pct'/100') ///
    source("`SRCP'") ///
    note("Music coefficient expressed as a percentage difference, 100*(exp(b)-1). 95 percent CI `=strtrim(string(`pctlo',"%6.1f"))' to `=strtrim(string(`pcthi',"%6.1f"))' percent. Conditional association, not the earnings penalty of choosing music.")
quietly count if !missing(ln_pernp)
numcnt, key(pums_reg_n) value(`=r(N)') unit("unweighted person records") ///
    source("`SRCP'") note("Regression sample: employed Texans 18-64 with positive personal earnings.")


* ============================================== 7. HOUSING COST BURDEN (T2) ==
* Households are labelled by who lives in them. Three labels, kept separate so
* no pooled-group rate is ever presented as a musician rate:
*   hh_mus    at least one employed 18-64 resident whose job is musician or
*             singer (OCCP 2752). This is the one the figure plots.
*   hh_music  the same, widened to include music directors and composers
*             (OCCP 2751), who are a better-paid and more salaried group.
*   hh_worker at least one employed 18-64 resident of any occupation.
* The groups nest on purpose, so the comparison is "musician households against
* all households with a worker in them", not against a mutually exclusive group.

use `persons', clear
keep SERIALNO g_mus g_music base_emp
collapse (max) hh_mus = g_mus (max) hh_music = g_music (max) hh_worker = base_emp, ///
    by(SERIALNO)
tempfile hhflags
save `hhflags'

import delimited "`tmph'", varnames(1) case(preserve) clear
rename WGTP WGTP_check
tempfile hrep
save `hrep'

import delimited "${EV_PUMS}/pums_housing_costburden_TX_2020_2024_5yr.csv", ///
    varnames(1) case(preserve) clear
isid SERIALNO
local n_hh_all = _N

* The housing replicate-weight extract covers exactly the households that hold
* at least one person in the person extract, which is the universe this section
* needs. Texas households with nobody working and aged 18-64 in them are absent,
* so nothing here should be read as a statewide all-household rate.
merge 1:1 SERIALNO using `hrep', keep(match) nogenerate
quietly count if WGTP != WGTP_check
if r(N) > 0 {
    display as error "Housing replicate weights disagree with the extract on WGTP for `r(N)' records."
    exit 459
}
drop WGTP_check
local n_hh_rep = _N

merge 1:1 SERIALNO using `hhflags', keep(master match) nogenerate
foreach v in hh_mus hh_music hh_worker {
    replace `v' = 0 if missing(`v')
}

* Group-quarters records carry a zero household weight and no tenure; they are
* not households and cannot be cost-burdened.
drop if WGTP <= 0

generate byte renter = (TEN == 3) & !missing(GRPIP)
generate byte owner  = inlist(TEN, 1, 2) & !missing(OCPIP)
generate byte rent30 = (GRPIP > 30) if renter == 1
generate byte rent50 = (GRPIP > 50) if renter == 1
generate byte own30  = (OCPIP > 30) if owner == 1
generate byte own50  = (OCPIP > 50) if owner == 1
generate double GRNTP_2025usd = GRNTP * (ADJHSG/1000000) * ${DEFL2024} if renter == 1

svyset [pw=WGTP], sdrweight(WGTP1-WGTP80) vce(sdr) mse

numcnt, key(pums_hh_records_all) value(`n_hh_all') unit("unweighted household records") ///
    source("`SRCH'") note("All Texas household records in the ACS 2020-2024 5-year PUMS housing extract, before restricting to households with replicate weights.")
numcnt, key(pums_hh_records_analysis) value(`n_hh_rep') unit("unweighted household records") ///
    source("`SRCH'") note("Households carrying replicate weights, which are exactly the households holding at least one person in the person extract. Texas households with no employed 18-64 resident are outside this universe, so no figure here is a statewide all-household rate.")

tempfile housepanel
tempname hf
postfile `hf' str44 grp int(n_rent n_own) double(w_rent w_own r30 r30m r50 r50m o30 o30m o50 o50m medrent) ///
    using `housepanel', replace

foreach h in mus music worker {
    if "`h'" == "mus"    local hlab "Musician households"
    if "`h'" == "music"  local hlab "Musician and music-director households"
    if "`h'" == "worker" local hlab "All worker households"
    if "`h'" == "mus"    local hnote "Texas households with at least one employed resident aged 18-64 whose current job is musician or singer (OCCP 2752)"
    if "`h'" == "music"  local hnote "Texas households with at least one employed resident aged 18-64 whose current job is musician, singer, music director or composer (OCCP 2751 or 2752). Wider than the musician-only group and never to be quoted as a musician rate"
    if "`h'" == "worker" local hnote "Texas households with at least one employed resident aged 18-64"

    capture drop hr ho
    generate byte hr = (hh_`h' == 1) & (renter == 1)
    generate byte ho = (hh_`h' == 1) & (owner == 1)
    quietly count if hr == 1
    local nr = r(N)
    quietly count if ho == 1
    local no = r(N)

    numcnt, key(pums_hh_`h'_renters_n) value(`nr') unit("unweighted household records") ///
        source("`SRCH'") note("Denominator for the renter cost-burden shares. `hnote', renting for cash rent with a valid GRPIP.")
    numcnt, key(pums_hh_`h'_owners_n) value(`no') unit("unweighted household records") ///
        source("`SRCH'") note("Denominator for the owner cost-burden shares. `hnote', owning with or without a mortgage and with a valid OCPIP.")

    if (`nr' < 50) | (`no' < 50) {
        numadd, key(pums_hh_`h'_suppressed) value(`nr') formatted("suppressed") ///
            unit("unweighted records") source("`SRCH'") ///
            note("`hlab': `nr' renter and `no' owner records, below the 50-record floor.")
        continue
    }

    quietly svy, subpop(hr): mean rent30 rent50 GRNTP_2025usd
    local wr = e(N_subpop)
    pullest, variable(rent30)
    local r30 = r(b)
    local r30m = r(moe)
    pullest, variable(rent50)
    local r50 = r(b)
    local r50m = r(moe)
    quietly svy, subpop(ho): mean own30 own50
    local wo = e(N_subpop)
    pullest, variable(own30)
    local o30 = r(b)
    local o30m = r(moe)
    pullest, variable(own50)
    local o50 = r(b)
    local o50m = r(moe)
    sdrmed GRNTP_2025usd, sample(hr) wstub(WGTP)
    local mrent = r(b)
    local mrentm = r(moe)

    post `hf' ("`hlab'") (`nr') (`no') (`wr') (`wo') (`r30') (`r30m') (`r50') (`r50m') ///
        (`o30') (`o30m') (`o50') (`o50m') (`mrent')

    numcnt, key(pums_hh_`h'_renters_wtd) value(`wr') unit("households") ///
        source("`SRCH'") note("Weighted renter denominator. `hnote'. WGTP-weighted.")
    numcnt, key(pums_hh_`h'_owners_wtd) value(`wo') unit("households") ///
        source("`SRCH'") note("Weighted owner denominator. `hnote'. WGTP-weighted.")
    numpct, key(pums_hh_`h'_rent30) value(`r30') moe(`r30m') source("`SRCH'") ///
        note("Share of renter households paying more than 30 percent of household income in gross rent (GRPIP > 30). `hnote'; `nr' unweighted records. GRPIP is a ratio of two same-year quantities, so no inflation adjustment applies. GRPIP is top-coded at 101, which covers zero and negative household income.")
    numpct, key(pums_hh_`h'_rent50) value(`r50') moe(`r50m') source("`SRCH'") ///
        note("Share of renter households paying more than 50 percent of household income in gross rent (GRPIP > 50), the severe-burden line. `hnote'; `nr' unweighted records. Ratio of same-year quantities, no deflation.")
    numpct, key(pums_hh_`h'_own30) value(`o30') moe(`o30m') source("`SRCH'") ///
        note("Share of owner households whose selected monthly owner costs exceed 30 percent of household income (OCPIP > 30). `hnote'; `no' unweighted records. Ratio of same-year quantities, no deflation.")
    numpct, key(pums_hh_`h'_own50) value(`o50') moe(`o50m') source("`SRCH'") ///
        note("Share of owner households whose selected monthly owner costs exceed 50 percent of household income (OCPIP > 50). `hnote'; `no' unweighted records. Ratio of same-year quantities, no deflation.")
    numusd, key(pums_hh_`h'_medrent) value(`mrent') moe(`mrentm') source("`SRCH'") ///
        note("Median monthly gross rent, ADJHSG to 2024 then CPI-U to 2025 dollars. `hnote'; `nr' unweighted renter records.")
    display as text "  [done] housing `h' : renters = `nr', owners = `no'"
}
postclose `hf'
capture drop hr ho


* ================================================== 8. FIGURE 02 - EARNINGS ==
* The claim in the title is checked against the plotted values, not asserted:
* the musicians-and-singers bar is 25,100 dollars and the all-worker bar is
* 50,047, so "about half" is what the chart shows. No superlative is used,
* because actors and dancers sit below musicians on this measure and music
* directors sit above the all-worker line.
use `occpanel', clear
gsort medpernp
generate int ord = _n
generate double ye = ord - 0.18
generate double yi = ord + 0.18
generate double mp_lo = medpernp - mp_moe
generate double mp_hi = medpernp + mp_moe
generate double mi_lo = medpincp - mi_moe
generate double mi_hi = medpincp + mi_moe
* Value labels sit beyond the far end of the whisker so the two never overlap.
generate str12 lab_p = strtrim(string(round(medpernp,100), "%12.0fc"))
generate str12 lab_i = strtrim(string(round(medpincp,100), "%12.0fc"))
generate double xlab_p = mp_hi + 2200
generate double xlab_i = mi_hi + 2200

local ylab ""
forvalues i = 1/`=_N' {
    local L = lab[`i']
    local ylab `"`ylab' `i' "`L'""'
}

twoway (bar medpernp ye, horizontal barwidth(0.32) color("${ORANGE}") lwidth(none)) ///
       (rcap mp_lo mp_hi ye, horizontal lcolor("${MUTED}") lwidth(thin) msize(0.8)) ///
       (bar medpincp yi, horizontal barwidth(0.32) color("${NAVY}") lwidth(none)) ///
       (rcap mi_lo mi_hi yi, horizontal lcolor("${MUTED}") lwidth(thin) msize(0.8)) ///
       (scatter ye xlab_p, msymbol(none) mlabel(lab_p) mlabcolor("${ORANGE}") ///
            mlabsize(2.0) mlabposition(3)) ///
       (scatter yi xlab_i, msymbol(none) mlabel(lab_i) mlabcolor("${NAVY}") ///
            mlabsize(2.0) mlabposition(3)) ///
       , title("Musicians and singers earn about half the typical worker's earnings", $TITLEOPT) ///
         subtitle("Median personal earnings and median total personal income, 2025 dollars;" "Texas workers 18-64 with positive earnings, ACS 2020-2024 5-year PUMS", $SUBOPT) ///
         ylabel(`ylab', angle(0) labsize(2.6) notick nogrid) ytitle("") ///
         yscale(range(0.4 `=_N+0.6')) ///
         xlabel(0(20000)80000, format(%12.0fc) labsize(2.8)) ///
         xscale(range(0 96000)) ///
         xtitle("2025 dollars", size(2.8)) ///
         legend(order(1 "Earnings from work" 3 "Total personal income") ///
                rows(1) position(6) $LEGOPT) ///
         graphregion(color(white)) plotregion(margin(l=0)) ///
         ysize(5.0) xsize(8)
figsave, name(fig02_earnings_gap)
export delimited occ lab nunw_pos nunw_emp wtd_emp medpernp mp_moe medpincp mi_moe ///
    using "${OUT}/fig02_earnings_gap.csv", replace


* ================================================== 9. FIGURE 03 - SELF-EMP ==
use `occpanel', clear
gsort selfemp
generate int ord = _n
generate double s_lo = 100*(selfemp - se_moe)
generate double s_hi = 100*(selfemp + se_moe)
generate double s_pct = 100*selfemp
replace s_lo = 0 if s_lo < 0
* Orange marks the two music occupations, the series the report is about.
generate byte ismusic = inlist(occ, 2751, 2752)
generate double s_music = s_pct if ismusic == 1
generate double s_other = s_pct if ismusic == 0
generate str8 lab_s = strtrim(string(s_pct, "%4.0f")) + "%"
generate double xlab_s = s_hi + 1.6

local ylab ""
forvalues i = 1/`=_N' {
    local L = lab[`i']
    local ylab `"`ylab' `i' "`L'""'
}

* Title checked against the bars: musicians and singers 51.5 percent, all Texas
* workers 9.8 percent. Photographers sit above musicians here, so the title
* claims no ranking, only the two levels a reader can see.
twoway (bar s_other ord, horizontal barwidth(0.62) color("${NAVY}") lwidth(none)) ///
       (bar s_music ord, horizontal barwidth(0.62) color("${ORANGE}") lwidth(none)) ///
       (rcap s_lo s_hi ord, horizontal lcolor("${MUTED}") lwidth(thin) msize(0.8)) ///
       (scatter ord xlab_s, msymbol(none) mlabel(lab_s) mlabcolor("${TEXTC}") ///
            mlabsize(2.2) mlabposition(3)) ///
       , title("Half of Texas musicians are self-employed, against 10% of all workers", $TITLEOPT) ///
         subtitle("Share self-employed, incorporated or not;" "Texas workers 18-64 who are employed, ACS 2020-2024 5-year PUMS", $SUBOPT) ///
         ylabel(`ylab', angle(0) labsize(2.6) notick nogrid) ytitle("") ///
         yscale(range(0.4 `=_N+0.6')) ///
         xlabel(0(10)60, labsize(2.8)) xscale(range(0 74)) ///
         xtitle("Percent self-employed", size(2.8)) ///
         legend(order(2 "Music occupations" 1 "Other creative occupations and" "the all-worker baseline") ///
                rows(2) position(6) $LEGOPT) ///
         graphregion(color(white)) plotregion(margin(l=0)) ///
         ysize(5.0) xsize(8)
figsave, name(fig03_selfemp_share)
export delimited occ lab nunw_emp wtd_emp selfemp se_moe ///
    using "${OUT}/fig03_selfemp_share.csv", replace


* ============================================== 10. FIGURE 04 - EARNINGS CDF ==
* Cumulative share of workers earning less than each level. The musician curve
* carries a 90 percent replicate band; the all-worker band is a fraction of a
* point wide and would not be visible, so it is not drawn.

use `persons', clear
tempfile cdf
tempname cf
postfile `cf' int step double(thresh mus mus_lo mus_hi allw) using `cdf', replace

forvalues k = 0/20 {
    local t = `k' * 5000
    quietly generate byte _below = (PERNP_2025usd < `t')
    quietly summarize _below [aw=PWGTP], meanonly
    local aw = r(mean)
    quietly summarize _below [aw=PWGTP] if g_mus == 1, meanonly
    local mu = r(mean)
    quietly drop _below
    post `cf' (`k') (`t') (`mu') (.) (.) (`aw')
}
postclose `cf'

* Replicate band for the musician curve, by the same successive-difference
* formula used for the medians. Computed on a kept-down copy of the musician
* records so the 21 x 80 recomputations stay cheap. The all-worker curve gets no
* band because its 90 percent interval is under a fifth of a point wide and
* would render as a line.
preserve
    keep if base_emp == 1 & g_mus == 1
    forvalues k = 0/20 {
        local t = `k' * 5000
        quietly generate byte _below = (PERNP_2025usd < `t')
        quietly summarize _below [aw=PWGTP], meanonly
        local th = r(mean)
        local ss = 0
        forvalues r = 1/80 {
            quietly summarize _below [aw=max(PWGTP`r',0)], meanonly
            local ss = `ss' + (r(mean) - `th')^2
        }
        local cdfse`k' = sqrt((4/80)*`ss')
        quietly drop _below
    }
restore

use `cdf', clear
forvalues k = 0/20 {
    quietly replace mus_lo = max(0, mus - 1.645*`cdfse`k'') if step == `k'
    quietly replace mus_hi = min(1, mus + 1.645*`cdfse`k'') if step == `k'
}
foreach v in mus mus_lo mus_hi allw {
    quietly replace `v' = 100*`v'
}

twoway (rarea mus_lo mus_hi thresh, color("${ORANGE}%18") lwidth(none)) ///
       (line mus thresh, lcolor("${ORANGE}") lwidth(0.7)) ///
       (line allw thresh, lcolor("${NAVY}") lwidth(0.7) lpattern(dash)) ///
       , title("About half of employed Texas musicians earn under $25,000 from work", $TITLEOPT) ///
         subtitle("Cumulative share of workers earning less than each level, 2025 dollars;" "Texas workers 18-64 who are employed, ACS 2020-2024 5-year PUMS", $SUBOPT) ///
         ylabel(0(20)100, angle(0) labsize(2.8)) ///
         ytitle("Percent of workers earning less", size(2.8)) ///
         xlabel(0(20000)100000, format(%12.0fc) labsize(2.8)) ///
         xscale(range(0 105000)) ///
         xtitle("Annual personal earnings, 2025 dollars", size(2.8)) ///
         text(80 22000 "Musicians and singers", color("${ORANGE}") size(2.9) placement(e)) ///
         text(30 62000 "All Texas workers 18-64", color("${NAVY}") size(2.9) placement(e)) ///
         legend(off) graphregion(color(white)) ///
         ysize(4.6) xsize(8)
figsave, name(fig04_earnings_distribution)
export delimited thresh mus mus_lo mus_hi allw ///
    using "${OUT}/fig04_earnings_distribution.csv", replace


* ============================================== 11. FIGURE 05 - RENT BURDEN ==
* Only the musicians-and-singers definition and the all-worker comparison are
* plotted; the wider music-occupation grouping stays in the ledger so a pooled
* rate is never read off this chart as a musician rate.
use `housepanel', clear
keep if inlist(grp, "Musician households", "All worker households")
generate byte ismusic = (grp == "Musician households")
expand 2
bysort grp: generate byte which = _n
generate double share = 100*cond(which == 1, r30, r50)
generate double moe   = 100*cond(which == 1, r30m, r50m)
generate double lo = max(0, share - moe)
generate double hi = share + moe
generate double xpos = which + cond(ismusic == 1, -0.17, 0.17)
generate double s_music = share if ismusic == 1
generate double s_other = share if ismusic == 0
generate str8 lab_b = strtrim(string(share, "%4.0f")) + "%"

* Title checked against the bars: musician renters 45.9 percent over the 30
* percent line against 44.4 percent for all worker households, and 21.0 against
* 18.9 at the 50 percent line. Both differences sit well inside the musician
* margin of error, so the chart shows similarity, and the title says so.
twoway (bar s_other xpos, barwidth(0.30) color("${NAVY}") lwidth(none)) ///
       (bar s_music xpos, barwidth(0.30) color("${ORANGE}") lwidth(none)) ///
       (rcap lo hi xpos, lcolor("${MUTED}") lwidth(thin) msize(0.9)) ///
       (scatter hi xpos, msymbol(none) mlabel(lab_b) mlabcolor("${TEXTC}") ///
            mlabsize(2.4) mlabposition(12) mlabgap(1.4)) ///
       , title("Musician renters carry about the same rent burden as other workers", $TITLEOPT) ///
         subtitle("Gross rent as a share of household income;" "Texas renter households with an employed resident 18-64, ACS 2020-2024 5-year PUMS", $SUBOPT) ///
         xlabel(1 "More than 30% of income" 2 "More than 50% of income", labsize(2.9) notick) ///
         xtitle("") xscale(range(0.5 2.5)) ///
         ylabel(0(10)60, angle(0) labsize(2.8)) ///
         ytitle("Percent of renter households", size(2.8)) ///
         legend(order(2 "Musician households" 1 "All worker households") ///
                rows(1) position(6) $LEGOPT) ///
         graphregion(color(white)) ///
         ysize(4.6) xsize(8)
figsave, name(fig05_housing_burden)
export delimited grp n_rent n_own w_rent w_own r30 r30m r50 r50m o30 o30m o50 o50m medrent ///
    using "${OUT}/fig05_housing_burden.csv", replace


* ==================================================== 12. VALIDATION PRINTS ==
* Checks against the earlier evidence pass, printed so the run's log is the
* record. Where the numbers differ the reason is the analysis base, not the
* arithmetic; the header of this file explains it and the ledger carries both.
display as text _newline "{hline 72}"
display as text "Validation against the 2026-08-01 evidence pass"
display as text "{hline 72}"

use `persons', clear
display as text "  target from the fact-check, matched employed 18-64 base:"
display as text "    musicians nominal PINCP 25,000 / PERNP 21,000;"
display as text "    all workers nominal PINCP 45,000 / PERNP 43,700;"
display as text "    self-employment 51.5 TX musicians, 72.2 Austin musicians, 9.8 baseline."
quietly _pctile PINCP [pw=PWGTP] if g_mus == 1 & base_emp == 1, p(50)
display as text "  median PINCP, musicians, NOMINAL, matched base    : " %9.0fc r(r1)
quietly _pctile PERNP [pw=PWGTP] if g_mus == 1 & base_emp == 1, p(50)
display as text "  median PERNP, musicians, NOMINAL, matched base    : " %9.0fc r(r1)
quietly _pctile PINCP [pw=PWGTP] if base_emp == 1, p(50)
display as text "  median PINCP, all workers, NOMINAL                : " %9.0fc r(r1)
quietly _pctile PERNP [pw=PWGTP] if base_emp == 1, p(50)
display as text "  median PERNP, all workers, NOMINAL                : " %9.0fc r(r1)
quietly _pctile PERNP_2025usd [pw=PWGTP] if g_mus == 1 & base_pos == 1, p(50)
display as text "  median PERNP, musicians, 2025 dollars, POS base   : " %9.0fc r(r1)
quietly _pctile PERNP_2025usd [pw=PWGTP] if base_pos == 1, p(50)
display as text "  median PERNP, all workers, 2025 dollars, POS base : " %9.0fc r(r1)
quietly summarize selfemp [aw=PWGTP] if g_mus == 1 & base_emp == 1
display as text "  self-employment, musicians and singers, Texas     : " %5.1f 100*r(mean) "%  (n = " r(N) ")"
quietly summarize selfemp [aw=PWGTP] if g_mus == 1 & base_emp == 1 & geo_austin == 1
display as text "  self-employment, musicians and singers, Austin    : " %5.1f 100*r(mean) "%  (n = " r(N) ")"
quietly summarize selfemp [aw=PWGTP] if base_emp == 1
display as text "  self-employment, all Texas workers 18-64          : " %5.1f 100*r(mean) "%"
quietly summarize selfemp [aw=PWGTP] if g_music == 1 & base_emp == 1
display as text "  self-employment, POOLED 2751+2752 (do not label as musicians) : " %5.1f 100*r(mean) "%"
quietly summarize selfemp [aw=PWGTP] if g_creative == 1 & base_emp == 1
display as text "  self-employment, POOLED nine creative occupations (do not label as musicians) : " %5.1f 100*r(mean) "%"
quietly total PWGTP if g_mus == 1
matrix A = e(b)
quietly total PWGTP if g_mus == 1 & geo_austin == 1
matrix B = e(b)
quietly count if g_mus == 1 & geo_austin == 1
display as text "  Austin share of Texas musicians                   : " %5.1f 100*B[1,1]/A[1,1] "%  (Austin n = " r(N) ", weighted " %8.0fc B[1,1] ")"

* Housekeeping: the decompressed replicate files are large and temporary.
capture erase "`tmpp'"
capture erase "`tmph'"

display as text _newline "10_pums_earnings.do complete"
