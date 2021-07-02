clear all
set more off
capture log close
set maxvar 32767

use "../dementia_bene_wv.dta", clear
merge 1:1 hhidpn using "../cogstate_wide.dta", keepusing(hhidpn cogstate10)
drop _m
rename cogstate10 rcogstate10

merge 1:1 hhidpn using "../rndhrs_p.dta", keepusing(hhidpn r*stroke r*hearte r*diabe r*hibpe r*mstat r10iwstat)
drop _m

foreach var in cogstate proxy wtcrnh agey_e iwend iwstat stroke hearte diabe hibpe mstat { 
			forvalues i = 1(1)9{
					rename r`i'`var' r`var'`i' 
	}
}		
rename r10iwstat riwstat10

keep hhidpn ragey_e* inw* rcogstate* rproxy* sampwv* riwend* riwstat* rwtcrnh* rstroke* rhearte* rdiabe* rhibpe* rmstat* everad* evernonad* everdem* newdem* newad* demver* ragender race raeduc raddate ad_date nonad_date nonad_add_date dx2_add_date
drop inw sampwv everdem demver
reshape long ragey_e inw rcogstate rproxy sampwv riwend riwstat rwtcrnh rstroke rhearte rdiabe rhibpe rmstat everad evernonad everdem newdem newad demver, i(hhidpn) j(wave)
bys hhidpn (wave): gen deadfwd = inlist(riwstat[_n+1],5,6)
label var deadfwd "already dead before next wv"

/* absorbed dementia in long file */
gen dementia = (rcogstate == 1) if !missing(rcogstate)
bys hhidpn (wave): egen firstdemwv = min(cond(rcogstate == 1), wave, .)
gen dementiae = dementia
replace dementiae = 1 if wave >= firstdemwv & dementiae == 0
/* persistent dementia - make sure subsequent wave has dementia or CIND or death */
gen dementiae_strict = dementia
bys hhidpn (wave): egen confirmedwv = min(cond(inlist(rcogstate[_n+1],1,2) & rcogstate == 1), wave, .)
* fill in the zeros if not yet confirmed
replace dementiae_strict = 0 if dementia == 1 & wave < confirmedwv & deadfwd == 0
* fill forward once confirmed
replace dementiae_strict = 1 if dementiae_strict == 0 & wave >= confirmedwv 
label var dementia "Respondent has cogstate = 1 in this wave"
label var dementiae "Respondent ever had cogstate = 1"
label var dementiae_strict "Persistent dementia (subsequent wave has dementia, CIND, or death)"

/* dx dummy */
tab demver everdem [aw=rwtcrnh]
gen dxver = (everdem==1 & demver==1)
label var dxver "Verified dx"
label var everdem "Raw dx"
gen demdx_date = min(ad_date, nonad_date, nonad_add_date) 

/* make covariates */
recode ragender (1=0 "0.Male") (2=1 "1.Female"), gen(female) label(female)
recode raeduc (1 2 = 1 "1.lt highschool") (3 = 2 "2.highschool equiva") (5 4 = 3 "3.college and above"), gen(educ_3) label(educ_3)
gen agegroup = 1 if ragey_e >= 67 & ragey_e <75
replace agegroup = 2 if ragey_e >=75 & ragey_e < 85
replace agegroup = 3 if ragey_e >= 85 & !missing(ragey_e)
label define agelabel 1 "1.67-74" 2 "2.75-84" 3 "3.85+"
label values agegroup agelabel
recode rmstat (1 2 3 = 0) (4 5 6 7 8 =1), gen(single)

/* flag sample selection */
gen insamp= (inw ==1 & sampwv==3 & ragey_e>=67)

save "../analytical_long.dta", replace

reshape wide ragey_e inw insamp rcogstate rproxy sampwv riwend riwstat rwtcrnh rstroke rhearte rdiabe rhibpe everad evernonad everdem newdem newad demver deadfwd dementia dementiae dementiae_strict dxver agegroup, i(hhidpn) j(wave)
keep if insamp5==1 |insamp6 ==1|insamp7 ==1|insamp8 ==1|insamp9 ==1
save "../analytical_wide.dta", replace

