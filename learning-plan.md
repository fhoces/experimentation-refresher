# Experimentation Refresher

Refresh experimentation fundamentals for tech company interviews. Heavy on
intuition, simulations, and numerical examples. Proofs live in backup slides.
Applications drawn from ride-sharing platforms, online advertising, and
academic research (reporting of pre-registered results).

**Target:** Senior data scientist / economist roles at tech companies.
They care especially about: spillovers, SUTVA violations, external validity,
and practical design choices for marketplace experiments.

**Background:** Mastering Metrics (solid), MHE (rusty), Imbens & Rubin (rusty).

---

## Module 1: The Experimental Ideal
- Potential outcomes framework (Rubin causal model)
- ATE, ATT, ATU — when they differ and why it matters
- Selection bias: the fundamental problem of causal inference
- Randomization as the solution — why it works (simulation)
- **Application — Ride-sharing:** Does a new driver bonus increase retention?
  Naive comparison of drivers who got bonuses vs didn't → selection bias.
  Randomize → unbiased estimate.
- **Exercise (R):** Simulate potential outcomes, show selection bias, show
  randomization eliminates it in expectation.

## Module 2: SUTVA and When It Breaks
- SUTVA stated precisely: no interference + no hidden versions of treatment
- Why SUTVA is almost always violated in marketplace experiments
- Interference through the marketplace: treating drivers affects passengers
  (and vice versa). Treating users affects other users through prices.
- Interference through networks: co-author spillovers (academic research),
  social network effects (ad campaigns)
- Partial vs. general equilibrium effects
- **Application — Ride-sharing:** Experiment giving 50% of drivers a bonus.
  Treated drivers take more rides → fewer rides available for control drivers.
  Control group outcomes are *affected by treatment*. Naive ATE is biased.
- **Application — Academic research:** Co-author network spillovers — an
  author treated in one study may change behavior in another study they
  co-authored.
- **Exercise (R):** Simulate a marketplace with interference. Compare naive
  ATE to true ATE. Show the bias depends on interference strength.

## Module 3: Designing Around Interference
- Cluster randomization: randomize at the market/city level
- Switchback / time-based designs: alternate treatment on/off over time
- Two-sided marketplace designs: randomize one side, measure the other
- Geo experiments: geographic units as clusters
- Ego-cluster randomization for network spillovers
- Bias-variance tradeoff: bigger clusters reduce interference bias but
  increase variance (fewer independent units)
- **Application — Ride-sharing:** City-level randomization for a pricing
  change. Switchback design for surge algorithm experiments.
- **Application — Online ads:** Geo-based incrementality testing for ad
  campaigns.
- **Exercise (R):** Compare simple vs cluster randomization in a simulated
  marketplace. Show the bias-variance tradeoff as cluster size varies.

## Module 4: Power and Sample Size
- What power is: P(reject H0 | H1 true)
- The four knobs: effect size, sample size, variance, significance level
- Simulation-based power analysis (more intuitive than formulas)
- Clustering effects on power: design effect / ICC
- Minimum detectable effect (MDE) — the question the business actually asks
- Pre-treatment covariates to reduce variance (CUPED preview)
- **Application — Online ads:** Planning an A/B test for a new ad format.
  How many impressions do you need to detect a 2% lift in click-through rate?
- **Application — Ride-sharing:** Power for a city-level experiment with
  only 20 cities. Why individual-level n doesn't save you.
- **Exercise (R):** Simulate power curves. Show how clustering kills power.
  Implement a simulation-based power calculator.

## Module 5: Analyzing Experiments
- Difference in means: the simplest estimator
- Regression with covariates: Lin (2013) — why and how to adjust
- CUPED (Controlled-experiment Using Pre-Experiment Data): variance reduction
  using pre-treatment outcomes
- Stratification and post-stratification
- Robust standard errors: HC2, cluster-robust
- ITT vs LATE: non-compliance in experiments
- Pre-analysis plans: what to specify, how to handle deviations
- **Application — Ride-sharing:** Estimating the effect of a driver bonus
  using CUPED (pre-treatment trip counts as covariate). Handling drivers who
  didn't use the bonus (non-compliance → ITT vs LATE).
- **Application — Academic research:** DiD specification for pre/post
  intervention effects on hypothesis reporting rates.
- **Exercise (R):** Implement CUPED from scratch. Compare precision with
  and without covariate adjustment.

## Module 6: Multiple Testing and Subgroup Analysis
- The multiple comparisons problem: why looking at 20 subgroups guarantees
  false positives
- Bonferroni, Holm, BH (FDR control) — when to use which
- Pre-specified vs exploratory subgroups
- Interaction effects vs subgroup-specific effects
- The garden of forking paths
- **Application — Online ads:** Testing 10 ad creatives simultaneously.
  Adjusting for multiple comparisons.
- **Application — Ride-sharing:** Heterogeneous treatment effects by city
  type (LMIC vs HIC), driver tenure, peak vs off-peak.
- **Exercise (R):** Simulate 20 A/A tests, show false positive inflation.
  Apply BH correction. Pre-register one subgroup, show it survives.

## Module 7: External Validity and Generalizability
- Internal vs external validity — the tradeoff
- Site selection bias: your experiment ran in SF, does it generalize to Lagos?
- Heterogeneous treatment effects as the key to generalizability
- Transportability: formal frameworks (Pearl, Bareinboim)
- Dose-response and mechanism: *why* does it work → *where* will it work
- Temporal validity: effects that decay (novelty effects in tech)
- Hawthorne effects and demand effects
- **Application — Ride-sharing:** A pricing experiment in one city. Can you
  extrapolate to other cities with different supply/demand dynamics?
- **Application — Academic research:** Do results from 2015-2017 AEA
  Registry studies generalize to current research practices?
- **Exercise (R):** Simulate treatment effect heterogeneity across sites.
  Show when/why extrapolation fails.

## Module 8: Advanced Topics for Tech Interviews
Focus: when randomization isn't available or isn't enough — modern DiD,
synthetic control, and heterogeneous treatment effects via causal forests.
- **Modern DiD** — parallel trends and pretrend testing pitfalls
  (Roth 2022); the staggered-adoption problem; Goodman-Bacon (2021)
  decomposition and TWFE negative weights; the heterogeneity-robust
  estimators (Callaway & Sant'Anna 2021, Sun & Abraham 2021,
  de Chaisemartin & D'Haultfœuille 2020, Borusyak et al. 2024); Honest
  DiD (Rambachan & Roth 2023) bounds under partial PT violations.
- **Synthetic control + Synthetic DiD** — Abadie/Diamond/Hainmueller
  weighted donor-pool estimator, placebo inference, and the
  Arkhangelsky et al. (2021) bridge to DiD via dual time + unit weights.
- **Causal forest** — Wager & Athey (2018) honest splitting; the `grf`
  package; HTE estimation as a building block for policy learning.
- **One-pagers** — bandits (explore-exploit), sequential testing
  (peeking, mSPRT/always-valid CIs).
- **Application — Ride-sharing:** Staggered rollout of a
  zone-notification feature across cities — show TWFE bias vs
  Callaway-Sant'Anna; synthetic-control / SDID for a one-city policy
  change; causal forest for HTE by city + driver tenure.
- **Exercise (R):** (a) detect TWFE bias on simulated staggered data via
  Goodman-Bacon, (b) build a synthetic control by hand (NNLS) and
  compare to SDID, (c) fit a causal forest and recover the true
  treatment heterogeneity.
- **Backup slides** — Goodman-Bacon derivation; CS estimator formal
  definition; staggered-adoption DGP; SC / SDID DGP; honest-DiD bounds;
  causal forest splitting algorithm; policy-learning detail.

---

## R Stack
- **tidyverse** — data wrangling and visualization
- **estimatr** — robust standard errors, IV, cluster-robust
- **DeclareDesign** — design-based simulation and power
- **fixest** — fast fixed effects, DiD, cluster SE
- **rdrobust** — regression discontinuity
- **did** — difference-in-differences
- **randomizr** — randomization utilities
- **ggplot2** — visualization

## Key References
- Angrist & Pischke — *Mastering 'Metrics* (Chapters 1-2 especially)
- Angrist & Pischke — *Mostly Harmless Econometrics* (Chapters 2, 4, 8)
- Imbens & Rubin — *Causal Inference for Statistics, Social, and Biomedical
  Sciences* (Chapters 1-6, 22-24 on interference)
- Athey & Imbens (2017) — "The Econometrics of Randomized Experiments"
- Deng et al. (2013) — "Improving the Sensitivity of Online Controlled
  Experiments by Utilizing Pre-Experiment Data" (CUPED)
- Aronow & Samii (2017) — "Estimating Average Causal Effects Under General
  Interference"
- Kohavi, Tang & Xu — *Trustworthy Online Controlled Experiments* (the
  industry bible)

## How to Use This Plan
1. Review the learning plan and adjust topics/ordering.
2. Say **"start module 1"** to build the slides.
3. Review slides, iterate, then move to the next module.
