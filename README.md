# Experimentation Refresher

A hands-on refresher on experimental design and causal inference for tech
company interviews. Heavy on simulations, numerical examples, and intuition.
Proofs in backup slides.

Applications drawn from ride-sharing platforms, online advertising, and
academic research.

> **Live slides:** https://fhoces.github.io/experimentation-refresher/
>
> **Focus areas:** spillovers, SUTVA violations, external validity, marketplace
> experiments, power analysis, CUPED, multiple testing.

## Modules

| # | Module | Concepts | Application |
|---|--------|----------|-------------|
| **1** | [The Experimental Ideal](module-01/) ([slides](https://fhoces.github.io/experimentation-refresher/module-01/slides.html)) | Potential outcomes, ATE, selection bias, randomization | Zone-notification driver experiment |
| **2** | [SUTVA and When It Breaks](module-02/) ([slides](https://fhoces.github.io/experimentation-refresher/module-02/slides.html)) | Interference, marketplace effects, network spillovers | Zone crowding + co-author spillovers |
| **3** | [Designing Around Interference](module-03/) ([slides](https://fhoces.github.io/experimentation-refresher/module-03/slides.html)) | Cluster randomization, switchback, geo experiments | City-level pricing experiments |
| 4 | Power and Sample Size | MDE, simulation-based power, clustering effects, ICC | A/B test planning for ad formats |
| 5 | Analyzing Experiments | Regression adjustment, CUPED, ITT vs LATE, PAPs | Covariate adjustment for driver experiments |
| 6 | Multiple Testing & Subgroups | Bonferroni, BH, pre-specified subgroups, forking paths | Testing multiple ad creatives |
| 7 | External Validity | Site selection, transportability, temporal validity | Cross-city generalization |
| 8 | Advanced Topics | Synthetic control, bandits, sequential testing, DiD | Feature rollout and adaptive experiments |

## Structure

Each module folder contains:
- **`concepts.md`** — written refresher
- **`slides.Rmd`** — xaringan slide deck
- **`exercise.R`** — runnable R script with simulations
