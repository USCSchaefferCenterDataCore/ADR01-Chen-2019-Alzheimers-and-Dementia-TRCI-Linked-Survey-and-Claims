clear all
set more off
capture log close

use "../analytical_wide.dta", clear

gen incog5 = 0
replace incog5=1 if confirmedwv==5 & insamp5==1
gen incog6 = 0
replace incog6 = 1 if confirmedwv==6 & inw5==1 & insamp6==1
gen incog7 = 0
replace incog7 = 1 if confirmedwv==7 & inw6==1 & insamp7==1
gen incog8 = 0
replace incog8=1 if dementiae_strict5!=1 & dementiae_strict6!=1 & dementiae_strict7!=1 & dementiae_strict8==1 & inw8==1 & ragey_e8>=67
gen incog9 = 0
replace incog9=1 if dementiae_strict5!=1 & dementiae_strict6!=1 & dementiae_strict7!=1 & dementiae_strict8!=1 & dementiae_strict9==1  & inw9==1 & ragey_e9>=67
keep if incog5==1 | incog6==1 | incog7==1 | incog8==1 | incog9==1

save "../analytical_wide_inci.dta", replace

gen demverdx_date = demdx_date
replace demverdx_date = . if demver9==0
gen diffver_date = demverdx_date - firstdem_hrs_date
sum demverdx_date, d
sum demdx_date, d

gen concor_ver = 0
replace concor_ver = 1 if ((diffver_date < (riwend4-riwend5) & !missing(riwend4)) | (missing(riwend4) & diffver_date < -730)) & incog5==1
replace concor_ver = 1 if ((diffver_date < (riwend5-riwend6) & !missing(riwend5)) | (missing(riwend5) & diffver_date < -730)) & incog6==1
replace concor_ver = 1 if ((diffver_date < (riwend6-riwend7) & !missing(riwend6)) | (missing(riwend6) & diffver_date < -730)) & incog7==1
replace concor_ver = 1 if ((diffver_date < (riwend7-riwend8) & !missing(riwend7)) | (missing(riwend7) & diffver_date < -730)) & incog8==1
replace concor_ver = 1 if ((diffver_date < (riwend8-riwend9) & !missing(riwend8)) | (missing(riwend8) & diffver_date < -730)) & incog9==1
replace concor_ver = 2 if ((diffver_date >= (riwend4-riwend5) & diffver_date <0 & !missing(riwend4)) | (diffver_date >= -730 & diffver_date<0 & missing(riwend4))) & incog5==1
replace concor_ver = 2 if ((diffver_date >= (riwend5-riwend6) & diffver_date <0 & !missing(riwend5)) | (diffver_date >= -730 & diffver_date<0 & missing(riwend5))) & incog6==1
replace concor_ver = 2 if ((diffver_date >= (riwend6-riwend7) & diffver_date <0 & !missing(riwend6)) | (diffver_date >= -730 & diffver_date<0 & missing(riwend6))) & incog7==1
replace concor_ver = 2 if ((diffver_date >= (riwend7-riwend8) & diffver_date <0 & !missing(riwend7)) | (diffver_date >= -730 & diffver_date<0 & missing(riwend7))) & incog8==1
replace concor_ver = 2 if ((diffver_date >= (riwend8-riwend9) & diffver_date <0 & !missing(riwend8)) | (diffver_date >= -730 & diffver_date<0 & missing(riwend8))) & incog9==1
replace concor_ver = 3 if (diffver_date>=0 & demdx_date<=17897)
replace concor_ver = 4 if missing(diffver_date) & raddate<=17897
replace concor_ver = 5 if demverdx_date>=17897 & raddate>17897
** concor_ver: 
	* dx precedes last wave = 1 
	* dx btw last & this wave = 2
	* dx after this wave & before EO2008 = 3
	* died before EO2008 w/o dx = 4
	* survived thru EO2008 w/o dx = 5 
** concor based on diff_date is actually an unverified version

gen timelydx_ver = (concor_ver==2 | (concor_ver==3 & diffver_date<=730)) 
gen concorf_ver = concor_ver
replace concorf_ver = 2 if (concor_ver==3 & timelydx_ver ==1)
** concorf_ver: 
	* dx precedes last wave = 1 
	* dx btw one-wave window (both back and forward) = 2
	* dx after next wave & before EO2008 = 3
	* died before EO2008 w/o dx = 4
	* survived thru EO2008 w/o dx = 5 

gen concorsv_ver = 0
replace concorsv_ver = 1 if concor_ver == 1
replace concorsv_ver = 2 if concor_ver == 2
replace concorsv_ver = 3 if concor_ver == 3 & timelydx_ver == 1
replace concorsv_ver = 4 if concor_ver == 3 & timelydx_ver == 0
replace concorsv_ver = 6 if concor_ver == 4
replace concorsv_ver = 5 if concor_ver == 4 & concors_ver == 6
replace concorsv_ver = 7 if concor_ver == 5
** concorsv: 
	* dx precedes last wave = 1 
	* dx btw last & this wave = 2
	* dx btw this & next wave = 3
	* dx after next wave & before EO2008 = 4
	* died before next wave w/o dx = 5
	* died after next wv & before EO2008 w/o dx = 6
	* survived thru EO2008 w/o dx = 7 
	
foreach var in ragey_e agegroup rstroke rhearte rdiabe rhibpe rproxy rnhmliv rwtcrnh {
		gen base`var' = 0
			forvalues j=5/9{
			replace base`var' = 1 if `var'`j'==1 & incog`j'==1
	}
}
rename baseragey_e baseage
rename baserwtcrnh basewt 	
rename basernhmliv basenh
	
********** Figure 2. Timing of Incidence: DX v. HRS ********	
tab concorsv_ver [aw=basewt] if incog5==1 | incog6==1 | incog7==1
	

********** Supplementary Table 3. Characteristics by Timing of Incidence ********	
foreach var in baseagegroup female race educ_3 baserstroke baserhearte baserdiabe baserhibpe doctor baserproxy basenh { 
	tab concorsv_ver `var' [aw=basewt] if incog5==1 | incog6==1 | incog7==1, col
}
table concorsv_ver [aw=basewt] if incog5==1 | incog6==1 | incog7==1, c(mean baseage sd baseage)
table concorsv_ver [aw=basewt] if incog5==1 | incog6==1 | incog7==1, c(mean diffver_event_date)


********** Figure 3. Modeling Timing of Incidence ********	
mlogit concor_ver female i.race i.educ_3 i.baseagegroup doctor i.wave if inrange(wave,5,7), base(2)
foreach var in race educ_3 {
	forvalues i=1/5 {
		margins, at(`var'=(1 2 3)) predict(outcome(`i')) post
	}
}
forvalues i=1/5 {
	margins, at(female=(0 1)) predict(outcome(`i')) post
}
