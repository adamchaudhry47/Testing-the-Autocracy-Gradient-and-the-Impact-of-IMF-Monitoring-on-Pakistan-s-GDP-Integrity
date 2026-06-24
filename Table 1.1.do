********************************************************************************
* PAKISTAN CASE STUDY: DUAL-PROXY FORENSIC AUDIT (ELEC & VIIRS)
********************************************************************************
clear all
set more off

* 0. INSTALL REQUIRED PACKAGES
capture ssc install estout, replace

* ------------------------------------------------------------------------------
* 1. PROCESS BASELINE GDP DATA (2001-2022)
* ------------------------------------------------------------------------------
cd "C:\Users\adamc\Desktop\Diss\Data\Other Countries Electricity Consumption and GDP\P_Data_Extract_From_World_Development_Indicators"
import delimited "GDP and Electricity Consumption for Control.csv", clear varnames(1)

replace seriescode = "gdp_growth" if seriescode == "NY.GDP.MKTP.KD.ZG"
keep if countrycode == "PAK" & seriescode == "gdp_growth"

foreach v of varlist _all {
    local lbl : var label `v'
    if strpos("`lbl'", "[YR") > 0 {
        local year = substr("`lbl'", 1, 4)
        if `year' >= 2001 & `year' <= 2022 {
            rename `v' yr`year'
        }
    }
}

reshape long yr, i(seriescode) j(year)
rename yr gdp_growth
destring gdp_growth, replace force

* Add 1999 & 2000 GDP Growth
set obs `=_N + 2'
replace year = 1999 in -2
replace gdp_growth = 3.66 in -2
replace year = 2000 in -1
replace gdp_growth = 4.26 in -1

tempfile master_gdp
save `master_gdp'

* ------------------------------------------------------------------------------
* 2. REGRESSION 1: ELECTRICITY AUDIT (1999-2022)
* ------------------------------------------------------------------------------
cd "C:\Users\adamc\Desktop\Diss\Data\Pakistan Electricity Consumption"
import delimited "ElectricityConsumption.csv", clear varnames(5) rowrange(5)
keep if countrycode == "PAK"

foreach v of varlist _all {
    local lbl : var label `v'
    if real("`lbl'") >= 1998 & real("`lbl'") <= 2022 {
        rename `v' yr`lbl'
    }
}

keep yr1998-yr2022
gen country = "PAK"
reshape long yr, i(country) j(year)
rename yr elec_cons
destring elec_cons, replace force

merge 1:1 year using `master_gdp', keep(match) nogenerate
tsset year
gen elec_growth = ((elec_cons - l.elec_cons) / l.elec_cons) * 100

* Run and Store
reg elec_growth gdp_growth if year >= 1999 & year <= 2022, robust
    test gdp_growth = 1
    eststo model_elec
    estadd scalar p_wald = r(p)

* ------------------------------------------------------------------------------
* 3. REGRESSION 2: VIIRS NIGHTLIGHTS AUDIT (2013-2022)
* ------------------------------------------------------------------------------
cd "C:\Users\adamc\Desktop\Diss\Data\Raw Sunlight"
import delimited "VIIRS-nighttime-lights-2013m1to2024m5-level0.csv", clear
keep if iso == "PAK"
collapse (sum) nlsum, by(year)
keep if year <= 2022

* Merge with Master GDP
merge 1:1 year using `master_gdp', keep(match) nogenerate
tsset year
gen nl_growth = ((nlsum - l.nlsum) / l.nlsum) * 100

* Run and Store
reg nl_growth gdp_growth if year >= 2013 & year <= 2022, robust
    test gdp_growth = 1
    eststo model_viirs
    estadd scalar p_wald = r(p)

* ------------------------------------------------------------------------------
* 4. EXPORT COMBINED TABLE
* ------------------------------------------------------------------------------
esttab model_elec model_viirs using "Pakistan_Dual_Audit_Table.rtf", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) mtitles("Electricity" "Nightlights") ///
    stats(p_wald r2 N, labels("Wald P-value (H0:B=1)" "R-sq" "Obs") fmt(3 3 0)) ///
    title("Table 5.1: Comparative Forensic Audit of Pakistan (Grid vs. Satellite)") ///
    addnotes("Note: Wald P-value > 0.05 indicates statistical reporting honesty.")