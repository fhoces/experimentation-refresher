# Module 8: Advanced Topics for Tech Interviews

## Quick Refresher

This module covers methods beyond the standard A/B test that come up
frequently in tech interviews. These are tools for when randomization is
impossible, impractical, or when you want to be smarter about how you
run experiments.

### Synthetic Control

**When:** You can't randomize and only have one (or very few) treated units.
Classic example: a policy change in one city.

**How it works:** Construct a weighted combination of untreated "donor" units
that matches the treated unit's pre-treatment trajectory. The gap between
the treated unit and the synthetic control after treatment = the estimated
causal effect.

**Key points:**
- Weights are non-negative and sum to 1 (convex combination)
- Pre-treatment fit quality validates the approach
- Inference via permutation: apply the method to each untreated unit and
  compare placebo effects to the actual effect
- With J donors, smallest p-value = 1/J (need large donor pools)

**Interview tip:** This is the go-to answer for "how would you measure the
effect of X in one city/country/market?" Better than naive before/after
comparisons because it constructs the counterfactual from data.

### Regression Discontinuity (RD)

**When:** Treatment is assigned based on whether a continuous "running variable"
crosses a known cutoff. Examples: eligibility thresholds, score cutoffs,
completion bonuses.

**Sharp RD:** Everyone above the cutoff is treated, everyone below is not.
$D_i = \mathbf{1}[X_i \geq c]$

**Fuzzy RD:** Crossing the cutoff changes the probability of treatment but
doesn't guarantee it. Use the cutoff as an instrument (IV/Wald estimator).

**Key design choices:**
- Bandwidth: how much data around the cutoff to use
  - Too narrow: noisy estimates
  - Too wide: bias from misspecified functional form
  - Use data-driven methods (CCT, IK)
- Kernel: how to weight observations near vs far from cutoff
- Polynomial order: usually local linear is safest

**What it estimates:** A *local* average treatment effect at the cutoff. This
may not generalize away from the threshold.

### Difference-in-Differences (DiD)

**When:** You have panel data (multiple units observed over time) and treatment
affects some units at a known time.

**The identifying assumption:** Parallel trends --- absent treatment, treated
and control groups would have followed the same trajectory.

**How to assess parallel trends:**
1. Plot pre-treatment trends visually
2. Run event-study regression with leads (pre-treatment dummies should be zero)
3. Check robustness to different control groups

**When parallel trends fail:**
- Treatment group was already trending differently
- DiD estimate will be biased (direction depends on the violation)
- Consider: synthetic control, triple differences, or matching + DiD

**Specification:**
$$Y_{it} = \alpha_i + \lambda_t + \tau \cdot D_{it} + \varepsilon_{it}$$
where $\alpha_i$ = unit fixed effects, $\lambda_t$ = time fixed effects,
$D_{it}$ = treatment indicator.

### Bandits and Adaptive Experimentation

**The idea:** Instead of fixed 50/50 allocation, shift traffic toward
better-performing variants during the experiment.

**Thompson Sampling:**
1. Start with a prior on each arm's conversion rate: $\theta_k \sim \text{Beta}(1,1)$
2. At each round, draw $\tilde{\theta}_k$ from the posterior for each arm
3. Play the arm with the highest draw
4. Update the posterior with the observed outcome:
   $\theta_k | \text{data} \sim \text{Beta}(1 + s_k, 1 + f_k)$

**Regret:** The difference between the reward you earned and the reward
you would have earned always playing the best arm. Bandits minimize
cumulative regret.

**The trade-off:**
- Bandits *optimize reward* during the experiment
- A/B tests *optimize learning* (unbiased effect estimates)
- Non-uniform allocation biases standard estimators
- Use bandits when: cost of suboptimal allocation is high AND you don't
  need a precise treatment effect estimate
- Use A/B tests when: you need to *measure* the effect for a launch decision

### Sequential Testing

**The problem:** If you peek at your A/B test results repeatedly and stop
when p < 0.05, your actual false positive rate is much higher than 5%.
With 20 peeks, it can exceed 25%.

**Why:** Under H0, the test statistic follows a random walk. Given enough
looks, a random walk will eventually cross any finite boundary.

**Group sequential designs:**
- Pre-specify the number of interim looks
- Use adjusted boundaries at each look (stricter than 1.96 early on)
- **O'Brien-Fleming:** Very conservative early, nearly standard at the end.
  Most power preserved.
- **Pocock:** Equal boundary at each look. Easier to reject early, harder
  at the end.

**Always-valid inference (confidence sequences):**
- Modern approach: construct intervals valid at *any* stopping time
- No need to pre-specify look times
- Cost: ~20-30% wider than fixed-sample CIs (need more data)
- Increasingly adopted at tech companies (Optimizely, Netflix)

### Metric Selection

**Success metrics** (primary): What you're trying to improve. Must be:
- Measurable in the experiment timeframe
- Sensitive enough to detect realistic effect sizes
- Aligned with long-term business goals

**Guardrail metrics:** Must not get worse. Tested one-sided. Examples:
crash rate, latency, support tickets. Set maximum acceptable degradation.

**Surrogate outcomes:** Proxies for long-term outcomes. Use when the true
outcome takes too long to observe. Requires a validated relationship
between surrogate and long-term outcome.

**OEC (Overall Evaluation Criterion):** A single composite metric that
combines success metrics and guardrails into one number. Makes launch
decisions mechanical: if OEC is positive and statistically significant,
ship it.

### Interview Framework

When asked "How would you design an experiment to test X?":

1. **Define the question:** What causal effect? On whom (ATE/ATT)?
2. **Unit of randomization:** User, session, city? (SUTVA considerations)
3. **Metrics:** Primary, guardrails, surrogates
4. **Power:** MDE, sample size, duration
5. **Analysis plan:** Estimator, covariates, multiple comparisons
6. **Threats:** Interference, novelty effects, non-compliance, peeking

Walk through this out loud. Interviewers test structured thinking, not
just technical knowledge.

### What Tech Companies Care About

- Can you choose the right method for the constraint? (Can't randomize?
  Use synth control or DiD. Need to peek? Use sequential testing.)
- Do you understand the trade-offs? (Bandits sacrifice inference for
  reward. Sequential testing sacrifices power for flexibility.)
- Can you structure an experiment design from scratch?
- Do you know what metrics matter and how to define them?
- Can you identify when standard A/B testing breaks down?
