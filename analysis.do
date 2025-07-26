* Editor Instructions:
* This code runs end-to-end without error.
* All final results are exported via asdoc into one Word file: gravity_results.doc.
* Do not modify section headers. If adding models, append to PHASE 5.
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
*
* =============================================================================

clear
cls

* ---------------------------------------------------------------
* INITIAL EXPLORATION
* Purpose: Understand how the data is, before any other analysis.
* ---------------------------------------------------------------

* (1) Load and filter dataset
* - I am only interested in India as the origin country (iso3_o == "IND")
* - I restrict the period to 1995–2021 for contemporary relevance

* NOTE: Please change this to gravity_model.dta path
use "C:\Users\Administrator\Desktop\WORK\Assignments\ONES\Stata Thesis\gravity_model.dta", clear
keep if iso3_o == "IND"
keep if year >= 1995 & year <= 2021

* (2) Inspect the dataset structure and spot missingness
* - describe: metadata (var names, types, labels)
* - misstable summarize: good first check for NAs and completeness
describe
misstable summarize

* (3) Summary statistics of core economic and geographic variables
* These are the basis of the gravity model, so I need to know:
* - whether values are realistic (range, scale)
* - whether any are highly skewed or prone to transformation
summarize tradeflow_baci gdp_o gdp_d dist pop_o pop_d

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

* (7) Visualize India’s total outbound trade trend (1995–2021)
* - Sum trade values for each year (across all partners)
* - Plot trend to detect shocks, breakpoints (e.g., global financial crisis, COVID)
bysort year (iso3_d): gen one = 1  // dummy to enable collapse safely
preserve
collapse (sum) tradeflow_baci, by(year)
twoway (line tradeflow_baci year), title("India’s Total Trade Over Time")
restore

* ---------------------------------------------------------------
* MISSING DATA DIAGNOSTICS
* Purpose: I want to understand which variables are missing, how many rows, 
*			and whether the missingness is systematic (by year or country).
* ---------------------------------------------------------------

* Check for completeness across essential gravity model variables
summarize tradeflow_baci gdp_d pop_d dist
count if missing(tradeflow_baci, gdp_d, pop_d, dist)

* Explore the distribution of missing values across time
* - Is there an increase in recent years (e.g., 2021)?
* - Does early data suffer from poor coverage?
tab year if missing(tradeflow_baci, gdp_d, pop_d, dist)

* Explore which countries are contributing to missing values
* - Useful to know whether we’re losing strategic partners
tab iso3_d if missing(tradeflow_baci, gdp_d, pop_d, dist)

* ----------------------------------------
* VERDICT:
* ----------------------------------------
* (1) Trade and macroeconomic data are incomplete for some year-country pairs.
* (2) Missingness appears broadly distributed — not clustered by region or income group.
* (3) Therefore, I do not impute values (would introduce bias in structural gravity models).
* (4) Instead, we drop rows with missing core variables for robustness.

drop if missing(tradeflow_baci, gdp_d, pop_d, dist)


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

* Check overall distribution of PTA dummies
tab pta_india

* List destination countries flagged under PTA arrangements
tab iso3_d if pta_india == 1, sort

* If needed later, I can check the distributions of interaction terms
* uncommenting the below:
* tabstat pta_comlang pta_wto, stat(mean sd min max n)



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
summarize ln_trade ln_gdp_o ln_gdp_d ln_dist tradeflow_baci gdp_o gdp_d dist

* Summary stats for policy variables and interactions
tabstat pta_india pta_comlang pta_wto, stat(mean sd min max n)

* Compare core variables by PTA status – shows how PTA partners differ
tabstat ln_trade ln_gdp_o ln_gdp_d ln_dist if pta_india==1, stat(mean sd min max n)
tabstat ln_trade ln_gdp_o ln_gdp_d ln_dist if pta_india==0, stat(mean sd min max n)


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


* (2.5) Top Trading Partners
* Frequency of non-zero trade relationships (intensive vs. extensive margin)
tab iso3_d if tradeflow_baci > 0, sort

* Aggregate total trade by partner to rank top destinations
preserve
collapse (sum) tradeflow_baci, by(iso3_d)
gsort -tradeflow_baci
list iso3_d tradeflow_baci in 1/10  // Top 10 partners
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

* Objective: I estimate the effects of economic size, distance, and
*            preferential trade agreements (PTAs) on India's bilateral trade
* ---------------------------------------------------------------

* PREPARATION: Create unique dyad identifier for panel regressions
* India is the only origin (iso3_o == "IND"), so I use iso3_d to define dyads
egen dyadid = group(iso3_d)

* Declare panel structure: dyads over time
xtset dyadid year



* (3.1) Baseline Pooled OLS Model
* No fixed effects. Useful as a reference model.
* Clustered standard errors by destination country.
reg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, vce(cluster iso3_d)

* Include year fixed effects to capture global time shocks
reg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india i.year, vce(cluster iso3_d)



* (3.2) Fixed Effects Model (Preferred Specification)

* ----------
* LAGGED DEPENDENT VARIABLE – Dynamic Gravity
* ----------

* Create lagged trade (panel-aware)
gen L1_ln_trade = .
sort dyadid year
by dyadid: replace L1_ln_trade = ln_trade[_n-1]
* FE model with lagged DV
xtreg ln_trade L1_ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india i.year, fe vce(cluster iso3_d)

* ----------
* Controls for time-invariant partner-specific unobserved factors
* Removes bias from omitted variables like historical/political ties
* ----------
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, fe vce(cluster iso3_d)

* Add year fixed effects to capture macro shocks (e.g., global crises)
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india i.year, fe vce(cluster iso3_d)

* -----------
* AGREEMENT-SPECIFIC FIXED EFFECT REGRESSIONS
* -----------
* ASEAN
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_asean i.year, fe vce(cluster iso3_d)
* Japan
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_japan i.year, fe vce(cluster iso3_d)
* Korea
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_korea i.year, fe vce(cluster iso3_d)
* Sri Lanka
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_srilanka i.year, fe vce(cluster iso3_d)
* Nepal
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_nepal i.year, fe vce(cluster iso3_d)
* Bhutan
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_bhutan i.year, fe vce(cluster iso3_d)
* Alternatively, include all PTA dummies together:
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan ///
    i.year, fe vce(cluster iso3_d)

* Compare PTA impacts across agreements
eststo clear
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_asean i.year, fe vce(cluster iso3_d)
eststo asean
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_japan i.year, fe vce(cluster iso3_d)
eststo japan
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_korea i.year, fe vce(cluster iso3_d)
eststo korea

coefplot asean japan korea, ///
    keep(pta_*) ///
    label("ASEAN" "Japan" "Korea") ///
    title("Comparative PTA Effects") ///
    xline(0)


	
* (3.3) Random Effects Model (For Comparison)
* Assumes unobserved effects are uncorrelated with regressors
* More efficient if assumption holds
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, re vce(cluster iso3_d)


* (3.4) Hausman Test – Fixed Effects vs Random Effects
* Purpose: To test whether RE is a consistent estimator.
* Note: Hausman test cannot be used with clustered or robust SEs.
* Therefore, temporarily re-run FE and RE models without vce(cluster ...)

* Run FE model without clustering (only for Hausman)
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, fe
estimates store fe

* Run RE model without clustering (only for Hausman)
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, re
estimates store re

* Perform Hausman test
hausman fe re, sigmamore

*********************************************************************
* === Interpretation Guidance ===
* - If p < 0.05 -> reject RE -> use FE model (RE is inconsistent)
* - If p >= 0.05 -> fail to reject RE -> RE is consistent and may be preferred
*
* Important:
* Return to using FE and RE models with clustered SEs (vce(cluster iso3_d))
* for final reporting, as clustering accounts for within-group correlation.
*********************************************************************


* (3.5) Export vs Import Models (Optional – Only if disaggregated)
* If there are variables splitting trade direction, e.g.:
* gen ln_exports = ln_trade if direction == "EXP"
* gen ln_imports = ln_trade if direction == "IMP"
* Then estimate FE models for each:
* xtreg ln_exports ln_gdp_o ln_gdp_d ln_dist pta_india, fe vce(cluster iso3_d)
* xtreg ln_imports ln_gdp_o ln_gdp_d ln_dist pta_india, fe vce(cluster iso3_d)

* Note: Only if disaggregated direction data is available.

* ------------------------------------------------------------
* OPTIONAL: I ADD Interaction Terms for Robustness
* ------------------------------------------------------------
* Test if PTA impact depends on shared institutions or characteristics
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_comlang pta_wto, fe vce(cluster iso3_d)
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
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_ln_dist, fe vce(cluster iso3_d)



* ---------------------------------------------------------------
* PHASE 4: ROBUSTNESS AND EXTENSIONS
* Purpose: To confirm that the core findings hold across alternative specifications,
*          dependent variables, interaction effects, and partner characteristics.
* ---------------------------------------------------------------

* (4.1) ALTERNATIVE DEPENDENT VARIABLES
* Purpose: Test if results are consistent across different measures of trade

* (a) IMF-based trade flow
gen ln_trade_imf = ln(tradeflow_imf_o + 1)
xtreg ln_trade_imf ln_gdp_o ln_gdp_d ln_dist pta_india, fe vce(cluster iso3_d)

* (b) Manufacturing-only trade flow (from BACI sectoral data)
gen ln_manuf_trade = ln(manuf_tradeflow_baci + 1)
xtreg ln_manuf_trade ln_gdp_o ln_gdp_d ln_dist pta_india, fe vce(cluster iso3_d)



* (4.2) LAGGED EFFECTS OF PREFERENTIAL TRADE AGREEMENTS
* Purpose: Test if PTAs take time before influencing trade

* Lag PTA dummy for Japan agreement as an example (can be done for others)
gen pta_japan_lag = .
sort iso3_d year
by iso3_d: replace pta_japan_lag = pta_japan[_n-1]

* Estimate model with contemporaneous and lagged PTA effects
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_japan pta_japan_lag, fe vce(cluster iso3_d)


* (4.3) HETEROGENEOUS EFFECTS (INTERACTIONS)
* Purpose: Explore whether PTA effects differ by structural/institutional factors

* (a) PTA effect moderated by economic size (partner GDP)
gen pta_gdp = pta_india * ln_gdp_d
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_gdp, fe vce(cluster iso3_d)

* (b) PTA effect moderated by WTO membership
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_wto, fe vce(cluster iso3_d)

* (c) PTA effect moderated by shared official language
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_comlang, fe vce(cluster iso3_d)

* (d) PTA effect moderated by distance (nonlinear moderator)
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_ln_dist, fe vce(cluster iso3_d)


* (4.4) QUANTILE REGRESSION (DISTRIBUTIONAL ROBUSTNESS)
* Purpose: Test if PTA effects vary across levels of trade intensity
* NOTE: Panel quantile regression is advanced. I run pooled quantile regression here.
* This helps check if PTA effects differ for low vs. high trade partners.
* (a) Median regression (50th percentile)
qreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, quantile(0.5)

* (b) 25th percentile (lower trade flows)
qreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, quantile(0.25)

* (c) 75th percentile (high trade flows)
qreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india, quantile(0.75)

* ---------
* PPML ESTIMATION – Robust to Heteroskedasticity
* ----------
* PPML with dyad and year fixed effects (absorbed)
* ssc install ftools
ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist pta_india, ///
    absorb(iso3_d year) vce(cluster iso3_d)

* Agreement-specific PPML
ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist ///
    pta_asean pta_japan pta_korea pta_srilanka pta_nepal pta_bhutan, ///
    absorb(iso3_d year) vce(cluster iso3_d)

* Plotting PPML coefficients
eststo clear
ppmlhdfe tradeflow_baci ln_gdp_o ln_gdp_d ln_dist pta_india, absorb(iso3_d year) vce(cluster iso3_d)
eststo ppml_model

coefplot ppml_model, drop(_cons) ///
    title("Coefficient Plot – PPML Estimates") ///
    yline(0, lpattern(dash)) ///
    xline(0, lpattern(dash))

	
* -----------
* PLACEBO TEST – False PTA Dummy
* -----------

* Create placebo PTA (e.g., assign PTA to non-agreement countries)
gen pta_placebo = (iso3_d == "FRA" | iso3_d == "MEX") & year >= 2008

* Run placebo regression
xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_placebo i.year, fe vce(cluster iso3_d)

* =====================================================
* PHASE 5: EXPORT KEY RESULTS – PUBLICATION-STYLE OUTPUT
* =====================================================

cd "C:\\Your\\Export\\Path"
asdoc clear  // just in case

* === MAIN FIXED EFFECTS MODEL ===
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india i.year, fe vce(cluster iso3_d) ///
    save("gravity_results.doc"), replace title("Main FE Model – PTA Impact")

* === RANDOM EFFECTS MODEL ===
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india i.year, re vce(cluster iso3_d), ///
    append title("Random Effects Model – Comparison")

* === AGREEMENT-SPECIFIC EFFECTS ===
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_asean i.year, fe vce(cluster iso3_d), ///
    append title("ASEAN Agreement")
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_japan i.year, fe vce(cluster iso3_d), ///
    append title("Japan Agreement")
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_korea i.year, fe vce(cluster iso3_d), ///
    append title("Korea Agreement")

* === ROBUSTNESS: LAG EFFECT ===
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_japan pta_japan_lag, fe vce(cluster iso3_d), ///
    append title("Lagged Effect – Japan Agreement")

* === INTERACTION EFFECTS ===
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_wto, fe vce(cluster iso3_d), ///
    append title("PTA × WTO Membership Interaction")
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_india pta_comlang, fe vce(cluster iso3_d), ///
    append title("PTA × Common Language Interaction")

* === PLACEBO TEST ===
asdoc xtreg ln_trade ln_gdp_o ln_gdp_d ln_dist pta_placebo i.year, fe vce(cluster iso3_d), ///
    append title("Placebo Regression – False PTA")
