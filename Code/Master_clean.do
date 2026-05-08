******************************************************************************
* Master_clean.do
* "What's in a Debt Rating Agency Methodologies and Firms' Financing and
*  Investment Decisions" -- Fracassi & Weitzner
*
* PURPOSE: Build all datasets needed for the regression analysis.
*   Raw data  -> [Data/Intermediate/] intermediate checkpoint files
*             -> [Data/Processed/]    final datasets used by Regressions_clean.do
*
* INTERMEDIATE FILES (Data/Intermediate/):
*   Master_v1.dta, match2.dta, match2_1norep.dta, match3.dta,
*   match3_1norep.dta, Matched Sample_v2.dta, Matched Sample_v2_1norep.dta,
*   CAR_v1.dta, CAR_vTicker.dta, matchcs.dta, matchcs2.dta, temp.dta
*
* FINAL OUTPUT FILES (Data/Processed/):
* RUNTIME: ~5--10 minutes
********************************************************************************

set more off

* ------------------------------------------------------------------------------
* 0. PORTABLE PATH SETUP
*    Change global root to your machine's path; everything else follows.
* ------------------------------------------------------------------------------

global root    "C:\Users\cf8745\Box\Research\Rating Agency Paper - Final\ReplicationPackage"

global raw     "$root/Data/Raw"
global proc    "$root/Data/Processed"
global inter   "$root/Data/Intermediate"
global code    "$root/Code"

* Create output folders if they do not exist
capture mkdir "$proc"
capture mkdir "$inter"

* Log
capture log close
log using "$code/Master_clean.log", replace text

* Source subdirectory globals (raw inputs)
global compustat    "$raw/Compustat"
global crsp         "$raw/CRSP"
global eikon        "$raw/Eikon"
global icebaml      "$raw/ICE-BAML"
global manual       "$raw/Manual"
global cds          "$raw/CDS"


********************************************************************************
* SECTION 1: LOAD COMPUSTAT AND DEFINE SAMPLE
*
* Source: Compustat Fundamentals Quarterly (US, non-financial, 2006--2015).
* CompustatQ_v2.dta is a pre-filtered version keeping only the variables
* needed for this project. The filtering code (CompustatQ_v1 -> v2) is
* commented out in the original file; CompustatQ_v2.dta is the starting point.
********************************************************************************

use "$compustat/CompustatQ_v2.dta", clear

drop if missing(gvkey)
destring gvkey, g(gvkey_d)

* US firms only
drop if fic != "USA"

destring sic, replace

* One duplicate per quarter-gvkey: keep later date
gsort datacqtr gvkey -datadate
duplicates drop datacqtr gvkey, force

* Parse quarter string into numeric year and quarter
gen datacyr = substr(datacqtr, 1, 4)
destring datacyr, replace
gen datacq = substr(datacqtr, 6, 1)
destring datacq, replace

gen yearquarter = yq(datacyr, datacq)
format yearquarter %tq

gen year  = year(datadate)
gen month = month(datadate)

* Numeric panel identifiers
egen timecode    = group(datacqtr)
egen companycode = group(gvkey)
tsset companycode timecode

* Fama-French 49-industry and 10-industry classifications
/****************************************
* ffind.ado
* Creates variable containing Fama-French
* industry classification.
*
* Author:  Judson Caskey, UCLA
*          December 9, 2007
*
****************************************/

capture program drop ffind

program define ffind
	version 9.2
	syntax varlist(min=1 max=1 numeric) [if] [in], newvar(string) type(numlist max=1 min=1)

	tempvar ftyp
	tokenize "`type'"
	local `ftyp'=`1'
	
	* Check if newvar is valid variable name
	capture confirm new variable `newvar'
	if _rc != 0 {
		di as error "Variable `newvar' is invalid"
		exit 111
		}

	* Check type
	if ~inlist(``ftyp'',5,10,12,17,30,38,48,49) {
		di as error "Type must be 5, 10, 12, 17, 30, 38, 48 or 49"
		exit 111
		}

	* Set industries

	tempvar ffind
	tokenize "`varlist'"
	local `ffind' "`1'"


	qui gen `newvar'=.
	label variable `newvar' "Fama-French industry code (``ftyp'' industries)"

	capture label drop `newvar'
	if ``ftyp''==5 {
		label define `newvar' 1 "Consumer Durables, NonDurables, Wholesale, Retail, and Some Services (Laundries, Repair Shops)" 2 "Manufacturing, Energy, and Utilities" 3 "Business Equipment, Telephone and Television Transmission" 4 "Healthcare, Medical Equipment, and Drugs" 5 "Other -- Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment, Finance"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999) | inrange(``ffind'',2000,2399) | inrange(``ffind'',2700,2749) | inrange(``ffind'',2770,2799) | inrange(``ffind'',3100,3199) | inrange(``ffind'',3940,3989) | inrange(``ffind'',2500,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3630,3659) | inrange(``ffind'',3710,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3900,3939) | inrange(``ffind'',3990,3999) | inrange(``ffind'',5000,5999) | inrange(``ffind'',7200,7299) | inrange(``ffind'',7600,7699)
		qui replace `newvar'=2 if inrange(``ffind'',2520,2589) | inrange(``ffind'',2600,2699) | inrange(``ffind'',2750,2769) | inrange(``ffind'',2800,2829) | inrange(``ffind'',2840,2899) | inrange(``ffind'',3000,3099) | inrange(``ffind'',3200,3569) | inrange(``ffind'',3580,3629) | inrange(``ffind'',3700,3709) | inrange(``ffind'',3712,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3717,3749) | inrange(``ffind'',3752,3791) | inrange(``ffind'',3793,3799) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3860,3899) | inrange(``ffind'',1200,1399) | inrange(``ffind'',2900,2999) | inrange(``ffind'',4900,4949)
		qui replace `newvar'=3 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3660,3692) | inrange(``ffind'',3694,3699) | inrange(``ffind'',3810,3839) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7373,7373) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7391,7391) | inrange(``ffind'',8730,8734) | inrange(``ffind'',4800,4899)
		qui replace `newvar'=4 if inrange(``ffind'',2830,2839) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3859) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=5 if missing(`newvar') & ~missing(``ffind'')
		}
	else if ``ftyp''==10 {
		label define `newvar' 1 "Consumer NonDurables -- Food, Tobacco, Textiles, Apparel, Leather, Toys" 2 "Consumer Durables -- Cars, TV's, Furniture, Household Appliances" 3 "Manufacturing -- Machinery, Trucks, Planes, Chemicals, Off Furn, Paper, Com Printing" 4 "Oil, Gas, and Coal Extraction and Products" 5 "Business Equipment -- Computers, Software, and Electronic Equipment" 6 "Telephone and Television Transmission" 7 "Wholesale, Retail, and Some Services (Laundries, Repair Shops)" 8 "Healthcare, Medical Equipment, and Drugs" 9 "Utilities" 10 "Other -- Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment, Finance"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999) | inrange(``ffind'',2000,2399) | inrange(``ffind'',2700,2749) | inrange(``ffind'',2770,2799) | inrange(``ffind'',3100,3199) | inrange(``ffind'',3940,3989)
		qui replace `newvar'=2 if inrange(``ffind'',2500,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3630,3659) | inrange(``ffind'',3710,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3900,3939) | inrange(``ffind'',3990,3999)
		qui replace `newvar'=3 if inrange(``ffind'',2520,2589) | inrange(``ffind'',2600,2699) | inrange(``ffind'',2750,2769) | inrange(``ffind'',2800,2829) | inrange(``ffind'',2840,2899) | inrange(``ffind'',3000,3099) | inrange(``ffind'',3200,3569) | inrange(``ffind'',3580,3629) | inrange(``ffind'',3700,3709) | inrange(``ffind'',3712,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3717,3749) | inrange(``ffind'',3752,3791) | inrange(``ffind'',3793,3799) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3860,3899)
		qui replace `newvar'=4 if inrange(``ffind'',1200,1399) | inrange(``ffind'',2900,2999)
		qui replace `newvar'=5 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3660,3692) | inrange(``ffind'',3694,3699) | inrange(``ffind'',3810,3839) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7373,7373) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7391,7391) | inrange(``ffind'',8730,8734)
		qui replace `newvar'=6 if inrange(``ffind'',4800,4899)
		qui replace `newvar'=7 if inrange(``ffind'',5000,5999) | inrange(``ffind'',7200,7299) | inrange(``ffind'',7600,7699)
		qui replace `newvar'=8 if inrange(``ffind'',2830,2839) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3859) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=9 if inrange(``ffind'',4900,4949)
		qui replace `newvar'=10 if missing(`newvar') & ~missing(``ffind'')
		}
	else if ``ftyp''==12 {
		label define `newvar' 1 "Consumer NonDurables -- Food, Tobacco, Textiles, Apparel, Leather, Toys" 2 "Consumer Durables -- Cars, TV's, Furniture, Household Appliances" 3 "Manufacturing -- Machinery, Trucks, Planes, Off Furn, Paper, Com Printing" 4 "Oil, Gas, and Coal Extraction and Products" 5 "Chemicals and Allied Products" 6 "Business Equipment -- Computers, Software, and Electronic Equipment" 7 "Telephone and Television Transmission" 8 "Utilities" 9 "Wholesale, Retail, and Some Services (Laundries, Repair Shops)" 10 "Healthcare, Medical Equipment, and Drugs" 11 "Finance" 12 "Other -- Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999) | inrange(``ffind'',2000,2399) | inrange(``ffind'',2700,2749) | inrange(``ffind'',2770,2799) | inrange(``ffind'',3100,3199) | inrange(``ffind'',3940,3989)
		qui replace `newvar'=2 if inrange(``ffind'',2500,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3630,3659) | inrange(``ffind'',3710,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3900,3939) | inrange(``ffind'',3990,3999)
		qui replace `newvar'=3 if inrange(``ffind'',2520,2589) | inrange(``ffind'',2600,2699) | inrange(``ffind'',2750,2769) | inrange(``ffind'',3000,3099) | inrange(``ffind'',3200,3569) | inrange(``ffind'',3580,3629) | inrange(``ffind'',3700,3709) | inrange(``ffind'',3712,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3717,3749) | inrange(``ffind'',3752,3791) | inrange(``ffind'',3793,3799) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3860,3899)
		qui replace `newvar'=4 if inrange(``ffind'',1200,1399) | inrange(``ffind'',2900,2999)
		qui replace `newvar'=5 if inrange(``ffind'',2800,2829) | inrange(``ffind'',2840,2899)
		qui replace `newvar'=6 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3660,3692) | inrange(``ffind'',3694,3699) | inrange(``ffind'',3810,3829) | inrange(``ffind'',7370,7379)
		qui replace `newvar'=7 if inrange(``ffind'',4800,4899)
		qui replace `newvar'=8 if inrange(``ffind'',4900,4949)
		qui replace `newvar'=9 if inrange(``ffind'',5000,5999) | inrange(``ffind'',7200,7299) | inrange(``ffind'',7600,7699)
		qui replace `newvar'=10 if inrange(``ffind'',2830,2839) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3859) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=11 if inrange(``ffind'',6000,6999)
		qui replace `newvar'=12 if missing(`newvar') & ~missing(``ffind'')
		}

	else if ``ftyp''==17 {
		label define `newvar' 1 "Food" 2 "Mining and Minerals" 3 "Oil and Petroleum Products" 4 "Textiles, Apparel & Footware" 5 "Consumer Durables" 6 "Chemicals" 7 "Drugs, Soap, Prfums, Tobacco" 8 "Construction and Construction Materials" 9 "Steel Works Etc" 10 "Fabricated Products" 11 "Machinery and Business Equipment" 12 "Automobiles" 13 "Transportation" 14 "Utilities" 15 "Retail Stores" 16 "Banks, Insurance Companies, and Other Financials" 17 "Other"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',900,999) | inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2047,2047) | inrange(``ffind'',2048,2048) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2064,2068) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097) | inrange(``ffind'',2098,2099) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5191,5191)
		qui replace `newvar'=2 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1040,1049) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1200,1299) | inrange(``ffind'',1400,1499) | inrange(``ffind'',5050,5052)
		qui replace `newvar'=3 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',5170,5172)
		qui replace `newvar'=4 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2296,2296) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2300,2390) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2396,2396) | inrange(``ffind'',2397,2399) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965) | inrange(``ffind'',5130,5139)
		qui replace `newvar'=5 if inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3060,3069) | inrange(``ffind'',3070,3079) | inrange(``ffind'',3080,3089) | inrange(``ffind'',3090,3099) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949) | inrange(``ffind'',3960,3962) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099)
		qui replace `newvar'=6 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899) | inrange(``ffind'',5160,5169)
		qui replace `newvar'=7 if inrange(``ffind'',2100,2199) | inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5194,5194)
		qui replace `newvar'=8 if inrange(``ffind'',800,899) | inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2440,2449) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5198,5198) | inrange(``ffind'',5210,5211) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251)
		qui replace `newvar'=9 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=10 if inrange(``ffind'',3410,3412) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479) | inrange(``ffind'',3480,3489) | inrange(``ffind'',3490,3499)
		qui replace `newvar'=11 if inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3570,3579) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599) | inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3695,3695) | inrange(``ffind'',3699,3699) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3811,3811) | inrange(``ffind'',3812,3812) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3950,3955) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081)
		qui replace `newvar'=12 if inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5510,5521) | inrange(``ffind'',5530,5531) | inrange(``ffind'',5560,5561) | inrange(``ffind'',5570,5571) | inrange(``ffind'',5590,5599)
		qui replace `newvar'=13 if inrange(``ffind'',3713,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3724,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3728) | inrange(``ffind'',3730,3731) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3740,3743) | inrange(``ffind'',3760,3769) | inrange(``ffind'',3790,3790) | inrange(``ffind'',3795,3795) | inrange(``ffind'',3799,3799) | inrange(``ffind'',4000,4013) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4220,4229) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4742) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=14 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=15 if inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5421) | inrange(``ffind'',5430,5431) | inrange(``ffind'',5440,5441) | inrange(``ffind'',5450,5451) | inrange(``ffind'',5460,5461) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5540,5541) | inrange(``ffind'',5550,5551) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5750) | inrange(``ffind'',5800,5813) | inrange(``ffind'',5890,5890) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5921) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5960,5963) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=16 if inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6023) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6049) | inrange(``ffind'',6050,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6112) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6163) | inrange(``ffind'',6172,6172) | inrange(``ffind'',6199,6199) | inrange(``ffind'',6200,6299) | inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6312) | inrange(``ffind'',6320,6324) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6371) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411) | inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6611,6611) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6790,6790) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=17 if missing(`newvar') & ~missing(``ffind'')

		}

	else if ``ftyp''==30 {
		label define `newvar' 1 "Food Products" 2 "Beer & Liquor" 3 "Tobacco Products" 4 "Recreation" 5 "Printing and Publishing" 6 "Consumer Goods" 7 "Apparel" 8 "Healthcare, Medical Equipment, Pharmaceutical Products" 9 "Chemicals" 10 "Textiles" 11 "Construction and Construction Materials" 12 "Steel Works Etc" 13 "Fabricated Products and Machinery" 14 "Electrical Equipment" 15 "Automobiles and Trucks" 16 "Aircraft, ships, and railroad equipment" 17 "Precious Metals, Non-Metallic, and Industrial Metal Mining" 18 "Coal" 19 "Petroleum and Natural Gas" 20 "Utilities" 21 "Communication" 22 "Personal and Business Services" 23 "Business Equipment" 24 "Business Supplies and Shipping Containers" 25 "Transportation" 26 "Wholesale" 27 "Retail" 28 "Restaraunts, Hotels, Motels" 29 "Banking, Insurance, Real Estate, Trading" 30 "Everything Else"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',910,919) | inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2048,2048) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2064,2068) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097) | inrange(``ffind'',2098,2099)
		qui replace `newvar'=2 if inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085)
		qui replace `newvar'=3 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=4 if inrange(``ffind'',920,999) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949) | inrange(``ffind'',7800,7829) | inrange(``ffind'',7830,7833) | inrange(``ffind'',7840,7841) | inrange(``ffind'',7900,7900) | inrange(``ffind'',7910,7911) | inrange(``ffind'',7920,7929) | inrange(``ffind'',7930,7933) | inrange(``ffind'',7940,7949) | inrange(``ffind'',7980,7980) | inrange(``ffind'',7990,7999)
		qui replace `newvar'=5 if inrange(``ffind'',2700,2709) | inrange(``ffind'',2710,2719) | inrange(``ffind'',2720,2729) | inrange(``ffind'',2730,2739) | inrange(``ffind'',2740,2749) | inrange(``ffind'',2750,2759) | inrange(``ffind'',2770,2771) | inrange(``ffind'',2780,2789) | inrange(``ffind'',2790,2799) | inrange(``ffind'',3993,3993)
		qui replace `newvar'=6 if inrange(``ffind'',2047,2047) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',3160,3161) | inrange(``ffind'',3170,3171) | inrange(``ffind'',3172,3172) | inrange(``ffind'',3190,3199) | inrange(``ffind'',3229,3229) | inrange(``ffind'',3260,3260) | inrange(``ffind'',3262,3263) | inrange(``ffind'',3269,3269) | inrange(``ffind'',3230,3231) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3800,3800) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3960,3962) | inrange(``ffind'',3991,3991) | inrange(``ffind'',3995,3995)
		qui replace `newvar'=7 if inrange(``ffind'',2300,2390) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965)
		qui replace `newvar'=8 if inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2835,2835) | inrange(``ffind'',2836,2836) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3849) | inrange(``ffind'',3850,3851) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=9 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899)
		qui replace `newvar'=10 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2397,2399)
		qui replace `newvar'=11 if inrange(``ffind'',800,899) | inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2660,2661) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3295,3299) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',3490,3499) | inrange(``ffind'',3996,3996)
		qui replace `newvar'=12 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3370,3379) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=13 if inrange(``ffind'',3400,3400) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479) | inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3538,3538) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599)
		qui replace `newvar'=14 if inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3640,3644) | inrange(``ffind'',3645,3645) | inrange(``ffind'',3646,3646) | inrange(``ffind'',3648,3649) | inrange(``ffind'',3660,3660) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3699,3699)
		qui replace `newvar'=15 if inrange(``ffind'',2296,2296) | inrange(``ffind'',2396,2396) | inrange(``ffind'',3010,3011) | inrange(``ffind'',3537,3537) | inrange(``ffind'',3647,3647) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3700,3700) | inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3713,3713) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3790,3791) | inrange(``ffind'',3799,3799)
		qui replace `newvar'=16 if inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3723,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3729) | inrange(``ffind'',3730,3731) | inrange(``ffind'',3740,3743)
		qui replace `newvar'=17 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1040,1049) | inrange(``ffind'',1050,1059) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1070,1079) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1100,1119) | inrange(``ffind'',1400,1499)
		qui replace `newvar'=18 if inrange(``ffind'',1200,1299)
		qui replace `newvar'=19 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1330,1339) | inrange(``ffind'',1370,1379) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',2990,2999)
		qui replace `newvar'=20 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=21 if inrange(``ffind'',4800,4800) | inrange(``ffind'',4810,4813) | inrange(``ffind'',4820,4822) | inrange(``ffind'',4830,4839) | inrange(``ffind'',4840,4841) | inrange(``ffind'',4880,4889) | inrange(``ffind'',4890,4890) | inrange(``ffind'',4891,4891) | inrange(``ffind'',4892,4892) | inrange(``ffind'',4899,4899)
		qui replace `newvar'=22 if inrange(``ffind'',7020,7021) | inrange(``ffind'',7030,7033) | inrange(``ffind'',7200,7200) | inrange(``ffind'',7210,7212) | inrange(``ffind'',7214,7214) | inrange(``ffind'',7215,7216) | inrange(``ffind'',7217,7217) | inrange(``ffind'',7218,7218) | inrange(``ffind'',7219,7219) | inrange(``ffind'',7220,7221) | inrange(``ffind'',7230,7231) | inrange(``ffind'',7240,7241) | inrange(``ffind'',7250,7251) | inrange(``ffind'',7260,7269) | inrange(``ffind'',7270,7290) | inrange(``ffind'',7291,7291) | inrange(``ffind'',7292,7299) | inrange(``ffind'',7300,7300) | inrange(``ffind'',7310,7319) | inrange(``ffind'',7320,7329) | inrange(``ffind'',7330,7339) | inrange(``ffind'',7340,7342) | inrange(``ffind'',7349,7349) | inrange(``ffind'',7350,7351) | inrange(``ffind'',7352,7352) | inrange(``ffind'',7353,7353) | inrange(``ffind'',7359,7359) | inrange(``ffind'',7360,7369) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7380,7380) | inrange(``ffind'',7381,7382) | inrange(``ffind'',7383,7383) | inrange(``ffind'',7384,7384) | inrange(``ffind'',7385,7385) | inrange(``ffind'',7389,7390) | inrange(``ffind'',7391,7391) | inrange(``ffind'',7392,7392) | inrange(``ffind'',7393,7393) | inrange(``ffind'',7394,7394) | inrange(``ffind'',7395,7395) | inrange(``ffind'',7396,7396) | inrange(``ffind'',7397,7397) | inrange(``ffind'',7399,7399) | inrange(``ffind'',7500,7500) | inrange(``ffind'',7510,7519) | inrange(``ffind'',7520,7529) | inrange(``ffind'',7530,7539) | inrange(``ffind'',7540,7549) | inrange(``ffind'',7600,7600) | inrange(``ffind'',7620,7620) | inrange(``ffind'',7622,7622) | inrange(``ffind'',7623,7623) | inrange(``ffind'',7629,7629) | inrange(``ffind'',7630,7631) | inrange(``ffind'',7640,7641) | inrange(``ffind'',7690,7699) | inrange(``ffind'',8100,8199) | inrange(``ffind'',8200,8299) | inrange(``ffind'',8300,8399) | inrange(``ffind'',8400,8499) | inrange(``ffind'',8600,8699) | inrange(``ffind'',8700,8700) | inrange(``ffind'',8710,8713) | inrange(``ffind'',8720,8721) | inrange(``ffind'',8730,8734) | inrange(``ffind'',8740,8748) | inrange(``ffind'',8800,8899) | inrange(``ffind'',8900,8910) | inrange(``ffind'',8911,8911) | inrange(``ffind'',8920,8999)
		qui replace `newvar'=23 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3661,3661) | inrange(``ffind'',3662,3662) | inrange(``ffind'',3663,3663) | inrange(``ffind'',3664,3664) | inrange(``ffind'',3665,3665) | inrange(``ffind'',3666,3666) | inrange(``ffind'',3669,3669) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3695,3695) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3811,3811) | inrange(``ffind'',3812,3812) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839) | inrange(``ffind'',7373,7373)
		qui replace `newvar'=24 if inrange(``ffind'',2440,2449) | inrange(``ffind'',2520,2549) | inrange(``ffind'',2600,2639) | inrange(``ffind'',2640,2659) | inrange(``ffind'',2670,2699) | inrange(``ffind'',2760,2761) | inrange(``ffind'',3220,3221) | inrange(``ffind'',3410,3412) | inrange(``ffind'',3950,3955)
		qui replace `newvar'=25 if inrange(``ffind'',4000,4013) | inrange(``ffind'',4040,4049) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4220,4229) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4240,4249) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4749) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4782,4782) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4784,4784) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=26 if inrange(``ffind'',5000,5000) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5040,5042) | inrange(``ffind'',5043,5043) | inrange(``ffind'',5044,5044) | inrange(``ffind'',5045,5045) | inrange(``ffind'',5046,5046) | inrange(``ffind'',5047,5047) | inrange(``ffind'',5048,5048) | inrange(``ffind'',5049,5049) | inrange(``ffind'',5050,5059) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081) | inrange(``ffind'',5082,5082) | inrange(``ffind'',5083,5083) | inrange(``ffind'',5084,5084) | inrange(``ffind'',5085,5085) | inrange(``ffind'',5086,5087) | inrange(``ffind'',5088,5088) | inrange(``ffind'',5090,5090) | inrange(``ffind'',5091,5092) | inrange(``ffind'',5093,5093) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099) | inrange(``ffind'',5100,5100) | inrange(``ffind'',5110,5113) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5130,5139) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5160,5169) | inrange(``ffind'',5170,5172) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5190,5199)
		qui replace `newvar'=27 if inrange(``ffind'',5200,5200) | inrange(``ffind'',5210,5219) | inrange(``ffind'',5220,5229) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251) | inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5340,5349) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5429) | inrange(``ffind'',5430,5439) | inrange(``ffind'',5440,5449) | inrange(``ffind'',5450,5459) | inrange(``ffind'',5460,5469) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5500,5500) | inrange(``ffind'',5510,5529) | inrange(``ffind'',5530,5539) | inrange(``ffind'',5540,5549) | inrange(``ffind'',5550,5559) | inrange(``ffind'',5560,5569) | inrange(``ffind'',5570,5579) | inrange(``ffind'',5590,5599) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5799) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5929) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5950,5959) | inrange(``ffind'',5960,5969) | inrange(``ffind'',5970,5979) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=28 if inrange(``ffind'',5800,5819) | inrange(``ffind'',5820,5829) | inrange(``ffind'',5890,5899) | inrange(``ffind'',7000,7000) | inrange(``ffind'',7010,7019) | inrange(``ffind'',7040,7049) | inrange(``ffind'',7213,7213)
		qui replace `newvar'=29 if inrange(``ffind'',6000,6000) | inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6024) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6027,6027) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6113) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6130,6139) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6169) | inrange(``ffind'',6170,6179) | inrange(``ffind'',6190,6199) | inrange(``ffind'',6200,6299) | inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6319) | inrange(``ffind'',6320,6329) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6379) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411) | inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6520,6529) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6590,6599) | inrange(``ffind'',6610,6611) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6740,6779) | inrange(``ffind'',6790,6791) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6793,6793) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=30 if missing(`newvar') & ~missing(``ffind'')
		}

	else if ``ftyp''==38 {
		label define `newvar' 1 "Agriculture, forestry, and fishing" 2 "Mining" 3 "Oil and Gas Extraction" 4 "Nonmetalic Minerals Except Fuels" 5 "Construction" 6 "Food and Kindred Products" 7 "Tobacco Products" 8 "Textile Mill Products" 9 "Apparel and other Textile Products" 10 "Lumber and Wood Products" 11 "Furniture and Fixtures" 12 "Paper and Allied Products" 13 "Printing and Publishing" 14 "Chemicals and Allied Products" 15 "Petroleum and Coal Products" 16 "Rubber and Miscellaneous Plastics Products" 17 "Leather and Leather Products" 18 "Stone, Clay and Glass Products" 19 "Primary Metal Industries" 20 "Fabricated Metal Products" 21 "Machinery, Except Electrical" 22 "Electrical and Electronic Equipment" 23 "Transportation Equipment" 24 "Instruments and Related Products" 25 "Miscellaneous Manufacturing Industries" 26 "Transportation" 27 "Telephone and Telegraph Communication" 28 "Radio and Television Broadcasting" 29 "Electric, Gas, and Water Supply" 30 "Sanitary Services" 31 "Steam Supply" 32 "Irrigation Systems" 33 "Wholesale" 34 "Retail Stores" 35 "Finance, Insurance, and Real Estate" 36 "Services" 37 "Public Administration" 38 "Almost Nothing"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999)
		qui replace `newvar'=2 if inrange(``ffind'',1000,1299)
		qui replace `newvar'=3 if inrange(``ffind'',1300,1399)
		qui replace `newvar'=4 if inrange(``ffind'',1400,1499)
		qui replace `newvar'=5 if inrange(``ffind'',1500,1799)
		qui replace `newvar'=6 if inrange(``ffind'',2000,2099)
		qui replace `newvar'=7 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=8 if inrange(``ffind'',2200,2299)
		qui replace `newvar'=9 if inrange(``ffind'',2300,2399)
		qui replace `newvar'=10 if inrange(``ffind'',2400,2499)
		qui replace `newvar'=11 if inrange(``ffind'',2500,2599)
		qui replace `newvar'=12 if inrange(``ffind'',2600,2661)
		qui replace `newvar'=13 if inrange(``ffind'',2700,2799)
		qui replace `newvar'=14 if inrange(``ffind'',2800,2899)
		qui replace `newvar'=15 if inrange(``ffind'',2900,2999)
		qui replace `newvar'=16 if inrange(``ffind'',3000,3099)
		qui replace `newvar'=17 if inrange(``ffind'',3100,3199)
		qui replace `newvar'=18 if inrange(``ffind'',3200,3299)
		qui replace `newvar'=19 if inrange(``ffind'',3300,3399)
		qui replace `newvar'=20 if inrange(``ffind'',3400,3499)
		qui replace `newvar'=21 if inrange(``ffind'',3500,3599)
		qui replace `newvar'=22 if inrange(``ffind'',3600,3699)
		qui replace `newvar'=23 if inrange(``ffind'',3700,3799)
		qui replace `newvar'=24 if inrange(``ffind'',3800,3879)
		qui replace `newvar'=25 if inrange(``ffind'',3900,3999)
		qui replace `newvar'=26 if inrange(``ffind'',4000,4799)
		qui replace `newvar'=27 if inrange(``ffind'',4800,4829)
		qui replace `newvar'=28 if inrange(``ffind'',4830,4899)
		qui replace `newvar'=29 if inrange(``ffind'',4900,4949)
		qui replace `newvar'=30 if inrange(``ffind'',4950,4959)
		qui replace `newvar'=31 if inrange(``ffind'',4960,4969)
		qui replace `newvar'=32 if inrange(``ffind'',4970,4979)
		qui replace `newvar'=33 if inrange(``ffind'',5000,5199)
		qui replace `newvar'=34 if inrange(``ffind'',5200,5999)
		qui replace `newvar'=35 if inrange(``ffind'',6000,6999)
		qui replace `newvar'=36 if inrange(``ffind'',7000,8999)
		qui replace `newvar'=37 if inrange(``ffind'',9000,9999)
		qui replace `newvar'=38 if missing(`newvar') & ~missing(``ffind'')

		}
	else if ``ftyp''==48 {
		label define `newvar' 1 "Agriculture" 2 "Food Products" 3 "Candy & Soda" 4 "Beer & Liquor" 5 "Tobacco Products" 6 "Recreation" 7 "Entertainment" 8 "Printing and Publishing" 9 "Consumer Goods" 10 "Apparel" 11 "Healthcare" 12 "Medical Equipment" 13 "Pharmaceutical Products" 14 "Chemicals" 15 "Rubber and Plastic Products" 16 "Textiles" 17 "Construction Materials" 18 "Construction" 19 "Steel Works Etc" 20 "Fabricated Products" 21 "Machinery" 22 "Electrical Equipment" 23 "Automobiles and Trucks" 24 "Aircraft" 25 "Shipbuilding, Railroad Equipment" 26 "Defense" 27 "Precious Metals" 28 "Non-Metallic and Industrial Metal Mining" 29 "Coal" 30 "Petroleum and Natural Gas" 31 "Utilities" 32 "Communication" 33 "Personal Services" 34 "Business Services" 35 "Computers" 36 "Electronic Equipment" 37 "Measuring and Control Equipment" 38 "Business Supplies" 39 "Shipping Containers" 40 "Transportation" 41 "Wholesale" 42 "Retail" 43 "Restaraunts, Hotels, Motels" 44 "Banking" 45 "Insurance" 46 "Real Estate" 47 "Trading" 48 "Almost Nothing"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',910,919) | inrange(``ffind'',2048,2048)
		qui replace `newvar'=2 if inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2098,2099)
		qui replace `newvar'=3 if inrange(``ffind'',2064,2068) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097)
		qui replace `newvar'=4 if inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085)
		qui replace `newvar'=5 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=6 if inrange(``ffind'',920,999) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949)
		qui replace `newvar'=7 if inrange(``ffind'',7800,7829) | inrange(``ffind'',7830,7833) | inrange(``ffind'',7840,7841) | inrange(``ffind'',7900,7900) | inrange(``ffind'',7910,7911) | inrange(``ffind'',7920,7929) | inrange(``ffind'',7930,7933) | inrange(``ffind'',7940,7949) | inrange(``ffind'',7980,7980) | inrange(``ffind'',7990,7999)
		qui replace `newvar'=8 if inrange(``ffind'',2700,2709) | inrange(``ffind'',2710,2719) | inrange(``ffind'',2720,2729) | inrange(``ffind'',2730,2739) | inrange(``ffind'',2740,2749) | inrange(``ffind'',2770,2771) | inrange(``ffind'',2780,2789) | inrange(``ffind'',2790,2799)
		qui replace `newvar'=9 if inrange(``ffind'',2047,2047) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',3160,3161) | inrange(``ffind'',3170,3171) | inrange(``ffind'',3172,3172) | inrange(``ffind'',3190,3199) | inrange(``ffind'',3229,3229) | inrange(``ffind'',3260,3260) | inrange(``ffind'',3262,3263) | inrange(``ffind'',3269,3269) | inrange(``ffind'',3230,3231) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3800,3800) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3960,3962) | inrange(``ffind'',3991,3991) | inrange(``ffind'',3995,3995)
		qui replace `newvar'=10 if inrange(``ffind'',2300,2390) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965)
		qui replace `newvar'=11 if inrange(``ffind'',8000,8099)
		qui replace `newvar'=12 if inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3849) | inrange(``ffind'',3850,3851)
		qui replace `newvar'=13 if inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2835,2835) | inrange(``ffind'',2836,2836)
		qui replace `newvar'=14 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899)
		qui replace `newvar'=15 if inrange(``ffind'',3031,3031) | inrange(``ffind'',3041,3041) | inrange(``ffind'',3050,3053) | inrange(``ffind'',3060,3069) | inrange(``ffind'',3070,3079) | inrange(``ffind'',3080,3089) | inrange(``ffind'',3090,3099)
		qui replace `newvar'=16 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2397,2399)
		qui replace `newvar'=17 if inrange(``ffind'',800,899) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2660,2661) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3295,3299) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',3490,3499) | inrange(``ffind'',3996,3996)
		qui replace `newvar'=18 if inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799)
		qui replace `newvar'=19 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3370,3379) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=20 if inrange(``ffind'',3400,3400) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479)
		qui replace `newvar'=21 if inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3538,3538) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599)
		qui replace `newvar'=22 if inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3640,3644) | inrange(``ffind'',3645,3645) | inrange(``ffind'',3646,3646) | inrange(``ffind'',3648,3649) | inrange(``ffind'',3660,3660) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3699,3699)
		qui replace `newvar'=23 if inrange(``ffind'',2296,2296) | inrange(``ffind'',2396,2396) | inrange(``ffind'',3010,3011) | inrange(``ffind'',3537,3537) | inrange(``ffind'',3647,3647) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3700,3700) | inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3713,3713) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3790,3791) | inrange(``ffind'',3799,3799)
		qui replace `newvar'=24 if inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3723,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3729)
		qui replace `newvar'=25 if inrange(``ffind'',3730,3731) | inrange(``ffind'',3740,3743)
		qui replace `newvar'=26 if inrange(``ffind'',3760,3769) | inrange(``ffind'',3795,3795) | inrange(``ffind'',3480,3489)
		qui replace `newvar'=27 if inrange(``ffind'',1040,1049)
		qui replace `newvar'=28 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1050,1059) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1070,1079) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1100,1119) | inrange(``ffind'',1400,1499)
		qui replace `newvar'=29 if inrange(``ffind'',1200,1299)
		qui replace `newvar'=30 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1330,1339) | inrange(``ffind'',1370,1379) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',2990,2999)
		qui replace `newvar'=31 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=32 if inrange(``ffind'',4800,4800) | inrange(``ffind'',4810,4813) | inrange(``ffind'',4820,4822) | inrange(``ffind'',4830,4839) | inrange(``ffind'',4840,4841) | inrange(``ffind'',4880,4889) | inrange(``ffind'',4890,4890) | inrange(``ffind'',4891,4891) | inrange(``ffind'',4892,4892) | inrange(``ffind'',4899,4899)
		qui replace `newvar'=33 if inrange(``ffind'',7020,7021) | inrange(``ffind'',7030,7033) | inrange(``ffind'',7200,7200) | inrange(``ffind'',7210,7212) | inrange(``ffind'',7214,7214) | inrange(``ffind'',7215,7216) | inrange(``ffind'',7217,7217) | inrange(``ffind'',7219,7219) | inrange(``ffind'',7220,7221) | inrange(``ffind'',7230,7231) | inrange(``ffind'',7240,7241) | inrange(``ffind'',7250,7251) | inrange(``ffind'',7260,7269) | inrange(``ffind'',7270,7290) | inrange(``ffind'',7291,7291) | inrange(``ffind'',7292,7299) | inrange(``ffind'',7395,7395) | inrange(``ffind'',7500,7500) | inrange(``ffind'',7520,7529) | inrange(``ffind'',7530,7539) | inrange(``ffind'',7540,7549) | inrange(``ffind'',7600,7600) | inrange(``ffind'',7620,7620) | inrange(``ffind'',7622,7622) | inrange(``ffind'',7623,7623) | inrange(``ffind'',7629,7629) | inrange(``ffind'',7630,7631) | inrange(``ffind'',7640,7641) | inrange(``ffind'',7690,7699) | inrange(``ffind'',8100,8199) | inrange(``ffind'',8200,8299) | inrange(``ffind'',8300,8399) | inrange(``ffind'',8400,8499) | inrange(``ffind'',8600,8699) | inrange(``ffind'',8800,8899) | inrange(``ffind'',7510,7515)
		qui replace `newvar'=34 if inrange(``ffind'',2750,2759) | inrange(``ffind'',3993,3993) | inrange(``ffind'',7218,7218) | inrange(``ffind'',7300,7300) | inrange(``ffind'',7310,7319) | inrange(``ffind'',7320,7329) | inrange(``ffind'',7330,7339) | inrange(``ffind'',7340,7342) | inrange(``ffind'',7349,7349) | inrange(``ffind'',7350,7351) | inrange(``ffind'',7352,7352) | inrange(``ffind'',7353,7353) | inrange(``ffind'',7359,7359) | inrange(``ffind'',7360,7369) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7380,7380) | inrange(``ffind'',7381,7382) | inrange(``ffind'',7383,7383) | inrange(``ffind'',7384,7384) | inrange(``ffind'',7385,7385) | inrange(``ffind'',7389,7390) | inrange(``ffind'',7391,7391) | inrange(``ffind'',7392,7392) | inrange(``ffind'',7393,7393) | inrange(``ffind'',7394,7394) | inrange(``ffind'',7396,7396) | inrange(``ffind'',7397,7397) | inrange(``ffind'',7399,7399) | inrange(``ffind'',7519,7519) | inrange(``ffind'',8700,8700) | inrange(``ffind'',8710,8713) | inrange(``ffind'',8720,8721) | inrange(``ffind'',8730,8734) | inrange(``ffind'',8740,8748) | inrange(``ffind'',8900,8910) | inrange(``ffind'',8911,8911) | inrange(``ffind'',8920,8999) | inrange(``ffind'',4220,4229)
		qui replace `newvar'=35 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3695,3695) | inrange(``ffind'',7373,7373)
		qui replace `newvar'=36 if inrange(``ffind'',3622,3622) | inrange(``ffind'',3661,3661) | inrange(``ffind'',3662,3662) | inrange(``ffind'',3663,3663) | inrange(``ffind'',3664,3664) | inrange(``ffind'',3665,3665) | inrange(``ffind'',3666,3666) | inrange(``ffind'',3669,3669) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3812,3812)
		qui replace `newvar'=37 if inrange(``ffind'',3811,3811) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839)
		qui replace `newvar'=38 if inrange(``ffind'',2520,2549) | inrange(``ffind'',2600,2639) | inrange(``ffind'',2670,2699) | inrange(``ffind'',2760,2761) | inrange(``ffind'',3950,3955)
		qui replace `newvar'=39 if inrange(``ffind'',2440,2449) | inrange(``ffind'',2640,2659) | inrange(``ffind'',3220,3221) | inrange(``ffind'',3410,3412)
		qui replace `newvar'=40 if inrange(``ffind'',4000,4013) | inrange(``ffind'',4040,4049) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4240,4249) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4749) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4782,4782) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4784,4784) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=41 if inrange(``ffind'',5000,5000) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5040,5042) | inrange(``ffind'',5043,5043) | inrange(``ffind'',5044,5044) | inrange(``ffind'',5045,5045) | inrange(``ffind'',5046,5046) | inrange(``ffind'',5047,5047) | inrange(``ffind'',5048,5048) | inrange(``ffind'',5049,5049) | inrange(``ffind'',5050,5059) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081) | inrange(``ffind'',5082,5082) | inrange(``ffind'',5083,5083) | inrange(``ffind'',5084,5084) | inrange(``ffind'',5085,5085) | inrange(``ffind'',5086,5087) | inrange(``ffind'',5088,5088) | inrange(``ffind'',5090,5090) | inrange(``ffind'',5091,5092) | inrange(``ffind'',5093,5093) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099) | inrange(``ffind'',5100,5100) | inrange(``ffind'',5110,5113) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5130,5139) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5160,5169) | inrange(``ffind'',5170,5172) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5190,5199)
		qui replace `newvar'=42 if inrange(``ffind'',5200,5200) | inrange(``ffind'',5210,5219) | inrange(``ffind'',5220,5229) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251) | inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5340,5349) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5429) | inrange(``ffind'',5430,5439) | inrange(``ffind'',5440,5449) | inrange(``ffind'',5450,5459) | inrange(``ffind'',5460,5469) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5500,5500) | inrange(``ffind'',5510,5529) | inrange(``ffind'',5530,5539) | inrange(``ffind'',5540,5549) | inrange(``ffind'',5550,5559) | inrange(``ffind'',5560,5569) | inrange(``ffind'',5570,5579) | inrange(``ffind'',5590,5599) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5799) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5929) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5950,5959) | inrange(``ffind'',5960,5969) | inrange(``ffind'',5970,5979) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=43 if inrange(``ffind'',5800,5819) | inrange(``ffind'',5820,5829) | inrange(``ffind'',5890,5899) | inrange(``ffind'',7000,7000) | inrange(``ffind'',7010,7019) | inrange(``ffind'',7040,7049) | inrange(``ffind'',7213,7213)
		qui replace `newvar'=44 if inrange(``ffind'',6000,6000) | inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6024) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6027,6027) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6113) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6130,6139) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6169) | inrange(``ffind'',6170,6179) | inrange(``ffind'',6190,6199)
		qui replace `newvar'=45 if inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6319) | inrange(``ffind'',6320,6329) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6379) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411)
		qui replace `newvar'=46 if inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6520,6529) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6590,6599) | inrange(``ffind'',6610,6611)
		qui replace `newvar'=47 if inrange(``ffind'',6200,6299) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6740,6779) | inrange(``ffind'',6790,6791) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6793,6793) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=48 if missing(`newvar') & ~missing(``ffind'')

		}
	else if ``ftyp''==49 {
		label define `newvar' 1 "Agriculture" 2 "Food Products" 3 "Candy & Soda" 4 "Beer & Liquor" 5 "Tobacco Products" 6 "Recreation" 7 "Entertainment" 8 "Printing and Publishing" 9 "Consumer Goods" 10 "Apparel" 11 "Healthcare" 12 "Medical Equipment" 13 "Pharmaceutical Products" 14 "Chemicals" 15 "Rubber and Plastic Products" 16 "Textiles" 17 "Construction Materials" 18 "Construction" 19 "Steel Works Etc" 20 "Fabricated Products" 21 "Machinery" 22 "Electrical Equipment" 23 "Automobiles and Trucks" 24 "Aircraft" 25 "Shipbuilding, Railroad Equipment" 26 "Defense" 27 "Precious Metals" 28 "Non-Metallic and Industrial Metal Mining" 29 "Coal" 30 "Petroleum and Natural Gas" 31 "Utilities" 32 "Communication" 33 "Personal Services" 34 "Business Services" 35 "Computer Hardware" 36 "Computer Software" 37 "Electronic Equipment" 38 "Measuring and Control Equipment" 39 "Business Supplies" 40 "Shipping Containers" 41 "Transportation" 42 "Wholesale" 43 "Retail" 44 "Restaraunts, Hotels, Motels" 45 "Banking" 46 "Insurance" 47 "Real Estate" 48 "Trading" 49 "Almost Nothing"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',910,919) | inrange(``ffind'',2048,2048)
		qui replace `newvar'=2 if inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2098,2099)
		qui replace `newvar'=3 if inrange(``ffind'',2064,2068) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097)
		qui replace `newvar'=4 if inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085)
		qui replace `newvar'=5 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=6 if inrange(``ffind'',920,999) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949)
		qui replace `newvar'=7 if inrange(``ffind'',7800,7829) | inrange(``ffind'',7830,7833) | inrange(``ffind'',7840,7841) | inrange(``ffind'',7900,7900) | inrange(``ffind'',7910,7911) | inrange(``ffind'',7920,7929) | inrange(``ffind'',7930,7933) | inrange(``ffind'',7940,7949) | inrange(``ffind'',7980,7980) | inrange(``ffind'',7990,7999)
		qui replace `newvar'=8 if inrange(``ffind'',2700,2709) | inrange(``ffind'',2710,2719) | inrange(``ffind'',2720,2729) | inrange(``ffind'',2730,2739) | inrange(``ffind'',2740,2749) | inrange(``ffind'',2770,2771) | inrange(``ffind'',2780,2789) | inrange(``ffind'',2790,2799)
		qui replace `newvar'=9 if inrange(``ffind'',2047,2047) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',3160,3161) | inrange(``ffind'',3170,3171) | inrange(``ffind'',3172,3172) | inrange(``ffind'',3190,3199) | inrange(``ffind'',3229,3229) | inrange(``ffind'',3260,3260) | inrange(``ffind'',3262,3263) | inrange(``ffind'',3269,3269) | inrange(``ffind'',3230,3231) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3800,3800) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3960,3962) | inrange(``ffind'',3991,3991) | inrange(``ffind'',3995,3995)
		qui replace `newvar'=10 if inrange(``ffind'',2300,2390) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965)
		qui replace `newvar'=11 if inrange(``ffind'',8000,8099)
		qui replace `newvar'=12 if inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3849) | inrange(``ffind'',3850,3851)
		qui replace `newvar'=13 if inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2835,2835) | inrange(``ffind'',2836,2836)
		qui replace `newvar'=14 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899)
		qui replace `newvar'=15 if inrange(``ffind'',3031,3031) | inrange(``ffind'',3041,3041) | inrange(``ffind'',3050,3053) | inrange(``ffind'',3060,3069) | inrange(``ffind'',3070,3079) | inrange(``ffind'',3080,3089) | inrange(``ffind'',3090,3099)
		qui replace `newvar'=16 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2397,2399)
		qui replace `newvar'=17 if inrange(``ffind'',800,899) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2660,2661) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3295,3299) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',3490,3499) | inrange(``ffind'',3996,3996)
		qui replace `newvar'=18 if inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799)
		qui replace `newvar'=19 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3370,3379) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=20 if inrange(``ffind'',3400,3400) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479)
		qui replace `newvar'=21 if inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3538,3538) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599)
		qui replace `newvar'=22 if inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3640,3644) | inrange(``ffind'',3645,3645) | inrange(``ffind'',3646,3646) | inrange(``ffind'',3648,3649) | inrange(``ffind'',3660,3660) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3699,3699)
		qui replace `newvar'=23 if inrange(``ffind'',2296,2296) | inrange(``ffind'',2396,2396) | inrange(``ffind'',3010,3011) | inrange(``ffind'',3537,3537) | inrange(``ffind'',3647,3647) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3700,3700) | inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3713,3713) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3790,3791) | inrange(``ffind'',3799,3799)
		qui replace `newvar'=24 if inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3723,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3729)
		qui replace `newvar'=25 if inrange(``ffind'',3730,3731) | inrange(``ffind'',3740,3743)
		qui replace `newvar'=26 if inrange(``ffind'',3760,3769) | inrange(``ffind'',3795,3795) | inrange(``ffind'',3480,3489)
		qui replace `newvar'=27 if inrange(``ffind'',1040,1049)
		qui replace `newvar'=28 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1050,1059) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1070,1079) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1100,1119) | inrange(``ffind'',1400,1499)
		qui replace `newvar'=29 if inrange(``ffind'',1200,1299)
		qui replace `newvar'=30 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1330,1339) | inrange(``ffind'',1370,1379) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',2990,2999)
		qui replace `newvar'=31 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=32 if inrange(``ffind'',4800,4800) | inrange(``ffind'',4810,4813) | inrange(``ffind'',4820,4822) | inrange(``ffind'',4830,4839) | inrange(``ffind'',4840,4841) | inrange(``ffind'',4880,4889) | inrange(``ffind'',4890,4890) | inrange(``ffind'',4891,4891) | inrange(``ffind'',4892,4892) | inrange(``ffind'',4899,4899)
		qui replace `newvar'=33 if inrange(``ffind'',7020,7021) | inrange(``ffind'',7030,7033) | inrange(``ffind'',7200,7200) | inrange(``ffind'',7210,7212) | inrange(``ffind'',7214,7214) | inrange(``ffind'',7215,7216) | inrange(``ffind'',7217,7217) | inrange(``ffind'',7219,7219) | inrange(``ffind'',7220,7221) | inrange(``ffind'',7230,7231) | inrange(``ffind'',7240,7241) | inrange(``ffind'',7250,7251) | inrange(``ffind'',7260,7269) | inrange(``ffind'',7270,7290) | inrange(``ffind'',7291,7291) | inrange(``ffind'',7292,7299) | inrange(``ffind'',7395,7395) | inrange(``ffind'',7500,7500) | inrange(``ffind'',7520,7529) | inrange(``ffind'',7530,7539) | inrange(``ffind'',7540,7549) | inrange(``ffind'',7600,7600) | inrange(``ffind'',7620,7620) | inrange(``ffind'',7622,7622) | inrange(``ffind'',7623,7623) | inrange(``ffind'',7629,7629) | inrange(``ffind'',7630,7631) | inrange(``ffind'',7640,7641) | inrange(``ffind'',7690,7699) | inrange(``ffind'',8100,8199) | inrange(``ffind'',8200,8299) | inrange(``ffind'',8300,8399) | inrange(``ffind'',8400,8499) | inrange(``ffind'',8600,8699) | inrange(``ffind'',8800,8899) | inrange(``ffind'',7510,7515)
		qui replace `newvar'=34 if inrange(``ffind'',2750,2759) | inrange(``ffind'',3993,3993) | inrange(``ffind'',7218,7218) | inrange(``ffind'',7300,7300) | inrange(``ffind'',7310,7319) | inrange(``ffind'',7320,7329) | inrange(``ffind'',7330,7339) | inrange(``ffind'',7340,7342) | inrange(``ffind'',7349,7349) | inrange(``ffind'',7350,7351) | inrange(``ffind'',7352,7352) | inrange(``ffind'',7353,7353) | inrange(``ffind'',7359,7359) | inrange(``ffind'',7360,7369) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7380,7380) | inrange(``ffind'',7381,7382) | inrange(``ffind'',7383,7383) | inrange(``ffind'',7384,7384) | inrange(``ffind'',7385,7385) | inrange(``ffind'',7389,7390) | inrange(``ffind'',7391,7391) | inrange(``ffind'',7392,7392) | inrange(``ffind'',7393,7393) | inrange(``ffind'',7394,7394) | inrange(``ffind'',7396,7396) | inrange(``ffind'',7397,7397) | inrange(``ffind'',7399,7399) | inrange(``ffind'',7519,7519) | inrange(``ffind'',8700,8700) | inrange(``ffind'',8710,8713) | inrange(``ffind'',8720,8721) | inrange(``ffind'',8730,8734) | inrange(``ffind'',8740,8748) | inrange(``ffind'',8900,8910) | inrange(``ffind'',8911,8911) | inrange(``ffind'',8920,8999) | inrange(``ffind'',4220,4229)
		qui replace `newvar'=35 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3695,3695)
		qui replace `newvar'=36 if inrange(``ffind'',7370,7372) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7373,7373)
		qui replace `newvar'=37 if inrange(``ffind'',3622,3622) | inrange(``ffind'',3661,3661) | inrange(``ffind'',3662,3662) | inrange(``ffind'',3663,3663) | inrange(``ffind'',3664,3664) | inrange(``ffind'',3665,3665) | inrange(``ffind'',3666,3666) | inrange(``ffind'',3669,3669) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3812,3812)
		qui replace `newvar'=38 if inrange(``ffind'',3811,3811) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839)
		qui replace `newvar'=39 if inrange(``ffind'',2520,2549) | inrange(``ffind'',2600,2639) | inrange(``ffind'',2670,2699) | inrange(``ffind'',2760,2761) | inrange(``ffind'',3950,3955)
		qui replace `newvar'=40 if inrange(``ffind'',2440,2449) | inrange(``ffind'',2640,2659) | inrange(``ffind'',3220,3221) | inrange(``ffind'',3410,3412)
		qui replace `newvar'=41 if inrange(``ffind'',4000,4013) | inrange(``ffind'',4040,4049) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4240,4249) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4749) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4782,4782) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4784,4784) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=42 if inrange(``ffind'',5000,5000) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5040,5042) | inrange(``ffind'',5043,5043) | inrange(``ffind'',5044,5044) | inrange(``ffind'',5045,5045) | inrange(``ffind'',5046,5046) | inrange(``ffind'',5047,5047) | inrange(``ffind'',5048,5048) | inrange(``ffind'',5049,5049) | inrange(``ffind'',5050,5059) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081) | inrange(``ffind'',5082,5082) | inrange(``ffind'',5083,5083) | inrange(``ffind'',5084,5084) | inrange(``ffind'',5085,5085) | inrange(``ffind'',5086,5087) | inrange(``ffind'',5088,5088) | inrange(``ffind'',5090,5090) | inrange(``ffind'',5091,5092) | inrange(``ffind'',5093,5093) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099) | inrange(``ffind'',5100,5100) | inrange(``ffind'',5110,5113) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5130,5139) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5160,5169) | inrange(``ffind'',5170,5172) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5190,5199)
		qui replace `newvar'=43 if inrange(``ffind'',5200,5200) | inrange(``ffind'',5210,5219) | inrange(``ffind'',5220,5229) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251) | inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5340,5349) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5429) | inrange(``ffind'',5430,5439) | inrange(``ffind'',5440,5449) | inrange(``ffind'',5450,5459) | inrange(``ffind'',5460,5469) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5500,5500) | inrange(``ffind'',5510,5529) | inrange(``ffind'',5530,5539) | inrange(``ffind'',5540,5549) | inrange(``ffind'',5550,5559) | inrange(``ffind'',5560,5569) | inrange(``ffind'',5570,5579) | inrange(``ffind'',5590,5599) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5799) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5929) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5950,5959) | inrange(``ffind'',5960,5969) | inrange(``ffind'',5970,5979) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=44 if inrange(``ffind'',5800,5819) | inrange(``ffind'',5820,5829) | inrange(``ffind'',5890,5899) | inrange(``ffind'',7000,7000) | inrange(``ffind'',7010,7019) | inrange(``ffind'',7040,7049) | inrange(``ffind'',7213,7213)
		qui replace `newvar'=45 if inrange(``ffind'',6000,6000) | inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6024) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6027,6027) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6113) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6130,6139) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6169) | inrange(``ffind'',6170,6179) | inrange(``ffind'',6190,6199)
		qui replace `newvar'=46 if inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6319) | inrange(``ffind'',6320,6329) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6379) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411)
		qui replace `newvar'=47 if inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6520,6529) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6590,6599) | inrange(``ffind'',6610,6611)
		qui replace `newvar'=48 if inrange(``ffind'',6200,6299) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6740,6779) | inrange(``ffind'',6790,6791) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6793,6793) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=49 if missing(`newvar') & ~missing(``ffind'')

		}
	else {
		di as error "Type must be 5, 10, 12, 17, 30, 38, 48 or 49"
		exit 111
		}


end
ffind sic, newvar(ffi)   type(49)
ffind sic, newvar(ffi10) type(10)
egen industry   = group(ffi)
egen industry10 = group(ffi10)

* Industry -- time fixed-effect codes (used in matching and some regressions)
egen itimecode   = group(industry   timecode)
egen itimecode10 = group(industry10 timecode)


********************************************************************************
* SECTION 2: EVENT DEFINITION -- MOODY'S RULE CHANGE, JULY 31, 2013
*
* Moody's changed equity credit for preferred stock of speculative-grade firms
* from 50% to 100% effective July 31, 2013.  Treated firms are speculative-
* grade firms that held preferred stock as of the last quarter before the change.
* This section defines the event dummy and the "treatment quarter" identifier.
********************************************************************************

* Post-event dummy (event = 1 for quarters after July 31, 2013)
gen event = 1 if year >= 2014
replace event = 1 if year == 2013 & month >= 8
replace event = 0 if missing(event)

* treatmentq = 1 for the last pre-event quarter of each firm
* (the quarter used to assign treatment intensity and matching variables)
egen maxtimecode = max(timecode) if event == 0, by(companycode)
gen  treatmentq  = 1 if timecode == maxtimecode
replace treatmentq = 0 if missing(treatmentq)

* Drop firms whose last pre-event quarter is before April 2013
* (incomplete pre-treatment window would confound identification)
gen include = 0 if treatmentq == 1 & month < 4
replace include = 0 if treatmentq == 1 & year < 2013
egen maxinclude = max(include), by(companycode)
drop if maxinclude == 0 & !missing(maxinclude)


********************************************************************************
* SECTION 3: VARIABLE CONSTRUCTION -- LEVERAGE, DEBT, AND PREFERRED STOCK
********************************************************************************

*---- 3a. Debt and leverage ------------------------------------------------------------------------------------------------------------

gen me  = prccq * cshoq          // market equity ($M)
gen me2 = me / 1000              // market equity ($B)

replace dlttq = 0 if dlttq == .
replace dlcq  = 0 if dlcq  == .
egen td = rowtotal(dlcq dlttq)   // total debt

gen cash        = cheq / atq
gen logdebt     = log(td)
gen marketcap   = log(me)
gen logcash     = log(cheq)
gen logltdebt   = log(dlttq)
gen logstdebt   = log(dlcq)
gen loglt1debt  = log(1 + dlttq)
gen logst1debt  = log(1 + dlcq)
gen log1debt    = log(1 + td)
gen log1cash    = log(1 + cheq)

* Debt maturity: share of debt that is long-term
gen maturity   = dlttq / (dlttq + dlcq)
gen maturity_1 = max(maturity, 0)
replace maturity_1 = min(maturity_1, 1)
gen maturity0  = maturity_1 if treatmentq == 1
egen mmaturity0 = max(maturity0), by(gvkey)
replace maturity0 = mmaturity0
drop mmaturity0

replace dd1q = 0 if missing(dd1q)
gen maturity2   = dd1q / (dlttq + dlcq)
gen maturity2_1 = max(maturity2, 0)
replace maturity2_1 = min(maturity2_1, 1)
gen maturity20  = maturity2_1 if treatmentq == 1
egen mmaturity20 = max(maturity20), by(gvkey)
replace maturity20 = mmaturity20
drop mmaturity20

gen logdiv = log(dvy)

* Liabilities over assets
gen la = ltq / atq

* Book equity: use teqq if seqq is missing
replace seqq = teqq if missing(seqq)

* Leverage ratios
gen bl  = td / (td + seqq)       // book leverage
gen bla = td / atq               // debt-to-assets
gen ml  = td / (td + me)         // market leverage
gen ev  = seqq + td              // book enterprise value

* Debt-to-EBITDA (Begley, trailing 4 quarters)
sort companycode yearquarter
by companycode: gen debtebitda = td / (oibdpq + oibdpq[_n-1] + oibdpq[_n-2] + oibdpq[_n-3])

*---- 3b. Convert year-to-date flow variables to quarterly flows ----------------------------------
* These Compustat items are reported on a fiscal-year-to-date basis; we
* subtract the prior quarter's YTD value to recover the quarterly flow.

sort companycode fyearq fqtr timecode

foreach x in dltisy dltry capxy sivy sppey aqcy sstky prstkcy dlcchy {
    replace `x' = 0 if `x' == .
    gen `x'q = `x' if fqtr == 1
    by companycode fyearq: replace `x'q = `x' - `x'[_n-1] if fqtr >= 2 & fqtr - fqtr[_n-1] == 1
    replace `x' = `x'q
    drop `x'q
}

* Set flow variables to missing for duplicate fiscal-year quarters
* (rare but possible when a firm changes its fiscal year)
duplicates tag companycode fyearq fqtr, gen(dup1)
bys companycode fyearq fqtr (datadate): gen dup2 = 1 if dup1 == 1 & _n == 1
foreach x in dltisy dltry capxy sivy sppey aqcy sstky prstkcy dlcchy {
    replace `x' = . if dup2 == 1
}
drop dup1 dup2

*---- 3c. Debt issuance and buybacks ------------------------------------------------------------------------------------------

sort companycode yearquarter

by companycode: gen deltaltd       = dlttq - dlttq[_n-1]
by companycode: gen deltatotald    = dlttq + dlcq - (dlttq[_n-1] + dlcq[_n-1])
by companycode: gen deltaltda      = (dlttq - dlttq[_n-1]) / atq[_n-1]
by companycode: gen netissuance    = dltisy - dltry
by companycode: gen netissuancetotal = dltisy - dltry + dlcchy
by companycode: gen deltatotald2   = dlttq + dlcq - (dlttq[_n-1] + dlcq[_n-1]) if fqtr - fqtr[_n-1] == 1
by companycode: gen deltaltd2      = dlttq - dlttq[_n-1] if fqtr - fqtr[_n-1] == 1
gen lognetissuance = log(30691 + netissuance)

*---- 3d. Controls ------------------------------------------------------------------------------------------------------------------------------

gen prof  = oiadpq / atq          // profitability
gen tang  = ppentq / atq          // tangibility
gen size  = log(atq)              // log assets
gen ppe   = log(ppentq)           // log PP&E
gen sales = log(1 + saleq)        // log sales

gen atqc  = atq / (td + seqq)
gen ppec  = ppentq / (td + seqq)

by companycode: gen sga   = xsgaq / atq[_n-1]
by companycode: gen capex = capxy / atq[_n-1]
by companycode: gen rd    = xrdq  / atq[_n-1]

by companycode: gen netltdissuance  = (dltisy - dltry) / atq[_n-1]
by companycode: gen netltdev        = (dltisy - dltry) / (seqq[_n-1] + td[_n-1])
by companycode: gen ltdebtissuance  = dltisy / atq[_n-1]
by companycode: gen ltdebtbuyback   = dltry  / atq[_n-1]

by companycode: gen logltdebtissuance = log(1 + dltisy)
replace logltdebtissuance = 0 if missing(logltdebtissuance)
by companycode: gen logdebtbuyback  = log(1 + dltry)

gen logcapex     = log(1 + capxy)
gen logrd        = log(1 + xrdq)
gen logsga       = log(1 + xsgaq)
gen logsharerepo = log(1 + prstkcy)
gen logequitysale = log(1 + sstky)
gen logreturn    = log(1 + prstkcy + dvy)
gen logseqq      = log(seqq)

by companycode: gen debtissuancedummy = 1 if dltisy > 0
by companycode: replace debtissuancedummy = 0 if missing(debtissuancedummy)

by companycode: gen ndebtissuancedummy = 1 if dltisy - dltry > 0
by companycode: replace ndebtissuancedummy = 0 if missing(ndebtissuancedummy)

by companycode: gen debtincrease = 1 if td - td[_n-1] > 0
replace debtincrease = 0 if missing(debtincrease)

*---- 3e. Preferred stock ----------------------------------------------------------------------------------------------------------------

gen pref = pstkq
replace pref = 0 if missing(pref)
replace pref = 0 if pref < 0

gen prefev   = pref / (td + seqq)
gen prefev_1 = min(prefev, 1)
replace prefev_1 = max(prefev_1, 0)
gen prefevpp = prefev_1 * 100

gen prefat   = pref / atq
gen preftd   = pref / td
gen preftd2  = pref / (td + pref)
gen logpref  = log(1 + pref)

by companycode: gen prefissue = 1 if pref - pref[_n-1] > 0
replace prefissue = 0 if missing(prefissue)

*---- 3f. Market-to-book ----------------------------------------------------------------------------------------------------------------

replace txditcq = 0 if missing(txditcq)
replace pstkq   = 0 if missing(pstkq)
replace dlcq    = 0 if missing(dlcq)
replace dlttq   = 0 if missing(dlcq)

gen mk2bk  = (me + dlcq + dlttq + pstkq + txditcq) / atq
gen mk2bk2 = (me + atq - seqq) / atq

*---- 3g. Treatment assignment ----------------------------------------------------------------------------------------------------

* preferred = 1 if firm holds any preferred stock
gen preferred = 1 if pref > 0
replace preferred = 0 if missing(preferred)

* treatment = 1 if firm ever had preferred stock (across all periods)
gen treatment = 1 if preferred == 1 & treatmentq == 1
replace treatment = 0 if preferred == 0 & treatmentq == 1
egen maxtreatment = max(treatment), by(companycode)
replace treatment = maxtreatment
drop maxtreatment

*---- 3h. Sample windows ----------------------------------------------------------------------------------------------------------------

* Short sample: 2012Q3--2015Q2 (used in main regressions)
gen sample = 1 if datacyr == 2012 & datacq >= 3
replace sample = 1 if datacyr == 2013
replace sample = 1 if datacyr == 2014
replace sample = 1 if datacyr == 2015 & datacq <= 2

* Medium sample: 2011Q3--2015Q2 (used in time-series figures)
gen longsample = 1 if datacyr == 2011 & datacq >= 3
replace longsample = 1 if datacyr == 2012
replace longsample = 1 if datacyr == 2013
replace longsample = 1 if datacyr == 2014
replace longsample = 1 if datacyr == 2015 & datacq <= 2


********************************************************************************
* SECTION 4: DATA MERGES
*
* Merges in: CRSP equity returns, hand-collected preferred stock type
* classifications, convertible debt data, CDS spreads, and Thomson Eikon ratings.
********************************************************************************

gen issuer_cusip  = substr(cusip, 1, 6)
gen sixdigitcusip = issuer_cusip
gen cusip8        = substr(cusip, 1, 8)

* CRSP 2-year equity returns (matched on cusip, then on ticker for gaps)
merge m:1 cusip month year using "$crsp/Two year return_v1.dta"
drop if _merge == 2
drop _merge

merge m:1 tic month year using "$crsp/Two year return_v1 Tic.dta"
drop if _merge == 2
drop _merge
replace yearret = yearrettic if missing(yearret)

* Hand-collected preferred stock classification
* (distinguishes mandatory convertible, trust preferred, pure equity, etc.)
merge m:1 cusip using "$manual/Preferred Manual_v1.dta"
drop _merge

* Additional foreign-incorporated preferred stock (hand-collected)
merge m:1 cusip using "$manual/Preferred Manual Foreign_v1.dta", update
drop if _merge == 2
drop _merge

* Convertible debt outstanding at time of rule change
merge m:1 gvkey using "$manual/Convert_v2.dta"
drop if _merge == 2
drop _merge

* Markit CDS spreads (monthly)
merge m:1 sixdigitcusip year month using "$cds/CDS Monthly.dta"
drop if _merge == 2
drop _merge

* Post and Vanguard Natural Resources: hand-identified from FISD
* (preferred stock not captured by Compustat pstkq)
replace treatment = 1 if gvkey == "170527"
replace newpref   = 240 if gvkey == "170527"
replace convertiblepreferred = 1 if gvkey == "170527"
replace treatment = 1 if gvkey == "178684"
replace newpref   = 63  if gvkey == "178684"

* Preferred stock as share of book enterprise value
gen prefqnorm = newpref / (td + seqq)
replace prefqnorm = 0 if missing(prefqnorm)

* Fill missing indicators from hand-collected preferred classification
foreach x of varlist onlymando convertiblepreferred juniordebt pureequity defaulted trustpreferred nothing {
    replace `x' = 0 if missing(`x')
}

* Remove from treatment firms whose preferred is not affected by Moody's rule change:
*   mandatory convertible (converts to equity automatically -> already equity)
*   pureequity / juniordebt / trustpreferred / nothing (no equity credit adjustment)
replace treatment = 0 if onlymando    == 1
replace treatment = 0 if nothing      == 1
replace treatment = 0 if pureequity   == 1
replace treatment = 0 if juniordebt   == 1
replace treatment = 0 if trustpreferred == 1

* Thomson Eikon ratings (Moody's and S&P, quarterly)
merge 1:1 year month gvkey using "$eikon/Thomson Eikon_v2.dta"
drop if _merge == 2
drop _merge

* Drop Eikon outlook variables that were miscoded (not used in paper)
drop Moodynegoutlook - Moodyruroutlook

* Construct outlook/watch indicator variables
gen Snegoutlook   = 1 if SPoutlook   == "NEGATIVE"
gen Sposoutlook   = 1 if SPoutlook   == "POSITIVE"
gen Sstableoutlook = 1 if SPoutlook  == "STABLE"
gen Mnegoutlook   = 1 if Moodyoutlook == "NEG"
gen Mposoutlook   = 1 if Moodyoutlook == "POS"
gen Mstableoutlook = 1 if Moodyoutlook == "STA"
gen Mdevoutlook   = 1 if Moodyoutlook == "DEV"
gen Mruroutlook   = 1 if Moodyoutlook == "RUR"

gen Snegwatch  = 1 if SPwatch    == "NEG"
gen Sposwatch  = 1 if SPwatch    == "POS"
gen Sdevwatch  = 1 if SPwatch    == "DEV"
gen Mnegwatch  = 1 if Moodywatch == "DNG"
gen Mposwatch  = 1 if Moodywatch == "UPG"
gen Muncwatch  = 1 if Moodywatch == "UNC"

drop Ric - numrating

foreach x of varlist Snegoutlook - Muncwatch {
    replace `x' = 0 if missing(`x')
}

* S&P negative/positive signals (watch or outlook)
gen spneg = 1 if Snegwatch == 1
replace spneg = 1 if Snegoutlook == 1
replace spneg = 0 if missing(spneg) & !missing(SP)

gen spneg2 = 1 if Snegwatch == 1
replace spneg2 = 0 if Snegwatch == 0 & !missing(SP)

gen spneg3 = 1 if Snegoutlook == 1
replace spneg3 = 0 if Snegoutlook == 0 & !missing(SP)

gen mneg = 1 if Mnegoutlook == 1
replace mneg = 1 if Mnegwatch == 1
replace mneg = 0 if missing(mneg) & !missing(M)

gen sppos = 1 if Sposwatch == 1
replace sppos = 1 if Sposoutlook == 1
replace sppos = 0 if missing(sppos) & !missing(SP)

gen mpos = 1 if Mposoutlook == 1
replace mpos = 1 if Mposwatch == 1
replace mpos = 0 if missing(mpos)

gen sprated = 1 if !missing(SP)
replace sprated = 0 if missing(SP)

gen mrated = 1 if !missing(M)
replace mrated = 0 if missing(M)

* Granular rating: adjust by +/-0.5 notch for watch/outlook
gen Mgranular = M
replace Mgranular = M - 1/2 if Mnegwatch == 1 | Mnegoutlook == 1
replace Mgranular = M + 1/2 if Mposwatch == 1 | Mposoutlook == 1

gen Sgranular = SP
replace Sgranular = SP - 1/2 if Snegwatch == 1 | Snegoutlook == 1
replace Sgranular = SP + 1/2 if Sposwatch == 1 | Sposoutlook == 1

gen Mgranular2 = 0
replace Mgranular2 =  1 if Mposwatch == 1 | Mposoutlook == 1
replace Mgranular2 = -1 if Mnegwatch == 1 | Mnegoutlook == 1

gen Sgranular2 = 0
replace Sgranular2 =  1 if Sposwatch == 1 | Sposoutlook == 1
replace Sgranular2 = -1 if Snegwatch == 1 | Snegoutlook == 1

gen Sgranular3 = .
replace Sgranular3 =  1 if Sposwatch == 1 | Sposoutlook == 1
replace Sgranular3 = -1 if Snegwatch == 1 | Snegoutlook == 1

* Fill rating at treatment quarter forward/backward for all periods
* (Eikon coverage is incomplete outside the sample window)
foreach x of varlist SJuly MJuly {
    egen max`x' = max(`x'), by(gvkey)
    replace `x' = max`x'
    drop max`x'
}

* Remove firms with Compustat preferred stock but confirmed (manually) to have none
replace treatment = 0 if missing(newpref) & TMJunk == 1


********************************************************************************
* SECTION 5: RATING AGENCY LEVERAGE ADJUSTMENTS
*
* Moody's pre-rule-change methodology counted 50% of preferred stock face value
* as equity when computing adjusted (rating agency) leverage.  After July 31,
* 2013, it counts 100% as equity.  We define:
*   changeratinglev = 0.5 -- preferred / (debt + equity)
* i.e., the mechanical decrease in Moody's leverage caused by the rule change.
* This is the key continuous treatment variable.
********************************************************************************

* Spread rating variables for all time periods (needed for fixed effects)
foreach x of varlist TMJunk TMIG TMoodyIGboundary aboveIGboundary belowIGboundary SPIGboundary SPJunk SPIG SPnegoutlook - SPdevwatch SPRated {
    egen max`x' = max(`x'), by(gvkey)
    replace `x' = max`x'
    drop max`x'
    replace `x' = 0 if missing(`x')
}

* treated = 1 if firm is speculative-grade (Moody's) AND held preferred stock
gen treated = 1 if treatment == 1 & TMJunk == 1
replace treated = 0 if missing(treated)

replace newpref = . if treated == 0

* changeratinglev: treatment intensity (Preferred/Capital ratio at event date)
* Factor of 0.5 -- newpref reflects the equity credit that Moody's adds;
* multiplied by 2 at end of section to yield Preferred/Capital in [0,1].
gen changeratinglev = 0.5 * newpref / (td + seqq) if treatmentq == 1 & treated == 1
replace changeratinglev = 0 if missing(changeratinglev)
egen minchangeratinglev = max(changeratinglev), by(gvkey)
replace changeratinglev = minchangeratinglev
drop minchangeratinglev

* S&P version (uses Compustat pstkq rather than hand-collected newpref)
gen changeratinglevsp = 0.5 * pref / (td + seqq) if treatmentq == 1
egen minchangeratinglevsp = max(changeratinglevsp), by(gvkey)
replace changeratinglevsp = minchangeratinglevsp
drop minchangeratinglevsp

* Debt-to-EBITDA version of rating agency treatment intensity
sort companycode timecode
by companycode: gen changeratingde = -1 * (td / (oibdpq + oibdpq[_n-1] + oibdpq[_n-2] + oibdpq[_n-3]) - ///
    ((td + 0.5 * newpref) / (oibdpq + oibdpq[_n-1] + oibdpq[_n-2] + oibdpq[_n-3]))) if treatmentq == 1 & treated == 1
replace changeratingde = 0 if missing(changeratingde)
egen minchangeratingde = max(changeratingde), by(gvkey)
replace changeratingde = minchangeratingde
drop minchangeratingde

* Book-leverage version of treatment intensity
gen changeratingbla = td / atq - ((td + 0.5 * newpref) / atq) if treatmentq == 1 & treated == 1
egen minchangeratingbla = min(changeratingbla), by(gvkey)
replace changeratingbla = minchangeratingbla
drop minchangeratingbla
replace changeratingbla = 0 if missing(changeratingbla)

* Preferred over book enterprise value
gen prefeq = newpref / (td + seqq) if treatmentq == 1 & treated == 1
egen maxprefeq = max(prefeq), by(gvkey)
replace prefeq = maxprefeq if missing(prefeq)
drop maxprefeq
replace prefeq = 0 if missing(prefeq)

* Adjusted debt (pre-event: debt + 50% preferred for treated firms)
gen logadjdebt = log(td)              if event == 1
replace logadjdebt = log(td + .5 * newpref) if treated == 1 & event == 0
replace logadjdebt = log(td)          if treated == 0 & event == 0

* Rating agency leverage (bl using Moody's adjusted debt)
gen ratinglev = td / (td + seqq)                              if event == 1
replace ratinglev = td / (td + seqq)                          if event == 0 & treated == 0
replace ratinglev = (td + 0.5 * newpref) / (td + seqq)        if event == 0 & treated == 1

gen ratingbla = td / atq                                       if event == 1
replace ratingbla = td / atq                                   if event == 0 & treated == 0
replace ratingbla = (td + 0.5 * newpref) / atq                 if event == 0 & treated == 1

gen ratingla = ltq / atq                                       if event == 1
replace ratingla = ltq / atq                                   if event == 0 & treated == 0
replace ratingla = (ltq + 0.5 * newpref) / atq                 if event == 0 & treated == 1

* Alternative: using pstkq instead of hand-collected newpref
gen ratinglev2 = td / (td + seqq)                              if event == 1
replace ratinglev2 = td / (td + seqq)                          if event == 0 & treated == 0
replace ratinglev2 = (td + 0.5 * pstkq) / (td + seqq)          if event == 0 & treated == 1


********************************************************************************
* SECTION 6: ADDITIONAL VARIABLES AND WINSORIZATION
********************************************************************************

* Placebo half-year dummy (for placebo tests in Table A.2)
gen secondhalf = 1 if month > 7 | month == 1
replace secondhalf = 0 if missing(secondhalf)

* Increasing rating scale (M and SP from Eikon decrease as rating improves)
gen Moody = .
forvalues k = 0/21 {
    replace Moody = `k' + 1 if M == 22 - `k'
}

gen S = .
forvalues k = 0/21 {
    replace S = `k' + 1 if SP == 22 - `k'
}

* Contemporary junk dummies (complement to the at-treatment-date TMJunk/SPJunk)
drop TMoodyJunk
gen MJunk = 1 if M  > 10 & !missing(M)
replace MJunk = 0 if missing(MJunk)
gen SJunk = 1 if SP > 10 & !missing(SP)
replace SJunk = 0 if missing(SJunk)

* S&P negative/positive signal at treatment (used in triple-diff analyses)
gen SPneg = 1 if SPnegwatch == 1 & treatmentq == 1
replace SPneg = 1 if SPnegoutlook == 1 & treatmentq == 1
egen maxSPneg = max(SPneg), by(companycode)
replace SPneg = maxSPneg
replace SPneg = 0 if missing(SPneg)

replace SPRated = 0 if missing(SPRated)
gen SPpos = 1 if SPposwatch == 1 & treatmentq == 1
replace SPpos = 1 if SPposoutlook == 1 & treatmentq == 1
replace SPpos = 1 if SPRated == 0 & treatmentq == 1        // not S&P rated -> less constrained
egen maxSPpos = max(SPpos), by(companycode)
replace SPpos = maxSPpos
drop maxSPpos
replace SPpos = 0 if missing(SPpos)

gen SPpos2 = 1 if SPposoutlook == 1 & treatmentq == 1
replace SPpos2 = 1 if SPRated == 0 & treatmentq == 1
egen maxSPpos2 = max(SPpos2), by(companycode)
replace SPpos2 = maxSPpos2
drop maxSPpos2
replace SPpos2 = 0 if missing(SPpos2)

gen SPpos3 = 1 if SPposwatch == 1 & treatmentq == 1
replace SPpos3 = 1 if SPRated == 0 & treatmentq == 1
egen maxSPpos3 = max(SPpos3), by(companycode)
replace SPpos3 = maxSPpos3
drop maxSPpos3
replace SPpos3 = 0 if missing(SPpos3)

gen posorneg = 1 if SPpos == 1 | SPneg == 1
replace posorneg = 0 if missing(posorneg)

* Moody's negative watch at treatment
gen Moodyneg = 1 if Moodynegwatch == 1 & treatmentq == 1
egen maxMoodyneg = max(Moodyneg), by(companycode)
replace Moodyneg = maxMoodyneg
replace Moodyneg = 0 if missing(Moodyneg)

* Split-rated dummies (junk by one agency, IG by the other)
gen SJunkonly  = 1 if SPJunk == 1 & TMJunk == 0
replace SJunkonly = 0 if missing(SJunkonly)

gen MJunkonly  = 1 if TMJunk == 1 & SPJunk == 0
replace MJunkonly = 0 if missing(MJunkonly)

gen MIGonly    = 1 if TMIG == 1 & SPIG == 0
replace MIGonly = 0 if missing(MIGonly)

gen SPIGonly   = 1 if TMIG == 0 & SPIG == 1
replace SPIGonly = 0 if missing(SPIGonly)

gen MJunkonly2 = 1 if MJunk == 1 & SJunk == 0
replace MJunkonly2 = 0 if missing(MJunkonly2)

gen junk    = 1 if SPJunk == 1 | TMJunk == 1
replace junk = 0 if missing(junk)

gen onejunk = 1 if SPJunk == 1 & TMJunk == 0
replace onejunk = 1 if SPJunk == 0 & TMJunk == 1
replace onejunk = 0 if missing(onejunk)

gen oneig   = 1 if SPIG == 1 & TMIG == 0
replace oneig = 1 if SPIG == 0 & TMIG == 1
replace oneig = 0 if missing(oneig)

gen ig = 1 if SPIG == 1 | TMIG == 1
replace ig = 0 if missing(ig)

gen onejunk2 = 1 if SJunk == 1 & TMJunk == 0
replace onejunk2 = 1 if SJunk == 0 & TMJunk == 1
replace onejunk2 = 0 if missing(onejunk2)

gen onejunkig = 1 if oneig == 1 | onejunk == 1
replace onejunkig = 0 if missing(onejunkig)

* Rating coverage indicators
gen rated  = 1 if !missing(M) | !missing(SP)
replace rated = 0 if missing(rated)

gen Mrated = 1 if !missing(M)
replace Mrated = 0 if missing(Mrated)

gen Srated = 1 if !missing(SP)
replace Srated = 0 if missing(Srated)

gen Monly = 1 if Mrated == 1 & Srated == 0
replace Monly = 0 if missing(Monly) & rated == 1

gen Sonly = 1 if Mrated == 0 & Srated == 1
replace Sonly = 0 if missing(Sonly) & rated == 1

* Time--rating fixed-effect codes for split-rated firms
gen num = MJuly if onejunk == 1
replace num = SJuly if missing(MJuly) & onejunk == 1
egen ratingnumt    = group(num timecode)
egen ratingnumi10t = group(num itimecode10)
egen ratingMt      = group(MJuly timecode)

gen splitrated = 1 if Moody != S & !missing(S) & !missing(Moody)
replace splitrated = 0 if Moody == S & !missing(S) & !missing(Moody)

* Manual correction: Danaher had positive watch incorrectly coded as negative outlook
replace SPneg = 0 if tic == "DAN" & !missing(tic)

* Drop financial firms and utility holding company
drop if sic >= 6000 & sic <= 6999
drop if sic == 9995
drop if tic == "AIG1"

* Winsorize key financial variables at 1st and 99th percentile
foreach x of varlist bl atqc ppec ratingbla deltaltd - deltaltd2 ppe debtebitda logltdebt logdiv logstdebt bla logdebt logadjdebt logcash sga - logequitysale size {
    winsor2 `x', suffix(_win) cuts(1 99)
    winsor2 `x', suffix(_trim) cuts(1 99) trim
}

* Winsorize controls
foreach x of varlist mk2bk prof tang sales {
    winsor2 `x', suffix(_win) cuts(1 99)
}

* Time fixed-effect dummies
tabulate timecode, generate(tc)

* Rescale treatment intensity: changeratinglev now = Preferred/Capital  [0,1]
* The factor of 2 converts from the 0.5-- definition above to face-value share.
replace changeratinglev = changeratinglev * 2
replace changeratingbla = changeratingbla * -2

* Preferred face value in billions (for summary statistics)
gen prefbn = newpref / 1000
replace prefbn = 0 if missing(newpref)

* Altman Z-score
gen Altman_Z = 3.3*(oiadpq/atq) + 0.99*(saleq/atq) + 0.6*(me/ltq) + 1.2*(wcapq/atq) + 1.4*(req/atq)
winsor2 Altman_Z, suffix(_win) cuts(1 99)

gen alert  = 1 if Altman_Z_win < 3
replace alert = 0 if missing(alert)
gen alert2 = 1 if Altman_Z_win < 1.8
replace alert2 = 0 if missing(alert2)
gen alert3 = 1 if Altman_Z_win < 0
replace alert3 = 0 if missing(alert3)

* Short-sample indicator (tighter definition used in main regressions)
gen sample_short = (sample == 1 & yearquarter < yq(2015,3) & yearquarter > yq(2012,2))

* Debt growth (year-over-year using 4-quarter lag, panel-tsset)
xtset gvkey_d yearquarter

gen debt_growth  = (td - l4.td) / (l4.td + l4.seqq)
winsor2 debt_growth, suffix(_win) cuts(1 99)

gen debt_growth2 = (td - l4.td) / l4.td
winsor2 debt_growth2, suffix(_win) cuts(5 95)

gen lev_growth   = (bl  - l4.bl)  / l4.bl
winsor2 lev_growth, suffix(_win) cuts(1 99)

gen lev_growth2  = (bla - l4.bla) / l4.bla
winsor2 lev_growth2, suffix(_win) cuts(1 99)

* Trim leverage measures to [0,1]
gen bl_1  = min(bl, 1)
replace bl_1 = max(bl_1, 0)

gen bla_1 = min(bla, 1)
replace bla_1 = max(bla_1, 0)

gen la_1  = min(la, 1)
replace la_1 = max(la_1, 0)

gen ratinglev_1  = min(ratinglev, 1)
replace ratinglev_1 = max(ratinglev_1, 0)

gen ratingbla_1  = min(ratingbla, 1)
replace ratingbla_1 = max(ratingbla_1, 0)

gen ratingla_1   = min(ratingla, 1)
replace ratingla_1 = max(ratingla_1, 0)

gen le = ltq / (me + ltq)

gen year_cq = year(dofq(yearquarter))

* Ratings-trigger firms (identified from 10-K/10-Q text review)
gen trigger = 1 if gvkey == "001356"  // Alcoa
replace trigger = 1 if gvkey == "008807"  // PNM Resources
replace trigger = 1 if gvkey == "012615"  // M/I Homes
replace trigger = 1 if gvkey == "011670"  // HRG
replace trigger = 1 if gvkey == "027786"  // Chesapeake
replace trigger = 1 if gvkey == "135990"  // NRG
replace trigger = 1 if gvkey == "005073"  // GM
replace trigger = 1 if gvkey == "165699"  // Regency
replace trigger = 0 if missing(trigger)

gen trigger3 = trigger
replace trigger3 = 0 if gvkey == "005073"  // GM: IG upgrade condition, not applicable
replace trigger3 = 0 if gvkey == "012615"  // M/I Homes: not applicable
replace trigger3 = 0 if gvkey == "027786"  // Chesapeake: loan-dependent

* Derivatives exposure variables
foreach x in aocidergl derac deralt derlc derllt ciderglq derhedgly derhedglq ciderglq cidergly {
    replace `x' = 0 if missing(`x')
}

gen logder = log(1 + derlc + derllt)
winsor2 logder, suffix(_win) cuts(1 99)

gen netderq = (derac + deralt - derlc - derllt) / atq
winsor2 netderq, suffix(_win) cuts(1 99)

gen netderlt = (deralt - derllt) / atq if treatmentq == 1
egen mnetderlt = max(netderlt), by(gvkey)
drop netderlt
ren mnetderlt netderlt
winsor2 netderlt, suffix(_win) cuts(1 99)

gen netderlt2 = (deralt - derllt) / (seqq + td) if treatmentq == 1
egen mnetderlt2 = max(netderlt2), by(gvkey)
drop netderlt2
ren mnetderlt2 netderlt2
winsor2 netderlt2, suffix(_win) cuts(1 99)

gen lderlt = derllt / atq if treatmentq == 1
egen mlderlt = max(lderlt), by(gvkey)
drop lderlt
ren mlderlt lderlt
winsor2 lderlt, suffix(_win) cuts(1 99)

gen netderlt3 = (derac + deralt - derlc - derllt) / ltq if treatmentq == 1
gen dl2        = (derlc + derllt) / (seqq + td)         if treatmentq == 1

gen derinc = derhedglq / atq if treatmentq == 1
egen dinc  = max(derinc), by(gvkey)
gen derinc2 = ciderglq / atq if treatmentq == 1
egen dinc2  = max(derinc2), by(gvkey)
gen derinc3 = cidergly / atq if treatmentq == 1
gen derinc4 = derhedgly / atq if treatmentq == 1
egen dinc4  = max(derinc4), by(gvkey)
gen derinc5 = aocidergl / atq if treatmentq == 1
egen dinc5  = max(derinc5), by(gvkey)


* Controls measured at time of rule change (frozen cross-section)
foreach x of varlist prof_win tang_win sales_win mk2bk_win {
    gen `x'0 = `x' if treatmentq == 1
    egen max`x'0 = max(`x'0), by(gvkey)
    replace `x'0 = max`x'0 if missing(`x'0)
    drop max`x'0
}


********************************************************************************
* SECTION 7: SAVE Master_v1.dta
* Full panel with all variables; used directly for unmatched (full-sample)
* regressions in the Online Appendix.
********************************************************************************

save "$inter/Master_v1.dta", replace


********************************************************************************
* SECTION 8: PROPENSITY SCORE MATCHING
*
* Main matched sample: mahapick, 4 matches with replacement, using:
*   MJuly (Moody's rating), lev_growth_win, mk2bk_win
*   sliced by Fama-French industry.
* Robustness: 1 match without replacement (kmatch, same covariates).
*
* match files saved to $proc/ (temporary intermediate datasets).
********************************************************************************

use "$inter/Master_v1.dta", clear

* Filter to single cross-section at treatment quarter
bys gvkey: egen maxdate = max(datadate)
bys gvkey: egen mindate = min(datadate)
format maxdate %d
format mindate %d

* Drop if any control variable missing during short sample window
foreach v of varlist prof_win tang_win sales_win mk2bk_win MJuly {
    gen temp_miss_v = (`v' == .)
    bys gvkey: egen miss_`v' = max(temp_miss_v) if sample_short == 1
    drop if miss_`v' == 1
    drop temp_miss_v
}

keep if treatmentq == 1 & TMJunk == 1
sort gvkey

* Require balanced panel: control firms must span at least 2012Q3--2014Q3
keep if (maxdate >= date("07-31-2014","MDY") & mindate < date("08-31-2012","MDY")) | treated == 1

* Mahapick matching: 4 controls per treated firm, with replacement
* Match on Moody's rating notch and pre-treatment leverage growth, within industry
cd "$inter"
mahapick MJuly lev_growth_win mk2bk_win, idvar(gvkey) treated(treated) genfile(match2) nummatches(4) replace matchon(industry) sliceby(industry)

* 1-match without replacement using kmatch (robustness check)
preserve
kmatch md treated MJuly lev_growth_win mk2bk_win, ematch(industry) nn(1) wor gen idgenerate(mid) idvar(gvkey)
keep if treated == 1 & _KM_nm > 0
keep gvkey mid1
rename gvkey _prime_id
rename mid1 gvkey
save "$inter/temp.dta", replace
keep _prime_id
gen gvkey = _prime_id
append using "$inter/temp.dta"
sort _prime_id gvkey
gen _matchnum = 1
save "$inter/match2_1norep.dta", replace
restore

* Reshape match file: one row per control--treated pair
use "$inter/match2.dta", clear
rename gvkey       gvkey_control
rename _prime_id   gvkey_treat
drop _matchnum
sort gvkey_control
save "$inter/match3.dta", replace

use "$inter/match2_1norep.dta", clear
rename gvkey       gvkey_control
rename _prime_id   gvkey_treat
drop _matchnum
sort gvkey_control
save "$inter/match3_1norep.dta", replace

* Build matched panel: joinby pairs onto full panel, create cohort FE
use "$inter/Master_v1.dta", clear
rename gvkey gvkey_control
joinby gvkey_control using "$inter/match3.dta", unmatched(both)
keep if _merge == 3
replace gvkey_treat = gvkey_control if gvkey_treat == ""
egen double cohort  = group(gvkey_treat)
drop gvkey_treat
rename gvkey_control gvkey
sum cohort, detail

* tcohort = quarter -- cohort fixed effect (absorbs aggregate time trends
* within each matched pair, removing cross-cohort confounds)
egen double tcohort = group(cohort timecode)

save "$inter/Matched Sample_v2.dta", replace

* Same for 1-match-no-replacement sample
use "$inter/Master_v1.dta", clear
rename gvkey gvkey_control
joinby gvkey_control using "$inter/match3_1norep.dta", unmatched(both)
keep if _merge == 3
replace gvkey_treat = gvkey_control if gvkey_treat == ""
egen double cohort  = group(gvkey_treat)
drop gvkey_treat
rename gvkey_control gvkey
egen double tcohort = group(cohort timecode)

save "$inter/Matched Sample_v2_1norep.dta", replace

* Master_v2: full panel + matched sample indicator (matched == 1 for matched obs)
use "$inter/Master_v1.dta", clear
gen matched = 0
append using "$inter/Matched Sample_v2.dta"
replace matched = 1 if missing(matched)
save "$proc/MainPanel.dta", replace

* Master_v2_1norep: same but with 1-match-no-replacement matched sample
use "$inter/Master_v1.dta", clear
gen matched = 0
append using "$inter/Matched Sample_v2_1norep.dta"
replace matched = 1 if missing(matched)
save "$proc/MainPanel_1norep.dta", replace


********************************************************************************
* SECTION 9: EVENT STUDY -- EQUITY CARs AND CREDIT SPREAD CARs
*
* Computes cumulative abnormal returns (CARs) and credit spread changes around
* the July 31, 2013 announcement date.
* Saves CAR_v2.dta and Matched Sample_vCS.dta for use in Regressions_clean.do.
********************************************************************************

*---- 9a. Equity CARs --------------------------------------------------------------------------------------------------------------------

use "$crsp/Crsp Daily_v1.dta", clear

gen month = month(date)
gen year  = year(date)
gen day   = day(date)

gen excret = ret - vwretd       // market-adjusted excess return

sort cusip date

* CAR windows: [-1,+1], [-1,+3], [-1,+5], [-1,+10]
by cusip: gen car  = excret + excret[_n-1] + excret[_n+1]
by cusip: gen car2 = excret + excret[_n-1] + excret[_n+1] + excret[_n+2] + excret[_n+3]
by cusip: gen car3 = excret + excret[_n-1] + excret[_n+1] + excret[_n+2] + excret[_n+3] + excret[_n+4] + excret[_n+5]
by cusip: gen car4 = excret + excret[_n-1] + excret[_n+1] + excret[_n+2] + excret[_n+3] + excret[_n+4] + excret[_n+5] + excret[_n+6] + excret[_n+7] + excret[_n+8] + excret[_n+9] + excret[_n+10]

gen stockret = (1+excret) * (1+excret[_n-1]) * (1+excret[_n+1]) * (1+excret[_n+2]) * (1+excret[_n+3]) - 1

* Pre- and post-event drift windows (used in extended event study plots)
forvalues i = 2/30 {
    by cusip: gen prepcar`i' = excret[_n-`i']
}
egen prepcar = rowtotal(prepcar2 - prepcar30)

forvalues i = 4/30 {
    by cusip: gen postpcar`i' = excret[_n+`i']
}
egen postpcar    = rowtotal(postpcar6 - postpcar30)
egen postpcar430 = rowtotal(postpcar4 - postpcar30)

gen car5 = postpcar + car3

by cusip: gen mktret  = vwretd + vwretd[_n-1] + vwretd[_n+1]
by cusip: gen mktret2 = vwretd + vwretd[_n-1] + vwretd[_n+1] + vwretd[_n+2] + vwretd[_n+3]

* Keep only the event date (July 31, 2013)
keep if day == 31 & month == 7 & year == 2013

* Manual CUSIP corrections for firms with mismatched identifiers
replace cusip = "01381710" if ticker == "AA"
replace cusip = "17187110" if ticker == "CBB"
replace cusip = "40537Q50" if ticker == "HK"
replace cusip = "86164230" if ticker == "SGY"
replace cusip = "86853610" if ticker == "SVU"
replace cusip = "06985P10" if ticker == "BAS"
replace cusip = "23108210" if ticker == "CMLS"
replace cusip = "20854P10" if ticker == "CNX"
replace cusip = "49291410" if ticker == "KEG"
replace cusip = "62913F50" if ticker == "NIHD"
replace cusip = "75040P40" if ticker == "ROIAK"
replace cusip = "25786710" if ticker == "RRD"

save "$inter/CAR_v1.dta", replace

* Remove duplicates (keep one observation per ticker)
use "$inter/CAR_v1.dta", clear
drop if missing(ticker)
duplicates tag ticker, gen(dup)
drop if dup > 0
drop dup
save "$inter/CAR_vTicker.dta", replace

* Merge CARs onto Master_v2 (treatment quarter cross-section)
use "$proc/MainPanel.dta", clear
keep if treatmentq == 1
drop _merge
ren tic ticker
gen tsymbol = ticker
replace cusip = substr(cusip, 1, 8)

merge m:1 cusip using "$inter/CAR_v1.dta"
drop if _merge == 2
drop _merge

save "$proc/EquityCAR.dta", replace


*---- 9b. Credit spread CARs ------------------------------------------------------------------------------------------------------

* Match on credit spread level to control for pre-event spread difference
* between treated and control firms.

use "$proc/MainPanel.dta", clear
keep if treatmentq == 1
keep if TMJunk == 1 | SPJunk == 1
drop month year _merge

merge m:1 sixdigitcusip using "$icebaml/BAMLCAR_v1.dta"
drop if _merge == 2
drop _merge
save "$proc/BondCAR.dta", replace

use "$proc/BondCAR.dta", clear
drop if matched == 1
keep if treatmentq == 1 & TMJunk == 1

* Drop if any matching covariate missing
foreach v of varlist prof_win tang_win sales_win mk2bk_win MJuly w2car {
    drop if missing(`v')
}

sort gvkey

* Mahapick: match also on log credit spread level (lwOAS)
* This ensures the parallel-trends assumption holds in OAS space
cd "$inter"
mahapick MJuly lev_growth_win mk2bk_win lwOAS, idvar(gvkey) treated(treated) genfile(matchcs) nummatches(4) replace matchon(industry) sliceby(industry)

use "$inter/matchcs.dta", clear
rename gvkey       gvkey_control
rename _prime_id   gvkey_treat
drop _matchnum
sort gvkey_control
save "$inter/matchcs2.dta", replace

use "$inter/Master_v1.dta", clear
rename gvkey gvkey_control
joinby gvkey_control using "$inter/matchcs2.dta", unmatched(both)
keep if _merge == 3
replace gvkey_treat = gvkey_control if gvkey_treat == ""
egen double cohort  = group(gvkey_treat)
drop gvkey_treat
rename gvkey_control gvkey
sum cohort, detail
egen double tcohort = group(cohort timecode)

keep if treatmentq == 1
drop _merge

merge m:1 sixdigitcusip using "$icebaml/BAMLCAR_v1.dta"
drop if _merge == 2
drop _merge

* Express credit spread CARs as a fraction of pre-event OAS level
foreach x of varlist w2car w2car2 w2car3 w2car4 {
    gen `x'perc = `x' / lwOAS
}
gen w2car0perc = w2car0 / (lwOAS - w2car0)

save "$proc/BondCAR_Matched.dta", replace


********************************************************************************
* SECTION 10: FINANCIAL CONSTRAINT INDICES
* Whited-Wu (WW), Kaplan-Zingales (KZ), and Size-Age (SA) indices
* computed from Compustat quarterly data and merged back into MainPanel.dta.
********************************************************************************

use "$proc/MainPanel.dta", clear

* Compute on matched==0 deduplicated subset (one unique row per companycode+datadate)
sort companycode datadate
keep if matched == 0
capture drop tcohort cohort _merge matched
duplicates drop


* 1. Whited-Wu (WW) Index — Whited & Wu (2006)
* WW = -0.091*CF - 0.062*DIVPOS + 0.021*TLTD - 0.044*LNTA + 0.102*ISG - 0.035*SG

gen cf = (ibq + dpq) / atq

replace cdvcy = 0 if missing(cdvcy)
replace pdvcy = 0 if missing(pdvcy)
gen divpos = (cdvcy + pdvcy > 0) if !missing(atq)

replace dlttq = 0 if missing(dlttq)
gen tltd = dlttq / atq
gen lnta = log(atq)

by companycode: gen sg = (saleq - saleq[_n-4]) / abs(saleq[_n-4])

tostring sic, gen(sic_str) format("%04.0f")
gen sic3 = substr(sic_str, 1, 3)
bysort sic3 fyearq fqtr: egen isg = mean(sg)

gen WW = -0.091*cf - 0.062*divpos + 0.021*tltd - 0.044*lnta + 0.102*isg - 0.035*sg


* 2. Kaplan-Zingales (KZ) Index — Lamont, Polk & Saá-Requejo (2001)
* KZ = -1.002*CF + 0.283*Q + 3.139*LEV - 39.368*DIV - 1.315*CASH

sort companycode datadate

by companycode: gen ppentq_lag = ppentq[_n-1]
gen kz_cf = (ibq + dpq) / ppentq_lag

gen be = seqq
replace be = atq - ltq if missing(seqq)
gen mve = cshoq * prccq
gen kz_q = (atq - be + mve) / atq

replace dlcq = 0 if missing(dlcq)
replace dlttq = 0 if missing(dlttq)
gen total_debt = dlcq + dlttq
gen kz_lev = total_debt / (total_debt + seqq)

gen kz_div = (cdvcy + pdvcy) / ppentq_lag
gen kz_cash = cheq / ppentq_lag

gen KZ = -1.002*kz_cf + 0.283*kz_q + 3.139*kz_lev - 39.368*kz_div - 1.315*kz_cash


* 3. Size-Age (SA) Index — Hadlock & Pierce (2010)
* SA = -0.737*SIZE + 0.043*SIZE^2 - 0.040*AGE

by companycode: egen first_date = min(datadate)
gen age_quarters = (datadate - first_date) / 91.25
gen age = age_quarters / 4
replace age = 37 if age > 37 & !missing(age)

winsor2 size, cuts(10 90) replace

gen SA = -0.737*size + 0.043*(size^2) - 0.040*age


* Clean up and winsorize
drop if missing(atq) | atq <= 0
replace KZ = . if missing(ppentq_lag) | ppentq_lag < 1

winsor2 WW KZ SA, cuts(1 99) suffix(_w)

label var WW   "Whited-Wu Index (2006)"
label var KZ   "Kaplan-Zingales Index (Lamont et al. 2001)"
label var SA   "Size-Age Index (Hadlock & Pierce 2010)"
label var WW_w "Whited-Wu Index (winsorized)"
label var KZ_w "Kaplan-Zingales Index (winsorized)"
label var SA_w "Size-Age Index (winsorized)"

* Keep only merge keys and the new index variables, then merge back into MainPanel
keep companycode datadate WW WW_w KZ KZ_w SA SA_w
save "$inter/fin_constr.dta", replace

use "$proc/MainPanel.dta", clear
capture drop _merge
sort companycode datadate
merge m:1 companycode datadate using "$inter/fin_constr.dta"
drop _merge
save "$proc/MainPanel.dta", replace


* ==============================================================================
* SECTION 10: MARKET DATA FOR TABLE A.15
* ==============================================================================
* Source files (included in Data/Raw/Market/):
*   SP500.csv  -- S&P 500 daily closes, Jun-Sep 2013 (Yahoo Finance via ^GSPC)
*   TNX.csv    -- 10Y Treasury yield, Jun-Sep 2013 (Yahoo Finance via ^TNX)
*
* To refresh the raw files, run Code/download_market_data.py (requires Python).
* The included CSVs are static 2013 data and do not need to be re-downloaded
* for replication.
* ------------------------------------------------------------------------------

* S&P 500 (Yahoo Finance ^GSPC)
import delimited "$raw/Market/SP500.csv", clear varnames(1) case(lower)
gen date = date(observation_date, "YMD")
format date %td
drop observation_date
rename sp500 sp500_close
drop if missing(sp500_close)
sort date
save "$proc/SP500.dta", replace

* 10Y Treasury yield (Yahoo Finance ^TNX)
import delimited "$raw/Market/TNX.csv", clear varnames(1) case(lower)
gen date = date(observation_date, "YMD")
format date %td
drop observation_date
destring tnx, replace force
rename tnx tnx_yield
drop if missing(tnx_yield)
sort date
save "$proc/TNX.dta", replace

********************************************************************************
* END OF MASTER_CLEAN.DO
* Final output files (Data/Processed/ -- read by Regressions_clean.do):
*   MainPanel.dta            -- full panel (all firms, all quarters); includes WW/KZ/SA
*   Master_v2.dta            -- main matched sample (4 matches with replacement)
*   Master_v2_1norep.dta     -- robustness matched sample (1 match without replacement)
*   CAR_v2.dta               -- equity event study
*   BAMLCAR_v2.dta           -- credit spread event study (unmatched)
*   Matched Sample_vCS.dta   -- credit spread event study (matched)
*   BondCAR_Matched.dta      -- credit spread matched event study (intermediate)
*   SP500.dta                -- S&P 500 daily closes (for Table A.15)
*   TNX.dta                  -- 10Y Treasury yields (for Table A.15)
********************************************************************************

log close


