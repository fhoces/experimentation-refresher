# Module 8: Beyond the A/B Test

## Quick Refresher

When randomization isn't available — or isn't enough — the M5 toolkit (regression
adjustment, CUPED, ITT/LATE) doesn't apply. This module covers three observational
or quasi-experimental settings that come up constantly in tech-platform interviews:
staggered rollouts, single treated units, and effect heterogeneity.

For each, the field's "default" answer from a decade ago is now known to be
broken or insufficient. The slides cover what replaced them.

---

## Modern Difference-in-Differences

### The Staggered-Adoption Problem

Treatment turns on city-by-city over months. The "default" estimator is
two-way fixed effects (TWFE):

$$Y_{it} = \alpha_i + \lambda_t + \beta\, D_{it} + \varepsilon_{it}$$

If the true treatment effect is *constant* across cohorts and time, $\hat\beta$
is unbiased for the ATT. But once effects vary — across cohorts, or within a
cohort over time — TWFE gives a biased, hard-to-interpret weighted average.

### Goodman-Bacon (2021) Decomposition

$\hat\beta_{\text{TWFE}}$ can be written as a weighted average of all 2×2
DiDs in the data: every cohort vs every other cohort, vs the never-treated.

The bug: when an *earlier-treated* cohort serves as a "control" for a
*later-treated* one, the post-period for the comparison cohort is itself
under treatment. So the 2×2 subtracts a treated trend, not a counterfactual.
If effects grow over time, this 2×2 has a *negative* sign — and TWFE puts
positive weight on it.

The result: TWFE can have a sign opposite to the true average effect.

### The Heterogeneity-Robust Estimators

All four solve the same problem: only use **clean** comparisons (treated vs
not-yet-treated or never-treated):

| Estimator | Year | Idea |
|---|---|---|
| Callaway & Sant'Anna | 2021 | Estimate group-time ATT(g,t) separately, then aggregate |
| Sun & Abraham | 2021 | Saturated event-study with cohort × event-time interactions |
| de Chaisemartin & D'Haultfœuille | 2020 | Switchers vs not-yet-switchers |
| Borusyak, Jaravel, Spiess | 2024 | Impute Y(0) from never-treated, average residuals |

In simple cases all four converge. **Callaway-Sant'Anna is the most-cited
workhorse.** Report the event-study plot from one and a robustness column
from another.

### Pretrend Tests Have Low Power (Roth 2022)

The standard practice — check that pre-treatment leads are not
significantly different from zero — has low power against linear or
near-linear violations. Failing to reject is not strong evidence. Use
**Honest DiD** (Rambachan & Roth 2023) instead: posit a bound on the
post-treatment violation and report a robust CI that grows with the bound.
The smallest violation that flips your conclusion is the *breakdown value*.

---

## Synthetic Control

### The Estimator (Abadie/Diamond/Hainmueller 2010, 2015)

One treated unit, no good single control. Build a counterfactual as a
weighted combination of donors. Choose weights $w_j \ge 0$ with $\sum_j w_j = 1$
to minimize pre-treatment squared error:

$$\min_w \sum_{t < T_0} \left( Y_{1t} - \sum_{j \ge 2} w_j Y_{jt} \right)^2$$

The simplex constraint ($w_j \ge 0$, sum to 1) is what makes the synthetic
unit interpretable: a convex combination of real donors. Produces tighter,
more credible counterfactuals than unconstrained regression because it can't
extrapolate.

### Inference: Placebo-in-Space

Standard errors don't apply with one treated unit. Instead: re-run the
procedure pretending each *donor* is the treated unit. Compute the gap
between each placebo and its synthetic. If the true treated unit's gap is
extreme relative to the placebo distribution, that's evidence of an effect.

The p-value is approximately (rank of treated gap) / (number of placebos +1).

### Synthetic DiD (Arkhangelsky et al. 2021)

Generalizes both DiD and SC. Two sets of weights:

- **Unit weights** ($\hat\omega_i$) — like SC, match donor pre-trajectories to
  the treated unit. Adds an L2 penalty for stability.
- **Time weights** ($\hat\lambda_t$) — match the treated unit's pre-period to
  its post-period level. Down-weights pre-periods that don't look like "now".

Then run a weighted DiD using both. In Arkhangelsky's empirical comparisons,
SDID has lower MSE than either DiD or SC alone.

R: `synthdid::synthdid_estimate()`.

---

## Causal Forest (Wager & Athey 2018)

### Why HTE Matters

ATE answers "should we ship?". HTE answers "to whom?". Heterogeneity is the
input to:

- **Targeted rollout** — deploy where the effect is large.
- **Personalized policy** — assign treatment based on covariates.
- **Aggregate forecasting** — predict effect under different deployment plans.

Pre-specified subgroup analysis has two problems: multiple testing and
mis-specification (the right cuts aren't always the obvious ones).
Non-parametric estimation handles both.

### Honest Splitting

Each tree in the forest:

1. Splits the sample into two halves.
2. Uses one half to *grow* the tree (decide where to split).
3. Uses the other half to *estimate* the treatment effect within each leaf.

Without this split, the same noise that drove the split inflates the
estimated effect in the leaf — the over-fitting bias of vanilla regression
trees on causal targets.

### Splitting Criterion

Vanilla regression trees split where the outcome mean differs most. Causal
forests (Athey, Tibshirani & Wager 2019) split where the *treatment effect*
differs most:

$$\Delta(j, c) = n_L \, n_R \, (\hat\tau_L - \hat\tau_R)^2 / n$$

The `grf` package uses a fast gradient-based approximation rather than
evaluating $\hat\tau$ at every candidate split.

### Forest Prediction

For a new $x$:
- Each tree drops $x$ down to a leaf.
- The leaf defines a *local neighborhood* of training points.
- $\hat\tau(x)$ is a weighted DiD or IV across that neighborhood, weighted by
  how often training points share a leaf with $x$.

Pointwise confidence intervals are available — Wager & Athey prove
asymptotic normality.

### Policy Learning

Once you have $\hat\tau(x)$, learn a treatment rule
$\pi(x) = \mathbb{1}\{\hat\tau(x) > c(x)\}$ that maximizes welfare (Athey &
Wager 2021). `grf::policy_tree()` fits a depth-$L$ decision tree over $X$ —
an interpretable deployment rule.

---

## One-Pagers (Bandits, Sequential Testing)

### Bandits

$K$ arms; pick one each step, observe reward; maximize cumulative reward.
**Thompson Sampling** is the workhorse: maintain a posterior over each arm's
reward, sample, play the argmax. Asymptotically optimal regret, minimal tuning.

**Don't use bandits when** you need an unbiased ATE for a fixed-population
launch decision — bandits make assignment correlated with outcome history, so
naive pooled analysis is biased.

### Sequential Testing

Classical $p$-values are valid only at one fixed $n$. Repeated peeking
inflates Type-I to ~30% under the null at standard schedules. Two industry
fixes:

- **Group-sequential / O'Brien-Fleming** — spend $\alpha$ on a pre-specified
  schedule of looks. Conservative early, normal late.
- **Always-valid CIs / mSPRT** — confidence sequences valid uniformly over
  time. Stop whenever, CIs hold.

mSPRT form: $\hat\theta_t \pm \sigma\sqrt{(2\log(1/\alpha) + \log(1+t\rho^2))/(t\rho^2)}$.

---

## When to Use Which

- **Got randomization?** → M5 toolkit.
- **Staggered rollout, multiple cohorts?** → Callaway-Sant'Anna or
  Sun-Abraham. Avoid TWFE. Sensitivity-check with Honest DiD.
- **One treated unit?** → Synthetic control or SDID.
- **Effect heterogeneity?** → Causal forest, then policy tree.
- **Many arms, online?** → Thompson Sampling (unless you need a clean ATE).
- **Repeated looks?** → mSPRT or group-sequential.

---

## Going Deeper

The companion course **Causal Inference Beyond A/B Tests** (in development)
covers the formal estimators, full Honest DiD, augmented and generalized
synthetic control, matrix completion methods, and the Athey-Wager
policy-learning stack in depth.

## Key References

- Goodman-Bacon (2021), J. Econometrics — TWFE decomposition.
- Callaway & Sant'Anna (2021), J. Econometrics — group-time ATT.
- Sun & Abraham (2021), J. Econometrics — interaction-weighted estimator.
- Borusyak, Jaravel & Spiess (2024) — imputation estimator.
- Rambachan & Roth (2023), ReStud — Honest DiD.
- Roth (2022), AER:Insights — pretrend power critique.
- Abadie, Diamond & Hainmueller (2010, 2015) — synthetic control.
- Arkhangelsky et al. (2021), AER — synthetic difference in differences.
- Wager & Athey (2018), JASA — causal forests + asymptotic normality.
- Athey, Tibshirani & Wager (2019), Annals of Statistics — generalized
  random forests.
- Athey & Wager (2021), Econometrica — policy learning with regret bounds.
- Howard et al. (2021) — confidence sequences.
