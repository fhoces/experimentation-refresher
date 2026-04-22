# Module 7: External Validity & Generalizability

## Quick Refresher

Internal validity tells you the experiment was done right. External validity
tells you the result matters beyond the experiment. This module is about
the second question — and why it is much harder than the first.

### Internal vs External Validity

**Internal validity** is about whether the causal estimate is correct within
the study population. Randomization, proper analysis, and avoiding attrition
and spillovers ensure internal validity.

**External validity** is about whether the result generalizes to other
populations, settings, time periods, or implementations. Internal validity
is necessary but not sufficient for external validity.

**The tradeoff:** Tightly controlled lab experiments maximize internal
validity but may have low external validity. Multi-site field experiments
sacrifice some precision for generalizability.

### Site Selection Bias

Experiments are not run in randomly selected sites. They are run where
it is convenient, where the treatment is expected to work, or where the
organization has capacity. This creates a systematic bias: experimental
estimates tend to overstate the average effect across the full population
of potential sites.

### Heterogeneous Treatment Effects: The Core Issue

External validity is **only** a concern when treatment effects vary across
populations. If the effect is the same everywhere (homogeneous), any single
experiment generalizes perfectly. The problem arises when:

1. Effects vary with population characteristics (effect modification)
2. The experimental population differs from the target on those characteristics
3. The researcher does not know or cannot adjust for the relevant effect modifiers

### Transportability

Formal frameworks (Pearl & Bareinboim, 2014) define when a causal effect
estimated in one population can be "transported" to another:

$$\tau_B = \sum_x E_A[Y(1) - Y(0) | X = x] \cdot P_B(X = x)$$

This requires:
- Knowing which variables $X$ are effect modifiers
- Conditional effects being the same across populations (given $X$)
- Having overlap: $P_A(X = x) > 0$ wherever $P_B(X = x) > 0$

In practice, this means: estimate conditional treatment effects from your
experiment, then reweight to the target population's covariate distribution.

### Dose-Response and Mechanism

Understanding **why** a treatment works is more useful for generalization
than knowing **that** it works. If you understand the mechanism, you can
predict where it will and will not work:

- A price cut works by stimulating demand. It only works where supply can
  absorb extra demand.
- A nudge works by reducing friction. It only works where friction is the
  binding constraint.
- A bonus works by increasing motivation. It only works where motivation
  is the bottleneck.

Dose-response curves provide additional information: they show whether the
effect is linear, concave, or has a threshold.

### Temporal Validity

Effects can change over time for several reasons:

**Novelty effects:** Users engage with a new feature because it is new, not
because it is better. A 4-week experiment may capture peak novelty rather
than the steady state. Exponential decay: $\tau(t) = \tau_\infty + (\tau_0 - \tau_\infty) e^{-\lambda t}$.

**Changing populations:** The users who adopt first may differ from later
adopters (early adopters vs mainstream).

**Changing context:** Market conditions, competitor actions, and norms
evolve. A result from 2015 may not hold in 2025.

### Hawthorne and Demand Effects

**Hawthorne effect:** Behavior changes because participants know they are
observed, not because of the treatment. Most relevant for lab experiments,
employee studies, and opt-in trials. Less relevant for standard A/B tests
where users are unaware of their assignment.

**Demand effects:** Participants infer the experimenter's hypothesis and
adjust behavior accordingly (compliance or reactance). Mitigated by
blinding, behavioral outcomes, and deception.

### Strategies for External Validity

| Strategy | How it helps |
|----------|-------------|
| Multi-site experiments | Directly measures effect heterogeneity |
| Stratified site selection | Ensures diversity on key dimensions |
| Effect modifier analysis | Models why effects vary across contexts |
| Mechanism tests | Predicts where treatment will work |
| Longer experiments | Captures steady-state effects |
| Replication | Confirms or refutes in new settings |

### What Tech Companies Care About

- Can you identify when a result from one market will not generalize?
- Can you propose a multi-site experiment design?
- Do you understand novelty effects and how to test for them?
- Can you distinguish between "the treatment works" and "the treatment
  works here, now, for these users"?
- Can you articulate what additional data you would need to extrapolate?
