********************************************************************************
* FINAL CROSS-COUNTRY FORENSIC AUDIT: RESOLVING ALL ERRORS
********************************************************************************
clear all
set more off

* 1. PROCESS 20-COUNTRY WORLD BANK DATA (Grid Proxy)
* ------------------------------------------------------------------------------
cd "C:\Users\adamc\Desktop\Diss\Data\Other Countries Electricity Consumption and GDP\P_Data_Extract_From_World_Development_Indicators"
import delimited "GDP and Electricity Consumption for Control.csv", clear varnames(1)

* Clean Series Codes
replace seriescode = "gdp_growth" if seriescode == "NY.GDP.MKTP.KD.ZG"
replace seriescode = "elec_cons"  if seriescode == "EG.USE.ELEC.KH.PC"
replace seriescode = subinstr(seriescode, ".", "_", .)
drop if seriescode == "" | countrycode == ""

* BRACE FIX: Ensure no code follows the "{" on the same line
foreach v of varlist _all {
    local lbl : var label `v'
    if strpos("`lbl'", "[YR") > 0 {
        local year = substr("`lbl'", 1, 4)
        if `year' >= 2001 & `year' <= 2022 {
            rename `v' yr`year'
        }
        else {
            drop `v'
        }
    }
}

reshape long yr, i(countrycode seriescode) j(year)
rename yr value
destring value, replace force
drop seriesname
reshape wide value, i(countrycode year) j(seriescode) string
rename value* *

* Calculate Electricity Growth (FIXED SORT)
encode countrycode, gen(id_num)
sort id_num year
tsset id_num year
gen elec_growth = ((elec_cons - l.elec_cons) / l.elec_cons) * 100
tempfile master_panel
save `master_panel'

* 2. PROCESS VIIRS DATA (Satellite Proxy)
* ------------------------------------------------------------------------------
cd "C:\Users\adamc\Desktop\Diss\Data\Raw Sunlight"
import delimited "VIIRS-nighttime-lights-2013m1to2024m5-level0.csv", clear
rename iso countrycode
collapse (sum) nlsum, by(countrycode year)

* Encode and Sort VIIRS Data separately
encode countrycode, gen(id_v)
sort id_v year
tsset id_v year
gen nl_growth = ((nlsum - l.nlsum) / l.nlsum) * 100
tempfile viirs_data
save `viirs_data'

* 3. PROCESS REGIME DATA (FIXING R(459) DUPLICATES)
* ------------------------------------------------------------------------------
cd "C:\Users\adamc\Desktop\Diss\Data\political-regime"
import delimited "political-regime.csv", clear
rename code countrycode
rename politicalregime regime_score
drop if countrycode == ""

* Remove duplicates to prevent merge error r(459)
sort countrycode year
duplicates drop countrycode year, force
tempfile regime_data
save `regime_data'

* 4. MASTER MERGE AND INTERACTIONS
* ------------------------------------------------------------------------------
use `master_panel', clear
merge 1:1 countrycode year using `viirs_data', keep(master match) nogenerate
merge m:1 countrycode year using `regime_data', keep(master match) nogenerate

* Define IMF Recipients and Autocrats
gen is_autocrat = (regime_score <= 1)
gen is_imf = 0
foreach c in PAK EGY JOR KEN AGO ARG LKA TUR SUR GAB {
    replace is_imf = 1 if countrycode == "`c'"
}

* Create Interactions
gen elec_x_auth = elec_growth * is_autocrat
gen elec_x_imf  = elec_growth * is_imf
gen nl_x_auth   = nl_growth   * is_autocrat
gen nl_x_imf    = nl_growth    * is_imf

* 5. GENERATE FINAL COMPARISON TABLE
* ------------------------------------------------------------------------------
* Model 1: The Internal Audit (Grid)
xtreg gdp_growth elec_growth elec_x_auth elec_x_imf, fe robust
eststo model_elec

* Model 2: The External Audit (Satellite)
xtreg gdp_growth nl_growth nl_x_auth nl_x_imf if year >= 2013, fe robust
eststo model_viirs

esttab model_elec model_viirs using "Final_IMF_Audit_Results.rtf", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Electricity (Grid)" "Nightlights (Satellite)") ///
    stats(r2_w N, labels("Within R-sq" "Obs"))