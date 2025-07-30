* =============================================================================
* INDIA’S BILATERAL TRADE ANALYSIS VIA STRUCTURAL GRAVITY MODEL (1995–2021)
* =============================================================================
* Suggested       : Assessing the Impact of Preferential Trade Agreements on India’s
* Topic             Bilateral Trade Flows: An Augmented Gravity Model Approach
* 
* Purpose     : To empirically evaluate whether India’s Preferential Trade 
*               Agreements (PTAs) significantly affect bilateral trade volumes,
*               controlling for economic size, distance, and institutional factors.
*
* Research Qs : - Do India’s PTAs increase bilateral trade?
*               - Which PTAs have the strongest/weakest effects?
*               - Are effects shaped by geography and institutions (e.g. WTO)?
*               - Are impacts symmetric across exports/imports?
*
* Data        : gravity_model.dta
*               - Source: BACI (trade), WDI (macro), CEPII (geography/institutions)
*               - Panel: 1995–2021, India as origin (iso3_o == "IND")
*               - >4.7 million obs, filtered to 4,713 rows for India’s dyads
*
* Methodology : Phase 1 – Data filtering, variable creation
*               Phase 2 – Descriptive analysis, trade patterns, PTA diagnostics
*               Phase 3 – Econometric estimation:
*                         - Pooled OLS (baseline)
*                         - Fixed Effects (preferred)
*                         - Random Effects (for comparison)
*                         - Hausman test
*                         - Robustness checks (interaction terms, subgroup analysis)
* =============================================================================

* (1) Loading data
clear
cls
cd "C:\Users\Administrator\Desktop\WORK\Assignments\ONES\Stata Thesis"
* Load preprocessed dataset with all factor variables included
use "gravity_final_with_factors.dta", clear

* (2) Inspect the dataset structure and spot missingness
* - describe: metadata (var names, types, labels)
* - misstable summarize: good first check for NAs and completeness
describe
misstable summarize
misstable summarize emp_o emp_d hc_o hc_d cn_o cn_d land_o land_d kl_diff landl_diff hc_diff


* (3) Summary statistics of core economic and geographic variables
* These are the basis of the gravity model, so I need to know:
* - whether values are realistic (range, scale)
* - whether any are highly skewed or prone to transformation
summarize tradeflow_baci gdp_o gdp_d dist pop_o pop_d
summarize kl_diff landl_diff hc_diff emp_o emp_d cn_o cn_d land_o land_d

* (4) Visualize the trade flow distribution
* - histogram with normal curve: shows skewness, long-tail nature
* - kernel density: smooth distribution check, used to justify logs
histogram tradeflow_baci, normal title("Histogram: India's Trade Flows")
kdensity tradeflow_baci, title("Kernel Density: India's Trade Flows")

* (5) Identify India’s major trading partners (by frequency of non-zero trade)
* - THis will help me later with robustness checks, partner-level fixed effects
tab iso3_d if tradeflow_baci > 0, sort

* (6) Descriptive summary of key gravity variables
* - I will use this for interpreting coefficient magnitude
tabstat tradeflow_baci gdp_o gdp_d dist, stat(mean sd min max n) columns(statistics)
tabstat kl_diff landl_diff hc_diff, stat(mean sd min max n) columns(statistics)

* (7) Visualize India’s total outbound trade trend (1995–2021)
* - Sum trade values for each year (across all partners)
* - Plot trend to detect shocks, breakpoints (e.g., global financial crisis, COVID)
bysort year (iso3_d): gen one = 1  // dummy to enable collapse safely
preserve
collapse (sum) tradeflow_baci, by(year)

* Generate a smoother for visualization (optional)
gen tradeflow_baci_millions = tradeflow_baci / 1e6

* Plot the line graph of total trade value
twoway (line tradeflow_baci_millions year, lwidth(medthick)), ///
    title("India’s Total Outbound Trade (1995–2021)") ///
    ytitle("Total Exports (Million USD)") ///
    xtitle("Year") ///
    ylabel(, angle(horizontal)) ///
    xlabel(1995(5)2021) ///
    graphregion(color(white))

* Optional: Add vertical lines for known events
* For reference points like WTO entry (1995), ASEAN FTA (2010), COVID (2020)
line tradeflow_baci_millions year, ///
    lcolor(blue) lwidth(medium) ///
    title("India’s Total Outbound Trade & Key Events") ///
    ytitle("Million USD") xtitle("Year") ///
    xline(1995 2010 2020, lpattern(dash) lcolor(red)) ///
    legend(off)

* Optional: Export graph
graph export "India_Trade_Trend.png", width(1000) replace
restore

* ---------------------------------------------------------------
* MISSING DATA DIAGNOSTICS
* Purpose: I want to understand which variables are missing, how many rows, 
*			and whether the missingness is systematic (by year or country).
* ---------------------------------------------------------------

* Check for completeness across essential gravity model variables
summarize tradeflow_baci gdp_d pop_d dist kl_diff landl_diff hc_diff
count if missing(tradeflow_baci, gdp_d, pop_d, dist, kl_diff, landl_diff, hc_diff)

* Explore the distribution of missing values across time
* - Is there an increase in recent years (e.g., 2021)?
* - Does early data suffer from poor coverage?
tab year if missing(tradeflow_baci, gdp_d, pop_d, dist, kl_diff, landl_diff, hc_diff)

* Explore which countries are contributing to missing values
* - Useful to know whether we’re losing strategic partners
tab iso3_d if missing(tradeflow_baci, gdp_d, pop_d, dist, kl_diff, landl_diff, hc_diff)

* ----------------------------------------
* VERDICT:
* ----------------------------------------
* (1) Trade and macroeconomic data are incomplete for some year-country pairs.
* (2) Missingness appears broadly distributed — not clustered by region or income group.
* (3) Therefore, I do not impute values (would introduce bias in structural gravity models).
* (4) Instead, we drop rows with missing core variables for robustness.

drop if missing(tradeflow_baci, gdp_d, pop_d, dist, kl_diff, landl_diff, hc_diff)

* ---------------------------------------------
* VARIABLE CREATION – India Gravity Dataset
* Purpose: Prepare transformed and policy-relevant variables
* Dataset: Already filtered to India as origin and 1995–2021
* ---------------------------------------------

* Dependent Variable: Log of trade flow (add 1 to avoid log(0) issues)
gen ln_trade = ln(tradeflow_baci + 1)

* Log transformations of core explanatory variables
gen ln_gdp_o = ln(gdp_o)
gen ln_gdp_d = ln(gdp_d)
gen ln_dist = ln(dist + 1)


* ----------------------------------------------------
* Preferential Trade Agreement (PTA) Dummies
* ----------------------------------------------------
* Purpose:
* These dummies mark country-year combinations where India had a formal PTA
* in effect with a given partner. They serve as treatment indicators in our model.
*
* Important:
* --> I am NOT limiting our analysis to just these countries.
* --> The dataset includes ALL of India's trading partners (1995–2021).
* --> These PTA dummies simply flag the countries that had trade agreements,
*     so we can estimate their effects relative to others.
*
* Think of them as "policy intervention" indicators in a full sample regression.
* These are going to be well referenced in the report, to show these historical
* event and how they happened.
* The key events in India versus other nations are:
*	- 1998 / 2000
*	- 2006
*	- 2009
*	- 2010
*	- 2010
*	- 2011
* ----------------------------------------------------

* India–Sri Lanka FTA (signed 1998, entered into force in 2000)
gen pta_srilanka = (iso3_d == "LKA") & year >= 2000

* India–ASEAN FTA (for goods trade, implemented 2010)
gen pta_asean = inlist(iso3_d, "IDN", "THA", "MYS", "PHL", "SGP", "VNM") & year >= 2010

* India–Japan CEPA (Comprehensive Economic Partnership Agreement, 2011)
gen pta_japan = (iso3_d == "JPN") & year >= 2011

* India–South Korea CEPA (implemented 2010)
gen pta_korea = (iso3_d == "KOR") & year >= 2010

* India–Bhutan trade agreement (reaffirmed in FTA-like framework in 2006)
gen pta_bhutan = (iso3_d == "BTN") & year >= 2006

* India–Nepal bilateral trade treaty (revamped 2009, active earlier)
gen pta_nepal = (iso3_d == "NPL") & year >= 2009

* Create a combined PTA indicator variable for India
* This will be used to estimate the average treatment effect of PTAs
gen pta_india = pta_srilanka | pta_asean | pta_japan | pta_korea | pta_bhutan | pta_nepal

* Interaction with factor differences
* The following will allow for this:
* Does PTA impact vary by structural factor distance?
gen pta_kl = pta_india * kl_diff
gen pta_landl = pta_india * landl_diff
gen pta_hc = pta_india * hc_diff


* ----------------------------------------------------
* OPTIONAL INTERACTION TERMS – For Robustness Analysis
* ----------------------------------------------------
* These interactions test whether the effects of PTAs depend on:
*   - Having a common official language (comlang_off)
*   - Shared WTO membership (wto_d)
*
* NOTE:
* These are not mandatory for baseline regressions, but will be 
* useful in advanced specifications, especially if you want to test 
* for institutional or structural modifiers of PTA impact.
* ----------------------------------------------------

* PTA X Common official language
gen pta_comlang = pta_india * comlang_off if !missing(comlang_off)

* PTA X WTO membership
gen pta_wto = pta_india * wto_d if !missing(wto_d)

* ----------------------------------------------------
* SANITY CHECKS AFTER VARIABLE CREATION
* ----------------------------------------------------

* Inspect summary stats for log-transformed continuous variables
summarize ln_trade ln_gdp_o ln_gdp_d ln_dist
* summary stats for factor variables
summarize kl_diff landl_diff hc_diff

* Check overall distribution of PTA dummies
tab pta_india

* List destination countries flagged under PTA arrangements
tab iso3_d if pta_india == 1, sort

* I check the distributions of interaction terms
tabstat pta_comlang pta_wto, stat(mean sd min max n)


* ------------------------------------------------------------------
* PHASE 2: DESCRIPTIVE ANALYSIS – India’s Bilateral Trade (1995–2021)
* Purpose:
* 	I do the following in this section:
*   	- Summarize the data and inspect key gravity variables
*   	- Compare trade patterns before/after PTAs
*   	- Reveal early patterns supporting the gravity model logic
* ------------------------------------------------------------------

* (2.1) Summary Statistics for Core Variables
* These help in essential for understanding scale,
* variation, and potential anomalies
summarize ln_trade ln_gdp_o ln_gdp_d ln_dist tradeflow_baci gdp_o gdp_d dist kl_diff landl_diff hc_diff

* Summary stats for policy variables and interactions
tabstat pta_india pta_comlang pta_wto, stat(mean sd min max n)

* Compare core variables by PTA status – shows how PTA partners differ
tabstat ln_trade ln_gdp_o ln_gdp_d ln_dist if pta_india==1, stat(mean sd min max n)
tabstat ln_trade ln_gdp_o ln_gdp_d ln_dist if pta_india==0, stat(mean sd min max n)
* compare factor differences by PTA status
tabstat kl_diff landl_diff hc_diff if pta_india == 1, stat(mean sd min max n)
tabstat kl_diff landl_diff hc_diff if pta_india == 0, stat(mean sd min max n)


* (2.2) India's Trade Trend Over Time (Aggregated)
* This gives a macro view of how India’s trade evolved between 1995 and 2021
preserve
collapse (sum) tradeflow_baci, by(year)
twoway (line tradeflow_baci year), ///
    title("India’s Total Trade with All Partners (1995–2021)") ///
    ytitle("Total Trade (USD)") xtitle("Year")
restore


* (2.3) Pre/Post PTA Comparison
* Test if trade flows are statistically different between PTA and non-PTA partners
mean ln_trade if pta_india == 1
mean ln_trade if pta_india == 0

* Run t-test to check significance
ttest ln_trade, by(pta_india)
* comparison of factor proportions across PTA vs. non-PTA.
ttest kl_diff, by(pta_india)

* Optional: visualize this comparison
graph box ln_trade, over(pta_india, label(labsize(medium))) ///
    title("Trade Flows: PTA vs. Non-PTA Partners") ///
    ytitle("Log Trade Flow")


* (2.4) Gravity Theory Diagnostics
* These visual checks confirm whether distance negatively correlates with trade
* and whether GDP of partners is positively related
twoway (scatter ln_trade ln_gdp_d), ///
    title("India’s Trade vs. Partner GDP (Logged)") ///
    xtitle("Log GDP of Destination") ytitle("Log Trade Flow")

twoway (scatter ln_trade ln_dist), ///
    title("India’s Trade vs. Distance (Logged)") ///
    xtitle("Log Distance") ytitle("Log Trade Flow")

* Ovelay of a lowess smoother to better see trends
twoway (scatter ln_trade ln_dist) (lowess ln_trade ln_dist), ///
    title("Trade vs. Distance with Lowess Fit")
	
*  tests whether factor distance has visual explanatory power
* — helpful before formal regression.
twoway (scatter ln_trade kl_diff), ///
    title("India’s Trade vs. Capital per Worker Difference") ///
    xtitle("Capital per Worker Diff (K/L)") ytitle("Log Trade Flow")


* (2.5) Top Trading Partners
* Frequency of non-zero trade relationships (intensive vs. extensive margin)
tab iso3_d if tradeflow_baci > 0, sort

* Aggregate total trade by partner to rank top destinations
preserve
collapse (sum) tradeflow_baci, by(iso3_d)
gsort -tradeflow_baci
list iso3_d tradeflow_baci in 1/10  // Top 10 partners
restore

*  top PTA countries by trade volume
preserve
keep if pta_india == 1
collapse (sum) tradeflow_baci, by(iso3_d)
gsort -tradeflow_baci
list iso3_d tradeflow_baci in 1/5  // Top PTA partners
restore


* ---------------------------------------------------------------
* Summary:
*   This descriptive phase provides a foundation for the regression strategy:
*   - Confirms skew in trade -> justifies log transformation
*   - Shows trade has grown over time
*   - Indicates that PTA partners may have higher trade on average
*   - Highlights the intuitive roles of GDP and distance
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* PHASE 3: MODEL ESTIMATION – Structural Gravity Models

* Objective: I estimate the effects of economic size, distance, factor endowments, 
*            and preferential trade agreements (PTAs) on India's bilateral trade
* ---------------------------------------------------------------

* PREPARATION: Create unique dyad identifier for panel regressions
* India is the only origin (iso3_o == "IND"), so I use iso3_d to define dyads
egen dyadid = group(iso3_d)

* Declare panel structure: dyads over time
xtset dyadid year


* (3.1) Baseline Pooled OLS Model
* No fixed effects. Useful as a reference model.
* Clustered standard errors by destination country.
reg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, vce(cluster iso3_d)

* Include year fixed effects to capture global time shocks
reg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india i.year, vce(cluster iso3_d)


* (3.2) Fixed Effects Model (Preferred Specification)
* ----------
* LAGGED DEPENDENT VARIABLE – Dynamic Gravity
* ----------
* Create lagged trade (panel-aware)
gen L1_ln_trade = .
sort dyadid year
by dyadid: replace L1_ln_trade = ln_trade[_n-1]
* FE model with lagged DV
xtreg ln_trade L1_ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india i.year, fe vce(cluster iso3_d)

* ----------
* Controls for time-invariant partner-specific unobserved factors
* Removes bias from omitted variables like historical/political ties
* ----------
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, fe vce(cluster iso3_d)

* Add year fixed effects to capture macro shocks (e.g., global crises)
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india i.year, fe vce(cluster iso3_d)

* -----------
* AGREEMENT-SPECIFIC FIXED EFFECT REGRESSIONS
* -----------
* ASEAN
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_asean i.year, fe vce(cluster iso3_d)
* Japan
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_japan i.year, fe vce(cluster iso3_d)
* Korea
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_korea i.year, fe vce(cluster iso3_d)
* Sri Lanka
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_srilanka i.year, fe vce(cluster iso3_d)
* Nepal
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_nepal i.year, fe vce(cluster iso3_d)
* Bhutan
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_bhutan i.year, fe vce(cluster iso3_d)
* Alternatively, include all PTA dummies together:
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan ///
    i.year, fe vce(cluster iso3_d)

* Compare PTA impacts across agreements
eststo clear
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_asean i.year, fe vce(cluster iso3_d)
eststo asean
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_japan i.year, fe vce(cluster iso3_d)
eststo japan
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_korea i.year, fe vce(cluster iso3_d)
eststo korea

coefplot asean japan korea, ///
    keep(pta_*) ///
    label("ASEAN" "Japan" "Korea") ///
    title("Comparative PTA Effects") ///
    xline(0)


* (3.3) Random Effects Model (For Comparison)
* Assumes unobserved effects are uncorrelated with regressors
* More efficient if assumption holds
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, re vce(cluster iso3_d)


* (3.4) Hausman Test – Fixed Effects vs Random Effects
* Purpose: To test whether RE is a consistent estimator.
* Note: Hausman test cannot be used with clustered or robust SEs.
* Therefore, I temporarily re-run FE and RE models without vce(cluster ...)

* Run FE model without clustering (only for Hausman)
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, fe
estimates store fe

* Run RE model without clustering (only for Hausman)
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, re
estimates store re

* Perform Hausman test
hausman fe re, sigmamore

*********************************************************************
* === Interpretation Guidance ===
* - If p < 0.05 -> reject RE -> use FE model (RE is inconsistent)
* - If p >= 0.05 -> fail to reject RE -> RE is consistent and may be preferred
*********************************************************************


* ------------------------------------------------------------
* OPTIONAL: I ADD Interaction Terms for Robustness
* ------------------------------------------------------------
* Test if PTA impact depends on shared institutions or characteristics
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff i.wto_d##i.pta_india, fe vce(cluster iso3_d)
* Visualizing Marginal Effect of PTA by WTO Membership
margins pta_india, at(wto_d=(0 1))
marginsplot, title("PTA Effect by WTO Status") ///
    ylabel(, angle(horizontal)) ///
    ytitle("Predicted Log Trade")

* Visualize PTA x GDP interaction
margins, at(ln_gdp_d=(22(1)30)) over(pta_india)
marginsplot, title("PTA Impact Across Partner GDP Levels") ///
    xtitle("Log GDP of Destination") ytitle("Predicted Log Trade")

	
* Interaction with distance (moderation effect)
gen pta_ln_dist = pta_india * ln_dist
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_ln_dist, fe vce(cluster iso3_d)


* ---------------------------------------------------------------
* PHASE 4: ROBUSTNESS AND EXTENSIONS
* Purpose: To confirm that the core findings hold across alternative specifications,
*          dependent variables, interaction effects, and partner characteristics.
* ---------------------------------------------------------------
* (4.1) ALTERNATIVE DEPENDENT VARIABLES
* Purpose: Test if results are consistent across different measures of trade

* (a) IMF-based trade flow
* Uses IMF data source as robustness check for BACI-based flows
* Note: This variable already exists in the dataset

gen ln_trade_imf = ln(tradeflow_imf_o + 1)
xtreg ln_trade_imf ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, fe vce(cluster iso3_d)

* (b) Manufacturing-only trade flow (sectoral)
* Tests whether PTA effects are stronger in specific sectors

gen ln_manuf_trade = ln(manuf_tradeflow_baci + 1)
xtreg ln_manuf_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, fe vce(cluster iso3_d)


* (4.2) LAGGED EFFECTS OF PREFERENTIAL TRADE AGREEMENTS
* Purpose: Test if PTA impacts take time to materialize

* Lag PTA dummy for Japan agreement as an example
sort iso3_d year
by iso3_d: gen pta_japan_lag = pta_japan[_n-1]

xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
      pta_japan pta_japan_lag, fe vce(cluster iso3_d)


* (4.3) HETEROGENEOUS EFFECTS (INTERACTIONS)
* Purpose: Explore whether PTA effects differ by structural/institutional factors

* (a) PTA effect moderated by partner GDP (economic size)
gen pta_gdp = pta_india * ln_gdp_d
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
      pta_india pta_gdp, fe vce(cluster iso3_d)

* (b) PTA effect moderated by WTO membership
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
      pta_india pta_wto, fe vce(cluster iso3_d)

* (c) PTA effect moderated by shared official language
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
      pta_india pta_comlang, fe vce(cluster iso3_d)

* (d) PTA effect moderated by distance
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
      pta_india pta_ln_dist, fe vce(cluster iso3_d)


* (4.4) QUANTILE REGRESSION (DISTRIBUTIONAL ROBUSTNESS)
* Purpose: Check if PTA effects vary across trade intensity levels

* (a) Median regression
qreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, quantile(0.5)

* (b) 25th percentile
qreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, quantile(0.25)

* (c) 75th percentile
qreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, quantile(0.75)


* (4.5) PPML ESTIMATION – Robust to Heteroskedasticity
* Use Poisson Pseudo-Maximum Likelihood estimator with fixed effects

ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, ///
    absorb(iso3_d year) vce(cluster iso3_d)

* Agreement-specific PTA effects using PPML
ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan, ///
    absorb(iso3_d year) vce(cluster iso3_d)

* Plotting PPML estimates
eststo clear
ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, absorb(iso3_d year) vce(cluster iso3_d)
eststo ppml_model

coefplot ppml_model, drop(_cons) ///
    title("Coefficient Plot – PPML Estimates") ///
    yline(0, lpattern(dash)) ///
    xline(0, lpattern(dash))


* (4.6) PLACEBO TEST – False PTA Dummy
* Purpose: Check if PTA effects are falsely detected in unrelated countries

gen pta_placebo = (iso3_d == "FRA" | iso3_d == "MEX") & year >= 2008

xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_placebo i.year, fe vce(cluster iso3_d)

* =====================================================
* PHASE 5: EXPORT KEY RESULTS – PUBLICATION-STYLE OUTPUT
* Purpose: Generate export-ready regression tables and descriptive outputs
* =====================================================

* Set working directory
* Change it different from mine for re-use.
cd "C:\Users\Administrator\Desktop\WORK\Assignments\ONES\Stata Thesis"


* === SUMMARY STATISTICS ===
* Log structure and variable type check
log using variable_types.log, replace
describe ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_comlang pta_wto ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan ///
    pta_japan_lag pta_ln_dist pta_gdp ln_trade_imf ln_manuf_trade tradeflow_baci ///
    kl_diff landl_diff hc_diff
log close

* Ensure numeric format for variables if needed
foreach var in ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_comlang pta_wto ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan ///
    pta_japan_lag pta_ln_dist pta_gdp ln_trade_imf ln_manuf_trade tradeflow_baci ///
    kl_diff landl_diff hc_diff {
    capture confirm numeric variable `var'
    if _rc {
        destring `var', replace force
    }
}

* Summary statistics for core variables
asdoc tabstat ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_comlang pta_wto kl_diff landl_diff hc_diff if !missing(ln_trade), ///
    stat(mean sd min max n) columns(statistics) ///
    save(gravity_results.doc), replace title(Summary Statistics of Key Variables)

* Compare PTA vs. non-PTA partner statistics
asdoc tabstat ln_trade ln_gdp_o ln_gdp_d ln_dist if pta_india == 1, ///
    stat(mean sd min max n) columns(statistics), ///
    append title(Summary Statistics: PTA Partners)
asdoc tabstat ln_trade ln_gdp_o ln_gdp_d ln_dist if pta_india == 0, ///
    stat(mean sd min max n) columns(statistics), ///
    append title(Summary Statistics: Non-PTA Partners)


* === AGGREGATED TABLE OF MAIN RESULTS ===
* Store estimation results
eststo clear
eststo fe_main: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india i.year, fe vce(cluster iso3_d)
eststo re_main: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india i.year, re vce(cluster iso3_d)
eststo pta_combined: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan i.year, fe vce(cluster iso3_d)
eststo ppml_main: ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, absorb(iso3_d year) vce(cluster iso3_d)
eststo int_wto: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_wto, fe vce(cluster iso3_d)
eststo int_comlang: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_comlang, fe vce(cluster iso3_d)
eststo int_dist: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_ln_dist, fe vce(cluster iso3_d)
eststo int_gdp: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_gdp, fe vce(cluster iso3_d)
eststo lag_japan: xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_japan pta_japan_lag, fe vce(cluster iso3_d)
eststo qreg_25: qreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, quantile(0.25)
eststo qreg_50: qreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, quantile(0.5)
eststo qreg_75: qreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, quantile(0.75)

* Output tables
asdoc esttab fe_main re_main pta_combined, cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) stats(r2 N, fmt(3 0)) ///
    title(Aggregated Gravity Models with PTA) append

asdoc esttab int_wto int_comlang int_dist int_gdp lag_japan, cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) stats(r2 N, fmt(3 0)) ///
    title(Interactions and Lagged PTA Effects) append

asdoc esttab qreg_25 qreg_50 qreg_75, cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) stats(r2 N, fmt(3 0)) ///
    title(Quantile Regressions at Key Percentiles) append

* Export key models separately with titles
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india i.year, fe vce(cluster iso3_d), ///
    append title(Main Fixed Effects Model)
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india i.year, re vce(cluster iso3_d), ///
    append title(Random Effects Model)

* Agreement-specific regressions
foreach pta in asean japan korea srilanka nepal bhutan {
    asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_`pta' i.year, fe vce(cluster iso3_d), ///
        append title(PTA Agreement Effect - `pta')
}

* Lagged PTA
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_japan pta_japan_lag, fe vce(cluster iso3_d), ///
    append title(Lagged Effect - Japan Agreement)

* Interaction terms
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_wto, fe vce(cluster iso3_d), append title(PTA × WTO)
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_comlang, fe vce(cluster iso3_d), append title(PTA × Common Language)
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_ln_dist, fe vce(cluster iso3_d), append title(PTA × Distance)
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india pta_gdp, fe vce(cluster iso3_d), append title(PTA × GDP)

* Robustness: Alternative DVs
asdoc xtreg ln_trade_imf ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, fe vce(cluster iso3_d), append title(IMF-Based Trade)
asdoc xtreg ln_manuf_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, fe vce(cluster iso3_d), append title(Manufacturing Trade Only)

* PPML estimation
asdoc ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_india, absorb(iso3_d year) vce(cluster iso3_d), append title(PPML Model - Main)
asdoc ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan, ///
    absorb(iso3_d year) vce(cluster iso3_d), append title(PPML - PTA Specific)

* Placebo regression
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist kl_diff landl_diff hc_diff pta_placebo i.year, fe vce(cluster iso3_d), ///
    append title(Placebo Test - False PTA)

