# Module 4: Power and Sample Size

## Quick Refresher

You know the basics from Imbens & Rubin Chapter 5 and Duflo, Glennerster &
Kremer (2007). Here's the fast version with emphasis on what comes up in
experiment design and tech interviews.

### What Is Power?

**Power** = $P(\text{reject } H_0 \mid H_1 \text{ is true})$ -- the probability
that your experiment correctly detects a real effect.

Conventional target: 80% power at the 5% significance level. This means if
the true effect exists, you have an 80% chance of finding it.

**Why it matters:** An underpowered experiment with a null result tells you
*nothing*. You can't distinguish "no effect" from "effect exists but sample
too small." This is the most common mistake in experiment design.

### The Four Knobs

Power depends on exactly four quantities:

1. **Effect size** ($\delta$): The true difference between treatment and control.
   Larger effects are easier to detect.
2. **Sample size** ($n$): More data = smaller standard errors = more power.
3. **Outcome variance** ($\sigma^2$): Noisier outcomes require larger samples.
   This is where covariate adjustment helps.
4. **Significance level** ($\alpha$): Usually fixed at 0.05 by convention. Larger
   $\alpha$ means more power but more false positives.

The formula for a two-sample test with equal groups:

$$n_{\text{per arm}} = \frac{(z_{1-\alpha/2} + z_\beta)^2 \cdot 2\sigma^2}{\delta^2}$$

### Simulation-Based Power Analysis

The formula above assumes normality, equal variances, and a simple
difference-in-means test. In practice you should use simulation:

1. Generate fake data under the alternative hypothesis (with a known effect).
2. Run your actual analysis (the same regression you'll run on real data).
3. Check if you reject $H_0$ at $\alpha = 0.05$.
4. Repeat 1,000+ times. Power = fraction of rejections.

**Advantages of simulation:**
- Works for any outcome distribution (binary, count, skewed)
- Handles covariates, stratification, clustering
- Directly tests your actual analysis pipeline
- No assumptions about closed-form distributions

### Minimum Detectable Effect (MDE)

Power analysis is often framed backwards. The business question is not
"given an effect size, how many samples?" but rather "given our sample size,
what's the smallest effect we can detect?"

$$\text{MDE} = (z_{1-\alpha/2} + z_{1-\beta}) \cdot \sqrt{\frac{2\sigma^2}{n}}$$

**Interview tip:** When asked "how would you design this experiment?", start
with the MDE. How big an effect matters for the business? How much traffic
do you have? Is the MDE smaller than the effect that matters? If not, the
experiment isn't worth running.

### Clustering and the Design Effect

When randomization is at the cluster level (e.g., cities, stores, schools)
but outcomes are measured at the individual level, power drops dramatically.

**ICC** (Intra-cluster Correlation): The fraction of total variance that is
between clusters. Even ICC = 0.05 can be devastating.

**Design effect** = $1 + (m - 1) \times \text{ICC}$, where $m$ is the
number of individuals per cluster.

| Cluster size | ICC = 0.01 | ICC = 0.05 | ICC = 0.10 |
|-------------|-----------|-----------|-----------|
| 10          | 1.09      | 1.45      | 1.90      |
| 50          | 1.49      | 3.45      | 5.90      |
| 100         | 1.99      | 5.95      | 10.90     |
| 500         | 5.99      | 25.95     | 50.90     |

**The key insight:** once clusters are "large enough" (roughly > 50 units),
adding more units per cluster barely helps. You need **more clusters**. This
is why cluster-randomized experiments in 20 cities are almost always
underpowered -- even if each city has millions of users.

**Effective sample size** = $\frac{Jm}{\text{DEFF}}$, where $J$ = number
of clusters and DEFF = design effect. With 20 clusters of 500 and ICC = 0.05,
the effective $n$ is $\frac{10{,}000}{25.95} \approx 385$ per arm, not 10,000.

### Reducing Variance: The Free Lunch

You can increase power without more samples by reducing residual variance:

- **Pre-treatment covariates:** Control for variables that predict the outcome
  but are uncorrelated with treatment (e.g., last month's revenue, user
  tenure). This is valid because randomization ensures independence.
- **Stratified randomization:** Randomize within blocks defined by important
  covariates. Guarantees exact balance on those variables.
- **CUPED:** Uses pre-treatment outcomes as a covariate to reduce variance.
  Can reduce variance by 30-50% in practice. Covered in detail in Module 5.

A covariate with $R^2 = 0.3$ reduces the required sample size by ~30%.
This is equivalent to getting 30% more users for free.

### What Tech Companies Care About

- Can you compute the MDE for a given experiment?
- Can you explain why a null result from an underpowered test is uninformative?
- Do you understand why clustering kills power and what to do about it?
- Can you set up a simulation-based power analysis for a non-standard design?
- Do you know how to use pre-treatment data to boost power?
