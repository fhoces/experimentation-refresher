# Module 1: The Experimental Ideal

## Quick Refresher

You know this from Mastering Metrics Chapter 1 and Imbens & Rubin Chapters 1-3.
Here's the fast version with emphasis on what comes up in tech interviews.

### The Fundamental Problem of Causal Inference

For each unit $i$, there are two potential outcomes:
- $Y_i(1)$: outcome if treated
- $Y_i(0)$: outcome if not treated

The individual treatment effect is $\tau_i = Y_i(1) - Y_i(0)$.

**The problem:** we only ever observe one of the two. The other is the
*counterfactual* — it doesn't exist in the data.

### Estimands: ATE, ATT, ATU

- **ATE** (Average Treatment Effect): $E[Y_i(1) - Y_i(0)]$ — average over
  everyone
- **ATT** (on the Treated): $E[Y_i(1) - Y_i(0) | D_i = 1]$ — average over
  those who actually got treated
- **ATU** (on the Untreated): $E[Y_i(1) - Y_i(0) | D_i = 0]$

These three are equal when the treatment effect is constant ($\tau_i = \tau$
for all $i$). They differ when effects are heterogeneous AND treatment
assignment is correlated with the effect.

**Interview tip:** When someone asks "what's the effect of X?", the first
question back should be "for whom?" ATE, ATT, and ATU answer different
questions and can have opposite signs.

### Selection Bias

The naive comparison is:
$$E[Y_i | D_i = 1] - E[Y_i | D_i = 0]$$

This equals the ATT + selection bias:
$$= \underbrace{E[Y_i(1) - Y_i(0) | D_i = 1]}_{\text{ATT}} + \underbrace{E[Y_i(0) | D_i = 1] - E[Y_i(0) | D_i = 0]}_{\text{selection bias}}$$

Selection bias = the difference in baseline outcomes between the groups. If
people who choose treatment are systematically different (higher income,
more motivated, etc.), the naive comparison confounds the treatment effect
with these pre-existing differences.

### Randomization: Why It Works

Random assignment makes $D_i$ independent of potential outcomes:
$(Y_i(1), Y_i(0)) \perp D_i$

This kills selection bias:
$$E[Y_i(0) | D_i = 1] = E[Y_i(0) | D_i = 0] = E[Y_i(0)]$$

So the simple difference in means is unbiased for the ATE:
$$E[Y_i | D_i = 1] - E[Y_i | D_i = 0] = E[Y_i(1)] - E[Y_i(0)] = \text{ATE}$$

**Key insight for interviews:** Randomization doesn't guarantee balance in
any single experiment — it guarantees balance *in expectation*. Any given
experiment can have imbalanced covariates by chance. That's what confidence
intervals are for.

### SUTVA (Preview)

The potential outcomes framework assumes:
1. **No interference:** $Y_i(d)$ depends only on $i$'s own treatment, not
   on anyone else's
2. **No hidden versions:** treatment is the same for everyone who gets it

Both assumptions are routinely violated in tech/marketplace settings. Module 2
goes deep on this.

### What Tech Companies Care About

- Can you decompose the naive comparison into causal effect + bias?
- Can you identify *where* selection bias comes from in a specific scenario?
- Do you understand that randomization is necessary but not sufficient
  (SUTVA, power, compliance matter too)?
- Can you distinguish ATE from ATT and explain when it matters?
