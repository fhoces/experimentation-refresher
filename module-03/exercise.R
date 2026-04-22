# ============================================================================
# Module 3 Exercise: Designing Around Interference
# ============================================================================
#
# Compare individual vs cluster randomization in a simulated marketplace.
# Show the bias-variance tradeoff as cluster size varies.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. Setup: A Marketplace Across Cities -----------------------------------

n_cities <- 40
drivers_per_city <- 50
n_total <- n_cities * drivers_per_city
interference_strength <- 0.3

# Generate drivers nested in cities
market <- tibble(
  driver_id = 1:n_total,
  city_id = rep(1:n_cities, each = drivers_per_city),
  skill = rnorm(n_total),
  city_effect = rep(rnorm(n_cities, 0, 0.3), each = drivers_per_city)
)

# True ATE without interference
true_ate <- mean(plogis(-0.5 + 0.3 * market$skill + market$city_effect + 0.5) -
                   plogis(-0.5 + 0.3 * market$skill + market$city_effect))
cat("True ATE (direct effect):", round(true_ate, 3), "\n")

# --- 2. Individual Randomization (with interference) -------------------------

sim_individual <- function(data, interference = 0.3) {
  data <- data |>
    mutate(bonus = sample(rep(c(0, 1), each = n() / 2)))

  # Within-city interference: control drivers harmed by treated drivers
  data <- data |>
    group_by(city_id) |>
    mutate(
      frac_treated_city = mean(bonus),
      interf = -interference * frac_treated_city * (1 - bonus)
    ) |>
    ungroup()

  data <- data |>
    mutate(y = rbinom(n(), 1, prob = plogis(-0.5 + 0.3 * skill +
                                              city_effect + 0.5 * bonus + interf)))

  mean(data$y[data$bonus == 1]) - mean(data$y[data$bonus == 0])
}

individual_ests <- replicate(500, sim_individual(market))
cat("\nIndividual randomization:\n")
cat("  Mean ATE:", round(mean(individual_ests), 3), "\n")
cat("  SD:", round(sd(individual_ests), 3), "\n")
cat("  Bias:", round(mean(individual_ests) - true_ate, 3), "\n")

# Q1: Is the individual-level estimate biased? In which direction?

# --- 3. City-Level Cluster Randomization --------------------------------------

sim_cluster <- function(data, interference = 0.3) {
  # Randomize at the CITY level
  city_arms <- tibble(
    city_id = 1:n_cities,
    bonus = sample(rep(c(0, 1), each = n_cities / 2))
  )

  data <- data |>
    select(-any_of(c("bonus", "frac_treated_city", "interf", "y"))) |>
    left_join(city_arms, by = "city_id")

  # Within-city interference still happens, but now all drivers in a city
  # have the SAME treatment -> no within-city interference!
  data <- data |>
    group_by(city_id) |>
    mutate(
      frac_treated_city = mean(bonus),
      # Between-city interference (much smaller, assume negligible)
      interf = 0
    ) |>
    ungroup()

  data <- data |>
    mutate(y = rbinom(n(), 1, prob = plogis(-0.5 + 0.3 * skill +
                                              city_effect + 0.5 * bonus + interf)))

  mean(data$y[data$bonus == 1]) - mean(data$y[data$bonus == 0])
}

cluster_ests <- replicate(500, sim_cluster(market))
cat("\nCluster (city-level) randomization:\n")
cat("  Mean ATE:", round(mean(cluster_ests), 3), "\n")
cat("  SD:", round(sd(cluster_ests), 3), "\n")
cat("  Bias:", round(mean(cluster_ests) - true_ate, 3), "\n")

# Q2: How does the bias compare to individual randomization?
#     How does the variance compare? Why?
#
# Your answer:
# _____

# --- 4. The Bias-Variance Tradeoff -------------------------------------------

# Q3: What happens as we vary cluster size? Bigger clusters = less interference
#     (good) but fewer independent clusters (bad for variance).

# Simulate different "cluster sizes" by grouping cities into mega-clusters
sim_varying_clusters <- function(n_clusters) {
  # Divide 40 cities into n_clusters groups
  cities_per_cluster <- n_cities / n_clusters
  cluster_arms <- tibble(
    cluster_id = 1:n_clusters,
    bonus = sample(rep(c(0, 1), each = n_clusters / 2))
  )

  data <- market |>
    mutate(cluster_id = ceiling(city_id / cities_per_cluster)) |>
    left_join(cluster_arms, by = "cluster_id")

  # Within-cluster interference: cities within the same cluster may
  # have some interference (adjacent cities share drivers)
  data <- data |>
    group_by(cluster_id) |>
    mutate(
      frac_treated_cluster = mean(bonus),
      # Residual interference decreases with cluster size
      interf = -interference_strength *
        (1 - frac_treated_cluster) * (1 - bonus) * (n_clusters / n_cities)
    ) |>
    ungroup()

  data <- data |>
    mutate(y = rbinom(n(), 1, prob = plogis(-0.5 + 0.3 * skill +
                                              city_effect + 0.5 * bonus + interf)))

  mean(data$y[data$bonus == 1]) - mean(data$y[data$bonus == 0])
}

# Q4: Fill in the blank with cluster sizes that divide 40 evenly
cluster_sizes <- c(40, 20, 10, 8, 4, 2)

tradeoff <- map_dfr(cluster_sizes, function(nc) {
  ests <- replicate(500, sim_varying_clusters(nc))
  tibble(
    n_clusters = nc,
    cities_per_cluster = n_cities / nc,
    mean_ate = mean(ests),
    sd_ate = sd(ests),
    bias = mean(ests) - true_ate,
    rmse = sqrt(mean((ests - true_ate)^2))
  )
})

print(tradeoff)

# Q5: Plot the bias-variance tradeoff
ggplot(tradeoff, aes(cities_per_cluster)) +
  geom_line(aes(y = abs(bias), color = "Absolute bias"), linewidth = 1.2) +
  geom_line(aes(y = sd_ate, color = "Std dev"), linewidth = 1.2) +
  geom_line(aes(y = rmse, color = "RMSE"), linewidth = 1.2, linetype = "dashed") +
  scale_color_manual(values = c("firebrick", "steelblue", "grey40")) +
  labs(title = "Bias-Variance Tradeoff in Cluster Randomization",
       subtitle = "Bigger clusters reduce bias but increase variance",
       x = "Cities per cluster", y = "Value", color = "") +
  theme(legend.position = "top")

# Q6: Where is the RMSE-minimizing cluster size? Is it the biggest or
#     smallest cluster? Why?
#
# Your answer:
# _____

# --- 5. Switchback Design ----------------------------------------------------

# Alternate treatment on/off across 20 time periods in 10 cities.

sim_switchback <- function(n_periods = 20, n_sw_cities = 10,
                           drivers_per = 50, carryover = 0) {
  # Each (city, period) is a cell. Randomize at the cell level.
  design <- expand_grid(
    city_id = 1:n_sw_cities,
    period = 1:n_periods
  ) |>
    mutate(
      # Randomize treatment for each cell
      bonus = sample(c(0, 1), n(), replace = TRUE),
      city_effect = rep(rnorm(n_sw_cities, 0, 0.3), times = n_periods),
      period_effect = rep(rnorm(n_periods, 0, 0.1), each = n_sw_cities)
    )

  # Add carryover: previous period's treatment leaks into current period
  design <- design |>
    group_by(city_id) |>
    mutate(prev_bonus = lag(bonus, default = 0),
           carryover_effect = carryover * prev_bonus) |>
    ungroup()

  # Simulate aggregate outcomes per cell
  design <- design |>
    mutate(
      base_rate = plogis(-0.5 + city_effect + period_effect),
      treated_rate = plogis(-0.5 + city_effect + period_effect + 0.5),
      # Observed rate includes carryover
      y = if_else(bonus == 1, treated_rate, base_rate) + carryover_effect +
        rnorm(n(), 0, 0.03)
    )

  mean(design$y[design$bonus == 1]) - mean(design$y[design$bonus == 0])
}

# No carryover
sw_no_carry <- replicate(500, sim_switchback(carryover = 0))
# With carryover
sw_carry <- replicate(500, sim_switchback(carryover = 0.05))

cat("\nSwitchback design:\n")
cat("  No carryover - Mean ATE:", round(mean(sw_no_carry), 3),
    "SD:", round(sd(sw_no_carry), 3), "\n")
cat("  With carryover - Mean ATE:", round(mean(sw_carry), 3),
    "SD:", round(sd(sw_carry), 3), "\n")

# Q7: How does carryover bias the switchback estimate? Why?
#
# Your answer:
# _____

# --- 6. Comparing Designs Head-to-Head ----------------------------------------

# Q8: Put it all together. Which design would you choose for:
#
# (a) A pricing experiment for a ride-sharing platform (10 cities)?
# (b) An ad campaign incrementality test (50 DMAs)?
# (c) A social network feature experiment (viral mechanics)?
#
# Your answer:
# (a) _____
# (b) _____
# (c) _____

# --- 7. Effective Sample Size and ICC ----------------------------------------

# The design effect formula: n_eff = n / (1 + (m - 1) * rho)
# where m = cluster size and rho = ICC

design_effect <- function(n, m, rho) {
  n_eff <- n / (1 + (m - 1) * rho)
  tibble(n = n, m = m, rho = rho, n_eff = round(n_eff),
         pct_lost = round(100 * (1 - n_eff / n), 1))
}

# Q9: Fill in the ICC values and compute effective sample sizes
scenarios <- bind_rows(
  design_effect(n = 10000, m = 50, rho = 0.01),
  design_effect(n = 10000, m = 50, rho = 0.05),
  design_effect(n = 10000, m = 50, rho = 0.10),
  design_effect(n = 10000, m = 50, rho = 0.20),
  design_effect(n = 10000, m = 250, rho = _____),  # fill in: what ICC makes n_eff = 1000?
  design_effect(n = 10000, m = 500, rho = _____)   # fill in: what ICC makes n_eff = 500?
)

print(scenarios)

# Q10: For a marketplace experiment with 10,000 drivers across 50 cities
#      (200 per city), and ICC = 0.05, what is the effective sample size?
#      Is that enough to detect a 3 percentage point effect on retention?
#
# Your answer:
# _____
