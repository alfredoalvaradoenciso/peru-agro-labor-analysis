use "C:\Users\gian_\Downloads\inspectors.dta", clear

use "C:\Users\gian_\Downloads\inspectors.dta", clear

* --- Make sure year is numeric for sorting/merging ---
gen year = real(time)

* --- Define LAC (Latin America & Caribbean) ISO3 list ---
* Adjust this list if your classification differs (e.g. World Bank vs UN)
local lac "ATG ARG ABW BHS BRB BLZ BOL BRA VGB CYM CHL COL CRI CUB CUW DMA DOM ECU SLV GRD GTM GUY HTI HND JAM MEX NIC PAN PRY PER PRI KNA LCA MAF VCT SXM SUR TTO TCA URY VEN VIR"

gen group_lac = 0
foreach c of local lac {
    replace group_lac = 1 if ref_area == "`c'"
}

* --- 1) World average per year ---
preserve
collapse (mean) obs_value, by(year)
rename obs_value world_avg
tempfile world
save `world'
restore

* --- 2) LAC average per year ---
preserve
keep if group_lac == 1
collapse (mean) obs_value, by(year)
rename obs_value lac_avg
tempfile lac
save `lac'
restore

* --- 3) Peru value per year ---
preserve
keep if ref_area == "PER"
collapse (mean) obs_value, by(year)
rename obs_value peru_value
tempfile peru
save `peru'
restore

* --- Merge into one table ---
use `world', clear
merge 1:1 year using `lac', nogen
merge 1:1 year using `peru', nogen

sort year
list year world_avg lac_avg peru_value, clean noobs
