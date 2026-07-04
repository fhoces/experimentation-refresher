# Module 2: SUTVA and When It Breaks

## Quick Refresher

You know the basics from Imbens & Rubin Chapters 22-24 and Aronow & Samii
(2017). Here's the fast version with emphasis on marketplace and network
interference -- the stuff tech interviewers love to probe.

### SUTVA: The Assumption You Forgot You Were Making

The **Stable Unit Treatment Value Assumption** has two components:

1. **No interference:** unit $i$'s outcome depends *only* on $i$'s own
   treatment assignment, not on anyone else's.
   $$Y_i = Y_i(D_i) \quad \text{not} \quad Y_i(D_1, D_2, \ldots, D_N)$$

2. **No hidden versions of treatment:** there is only one version of
   "treated" and one version of "control." The treatment is the same
   regardless of how it was assigned or who else is treated.

When SUTVA holds, potential outcomes are well-defined as $Y_i(0)$ and
$Y_i(1)$. When it fails, $Y_i$ depends on the entire treatment vector
$\mathbf{D}$, and there are $2^N$ potential outcomes per unit instead of 2.

### Why SUTVA Is Almost Always Violated in Practice

**Marketplace interference (two-sided markets):**
- Treating drivers (supply side) changes the experience for riders (demand
  side) -- more drivers means shorter wait times for riders.
- Treating riders (demand side) changes outcomes for drivers -- more ride
  requests means more revenue per driver.
- Within the same side: notifying some drivers about a high-demand zone
  sends them all there; the zone saturates and each notified driver takes
  fewer rides than the notification alone would give.

**Network interference:**
- In social networks: treating user A with a new feature might change user
  B's behavior if A and B interact.
- In academic research: an author treated in one study (e.g., receiving
  feedback on their results) may change how they report results in another
  study where they are a co-author.

**General equilibrium effects:**
- A small experiment (1% of users) is approximately "partial equilibrium" --
  the treated fraction is too small to move the market.
- A full rollout (100% of users) is "general equilibrium" -- the treatment
  changes the entire market structure.
- The experiment estimates the partial equilibrium effect, but you want to
  predict the general equilibrium effect. These can differ dramatically.

### The Bias from Interference

When treatment spills over from treated to control units, the control group
outcomes are contaminated. Specifically:

- If treatment has positive spillovers (e.g., vaccination), control outcomes
  improve, and the naive ATE *underestimates* the true effect.
- If treatment has negative spillovers (e.g., competition for scarce
  resources), control outcomes worsen, and the naive ATE *overestimates*
  the true effect.

The direction and magnitude of the bias depend on:
1. The fraction of units treated
2. The strength of the interference
3. The network structure / market structure

### What Tech Companies Care About

- Can you identify *where* SUTVA is violated in a specific experiment?
- Can you predict the *direction* of the bias from interference?
- Do you understand partial vs general equilibrium and why it matters for
  experiment-to-rollout extrapolation?
- Can you reason about network spillovers and co-author / social contagion?
- Do you know the solutions? (That's Module 3.)

## The same problem at an online retailer

Customer-level randomization of next-day delivery violates SUTVA through shared fulfillment capacity. A courier assigned to a treated customer's package cannot simultaneously serve a control customer in the same metro; treating some customers slows others' deliveries and degrades control outcomes. This means the measured control outcome is not the true $Y(0)$ under a world where no one gets next-day delivery; it is the outcome of competing for a constrained courier pool with a treated group. The naive difference-in-means therefore overstates the benefit of a full rollout, because the observed control counterfactual is artificially degraded. The hidden-versions component of SUTVA does hold here: all treated customers receive the same next-day promise regardless of their location within the metro, so treatment has a single well-defined version. The interference mechanism is capacity-mediated logistics, not social or informational, which shapes how one would design around it (Module 3).
