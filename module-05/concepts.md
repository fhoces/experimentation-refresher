# Module 5: Analyzing Experiments

## Quick Refresher

You know the basics from Angrist & Pischke Chapters 2-4, Lin (2013), and
Deng et al. (2013, "CUPED"). Here's the fast version with emphasis on
practical analysis decisions.

### Difference in Means: The Starting Point

In a randomized experiment, the simplest estimator is the difference in
sample means:

$$\hat{\tau} = \bar{Y}_T - \bar{Y}_C$$

This is unbiased for the ATE by randomization. It's equivalent to OLS
regression of $Y$ on treatment indicator $D$:

$$Y_i = \alpha + \tau D_i + \varepsilon_i$$

The coefficient $\hat{\tau}$ is literally the difference in means.

### Covariate Adjustment: Reducing Variance

Adding pre-treatment covariates to the regression reduces residual variance:

$$Y_i = \alpha + \tau D_i + \beta X_i + \varepsilon_i$$

This does NOT change the unbiasedness of $\hat{\tau}$ (because $X$ is
pre-treatment and independent of $D$ by randomization), but it reduces the
standard error.

**Variance reduction** = $1 - (1 - R^2_X)$, where $R^2_X$ is the
fraction of outcome variance explained by the covariate.

### Lin (2013): Covariate Adjustment Done Right

The simple covariate-adjusted regression above imposes that the
relationship between $X$ and $Y$ is the same in treatment and control. If
effects are heterogeneous, this can introduce small bias.

Lin's estimator interacts the demeaned covariate with treatment:

$$Y_i = \alpha + \tau D_i + \beta_0 (X_i - \bar{X}) + \beta_1 D_i(X_i - \bar{X}) + \varepsilon_i$$

Properties:
- Always at least as precise as difference in means
- Consistent for ATE regardless of functional form
- Use with HC2 standard errors for valid inference

### CUPED (Controlled-experiment Using Pre-Experiment Data)

CUPED constructs a variance-reduced outcome:

$$\tilde{Y}_i = Y_i - \theta(X_i - \bar{X})$$

where $\theta = \text{Cov}(Y, X) / \text{Var}(X)$.

Then estimate the ATE as $\bar{\tilde{Y}}_T - \bar{\tilde{Y}}_C$.

**Key insight:** CUPED is mathematically equivalent to regression
adjustment. The optimal $\theta$ is the OLS slope. The variance reduction
equals $\text{Corr}(Y, X)^2$.

**Why use CUPED framing?**
- Easy to implement in production metric pipelines
- Transform the metric once, then compute simple means
- Separates the variance-reduction step from the inference step
- Widely understood at tech companies (Microsoft, Netflix, Uber)

### Stratification and Post-Stratification

**Stratified randomization:** Randomize within blocks defined by covariates.
Guarantees exact balance on stratification variables.

**Post-stratification:** Include stratum fixed effects in the regression,
even if randomization wasn't stratified. This is free variance reduction.

$$Y_i = \alpha + \tau D_i + \sum_s \gamma_s \cdot \mathbb{1}[S_i = s] + \varepsilon_i$$

Always include randomization strata as fixed effects in the analysis.

### Robust Standard Errors

Standard OLS assumes homoskedasticity. In experiments:

- **HC2 standard errors** are recommended (Imbens & Kolesar, 2016). They
  correct for heteroskedasticity without being overly conservative.
- **Cluster-robust SEs:** When randomization is at the cluster level,
  cluster standard errors at the level of randomization.
- **Rule:** always cluster at the level of randomization or higher.

### ITT vs LATE

When there is non-compliance (not everyone assigned to treatment takes it):

**ITT** (Intent-to-Treat) = effect of *assignment*:
$$\text{ITT} = E[Y | Z=1] - E[Y | Z=0]$$
Always identified by randomization. This is the policy-relevant effect.

**LATE** (Local Average Treatment Effect) = effect on compliers:
$$\text{LATE} = \frac{\text{ITT}}{\text{compliance rate}} = \frac{E[Y|Z=1] - E[Y|Z=0]}{E[D|Z=1] - E[D|Z=0]}$$

Requires IV assumptions: relevance, independence, exclusion restriction,
monotonicity.

**Never** regress $Y$ on actual take-up $D$ -- compliance is endogenous.
Use assignment $Z$ as an instrument.

### Pre-Analysis Plans

A pre-analysis plan (PAP) specifies before data collection:
1. Primary outcomes and construction rules
2. Estimating equations (DiD, cross-sectional, etc.)
3. Standard error specification (robust, clustered)
4. Multiple testing corrections
5. Subgroup analyses (confirmatory vs. exploratory)
6. Rules for handling deviations

PAPs prevent specification searching and p-hacking. They distinguish
pre-specified (confirmatory) from data-driven (exploratory) results.

### What Tech Companies Care About

- Can you implement CUPED and explain why it works?
- Do you know when to use ITT vs LATE?
- Can you set up proper standard errors for a clustered design?
- Do you understand why naively regressing on compliance is wrong?
- Can you explain the difference between pre-specified and post-hoc analysis?
