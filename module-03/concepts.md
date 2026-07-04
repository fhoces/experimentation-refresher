# Module 3: Designing Around Interference

## Quick Refresher

You know from Module 2 that SUTVA violations bias the naive ATE. This module
covers the design solutions. Key references: Imbens & Rubin Ch. 22-24,
Baird et al. (2018) on cluster randomization, Bojinov & Shephard (2019,
JASA) and Bojinov, Simchi-Levi & Zhao (2023, Mgmt Sci) on switchback
designs, Bajari et al. (2023) on multiple-randomization designs,
Aronow & Samii (2017, Annals of Applied Stats) on exposure mappings
under general interference, and Kohavi et al. (2020) on marketplace
experiments.

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

**Choosing the period length.** Short blocks suffer carryover bias (many
transitions); long blocks waste statistical efficiency (fewer effectively
independent assignments under block-clustered SE). Under Markov-1 carryover
$\delta$, naive bias is $\delta/(2L)$ and block-clustered variance is
$\propto L/(CT)$, so the MSE-optimal block length scales as $L^{*} \propto
(\delta^{2} CT / \sigma^{2})^{1/3}$. Bojinov, Simchi-Levi & Zhao (2023) give
the formal characterization and an implementable scheme. Pre-estimate
$\delta$ from a pre-period A/A test and cluster SE at the block.

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

## The same problem at an online retailer

Because fulfillment capacity is a metro-level resource, the natural unit of randomization for next-day delivery is the metro. Assigning individual customers within a metro to next-day eligibility creates within-metro interference: treated and control customers draw from the same courier pool, so the design violates SUTVA through exactly the capacity mechanism described in Module 2. The clean design is a geo experiment that assigns entire metros to next-day or two-day, keeping the interference within each group rather than across arms. Switchback designs are a poor fit here. A driver's response to a surge resets within a trip, but a customer told that their packages arrive tomorrow develops an expectation that persists across days or weeks. Flipping a metro back to two-day delivery in a switchback's off period measures the effect of disappointed expectations, not the counterfactual without next-day. The metro-level design also sharply reduces the effective sample size, from millions of customers to dozens of metros, which has direct implications for statistical power covered in Module 4.
