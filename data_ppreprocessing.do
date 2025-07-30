* ---------------------------------------------------------------
* FACTOR DATA PREP (RUN ONCE ONLY – COMMENTED OUT)
* ---------------------------------------------------------------
* NOTE: The cleaning step for factor data was performed 
* earlier and saved as factor_data_cleaned.dta
* If needed again, uncomment the block below and rerun.

clear
cls
cd "C:\Users\Administrator\Desktop\WORK\Assignments\ONES\Stata Thesis"

import excel "Cleaned_Dataset.xlsx", firstrow clear
rename countrycode iso3
rename Landareasqkm land
foreach var in emp hc cn land {
    destring `var', replace force
}
destring year, replace force
save "factor_data_cleaned.dta", replace

* ---------------------------------------------------------------
* (1) Filter gravity data: India as origin, years 1995–2021
* ---------------------------------------------------------------
use "gravity_model.dta", clear
keep if iso3_o == "IND"
keep if year >= 1995 & year <= 2021
* ---------------------------------------------------------------
* (2) Merge in origin country factor data
* ---------------------------------------------------------------
gen iso3 = iso3_o
merge m:1 iso3 year using "factor_data_cleaned.dta", keepusing(emp hc cn land) nogenerate
drop iso3
rename emp emp_o
rename hc hc_o
rename cn cn_o
rename land land_o
* Optional: check merge success
* tab _merge
save "gravity_with_origin.dta", replace
* ---------------------------------------------------------------
* (3) Merge in destination country factor data
* ---------------------------------------------------------------
use "gravity_with_origin.dta", clear
gen iso3 = iso3_d
merge m:1 iso3 year using "factor_data_cleaned.dta", keepusing(emp hc cn land) nogenerate
drop iso3
rename emp emp_d
rename hc hc_d
rename cn cn_d
rename land land_d

* Optional: check merge success
* tab _merge

* ---------------------------------------------------------------
* (4) Construct factor proportion variables
* ---------------------------------------------------------------
gen kl_diff     = (cn_o / emp_o) - (cn_d / emp_d)
gen landl_diff  = (land_o / emp_o) - (land_d / emp_d)
gen hc_diff     = hc_o - hc_d

replace kl_diff = . if emp_o == 0 | emp_d == 0
replace landl_diff = . if emp_o == 0 | emp_d == 0

* ---------------------------------------------------------------
* (5) Label variables for regression output clarity
* ---------------------------------------------------------------
label var kl_diff      "Capital per worker difference (India - partner)"
label var landl_diff   "Land per worker difference (India - partner)"
label var hc_diff      "Human capital difference (India - partner)"

* ---------------------------------------------------------------
* (6) Summary check and save
* ---------------------------------------------------------------
summarize kl_diff landl_diff hc_diff
save "gravity_final_with_factors.dta", replace


