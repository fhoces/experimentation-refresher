# ============================================================================
# Module 1 Exercise: The Experimental Ideal
# ============================================================================
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
  # Unobserved motivation (affects both bonus-seeking and retention)
  motivation = rnorm(n),
  # Potential outcomes
  y0 = rbinom(n, 1, prob = plogis(-0.3 + 0.4 * motivation)),      # without bonus
  y1 = rbinom(n, 1, prob = plogis(-0.3 + 0.4 * motivation + 0.4)) # with bonus
)

# Q1: What is the true ATE? (We can compute it because we have BOTH potential
#     outcomes — this is the privilege of simulation)
true_ate <- mean(drivers$y1 - drivers$y0)
cat("True ATE:", round(true_ate, 3), "\n")

# Q2: What is the true ATT and ATU if motivated drivers self-select into bonus?
drivers <- drivers |>
  mutate(self_selected = rbinom(n, 1, prob = plogis(0.8 * motivation)))

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

# Run 1000 simulated RCTs
sim_rct <- function(i) {
  # Random assignment
  bonus <- sample(rep(c(0, 1), each = n/2))
  # Observed outcome depends on assignment
  y_obs <- if_else(bonus == 1, drivers$y1, drivers$y0)
  # Simple difference in means
  mean(y_obs[bonus == 1]) - mean(y_obs[bonus == 0])
}

rct_estimates <- map_dbl(1:1000, sim_rct)

cat("\nMean of 1000 RCT estimates:", round(mean(rct_estimates), 3), "\n")
cat("True ATE:", round(true_ate, 3), "\n")
cat("SD of estimates:", round(sd(rct_estimates), 3), "\n")

# Q6: Is the mean of the estimates close to the true ATE? Why?

# Visualize
ggplot(tibble(est = rct_estimates), aes(est)) +
  geom_histogram(bins = 40, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = true_ate, color = "firebrick",
             linewidth = 1.2, linetype = "dashed") +
  labs(title = "1,000 Simulated RCTs",
       x = "Estimated ATE", y = "Count")

# --- 4. Compare randomized vs observational --------------------------------

# Run 1000 observational (self-selected) studies
sim_obs <- function(i) {
  bonus <- rbinom(n, 1, prob = plogis(0.8 * drivers$motivation))
  y_obs <- if_else(bonus == 1, drivers$y1, drivers$y0)
  mean(y_obs[bonus == 1]) - mean(y_obs[bonus == 0])
}

obs_estimates <- map_dbl(1:1000, sim_obs)

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

# Simple interference: treated drivers take more rides, leaving fewer for
# control drivers. Control group retention DROPS when more drivers are treated.

sim_sutva_violation <- function(frac_treated) {
  bonus <- sample(c(rep(1, n * frac_treated), rep(0, n * (1 - frac_treated))))
  # Interference: control drivers' retention decreases with treatment fraction
  interference <- -0.2 * frac_treated * (1 - bonus)
  y_obs <- rbinom(n, 1, prob = plogis(-0.3 + 0.4 * drivers$motivation[1:n] +
                                        0.4 * bonus + interference))
  mean(y_obs[bonus == 1]) - mean(y_obs[bonus == 0])
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
       subtitle = "More treated drivers → more interference → more bias",
       x = "Fraction treated", y = "Estimated ATE")

# Q10: Why does the estimated ATE increase with the treatment fraction?
#      What does this mean for the validity of the experiment?
#
# Your answer:
# _____
