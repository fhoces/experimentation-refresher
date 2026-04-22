# ============================================================================
# Module 8 Exercise: Advanced Topics for Tech Interviews
# ============================================================================
#
# Implement Thompson Sampling, demonstrate peeking problems, build a
# simple sequential test, and construct a basic synthetic control.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. Thompson Sampling Bandit ---------------------------------------------

# Setup: 3 arms with unknown conversion rates
true_rates <- c(A = 0.10, B = 0.13, C = 0.09)
n_rounds <- 2000

# Initialize Beta priors (uniform)
alpha_prior <- c(A = 1, B = 1, C = 1)
beta_prior <- c(A = 1, B = 1, C = 1)

# Storage
ts_choices <- character(n_rounds)
ts_rewards <- numeric(n_rounds)

# Q1: Implement Thompson Sampling
for (i in 1:n_rounds) {
  # Draw from posterior for each arm
  draws <- rbeta(3, _____, _____)

  # Choose the arm with the highest draw
  chosen <- _____

  # Simulate reward
  reward <- rbinom(1, 1, true_rates[chosen])

  # Update posterior
  alpha_prior[chosen] <- alpha_prior[chosen] + _____
  beta_prior[chosen] <- beta_prior[chosen] + _____

  ts_choices[i] <- names(true_rates)[chosen]
  ts_rewards[i] <- reward
}

# Check: what fraction went to each arm?
table(ts_choices) / n_rounds

# Q2: Compare to fixed A/B/C test (equal allocation)
fixed_choices <- sample(rep(c("A", "B", "C"), length.out = n_rounds))
fixed_rewards <- rbinom(n_rounds, 1, true_rates[fixed_choices])

# Compute cumulative regret for both
best_rate <- max(true_rates)

ts_regret <- cumsum(best_rate - true_rates[ts_choices])
fixed_regret <- cumsum(best_rate - true_rates[fixed_choices])

# Q3: Plot cumulative regret
regret_df <- tibble(
  round = rep(1:n_rounds, 2),
  regret = c(ts_regret, fixed_regret),
  method = rep(c("Thompson Sampling", "Fixed allocation"), each = n_rounds)
)

ggplot(regret_df, aes(round, regret, color = method)) +
  geom_line(linewidth = 1) +
  labs(title = "Cumulative regret: bandit vs fixed allocation",
       x = "Round", y = "Cumulative regret", color = "")

# Q4: At round 2000, how much less regret does Thompson Sampling have?
#     Why does fixed allocation regret grow linearly?
# Your answer: _____


# --- 2. Peeking Inflates False Positives -------------------------------------

# Simulate A/A tests (NO true effect) with repeated peeking

n_sims <- 2000
n_obs <- 500
peek_schedule <- seq(50, n_obs, by = 50)  # peek every 50 obs

# Q5: Run simulation — for each A/A test, check if we EVER get p < 0.05
peeking_results <- replicate(n_sims, {
  x <- rnorm(n_obs, mean = 0, sd = 1)   # arm A
  y <- rnorm(n_obs, mean = 0, sd = 1)   # arm B (same!)

  # Check at each peek time
  p_values <- sapply(peek_schedule, function(k) {
    t.test(x[1:k], y[1:k])$p.value
  })

  # Did we EVER reject?
  any(p_values < 0.05)
})

cat("False positive rate with peeking:", mean(peeking_results), "\n")

# Q6: Compare to testing only at the end
no_peek_results <- replicate(n_sims, {
  x <- rnorm(n_obs)
  y <- rnorm(n_obs)
  t.test(x, y)$p.value < 0.05
})

cat("False positive rate without peeking:", mean(no_peek_results), "\n")

# Q7: How does the false positive rate change with the number of peeks?
peek_counts <- c(1, 2, 5, 10, 20, 50)

fpr_by_peeks <- sapply(peek_counts, function(n_peeks) {
  peek_times <- round(seq(50, n_obs, length.out = n_peeks))

  mean(replicate(1000, {
    x <- rnorm(n_obs)
    y <- rnorm(n_obs)
    p_vals <- sapply(peek_times, function(k) t.test(x[1:k], y[1:k])$p.value)
    any(p_vals < 0.05)
  }))
})

tibble(n_peeks = peek_counts, false_positive_rate = fpr_by_peeks) |>
  ggplot(aes(n_peeks, false_positive_rate)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3) +
  geom_hline(yintercept = 0.05, linetype = "dashed", color = "firebrick") +
  annotate("text", x = 30, y = 0.06, label = "Nominal alpha = 0.05",
           color = "firebrick") +
  labs(title = "More peeks = higher false positive rate",
       x = "Number of peeks", y = "False positive rate")

# Q8: Why does peeking inflate false positives? What's the intuition?
# Your answer: _____


# --- 3. Simple Group Sequential Boundary -------------------------------------

# Implement a Pocock-like correction: use the same adjusted alpha at each look
# so that the overall Type I error is approximately 0.05.

n_looks <- 5
# Q9: The Bonferroni correction uses alpha/n_looks at each look.
#     This is conservative. What's the adjusted alpha?
adjusted_alpha <- _____

# Simulate: does this control the overall false positive rate?
seq_results <- replicate(2000, {
  x <- rnorm(n_obs)
  y <- rnorm(n_obs)
  look_times <- round(seq(n_obs / n_looks, n_obs, length.out = n_looks))

  p_values <- sapply(look_times, function(k) t.test(x[1:k], y[1:k])$p.value)
  any(p_values < adjusted_alpha)
})

cat("FPR with Bonferroni sequential:", mean(seq_results), "\n")
# Q10: Is this below 0.05? Why is it conservative (below, not exactly 0.05)?
# Your answer: _____

# Now compare power: does the sequential design detect a TRUE effect?
true_effect <- 0.2

seq_power <- mean(replicate(2000, {
  x <- rnorm(n_obs, mean = 0)
  y <- rnorm(n_obs, mean = true_effect)
  look_times <- round(seq(n_obs / n_looks, n_obs, length.out = n_looks))
  p_values <- sapply(look_times, function(k) t.test(x[1:k], y[1:k])$p.value)
  any(p_values < adjusted_alpha)
}))

fixed_power <- mean(replicate(2000, {
  x <- rnorm(n_obs)
  y <- rnorm(n_obs, mean = true_effect)
  t.test(x, y)$p.value < 0.05
}))

cat("Power (sequential):", round(seq_power, 3), "\n")
cat("Power (fixed):", round(fixed_power, 3), "\n")
# Q11: Which has higher power? Why?
# Your answer: _____


# --- 4. Basic Synthetic Control -----------------------------------------------

# Simulate: 1 treated city + 8 donor cities, 20 time periods, treatment at t=11
n_cities <- 9
n_time <- 20
treat_time <- 11
true_effect <- -2.0

# City-specific levels and common time trend
city_levels <- c(5, 3, 4, 6, 2, 3.5, 4.5, 5.5, 2.5)
time_trend <- seq(0, 2, length.out = n_time)

# Generate data
synth_data <- expand_grid(city = 1:n_cities, time = 1:n_time) |>
  mutate(
    y_clean = city_levels[city] + time_trend[time],
    noise = rnorm(n(), 0, 0.3),
    treatment = if_else(city == 1 & time >= treat_time, true_effect, 0),
    y = y_clean + noise + treatment
  )

# Q12: Construct synthetic control weights using pre-treatment data
pre_data <- synth_data |>
  filter(time < treat_time) |>
  select(city, time, y) |>
  pivot_wider(names_from = city, values_from = y)

y_treated <- pre_data$`1`
X_donors <- as.matrix(pre_data[, paste0(2:n_cities)])

# Fit weights via OLS (simplified — real SC uses constrained optimization)
raw_weights <- coef(lm(y_treated ~ X_donors - 1))
raw_weights[raw_weights < 0] <- 0
weights <- raw_weights / sum(raw_weights)

cat("Synthetic control weights:\n")
print(round(weights, 3))

# Q13: Compute the synthetic control outcome for all time periods
all_wide <- synth_data |>
  select(city, time, y) |>
  pivot_wider(names_from = city, values_from = y)

synth_outcome <- as.matrix(all_wide[, paste0(2:n_cities)]) %*% _____

# Q14: Estimate the treatment effect (gap between treated and synthetic)
gap <- all_wide$`1` - as.numeric(synth_outcome)
post_gap <- mean(gap[treat_time:n_time])
cat("Estimated effect:", round(post_gap, 2), "\n")
cat("True effect:", true_effect, "\n")

# Q15: Plot treated vs synthetic control
plot_df <- tibble(
  time = rep(1:n_time, 2),
  y = c(all_wide$`1`, as.numeric(synth_outcome)),
  series = rep(c("Treated", "Synthetic control"), each = n_time)
)

ggplot(plot_df, aes(time, y, color = series)) +
  geom_line(linewidth = 1.2) +
  geom_vline(xintercept = treat_time - 0.5, linetype = "dashed") +
  labs(title = "Synthetic Control: treated city vs constructed counterfactual",
       x = "Time", y = "Outcome", color = "")

# Q16: How well does the synthetic control fit in the pre-treatment period?
#      What would a poor pre-treatment fit tell you about the estimate?
# Your answer: _____


# --- 5. Bonus: Bandit Inference Problem --------------------------------------

# Q17: Run an A/B test AND a Thompson Sampling bandit on the SAME problem
#      (true_rates from section 1). Compute the estimated treatment effect
#      (B - A) under both designs. Which gives a more accurate estimate?

# Fixed A/B
n_ab <- 2000
ab_a <- rbinom(n_ab / 2, 1, true_rates["A"])
ab_b <- rbinom(n_ab / 2, 1, true_rates["B"])
ab_estimate <- mean(ab_b) - mean(ab_a)

# Bandit estimate (using data from section 1)
bandit_a_rewards <- ts_rewards[ts_choices == "A"]
bandit_b_rewards <- ts_rewards[ts_choices == "B"]
bandit_estimate <- mean(bandit_b_rewards) - mean(bandit_a_rewards)

cat("True B - A:", true_rates["B"] - true_rates["A"], "\n")
cat("A/B estimate:", round(ab_estimate, 4), "\n")
cat("Bandit estimate:", round(bandit_estimate, 4), "\n")

# Q18: Why is the bandit estimate potentially biased? Think about which
#      observations of arm A are collected early vs late in the experiment.
# Your answer: _____
