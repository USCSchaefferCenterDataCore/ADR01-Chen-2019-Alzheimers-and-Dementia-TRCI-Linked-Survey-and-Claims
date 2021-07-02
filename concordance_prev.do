clear all
set more off
capture log close
set maxvar 32767

**** Table 2. Concordance in Prevalence & by Race  *****
* compare dementia state in two sources for each person
use "../analytical_long.dta", clear
 
replace dxver = 1 if everdem==1 & demver==0 & (raddate-demdx_date<=17897)
tab dxver dementiae_strict [aw=rwtcrnh]
tab everdem dementiae_strict [aw=rwtcrnh]

gen concordance = 0
replace concordance = 1 if dxver == 1 & dementiae_strict == 1
replace concordance = 2 if dxver == 0 & dementiae_strict == 0
replace concordance = 3 if dxver == 0 & dementiae_strict == 1
replace concordance = 4 if dxver == 1 & dementiae_strict == 0
tab concordance [aw=rwtcrnh]
* concordance:
	* both dem = 1
	* both not dem = 2
	* hrs dem, no dx = 3
	* hrs not dem, dx = 4
* HRS dementia measure: dementiae_strict (absorbed, persistent, account for death)
* dx measure: 
			* everdem (raw dx as of each wave)
			* dxver (dx as of each wave must be verified by subsequent dx or death within two yrs)

* concordance when allowing dx to occur two yrs after HRS dem
gen dxver_ow = dxver
replace dxver_ow = 1 if everdem==1 & dxver==0 & (demdx_date-riwend <=730)
gen concordance_ow = 0
replace concordance_ow = 1 if dxver_ow == 1 & dementiae_strict == 1
replace concordance_ow = 2 if dxver_ow == 0 & dementiae_strict == 0
replace concordance_ow = 3 if dxver_ow == 0 & dementiae_strict == 1
replace concordance_ow = 4 if dxver_ow == 1 & dementiae_strict == 0
tab concordance_ow if wave!=9 [aw=rwtcrnh] // wave 9 people were excluded since we don't have their dx after end of 2008

tab concordance [aw=rwtcrnh]
tab concordance race [aw=rwtcrnh], col
tab concordance_ow
tab concordance_ow race [aw=rwtcrnh], col


**** Figure 1. Modeling Concordance in Prevalence  *****
** add doctor visists as a covariate
use "../analytical_long.dta", clear
merge m:1 hhidpn using "../rndhrs_p.dta", keepusing(hhidpn r*doctor r*doctim)
keep if _m==3
drop _m
foreach var in doctor doctim { 
			forvalues i = 1(1)12{
					rename r`i'`var' r`var'`i' 
	}
}		
drop rdoctor1 rdoctor2 rdoctor3 rdoctor4 rdoctor10 rdoctor11 rdoctor12 rdoctim1 rdoctim2 rdoctim3 rdoctim4 rdoctim10 rdoctim11 rdoctim12 
gen doctim = .
forvalues i = 5(1)9{
	replace doctim = rdoctim`i' if wave==`i' 	
}
gen doctor = .
forvalues i = 5(1)9{
	replace doctor = rdoctor`i' if wave==`i' 	
}

svyset hhidpn
svy: mlogit concordance female i.race i.agegroup single deadfw doctor wave, base(1)
svy: mlogit concordance female i.race i.educ_3 i.agegroup single deadfw doctor wave, base(1)
svy: mlogit concordance female i.race##c.wave i.educ_3 i.agegroup single deadfw doctor, base(1)

margins, at(race=(1 2 3)) predict(outcome(1)) post
margins, at(race=(1 2 3)) predict(outcome(2)) post
margins, at(race=(1 2 3)) predict(outcome(3)) post
margins, at(race=(1 2 3)) predict(outcome(4)) post

margins, at(educ_3=(1 2 3)) predict(outcome(1)) post
margins, at(educ_3=(1 2 3)) predict(outcome(2)) post
margins, at(educ_3=(1 2 3)) predict(outcome(3)) post
margins, at(educ_3=(1 2 3)) predict(outcome(4)) post

margins, at(female=(0 1)) predict(outcome(1)) post
margins, at(female=(0 1)) predict(outcome(2)) post
margins, at(female=(0 1)) predict(outcome(3)) post
margins, at(female=(0 1)) predict(outcome(4)) post




