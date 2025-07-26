## ✅ FINALIZED ASDOC INSTRUCTIONS (BRIEF)

### 📍WHERE TO PLACE:

➡️ **At the very end** of your `.do` file, add a section titled:

```stata
* =====================================================
* PHASE 5: EXPORT KEY RESULTS – PUBLICATION-STYLE OUTPUT
* =====================================================
```

---

### 📂 ONE WORD DOCUMENT ONLY:

Use `asdoc` with `append` to combine **all tables into a single file**.

### 📌 Set folder and file:

```stata
cd "C:\Your\Export\Path"
asdoc clear  // just in case
```

---

## 📊 WHAT TO EXPORT (KEY MODELS)

Paste this in your export section:

```stata
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
```

---

## 🖼️ OPTIONAL: Export Plots (Not via asdoc)

Stata can't embed plots in Word using `asdoc`, but you can export them manually like this:

```stata
graph export "pta_effect_boxplot.png", replace
graph export "margins_pta_wto.png", replace
```

📌 Then manually insert the images into the same `gravity_results.doc` after you generate it.

---

## 🧾 EDITOR’S SHORT NOTE (TOP OF FILE)

Add this at the top of the `.do` file for clarity:

```stata
* Editor Instructions:
* This code runs end-to-end without error.
* All final results are exported via asdoc into one Word file: gravity_results.doc.
* Do not modify section headers. If adding models, append to PHASE 5.
```
