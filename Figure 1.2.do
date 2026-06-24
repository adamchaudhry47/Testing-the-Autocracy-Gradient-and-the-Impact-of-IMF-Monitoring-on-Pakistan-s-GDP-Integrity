clear all
set more off

* 1. PREPARE GDP DATA (The "Using" Data)
use "C:\Users\adamc\Desktop\Diss\Data\Pakistan GDP and other metrics\API_PAK_DS2_en_csv_v2_3451\Cleaned_GDP_Data.dta", clear
replace year = round(year)

* Add 2023 GDP Growth estimate (-0.17%)
set obs `=_N+1'
replace year = 2023 in L
replace gdp_growth = -0.17 in L

* --- THE FIX FOR "USING DATA" ERROR ---
* This ensures that if 2023 already existed, we don't have two of them
duplicates drop year, force
* --------------------------------------

save "temp_gdp_for_merge.dta", replace

* 2. PREPARE ELECTRICITY DATA (The "Master" Data)
import delimited "C:\Users\adamc\Desktop\Diss\Data\Pakistan Electricity Consumption\ElectricityConsumption.csv", rowrange(5) varnames(5) clear

capture rename countrycode c_code
capture rename country_code c_code
capture rename v2 c_code
capture rename indicatorcode i_code
capture rename indicator_code i_code
capture rename v4 i_code

keep if c_code == "PAK" & i_code == "EG.USE.ELEC.KH.PC"
duplicates drop i_code, force

capture drop countryname
capture drop indicatorname
reshape long v, i(i_code) j(year_idx)
gen year = year_idx + 1955
rename v elec_cons

* Add 2023 Electricity Proxy (-8% contraction)
set obs `=_N+1'
replace year = 2023 in L
replace elec_cons = elec_cons[_n-1] * 0.92 in L

* Ensure year is unique in Master data too
duplicates drop year, force

* 3. MERGE AND CALCULATE GROWTH
merge 1:1 year using "temp_gdp_for_merge.dta"
keep if _merge == 3
sort year
tsset year

gen elec_growth = ((elec_cons - L.elec_cons) / L.elec_cons) * 100
keep if year >= 1999 & year <= 2023

* 4. GENERATE RAW LABELED SCATTER PLOT
twoway (scatter elec_growth gdp_growth, mlabel(year) mlabcolor(navy) mcolor(navy) msize(medium)) ///
       (function y = x, range(-12 12) lcolor(maroon) lpattern(dash) lwidth(medium)), ///
       yline(0, lcolor(black) lwidth(vthin)) ///
       xline(0, lcolor(black) lwidth(vthin)) ///
       ytitle("Annual Electricity Consumption Growth (%)") ///
       xtitle("Annual Reported GDP Growth (%)") ///
       title("Pakistan: Energy-GDP Alignment (1999-2023)") ///
       subtitle("Raw Forensic Audit: 1:1 Parity Benchmark") ///
       legend(order(2 "1:1 Physical Parity")) ///
       aspect(1) scheme(s2color)

* Cleanup
capture erase "temp_gdp_for_merge.dta"