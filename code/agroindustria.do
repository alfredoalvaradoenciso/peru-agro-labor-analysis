global enaho "C:\Users\gian_\OneDrive - pucp.pe\ENAHO"
local vars cong vivi hog codperso estrato p500i p204 p205 p206 ocu500 p506* p507 p510* p512* fac500a i524b1 i524a1 d529t d540t i538a1 i530a d536 i541a d543 i513t i518 i520 p519 p506 fac500a ubigeo
/*
forval i=2007/2011 {
use  conglome vivienda hogar codperso activida e1 using "$enaho\\`i'\enaho04-`i'-1-preg-1-a-13", clear 
keep if activida=="1"
merge 1:1 conglome vivienda hogar codperso using "$enaho\\`i'\enaho01a-`i'-500", gen(merge_04) keepus(`vars')
keep if (p204==1 & p205==2) | (p204==2 & p206==1) // nos quedamos con PET residente habitual
keep if ocu500==1
do "$do\informalidad2007-2011.do"
egen ingtot=rowtotal(i524a1 d529t d540t i538a i530a d536 i541a d543), missing
egen horas=rowtotal(i513t i518), missing
replace horas=i520 if p519==2
replace ingtot=ingtot/horas/52
gen y=`i'
tempfile b`i'
save `b`i''
}
*/

local vars cong vivi hog codperso p419a1 p419a2 p419a3 p419a4 p419a5 p419a6 p419a7 p419a8 p4191 p4192 p4193 p4194 p4195 p4196 p4197 p4198
forval i = 2019/2025 {
use `vars' using "$enaho\\`i'\enaho01a-`i'-400", clear
* 1. Default to informal
gen byte sinseguro = 1

* 2. Reclassify as formal if at least one insurance condition is valid
forval j = 1/8 {
    replace sinseguro = 0 if p419`j' == 1 & p419a`j' == 1
}
* 3. Handle incomplete/missing survey responses
forval j = 1/8 {
    replace sinseguro = . if p419`j' == 1 & missing(p419a`j')
}
replace sinseguro = . if missing(p4191, p4192, p4193, p4194, p4195, p4196, p4197, p4198)
gen y=`i'
tempfile h`i'
save `h`i''
}
use `h2019', clear
forval i= 2020/2025 {
append using `h`i''
}
tempfile h
save `h'

local vars cong vivi hog codperso estrato p500i p204 p205 p206 ocu500 p506* p507 p510* p512* fac500a i524b1 i524a1 d529t d540t i538a1 i530a d536 i541a d543 i513t i518 i520 p519 p506 fac500a ubigeo
forval i = 2019/2025 {
use `vars' using "$enaho\\`i'\enaho01a-`i'-500", clear
keep if (p204==1 & p205==2) | (p204==2 & p206==1) // nos quedamos con PET residente habitual
keep if ocu500==1
egen ingtot=rowtotal(i524a1 d529t d540t i538a i530a d536 i541a d543), missing
egen horas=rowtotal(i513t i518), missing
replace horas=i520 if p519==2
replace ingtot=ingtot/horas/52

* 1. Location filter (agroindustry excluded in Lima province & Callao)
gen fuera_lima_callao = 1
replace fuera_lima_callao = 0 if substr(ubigeo,1,4)=="1501" | substr(ubigeo,1,4)=="0701"

* 2. Identify excluded agroindustrial activities using ISIC Rev.4
gen excluidos_rev4 = inlist(p506r4,1061,1200,1040,1103)

* 3. Beneficiaries according to Ley 31110
gen beneficiarios = .

* Agriculture (ISIC Rev.3 01xx) — always included
replace beneficiarios = 1 if (p506>=100 & p506<200)

* Agroindustry (ISIC Rev.3 15xx) — included only if:
*   - outside Lima/Callao
*   - NOT in excluded Rev.4 categories
replace beneficiarios = 1 if (p506>=1500 & p506<1600) ///
    & fuera_lima_callao==1 ///
    & excluidos_rev4==0

* Everything else excluded
replace beneficiarios = 0 if beneficiarios==.
rename beneficiarios agroindustria
gen y=`i'
tempfile b`i'
save `b`i''
}

use `b2019', clear
forval i= 2020/2025 {
append using `b`i''
}
merge 1:1 y cong vivi hog codperso using `h'

gen informal=.
replace informal= 1 if p510a1==3 & (p507==1 |  p507==2)
replace informal= 0 if p510a1<3 & (p507==1 |  p507==2)
replace informal= 1 if sinseguro==1 & (p507==3 |  p507==4 |  p507==6)
replace informal= 0 if sinseguro==0 & (p507==3 |  p507==4 |  p507==6)


gen salaried=p507==3 |  p507==4 |  p507==6 if p507!=.

preserve
collapse (mean) ingtot [iw=fac500a] if salaried==1, by(y)
tempfile total
save `total'
restore

preserve
collapse (mean) agro=ingtot [iw=fac500a] if salaried==1, by(y agroindustria)
reshape wide agro, i(y) j(agroindustria)
tempfile agro
save `agro'
restore

preserve
collapse (mean) inf=ingtot [iw=fac500a] if salaried==1, by(y informal)
drop if informal==.
reshape wide inf, i(y) j(informal)
tempfile informal
save `informal'
restore


collapse (mean) ingtot [iw=fac500a] if salaried==1, by(y agroindustria informal)
reshape wide ingtot, i(y informal) j(agroindustria)
rename (ingtot0 ingtot1) (wnoagro wagro)
drop if informal==.
reshape wide wnoagro wagro, i(y ) j(informal)
merge 1:1 y using `total', nogen
merge 1:1 y using `agro', nogen
merge 1:1 y using `informal', nogen
twoway ///
    (line ingtot y, lwidth(thick) lpattern(solid)  lcolor(navy)) ///
    (line agro1 y, lwidth(thick) lpattern(dash)   lcolor(cranberry)) ///
    (line agro0 y, lwidth(thick) lpattern(shortdash) lcolor(forest_green)) ///
	(line inf1 y, lwidth(thick) lpattern(dash)   lcolor(cranberry)) ///
    (line inf0 y, lwidth(thick) lpattern(shortdash) lcolor(forest_green)) ///
    (line wagro1 y, lwidth(thick) lpattern(dash_dot) lcolor(sienna)) ///
    (line wagro0 y, lwidth(thick) lpattern(longdash) lcolor(teal)), ///
    title("Wage Dynamics Over Time", size(medium)) ///
    ytitle("Earnings") ///
    xtitle("Year") ///
    legend(order(1 "Total" ///
	             2 "Agro" ///
                 3 "Non Agro" ///
                 4 "Informal" ///
                 5 "Formal" ///
                 6 "Informal - Agro-Exporter" ///
                 7 "Formal - Agro-Exporter") ///
           rows(2) position(6) ring(1) size(small))

