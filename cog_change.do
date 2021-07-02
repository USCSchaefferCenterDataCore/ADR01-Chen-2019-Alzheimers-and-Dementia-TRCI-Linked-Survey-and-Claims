clear all
set more off
capture log close

use "../analytical_wide_inci.dta", clear
merge 1:1 hhidpn using "../cogstate_wide.dta", keepusing(hhidpn cogstate* totcog* proxy*)
keep if _m==3
drop _m

***** calculate change in cog score from last 'normal/CIND' to first 'dem', to see if they are marginal decline *****
keep if incog5==1 | incog6==1 | incog7==1
forvalues i=5/7 {
	gen inciwv = `i' if incog`i'==1
}
gen inci_self = 0
forvalues i=5/7{
	replace inci_self= 1 if inciwv==`i' & !missing(totcog`i')
}
gen preinciwv = inciwv-1
gen pre_self = 0
forvalues i=4/6{
	replace pre_self= 1 if preinciwv==`i' & !missing(totcog`i')
}
gen resptype = (inci_self ==1 & pre_self ==1)
replace resptype = 2 if inci_self ==0 & pre_self ==1
replace resptype = 3 if inci_self ==0 & pre_self ==0
replace resptype = 4 if inci_self ==1 & pre_self ==0
label define type2 1 "1.self-self" 2 "2.self-proxy" 3 "3.proxy-proxy" 4 "4.proxy-self"
label values resptype type2
tab resptype [aw=basewt]

gen inci_score = .
forvalues i=5/7{
	replace inci_score= totcog`i' if inciwv== `i' & inci_self == 1
	replace inci_score= proxy_nonmiss`i' if inciwv== `i' & inci_self == 0
}
gen pre_score = .
forvalues i=4/6{
	replace pre_score= totcog`i' if preinciwv== `i' & pre_self == 1
	replace pre_score= proxy_nonmiss`i' if preinciwv== `i' & pre_self == 0
}

gen cog_change=.
replace cog_change = inci_score - pre_score if resptype==1
replace cog_change = inci_score - pre_score if resptype==3
table resptype, c(mean cog_change sd cog_change)

forvalues i=1/4 {
	ci pre_score [aw=basewt] if inlist(concorsv_ver,1,2,3,4) & resptype==`i'
	ci pre_score [aw=basewt] if concorsv_ver==7 & resptype==`i'
}

gen flag=.
replace flag=1 if concorsv_ver==7
replace flag=0 if inlist(concorsv_ver,1,2,3,4)
ttest cog_change if resptype==1, by(flag)
ttest cog_change if resptype==3, by(flag)
ttest pre_score if resptype==2, by(flag)
ttest inci_score if resptype==2, by(flag)
ttest pre_score if resptype==4, by(flag)
ttest inci_score if resptype==4, by(flag)

