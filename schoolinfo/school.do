clear all
// cd E:\Desktop\Projects\CFPS0902\0.DataCleaning\schoolinfo
cd $Dir\schoolinfo

// import excel "E:\Desktop\Projects\CFPS0902\0.DataCleaning\schoolinfo\population.xlsx", sheet("Sheet1") firstrow clear
// gen provd = subinstr(年末人口数PopulationatYearend单位, " ", "", .)
// rename B year
// rename C popu
// destring popu, replace
// drop if year<2009
// drop 年末人口数PopulationatYearend单位
// save popu_new, replace

// import excel "E:\Desktop\Projects\CFPS0902\0.DataCleaning\schoolinfo\population.xlsx", sheet("Sheet2") firstrow clear
// gen provd = subinstr(省, " ", "", .)
// drop 省
// destring 年 人口, replace
// rename 年 year
// rename 人口 popu
// append using popu_new
// sort provd year
// save popu, replace

import delimited "E:\Desktop\Projects\CFPS0902\0.DataCleaning\schoolinfo\popu.csv", varnames(1) encoding(UTF-8) clear
gen provd = subinstr(地区, " ", "", .)
drop 地区 region
reshape long t, i(provd) j(year)
rename t popu
drop if provd == "全国" | provd == "合计" | provd == "总计"
save popu, replace

forvalues i = 1996(1)2010 {
	import excel "E:\Desktop\Projects\CFPS0902\0.DataCleaning\schoolinfo\school.xlsx", sheet("`i'") firstrow clear
	gen provd = strtrim(regexr(regexr(A, "\s*[a-zA-Z]+", ""), "\s*[a-zA-Z]+", ""))
	gen 城镇小学数量 = 小学城市+小学县镇
    gen 农村小学数量 = 小学农村
	gen 城镇初中数量 = 初中城市+初中县镇
    gen 农村初中数量 = 初中农村
    keep 城镇小学数量 农村小学数量 城镇初中数量 农村初中数量 provd
    gen year = `i'
	save school_`i', replace
} 

forvalues i = 2011(1)2015 {
	import excel "E:\Desktop\Projects\CFPS0902\0.DataCleaning\schoolinfo\school.xlsx", sheet("`i'") firstrow clear
	gen provd = strtrim(regexr(regexr(A, "\s*[a-zA-Z]+", ""), "\s*[a-zA-Z]+", ""))
	gen 城镇小学数量 = 小学城区+小学城乡结合区+小学镇区+小学镇乡结合区
    gen 农村小学数量 = 小学农村
	gen 城镇初中数量 = 初中城区+初中城乡结合区+初中镇区+初中镇乡结合区
    gen 农村初中数量 = 初中农村
    keep 城镇小学数量 农村小学数量 城镇初中数量 农村初中数量 provd
    gen year = `i'
	save school_`i', replace
} 

use school_1996, clear
forvalues i = 1997(1)2015 {
	append using school_`i'
}
sort provd year
drop if provd == "全国" | provd == "合计" | provd == "总计"

merge 1:1 provd year using popu
drop _merge

foreach v of varlist 城镇小学数量 农村小学数量 城镇初中数量 农村初中数量 {
	gen `v'per = `v'/popu
}

save school, replace

use school, clear

forvalues i = 1990(1)1999 {
	foreach v of varlist 城镇小学数量 农村小学数量  {
		egen `v'per`i' = mean(cond(inrange(year, `i'+6, `i'+1+6+6)),`v'per, .), by(provd)
	}	
}

forvalues i = 1990(1)1999 {
	foreach v of varlist 城镇初中数量 农村初中数量  {
		egen `v'per`i' = mean(cond(inrange(year, `i'+6+6, `i'+1+6+6+3)),`v'per, .), by(provd)
	}	
}

drop 城镇小学数量-农村初中数量per
duplicates drop 

reshape long 城镇小学数量per 农村小学数量per 城镇初中数量per 农村初中数量per, i(provd) j(year)
reshape long @小学数量per @初中数量per, i(provd year) j(location) string
rename provd prov_CN
merge m:1 prov_CN using info
drop _merge
rename year ibirthy_update
gen hukou3=1 if location=="农村"
replace hukou3=0 if location=="城镇"
keep hukou3 provid ibirthy_update 小学数量per 初中数量per
replace 小学数量per = 小学数量per*10
replace 小学数量per = 初中数量per*10
save school_info, replace
