clear all
global Dir "E:\Desktop\Projects\Putonghua\Data\Cleaning"
cd $Dir

use cfps2018person_202012.dta, clear
replace urban18=. if urban18==-9

merge 1:1 pid using ".\parentsinfo\parents_edu.dta"
keep if _merge==3
drop _merge

merge 1:1 pid using ".\locationinfo\locationinfo.dta"
keep if _merge==3
drop _merge

merge 1:1 pid using ".\locationinfo\hukouinfo.dta"
drop if _merge==2
drop _merge

gen non_immigrant=1 if provcd18==location3
replace non_immigrant=0 if provcd18!=location3

gen immigrant=0 if provcd18==location0
replace immigrant=1 if provcd18!=location0

rename location3 provid
drop if provid==.

merge m:1 provid using info.dta
tab _merge
keep if _merge==3
drop _merge

rename provid province
rename ibirthy_update birthyear

gen maxparentschooling=max(fatheredu2,motheredu2)

gen reformyearmonth=Year+0.0 if inrange(Month, 1, 6)
replace reformyearmonth=Year+0.5 if inrange(Month, 7, 12)

gen xiaoxuebeginyear=birthyear+6 if birthmonth<=8
replace xiaoxuebeginyear=birthyear+6+1 if birthmonth>8 & birthmonth<.

gen treatment = 0 if reformyearmonth>xiaoxuebeginyear+6 | reformyearmonth==.
replace treatment = 1 if reformyearmonth<=xiaoxuebeginyear+6

keep if birthyear>=1985 &  birthyear<=2000

bysort province: gen provincepeople=_N
drop if provincepeople<=20

gen birthyear_1=birthyear-1989
gen birthyear_2=(birthyear-1989)^2

foreach v of varlist qn12012 qn12016 qn406 qn407 qn411 qn414 qn418 qn420 {
    replace `v'=. if `v'<=0
}

gen depression = qn406+qn407+qn411+qn414+qn418+qn420
gen depressionsevere = 1 if depression>12 & depression<.
replace depressionsevere = 0 if depression<=12

// egen double_cluster=group(province birthyear)

global dependent_vars immigrant qn12012 qn12016
global independent_vars treatment i.province i.birthyear i.birthmonth ///
 urban18 gender motheredu2 fatheredu2
global vce_option vce (cluster province)
global outreg_option dec(3) stats(coef se) title(The Impact of Putonghua Promotion (Reduced Form)) nocons noni adjr2 replace tex label ///
		keep(treatment) addtext(Province FE, YES, Birth Year FE, YES, Birth Month FE, YES, ///
		Province Linear Time Trend, YES, Province Quadratic Time Trend, YES, Control Variables, YES)
global table_option varlabel keep(treatment) b star(0.1 0.05 0.01) stats(r2_a N) varwidth(24)

estimates clear
foreach v of varlist  $dependent_vars {
reg `v' $independent_vars , $vce_option
eststo `v'main
}
estimates table *main, $table_option
outreg2 [*main] using "./Output/main.tex", $outreg_option
