clear all
cd E:\Desktop\Projects\Putonghua\Data\CLDS

use CLDS2014-individual-panaldata-160520-STATA_utf8.dta, clear
// drop _merge
drop if I1_3_1_2012<100000
gen provid = I1_3_1_2012/10000
rename I1_3_1_2012 province
merge m:1 provid using info
keep if _merge==3
drop _merge
rename birthmonth_2014 birthmonth
drop if birthmonth>100 | birthmonth<0
drop if birthyear>3000 | birthyear<0

gen reformyearmonth=Year+0.0 if inrange(Month, 1, 6)
replace reformyearmonth=Year+0.5 if inrange(Month, 7, 12)

gen xiaoxuebeginyear=birthyear+6 if birthmonth<=8
replace xiaoxuebeginyear=birthyear+6+1 if birthmonth>8 & birthmonth<.

gen treatment = 0 if reformyearmonth>xiaoxuebeginyear+6 | reformyearmonth==.
replace treatment = 1 if reformyearmonth<=xiaoxuebeginyear+6

gen treatmentlength = 0 if reformyearmonth>xiaoxuebeginyear+6 | reformyearmonth==.
replace treatmentlength = xiaoxuebeginyear+6-reformyearmonth+0.5 if reformyearmonth<=xiaoxuebeginyear+6
replace treatmentlength = 6 if treatmentlength>=6

// keep if birthyear>=1980 &  birthyear<=2000
// bysort province: gen provincepeople=_N
// drop if provincepeople<=20
rename I10_9_2012 I10_9
gen speak_cont = -I10_9+5
gen speak_class = 1 if I10_9==1 | I10_9==2
replace speak_class = 0 if I10_9>2 & I10_9<.
gen speak_class1 = 1 if I10_9==1
replace speak_class1 = 0 if I10_9>=2 & I10_9<.

rename I1_8_3_2014 I1_8_3
rename I1_8_4_2014 I1_8_4
gen onwork_speak = 1 if I1_8_3==1
replace onwork_speak = 0 if I1_8_3>1 & I1_8_3<.
gen afterwork_speak = 1 if I1_8_4==1
replace afterwork_speak = 0 if I1_8_4>1 & I1_8_4<.

gen dropp = 1 if prov_CN == "北京" | prov_CN == "天津" | prov_CN == "上海" 
// | prov_CN == "河北" | prov_CN == "吉林" ///
//  | prov_CN == "辽宁" | prov_CN == "黑龙江"

estimates clear
foreach v of varlist speak_cont speak_class speak_class1 onwork_speak afterwork_speak ///
 {
reg `v' treatmentlength i.birthyear i.province ///
utype gender if (dropp != 1 & inrange(birthyear, 1989, 1999) & I2_15_2014==1), vce(cluster province)
eststo `v'main
}
estimates table *main,  varlabel ///
keep(treatmentlength) b star(0.1 0.05 0.01) stats(r2_a N) varwidth(24)

/*
i.province#c.birthyear 
reg pth1 treatmentlength i.birthyear i.province i.province#c.birthyear if utype==1, vce(cluster province)

//  if I10_8==1
 // if utype==1
