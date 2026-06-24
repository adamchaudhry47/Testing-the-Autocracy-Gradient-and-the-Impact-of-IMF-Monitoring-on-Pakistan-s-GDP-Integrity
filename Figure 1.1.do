********************************************************
* THE MARTINEZ ELASTICITY TEST (2013-2023)
* Objective: Calculate Beta (Elasticity) & The Decoupling Gap
********************************************************

clear all
set more off
set scheme s1color

* ==========================================
* 1. LOAD & PREPARE DATA
* ==========================================
* (Same data loading steps as before - ensuring we have growth rates)
cd "C:\Users\adamc\Desktop\Diss\Data\Pakistan GDP and other metrics\API_PAK_DS2_en_csv_v2_3451"
import delimited "API_PAK_DS2_en_csv_v2_3451.csv", varnames(5) rowrange(5) clear 
keep if indicatorcode == "NY.GDP.MKTP.KD.ZG"
gen country_id = _n
drop countryname countrycode indicatorname indicatorcode
reshape long v, i(country_id) j(year_offset)
gen year = 1955 + year_offset
rename v gdp_growth
keep if year >= 2013 & year <= 2024
save "Temp_GDP.dta", replace

import delimited "C:\Users\adamc\Desktop\Diss\Data\Raw Sunlight\VIIRS-nighttime-lights-2013m1to2024m5-level0.csv", clear
capture rename nlsum lights_sum
capture rename sum lights_sum
capture rename v2 lights_sum
collapse (sum) lights_sum, by(year)
tsset year
gen lights_growth = (D.lights_sum / L.lights_sum) * 100

merge 1:1 year using "Temp_GDP.dta"
keep if _merge == 3
drop _merge

* ==========================================
* 2. THE MARTINEZ REGRESSION (CALCULATING BETA)
* ==========================================
* We run this regression to find the "Honest" relationship.
* We exclude the crisis years (2022-2023) to get a "clean" baseline.
regress gdp_growth lights_growth if year < 2022

* SAVE THE COEFFICIENT (BETA)
local beta = _b[lights_growth]
local alpha = _b[_cons]

display as text "---------------------------------------------------"
display as text "THE MARTINEZ ELASTICITY (BETA) IS: " as result `beta'
display as text "Interpretation: For every 1% increase in Lights, GDP grows by " `beta' "%"
display as text "---------------------------------------------------"

* ==========================================
* 3. THE FORENSIC AUDIT (DETECTING THE LIE)
* ==========================================
* We use the 'Clean Beta' to predict what GDP *should* have been in 2023
predict gdp_predicted
gen decoupling_gap = gdp_growth - gdp_predicted

* LABEL THE GAP
label var decoupling_gap "The Lie (Difference between Official and Predicted)"

* ==========================================
* 4. DISPLAY THE RESULTS FOR YOUR DISSERTATION
* ==========================================
list year gdp_growth lights_growth gdp_predicted decoupling_gap, separator(0)

* ==========================================
* 5. VISUALIZE THE ELASTICITY BREAK
* ==========================================
* This scatter plot shows the "Line of Truth" (Red) and the "Lies" (Outliers)
twoway (scatter gdp_growth lights_growth if year < 2022, mcolor(blue) msymbol(circle) msize(medium) legend(label(1 "Normal Years"))) ///
       (scatter gdp_growth lights_growth if year >= 2022, mcolor(red) msymbol(diamond) msize(large) mlabel(year) legend(label(2 "Crisis Years (Outliers)"))) ///
       (lfit gdp_growth lights_growth if year < 2022, lcolor(black) lwidth(thick)), ///
       title("The Martinez Elasticity Test") ///
       subtitle("Visualizing the 2023 Structural Break") ///
       ytitle("Official GDP Growth (%)") xtitle("Nightlights Growth (%)") ///
       note("The Black Line is the 'Honest Elasticity'. Red Diamonds are the Deviation.")


* ==========================================
* VISUALIZE WITH LABELS
* ==========================================
twoway (scatter gdp_growth lights_growth if year < 2022, mcolor(blue) mlabel(year) mlabsize(small)) ///
       (scatter gdp_growth lights_growth if year >= 2022, mcolor(red) msymbol(diamond) msize(large) mlabel(year) mlabcolor(red)) ///
       (lfit gdp_growth lights_growth if year < 2022, lcolor(black) lwidth(thick)), ///
       title("The Martinez Elasticity Test") ///
       subtitle("With Year Labels") ///
       ytitle("Official GDP Growth (%)") xtitle("Nightlights Growth (%)") ///
       legend(off)