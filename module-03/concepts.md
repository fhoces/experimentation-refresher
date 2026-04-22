# Module 3: Designing Around Interference

## Quick Refresher

You know from Module 2 that SUTVA violations bias the naive ATE. This module
covers the design solutions. Key references: Imbens & Rubin Ch. 22-24,
Baird et al. (2018) on cluster randomization, Bajari et al. (2023) on
switchback designs, and Kohavi et al. (2020) on marketplace experiments.

### The Core Tradeoff

Every interference-robust design trades **bias** for **variance**:
- Individual randomization: minimal variance, maximal interference bias
- Cluster randomization: less bias, but fewer independent units = more variance
- Bigger clusters: even less bias, even more variance

### Cluster Randomization

Randomize at a level where interference is contained *within* clusters:
- Cities, markets, geographic regions
- Time periods (switchback)
- Network communities (ego-clusters)

**Key formula for effective sample size:**

$$n_{eff} = \frac{n}{1 + (m - 1) \cdot \rho}$$

where $n$ = total units, $m$ = cluster size, $\rho$ = intra-cluster correlation (ICC).

If $\rho = 0.1$ and $m = 50$, then $n_{eff} = n / 5.9$. You lose ~83% of
your effective sample.

### Switchback Designs

Alternate treatment on/off over time within the same unit (city, market):
- Period 1: treatment ON in all cities
- Period 2: treatment OFF in all cities
- Period 3: randomize which cities are ON vs OFF
- Repeat with different randomization each period

**Advantages:** every unit serves as its own control; good for marketplace
experiments where within-unit interference is strong but between-unit
interference is weak.

**Risks:** carryover effects (treatment in period $t$ affects outcomes in
period $t+1$). Requires "burn-in" periods between switches.

### Two-Sided Marketplace Designs

In a two-sided market (drivers/riders), randomize on the **less elastic** side
and measure outcomes on the other:
- Randomize riders into treatment/control
- Measure the effect on driver outcomes
- The rider-side randomization doesn't contaminate (each rider sees one
  experience), and driver outcomes reflect equilibrium effects

### Geo Experiments

Use geographic units (DMAs, cities, zip codes) as clusters for ad campaigns
or pricing experiments:
- Each geo unit is an independent market
- Randomize treatment at the geo level
- Measure aggregate outcomes per geo unit
- Requires enough geo units for power (often 50-200+)

### Ego-Cluster Randomization

For network experiments, define each unit's "ego cluster" as the unit plus
their immediate neighbors:
- Randomize the entire ego cluster to the same arm
- Interference within the cluster is absorbed
- Between-cluster interference is (hopefully) small

### What Tech Companies Care About

- Can you choose the right design for a given interference structure?
- Can you reason about the bias-variance tradeoff explicitly?
- Do you understand when switchback is better than cluster randomization?
- Can you estimate the power loss from clustering (ICC, design effect)?
- Can you identify when none of these solutions works (pervasive GE effects)?
