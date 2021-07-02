clear all
set more off
capture log close
set maxvar 32767

**** Table 1. Person-wave Sample Characteristics *****
use "../analytical_long.dta", clear

** HRS-Medicare linked sample
sum ragey_e [aw=rwtcrnh] if wave==5, d
foreach var in agegroup female race educ_3 rstroke rhearte rdiabe rhibpe rmstat deadfwd{
	tab `var' [aw=rwtcrnh] if wave==5, m
}
sum ragey_e [aw=rwtcrnh] if wave==9, d
foreach var in agegroup female race educ_3 rstroke rhearte rdiabe rhibpe rmstat deadfwd{
	tab `var' [aw=rwtcrnh] if wave==9, m
}

** HRS 67+ sample
use "../rndhrs_p.dta", clear

gen agegroup5 = 1 if r5agey_e >= 67 & r5agey_e <75 & inw5==1 
replace agegroup5 = 2 if r5agey_e >=75 & r5agey_e < 85 & inw5==1 
replace agegroup5 = 3 if r5agey_e >= 85 & !missing(r5agey_e) & inw5==1 
recode raeduc (1 2 = 1 "1.lt highschool") (3 = 2 "2.highschool equiva") (5 4 = 3 "3.college and above"), gen(educ_3) label(educ_3)
gen deadfwd5 = inlist(r6iwstat,5,6)

sum r5agey_e [aw=r5wtcrnh] if inw5==1 & r5agey_e>=67 & !missing(r5agey_e), d
foreach var in agegroup ragender race educ_3 r5stroke r5hearte r5diabe r5hibpe r5mstat deadfwd5{
	tab `var' [aw=r5wtcrnh] if inw5==1 & r5agey_e >= 67, m
}

gen agegroup9 = 1 if r9agey_e >= 67 & r9agey_e <75 & inw9==1 
replace agegroup9 = 2 if r9agey_e >=75 & r9agey_e < 85 & inw9==1 
replace agegroup9 = 3 if r9agey_e >= 85 & !missing(r9agey_e) & inw9==1 
gen deadfwd9 = inlist(r10iwstat,5,6)

sum r9agey_e [aw=r9wtcrnh] if inw9==1 & r9agey_e>=67 & !missing(r9agey_e), d
foreach var in agegroup ragender race educ_3 r9stroke r9hearte r9diabe r9hibpe r9mstat deadfwd9{
	tab `var' [aw=r9wtcrnh] if inw9==1 & r9agey_e >= 67, m
}

