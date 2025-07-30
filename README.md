## Summary of the Empirical Analysis

This study investigates the impact of India's Preferential Trade Agreements (PTAs) on its bilateral trade flows over the period 1995–2021, using a structural gravity model framework. The analysis progresses systematically through several phases, each designed to build a robust empirical foundation and explore the consistency and nuance of PTA effects on trade.

---

### Phase 1: Data Preparation

Before modeling, the dataset was extensively cleaned and structured to fit the requirements of panel data analysis. Key transformations included the generation of logged variables such as trade flows, GDP, and distance. Dummy variables representing India’s PTAs with specific partner countries—ASEAN, Japan, Korea, Sri Lanka, Nepal, and Bhutan—were constructed, along with institutional and structural controls like WTO membership, common language, and proxies for factor endowments (capital-labor ratio, land-labor ratio, and human capital). All identifiers were standardized and missing values handled to avoid estimation bias.

---

### Phase 2: Descriptive Statistics

Descriptive analyses laid the groundwork for model estimation. Summary statistics showed substantial variation in trade volumes across PTA and non-PTA partners. On average, PTA countries exhibited higher trade values, larger economic size, and slightly shorter distances from India—aligning well with gravity model expectations. Time-series plots confirmed that India’s total trade volume has expanded over time, and simple visual diagnostics indicated positive associations between trade and GDP, and a negative correlation between trade and distance.

---

### Phase 3: Structural Gravity Model Estimation

#### Baseline Regressions:

Initial pooled OLS and fixed effects (FE) regressions assessed the influence of core gravity variables and PTAs. The results confirmed that GDP positively drives trade, while distance has a dampening effect. India's PTAs were consistently associated with higher trade flows.

#### Dynamic Specification:

A lagged dependent variable was introduced to capture persistence in trade relationships, and the findings held under this dynamic framework—validating the robustness of the PTA effect.

#### Agreement-Specific Effects:

Separate regressions for each PTA revealed varying magnitudes of impact, with the ASEAN and Japan agreements showing particularly strong associations with trade increases. A comparative plot using `coefplot` helped visualize these differences clearly.

#### Hausman Test:

To determine whether fixed or random effects were more appropriate, the Hausman test was conducted. Results rejected the random effects model in favor of fixed effects, justifying the use of FE in subsequent analysis.

---

### Phase 4: Robustness and Extensions

This phase tested the resilience of findings across various model specifications.

#### Alternative Dependent Variables:

Using alternative trade measures (IMF-based data and manufacturing-only trade), the PTA coefficients remained positive and statistically significant—bolstering the core conclusions.

#### Lagged Effects:

The impact of PTAs was also tested with one-period lags (e.g., for Japan). These lagged terms were also significant, suggesting that trade responses may materialize with delay.

#### Heterogeneous Effects:

Interaction terms revealed that PTA effects were amplified when partners were WTO members or had larger economies. Shared language and geographic proximity also strengthened PTA-related trade gains.

#### Quantile Regression:

Quantile regressions showed that PTA effects are more pronounced among partners with higher trade volumes, implying that PTAs are especially impactful where trade is already intensive.

#### PPML Estimation:

Given concerns over heteroskedasticity, Poisson Pseudo Maximum Likelihood (PPML) models were estimated. These reaffirmed the positive and significant influence of PTAs, including under agreement-specific specifications. A coefficient plot visually confirmed the consistency of results.

#### Placebo Test:

To verify that results were not spurious, a placebo PTA variable was created for countries without any real PTA with India (France and Mexico). The lack of a significant effect supported the credibility of the earlier findings.

---

### Phase 5: Output and Presentation

All results were exported in publication-ready format using `asdoc` and `esttab`. Tables included:

* Summary statistics for PTA vs. non-PTA partners
* Main model estimates (FE, RE, and dynamic)
* Agreement-specific effects
* Robustness checks (alternative dependent variables, lagged effects)
* Interaction models
* Quantile regressions
* PPML estimations
* Placebo tests

This organized output provides a coherent and rigorous empirical base for further interpretation and policy discussion.

---

### Conclusion

Overall, the evidence from multiple estimation strategies supports the conclusion that India's PTAs have had a positive and statistically significant effect on its bilateral trade. These effects are not uniform—some agreements appear more impactful than others—and they interact with structural characteristics like economic size, institutional ties, and trade intensity. The layered approach taken in this analysis helps mitigate common econometric concerns and lends confidence to the results, making them suitable for academic publication and policy consideration.
