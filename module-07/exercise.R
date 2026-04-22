# ============================================================================
# Module 7 Exercise: External Validity & Generalizability
# ============================================================================
#
# Simulate treatment effect heterogeneity across sites and show when
# extrapolation fails.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. Simulate heterogeneous treatment effects across sites ---------------

n_sites <- 30
n_per_site <- 200

# Each site has a characteristic (e.g., market maturity, supply/demand ratio)
# The treatment effect depends on this characteristic
site_info <- tibble(
  site = 1:n_sites,
  characteristic = runif(n_sites, 0, 2),
  # True CATE: effect is larger for sites with higher characteristic
  true_cate = 2 * characteristic + rnorm(n_sites, sd = 0.3)
)

# Generate individual-level data for all sites
all_data <- map_dfr(1:n_sites, function(s) {
  info <- site_info |> filter(site == s)
  tibble(
    site = s,
    characteristic = info$characteristic,
    true_cate = info$true_cate,
    treated = sample(c(0, 1), n_per_site, replace = TRUE),
    y = 5 + info$true_cate * treated + rnorm(n_per_site, sd = 3)
  )
})

# Q1: What is the population ATE (average across all sites)?
pop_ate <- mean(site_info$true_cate)
cat("Population ATE:", round(pop_ate, 3), "\n")

# Q2: What is the range of site-specific effects?
cat("Min site effect:", round(min(site_info$true_cate), 3), "\n")
cat("Max site effect:", round(max(site_info$true_cate), 3), "\n")

# Visualize
ggplot(site_info, aes(characteristic, true_cate)) +
  geom_point(size = 3, color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "firebrick",
              linetype = "dashed") +
  labs(title = "Treatment effect varies by site characteristic",
       x = "Site characteristic", y = "True CATE")

# --- 2. Site selection bias -------------------------------------------------

# Experiment ran in the 5 sites with the HIGHEST characteristic value
# (e.g., company chose its most mature/developed markets)
experimental_sites <- site_info |>
  arrange(desc(characteristic)) |>
  slice(1:5) |>
  pull(site)

exp_data <- all_data |> filter(site %in% experimental_sites)

# Estimate ATE from the experiment
exp_ate <- mean(exp_data$y[exp_data$treated == 1]) -
  mean(exp_data$y[exp_data$treated == 0])

cat("\nExperimental ATE (biased site selection):", round(exp_ate, 3), "\n")
cat("Population ATE:", round(pop_ate, 3), "\n")
cat("Bias:", round(exp_ate - pop_ate, 3), "\n")

# Q3: Why is the experimental ATE higher than the population ATE?
#     Your answer: _____

# --- 3. Transportability via reweighting ------------------------------------

# If we know the effect modifier (characteristic) and can model the
# CATE as a function of it, we can reweight to the target population.

# Step 1: Estimate CATE(x) from experimental data
# (Use site-level estimates + regression on characteristic)
site_estimates <- exp_data |>
  group_by(site, characteristic) |>
  summarise(
    est_cate = mean(y[treated == 1]) - mean(y[treated == 0]),
    .groups = "drop"
  )

# Fit a model of effect as a function of characteristic
cate_model <- lm(est_cate ~ characteristic, data = site_estimates)
cat("\nCATE model from experimental sites:\n")
print(summary(cate_model)$coefficients)

# Step 2: Predict effects for ALL sites using their characteristics
site_info <- site_info |>
  mutate(predicted_cate = predict(cate_model, newdata = site_info))

# Step 3: Compute transported ATE (average predicted CATE across all sites)
transported_ate <- mean(site_info$predicted_cate)

cat("\nTransported ATE:", round(transported_ate, 3), "\n")
cat("Population ATE:", round(pop_ate, 3), "\n")
cat("Naive experimental ATE:", round(exp_ate, 3), "\n")

# Q4: Is the transported ATE closer to the population ATE than the naive
#     experimental ATE?
#     Your answer: _____

# --- 4. When transportability fails -----------------------------------------

# Now simulate a non-linear relationship that the linear model can't capture
set.seed(99)
site_info_nl <- tibble(
  site = 1:n_sites,
  characteristic = runif(n_sites, 0, 2),
  # Non-linear: effect peaks at characteristic = 1, then declines
  true_cate = 3 * sin(characteristic * pi / 2) + rnorm(n_sites, sd = 0.2)
)

all_data_nl <- map_dfr(1:n_sites, function(s) {
  info <- site_info_nl |> filter(site == s)
  tibble(
    site = s, characteristic = info$characteristic,
    treated = sample(c(0, 1), n_per_site, replace = TRUE),
    y = 5 + info$true_cate * treated + rnorm(n_per_site, sd = 3)
  )
})

# Experiment only in low-characteristic sites (< 0.8)
exp_sites_nl <- site_info_nl |> filter(characteristic < 0.8) |> pull(site)
exp_data_nl <- all_data_nl |> filter(site %in% exp_sites_nl)

site_est_nl <- exp_data_nl |>
  group_by(site, characteristic) |>
  summarise(est_cate = mean(y[treated == 1]) - mean(y[treated == 0]),
            .groups = "drop")

# Fit linear model and extrapolate
cate_model_nl <- lm(est_cate ~ characteristic, data = site_est_nl)
site_info_nl <- site_info_nl |>
  mutate(predicted_cate = predict(cate_model_nl, newdata = site_info_nl))

cat("\nNon-linear case:\n")
cat("  Pop ATE:", round(mean(site_info_nl$true_cate), 3), "\n")
cat("  Experiment ATE:", round(mean(site_est_nl$est_cate), 3), "\n")
cat("  Transported ATE (linear model):", round(mean(site_info_nl$predicted_cate), 3), "\n")

# Q5: Why does transportability fail here?
#     Your answer: _____

# Visualize the failure
ggplot(site_info_nl, aes(characteristic, true_cate)) +
  geom_point(size = 3, color = "steelblue") +
  geom_line(aes(y = predicted_cate), color = "firebrick",
            linewidth = 1, linetype = "dashed") +
  geom_vline(xintercept = 0.8, linetype = "dotted") +
  annotate("text", x = 0.4, y = -1, label = "Experiment range") +
  annotate("text", x = 1.4, y = -1, label = "Extrapolation zone") +
  labs(title = "Linear extrapolation fails with non-linear treatment effects",
       x = "Site characteristic", y = "Treatment effect")

# --- 5. Novelty effects: experiment duration matters ------------------------

set.seed(42)
n <- 5000

# True effect decays exponentially
# tau(t) = tau_inf + (tau_0 - tau_inf) * exp(-lambda * t)
tau_0 <- 5       # initial effect (with novelty)
tau_inf <- 1     # long-run effect
lambda <- 0.15   # decay rate

weeks <- 1:24
true_effect <- tau_inf + (tau_0 - tau_inf) * exp(-lambda * weeks)

# Simulate weekly estimates with noise
weekly_estimates <- tibble(
  week = weeks,
  true = true_effect,
  estimated = true_effect + rnorm(24, sd = 0.4)
)

# What you'd conclude from experiments of different lengths
exp_lengths <- c(2, 4, 8, 16, 24)
duration_estimates <- map_dfr(exp_lengths, function(w) {
  tibble(
    duration = paste0(w, " weeks"),
    weeks = w,
    estimated_ate = mean(weekly_estimates$estimated[1:w]),
    true_longrun = tau_inf
  )
})

cat("\nEffect estimates by experiment duration:\n")
print(duration_estimates)

# Q6: A 2-week experiment estimates the effect at _____.
#     The true long-run effect is _____.
#     How wrong is the 2-week estimate?

# Visualize
ggplot(weekly_estimates, aes(week, estimated)) +
  geom_point(color = "steelblue") +
  geom_line(aes(y = true), color = "firebrick", linewidth = 1) +
  geom_hline(yintercept = tau_inf, linetype = "dotted") +
  annotate("text", x = 20, y = tau_inf + 0.3, label = "Long-run effect") +
  labs(title = "Novelty effect: the experiment overstates long-run impact",
       x = "Week", y = "Treatment effect")

# --- 6. Multi-site vs single-site design ------------------------------------

# Compare: (a) all budget in 1 site, (b) spread across 10 sites
set.seed(42)
total_n <- 2000

# (a) Single site (the best one)
best_site <- site_info |> arrange(desc(true_cate)) |> slice(1)
single_site_est <- map_dbl(1:500, function(iter) {
  y_t <- rnorm(total_n/2, mean = 5 + best_site$true_cate)
  y_c <- rnorm(total_n/2, mean = 5)
  mean(y_t) - mean(y_c)
})

# (b) 10 sites, 200 per site
multi_sites <- site_info |> sample_n(10)
multi_site_est <- map_dbl(1:500, function(iter) {
  effects <- map_dbl(1:10, function(s) {
    cate <- multi_sites$true_cate[s]
    y_t <- rnorm(100, mean = 5 + cate)
    y_c <- rnorm(100, mean = 5)
    mean(y_t) - mean(y_c)
  })
  mean(effects)  # average across sites
})

cat("\nSingle-site design:\n")
cat("  Mean estimate:", round(mean(single_site_est), 3), "\n")
cat("  SD:", round(sd(single_site_est), 3), "\n")

cat("Multi-site design:\n")
cat("  Mean estimate:", round(mean(multi_site_est), 3), "\n")
cat("  SD:", round(sd(multi_site_est), 3), "\n")

cat("Population ATE:", round(pop_ate, 3), "\n")

# Q7: Which design gives an estimate closer to the population ATE?
#     Which is more precise (lower SD)?
#     What is the tradeoff?
#
# Your answer:
# _____

# --- 7. Bonus: build your own transportability estimator --------------------

# Q8: Using the linear CATE model from section 3, write a function that
#     takes a target population's characteristic distribution and returns
#     the transported ATE.

transport_ate <- function(target_characteristics, cate_model) {
  predicted <- predict(cate_model, newdata = data.frame(
    characteristic = _____
  ))
  mean(predicted)
}

# Test it: what's the predicted ATE for a population with characteristics
# uniformly distributed on [0, 0.5] (low-characteristic markets)?
low_char <- runif(1000, 0, 0.5)
cat("\nTransported ATE for low-characteristic markets:",
    round(transport_ate(low_char, cate_model), 3), "\n")

# Compare to high-characteristic markets [1.5, 2]
high_char <- runif(1000, 1.5, 2)
cat("Transported ATE for high-characteristic markets:",
    round(transport_ate(high_char, cate_model), 3), "\n")

# Q9: Why is the transported ATE so different for the two populations?
#
# Your answer:
# _____
