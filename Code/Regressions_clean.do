* =============================================================================
* Regressions_clean.do
* "What's in a Debt? Rating Agency Methodologies and Firms' Financing and
*  Investment Decisions" -- Fracassi & Weitzner
*
* Produces all tables and figures in the paper and online appendix.
* Run AFTER Master_clean.do has created the processed datasets.
* ==============================================================================

* 0. SETUP
* ==============================================================================

* Change this one line to match your machine; all other paths follow.
global root "C:\Users\cf8745\Box\Research\Rating Agency Paper - Final\ReplicationPackage"

global proc    "$root/Data/Processed"
global tables  "$root/Output/Tables"
global figures "$root/Output/Figures"
global code    "$root/Code"

global controls  "prof_win tang_win sales_win mk2bk_win"
global controls2 "prof_win0 tang_win0 sales_win0 mk2bk_win0"

* Create output folders if they do not exist
capture mkdir "$root/Output"
capture mkdir "$tables"
capture mkdir "$figures"

* Log
capture log close
capture log using "$code/Regressions_clean.log", replace

use "$proc/MainPanel.dta", clear

* Generate billion-dollar scaled variables needed for summary statistics
foreach x of varlist dlttq dlcq ppentq saleq atq {
    gen `x'bn = `x'/1000
}


* ==============================================================================
* SECTION 2: DATA AND SAMPLE
* ==============================================================================

* Table 2: Summary Statistics

***Not in logs
eststo clear
eststo treated:   quietly estpost summarize prefbn changeratinglev bl_1 dlttqbn dlcqbn me2 mk2bk_win MJuly SPRated SJuly ppentqbn prof_win tang_win saleqbn atqbn if treated == 1 & TMJunk ==1 & treatmentq ==1 & matched == 0, detail
eststo untreated: quietly estpost summarize prefbn changeratinglev bl_1 dlttqbn dlcqbn me2 mk2bk_win MJuly SPRated SJuly ppentqbn prof_win tang_win saleqbn atqbn  if treated == 0 & TMJunk ==1 & treatmentq ==1  & matched == 0, detail
eststo diff:      quietly estpost ttest prefbn changeratinglev bl_1 dlttqbn dlcqbn me2 mk2bk_win MJuly SPRated SJuly ppentqbn prof_win tang_win saleqbn atqbn if TMJunk ==1 & treatmentq ==1  & matched == 0 , by(treated) unequal
eststo matched:   quietly estpost summarize prefbn changeratinglev bl_1 dlttqbn dlcqbn me2 mk2bk_win MJuly SPRated SJuly ppentqbn prof_win tang_win saleqbn atqbn  if treated == 0 & TMJunk ==1 & treatmentq ==1  & matched == 1, detail
eststo diff2:     quietly estpost ttest prefbn changeratinglev bl_1 dlttqbn dlcqbn me2 mk2bk_win MJuly SPRated SJuly ppentqbn prof_win tang_win saleqbn atqbn if TMJunk ==1 & treatmentq ==1  & matched == 1 , by(treated) unequal
esttab using "$tables/summarynolog.tex", cells("count(pattern(1 1 0 1 0) fmt(0) label(N)) mean(pattern(1 1 0 1 0) fmt(3) label(Mean)) p50(pattern(1 1 0 1 0) fmt(2) label(Median)) sd(pattern(1 1 0 1 0) fmt(3) label(SD)) b(star pattern(0 0 1 0 1) fmt(3) label(Diff w.r.t. Treated))") label rename( prefbn "Preferred Stock" dlttqbn "Long-Term Debt" dlcqbn "Short-Term Debt" ppentqbn "PPE" bl_1 "Book Leverage" me2 "Market Equity" mk2bk_win "Market to Book" MJuly "Moodys Rating" SPRated "S\&P Rated" SJuly "S\&P Rating" prof_win "Profitability" tang_win "Tangibility" saleqbn "Sales" atqbn "Assets" prefqnorm "Preferred/EV" changeratinglev "Preferred/Capital" Observations "N" ) replace star(* .1 ** .05 *** .01)

***All in One
eststo clear
eststo treated:   quietly estpost summarize prefbn changeratinglev bl_1 logltdebt logstdebt me2 mk2bk_win MJuly SPRated SJuly ppe prof_win tang_win sales_win size if treated == 1 & TMJunk ==1 & treatmentq ==1 & matched == 0, detail
eststo untreated: quietly estpost summarize prefbn changeratinglev bl_1 logltdebt logstdebt me2 mk2bk_win MJuly SPRated SJuly ppe prof_win tang_win sales_win size  if treated == 0 & TMJunk ==1 & treatmentq ==1  & matched == 0, detail
eststo diff:      quietly estpost ttest prefbn changeratinglev bl_1 logltdebt logstdebt me2 mk2bk_win MJuly SPRated SJuly ppe prof_win tang_win sales_win size if TMJunk ==1 & treatmentq ==1  & matched == 0 , by(treated) unequal
eststo matched:   quietly estpost summarize prefbn changeratinglev bl_1 logltdebt logstdebt me2 mk2bk_win MJuly SPRated SJuly ppe prof_win tang_win sales_win size  if treated == 0 & TMJunk ==1 & treatmentq ==1  & matched == 1, detail
eststo diff2:     quietly estpost ttest prefbn changeratinglev bl_1 logltdebt logstdebt me2 mk2bk_win MJuly SPRated SJuly ppe prof_win tang_win sales_win size if TMJunk ==1 & treatmentq ==1  & matched == 1 , by(treated) unequal
esttab using "$tables/summary.tex", cells("count(pattern(1 1 0 1 0) fmt(0) label(N)) mean(pattern(1 1 0 1 0) fmt(3) label(Mean)) p50(pattern(1 1 0 1 0) fmt(2) label(Median)) sd(pattern(1 1 0 1 0) fmt(3) label(SD)) b(star pattern(0 0 1 0 1) fmt(3) label(Diff w.r.t. Treated))") label rename( prefbn "Preferred Stock" logltdebt "Long-Term Debt" logstdebt "Short-Term Debt" ppe "PPE" bl_1 "Book Leverage" me2 "Market Equity" mk2bk_win "Market to Book" MJuly "Moodys Rating" SPRated "S\&P Rated" SJuly "S\&P Rating" prof_win "Profitability" tang_win "Tangibility" sales_win "Sales" size "Assets" prefqnorm "Preferred/EV" changeratinglev "Preferred/Capital" Observations "N" ) replace star(* .1 ** .05 *** .01)


* Figure 1: Preferred Stock Histogram
histogram changeratinglev if treated == 1 & TMJunk ==1 & treatmentq ==1 & matched == 0, bgcolor(white) xtitle("") ytitle("") graphregion(color(white))
graph export "$figures/RALev_Histogram.png", replace

****Back of envelope amount of debt firms raise
sum td if treatmentq == 1 & treated == 1 & TMJunk == 1
sum me if treatmentq == 1 & treated == 1 & TMJunk == 1
reghdfe logdebt event##treatment $controls if TMJunk == 1 & sample == 1, absorb(i.timecode i.tcohort) vce(cluster companycode)

***Summary Statistics: Unrated vs Junk vs IG
use "$proc/MainPanel.dta", clear

foreach x of varlist dlttq dlcq ppentq saleq atq {
gen `x'bn = `x'/1000
}
gen prefbn2 = pref/1000

eststo clear
eststo junk:    quietly estpost summarize prefbn2 bl_1 dlttqbn dlcqbn me2 mk2bk_win ppentqbn prof_win tang_win saleqbn atqbn if junk ==1 & treatmentq ==1 & matched == 0, detail
eststo unrated: quietly estpost summarize prefbn2 bl_1 dlttqbn dlcqbn me2 mk2bk_win ppentqbn prof_win tang_win saleqbn atqbn  if  rated == 0 & treatmentq ==1  & matched == 0, detail
eststo diff:    quietly estpost ttest prefbn2 bl_1 dlttqbn dlcqbn me2 mk2bk_win ppentqbn prof_win tang_win saleqbn atqbn if treatmentq ==1  & matched == 0 & ig == 0, by(rated) unequal
eststo IG:      quietly estpost summarize prefbn2 bl_1 dlttqbn dlcqbn me2 mk2bk_win ppentqbn prof_win tang_win saleqbn atqbn  if ig == 1 & treatmentq ==1  & matched == 0, detail
eststo diff2:   quietly estpost ttest prefbn2 bl_1 dlttqbn dlcqbn me2 mk2bk_win ppentqbn prof_win tang_win saleqbn atqbn if rated ==1 & treatmentq ==1  & matched == 0, by(junk) unequal
esttab using "$tables/summaryunrated.tex", cells("count(pattern(1 1 0 1 0) fmt(0) label(N)) mean(pattern(1 1 0 1 0) fmt(3) label(Mean)) p50(pattern(1 1 0 1 0) fmt(2) label(Median)) sd(pattern(1 1 0 1 0) fmt(3) label(SD)) b(star pattern(0 0 1 0 1) fmt(3) label(Diff w.r.t. Treated))") label rename( prefbn2 "Preferred Stock" dlttqbn "Long-Term Debt" dlcqbn "Short-Term Debt" ppentqbn "PPE" bl_1 "Book Leverage" me2 "Market Equity" mk2bk_win "Market to Book" MJuly "Moodys Rating" SPRated "S\&P Rated" SJuly "S\&P Rating" prof_win "Profitability" tang_win "Tangibility" saleqbn "Sales" atqbn "Assets" prefqnorm "Preferred/EV" changeratinglev "Preferred/Capital" Observations "N" ) replace star(* .1 ** .05 *** .01)


* ==============================================================================
* SECTION 3: IDENTIFICATION
* ==============================================================================

use "$proc/MainPanel.dta", clear

* Figure 2: Diff-in-Diff Time Trends of Debt Levels       -> Logdebt TS Continous Matched.png
* Figure 3: Diff-in-Diff Time Trends of Leverage Ratios   -> RL TS Continous Matched.png
* Figure 4: Diff-in-Diff Time-Trends of Assets Levels     -> Assets TS Continous Matched.png
*                                   (Panel A: PP&E)        -> PPE TS Continous Matched.png

* tc27 (2012q2) is the reference period (omitted from level dummy varlist).
* Sample is extended to include tc27 obs so they serve as the comparison base.
* Interactions tc28-tc39 measure DiD effects relative to 2012q2.
* xline(4.2) marks between 2013q2 (position 4) and 2013q3 (position 5).

reghdfe bl_1 tc28 - tc39 1.tc28#c.changeratinglev 1.tc29#c.changeratinglev 1.tc30#c.changeratinglev 1.tc31#c.changeratinglev 1.tc32#c.changeratinglev 1.tc33#c.changeratinglev  1.tc34#c.changeratinglev 1.tc35#c.changeratinglev 1.tc36#c.changeratinglev 1.tc37#c.changeratinglev  1.tc38#c.changeratinglev  1.tc39#c.changeratinglev   $controls if TMJunk == 1 & (sample == 1 | yearquarter == yq(2012,2)) & yearquarter > yq(2012,1) & yearquarter < yq(2015,3) & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
coefplot,  drop(_cons tc28 tc29 tc30 tc31 tc32 tc33 tc34 tc35 tc36 tc37 tc38 tc39 changeratinglev $controls) rename(1.tc28#c.changeratinglev = 2012q3 1.tc29#c.changeratinglev = 2012q4 1.tc30#c.changeratinglev = 2013q1 1.tc31#c.changeratinglev = 2013q2 1.tc32#c.changeratinglev = 2013q3 1.tc33#c.changeratinglev = 2013q4 1.tc34#c.changeratinglev = 2014q1 1.tc35#c.changeratinglev = 2014q2 1.tc36#c.changeratinglev = 2014q3 1.tc37#c.changeratinglev = 2014q4 1.tc38#c.changeratinglev = 2015q1 1.tc39#c.changeratinglev = 2015q2)   xline(4.2, lwidth(*5) lcolor(gs14)) ciopts(lwidth(*1.5) recast(rline)  lpattern(dash)) msize(*1.2) graphregion(color(white)) color(maroon)  recast(connected) levels(90) vertical lwidth(*1.5) bgcolor(white) xlabel(,labsize(small)) xsize(8)
graph export "$figures/BL TS Continous Matched.png", width(900) height(525) replace

reghdfe ratinglev_1 tc28 - tc39 1.tc28#c.changeratinglev 1.tc29#c.changeratinglev 1.tc30#c.changeratinglev 1.tc31#c.changeratinglev 1.tc32#c.changeratinglev 1.tc33#c.changeratinglev  1.tc34#c.changeratinglev 1.tc35#c.changeratinglev 1.tc36#c.changeratinglev 1.tc37#c.changeratinglev  1.tc38#c.changeratinglev  1.tc39#c.changeratinglev   $controls if TMJunk == 1 & (sample == 1 | yearquarter == yq(2012,2)) & yearquarter > yq(2012,1) & yearquarter < yq(2015,3) & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
coefplot,  drop(_cons tc28 tc29 tc30 tc31 tc32 tc33 tc34 tc35 tc36 tc37 tc38 tc39 changeratinglev $controls) rename(1.tc28#c.changeratinglev = 2012q3 1.tc29#c.changeratinglev = 2012q4 1.tc30#c.changeratinglev = 2013q1 1.tc31#c.changeratinglev = 2013q2 1.tc32#c.changeratinglev = 2013q3 1.tc33#c.changeratinglev = 2013q4 1.tc34#c.changeratinglev = 2014q1 1.tc35#c.changeratinglev = 2014q2 1.tc36#c.changeratinglev = 2014q3 1.tc37#c.changeratinglev = 2014q4 1.tc38#c.changeratinglev = 2015q1 1.tc39#c.changeratinglev = 2015q2)   xline(4.2, lwidth(*5) lcolor(gs14)) ciopts(lwidth(*1.5) recast(rline)  lpattern(dash)) msize(*1.2) graphregion(color(white)) color(maroon)  recast(connected) levels(90) vertical lwidth(*1.5) bgcolor(white) xlabel(,labsize(small)) xsize(8)
graph export "$figures/RL TS Continous Matched.png", width(900) height(525) replace   // Figure 2

reghdfe logdebt tc28 - tc39 1.tc28#c.changeratinglev 1.tc29#c.changeratinglev 1.tc30#c.changeratinglev 1.tc31#c.changeratinglev 1.tc32#c.changeratinglev 1.tc33#c.changeratinglev  1.tc34#c.changeratinglev 1.tc35#c.changeratinglev 1.tc36#c.changeratinglev 1.tc37#c.changeratinglev  1.tc38#c.changeratinglev  1.tc39#c.changeratinglev   $controls if TMJunk == 1 & (sample == 1 | yearquarter == yq(2012,2)) & yearquarter > yq(2012,1) & yearquarter < yq(2015,3) & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
coefplot,  drop(_cons tc28 tc29 tc30 tc31 tc32 tc33 tc34 tc35 tc36 tc37 tc38 tc39 changeratinglev $controls) rename(1.tc28#c.changeratinglev = 2012q3 1.tc29#c.changeratinglev = 2012q4 1.tc30#c.changeratinglev = 2013q1 1.tc31#c.changeratinglev = 2013q2 1.tc32#c.changeratinglev = 2013q3 1.tc33#c.changeratinglev = 2013q4 1.tc34#c.changeratinglev = 2014q1 1.tc35#c.changeratinglev = 2014q2 1.tc36#c.changeratinglev = 2014q3 1.tc37#c.changeratinglev = 2014q4 1.tc38#c.changeratinglev = 2015q1 1.tc39#c.changeratinglev = 2015q2)   xline(4.2, lwidth(*5) lcolor(gs14)) ciopts(lwidth(*1.5) recast(rline)  lpattern(dash)) msize(*1.2) graphregion(color(white)) color(maroon)  recast(connected) levels(90) vertical lwidth(*1.5) bgcolor(white) xlabel(,labsize(small)) xsize(8)
graph export "$figures/Logdebt TS Continous Matched.png", width(900) height(525) replace  // Figure 3

reghdfe size tc28 - tc39 1.tc28#c.changeratinglev 1.tc29#c.changeratinglev 1.tc30#c.changeratinglev 1.tc31#c.changeratinglev 1.tc32#c.changeratinglev 1.tc33#c.changeratinglev  1.tc34#c.changeratinglev 1.tc35#c.changeratinglev 1.tc36#c.changeratinglev 1.tc37#c.changeratinglev  1.tc38#c.changeratinglev  1.tc39#c.changeratinglev   $controls if TMJunk == 1 & (sample == 1 | yearquarter == yq(2012,2)) & yearquarter > yq(2012,1) & yearquarter < yq(2015,3) & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
coefplot,  drop(_cons tc28 tc29 tc30 tc31 tc32 tc33 tc34 tc35 tc36 tc37 tc38 tc39 changeratinglev $controls) rename(1.tc28#c.changeratinglev = 2012q3 1.tc29#c.changeratinglev = 2012q4 1.tc30#c.changeratinglev = 2013q1 1.tc31#c.changeratinglev = 2013q2 1.tc32#c.changeratinglev = 2013q3 1.tc33#c.changeratinglev = 2013q4 1.tc34#c.changeratinglev = 2014q1 1.tc35#c.changeratinglev = 2014q2 1.tc36#c.changeratinglev = 2014q3 1.tc37#c.changeratinglev = 2014q4 1.tc38#c.changeratinglev = 2015q1 1.tc39#c.changeratinglev = 2015q2)   xline(4.2, lwidth(*5) lcolor(gs14)) ciopts(lwidth(*1.5) recast(rline)  lpattern(dash)) msize(*1.2) graphregion(color(white)) color(maroon)  recast(connected) levels(90) vertical lwidth(*1.5) bgcolor(white) xlabel(,labsize(small)) xsize(8)
graph export "$figures/Assets TS Continous Matched.png", width(900) height(525) replace  // Figure 4 Panel B

reghdfe ppe tc28 - tc39 1.tc28#c.changeratinglev 1.tc29#c.changeratinglev 1.tc30#c.changeratinglev 1.tc31#c.changeratinglev 1.tc32#c.changeratinglev 1.tc33#c.changeratinglev  1.tc34#c.changeratinglev 1.tc35#c.changeratinglev 1.tc36#c.changeratinglev 1.tc37#c.changeratinglev  1.tc38#c.changeratinglev  1.tc39#c.changeratinglev   $controls if TMJunk == 1 & (sample == 1 | yearquarter == yq(2012,2)) & yearquarter > yq(2012,1) & yearquarter < yq(2015,3) & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
coefplot,  drop(_cons tc28 tc29 tc30 tc31 tc32 tc33 tc34 tc35 tc36 tc37 tc38 tc39 changeratinglev $controls) rename(1.tc28#c.changeratinglev = 2012q3 1.tc29#c.changeratinglev = 2012q4 1.tc30#c.changeratinglev = 2013q1 1.tc31#c.changeratinglev = 2013q2 1.tc32#c.changeratinglev = 2013q3 1.tc33#c.changeratinglev = 2013q4 1.tc34#c.changeratinglev = 2014q1 1.tc35#c.changeratinglev = 2014q2 1.tc36#c.changeratinglev = 2014q3 1.tc37#c.changeratinglev = 2014q4 1.tc38#c.changeratinglev = 2015q1 1.tc39#c.changeratinglev = 2015q2)   xline(4.2, lwidth(*5) lcolor(gs14)) ciopts(lwidth(*1.5) recast(rline)  lpattern(dash)) msize(*1.2) graphregion(color(white)) color(maroon)  recast(connected) levels(90) vertical lwidth(*1.5) bgcolor(white) xlabel(,labsize(small)) xsize(8)
graph export "$figures/PPE TS Continous Matched.png", width(900) height(525) replace      // Figure 4 Panel A

reghdfe M tc28 - tc39 1.tc28#c.changeratinglev 1.tc29#c.changeratinglev 1.tc30#c.changeratinglev 1.tc31#c.changeratinglev 1.tc32#c.changeratinglev 1.tc33#c.changeratinglev  1.tc34#c.changeratinglev 1.tc35#c.changeratinglev 1.tc36#c.changeratinglev 1.tc37#c.changeratinglev  1.tc38#c.changeratinglev  1.tc39#c.changeratinglev   $controls if TMJunk == 1 & (sample == 1 | yearquarter == yq(2012,2)) & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
coefplot,  drop(_cons tc28 tc29 tc30 tc31 tc32 tc33 tc34 tc35 tc36 tc37 tc38 tc39 changeratinglev $controls) rename(1.tc28#c.changeratinglev = 2012q3 1.tc29#c.changeratinglev = 2012q4 1.tc30#c.changeratinglev = 2013q1 1.tc31#c.changeratinglev = 2013q2 1.tc32#c.changeratinglev = 2013q3 1.tc33#c.changeratinglev = 2013q4 1.tc34#c.changeratinglev = 2014q1 1.tc35#c.changeratinglev = 2014q2 1.tc36#c.changeratinglev = 2014q3 1.tc37#c.changeratinglev = 2014q4 1.tc38#c.changeratinglev = 2015q1 1.tc39#c.changeratinglev = 2015q2)   xline(4.2, lwidth(*5) lcolor(gs14)) ciopts(lwidth(*1.5) recast(rline)  lpattern(dash)) msize(*1.2) graphregion(color(white)) color(maroon)  recast(connected) levels(90) vertical lwidth(*1.5) bgcolor(white) xlabel(,labsize(small)) xsize(8)
graph export "$figures/Moody's TS Continous Matched.png", width(900) height(525) replace

reghdfe SP tc28 - tc39 1.tc28#c.changeratinglev 1.tc29#c.changeratinglev 1.tc30#c.changeratinglev 1.tc31#c.changeratinglev 1.tc32#c.changeratinglev 1.tc33#c.changeratinglev  1.tc34#c.changeratinglev 1.tc35#c.changeratinglev 1.tc36#c.changeratinglev 1.tc37#c.changeratinglev  1.tc38#c.changeratinglev  1.tc39#c.changeratinglev   $controls if TMJunk == 1 & (sample == 1 | yearquarter == yq(2012,2)) & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
coefplot,  drop(_cons tc28 tc29 tc30 tc31 tc32 tc33 tc34 tc35 tc36 tc37 tc38 tc39 changeratinglev $controls) rename(1.tc28#c.changeratinglev = 2012q3 1.tc29#c.changeratinglev = 2012q4 1.tc30#c.changeratinglev = 2013q1 1.tc31#c.changeratinglev = 2013q2 1.tc32#c.changeratinglev = 2013q3 1.tc33#c.changeratinglev = 2013q4 1.tc34#c.changeratinglev = 2014q1 1.tc35#c.changeratinglev = 2014q2 1.tc36#c.changeratinglev = 2014q3 1.tc37#c.changeratinglev = 2014q4 1.tc38#c.changeratinglev = 2015q1 1.tc39#c.changeratinglev = 2015q2)   xline(4.2, lwidth(*5) lcolor(gs14)) ciopts(lwidth(*1.5) recast(rline)  lpattern(dash)) msize(*1.2) graphregion(color(white)) color(maroon)  recast(connected) levels(90) vertical lwidth(*1.5) bgcolor(white) xlabel(,labsize(small)) xsize(8)
graph export "$figures/SP TS Continous Matched.png", width(900) height(525) replace
* ==============================================================================
* SECTION 4: MAIN RESULTS -- FINANCING
* ==============================================================================

use "$proc/MainPanel.dta", clear

* Table 3: The Effect of Rule Change on Debt Levels

eststo clear
eststo: quietly reghdfe logdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logltdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logltdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logstdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logstdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/debt.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Table 4: Yearly Placebo Tests
eststo clear
forvalues i = 2008/2015 {
eststo: quietly reghdfe logdebt secondhalf##treatment $controls if year_cq== `i' & TMJunk ==1  & matched == 1, absorb(i.tcohort i.companycode) vce(cluster companycode)
quietly: estadd local controls "Y"
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local year "`i'"
}
esttab using "$tables/placebo.tex", drop( 1.treatment 1.secondhalf prof_win tang_win mk2bk_win sales_win) cells(b(star fmt(3)) t(par fmt(2))) rename(1.secondhalf#1.treatment "AfterJulyxPreferred"  1.secondhalf#1.TMJunk "AfterJulyxJunk" 1.secondhalf#1.treatment#1.TMJunk "AfterJulyxPreferredxJunk") stats(space year controls firm quarter N r2_within , fmt(0 0 0 0 0 0 3) labels(" " "Year" "Controls" "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(AfterJulyxPreferred "Preferred x After July" AfterJulyxJunk "After July x Junk" AfterJulyxPreferredxJunk "After July x Preferred x Junk"  _cons "Constant" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table 5: The Effect of Rule Change on Leverage

eststo clear
eststo: quietly reghdfe bl_1 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ratinglev_1 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ratinglev_1 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/leverage.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace


* ==============================================================================
* SECTION 5: MAIN RESULTS -- INVESTMENT
* ==============================================================================

* Table 6: The Effect of Rule Change on the Balance Sheet

eststo clear
eststo: quietly reghdfe logcapex 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logcapex 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/real.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace


* ==============================================================================
* SECTION 6: MARKET REACTIONS
* ==============================================================================

* Table 8: Stock Price Response to Moody's Rule Change

use "$proc/EquityCAR.dta", clear

eststo clear
eststo: quietly reg prepcar treatment $controls i.cohort if matched == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg prepcar changeratinglev $controls i.cohort if matched == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg car treatment $controls i.cohort if matched == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg car changeratinglev $controls i.cohort if matched == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg car2 treatment $controls i.cohort if matched == 1, robust
quietly: estadd local industry "Y"
eststo: quietly reg car2 changeratinglev $controls i.cohort if matched == 1, robust
quietly: estadd local industry "Y"
eststo: quietly reg postpcar430 treatment $controls i.cohort if matched == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg postpcar430 changeratinglev $controls i.cohort if matched == 1 , robust
quietly: estadd local industry "Y"
esttab using "$tables/car.tex",  order(treatment changeratinglev) drop(*.cohort _cons) cells(b(star fmt(3)) t(par fmt(2))) stats(space industry N r2 , fmt( 0 0 0 3) labels(" " "Cohort FE" "Firms" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(changeratinglev "Preferred/Capital" treatment "Preferred Dummy"  1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table 9: Credit Spread Response to Moody's Rule Change

use "$proc/BondCAR_Matched.dta", clear

eststo clear
eststo: quietly reg w2car0 treatment $controls i.cohort , robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car0 changeratinglev $controls i.cohort , robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car treatment $controls i.cohort , robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car changeratinglev $controls i.cohort , robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car2 treatment $controls i.cohort, robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car2 changeratinglev $controls i.cohort, robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car430 treatment $controls i.cohort , robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car430 changeratinglev $controls i.cohort , robust
quietly: estadd local industry "Y"
esttab using "$tables/carspreadsNewMatch.tex",  order(treatment changeratinglev) drop(*.cohort _cons) cells(b(star fmt(1)) t(par fmt(2))) stats(space industry N r2 , fmt( 0 0 0 3) labels(" " "Cohort FE" "Firms" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(changeratinglev "Preferred/Capital" treatment "Preferred Dummy"  1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales"  ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace


* ==============================================================================
* SECTION 7: MECHANISM -- CONVERTIBLES
* ==============================================================================

use "$proc/MainPanel.dta", clear

* Table 10: The Effect of Convertible Debt on Response to Rule Change (continuous)
* Table A.23: Same specification with convertible dummy (instead of continuous)

eststo clear
eststo: quietly reghdfe logdebt 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logdebt 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/converts.tex", order(1.event#1.treatment 1.event#1.treatment#c.convert2_1 1.event#c.changeratinglev 1.event#c.changeratinglev#c.convert2_1 1.event#c.convert2_1) drop(1.treatment#c.convert2_1 c.changeratinglev#c.convert2_1 convert2_1 1.event changeratinglev 1.treatment) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#c.convert2_1 "Convert x Post" 1.event#c.changeratinglev#c.convert2_1 "Preferred/Capital x Convert x Post" 1.event#1.treatment "Preferred Dummy x Post" 1.treatment#c.convert2_1 "Preferred Dummy x Convert" 1.event#1.treatment#c.convert2_1 "Preferred Dummy x Convert x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Table A.23: Convertibles -- Dummy Version
gen convert2_1_dum = (convert2_1>0)
clear mata
eststo clear
eststo: quietly reghdfe logdebt 1.event##1.treatment##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe logdebt 1.event##c.changeratinglev##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe bl_1 1.event##1.treatment##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe bl_1 1.event##c.changeratinglev##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe ppe 1.event##1.treatment##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe ppe 1.event##c.changeratinglev##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe size 1.event##1.treatment##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe size 1.event##c.changeratinglev##1.convert2_1_dum $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
esttab using "$tables/converts_dummy.tex", order(1.event#1.treatment 1.event#1.treatment#1.convert2_1_dum 1.event#c.changeratinglev 1.event#1.convert2_1_dum#c.changeratinglev) drop(_cons 1.convert2_1_dum 1.treatment#1.convert2_1_dum 1.event changeratinglev 1.treatment 1.convert2_1_dum#c.changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#1.convert2_1_dum "Convert x Post" 1.event#1.treatment#1.convert2_1_dum "Preferred Dummy x Convert x Post" 1.event#1.treatment "Preferred Dummy x Post" 1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.convert2_1_dum#c.changeratinglev "Preferred/Capital x Convert x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace



* ==============================================================================
* SECTION 8: MECHANISM -- PREFERRED STOCK
* ==============================================================================

* Table 11: The Effect of Rule Change on Preferred Stock Levels

eststo clear
eststo: quietly reghdfe prefevpp event##MJunkonly $controls if sample_short == 1 & junk == 1 & matched == 0 ,  absorb(i.timecode i.companycode) vce(cluster companycode )
quietly: estadd local sample "Junk"
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe logpref event##MJunkonly $controls if sample_short == 1 & junk == 1 & matched == 0 ,  absorb(i.timecode i.companycode) vce(cluster companycode )
quietly: estadd local sample "Junk"
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe prefevpp event##MIGonly $controls if sample_short == 1 & ig == 1 & matched == 0 ,  absorb(i.timecode i.companycode) vce(cluster companycode )
quietly: estadd local sample "IG"
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe logpref event##MIGonly $controls if sample_short == 1 & ig == 1 & matched == 0 ,  absorb(i.timecode i.companycode) vce(cluster companycode )
quietly: estadd local sample "IG"
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
esttab using "$tables/preferred2.tex", order( 1.event#1.MJunkonly 1.event#1.MIGonly) drop(1.MIGonly 1.MJunkonly 1.event ) cells(b(star fmt(3)) t(par fmt(2))) stats(space sample firm quarter N r2_within , fmt(0 0 0 0 0  3) labels(" " "Sample" "Firm FE" "Quarter FE"  "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#1.MIGonly "MIGOnly x Post" sales_win "Sales" 1.event#1.MJunkonly "MJOnly x Post" mk2bk_win "Market-to-Book"  _cons "Constant" size_win "Size" prof_win "Profitability" tang_win "Tangibility") fragment mlabels(none) collabels(none) nolines posthead(\hline) replace


* ==============================================================================
* SECTION 9: RATINGS EFFECTS
* ==============================================================================

* Table 12: The Effect of Rule Change on Credit Ratings

eststo clear
eststo: quietly reghdfe M 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe M 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe SP 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe SP 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/ratings.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.4: Triple Difference -- S&P Rated

eststo clear
eststo: quietly reghdfe logdebt 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short  == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe M 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/3diff2.tex", order(1.event#1.treatment#1.SPRated 1.event#1.treatment 1.event#1.SPRated ) drop(1.treatment 1.treatment#1.SPRated 1.SPRated 1.event) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#1.SPRated "Post x SP" 1.event#1.SPRated#c.changeratinglev "Preferred/Capital x Post x SP" 1.treatment#1.SPRated "Preferred Dummy x SP" 1.treatment "Preferred Dummy" 1.event#1.treatment#1.SPRated "Preferred Dummy x Post x SP" 1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Table A.4 (variant): Triple Difference -- S&P Positive Rating

eststo clear
eststo: quietly reghdfe logdebt 1.event##c.changeratinglev##1.SPpos $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##c.changeratinglev##1.SPpos $controls if TMJunk == 1 & sample_short  == 1  & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##c.changeratinglev##1.SPpos $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##c.changeratinglev##1.SPpos $controls if TMJunk == 1 & sample_short  == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/3diff.tex", order(1.event#1.SPpos#c.changeratinglev 1.event#c.changeratinglev 1.event#1.SPpos ) drop(1.SPpos#c.changeratinglev 1.SPpos 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#1.SPpos "Post x SPPos" 1.event#1.SPpos#c.changeratinglev "Preferred/Capital x Post x SPPos" 1.event#1.treatment#1.SPpos "Preferred Dummy x Post x SPPos" 1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace


* ==============================================================================
* ONLINE APPENDIX
* ==============================================================================

use "$proc/MainPanel.dta", clear

* Table A.1: List of Treated Firms
keep if matched == 0 & treated == 1
keep conm ffi
sort conm
duplicates drop
replace conm = proper(conm)
listtex conm ffi using "$tables/list.tex", rstyle(tabular) replace

* ==============================================================================
* Figure A.1 / Table A.2: Financial Constraint Measures
* Required packages: ssc install iebaltab
* ==============================================================================

use "$proc/MainPanel.dta", clear

drop tcohort cohort

keep if matched == 1 | (matched == 0 & treated == 0)
bys companycode datadate: egen matched_max = max(matched)
drop matched
rename matched_max matched
duplicates drop

keep if treatmentq == 1

* Figure A.1: Density plots of financial constraint indices by treatment group
foreach var in WW_w KZ_w SA_w {
    twoway (kdensity `var' if treated == 1 & TMJunk == 1 & matched == 1, color(navy)) ///
           (kdensity `var' if treated == 0 & TMJunk == 1 & matched == 1, color(green)) ///
           (kdensity `var' if matched == 0  & TMJunk == 1, color(red)), ///
           legend(order(1 "Treated" 2 "Matched Untreated" 3 "Unmatched Untreated")) ///
           xtitle("`var'") ytitle("Density") ///
           bgcolor(white) graphregion(color(white))
    graph export "$figures/`var'_density.png", replace
}

* Table A.2: Balance table for financial constraint indices
gen treated_matched = 0 if matched == 0
replace treated_matched = 1 if treated == 0 & matched == 1
replace treated_matched = 2 if treated == 1 & matched == 1
iebaltab WW_w KZ_w SA_w if TMJunk == 1, grpvar(treated_matched) ///
    grplabels(2 "Treated" @ 1 "Matchd Untreated" @ 0 "Unmatched Untreated") ///
    rowvarlabels ///
    rowlabels(WW_w "Whited-Wu Index" KZ_w "Kaplan-Zingales Index" SA_w "Size-Age Index") ///
    savetex("$tables/fin_constraints_balance.tex") replace ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01")

* Table A.3: Ratings and LevGAAP
use "$proc/MainPanel.dta", clear
keep if treatmentq == 1 & matched == 0

* Top panel: mean LevGAAP by Moody's rating bucket → rating.tex
eststo clear
forvalues i = 11/22 {
    capture noisily eststo: quietly estpost summarize bl_1 if MJuly == `i'
}
esttab using "$tables/rating.tex", stat(N, labels("N") fmt(0)) cells("mean(fmt(3) label(Mean))") label rename(bl_1 "Book Leverage") fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Bottom panel: regression of LevGAAP on Moody's Rating → rating2.tex
eststo clear
eststo: quietly xi: reg bl_1 MJuly i.industry if TMJunk == 1
quietly: estadd local sample "All"
quietly: estadd local fe "Y"
eststo: quietly xi: reg bl_1 MJuly i.industry if TMJunk == 1 & M >= 13 & M <= 17
quietly: estadd local sample "Caa1 - Ba3"
quietly: estadd local fe "Y"
esttab using "$tables/rating2.tex", drop(_I* _cons) cells(b(star fmt(3)) t(par fmt(2))) stats(sample fe N r2, fmt(0 0 0 3) labels("Sample" "Industry FE" "N" "R\textsuperscript{2}")) nobaselevels starlevels(* .10 ** .05 *** .01) varlabels(MJuly "Moody's Rating") fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Reload full dataset for subsequent tables
use "$proc/MainPanel.dta", clear

* Table A.5: Debt -- Full (Unmatched) Sample
eststo clear
eststo: quietly reghdfe logdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logltdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logltdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logstdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 0,  absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logstdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/debtunmatched.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Table A.7: Leverage -- Full (Unmatched) Sample
eststo clear
eststo: quietly reghdfe bl_1 1.event##treatment $controls if TMJunk == 1 & sample == 1 & matched == 0 , absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##c.changeratinglev $controls if TMJunk == 1 & sample == 1  & matched == 0 ,  absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ratinglev_1 1.event##treatment $controls if TMJunk == 1 & sample == 1 & matched == 0 ,  absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ratinglev_1 1.event##c.changeratinglev $controls if TMJunk == 1 & sample == 1  & matched == 0 ,  absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/leveragefullsample.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.6: Yearly Placebo Tests -- Full (Unmatched) Sample
eststo clear
forvalues i = 2008/2015 {
eststo: quietly  reghdfe logdebt secondhalf##treatment $controls if year_cq== `i' & TMJunk ==1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local controls "Y"
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local year "`i'"
}
esttab using "$tables/placebounmatched.tex", drop( 1.treatment 1.secondhalf prof_win tang_win mk2bk_win sales_win) cells(b(star fmt(3)) t(par fmt(2))) rename(1.secondhalf#1.treatment "AfterJulyxPreferred"  1.secondhalf#1.TMJunk "AfterJulyxJunk" 1.secondhalf#1.treatment#1.TMJunk "AfterJulyxPreferredxJunk") stats(space year controls firm quarter N r2_within , fmt(0 0 0 0 0 0 3) labels(" " "Year" "Controls" "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(AfterJulyxPreferred "Preferred x After July" AfterJulyxJunk "After July x Junk" AfterJulyxPreferredxJunk "After July x Preferred x Junk"  _cons "Constant" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.8: Investment -- Full (Unmatched) Sample
eststo clear
eststo: quietly reghdfe logcapex 1.event##treatment $controls if TMJunk == 1 & sample_short == 1   & matched == 0,  absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logcapex 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1   & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1   & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/realfullsample.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.9: Equity CAR -- Full (Unmatched) Sample
use "$proc/EquityCAR.dta", clear

eststo clear
eststo: quietly reg prepcar treatment $controls i.industry if matched == 0 & TMJunk == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg prepcar changeratinglev $controls i.industry if matched == 0 & TMJunk == 1  , robust
quietly: estadd local industry "Y"
eststo: quietly reg car treatment $controls i.industry if matched == 0 & TMJunk == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg car changeratinglev $controls i.industry if matched == 0 & TMJunk == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg car2 treatment $controls i.industry if matched == 0 & TMJunk == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg car2 changeratinglev $controls i.industry if matched == 0 & TMJunk == 1 , robust
quietly: estadd local industry "Y"
eststo: quietly reg postpcar430 treatment $controls i.industry if matched == 0 & TMJunk == 1  , robust
quietly: estadd local industry "Y"
eststo: quietly reg postpcar430 changeratinglev $controls i.industry if matched == 0 & TMJunk == 1 , robust
quietly: estadd local industry "Y"
esttab using "$tables/carunmatched.tex",  order(treatment changeratinglev) drop(*.industry  _cons) cells(b(star fmt(3)) t(par fmt(2))) stats(space industry N r2 , fmt( 0 0 0 3) labels(" " "Industry FE" "Firms" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(changeratinglev "Preferred/Capital" treatment "Preferred Dummy"  1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.10: Credit Spread CAR -- Full (Unmatched) Sample
use "$proc/BondCAR.dta", clear

eststo clear
eststo: quietly reg w2car0 treatment i.industry $controls if matched == 0, robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car0 changeratinglev i.industry  $controls if matched == 0 , robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car treatment i.industry  $controls if matched == 0, robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car changeratinglev i.industry  $controls if matched == 0 , robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car2 treatment i.industry  $controls if matched == 0, robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car2 changeratinglev i.industry  $controls if matched == 0, robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car430 treatment i.industry  $controls if matched == 0, robust
quietly: estadd local industry "Y"
eststo: quietly reg w2car430 changeratinglev i.industry  $controls if matched == 0, robust
quietly: estadd local industry "Y"
esttab using "$tables/carspreadsUnMatched.tex",  order(treatment changeratinglev) drop(*.industry _cons) cells(b(star fmt(1)) t(par fmt(2))) stats(space industry N r2 , fmt( 0 0 0 3) labels(" " "Industry FE" "Firms" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(changeratinglev "Preferred/Capital" treatment "Preferred Dummy" 1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

use "$proc/MainPanel.dta", clear
clear mata

* Table A.11: Convertibles -- Full (Unmatched) Sample
eststo clear
eststo: quietly reghdfe logdebt 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe logdebt 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##1.treatment##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##c.changeratinglev##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/convertsunmatched.tex", order(1.event#1.treatment 1.event#1.treatment#c.convert2_1 1.event#c.changeratinglev 1.event#c.changeratinglev#c.convert2_1 1.event#c.convert2_1) drop(1.treatment#c.convert2_1 c.changeratinglev#c.convert2_1 convert2_1 1.event changeratinglev 1.treatment) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#c.convert2_1 "Convert x Post" 1.event#c.changeratinglev#c.convert2_1 "Preferred/Capital x Convert x Post" 1.event#1.treatment "Preferred Dummy x Post" 1.treatment#c.convert2_1 "Preferred Dummy x Convert" 1.event#1.treatment#c.convert2_1 "Preferred Dummy x Convert x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Table A.12: Ratings -- Full (Unmatched) Sample
eststo clear
eststo: quietly reghdfe M 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe M 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe SP 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe SP 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/ratingsfullsample.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.4 (unmatched): Triple Difference -- S&P Rated, Full Sample
eststo clear
eststo: quietly reghdfe logdebt 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short  == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe M 1.event##1.treatment##1.SPRated $controls if TMJunk == 1 & sample_short == 1  & matched == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/3diff2unmatched.tex", order( 1.event#1.treatment#1.SPRated 1.event#1.treatment 1.event#1.SPRated ) drop(1.treatment 1.treatment#1.SPRated 1.SPRated 1.event) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#1.SPRated "Post x SP" 1.event#1.SPRated#c.changeratinglev "Preferred/Capital x Post x SP" 1.treatment#1.SPRated "Preferred Dummy x SP" 1.treatment "Preferred Dummy" 1.event#1.treatment#1.SPRated "Preferred Dummy x Post x SP" 1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Table A.13: Different Control Groups
eststo clear
eststo: quietly reghdfe bl_1 event##TMJunk if treatment == 1 & sample == 1 & matched == 0, absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local quarterc "N"
quietly: estadd local sample "Preferred"
eststo: quietly reghdfe bl_1 event##TMJunk $controls if treatment == 1 & sample == 1 & matched == 0, absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local quarterc "N"
quietly: estadd local sample "Preferred"
eststo: quietly reghdfe bl_1 event##treatment##TMJunk if sample == 1 & matched == 0, absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local quarterc "N"
quietly: estadd local sample "All"
eststo: quietly reghdfe bl_1 event##treatment##TMJunk $controls if sample == 1 & matched == 0, absorb(i.timecode i.companycode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local quarterc "N"
quietly: estadd local sample "All"
esttab using "$tables/diffcontrols.tex", drop(1.treatment 1.event 1.TMJunk 1.treatment#1.TMJunk) cells(b(star fmt(3)) t(par fmt(2))) rename(1.event#1.treatment "PreferredxPost"  1.event#1.TMJunk "JunkxPost" 1.event#1.treatment#1.TMJunk "PreferredxPostxJunk" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales") stats(blank sample firm quarter quarterc N r2_within , fmt(0 0 0 0 0 0  3) labels(" " "Sample" "Firm FE" "Quarter FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) order( "JunkxPost" "PreferredxPostxJunk" "PreferredxPost" ) varlabels(PreferredxPost "Preferred x Post" JunkxPost "Junk x Post" PreferredxPostxJunk "Preferred x Post x Junk"  _cons "Constant" StockReturn "Stock Return") fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.14: Debt-to-Assets -- Matched Sample
eststo clear
eststo: quietly reghdfe bla_1 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bla_1 1.event##c.changeratingbla $controls if TMJunk == 1 & sample_short == 1  & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ratingbla_1 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ratingbla_1 1.event##c.changeratingbla $controls if TMJunk == 1 & sample_short == 1  & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/debttoassets2.tex", order(1.event#1.treatment 1.event#c.changeratingbla ) drop(1.treatment 1.event changeratingbla) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratingbla "Preferred/Assets x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace


* Table A.15: Market Trends around Moody's Rule Change Announcement (Jul 31 2013)
* Event date = July 31, 2013.  Window [-w,+w] = close at day -w to close at day +w.
* Cumulative return = p[er+w]/p[er-w] - 1 (telescoped sum of 2w daily log returns).
* S&P 500 cumulative return (%); 10Y Treasury cumulative yield change (bps).

local event_date = td(31jul2013)

* ── S&P 500 ──────────────────────────────────────────────────────────────────
use "$proc/SP500.dta", clear
keep if date >= td(01jun2013) & date <= td(30sep2013)
sort date
gen row = _n
gen logp = ln(sp500_close)
gen daily_ret = logp - logp[_n-1]

sum row if date == `event_date'
local er = r(mean)

foreach w in 1 3 5 {
    sum daily_ret if row > `er' - `w' & row <= `er' + `w'
    local sp_`w' = (exp(r(sum)) - 1)*100
}

* ── 10Y Treasury (^TNX from Yahoo Finance) ───────────────────────────────────
use "$proc/TNX.dta", clear
keep if date >= td(01jun2013) & date <= td(30sep2013)
sort date
gen row = _n
gen daily_yld_chg = (tnx_yield - tnx_yield[_n-1]) * 100

sum row if date == `event_date'
local er_tn = r(mean)

foreach w in 1 3 5 {
    sum daily_yld_chg if row > `er_tn' - `w' & row <= `er_tn' + `w'
    local tn_`w' = r(sum)
}

* ── Write LaTeX ───────────────────────────────────────────────────────────────
local sp1 : display %4.2f `sp_1'
local sp3 : display %4.2f `sp_3'
local sp5 : display %4.2f `sp_5'
local tn1 : display %4.2f `tn_1'
local tn3 : display %4.2f `tn_3'
local tn5 : display %4.2f `tn_5'

file open fh using "$tables/markettrends.tex", write replace
file write fh "            " ///
    "&\multicolumn{1}{c}{[-1,+1]}   " ///
    "&\multicolumn{1}{c}{[-3,+3]}   " ///
    "&\multicolumn{1}{c}{[-5,+5]}   \\" _n
file write fh "\hline" _n
file write fh "S\&P 500 Cumulative Return (\%)" ///
    "&       `sp1'   &       `sp3'   &       `sp5'   \\" _n
file write fh "10 Year Treasury Cumulative Yield Change (bps)" ///
    "&       `tn1'   &       `tn3'   &       `tn5'   \\" _n
file close fh

di "=== markettrends.tex written ==="
type "$tables/markettrends.tex"

* Reload main panel for subsequent tables
use "$proc/MainPanel.dta", clear

* Table A.22: PPE with Inverse Hyperbolic Sine Transformation
gen ihs_ppe = asinh(ppentq)

eststo clear
eststo: quietly reghdfe ihs_ppe 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ihs_ppe 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/ppe_asinh.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Tables A.16–A.17: Determinants of Preferred Stock and Convertibles
use "$proc/MainPanel.dta", clear
keep if treatmentq == 1
global controls "prof_win tang_win sales_win mk2bk_win bl_1 me2 ppe size"

* Table A.16: Determinants of Preferred Stock
eststo clear
eststo: quietly reghdfe preferred $controls if matched == 0, absorb(i.industry)
quietly: estadd local sample "All"
quietly: estadd local industry "Y"
eststo: quietly reghdfe preferred $controls if junk == 1 & matched == 0, absorb(i.industry)
quietly: estadd local sample "Junk"
quietly: estadd local industry "Y"
eststo: quietly reghdfe preferred $controls if junk == 0 & rated == 1 & matched == 0, absorb(i.industry)
quietly: estadd local sample "IG"
quietly: estadd local industry "Y"
eststo: quietly reghdfe preferred $controls if rated == 0 & matched == 0, absorb(i.industry)
quietly: estadd local sample "Unrated"
quietly: estadd local industry "Y"
eststo: quietly reghdfe treated $controls if matched == 1, absorb(i.industry)
quietly: estadd local sample "Matched"
quietly: estadd local industry "Y"
esttab using "$tables/prefdet.tex", drop(_cons) cells(b(star fmt(3)) t(par fmt(2))) stats(space sample industry N r2 , fmt(0 0 0 0 3) labels(" " "Sample" "Industry FE" "Observations" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" size "Log(Assets)" me2 "Market Cap" bl_1 "Leverage" ppe "Log(PPE)" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Table A.17: Determinants of Convertibles
eststo clear
eststo: quietly reghdfe convert $controls if matched == 0, absorb(i.industry)
quietly: estadd local sample "All"
quietly: estadd local industry "Y"
eststo: quietly reghdfe convert $controls if junk == 1 & matched == 0, absorb(i.industry)
quietly: estadd local sample "Junk"
quietly: estadd local industry "Y"
eststo: quietly reghdfe convert $controls if junk == 0 & rated == 1 & matched == 0, absorb(i.industry)
quietly: estadd local sample "IG"
quietly: estadd local industry "Y"
eststo: quietly reghdfe convert $controls if rated == 0 & matched == 0, absorb(i.industry)
quietly: estadd local sample "Unrated"
quietly: estadd local industry "Y"
eststo: quietly reghdfe convert $controls if matched == 1, absorb(i.industry)
quietly: estadd local sample "Matched"
quietly: estadd local industry "Y"
esttab using "$tables/convertdet.tex", drop(_cons) cells(b(star fmt(3)) t(par fmt(2))) stats(space sample industry N r2 , fmt(0 0 0 0 3) labels(" " "Sample" "Industry FE" "Observations" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" size "Log(Assets)" me2 "Market Cap" bl_1 "Leverage" ppe "Log(PPE)" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

global controls "prof_win tang_win sales_win mk2bk_win"

* Table 7 / Table A.18 / Appendix: Placebo Tests -- Alternate Treatment Groups
use "$proc/MainPanel.dta", clear
drop if matched == 1

* Convertible placebo (junk non-preferred firms)
eststo clear
eststo: quietly reghdfe logdebt 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe bl_1 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe ppe 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe size 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
esttab using "$tables/convertplacebo.tex", drop(_cons 1.event convert2_1) style(tex) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarter N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.convert2_1 "Convert x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Convertible placebo: IG vs Junk interaction
eststo clear
eststo: quietly reghdfe logdebt 1.event##c.convert2_1##TMJunk $controls if sample_short == 1 & treatment == 1, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe bl_1 1.event##c.convert2_1##TMJunk $controls if sample_short == 1 & treatment == 1, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe ppe 1.event##c.convert2_1##TMJunk $controls if sample_short == 1 & treatment == 1, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
eststo: quietly reghdfe size 1.event##c.convert2_1##TMJunk $controls if sample_short == 1 & treatment == 1, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
esttab using "$tables/convertIGplacebo.tex", drop(1.TMJunk#c.convert2_1 _cons 1.event convert2_1 1.TMJunk) order(1.event#1.TMJunk#c.convert2_1) style(tex) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarter N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.convert2_1 "Convert x Post" 1.event#1.TMJunk#c.convert2_1 "Convert x Post x Junk" 1.event#1.TMJunk "Post x Junk" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales"  1.TMJunk#c.convert2_1 "Convert x Junk") fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Unrated placebo
eststo clear
eststo: quietly reghdfe logdebt 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe bl_1 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe ppe 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
eststo: quietly reghdfe size 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
esttab using "$tables/unratedplacebo.tex", order(1.event#1.preferred) drop(_cons 1.preferred 1.event) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.preferred "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Combined placebo (Junk convertibles + Unrated preferred)
eststo clear
eststo: quietly reghdfe logdebt 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local sample "Junk"
eststo: quietly reghdfe logdebt 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local sample "Unrated"
eststo: quietly reghdfe bl_1 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local sample "Junk"
eststo: quietly reghdfe bl_1 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
quietly: estadd local sample "Unrated"
eststo: quietly reghdfe ppe 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local sample "Junk"
eststo: quietly reghdfe ppe 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local sample "Unrated"
eststo: quietly reghdfe size 1.event##c.convert2_1 $controls if TMJunk == 1 & sample_short == 1 & treated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local sample "Junk"
eststo: quietly reghdfe size 1.event##preferred $controls if sample_short == 1 & matched == 0 & rated == 0, absorb(i.companycode i.timecode) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarter "Y"
quietly: estadd local sample "Unrated"
esttab using "$tables/combinedplacebo.tex", style(tex) order(1.event#c.convert2_1 1.event#1.preferred) drop(_cons 1.preferred 1.event convert2_1) cells(b(star fmt(3)) t(par fmt(2))) stats(space sample firm quarter N r2_within , fmt(0 0 0 0 0 3) labels(" " "Sample" "Firm FE" "Quarter FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.preferred "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" 1.event#c.convert2_1 "Convert x Post") fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Tables A.19-A.21: Main Results -- 1 Match without Replacement
clear mata
use "$proc/MainPanel_1norep.dta", clear

global controls  "prof_win tang_win sales_win mk2bk_win"
global controls2 "prof_win0 tang_win0 sales_win0 mk2bk_win0"

* Debt
eststo clear
eststo: quietly reghdfe logdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe logdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe logltdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe logltdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe logstdebt 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe logstdebt 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
esttab using "$tables/debt_1norep.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) eqlabels(none) replace

* Leverage
eststo clear
eststo: quietly reghdfe bl_1 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe bl_1 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe ratinglev_1 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe ratinglev_1 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1 , absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
esttab using "$tables/leverage_1norep.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

* Investment
eststo clear
eststo: quietly reghdfe logcapex 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe logcapex 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe ppe 1.event##treatment $controls if TMJunk == 1 & sample_short == 1  & matched == 1,  absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe ppe 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe size 1.event##treatment $controls if TMJunk == 1 & sample_short == 1 & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
eststo: quietly reghdfe size 1.event##c.changeratinglev $controls if TMJunk == 1 & sample_short == 1  & matched == 1, absorb(i.companycode i.tcohort) vce(cluster companycode)
quietly: estadd local firm "Y"
quietly: estadd local quarterc "Y"
clear mata
esttab using "$tables/real_1norep.tex", order(1.event#1.treatment 1.event#c.changeratinglev ) drop(1.treatment 1.event changeratinglev) cells(b(star fmt(3)) t(par fmt(2))) stats(space firm quarterc N r2_within , fmt(0 0 0 0 3) labels(" " "Firm FE" "Quarter x Cohort FE" "Firm Quarters" "R\textsuperscript{2}"))  nobaselevels interaction(" X ") starlevels(* .10 ** .05 *** .01) varlabels(1.event#c.changeratinglev "Preferred/Capital x Post" 1.event#1.treatment "Preferred Dummy x Post" prof_win "Profitability" tang_win "Tangibility" yearret "StockReturn" mk2bk_win "Market-to-Book" sales_win "Sales" ) fragment mlabels(none) collabels(none) nolines posthead(\hline) replace

capture log close


