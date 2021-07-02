/*
Use wide file. Omit those with HRS inci at wv 9 because no post claims available
1. Concordance if DX and HRS=1 within a 4-year window (2 years pre and 2 years post)
2. DX only if DX at least 2 years prior to HRS=1 or HRS=0
3. HRS only if no DX prior to HRS=1 or more than 2 years after HRS=1
*/

use "/schaeffer-b/sch-protected/from-projects/HRS/yichen/Data/analytical_wide.dta", clear

gen inci_concor=0
label define incilbl 0 "0.wrong" 1 "no inci,both" 2 "inci,both" 3 "inci,HRS only" 4 "inci,dx only"
label val inci_concor incilbl
** clean cases
replace inci_concor=1 if missing(confirmedwv) & (dxver1==0 &dxver2==0 &dxver3==0 &dxver4==0 &dxver5==0 &dxver6==0 &dxver7==0 &dxver8==0 &dxver9==0 &dxver10==0 &dxver11==0 &dxver12==0)
replace inci_concor=3 if !missing(confirmedwv) & (dxver1==0 &dxver2==0 &dxver3==0 &dxver4==0 &dxver5==0 &dxver6==0 &dxver7==0 &dxver8==0 &dxver9==0 &dxver10==0 &dxver11==0 &dxver12==0)
replace inci_concor=4 if missing(confirmedwv) & (dxver1==1|dxver2==1|dxver3==1|dxver4==1|dxver5==1|dxver6==1|dxver7==1|dxver8==1|dxver9==1|dxver10==1|dxver11==1|dxver12==1)

** where timing matters

/*
For HRS incidence in wave 5:
1. Concordance if DX is between wave 4 and wave 6 (a 4-year window) and HRS incidence wave 5 =1
2. DX only if DX between wave 5 and 8 and no HRS dementia wave 8 HRS incidence=0
3. DX only if DX between wave 5 and 6 and HRS dementia wave 8=1
4. HRS only if no DX between wave 5 and 9 and HRS incidence at wave 8 = 1
*/
replace inci_concor=2 if confirmedwv==5 & (demdx_date>=riwend4)&(demdx_date<=riwend6)&!missing(riwend4)&!missing(riwend6)
replace inci_concor=2 if confirmedwv==5 & (demdx_date>=riwend4)&(demdx_date<=(riwend5+730))&!missing(riwend4)&missing(riwend6)
replace inci_concor=2 if confirmedwv==5 & (demdx_date>=(riwend5-730))&(demdx_date<=riwend6)&missing(riwend4)&!missing(riwend6)
replace inci_concor=2 if confirmedwv==5 & (demdx_date>=(riwend5-730))&(demdx_date<=(riwend5+730))&missing(riwend4)&missing(riwend6)
replace inci_concor=3 if confirmedwv==5 & (demdx_date>riwend6&!missing(riwend6)&!missing(demdx_date))
replace inci_concor=3 if confirmedwv==5 & (demdx_date>(riwend5+730)&missing(riwend6)&!missing(demdx_date))
replace inci_concor=4 if confirmedwv==5 & ((demdx_date<riwend4 & !missing(riwend4))|(demdx_date<(riwend5-730)&missing(riwend4)))

/*
For HRS incidence in wave 6:
1. Concordance if dx is between wave 5 and wave 7 (a 4-year window) and HRS incidence wave 6 =1
2. DX only if DX between wave 5 and 6 and no HRS dementia wave 6 HRS incidence=0
3. DX only if DX is prior to wave 5 and HRS dementia wave 6=1
4. HRS only if no DX between wave 5 and 8 and HRS incidence at wave 6 = 1
*/
replace inci_concor=2 if confirmedwv==6 & (demdx_date>=riwend5)&(demdx_date<=riwend7)&!missing(riwend5)&!missing(riwend7)
replace inci_concor=2 if confirmedwv==6 & (demdx_date>=riwend5)&(demdx_date<=(riwend6+730))&!missing(riwend5)&missing(riwend7)
replace inci_concor=2 if confirmedwv==6 & (demdx_date>=(riwend6-730))&(demdx_date<=riwend7)&missing(riwend5)&!missing(riwend7)
replace inci_concor=2 if confirmedwv==6 & (demdx_date>=(riwend6-730))&(demdx_date<=(riwend6+730))&missing(riwend5)&missing(riwend7)
replace inci_concor=3 if confirmedwv==6 & (demdx_date>riwend7&!missing(riwend7)&!missing(demdx_date))
replace inci_concor=3 if confirmedwv==6 & (demdx_date>(riwend6+730)&missing(riwend7)&!missing(demdx_date))
replace inci_concor=4 if confirmedwv==6 & ((demdx_date<riwend5 & !missing(riwend5))|(demdx_date<(riwend6-730)&missing(riwend5)))

/*
For HRS incidence in wave 7:
1. Concordance if DX is between wave 6 and wave 8 (a 4-year window) and HRS incidence wave 7 =1
2. DX only if DX between wave 5 and 7 and no HRS dementia wave 7 HRS incidence=0
3. DX only if DX between wave 5 and 6 and HRS dementia wave 7=1
4. HRS only if no DX between wave 5 and 8 and HRS incidence at wave 7 = 1
*/
replace inci_concor=2 if confirmedwv==7 & (demdx_date>=riwend6)&(demdx_date<=riwend8)&!missing(riwend6)&!missing(riwend8)
replace inci_concor=2 if confirmedwv==7 & (demdx_date>=riwend6)&(demdx_date<=(riwend7+730))&!missing(riwend6)&missing(riwend8)
replace inci_concor=2 if confirmedwv==7 & (demdx_date>=(riwend7-730))&(demdx_date<=riwend8)&missing(riwend6)&!missing(riwend8)
replace inci_concor=2 if confirmedwv==7 & (demdx_date>=(riwend7-730))&(demdx_date<=(riwend7+730))&missing(riwend6)&missing(riwend8)
replace inci_concor=3 if confirmedwv==7 & (demdx_date>riwend8&!missing(riwend8)&!missing(demdx_date))
replace inci_concor=3 if confirmedwv==7 & (demdx_date>(riwend7+730)&missing(riwend8)&!missing(demdx_date))
replace inci_concor=4 if confirmedwv==7 & ((demdx_date<riwend6 & !missing(riwend6))|(demdx_date<(riwend7-730)&missing(riwend6)))

/*
For HRS incidence in wave 8:
1. Concordance if DX is between wave 7 and wave 9 (a 4-year window) and HRS incidence wave 8 =1
2. DX only if DX between wave 5 and 8 and no HRS dementia wave 8 HRS incidence=0
3. DX only if DX between wave 5 and 6 and HRS dementia wave 8=1
4. HRS only if no DX between wave 5 and 9 and HRS incidence at wave 8 = 1
*/
replace inci_concor=2 if confirmedwv==8 & (demdx_date>=riwend7)&(demdx_date<=riwend9)&!missing(riwend7)&!missing(riwend9)
replace inci_concor=2 if confirmedwv==8 & (demdx_date>=riwend7)&(demdx_date<=(riwend8+730))&!missing(riwend7)&missing(riwend9)
replace inci_concor=2 if confirmedwv==8 & (demdx_date>=(riwend8-730))&(demdx_date<=riwend9)&missing(riwend7)&!missing(riwend9)
replace inci_concor=2 if confirmedwv==8 & (demdx_date>=(riwend8-730))&(demdx_date<=(riwend8+730))&missing(riwend7)&missing(riwend9)
replace inci_concor=3 if confirmedwv==8 & (demdx_date>riwend9&!missing(riwend9)&!missing(demdx_date))
replace inci_concor=3 if confirmedwv==8 & (demdx_date>(riwend8+730)&missing(riwend9)&!missing(demdx_date))
replace inci_concor=4 if confirmedwv==8 & ((demdx_date<riwend7 & !missing(riwend7))|(demdx_date<(riwend8-730)&missing(riwend7)))

************ Table 3. Concordance in Incidence & by Race ************
tab inci_concor if confirmedwv!=9 & confirmedwv!=4, m
tab inci_concor race if confirmedwv!=9 & confirmedwv!=4, col m
