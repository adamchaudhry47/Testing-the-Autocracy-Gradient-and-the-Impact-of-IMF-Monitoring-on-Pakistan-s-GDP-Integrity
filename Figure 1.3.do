clear all
set obs 12
gen year = 2012 + _n

* 1. HARD-CODE DATA (2013-2024)
* ---------------------------------------------------

* Real GDP (Constant Local Currency - Billions)
gen real_gdp = .
replace real_gdp = 11152 in 1
replace real_gdp = 11674 in 2
replace real_gdp = 12154 in 3
replace real_gdp = 12863 in 4
replace real_gdp = 13580 in 5
replace real_gdp = 14411 in 6
replace real_gdp = 14861 in 7
replace real_gdp = 14643 in 8
replace real_gdp = 15494 in 9
replace real_gdp = 16450 in 10
replace real_gdp = 16401 in 11
replace real_gdp = 16810 in 12

* Electricity Consumption (GWh)
gen electricity = .
replace electricity = 84654  in 1
replace electricity = 91474  in 2
replace electricity = 95155  in 3
replace electricity = 102604 in 4
replace electricity = 110421 in 5
replace electricity = 120621 in 6
replace electricity = 122703 in 7
replace electricity = 119854 in 8
replace electricity = 130562 in 9
replace electricity = 138742 in 10
replace electricity = 132540 in 11
replace electricity = 135000 in 12

* Nightlights Intensity (Radiance Mean)
gen nightlights = .
replace nightlights = 1.42 in 1
replace nightlights = 1.48 in 2
replace nightlights = 1.55 in 3
replace nightlights = 1.68 in 4
replace nightlights = 1.79 in 5
replace nightlights = 1.92 in 6
replace nightlights = 1.88 in 7
replace nightlights = 1.85 in 8
replace nightlights = 2.01 in 9
replace nightlights = 2.15 in 10
replace nightlights = 2.10 in 11
replace nightlights = 2.18 in 12

* 2. INDEXING: SETTING 2013 AS THE BASE YEAR (100)
* ---------------------------------------------------
foreach var in real_gdp electricity nightlights {
    quietly sum `var' if year == 2013
    gen `var'_idx = (`var' / r(mean)) * 100
}

* 3. THE CONSOLIDATED GRAPH (ALL 3 ON ONE)
* ---------------------------------------------------
twoway (line real_gdp_idx year, lcolor(ebblue) lwidth(thick)) ///
       (line electricity_idx year, lcolor(cranberry) lpattern(dash) lwidth(medthick)) ///
       (line nightlights_idx year, lcolor(orange) lpattern(shortdash) lwidth(medthick)), ///
       title("Growth Trends: Pakistan Economic Indicators (2013-2024)") ///
       subtitle("Relative Index (Base Year 2013 = 100)") ///
       ytitle("Growth Index Value") xtitle("Year") ///
       xlabel(2013(1)2024) ///
       legend(label(1 "Real GDP") label(2 "Electricity Consumption") label(3 "Nightlights Intensity")) ///
       graphregion(color(white)) ///
       note("Source: World Bank, NEPRA, and VIIRS Satellite Data.")