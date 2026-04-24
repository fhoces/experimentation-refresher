# ============================================================================
# Module 1 Exercise: The Experimental Ideal
# ============================================================================
#
# Setup: when a driver is heading into a zone with higher-than-average
# subsequent demand, does a push notification affect their decision to
# accept the next ride offer (and their earnings)?
#
# Simulate potential outcomes, demonstrate selection bias, and show why
# randomization works.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
library(estimatr)
set.seed(42)

# --- 1. Simulate potential outcomes -----------------------------------------

n <- 1000
drivers <- tibble(
  driver_id = 1:n,
  # Unobserved experience (affects both having notifications on and accepting)
  experience = rnorm(n),
  # Potential outcomes — LPM: P(Y=1) = 0.4 + 0.2*experience + 0.05*D, clipped
  y0 = rbinom(n, 1, prob = pmin(1, pmax(0, 0.4 + 0.2 * experience))),
  y1 = rbinom(n, 1, prob = pmin(1, pmax(0, 0.4 + 0.2 * experience + 0.05)))
)

# Q1: What is the true ATE? (We can compute it because we have BOTH potential
#     outcomes — this is the privilege of simulation)
true_ate <- mean(drivers$y1 - drivers$y0)
cat("True ATE:", round(true_ate, 3), "\n")

# Q2: What is the true ATT and ATU if experienced drivers self-select into
#     having notifications enabled?
drivers <- drivers |>
  mutate(self_selected = rbinom(n, 1,
    prob = pmin(1, pmax(0, 0.5 + 0.15 * experience))))

true_att <- mean((drivers$y1 - drivers$y0)[drivers$self_selected == 1])
true_atu <- mean((drivers$y1 - drivers$y0)[drivers$self_selected == 0])
cat("True ATT:", round(true_att, 3), "\n")
cat("True ATU:", round(true_atu, 3), "\n")
# Q3: Are ATE, ATT, ATU the same? Why or why not?

# --- 2. Selection bias ------------------------------------------------------

# Naive comparison using self-selected groups
naive_treated <- mean(drivers$y1[drivers$self_selected == 1])  # observed Y for treated
naive_control <- mean(drivers$y0[drivers$self_selected == 0])  # observed Y for control
naive_estimate <- naive_treated - naive_control
cat("Naive estimate:", round(naive_estimate, 3), "\n")
cat("True ATE:", round(true_ate, 3), "\n")
cat("Bias:", round(naive_estimate - true_ate, 3), "\n")

# Q4: Decompose the naive estimate into ATT + selection bias
selection_bias <- mean(drivers$y0[drivers$self_selected == 1]) -
  mean(drivers$y0[drivers$self_selected == 0])
cat("\nDecomposition:\n")
cat("  ATT:", round(true_att, 3), "\n")
cat("  + Selection bias:", round(selection_bias, 3), "\n")
cat("  = Naive:", round(true_att + selection_bias, 3), "\n")

# Q5: Is the selection bias positive or negative? Why does that make sense?

# --- 3. Randomization eliminates bias in expectation ------------------------

# Run 500 simulated RCTs
sim_rct <- function(i) {
  # Random assignment
  notification <- sample(rep(c(0, 1), each = n/2))
  # Observed outcome depends on assignment
  y_obs <- if_else(notification == 1, drivers$y1, drivers$y0)
  # Simple difference in means
  mean(y_obs[notification == 1]) - mean(y_obs[notification == 0])
}

rct_estimates <- map_dbl(1:500, sim_rct)

cat("\nMean of 500 RCT estimates:", round(mean(rct_estimates), 3), "\n")
cat("True ATE:", round(true_ate, 3), "\n")
cat("SD of estimates:", round(sd(rct_estimates), 3), "\n")

# Q6: Is the mean of the estimates close to the true ATE? Why?

# Visualize
ggplot(tibble(est = rct_estimates), aes(est)) +
  geom_histogram(bins = 40, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = true_ate, color = "firebrick",
             linewidth = 1.2, linetype = "dashed") +
  labs(title = "500 Simulated RCTs",
       x = "Estimated ATE", y = "Count")

# --- 4. Compare randomized vs observational --------------------------------

# Run 500 observational (self-selected) studies
sim_obs <- function(i) {
  prob_notif <- pmin(1, pmax(0, 0.5 + 0.15 * drivers$experience))
  notification <- rbinom(n, 1, prob = prob_notif)
  y_obs <- if_else(notification == 1, drivers$y1, drivers$y0)
  mean(y_obs[notification == 1]) - mean(y_obs[notification == 0])
}

obs_estimates <- map_dbl(1:500, sim_obs)

# Q7: Fill in the blank to create the comparison plot
bind_rows(
  tibble(est = rct_estimates, method = "Randomized"),
  tibble(est = obs_estimates, method = "Observational")
) |>
  ggplot(aes(est, fill = method)) +
  geom_histogram(bins = 40, alpha = 0.6, position = "identity") +
  geom_vline(xintercept = _____, color = "firebrick",
             linewidth = 1.2, linetype = "dashed") +
  labs(title = "Randomized vs Observational",
       x = "Estimated effect", y = "Count")

# Q8: What do you notice about the two distributions?

# --- 5. Breaking SUTVA (preview) -------------------------------------------

# Simple interference: notifying many drivers sends them to the same zone,
# so each notified driver faces more competition there — the treatment effect
# shrinks as the treated share rises.

sim_sutva_violation <- function(frac_treated) {
  notification <- sample(c(rep(1, n * frac_treated),
                           rep(0, n * (1 - frac_treated))))
  # Interference: notified drivers crowd the zone; effect shrinks with frac_treated
  crowding <- -0.04 * frac_treated * notification
  prob_y <- pmin(1, pmax(0, 0.4 + 0.2 * drivers$experience[1:n] +
                              0.05 * notification + crowding))
  y_obs <- rbinom(n, 1, prob = prob_y)
  mean(y_obs[notification == 1]) - mean(y_obs[notification == 0])
}

# Q9: How does the estimated ATE change as we treat more drivers?
fracs <- seq(0.1, 0.9, by = 0.1)
sutva_results <- tibble(
  frac_treated = fracs,
  estimated_ate = map_dbl(fracs, ~ mean(replicate(100, sim_sutva_violation(.x))))
)

ggplot(sutva_results, aes(frac_treated, estimated_ate)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3) +
  geom_hline(yintercept = true_ate, linetype = "dashed", color = "firebrick") +
  annotate("text", x = 0.5, y = true_ate + 0.01, label = "True ATE (no interference)",
           color = "firebrick") +
  labs(title = "SUTVA Violation: Estimated ATE Depends on Treatment Fraction",
       subtitle = "More notified drivers → more crowding in the zone → biased estimate",
       x = "Fraction treated", y = "Estimated ATE")

# Q10: Why does the estimated ATE change with the treatment fraction?
#      What does this mean for the validity of the experiment?
#
# Your answer:
# _____
