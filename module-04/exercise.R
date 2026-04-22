# ============================================================================
# Module 4 Exercise: Power and Sample Size
# ============================================================================
#
# Build simulation-based power tools, generate power curves, and see how
# clustering destroys power.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. Simulation-based power for proportions --------------------------------

# Write a function that simulates power for a two-sample test of proportions.
# - Generate control outcomes from Binomial(1, baseline)
# - Generate treated outcomes from Binomial(1, baseline + effect)
# - Use t.test() to get a p-value
# - Return the fraction of simulations where p < 0.05

sim_power_prop <- function(n_per_arm, effect, baseline = 0.10, nsim = 2000) {
  rejections <- map_lgl(1:nsim, function(i) {
    control <- rbinom(n_per_arm, 1, prob = baseline)
    treated <- rbinom(n_per_arm, 1, prob = _____)
    t.test(treated, control)$p.value < 0.05
  })
  mean(rejections)
}

# Test it:
sim_power_prop(n_per_arm = 1000, effect = 0.03, baseline = 0.10)
# Q1: What power do you get? Is 1,000 per arm enough for a 3pp lift on 10%?

# --- 2. Power curves ----------------------------------------------------------

# Generate a power curve: power as a function of sample size for a fixed effect.

sample_sizes <- c(100, 250, 500, 1000, 2000, 5000, 10000)

power_curve <- tibble(
  n_per_arm = sample_sizes,
  power = map_dbl(sample_sizes, ~ sim_power_prop(.x, effect = 0.02))
)

ggplot(power_curve, aes(n_per_arm, power)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "firebrick") +
  scale_x_continuous(labels = scales::comma) +
  labs(title = "Power curve: 2pp lift on 10% baseline",
       x = "Sample size per arm", y = "Power")

# Q2: At what sample size do you reach 80% power?

# --- 3. MDE curve -------------------------------------------------------------

# Now fix the sample size and vary the effect size to find the MDE.

effects <- seq(0.005, 0.05, by = 0.005)
mde_curve <- tibble(
  effect = effects,
  power = map_dbl(effects, ~ sim_power_prop(n_per_arm = 3000, effect = .x))
)

ggplot(mde_curve, aes(effect, power)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "firebrick") +
  scale_x_continuous(labels = scales::percent) +
  labs(title = "MDE curve: What effect can 3,000 per arm detect?",
       x = "True effect size", y = "Power")

# Q3: What is the approximate MDE for n = 3,000 per arm?
#     Does this make sense given the formula?

# --- 4. Clustering kills power -------------------------------------------------

# Simulate a cluster-randomized experiment.

sim_power_cluster <- function(n_clusters_per_arm, n_per_cluster, effect,
                              icc = 0.05, nsim = 1000) {
  total_clusters <- 2 * n_clusters_per_arm
  rejections <- map_lgl(1:nsim, function(i) {
    cluster_id <- rep(1:total_clusters, each = n_per_cluster)
    treatment <- rep(rep(c(0, 1), each = n_clusters_per_arm),
                     each = n_per_cluster)
    # Cluster random effect
    sigma_b <- sqrt(icc / (1 - icc))
    cluster_effect <- rep(rnorm(total_clusters, 0, sd = sigma_b),
                          each = n_per_cluster)
    y <- treatment * effect + cluster_effect + rnorm(_____, sd = 1)
    df <- data.frame(y = y, treatment = treatment, cluster = cluster_id)
    # Q4: Why do we need cluster-robust standard errors here?
    #     What happens if we use regular OLS standard errors?
    coef(summary(lm(y ~ treatment, data = df)))["treatment", "Pr(>|t|)"] < 0.05
  })
  mean(rejections)
}

# Compare: same total N = 2000, individual vs clustered
cat("Individual randomization (n=1000/arm):\n")
sim_power_prop(n_per_arm = 1000, effect = 0.05, baseline = 0.50)

cat("\nCluster randomization (20 clusters of 50/arm):\n")
sim_power_cluster(n_clusters_per_arm = 10, n_per_cluster = 50,
                  effect = 0.15, icc = 0.05)

# Q5: How much power did you lose from clustering? Why?

# --- 5. Design effect and effective sample size --------------------------------

# Compute the design effect for different scenarios
design_effect <- function(m, icc) {
  1 + (m - 1) * icc
}

# Q6: Fill in the table
scenarios <- tibble(
  cluster_size = c(10, 50, 100, 500),
  icc = 0.05,
  deff = map_dbl(cluster_size, ~ design_effect(.x, 0.05)),
  effective_n_per_1000 = _____  # total N = 1000, what's effective n?
)
print(scenarios)

# Q7: With 20 cities of 500 drivers each and ICC = 0.08, what is the
#     effective sample size per arm?
n_cities_per_arm <- 10
drivers_per_city <- 500
icc <- 0.08
deff <- design_effect(drivers_per_city, icc)
effective_n <- _____
cat("Design effect:", deff, "\n")
cat("Effective n per arm:", round(effective_n), "\n")

# --- 6. More clusters vs bigger clusters --------------------------------------

# Fix total N = 4000. Vary the split between clusters and cluster size.

configs <- tibble(
  n_clusters_per_arm = c(5, 10, 20, 50, 100),
  n_per_cluster = 4000 / (2 * n_clusters_per_arm)
)

configs <- configs |>
  mutate(
    power = map2_dbl(n_clusters_per_arm, n_per_cluster,
                     ~ sim_power_cluster(.x, .y, effect = 0.2,
                                          icc = 0.05, nsim = 500))
  )

ggplot(configs, aes(n_clusters_per_arm, power)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "firebrick") +
  labs(title = "Total N = 4,000 (fixed). How should you split clusters?",
       x = "Number of clusters per arm",
       y = "Power")

# Q8: What's the optimal split? Why does this make sense given the design
#     effect formula?

# --- 7. Covariates reduce variance (power boost) ------------------------------

# Simulate the power gain from including a pre-treatment covariate.

sim_power_covariate <- function(n_per_arm, effect, r_squared, nsim = 1000) {
  rejections <- map_lgl(1:nsim, function(i) {
    n_total <- 2 * n_per_arm
    x_pre <- rnorm(n_total)
    treat <- rep(c(0, 1), each = n_per_arm)
    y <- sqrt(r_squared) * x_pre + treat * effect +
         rnorm(n_total, sd = sqrt(1 - r_squared))
    coef(summary(lm(y ~ treat + x_pre)))[2, 4] < 0.05
  })
  mean(rejections)
}

# Compare power with and without covariate
r2_values <- c(0, 0.1, 0.2, 0.3, 0.5)
covariate_comparison <- tibble(
  r_squared = r2_values,
  power = map_dbl(r2_values, ~ sim_power_covariate(
    n_per_arm = 500, effect = 0.15, r_squared = .x))
)

ggplot(covariate_comparison, aes(r_squared, power)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "firebrick") +
  labs(title = "Power boost from pre-treatment covariates",
       subtitle = "n = 500 per arm, effect = 0.15",
       x = "Covariate R-squared", y = "Power")

# Q9: A covariate with R^2 = 0.3 gives you how much of a power boost?
#     How many MORE users would you need to get the same boost without the
#     covariate?

# Q10: In a ride-sharing experiment, what pre-treatment covariates might
#      have high R^2 with the outcome (driver earnings)?
#
# Your answer:
# _____
