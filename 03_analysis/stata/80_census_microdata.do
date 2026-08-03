*! 80_census_microdata.do - What the 2022 Greater Austin Music Census microdata
*!                          says about income composition, the cost of working,
*!                          and who is thinking about leaving Austin.
*!
*! Inputs  : 01_evidence/08_venues_ecosystem/austin_music_census_2022_details_an3p-3yqx.csv
*!           01_evidence/08_venues_ecosystem/austin_music_census_2022_zipcodes_p7ky-riuq.csv
*!           03_analysis/out/cpi_annual.dta            (built by _setup.do)
*!           03_analysis/out/venue_closure_reasons.csv (optional, from 30_venues)
*!
*! Outputs : 04_figures/fig25_income_concentration.png (+ out/fig25_*.csv)
*!           04_figures/fig26_retention_split.png      (+ out/fig26_*.csv)
*!           04_figures/fig27_cost_of_working.png      (+ out/fig27_*.csv)
*!           04_figures/fig28_venue_pressures.png      (+ out/fig28_*.csv)
*!           03_analysis/out/tables/table_census_item_response.csv
*!           03_analysis/out/tables/table_census_geography.csv
*!           03_analysis/out/tables/table_census_spending.csv
*!           03_analysis/out/tables/table_census_retention_subgroups.csv
*!           03_analysis/out/tables/table_census_retention_logit.csv
*!           03_analysis/out/tables/table_census_venue_pressures.csv
*!           03_analysis/out/numbers/numbers_census.csv
*!
*! ------------------------------------------------------------------------
*! WHAT THIS SURVEY IS, AND WHAT IT IS NOT - read before quoting any number
*! ------------------------------------------------------------------------
*! The 2022 Greater Austin Music Census is a SELF-SELECTED ONLINE CONVENIENCE
*! SAMPLE fielded 15 July - 12 September 2022 by Sound Music Cities, LLC. It
*! carries NO SURVEY WEIGHTS. Every figure in this module is therefore a share
*! of the respondents who answered a particular item, never an estimate of the
*! Austin music workforce. Nothing here may be compared with the ACS or PUMS
*! estimates elsewhere in this report as though the two measured the same
*! population: this instrument recruited through community partners, and the
*! federal series draw probability samples of households and establishments.
*!
*! It is a single snapshot. No comparable follow-up exists. Where the 2014
*! census asked a similar question, the comparison is between two different
*! self-selected samples eight years apart and is directional at best.
*!
*! THERE IS NO DOLLAR INCOME VARIABLE. On the advice of its community partners
*! the 2022 instrument removed the 2014 income-quantification questions, which
*! the Summary Report (printed p.2) says had turned off many respondents. What
*! it kept is income-adjacent: the SHARE of music income coming from each
*! source, on a five-point All / Most / Some / Very little / None scale. This
*! module never converts that scale into dollars.
*!
*! The one dollar-denominated quantity the census did collect from creatives is
*! a COST: annual spending on their own music work, in eight categories. That
*! is section 5, and it is the half of the picture the Census Bureau Nonemployer
*! Statistics receipts figure cannot see, because receipts are gross of expenses.
*!
*! ------------------------------------------------------------------------
*! ROUTING - why the denominators move so much
*! ------------------------------------------------------------------------
*! Respondents were routed into role-specific blocks. The creatives block was
*! answered almost only by people whose primary sector is Music Creative; the
*! presenter block was answered by primary presenters AND by creatives who also
*! present gigs. On top of routing there is heavy and uneven item nonresponse:
*! the 2,227 respondents fall to 1,900 on the retention pair, 1,119 on the
*! income-source scale, 1,086 on gig volume, 728 on the largest spending item
*! and 177 on the presenter pressure ranking. Section 2 registers every
*! denominator and writes table_census_item_response.csv, so no reader has to
*! guess which block is solid and which is thin.
*!
*! ------------------------------------------------------------------------
*! A PUBLISHED-CHART ERROR THIS MODULE CORRECTS
*! ------------------------------------------------------------------------
*! Data Appendix slide 41 plots the 2022 share reporting any income from each
*! source with four of seven bars under the wrong labels. The microdata and
*! slide 40, which shows the full five-segment distribution, agree with each
*! other and with the published Socrata column dictionary, and all three
*! disagree with slide 41. The corrected pairing is in section 3 and in the
*! registry. The evidence note in this project
*! (01_evidence/05_music_census_pay_surveys/_findings.md, item 14) repeats
*! slide 41 and should be corrected with it.

clear all
do "_setup.do"                    // run from 03_analysis/stata/
global CURMODULE "census"
numinit

* Paths carry spaces (the Google Drive "My Drive" mount), so every confirm is
* compound-quoted. An unquoted path with a space is what produces a misleading
* r(601) here.
foreach f in "${EV_VENUE}/austin_music_census_2022_details_an3p-3yqx.csv" ///
             "${EV_VENUE}/austin_music_census_2022_zipcodes_p7ky-riuq.csv" ///
             "${OUT}/cpi_annual.dta" {
    capture confirm file `"`f'"'
    if _rc != 0 {
        display as error "Required input not found: `f'"
        exit 601
    }
}

local SRC  "01_evidence/08_venues_ecosystem/austin_music_census_2022_details_an3p-3yqx.csv"
local SRCZ "01_evidence/08_venues_ecosystem/austin_music_census_2022_zipcodes_p7ky-riuq.csv"

* Repeated in the note of every registry row resting on this survey, so no
* number can travel into the report without its provenance. There is not one
* ASCII apostrophe anywhere in this file: one inside a local macro breaks macro
* expansion, and this string is passed through several.
local CAV "2022 Greater Austin Music Census, self-selected online convenience sample fielded 15 Jul - 12 Sep 2022, 2,227 respondent records, NO SURVEY WEIGHTS. Every figure is a sample share, not a population estimate, and none is comparable with ACS, PUMS, OEWS or QCEW."


* ============================================================== 0. HELPERS ==
* Thin wrappers over numadd so the ledger formats consistently. This survey has
* no design weights and no replicate weights, so no margin of error is ever
* attached: inventing one would imply a probability sample that does not exist.

capture program drop cnum
program define cnum
    syntax , KEY(string) VALUE(real) [UNIT(string) SOURCE(string) NOTE(string)]
    if "`unit'" == "" local unit "respondents"
    numadd, key(`key') value(`=string(`value',"%18.0g")') ///
            formatted("`=strtrim(string(round(`value'),"%15.0fc"))'") ///
            unit("`unit'") source("`source'") note("`note'")
end

capture program drop cpct
program define cpct
    * value arrives already on a 0-100 scale.
    syntax , KEY(string) VALUE(real) [SOURCE(string) NOTE(string)]
    numadd, key(`key') value(`=string(`value',"%18.0g")') ///
            formatted("`=strtrim(string(`value',"%9.1f"))'%") ///
            unit("percent of the denominator named in the note") ///
            source("`source'") note("`note'")
end

capture program drop cusd
program define cusd
    * char(36) is a dollar sign. Writing it literally would let Stata try to
    * expand it as a global macro.
    syntax , KEY(string) VALUE(real) [UNIT(string) SOURCE(string) NOTE(string)]
    if "`unit'" == "" local unit "2025 dollars"
    local f = char(36) + strtrim(string(round(`value'), "%15.0fc"))
    numadd, key(`key') value(`=string(`value',"%18.0g")') formatted("`f'") ///
            unit("`unit'") source("`source'") note("`note'")
end

capture program drop keyify
program define keyify, rclass
    * Turn a human label into a legal registry key: letters, digits, underscores.
    syntax , TEXT(string)
    local s = lower("`text'")
    foreach bad in "," "." "(" ")" "/" "-" ":" ";" {
        local s : subinstr local s "`bad'" "", all
    }
    local s : subinstr local s " " "_", all
    while strpos("`s'", "__") > 0 {
        local s : subinstr local s "__" "_", all
    }
    return local key "`s'"
end


* =============================================== 1. LOAD AND BUILD MEASURES ==
* Everything is imported as string. The file mixes true blanks, numeric strings
* and multi-select strings joined with commas, and letting Stata guess types
* would silently turn a blank into a zero on the spending items.

import delimited using "${EV_VENUE}/austin_music_census_2022_details_an3p-3yqx.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve) stringcols(_all)

quietly foreach v of varlist _all {
    replace `v' = trim(`v')
}

quietly count
local NTOT = r(N)
display as text _newline "Respondent records loaded: `NTOT'"

* --- role and background --------------------------------------------------
generate byte sector = .
replace sector = 1 if primary_music_ecosystem_sector == "Music Creative"
replace sector = 2 if primary_music_ecosystem_sector == "Music Industry"
replace sector = 3 if primary_music_ecosystem_sector == "Music Venue or Presenter"
replace sector = 4 if primary_music_ecosystem_sector == "None of these - Exit the Census"
label define sectorl 1 "Music creative" 2 "Music industry" 3 "Venue or presenter" 4 "Exited the census"
label values sector sectorl
label variable sector "Primary music ecosystem sector"

generate byte sector3 = sector if inlist(sector, 1, 2, 3)
label values sector3 sectorl
label variable sector3 "Primary sector, excluding census exits"

generate byte yrsexp = .
replace yrsexp = 1 if years_experience == "Less than 3"
replace yrsexp = 2 if years_experience == "3 to 5"
replace yrsexp = 3 if years_experience == "6 to 10"
replace yrsexp = 4 if years_experience == "More than 10"
label define yrsl 1 "Under 3 years" 2 "3 to 5 years" 3 "6 to 10 years" 4 "More than 10 years"
label values yrsexp yrsl
label variable yrsexp "Years working in music"

* --- geography ------------------------------------------------------------
generate byte austinres = .
replace austinres = 1 if city_of_austin_resident == "true"
replace austinres = 0 if city_of_austin_resident == "false"
label define ar 0 "Outside City of Austin" 1 "City of Austin resident"
label values austinres ar

generate double miles = real(residence_distance_from)
label variable miles "Self-reported miles from downtown Austin"

* --- retention (the headline pair) ---------------------------------------
* Both items are five-point. The published 89 / 64 pair aggregates the two
* affirmative options, so that is what is replicated here; the definitely-yes
* share alone is registered beside it so a reader can see how much of the
* affirmative rests on maybe.
generate byte contmusic = .
replace contmusic = 1 if inlist(intent_to_continue_music, "Definitely Yes", "Maybe Yes")
replace contmusic = 0 if inlist(intent_to_continue_music, "Unsure", "Maybe No", "Definitely No")
generate byte contdef = (intent_to_continue_music == "Definitely Yes") if contmusic < .

generate byte stayaus = .
replace stayaus = 1 if inlist(intent_to_stay_in_austin, "Definitely Yes", "Maybe Yes")
replace stayaus = 0 if inlist(intent_to_stay_in_austin, "Unsure", "Maybe No", "Definitely No")
generate byte staydef = (intent_to_stay_in_austin == "Definitely Yes") if stayaus < .

label define yn 0 "No, or unsure" 1 "Definitely or maybe yes"
label values contmusic yn
label values stayaus yn
label variable contmusic "Intends to continue music work over the next 3 years"
label variable stayaus "Intends to still live in greater Austin in 3 years"

* --- housing, insurance, workspace ---------------------------------------
* current_housing is a multi-select. A respondent who ticked both owner and
* renter is counted as an owner, the conservative choice for a story about
* renters being the least secure group.
generate byte tenure = .
replace tenure = 1 if strpos(current_housing, "Homeowner") > 0
replace tenure = 2 if strpos(current_housing, "Renter") > 0 & tenure >= .
replace tenure = 3 if current_housing != "" & tenure >= .
label define tenl 1 "Homeowner" 2 "Renter" 3 "Other or unstable housing"
label values tenure tenl
label variable tenure "Housing tenure"

generate byte insured = .
replace insured = 1 if health_insurance_currently == "Yes"
replace insured = 0 if inlist(health_insurance_currently, "Lack Recently Lost", ///
                              "Lack for Past 2 or More Years")
label define insl 0 "No health insurance" 1 "Has health insurance"
label values insured insl
label variable insured "Health insurance status"

generate byte wspace = .
replace wspace = 1 if strpos(work_space_status_including, "Currently Own") > 0
replace wspace = 2 if strpos(work_space_status_including, "Renter Lessee") > 0 & wspace >= .
replace wspace = 3 if strpos(work_space_status_including, "Need But Lack") > 0 & wspace >= .
replace wspace = 4 if work_space_status_including == "Employer Provides or Do Not Need"
label define wsl 1 "Owns work space" 2 "Rents work space" ///
                 3 "Needs but lacks work space" 4 "Provided or not needed"
label values wspace wsl
label variable wspace "Work or performance space status"

* --- income composition ---------------------------------------------------
* Five-point share-of-music-income scale, one variable per source. Column names
* come from the published Socrata dictionary for dataset an3p-3yqx; every
* mapping was re-verified against the full five-segment distribution on Data
* Appendix slide 40 before use, because slide 41 disagrees (see section 3).
local INCV creatives_income_from_live creatives_income_from_live_1 ///
           creatives_income_related creatives_income_related_2 ///
           creatives_income_related_3 creatives_income_related_1 ///
           creatives_income_related_4
local INCL `""Live performance, local" "Live performance, touring" "Recordings and royalties" "Studio and session work" "Merchandise" "Songwriting and mechanicals" "Teaching""'

local k = 0
foreach v of local INCV {
    local ++k
    generate byte inc`k' = .
    replace inc`k' = 1 if `v' == "None"
    replace inc`k' = 2 if `v' == "Very Little"
    replace inc`k' = 3 if `v' == "Some"
    replace inc`k' = 4 if `v' == "Most"
    replace inc`k' = 5 if `v' == "All"
}
label define incl 1 "None" 2 "Very little" 3 "Some" 4 "Most" 5 "All"
forvalues k = 1/7 {
    label values inc`k' incl
}

* Concentration of music income in local live performance. This is the closest
* thing the instrument has to an income variable, and it is WITHIN music: it is
* not the share of TOTAL income that comes from music, which was never asked.
generate byte liveconc = inc1
label values liveconc incl
label variable liveconc "Music income from local live performance"

* --- work volume ----------------------------------------------------------
generate byte gigs = .
replace gigs = 1 if creatives_paid_performances == "0"
replace gigs = 2 if creatives_paid_performances == "1 to 3"
replace gigs = 3 if creatives_paid_performances == "4 to 6"
replace gigs = 4 if creatives_paid_performances == "7 to 10"
replace gigs = 5 if creatives_paid_performances == "11 to 15"
replace gigs = 6 if creatives_paid_performances == "16 or more"
label define gigl 1 "0 a month" 2 "1 to 3" 3 "4 to 6" 4 "7 to 10" 5 "11 to 15" 6 "16 or more"
label values gigs gigl
label variable gigs "Paid local performances per month"

generate double guarpct = real(creatives_percentage_of_gigs)
label variable guarpct "Percent of gigs paying a base guarantee"

generate double localspend = real(creatives_percentage_of_annual)
label variable localspend "Percent of music spending paid to local providers"

* NOT gig work outside music. The Socrata dictionary names this "CREATIVES Work
* Also as Gig Presenter" and Data Appendix slide 47 confirms it means presenting
* or promoting other peoples gigs in addition to performing. The item that
* measured work outside music (Data Appendix slide 15) is absent from this
* microdata release entirely - see section 4.
generate byte gigpresent = .
replace gigpresent = 0 if creatives_work_also_as_gig == "No"
replace gigpresent = 1 if creatives_work_also_as_gig != "" & creatives_work_also_as_gig != "No"
label define gpl 0 "Performs only" 1 "Also presents or promotes gigs"
label values gigpresent gpl

generate byte restored = .
replace restored = 1 if restored_pre_pandemic_workload == "true"
replace restored = 0 if restored_pre_pandemic_workload == "false"

* --- annual spending ------------------------------------------------------
* Eight categories, dollars, creatives only. Category order taken from the
* Socrata dictionary and cross-checked against the eight published category
* means on Data Appendix p.46, each matching within 2 percent.
local SPV creatives_annual_spending creatives_annual_spending_1 ///
          creatives_annual_spending_2 creatives_annual_spending_3 ///
          creatives_annual_spending_4 creatives_annual_spending_5 ///
          creatives_annual_spending_6 creatives_annual_spending_7
local SPL `""New recordings" "Publicity and promotion" "Web and social media" "Supplies" "Rehearsal or work space" "Gear and rentals" "Merchandise" "Accounting and legal""'

generate byte nspend = 0
local k = 0
foreach v of local SPV {
    local ++k
    generate double sp`k' = real(`v') if `v' != ""
    quietly replace nspend = nspend + (`v' != "")
}
label variable nspend "Number of the 8 spending categories answered"

* --- presenter block ------------------------------------------------------
generate byte cap = .
replace cap = 1 if presenter_venue_capacity == "1 to 100"
replace cap = 2 if presenter_venue_capacity == "101 to 200"
replace cap = 3 if presenter_venue_capacity == "201 to 350"
replace cap = 4 if presenter_venue_capacity == "351 to 500"
replace cap = 5 if presenter_venue_capacity == "501 to 1000"
replace cap = 6 if presenter_venue_capacity == "1001 or more"
label define capl 1 "1 to 100" 2 "101 to 200" 3 "201 to 350" 4 "351 to 500" ///
                  5 "501 to 1,000" 6 "1,001 or more"
label values cap capl
label variable cap "Legal capacity of the venue"

generate byte prestype = .
replace prestype = 1 if cap < .
replace prestype = 2 if presenter_venue_capacity == "Independent Promoter"
replace prestype = 3 if presenter_venue_capacity == "Other"
label define ptl 1 "Venue operator" 2 "Independent promoter" 3 "Other presenter"
label values prestype ptl

local PRSV presenter_ranking_of_pressures presenter_ranking_of_pressures_1 ///
           presenter_ranking_of_pressures_2 presenter_ranking_of_pressures_3 ///
           presenter_ranking_of_pressures_4 presenter_ranking_of_pressures_5 ///
           presenter_ranking_of_pressures_6 presenter_ranking_of_pressures_7 ///
           presenter_ranking_of_pressures_8
local PRSL `""Talent costs" "Changing audience behavior" "Labor cost and retention" "Property tax" "Marketing" "Ordinances and permitting" "Unpredictable operating costs" "Neighborhood redevelopment" "Building operations and upkeep""'

local k = 0
foreach v of local PRSV {
    local ++k
    generate byte prs`k' = real(`v')
}


* ================================================== 2. PROFILE THE SAMPLE ==
* Nothing downstream is quotable without its denominator, so the denominators
* come first.

cnum, key(census_n_respondents) value(`NTOT') source("`SRC'") ///
    note("Respondent records in the published microdata file. The Summary Report headline count is 2,260; the microdata release carries 2,227 rows, 33 fewer, and the release documents no reason. All shares in this module use the 2,227-row file. `CAV'")

quietly count if sector < .
local NSEC = r(N)
forvalues s = 1/4 {
    quietly count if sector == `s'
    local ns`s' = r(N)
}
cnum, key(census_n_sector_creative) value(`ns1') source("`SRC'") ///
    note("Respondents whose primary music ecosystem sector is Music Creative. The sector item itself was answered by `NSEC' of `NTOT'. `CAV'")
cnum, key(census_n_sector_industry) value(`ns2') source("`SRC'") ///
    note("Primary sector Music Industry, of `NSEC' who answered the sector item. `CAV'")
cnum, key(census_n_sector_presenter) value(`ns3') source("`SRC'") ///
    note("Primary sector Music Venue or Presenter, of `NSEC' who answered the sector item. This is the smallest of the three role groups and it caps everything the venue section can say. `CAV'")
cnum, key(census_n_sector_exited) value(`ns4') source("`SRC'") ///
    note("Selected None of these - Exit the Census, which terminated the questionnaire. They remain in the 2,227-row file and in any all-respondent denominator, but answer almost nothing else, so they are excluded from the sector breakouts. `CAV'")

* --- item response inventory ---------------------------------------------
* One row per analysed item: how many answered it, the share of all 2,227, and
* the block it was routed to. This is the file to consult before quoting
* anything from this module.
tempname irf
tempfile irtab
postfile `irf' str44 item str18 block int n_answer double pct_all using `irtab', replace

capture program drop iradd
program define iradd
    syntax varname(string), IRF(string) ITEM(string) BLOCK(string) NTOT(integer)
    quietly count if `varlist' != ""
    post `irf' ("`item'") ("`block'") (r(N)) (100*r(N)/`ntot')
end

local ALLB "All respondents"
local CREB "Creatives block"
local PREB "Presenter block"

iradd county_of_residence,             irf(`irf') ntot(`NTOT') block("`ALLB'") item("County of residence")
iradd residence_distance_from,         irf(`irf') ntot(`NTOT') block("`ALLB'") item("Miles from downtown")
iradd city_of_austin_resident,         irf(`irf') ntot(`NTOT') block("`ALLB'") item("City of Austin resident")
iradd primary_music_ecosystem_sector,  irf(`irf') ntot(`NTOT') block("`ALLB'") item("Primary sector")
iradd music_business_structure,        irf(`irf') ntot(`NTOT') block("`ALLB'") item("Business structure (multi-select)")
iradd work_location,                   irf(`irf') ntot(`NTOT') block("`ALLB'") item("Work location")
iradd years_experience,                irf(`irf') ntot(`NTOT') block("`ALLB'") item("Years of experience")
iradd music_education,                 irf(`irf') ntot(`NTOT') block("`ALLB'") item("Music education (multi-select)")
iradd restored_pre_pandemic_workload,  irf(`irf') ntot(`NTOT') block("`ALLB'") item("Work back to pre-pandemic level")
iradd intent_to_continue_music,        irf(`irf') ntot(`NTOT') block("`ALLB'") item("Intent to continue in music")
iradd intent_to_stay_in_austin,        irf(`irf') ntot(`NTOT') block("`ALLB'") item("Intent to stay in greater Austin")
iradd work_space_status_including,     irf(`irf') ntot(`NTOT') block("`ALLB'") item("Work space status")
iradd conditions_of_current_lease,     irf(`irf') ntot(`NTOT') block("`ALLB'") item("Conditions of current lease")
iradd intent_to_renew_current_lease,   irf(`irf') ntot(`NTOT') block("`ALLB'") item("Intent to renew lease")
iradd current_housing,                 irf(`irf') ntot(`NTOT') block("`ALLB'") item("Housing tenure")
iradd housing_changes_over_past,       irf(`irf') ntot(`NTOT') block("`ALLB'") item("Housing changes over past 2 years")
iradd health_insurance_currently,      irf(`irf') ntot(`NTOT') block("`ALLB'") item("Health insurance")
iradd affordability_struggles,         irf(`irf') ntot(`NTOT') block("`ALLB'") item("Expenses hard to afford")
iradd received_covid_related_relief,   irf(`irf') ntot(`NTOT') block("`ALLB'") item("Received COVID relief")
iradd age,                             irf(`irf') ntot(`NTOT') block("`ALLB'") item("Age band")
iradd race,                            irf(`irf') ntot(`NTOT') block("`ALLB'") item("Race")
iradd gender,                          irf(`irf') ntot(`NTOT') block("`ALLB'") item("Gender")
iradd creatives_income_from_live,      irf(`irf') ntot(`NTOT') block("`CREB'") item("Income share: local live performance")
iradd creatives_income_from_live_1,    irf(`irf') ntot(`NTOT') block("`CREB'") item("Income share: touring")
iradd creatives_income_related,        irf(`irf') ntot(`NTOT') block("`CREB'") item("Income share: recordings and royalties")
iradd creatives_income_related_1,      irf(`irf') ntot(`NTOT') block("`CREB'") item("Income share: songwriting")
iradd creatives_income_related_2,      irf(`irf') ntot(`NTOT') block("`CREB'") item("Income share: studio work")
iradd creatives_income_related_3,      irf(`irf') ntot(`NTOT') block("`CREB'") item("Income share: merchandise")
iradd creatives_income_related_4,      irf(`irf') ntot(`NTOT') block("`CREB'") item("Income share: teaching")
iradd creatives_paid_performances,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Paid local gigs per month")
iradd creatives_percentage_of_gigs,    irf(`irf') ntot(`NTOT') block("`CREB'") item("Percent of gigs with a guarantee")
iradd creatives_work_also_as_gig,      irf(`irf') ntot(`NTOT') block("`CREB'") item("Also presents or promotes gigs")
iradd creatives_annual_spending,       irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: new recordings")
iradd creatives_annual_spending_1,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: publicity and promotion")
iradd creatives_annual_spending_2,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: web and social media")
iradd creatives_annual_spending_3,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: supplies")
iradd creatives_annual_spending_4,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: rehearsal or work space")
iradd creatives_annual_spending_5,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: gear and rentals")
iradd creatives_annual_spending_6,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: merchandise")
iradd creatives_annual_spending_7,     irf(`irf') ntot(`NTOT') block("`CREB'") item("Spend: accounting and legal")
iradd creatives_percentage_of_annual,  irf(`irf') ntot(`NTOT') block("`CREB'") item("Percent of spend paid locally")
iradd presenter_ownership_structure,   irf(`irf') ntot(`NTOT') block("`PREB'") item("Venue ownership structure")
iradd presenter_venue_type,            irf(`irf') ntot(`NTOT') block("`PREB'") item("Venue type")
iradd presenter_venue_capacity,        irf(`irf') ntot(`NTOT') block("`PREB'") item("Legal capacity")
iradd presenter_outdoor_live_music,    irf(`irf') ntot(`NTOT') block("`PREB'") item("Can host live music outdoors")
iradd presenter_ranking_of_pressures,  irf(`irf') ntot(`NTOT') block("`PREB'") item("Pressure ranking of 9 items")
iradd presenter_local_talent,          irf(`irf') ntot(`NTOT') block("`PREB'") item("Local talent share of bookings")
iradd presenter_confidence_booking,    irf(`irf') ntot(`NTOT') block("`PREB'") item("Confidence booking local talent")
postclose `irf'

preserve
use `irtab', clear
gsort -n_answer
export delimited using "${TABDIR}/table_census_item_response.csv", replace
display as text _newline "Item response inventory, n answering out of `NTOT':"
list item block n_answer pct_all, noobs sep(0) abbreviate(24)
restore

* --- geography ------------------------------------------------------------
quietly count if austinres < .
local NAR = r(N)
quietly count if austinres == 1
local NAR1 = r(N)
cnum, key(census_n_city_item) value(`NAR') source("`SRC'") ///
    note("Respondents who answered the City of Austin residency item. `CAV'")
cpct, key(census_pct_city_of_austin) value(`=100*`NAR1'/`NAR'') source("`SRC'") ///
    note("Share who are City of Austin residents: `NAR1' of the `NAR' who answered the item. On the full 2,227-row denominator it is 70.4 percent, because 78 respondents skipped the item. Quote the denominator with the share. `CAV'")

quietly count if county_of_residence == "Travis"
local NTRAV = r(N)
cpct, key(census_pct_travis) value(`=100*`NTRAV'/`NTOT'') source("`SRC'") ///
    note("Share living in Travis County: `NTRAV' of `NTOT'. County is the only item with complete response, which suggests it gated entry to the survey. The rest of the five-county field: Williamson 220, Hays 142, Bastrop 50, Caldwell 30. `CAV'")

quietly summarize miles, detail
local MMEAN = r(mean)
local MMED  = r(p50)
local MN    = r(N)
numadd, key(census_miles_mean) value(`=string(`MMEAN',"%9.4f")') ///
    formatted("`=strtrim(string(`MMEAN',"%9.1f"))' miles") unit("miles") source("`SRC'") ///
    note("Mean self-reported distance from downtown Austin, `MN' respondents who answered. Matches the published 10.6-mile average. `CAV'")
numadd, key(census_miles_median) value(`=string(`MMED',"%9.4f")') ///
    formatted("`=strtrim(string(`MMED',"%9.0f"))' miles") unit("miles") source("`SRC'") ///
    note("Median self-reported distance from downtown Austin, `MN' respondents. Matches the published 8-mile median. `CAV'")

preserve
contract county_of_residence, freq(n_respondents)
generate double pct_of_all = 100*n_respondents/`NTOT'
gsort -n_respondents
export delimited using "${TABDIR}/table_census_geography.csv", replace
display as text _newline "County of residence:"
list, noobs sep(0)
restore

* The ZIP export is a separate Socrata dataset with no respondent key, so it
* cannot be joined to the detail file. It is reported as a standalone marginal.
preserve
import delimited using "${EV_VENUE}/austin_music_census_2022_zipcodes_p7ky-riuq.csv", ///
    clear varnames(1) encoding("utf-8") case(preserve) stringcols(_all)
quietly count
local NZIP = r(N)
quietly levelsof home_zip_code, local(zl)
local NZIPD : word count `zl'
cnum, key(census_zip_rows) value(`NZIP') source("`SRCZ'") ///
    note("Rows in the companion ZIP-code export, stamped 2022-08-28, which is BEFORE the 12 September field close, so it is an interim extract and is 77 rows short of the detail file. It carries no respondent identifier and cannot be joined to the 2,227-row detail file; it supports a marginal distribution of home ZIPs and nothing else. `CAV'")
cnum, key(census_zip_distinct) value(`NZIPD') unit("distinct ZIP codes") source("`SRCZ'") ///
    note("Distinct home ZIP codes among the `NZIP' rows of the companion export. The four most common are 78745 (210 rows), 78704 (132), 78723 (101) and 78702 (85). `CAV'")
restore


* ============================ 3. INCOME COMPOSITION, WITHOUT ANY DOLLARS ==
* FIGURE 25.
*
* The five-point scale is the survey substitute for an earnings question. It
* answers something no federal source can: how concentrated a music income is
* in live performance. It says nothing about how large that income is.

tempname icf
tempfile ictab
postfile `icf' int srcid str30 srclab int nresp int cat double share using `ictab', replace
forvalues k = 1/7 {
    local L : word `k' of `INCL'
    quietly count if inc`k' < .
    local n = r(N)
    forvalues c = 1/5 {
        quietly count if inc`k' == `c'
        post `icf' (`k') ("`L'") (`n') (`c') (100*r(N)/`n')
    }
}
postclose `icf'

preserve
use `ictab', clear

* Rank sources by the share saying the source supplies ALL or MOST of their
* music income. That is the concentration measure this figure is about.
bysort srcid: egen double allmost = total(share*inlist(cat, 4, 5))
bysort srcid: egen double anyinc  = total(share*(cat > 1))
generate double negam = -allmost
egen double rk = group(negam)
generate double ypos = 8 - rk

* Stack All first at the left, None last at the right.
generate byte ord = 6 - cat
sort srcid ord
by srcid: generate double x1 = sum(share)
generate double x0 = x1 - share
generate double xmid = (x0 + x1)/2
generate str8 slab = strtrim(string(share, "%4.0f")) + "%" if share >= 6.5
label define catl 1 "None" 2 "Very little" 3 "Some" 4 "Most" 5 "All"
label values cat catl

sort srcid cat
export delimited srcid srclab nresp cat share x0 x1 allmost anyinc ypos ///
    using "${OUT}/fig25_income_concentration.csv", replace

display as text _newline "Share of music income by source (corrected labels):"
list srclab nresp cat share allmost anyinc, noobs sep(5) abbreviate(14)

forvalues s = 1/7 {
    quietly summarize allmost if srcid == `s', meanonly
    local am = r(mean)
    quietly summarize anyinc if srcid == `s', meanonly
    local ai = r(mean)
    quietly summarize nresp if srcid == `s', meanonly
    local nn = r(mean)
    quietly levelsof srclab if srcid == `s', local(lv) clean
    keyify, text("`lv'")
    local kk = r(key)
    cpct, key(census_incshare_allmost_`kk') value(`am') source("`SRC'") ///
        note("Share of music creatives saying ALL or MOST of their music income comes from `lv'. Denominator `nn' creatives who answered this item. Within-music share only: the instrument never asked what fraction of TOTAL income comes from music, so this cannot be read as a share of a livelihood. `CAV'")
    cpct, key(census_incshare_any_`kk') value(`ai') source("`SRC'") ///
        note("Share of music creatives reporting any income at all from `lv' - all, most, some or very little, excluding none. Denominator `nn'. Source labels follow the Socrata column dictionary for dataset an3p-3yqx and the five-segment distributions on Data Appendix slide 40, which agree with each other and with the microdata; see census_caveat_slide41 before quoting the same value from slide 41. `CAV'")
}

local ylab ""
forvalues s = 1/7 {
    quietly summarize ypos if srcid == `s', meanonly
    local yp = r(mean)
    quietly summarize nresp if srcid == `s', meanonly
    local nn = strtrim(string(r(mean), "%9.0fc"))
    quietly levelsof srclab if srcid == `s', local(lv) clean
    local ylab `"`ylab' `yp' "`lv' (n = `nn')""'
}

* A five-step ramp from dark to light, so the chart survives grayscale.
local C1 "27 45 85"
local C2 "43 108 176"
local C3 "125 170 214"
local C4 "190 210 230"
local C5 "222 226 230"

* A thin white outline on every stacked segment: "Very little" (C4) and
* "None" (C5) sit close in both hue and lightness, most visibly on the
* Teaching row, so the outline draws a clean edge at every segment boundary
* without changing any of the 5 ramp colours or the legend.
twoway (rbar x0 x1 ypos if cat == 5, horizontal barwidth(0.62) color("`C1'") lcolor(white) lwidth(vthin)) ///
       (rbar x0 x1 ypos if cat == 4, horizontal barwidth(0.62) color("`C2'") lcolor(white) lwidth(vthin)) ///
       (rbar x0 x1 ypos if cat == 3, horizontal barwidth(0.62) color("`C3'") lcolor(white) lwidth(vthin)) ///
       (rbar x0 x1 ypos if cat == 2, horizontal barwidth(0.62) color("`C4'") lcolor(white) lwidth(vthin)) ///
       (rbar x0 x1 ypos if cat == 1, horizontal barwidth(0.62) color("`C5'") lcolor(white) lwidth(vthin)) ///
       (scatter ypos xmid if cat >= 4, msymbol(none) mlabel(slab) mlabcolor(white) ///
            mlabsize(2.1) mlabposition(0)) ///
       (scatter ypos xmid if cat <= 3, msymbol(none) mlabel(slab) mlabcolor("${TEXTC}") ///
            mlabsize(2.1) mlabposition(0)) ///
       , title("Half of music creatives get most or all music income from local gigs", $TITLEOPT) ///
         subtitle("Share of a creative’s own music income coming from each source, music creatives only." ///
                  "2022 Greater Austin Music Census; self-selected sample, no weights, own base per row.", $SUBOPT) ///
         ylabel(`ylab', angle(0) labsize(2.5) notick nogrid) ytitle("") ///
         yscale(range(0.4 7.6)) ///
         xlabel(0(20)100, format(%3.0f) labsize(2.8)) xscale(range(0 100)) ///
         xtitle("Percent of creatives answering the item", size(2.8)) ///
         legend(order(1 "All" 2 "Most" 3 "Some" 4 "Very little" 5 "None") ///
                rows(1) position(6) $LEGOPT) ///
         graphregion(color(white)) plotregion(margin(l=0)) ///
         ysize(4.4) xsize(7.2)
figsave, name(fig25_income_concentration)
restore


* ================================================ 4. WORK VOLUME AND GIGS ==

quietly count if gigs < .
local NG = r(N)
cnum, key(census_n_gigs_item) value(`NG') source("`SRC'") ///
    note("Music creatives who answered the paid-local-performances-per-month item. `CAV'")

* The gig bands are coded 1 = zero a month, 2 = 1 to 3, 3 = 4 to 6, and up. So
* "more than 3 a month", the band the 2014 comparison uses, starts at gigs == 3.
quietly count if gigs == 1
cpct, key(census_gigs_zero) value(`=100*r(N)/`NG'') source("`SRC'") ///
    note("Share of music creatives reporting zero paid local performances a month, of `NG' who answered. Replicates the published 14 percent (Data Appendix p.42) against 7.6 percent in the 2014 census - but that is a comparison of two different self-selected samples eight years apart, not a measured change. `CAV'")
quietly count if gigs >= 3 & gigs < .
cpct, key(census_gigs_over3) value(`=100*r(N)/`NG'') source("`SRC'") ///
    note("Share reporting more than 3 paid local performances a month - the 4-to-6, 7-to-10, 11-to-15 and 16-or-more bands - of `NG' who answered. Replicates the published 35 percent against 43 percent in 2014, again two different self-selected samples. `CAV'")
quietly count if gigs >= 5 & gigs < .
cpct, key(census_gigs_over10) value(`=100*r(N)/`NG'') source("`SRC'") ///
    note("Share reporting more than 10 paid local performances a month, of `NG' who answered. A working-musician week is four or more gigs; this is the share at something close to full-time performing. `CAV'")
quietly count if gigs >= 2 & gigs < .
cpct, key(census_gigs_any) value(`=100*r(N)/`NG'') source("`SRC'") ///
    note("Share reporting at least one paid local performance a month, of `NG' who answered. `CAV'")

quietly count if gigs < . & restored == 1
local nrd = r(N)
quietly count if gigs >= 3 & gigs < . & restored == 1
local nrx = r(N)
if `nrd' >= 50 {
    cpct, key(census_gigs_over3_restored) value(`=100*`nrx'/`nrd'') source("`SRC'") ///
        note("Share reporting more than 3 paid local performances a month among the `nrd' creatives who also said their music work has returned to pre-pandemic levels. The published pandemic-adjusted comparison figure is 38 percent. `CAV'")
}

quietly summarize guarpct, detail
cpct, key(census_gig_guarantee_mean) value(`=r(mean)') source("`SRC'") ///
    note("Mean self-reported percent of gigs paying a base guarantee rather than a door or bar percentage, `=r(N)' creatives. Replicates the published 54 percent. The median is `=strtrim(string(r(p50),"%4.0f"))' percent and the distribution is close to bimodal at 0 and 100, so the mean describes no typical musician. No dollar amount was ever collected for a gig. `CAV'")

quietly count if gigpresent < .
local NGP = r(N)
quietly count if gigpresent == 1
cpct, key(census_also_presents_gigs) value(`=100*r(N)/`NGP'') source("`SRC'") ///
    note("Share of music creatives who also present or promote gigs, casually or professionally, of `NGP' who answered. THIS IS NOT WORK OUTSIDE MUSIC: the Socrata dictionary names the variable CREATIVES Work Also as Gig Presenter and Data Appendix slide 47 confirms the reading. See census_no_outside_work_item. `CAV'")

numadd, key(census_no_outside_work_item) value(0) formatted("not in the microdata") ///
    unit("flag") source("`SRC'") ///
    note("The census DID ask about work outside music - Data Appendix slide 15 reports 38 percent in a non-creative industry, 24 percent in another creative industry, 32 percent with no outside work and 22 percent calling the outside job primary. None of the 107 columns in the public microdata carries that item, so it cannot be reproduced, cross-tabulated or tested here. Quote it from the appendix with the appendix denominator, or not at all.")

display as text _newline "Gig volume by primary sector (routing check):"
tabulate gigs sector, column
* tabulate returns r(chi2) and r(p) but not the degrees of freedom, so it is
* built from the realised table dimensions rather than assumed from the coding.
display as text _newline "Gig volume by years of experience:"
tabulate gigs yrsexp, column chi2
local CHI_GY = r(chi2)
local P_GY   = r(p)
local DF_GY  = (r(r)-1)*(r(c)-1)
display as text _newline "Also presents gigs, by years of experience:"
tabulate gigpresent yrsexp, column chi2
local CHI_PY = r(chi2)
local P_PY   = r(p)
local DF_PY  = (r(r)-1)*(r(c)-1)
display as text _newline "Also presents gigs, by gig volume:"
tabulate gigpresent gigs, column chi2
local CHI_PG = r(chi2)
local P_PG   = r(p)
local DF_PG  = (r(r)-1)*(r(c)-1)

numadd, key(census_gigs_by_experience_chi2) value(`=string(`CHI_GY',"%9.3f")') ///
    formatted("chi-squared(`DF_GY') = `=strtrim(string(`CHI_GY',"%9.1f"))', p = `=strtrim(string(`P_GY',"%6.3f"))'") ///
    unit("Pearson chi-squared") source("`SRC'") ///
    note("Test of independence between the monthly paid-gig band and years of experience among music creatives. Not distinguishable: gig volume looks flat across career stage in this sample, which cuts against a story in which experience buys work. The p-value assumes simple random sampling, which a self-selected convenience sample is not, so read it as a descriptive discriminant among respondents. `CAV'")
numadd, key(census_presents_by_experience_chi2) value(`=string(`CHI_PY',"%9.3f")') ///
    formatted("chi-squared(`DF_PY') = `=strtrim(string(`CHI_PY',"%9.1f"))', p = `=strtrim(string(`P_PY',"%6.3f"))'") ///
    unit("Pearson chi-squared") source("`SRC'") ///
    note("Test of independence between also presenting or promoting gigs and years of experience. Not distinguishable. Association only; the p-value assumes a random sample. `CAV'")
numadd, key(census_presents_by_gigs_chi2) value(`=string(`CHI_PG',"%9.3f")') ///
    formatted("chi-squared(`DF_PG') = `=strtrim(string(`CHI_PG',"%9.1f"))', p = `=strtrim(string(`P_PG',"%6.3f"))'") ///
    unit("Pearson chi-squared") source("`SRC'") ///
    note("Test of independence between also presenting or promoting gigs and the monthly paid-gig band. Creatives who play more also promote more. Association, not causation, and the p-value assumes a random sample. `CAV'")

quietly count if sector == 1 & gigs < .
local ngc = r(N)
cpct, key(census_gigs_item_from_creatives) value(`=100*`ngc'/`NG'') source("`SRC'") ///
    note("Share of the gig-volume respondents whose primary sector is Music Creative. Because it is essentially 100 percent, a sector cross-tabulation of any creatives-block item carries no information and none is published here. Years of experience and business structure are the usable splits inside that block. `CAV'")


* =========================== 5. THE COST SIDE, IN 2025 DOLLARS (FIGURE 27) ==
* The census collected exactly one dollar quantity from creatives, and it is a
* cost. That makes it the missing half of the Census Bureau Nonemployer
* Statistics picture, which reports gross receipts BEFORE any expense.
*
* The published headline of about 10,500 dollars a year is a SUM OF EIGHT
* CATEGORY MEANS, each computed on a different set of respondents. It is
* replicated here, then set beside the two per-respondent totals a reader would
* more naturally assume it to be.

preserve
    use "${OUT}/cpi_annual.dta", clear
    quietly summarize defl if year == 2022, meanonly
    global DEFL22 = r(mean)
restore
display as text _newline "CPI-U factor, 2022 nominal to 2025 dollars: ${DEFL22}"

tempname spf
tempfile sptab
postfile `spf' int catid str30 catlab int n double mean_nom double med_nom ///
    double p75_nom double mean_real double med_real double p75_real using `sptab', replace
local summeans = 0
forvalues k = 1/8 {
    local L : word `k' of `SPL'
    quietly summarize sp`k', detail
    local summeans = `summeans' + r(mean)
    post `spf' (`k') ("`L'") (r(N)) (r(mean)) (r(p50)) (r(p75)) ///
        (r(mean)*${DEFL22}) (r(p50)*${DEFL22}) (r(p75)*${DEFL22})
}
postclose `spf'

cusd, key(census_spend_sumofmeans_2022) value(`summeans') unit("2022 dollars") source("`SRC'") ///
    note("Sum of the eight category MEANS, each on its own base of between 611 and 742 creatives. This reproduces the published average annual spend of about 10,500 dollars (Data Appendix p.46) to within 1 percent, and shows what that headline is: an addition of eight separately based averages, not the mean of any single respondent total. `CAV'")
cusd, key(census_spend_sumofmeans_2025) value(`=`summeans'*${DEFL22}') source("`SRC'") ///
    note("The same sum of eight category means, inflated from 2022 to 2025 dollars with the CPI-U annual factor from out/cpi_annual.dta. `CAV'")

* Per-respondent totals. Two versions, both stated, because the choice of base
* moves the number by more than the inflation adjustment does.
generate double sptot = 0
forvalues k = 1/8 {
    quietly replace sptot = sptot + cond(missing(sp`k'), 0, sp`k')
}
replace sptot = . if nspend == 0
generate double sptot_real = sptot * ${DEFL22}
label variable sptot_real "Total annual music business spending, 2025 dollars"

quietly count if nspend == 8
local T8N = r(N)
quietly summarize sptot_real if nspend == 8, detail
local T8M   = r(mean)
local T8D   = r(p50)
local T8P25 = r(p25)
local T8P75 = r(p75)
local T8P90 = r(p90)
quietly count if nspend >= 1
local T1N = r(N)
quietly summarize sptot_real if nspend >= 1, detail
local T1M = r(mean)
local T1D = r(p50)

display as text _newline "Total annual spending, 2025 dollars, complete responders only:"
summarize sptot_real if nspend == 8, detail

cnum, key(census_spend_complete_n) value(`T8N') source("`SRC'") ///
    note("Music creatives who gave a figure for all eight spending categories. This is the only base on which a per-respondent total is complete, and it is 22.5 percent of the 2,227 respondents. `CAV'")
cusd, key(census_spend_total_mean) value(`T8M') source("`SRC'") ///
    note("MEAN total annual spending on their own music work, 2025 dollars, all eight categories, `T8N' creatives who answered every category. The published 10,500-dollar headline is a sum of category means on eight different bases and is NOT this number. `CAV'")
cusd, key(census_spend_total_median) value(`T8D') source("`SRC'") ///
    note("MEDIAN total annual spending on their own music work, 2025 dollars, `T8N' creatives who answered every category. It is roughly half the mean, because the distribution is severely right-skewed. This is the number to quote for a typical creative. `CAV'")
cusd, key(census_spend_total_p25) value(`T8P25') source("`SRC'") ///
    note("25th percentile of total annual spending, 2025 dollars, `T8N' creatives answering all eight categories. `CAV'")
cusd, key(census_spend_total_p75) value(`T8P75') source("`SRC'") ///
    note("75th percentile of total annual spending, 2025 dollars, `T8N' creatives answering all eight categories. `CAV'")
cusd, key(census_spend_total_p90) value(`T8P90') source("`SRC'") ///
    note("90th percentile of total annual spending, 2025 dollars, `T8N' creatives answering all eight categories. The gap between this and the median is why the report should not lead with a mean. `CAV'")
cusd, key(census_spend_total_mean_anyitem) value(`T1M') source("`SRC'") ///
    note("MEAN total annual spending, 2025 dollars, over the `T1N' creatives who answered at least one category, treating unanswered categories as zero. A deliberate lower bound: some blanks are true zeros and some are simply unanswered, and the release cannot tell them apart. `CAV'")
cusd, key(census_spend_total_median_anyitem) value(`T1D') source("`SRC'") ///
    note("MEDIAN total annual spending, 2025 dollars, `T1N' creatives who answered at least one category, blanks treated as zero. Lower bound, same reason. `CAV'")

numadd, key(census_spend_vs_nes_receipts) value(`T8D') ///
    formatted("the missing cost side of a receipts figure") unit("2025 dollars, median") source("`SRC'") ///
    note("Census Bureau Nonemployer Statistics reports average gross receipts of roughly 32,962 dollars for NAICS 7115 establishments, BEFORE any expense. This census puts median self-reported annual business spending by Austin music creatives at the value in this row and the mean well above it, both 2025 dollars. The two cannot be differenced: different populations, different years, different units - NES counts businesses while the census counts people - and NES misses cash gig work entirely. Use the pairing to show that the expense side is material and unmeasured, never to compute a net figure.")

preserve
use `sptab', clear
gsort -mean_real
export delimited using "${TABDIR}/table_census_spending.csv", replace
export delimited using "${OUT}/fig27_cost_of_working.csv", replace
display as text _newline "Annual spending by category, 2025 dollars:"
list catlab n mean_real med_real p75_real, noobs sep(0) abbreviate(16)

forvalues i = 1/`=_N' {
    local L = catlab[`i']
    keyify, text("`L'")
    local kk = r(key)
    local nn = n[`i']
    cusd, key(census_spend_mean_`kk') value(`=mean_real[`i']') source("`SRC'") ///
        note("Mean annual spending on `L', 2025 dollars, `nn' music creatives who answered this category. `CAV'")
    cusd, key(census_spend_median_`kk') value(`=med_real[`i']') source("`SRC'") ///
        note("Median annual spending on `L', 2025 dollars, `nn' music creatives who answered this category. `CAV'")
}

generate double ypos = _N - _n + 1
generate double y1 = ypos + 0.18
generate double y2 = ypos - 0.18
generate str12 lm = strtrim(string(round(mean_real), "%12.0fc"))
generate str12 ld = strtrim(string(round(med_real), "%12.0fc"))

local ylab ""
forvalues i = 1/`=_N' {
    local L = catlab[`i']
    local N = strtrim(string(n[`i'], "%9.0fc"))
    local Y = ypos[`i']
    local ylab `"`ylab' `Y' "`L' (n = `N')""'
}

twoway (bar mean_real y1, horizontal barwidth(0.34) color("${NAVY}") lwidth(none)) ///
       (bar med_real y2, horizontal barwidth(0.34) color("${ORANGE}") lwidth(none)) ///
       (scatter y1 mean_real, msymbol(none) mlabel(lm) mlabcolor("${NAVY}") ///
            mlabsize(2.1) mlabposition(3) mlabgap(1.1)) ///
       (scatter y2 med_real, msymbol(none) mlabel(ld) mlabcolor("${ORANGE}") ///
            mlabsize(2.1) mlabposition(3) mlabgap(1.1)) ///
       , title("Recording is the largest cost of working, on the mean and the median", $TITLEOPT) ///
         subtitle("Annual spending on their own music work, 2025 dollars; music creatives only, 2022 Greater" ///
                  "Austin Music Census. Self-selected sample, no weights; each category has its own base.", $SUBOPT) ///
         ylabel(`ylab', angle(0) labsize(2.5) notick nogrid) ytitle("") ///
         yscale(range(0.4 `=_N+0.6')) ///
         xlabel(0(1000)4000, format(%12.0fc) labsize(2.8)) xscale(range(0 4900)) ///
         xtitle("2025 dollars a year", size(2.8)) ///
         legend(order(1 "Mean" 2 "Median") rows(1) position(6) $LEGOPT) ///
         graphregion(color(white)) plotregion(margin(l=0)) ///
         ysize(4.4) xsize(7.2)
figsave, name(fig27_cost_of_working)
restore

quietly summarize localspend, detail
cpct, key(census_spend_share_local) value(`=r(mean)') source("`SRC'") ///
    note("Mean self-reported percent of annual music business spending that goes to providers inside the Austin area, `=r(N)' creatives; median `=strtrim(string(r(p50),"%4.0f"))' percent. Replicates the published 60 percent. This is the channel through which a creative expense becomes local economic activity, and it is the only local-multiplier quantity the census measured. `CAV'")


* ================================ 6. RETENTION - THE HEADLINE (FIGURE 26) ==
* The 89 / 64 pair is already public. Who the 36 percent are is not, and that is
* what this section adds.

quietly count if contmusic < .
local NRET = r(N)
quietly count if contmusic == 1
local PCONT = 100*r(N)/`NRET'
quietly count if contdef == 1
local PCONTD = 100*r(N)/`NRET'
quietly count if stayaus < .
local NSTAY = r(N)
quietly count if stayaus == 1
local PSTAY = 100*r(N)/`NSTAY'
quietly count if staydef == 1
local PSTAYD = 100*r(N)/`NSTAY'
local GAP = `PCONT' - `PSTAY'

display as text _newline "Retention pair: continue " %5.1f `PCONT' "%, stay " %5.1f `PSTAY' "%, base `NRET'"

cnum, key(census_retention_denom) value(`NRET') source("`SRC'") ///
    note("Respondents answering the three-year intent items. Both items have exactly the same `NRET' answers out of 2,227, so the 89 and the 64 rest on an identical base and the gap between them is a within-person comparison rather than a comparison of two different groups. `CAV'")
cpct, key(census_intend_continue_music) value(`PCONT') source("`SRC'") ///
    note("Share intending to continue their music work over the next three years - definitely yes plus maybe yes - `NRET' respondents. Verifies the published 89 percent (Summary Report printed p.7). KUT reported 84 percent; use 89 and cite the report, not the coverage. `CAV'")
cpct, key(census_intend_continue_definitely) value(`PCONTD') source("`SRC'") ///
    note("Share answering DEFINITELY yes to continuing music work, `NRET' respondents. The published 89 percent folds in maybe yes; this is the firm part of it. `CAV'")
cpct, key(census_intend_stay_austin) value(`PSTAY') source("`SRC'") ///
    note("Share intending to still live in greater Austin in three years - definitely yes plus maybe yes - `NSTAY' respondents. Verifies the published 64 percent (Summary Report printed p.7). The 36 percent complement is mostly uncertainty rather than a stated intention to leave: unsure 25.6 points, maybe no 6.7, definitely no 3.6. Say so whenever the 36 percent is quoted. `CAV'")
cpct, key(census_intend_stay_definitely) value(`PSTAYD') source("`SRC'") ///
    note("Share answering DEFINITELY yes to still living in greater Austin in three years, `NSTAY' respondents. Below half. `CAV'")
numadd, key(census_retention_gap) value(`=string(`GAP',"%9.4f")') ///
    formatted("`=strtrim(string(`GAP',"%9.1f"))' points") unit("percentage points") source("`SRC'") ///
    note("Gap between the share intending to continue in music and the share intending to stay in greater Austin, on the same `NRET' respondents. The Summary Report reads it as a third of the ecosystem considering leaving the metro entirely. `CAV'")

* --- subgroup breakouts and independence tests ---------------------------
tempname rtf
tempfile rttab
postfile `rtf' str30 varlab str40 grouplab int n double pct_stay int n_cont ///
    double pct_continue double chi2 double pval int df using `rttab', replace

capture program drop retbreak
program define retbreak
    syntax varname(numeric), RTF(string) VARLAB(string)
    quietly tabulate `varlist' stayaus, chi2
    local c = r(chi2)
    local p = r(p)
    local d = (r(r)-1)*(r(c)-1)
    quietly levelsof `varlist', local(gl)
    foreach g of local gl {
        quietly count if `varlist' == `g' & stayaus < .
        local n = r(N)
        quietly count if `varlist' == `g' & stayaus == 1
        local ps = 100*r(N)/`n'
        quietly count if `varlist' == `g' & contmusic < .
        local nc = r(N)
        quietly count if `varlist' == `g' & contmusic == 1
        local pc = 100*r(N)/`nc'
        local lab : label (`varlist') `g'
        post `rtf' ("`varlab'") ("`lab'") (`n') (`ps') (`nc') (`pc') (`c') (`p') (`d')
    }
end

retbreak sector3,  rtf(`rtf') varlab("Primary sector")
retbreak yrsexp,   rtf(`rtf') varlab("Years of experience")
retbreak liveconc, rtf(`rtf') varlab("Music income from local gigs")
retbreak wspace,   rtf(`rtf') varlab("Work space status")
retbreak tenure,   rtf(`rtf') varlab("Housing tenure")
retbreak insured,  rtf(`rtf') varlab("Health insurance")
postclose `rtf'

preserve
use `rttab', clear
export delimited using "${TABDIR}/table_census_retention_subgroups.csv", replace
display as text _newline "Intent to stay in greater Austin, by subgroup:"
list varlab grouplab n pct_stay pct_continue chi2 pval, noobs sep(0) abbreviate(18)

forvalues i = 1/`=_N' {
    local vl = varlab[`i']
    local gl = grouplab[`i']
    keyify, text("`vl' `gl'")
    local kk = r(key)
    local nn = strtrim(string(n[`i'], "%9.0fc"))
    cpct, key(census_stay_`kk') value(`=pct_stay[`i']') source("`SRC'") ///
        note("Share intending to still live in greater Austin in three years among the `nn' respondents in the group `gl' (breakout variable: `vl') who answered the item. `CAV'")
}
quietly levelsof varlab, local(vls)
foreach v of local vls {
    quietly summarize chi2 if varlab == "`v'", meanonly
    local c = r(mean)
    quietly summarize pval if varlab == "`v'", meanonly
    local p = r(mean)
    quietly summarize df if varlab == "`v'", meanonly
    local d = r(mean)
    keyify, text("`v'")
    local kk = r(key)
    numadd, key(census_staychi2_`kk') value(`=string(`c',"%9.3f")') ///
        formatted("chi-squared(`=strtrim(string(`d',"%2.0f"))') = `=strtrim(string(`c',"%9.1f"))', p = `=strtrim(string(`p',"%6.4f"))'") ///
        unit("Pearson chi-squared") source("`SRC'") ///
        note("Test of independence between intending to stay in greater Austin and `v'. Report as association, never as causation. The p-value assumes simple random sampling; this is a self-selected convenience sample, so treat the test as a descriptive discriminant among respondents rather than inference to the Austin music workforce. `CAV'")
}
restore

* --- the logits -----------------------------------------------------------
* Three nested models, so a reader can see what the requested covariates do
* before and after housing and insurance enter, and how much sample each costs.
eststo clear
quietly eststo m1: logit stayaus i.sector3 i.yrsexp
quietly eststo m2: logit stayaus i.sector3 i.yrsexp i.tenure i.insured
quietly eststo m3: logit stayaus i.yrsexp i.tenure i.insured i.liveconc i.wspace if sector == 1
esttab m1 m2 m3 using "${TABDIR}/table_census_retention_logit.csv", replace csv ///
    eform b(3) se(3) label nogaps ///
    stats(N ll r2_p, fmt(0 2 3) labels("Respondents" "Log likelihood" "Pseudo R-squared")) ///
    title("Odds of intending to stay in greater Austin, 2022 Greater Austin Music Census") ///
    addnotes("Odds ratios. Self-selected convenience sample, no survey weights; association only, not causal." ///
             "M1 all respondents. M2 adds housing tenure and health insurance. M3 music creatives only.")
display as text _newline "Retention logits written to out/tables/table_census_retention_logit.csv"
esttab m1 m2 m3, eform b(3) se(3) label nogaps stats(N ll r2_p, fmt(0 2 3))

quietly logit stayaus i.sector3 i.yrsexp i.tenure i.insured
local NLOG = e(N)
quietly lincom 2.tenure, eform
local ORREN = r(estimate)
local PREN  = r(p)
numadd, key(census_logit_renter_or) value(`=string(`ORREN',"%9.4f")') ///
    formatted("`=strtrim(string(`ORREN',"%9.2f"))'") unit("odds ratio") source("`SRC'") ///
    note("Odds ratio on renting, relative to owning, in a logit of intending to stay in greater Austin on primary sector, years of experience, housing tenure and health insurance. `NLOG' respondents, p = `=strtrim(string(`PREN',"%6.4f"))'. Association only: tenure is not randomly assigned, and income, age and family stage all move with it. None of those can be controlled for, because the census collected no income variable and age is missing for 28 percent of respondents. `CAV'")
cnum, key(census_logit_n) value(`NLOG') source("`SRC'") ///
    note("Estimation sample for the retention logit that includes housing tenure and insurance. It is smaller than the 1,900 who answered the retention item, because tenure and insurance are themselves unevenly answered. `CAV'")

* --- FIGURE 26 -------------------------------------------------------------
* Housing tenure is the breakout that discriminates most, by a wide margin: a
* 23-point spread and much the largest chi-squared of the six tested. It is also
* the one the brief did not ask for, so the four requested breakouts stay in
* table_census_retention_subgroups.csv and in the registry.
preserve
use `rttab', clear
keep if varlab == "Housing tenure"
gsort -pct_stay
local NROW = _N
set obs `=`NROW'+1'
replace varlab       = "All"             in `=`NROW'+1'
replace grouplab     = "All respondents" in `=`NROW'+1'
replace n            = `NSTAY'           in `=`NROW'+1'
replace pct_stay     = `PSTAY'           in `=`NROW'+1'
replace pct_continue = `PCONT'           in `=`NROW'+1'

generate double ypos = 4 - _n
replace ypos = 4.25 if varlab == "All"

* Round each endpoint once, then derive the gap label from those SAME
* rounded values rather than from the unrounded difference. Two independently
* rounded endpoints do not always subtract to what their unrounded difference
* rounds to (Homeowner: 75.46 -> 75 and 91.95 -> 92 subtract to 17, while the
* unrounded gap 16.49 itself rounds to 16), and a reader can catch that kind
* of mismatch just by subtracting the two printed numbers. Deriving the gap
* from the rounded endpoints keeps the three printed numbers self-consistent
* on every row; it changes only the displayed gap label, never the
* underlying pct_stay or pct_continue values, their marker positions, or the
* logit/chi-squared results computed earlier from the unrounded shares.
generate double pct_stay_r     = round(pct_stay)
generate double pct_continue_r = round(pct_continue)
generate str8 ls = strtrim(string(pct_stay_r, "%4.0f")) + "%"
generate str8 lc = strtrim(string(pct_continue_r, "%4.0f")) + "%"
generate str10 gaplab = strtrim(string(pct_continue_r - pct_stay_r, "%4.0f")) + " points"
generate double xgap = (pct_stay + pct_continue)/2
generate double ygap = ypos + 0.30

local ylab ""
forvalues i = 1/`=_N' {
    local L = grouplab[`i']
    local N = strtrim(string(n[`i'], "%9.0fc"))
    local Y = ypos[`i']
    local ylab `"`ylab' `Y' "`L' (n = `N')""'
}

export delimited grouplab n pct_stay pct_continue chi2 pval ///
    using "${OUT}/fig26_retention_split.csv", replace

twoway (rspike pct_stay pct_continue ypos, horizontal lcolor("${MUTED}") lwidth(medthick)) ///
       (scatter ypos pct_continue, msymbol(O) mcolor("${NAVY}") msize(2.4) ///
            mlabel(lc) mlabcolor("${NAVY}") mlabsize(2.5) mlabposition(3) mlabgap(1.3)) ///
       (scatter ypos pct_stay, msymbol(D) mcolor("${ORANGE}") msize(2.4) ///
            mlabel(ls) mlabcolor("${ORANGE}") mlabsize(2.5) mlabposition(9) mlabgap(1.3)) ///
       (scatter ygap xgap, msymbol(none) mlabel(gaplab) mlabcolor("${MUTED}") ///
            mlabsize(2.2) mlabposition(0)) ///
       , title("Nearly all will stay in music; renters least expect to stay in Austin", $TITLEOPT) ///
         subtitle("Share answering definitely or maybe yes to continuing music work, and to living in greater" ///
                  "Austin, three years on. 2022 census; self-selected, no weights; axis does not start at zero.", $SUBOPT) ///
         ylabel(`ylab', angle(0) labsize(2.7) notick nogrid) ytitle("") ///
         yscale(range(0.4 4.85)) ///
         xlabel(40(10)100, format(%3.0f) labsize(2.8)) xscale(range(40 102)) ///
         xtitle("Percent of respondents answering the item", size(2.8)) ///
         legend(order(2 "Will continue music work" 3 "Will still live in greater Austin") ///
                rows(1) position(6) $LEGOPT) ///
         graphregion(color(white)) plotregion(margin(l=0)) ///
         ysize(3.9) xsize(7.2)
figsave, name(fig26_retention_split)
restore


* ============================== 7. THE VENUE SIDE (FIGURE 28) ==============
* The presenter block is answered by 177 respondents, above this reports
* 50-record floor, so it is published. The operator-versus-promoter split that
* the Data Appendix publishes is NOT reproduced: the promoter cell is 42.

quietly count if prs1 < .
local NPRS = r(N)
quietly count if prestype == 1
local NVOP = r(N)
quietly count if prestype == 2
local NIPR = r(N)

cnum, key(census_n_presenters_ranking) value(`NPRS') source("`SRC'") ///
    note("Respondents who completed the nine-item ranking of business pressures. Above the 50-record floor in aggregate, so it is published, but it is 8 percent of the survey and the thinnest block in this module. Only 77 of the 108 respondents whose PRIMARY sector is venue or presenter answered it; the other 100 are creatives and industry professionals who also present gigs, so this is a presenter-activity population, not a venue census. `CAV'")
cnum, key(census_n_venue_operators) value(`NVOP') source("`SRC'") ///
    note("Presenters reporting a numeric legal capacity band, that is, operators of a physical room. `CAV'")
cnum, key(census_n_independent_promoters) value(`NIPR') source("`SRC'") ///
    note("Presenters identifying as independent promoters rather than room operators. Below the 50-record floor, so no statistic is published for this group alone and the Data Appendix operator-versus-promoter split (slides 56 and 57) is not reproduced. `CAV'")

quietly count if cap < .
local NCAP = r(N)
display as text _newline "Venue legal capacity distribution, n = `NCAP':"
tabulate cap
forvalues c = 1/6 {
    quietly count if cap == `c'
    local nc = r(N)
    local L : label capl `c'
    cpct, key(census_venue_capacity_`c') value(`=100*`nc'/`NCAP'') source("`SRC'") ///
        note("Share of responding venue operators whose legal capacity is `L': `nc' of `NCAP' operators who gave a capacity band. Individual cells run as low as 8 records, so read the distribution as a whole and do not quote a single band on its own. `CAV'")
}
quietly count if inlist(cap, 1, 2)
local NSMALL = r(N)
cpct, key(census_venue_capacity_under200) value(`=100*`NSMALL'/`NCAP'') source("`SRC'") ///
    note("Share of responding venue operators with a legal capacity of 200 or fewer: `NSMALL' of `NCAP'. Small rooms are the modal responding venue, which matters because the fixed costs those same respondents rank highest - property tax, building operations - do not scale down with capacity. `CAV'")

tempname prf
tempfile prtab
postfile `prf' int pid str34 plab int n double pct_first double pct_top3 double meanrank using `prtab', replace
forvalues k = 1/9 {
    local L : word `k' of `PRSL'
    quietly count if prs`k' < .
    local n = r(N)
    quietly count if prs`k' == 1
    local f = 100*r(N)/`n'
    quietly count if inrange(prs`k', 1, 3)
    local t = 100*r(N)/`n'
    quietly summarize prs`k', meanonly
    post `prf' (`k') ("`L'") (`n') (`f') (`t') (r(mean))
}
postclose `prf'

preserve
use `prtab', clear
gsort -pct_top3
export delimited using "${TABDIR}/table_census_venue_pressures.csv", replace
export delimited using "${OUT}/fig28_venue_pressures.csv", replace
display as text _newline "Presenter pressure ranking, n = `NPRS':"
list plab n pct_first pct_top3 meanrank, noobs sep(0) abbreviate(22)

forvalues i = 1/`=_N' {
    local L = plab[`i']
    keyify, text("`L'")
    local kk = r(key)
    cpct, key(census_pressure_top3_`kk') value(`=pct_top3[`i']') source("`SRC'") ///
        note("Share of the `NPRS' responding presenters who ranked `L' among their three greatest business pressures. Nine items, each respondent ranked all nine, so the nine top-three shares sum to about 300 percent. Venue operators and independent promoters are pooled because the promoter cell is 42 records. `CAV'")
    cpct, key(census_pressure_first_`kk') value(`=pct_first[`i']') source("`SRC'") ///
        note("Share of the `NPRS' responding presenters who ranked `L' their single greatest business pressure. The nine first-place shares sum to 100 percent. `CAV'")
}

generate double zero = 0
generate double ypos = _N - _n + 1
* Total (top-3) value label at each bar end, for consistency with the other
* nine bar charts in this report, all of which carry value labels.
generate str8 lbltot = strtrim(string(pct_top3, "%4.0f")) + "%"
local ylab ""
forvalues i = 1/`=_N' {
    local L = plab[`i']
    local Y = ypos[`i']
    local ylab `"`ylab' `Y' "`L'""'
}

twoway (rbar pct_first pct_top3 ypos, horizontal barwidth(0.58) color("${MUTED}") lwidth(none)) ///
       (rbar zero pct_first ypos, horizontal barwidth(0.58) color("${ORANGE}") lwidth(none)) ///
       (scatter ypos pct_top3, msymbol(none) mlabel(lbltot) mlabcolor("${TEXTC}") ///
            mlabsize(2.4) mlabposition(3) mlabgap(1.1)) ///
       , title("More presenters rank property tax a top-three pressure than any other", $TITLEOPT) ///
         subtitle("Share ranking each of nine business pressures in their top three, top-ranked share in orange." ///
                  "177 Austin venue operators and promoters, 2022 census; self-selected sample, no weights.", $SUBOPT) ///
         ylabel(`ylab', angle(0) labsize(2.6) notick nogrid) ytitle("") ///
         yscale(range(0.4 9.6)) ///
         xlabel(0(10)50, format(%3.0f) labsize(2.8)) xscale(range(0 58)) ///
         xtitle("Percent of responding presenters", size(2.8)) ///
         legend(order(2 "Ranked first" 1 "Ranked second or third") rows(1) position(6) $LEGOPT) ///
         graphregion(color(white)) plotregion(margin(l=0)) ///
         ysize(4.2) xsize(7.2)
figsave, name(fig28_venue_pressures)
restore

* --- compare the ranking with what the receipts panel actually recorded ----
* 30_venues writes out/venue_closure_reasons.csv. If it has not been run, the
* comparison is skipped rather than guessed at.
capture confirm file `"${OUT}/venue_closure_reasons.csv"'
if _rc == 0 {
    preserve
    import delimited using "${OUT}/venue_closure_reasons.csv", clear varnames(1) case(preserve)
    quietly summarize n_closures, meanonly
    local NCLOS = r(sum)
    quietly summarize n_closures if inlist(reason_category, "sale_of_property", ///
        "rent_increase", "lease_expiration", "redevelopment"), meanonly
    local NPROP = r(sum)
    quietly summarize n_closures if reason_category == "covid", meanonly
    local NCOVID = r(sum)
    quietly summarize n_closures if reason_category == "permit_regulatory", meanonly
    local NPERM = r(sum)
    restore
    cpct, key(census_closures_property_share) value(`=100*`NPROP'/`NCLOS'') ///
        source("01_evidence/08_venues_ecosystem/venue_timeline.csv") ///
        note("Share of the `NCLOS' dated Austin venue closures in the 30_venues tracking panel attributed to a real-estate cause - sale of the property, a rent increase, lease expiration or redevelopment. It equals the pandemic share (`NCOVID' closures) and it AGREES with the census ranking, in which presenters put property tax first. Regulatory causes account for only `NPERM' closures, which also matches the mid-pack rank the census gives ordinances and permitting. The one item that does not line up is talent costs, ranked second by presenters but recorded as the cause of no closure at all - the receipts panel has no talent-cost field, so that is untested rather than contradicted. Both sources are small and neither is a probability sample.")
}
else {
    display as text "  venue_closure_reasons.csv absent - run 30_venues.do first for the closure comparison."
}


* ================================================ 8. CAVEATS, ON THE RECORD ==
* Registered so they travel with the numbers into the report rather than living
* only in this file.

numadd, key(census_caveat_selfselected) value(1) formatted("self-selected convenience sample") ///
    unit("flag") source("`SRC'") ///
    note("The 2022 Greater Austin Music Census recruited online through community partners between 15 July and 12 September 2022. It is not a probability sample of any population. Every percentage in this module is a share of the respondents who answered a given item, and nothing more.")
numadd, key(census_caveat_noweights) value(1) formatted("no survey weights") ///
    unit("flag") source("`SRC'") ///
    note("The release carries no design or post-stratification weights, so no statistic here is a population estimate, and no standard error or margin of error is computed anywhere in this module. Chi-squared tests and logits describe association among respondents; their p-values assume simple random sampling, which does not hold.")
numadd, key(census_caveat_nofollowup) value(1) formatted("single 2022 snapshot") ///
    unit("flag") source("`SRC'") ///
    note("One cross-section with no comparable follow-up. Austin appears in the Sound Music Cities 2023-24 cohort roster but published no later report, so nothing here can speak to change since 2022.")
numadd, key(census_caveat_notacs) value(1) formatted("not comparable with ACS or PUMS") ///
    unit("flag") source("`SRC'") ///
    note("Do not set these percentages beside the ACS, PUMS, OEWS or QCEW figures elsewhere in this report as though they measure the same population. The census population is self-defined participation in the Austin music ecosystem; the federal series measure occupation or industry in probability samples of households and establishments.")
numadd, key(census_caveat_2014comparison) value(1) formatted("2014 comparisons are directional") ///
    unit("flag") source("`SRC'") ///
    note("Where the 2014 census asked a comparable question, the comparison runs between two different self-selected samples eight years apart, with response falling from 3,968 to about 2,260 and 2022 outreach running through established community partners. The 2022 report itself calls these directional shifts, not estimates.")
numadd, key(census_caveat_nodollarincome) value(1) formatted("no dollar income variable") ///
    unit("flag") source("`SRC'") ///
    note("The instrument contains no dollar-denominated income question of any kind - annual, monthly or per gig. The share-of-income scale used in section 3 is ordinal and within-music. The only dollar quantity collected from creatives is business spending, which is a cost.")
numadd, key(census_caveat_slide41) value(1) formatted("published slide 41 mislabels four bars") ///
    unit("flag") source("`SRC'") ///
    note("Two published sources disagree about which income source goes with which value. The microdata, the Socrata column dictionary for dataset an3p-3yqx and the five-segment distributions on Data Appendix slide 40 all agree that the 2022 shares reporting any income from a source are: local live 92.4, touring 75.3, recordings and royalties 70.7, studio work 57.8, merchandise 56.1, songwriting 51.0, teaching 41.0. Data Appendix slide 41 plots the same seven values but labels four of them differently, reading merchandise 71.0, recordings 58.0, teaching 56.0 and studio 41.0. This module follows the microdata and slide 40, which are two independent sources against slide 41 alone. Anyone quoting a 2014-to-2022 change in these shares should note that the 2014 bars appear only on slide 41 and cannot be checked against microdata.")
numadd, key(census_caveat_rowcount) value(2227) formatted("2,227 rows, not 2,260") ///
    unit("flag") source("`SRC'") ///
    note("The published microdata file carries 2,227 respondent rows; the Summary Report and Data Appendix headline 2,260. The 33-row difference is undocumented in the release. All shares in this module use the 2,227-row file, so they can sit a few tenths of a point away from a published percentage even where the underlying counts agree.")

display as text _newline "80_census_microdata.do complete"
