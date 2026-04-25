# ============================================================================
# Module 2 Exercise: SUTVA and When It Breaks
# ============================================================================
#
# Setup: same zone-notification experiment as Module 1. Randomize drivers
# to receive (or not) a push notification when heading into a high-demand
# zone; outcome is whether they accept the next ride offer.
#
# Here we study what happens when SUTVA fails — interference, network
# spillovers, and general-equilibrium effects bias the naive ATE.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. A Simple Marketplace with No Interference ----------------------------

n_drivers <- 500

drivers <- tibble(
  driver_id = 1:n_drivers,
  experience = rnorm(n_drivers),
  # Potential outcomes — LPM: P(Y=1) = 0.4 + 0.2*experience + 0.05*D, clipped
  y0 = pmin(1, pmax(0, 0.4 + 0.2 * experience)),
  y1 = pmin(1, pmax(0, 0.4 + 0.2 * experience + 0.05))
)

true_ate <- mean(drivers$y1 - drivers$y0)
cat("True ATE (no interference):", round(true_ate, 3), "\n")

# Randomize and estimate (no interference version)
drivers <- drivers |>
  mutate(
    notification = sample(rep(c(0, 1), each = n_drivers / 2)),
    y_obs = rbinom(n_drivers, 1,
                   prob = if_else(notification == 1, y1, y0))
  )

naive_ate_no_interference <- mean(drivers$y_obs[drivers$notification == 1]) -
  mean(drivers$y_obs[drivers$notification == 0])
cat("Estimated ATE (no interference):",
    round(naive_ate_no_interference, 3), "\n")

# Q1: Is the estimate close to the true ATE? Why?

# --- 2. Add Marketplace Interference -----------------------------------------

# Now: notified drivers all head to the same zone. Zone gets crowded ->
# each notified driver gets fewer rides than the direct effect alone would
# give. Non-notified drivers (elsewhere) are unaffected.

sim_marketplace <- function(interference_strength = 0.15) {
  notification <- sample(rep(c(0, 1), each = n_drivers / 2))
  frac_treated <- mean(notification)

  # Potential outcomes (probabilities). Crowding shrinks y1 by the
  # treated share; control drivers (y0) are unaffected.
  y0 <- pmin(1, pmax(0, 0.4 + 0.2 * drivers$experience))
  y1 <- pmin(1, pmax(0, 0.4 + 0.2 * drivers$experience + 0.05 -
                          interference_strength * frac_treated))

  # Observed outcome based on assignment
  y_obs <- rbinom(n_drivers, 1, prob = if_else(notification == 1, y1, y0))

  # Naive ATE
  mean(y_obs[notification == 1]) - mean(y_obs[notification == 0])
}

# Q2: Run 500 simulations with interference. What happens to the ATE?
estimates_interference <- replicate(500, sim_marketplace(0.15))
estimates_no_interf    <- replicate(500, sim_marketplace(0.0))

cat("\nWith interference:\n")
cat("  Mean estimated ATE:", round(mean(estimates_interference), 3), "\n")
cat("Without interference:\n")
cat("  Mean estimated ATE:", round(mean(estimates_no_interf), 3), "\n")
cat("True ATE:", round(true_ate, 3), "\n")

# Q3: In which direction is the bias? Why does it make sense economically?
#     (Hint: who is harmed by crowding — the treated or the control group?)
#
# Your answer:
# _____

# --- 3. Bias Depends on Interference Strength --------------------------------

# Q4: Fill in the blank to sweep over interference strengths
strengths <- seq(0, 0.3, by = 0.03)
bias_by_strength <- tibble(
  interference = strengths,
  mean_ate = map_dbl(strengths, ~ mean(replicate(200, sim_marketplace(.x))))
)

ggplot(bias_by_strength, aes(interference, mean_ate)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3) +
  geom_hline(yintercept = _____, linetype = "dashed", color = "firebrick") +
  annotate("text", x = 0.15, y = true_ate + 0.005,
           label = "True ATE (no interference)", color = "firebrick") +
  labs(title = "Bias Increases with Interference Strength",
       x = "Interference strength", y = "Mean estimated ATE")

# Q5: What happens to the bias as interference strength grows?

# --- 4. Network Spillovers: Academic Co-Author Example -----------------------

# A separate application: 80 studies, each with 1-3 authors drawn from a
# pool of 60. Treatment arms T0 (control), T1, T2, T3. Here spillovers flow
# through the co-author network, not a marketplace.

n_studies <- 80
n_authors <- 60

# Create co-author network
studies <- tibble(
  study_id = 1:n_studies,
  n_authors = sample(1:3, n_studies, replace = TRUE,
                     prob = c(0.3, 0.4, 0.3))
)

# Assign authors to studies
study_authors <- studies |>
  rowwise() |>
  mutate(author_ids = list(sort(sample(1:n_authors, n_authors,
                                       replace = FALSE)))) |>
  ungroup() |>
  unnest(author_ids)

# Assign treatment arms (T0=0, T1=1, T2=2, T3=3)
studies <- studies |>
  mutate(arm = sample(0:3, n_studies, replace = TRUE,
                      prob = c(0.25, 0.25, 0.25, 0.25)))

# Q6: For each study, compute "spillover exposure" = number of co-author
#     connections to treated studies (arm > 0)

# Step 1: Find all (study, author) pairs
study_author_pairs <- study_authors |>
  select(study_id, author_ids) |>
  left_join(studies |> select(study_id, arm), by = "study_id")

# Step 2: For each study, find co-authored studies through shared authors
spillover_exposure <- study_author_pairs |>
  inner_join(study_author_pairs, by = "author_ids",
             suffix = c("_focal", "_linked"),
             relationship = "many-to-many") |>
  filter(study_id_focal != study_id_linked) |>
  group_by(study_id_focal) |>
  summarise(
    n_linked_studies = n_distinct(study_id_linked),
    n_treated_links = n_distinct(study_id_linked[arm_linked > 0])
  )

# Q7: Simulate outcomes where spillover exposure increases reporting
baseline_reporting <- 0.4  # 40% baseline reporting rate

studies_with_spillover <- studies |>
  left_join(spillover_exposure, by = c("study_id" = "study_id_focal")) |>
  mutate(
    n_linked_studies = replace_na(n_linked_studies, 0),
    n_treated_links = replace_na(n_treated_links, 0),
    # Direct treatment effect
    direct_effect = case_when(
      arm == 0 ~ 0,
      arm == 1 ~ 0.05,
      arm == 2 ~ 0.10,
      arm == 3 ~ 0.15
    ),
    # Spillover effect: each treated link adds a small boost
    spillover_effect = 0.02 * n_treated_links,
    # Observed reporting rate
    reporting_rate = pmin(1, baseline_reporting + direct_effect +
                           spillover_effect)
  )

# Q8: Compare the naive treatment effect to the true direct effect
naive_effect <- mean(studies_with_spillover$reporting_rate[
  studies_with_spillover$arm > 0]) -
  mean(studies_with_spillover$reporting_rate[
    studies_with_spillover$arm == 0])

cat("\nCo-author spillover example:\n")
cat("  Naive treatment effect:", round(naive_effect, 3), "\n")

# Q9: Is the naive effect biased? In which direction? Why?
#     Hint: Think about whether control studies also receive spillovers.
#
# Your answer:
# _____

# --- 5. Partial vs General Equilibrium ---------------------------------------

# Experiment on 5% of drivers vs rollout to 100%.

sim_partial_vs_ge <- function(frac_treated, interference = 0.15) {
  n <- 1000
  experience <- rnorm(n)
  notification <- sample(c(rep(1, round(n * frac_treated)),
                           rep(0, n - round(n * frac_treated))))

  # Potential outcomes. Partial equilibrium (small frac_treated): y1 ≈ direct effect.
  # General equilibrium (everyone treated): crowding shrinks y1 a lot.
  y0 <- pmin(1, pmax(0, 0.4 + 0.2 * experience))
  y1 <- pmin(1, pmax(0, 0.4 + 0.2 * experience + 0.05 -
                          interference * frac_treated))

  y_obs <- rbinom(n, 1, prob = if_else(notification == 1, y1, y0))

  tibble(
    frac_treated = frac_treated,
    mean_treated = mean(y_obs[notification == 1]),
    mean_control = if (sum(notification == 0) > 0) mean(y_obs[notification == 0]) else NA_real_,
    naive_ate = mean_treated - mean_control
  )
}

# Q10: Compare the estimated effect at 5% treated vs 50% treated vs 95% treated
fracs <- c(0.05, 0.10, 0.25, 0.50, 0.75, 0.95)
ge_results <- map_dfr(fracs, function(f) {
  reps <- replicate(200, sim_partial_vs_ge(f), simplify = FALSE) |>
    bind_rows()
  reps |> summarise(
    frac_treated = f,
    mean_ate = mean(naive_ate, na.rm = TRUE)
  )
})

ggplot(ge_results, aes(frac_treated, mean_ate)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3) +
  geom_hline(yintercept = true_ate, linetype = "dashed", color = "firebrick") +
  labs(title = "Partial vs General Equilibrium",
       subtitle = "Small experiments approximate the direct effect; as rollout grows, crowding dominates",
       x = "Fraction of drivers treated",
       y = "Estimated ATE")

# Q11: Why does the estimated ATE SHRINK as you treat more drivers?
#      What does this imply for extrapolating from a 5% experiment to
#      a full rollout?
#
# Your answer:
# _____
