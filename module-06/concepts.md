# Module 6: Multiple Testing & Subgroups

## Quick Refresher

You know the basics of hypothesis testing from earlier modules. This module
covers what happens when you do it many times at once — and why that is
the norm in practice, not the exception.

### The Multiple Comparisons Problem

If you test $m$ independent hypotheses, each at significance level $\alpha$,
the probability of at least one false positive is:

$$\text{FWER} = 1 - (1 - \alpha)^m$$

At $m = 20$ and $\alpha = 0.05$: FWER = 64%. You are more likely than not
to find a "significant" result even when nothing is going on.

**Why this matters in practice:** Every experiment involves choices —
which outcome, which subgroups, which specification. Each choice is an
implicit test. The more choices, the higher the FWER.

### Correction Methods

**Bonferroni:** Test each hypothesis at $\alpha / m$. Controls FWER via
the union bound. Simple but very conservative, especially when tests are
positively correlated (which is common with overlapping subgroups).

**Holm (1979):** A step-down procedure. Sort p-values smallest to largest.
Test the $k$-th smallest against $\alpha / (m - k + 1)$. Stop at the first
non-rejection. Holm is uniformly more powerful than Bonferroni and still
controls FWER. There is essentially no reason to use Bonferroni over Holm.

**Benjamini-Hochberg (1995):** Controls the False Discovery Rate (FDR)
instead of the FWER. FDR = the expected proportion of false positives
among rejections. BH is much less conservative than FWER methods and is
appropriate when you can tolerate some false positives (e.g., screening
many ad creatives or subgroups for follow-up).

### FWER vs FDR

- **FWER** = P(at least one false positive). Controls the "worst case."
  Use when a single false positive is costly (launch decision, regulatory).
- **FDR** = E[false positives / total rejections]. Controls the average
  rate of false discoveries. Use when you are screening many hypotheses
  and will follow up on the discoveries.

**Interview tip:** Know the difference. If someone asks "how do you handle
multiple testing?", the answer depends on the goal. FWER for confirmatory
analysis, FDR for exploratory screening.

### Pre-Specified vs Exploratory Subgroups

**Pre-specified** subgroups are defined in the analysis plan before looking
at the data. They have a limited, known correction burden (number of
pre-specified tests). They are credible because the researcher committed
to them ex ante.

**Exploratory** subgroups are discovered in the data. The correction burden
is unknown (how many things did you look at before finding this one?).
They should be labeled as hypothesis-generating and need replication.

### Interaction Effects vs Subgroup-Specific Effects

A common mistake: "The effect is significant in group A (p = 0.01) but not
in group B (p = 0.15), so the effect differs by group."

This is wrong. To test whether the effect *differs*, you must test the
interaction term. "Significant" vs "not significant" is not a statistically
significant difference (Gelman & Stern, 2006).

### The Garden of Forking Paths

Researcher degrees of freedom include: choice of outcome, subgroups,
covariates, outlier rules, functional form, time window, missing data
handling, etc. Each decision is a "fork." With enough forks, you can find
significance in pure noise.

The antidote is the pre-analysis plan (PAP): specify your primary tests
before seeing the data. This makes the number of tests explicit and small,
and makes the distinction between confirmatory and exploratory transparent.

### Decision Framework

| Scenario | Correction |
|----------|------------|
| 1 primary outcome, no subgroups | None needed |
| 1 primary + 2-3 pre-specified subgroups | Holm (FWER) |
| Screening 10+ variants | BH (FDR) |
| Post hoc exploration | Label as exploratory; no formal inference |

### What Tech Companies Care About

- Can you identify when multiple testing is a concern?
- Do you know the difference between FWER and FDR?
- Can you apply `p.adjust()` in R with the right method?
- Do you understand the interaction test vs subgroup-specific test distinction?
- Can you articulate why pre-analysis plans help?
