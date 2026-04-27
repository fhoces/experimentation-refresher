# ============================================================================
# Module 3 Exercise: Designing Around Interference
# ============================================================================
#
# Setup: same zone-notification experiment as Modules 1-2, now run across
# 40 cities of 50 drivers each. Within each city, notified drivers compete
# with non-notified ones for rides; non-notified drivers' accept rate
# drops in proportion to the share treated.
#
# Compare individual vs cluster randomization, sweep cluster sizes, and
# explore the bias-variance tradeoff. Then a switchback design with carryover.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. Setup: A Marketplace Across Cities -----------------------------------

n_cities <- 40
drivers_per_city <- 5000
n_total <- n_cities * drivers_per_city
interference_strength <- 0.10   # control's accept rate drops by this * frac_treated

# Generate drivers nested in cities
market <- tibble(
  driver_id = 1:n_total,
  city_id = rep(1:n_cities, each = drivers_per_city),
  experience = rnorm(n_total),
  city_effect = rep(rnorm(n_cities, 0, 0.05), each = drivers_per_city)
)

# True direct effect (LPM coefficient on D from Modules 1-2)
true_ate <- 0.05
cat("True ATE (direct effect):", round(true_ate, 3), "\n")

# --- 2. Individual Randomization (with interference) -------------------------

sim_individual <- function(data, interference = 0.10) {
  data <- data |>
    mutate(notification = sample(rep(c(0, 1), each = n() / 2)))

  # Within-city interference: control drivers' y0 drops as more are notified
  data <- data |>
    group_by(city_id) |>
    mutate(
      frac_treated_city = mean(notification),
      y0 = pmin(1, pmax(0, 0.4 + 0.2 * experience + city_effect -
                              interference * frac_treated_city)),
      y1 = pmin(1, pmax(0, 0.4 + 0.2 * experience + city_effect + 0.05))
    ) |>
    ungroup() |>
    mutate(y_obs = rbinom(n(), 1, prob = if_else(notification == 1, y1, y0)))

  mean(data$y_obs[data$notification == 1]) -
    mean(data$y_obs[data$notification == 0])
}

individual_ests <- replicate(100, sim_individual(market))
cat("\nIndividual randomization:\n")
cat("  Mean ATE:", round(mean(individual_ests), 3), "\n")
cat("  SD:", round(sd(individual_ests), 3), "\n")
cat("  Bias:", round(mean(individual_ests) - true_ate, 3), "\n")

# Q1: Is the individual-level estimate biased? In which direction? Why?
#     (Hint: in a 50/50 city, control's y0 drops by interference * 0.5,
#      so the gap treated - control opens up beyond the direct effect.)

# --- 3. City-Level Cluster Randomization --------------------------------------

sim_cluster <- function(data) {
  # Randomize at the CITY level
  city_arms <- tibble(
    city_id = 1:n_cities,
    notification = sample(rep(c(0, 1), each = n_cities / 2))
  )

  data <- data |>
    select(driver_id, city_id, experience, city_effect) |>
    left_join(city_arms, by = "city_id") |>
    mutate(
      # No within-city mixing: every driver in a city has the same status,
      # so no rides are stolen across arms within a city.
      y0 = pmin(1, pmax(0, 0.4 + 0.2 * experience + city_effect)),
      y1 = pmin(1, pmax(0, 0.4 + 0.2 * experience + city_effect + 0.05)),
      y_obs = rbinom(n(), 1, prob = if_else(notification == 1, y1, y0))
    )

  mean(data$y_obs[data$notification == 1]) -
    mean(data$y_obs[data$notification == 0])
}

cluster_ests <- replicate(100, sim_cluster(market))
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

sim_varying_clusters <- function(n_clusters) {
  cities_per_cluster <- n_cities / n_clusters
  cluster_arms <- tibble(
    cluster_id = 1:n_clusters,
    notification = sample(rep(c(0, 1), each = n_clusters / 2))
  )

  data <- market |>
    mutate(cluster_id = ceiling(city_id / cities_per_cluster)) |>
    left_join(cluster_arms, by = "cluster_id")

  # Within-cluster mixing diminishes as clusters get larger:
  # the share of within-cluster mixing scales with (1 / cluster_size).
  data <- data |>
    group_by(cluster_id) |>
    mutate(
      frac_treated_cluster = mean(notification),
      # residual interference scales with how much within-cluster mixing remains
      mixing_factor = (n_clusters / n_cities),
      y0 = pmin(1, pmax(0, 0.4 + 0.2 * experience + city_effect -
                              interference_strength * frac_treated_cluster *
                              mixing_factor)),
      y1 = pmin(1, pmax(0, 0.4 + 0.2 * experience + city_effect + 0.05))
    ) |>
    ungroup() |>
    mutate(y_obs = rbinom(n(), 1, prob = if_else(notification == 1, y1, y0)))

  mean(data$y_obs[data$notification == 1]) -
    mean(data$y_obs[data$notification == 0])
}

# Q4: Fill in the blank with cluster sizes that divide 40 evenly
cluster_sizes <- c(40, 20, 10, 8, 4, 2)

tradeoff <- map_dfr(cluster_sizes, function(nc) {
  ests <- replicate(100, sim_varying_clusters(nc))
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

# Alternate notification on/off across 20 time periods in 10 cities.

sim_switchback <- function(n_periods = 20, n_sw_cities = 10,
                           carryover = 0) {
  design <- expand_grid(
    city_id = 1:n_sw_cities,
    period = 1:n_periods
  ) |>
    mutate(
      notification = sample(c(0, 1), n(), replace = TRUE),
      city_effect = rep(rnorm(n_sw_cities, 0, 0.05), times = n_periods),
      period_effect = rep(rnorm(n_periods, 0, 0.02), each = n_sw_cities)
    )

  # Add carryover: previous period's notification leaks into current period
  design <- design |>
    group_by(city_id) |>
    mutate(prev_notif = lag(notification, default = 0),
           carryover_effect = carryover * prev_notif) |>
    ungroup() |>
    mutate(
      y = pmin(1, pmax(0, 0.4 + city_effect + period_effect +
                            0.05 * notification + carryover_effect)) +
            rnorm(n(), 0, 0.02)
    )

  mean(design$y[design$notification == 1]) -
    mean(design$y[design$notification == 0])
}

sw_no_carry <- replicate(100, sim_switchback(carryover = 0))
sw_carry    <- replicate(100, sim_switchback(carryover = 0.05))

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
# (a) A zone-notification experiment in 10 cities (the M1-M2 setup)?
# (b) An ad campaign incrementality test (50 DMAs)?
# (c) A network spillover experiment (the M2 author-nudge setup)?
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

# Q10: For a zone-notification experiment with 10,000 drivers across 50 cities
#      (200 per city), and ICC = 0.05, what is the effective sample size?
#      Is that enough to detect a 3 percentage point effect?
#
# Your answer:
# _____
