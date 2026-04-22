# ============================================================================
# Module 2 Exercise: SUTVA and When It Breaks
# ============================================================================
#
# Simulate marketplace interference, network spillovers, and general
# equilibrium effects. Show how SUTVA violations bias the naive ATE.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. A Simple Marketplace with No Interference ----------------------------

n_drivers <- 500
total_rides <- 300  # fixed supply of ride requests per period

drivers <- tibble(
  driver_id = 1:n_drivers,
  skill = rnorm(n_drivers),  # driving skill (affects retention)
  # Potential outcomes: retention probability under bonus / no bonus
  p_retain_0 = plogis(-0.5 + 0.3 * skill),           # without bonus
  p_retain_1 = plogis(-0.5 + 0.3 * skill + 0.5)      # with bonus (true effect)
)

true_ate <- mean(drivers$p_retain_1 - drivers$p_retain_0)
cat("True ATE (no interference):", round(true_ate, 3), "\n")

# Randomize and estimate (no interference version)
drivers <- drivers |>
  mutate(
    bonus = sample(rep(c(0, 1), each = n_drivers / 2)),
    y_obs = rbinom(n_drivers, 1,
                   prob = if_else(bonus == 1, p_retain_1, p_retain_0))
  )

naive_ate_no_interference <- mean(drivers$y_obs[drivers$bonus == 1]) -
  mean(drivers$y_obs[drivers$bonus == 0])
cat("Estimated ATE (no interference):", round(naive_ate_no_interference, 3), "\n")

# Q1: Is the estimate close to the true ATE? Why?

# --- 2. Add Marketplace Interference -----------------------------------------

# Now: bonus drivers take more rides, reducing rides available for control
# drivers. Control group retention DROPS because they earn less.

sim_marketplace <- function(interference_strength = 0.3) {
  bonus <- sample(rep(c(0, 1), each = n_drivers / 2))
  frac_treated <- mean(bonus)

  # Interference: control drivers lose retention when treated drivers
  # capture more rides
  interference <- -interference_strength * frac_treated * (1 - bonus)

  y_obs <- rbinom(n_drivers, 1,
                  prob = plogis(-0.5 + 0.3 * drivers$skill +
                                  0.5 * bonus + interference))

  # Naive ATE
  mean(y_obs[bonus == 1]) - mean(y_obs[bonus == 0])
}

# Q2: Run 500 simulations with interference. What happens to the ATE?
estimates_interference <- replicate(500, sim_marketplace(0.3))
estimates_no_interf    <- replicate(500, sim_marketplace(0.0))

cat("\nWith interference:\n")
cat("  Mean estimated ATE:", round(mean(estimates_interference), 3), "\n")
cat("Without interference:\n")
cat("  Mean estimated ATE:", round(mean(estimates_no_interf), 3), "\n")
cat("True ATE:", round(true_ate, 3), "\n")

# Q3: In which direction is the bias? Why does it make sense economically?
#
# Your answer:
# _____

# --- 3. Bias Depends on Interference Strength --------------------------------

# Q4: Fill in the blank to sweep over interference strengths
strengths <- seq(0, 0.8, by = 0.1)
bias_by_strength <- tibble(
  interference = strengths,
  mean_ate = map_dbl(strengths, ~ mean(replicate(200, sim_marketplace(.x))))
)

ggplot(bias_by_strength, aes(interference, mean_ate)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3) +
  geom_hline(yintercept = _____, linetype = "dashed", color = "firebrick") +
  annotate("text", x = 0.4, y = true_ate + 0.01,
           label = "True ATE (no interference)", color = "firebrick") +
  labs(title = "Bias Increases with Interference Strength",
       x = "Interference strength", y = "Mean estimated ATE")

# Q5: What happens to the bias as interference strength grows?

# --- 4. Network Spillovers: Academic Co-Author Example -----------------------

# Simulate 80 studies, each with 1-3 authors drawn from a pool of 60 authors.
# Treatment arms: T0 (control), T1, T2, T3.

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

sim_partial_vs_ge <- function(frac_treated, interference = 0.3) {
  n <- 1000
  skill <- rnorm(n)
  bonus <- sample(c(rep(1, n * frac_treated),
                    rep(0, n * (1 - frac_treated))))

  # Under partial equilibrium (small fraction treated), interference is small.
  # Under general equilibrium (everyone treated), interference is large.
  interference_effect <- -interference * frac_treated * (1 - bonus)

  y_obs <- rbinom(n, 1, prob = plogis(-0.5 + 0.3 * skill +
                                        0.5 * bonus + interference_effect))

  tibble(
    frac_treated = frac_treated,
    mean_treated = mean(y_obs[bonus == 1]),
    mean_control = if (sum(bonus == 0) > 0) mean(y_obs[bonus == 0]) else NA_real_,
    naive_ate = mean_treated - mean_control
  )
}

# Q10: Compare the estimated effect at 5% treated vs 50% treated vs 95% treated
fracs <- c(0.05, 0.10, 0.25, 0.50, 0.75, 0.95)
ge_results <- map_dfr(fracs, ~ {
  reps <- map_dfr(1:200, ~ sim_partial_vs_ge(.x))
  reps |> summarise(
    frac_treated = first(frac_treated),
    mean_ate = mean(naive_ate, na.rm = TRUE)
  )
}, .progress = FALSE)

# Fix: the inner .x is shadowed. Let's redo this properly:
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
       subtitle = "Small experiments underestimate bias; full rollout reveals GE effects",
       x = "Fraction of drivers treated",
       y = "Estimated ATE")

# Q11: Why does the estimated ATE INCREASE as you treat more drivers?
#      What does this imply for extrapolating from a 5% experiment to
#      a full rollout?
#
# Your answer:
# _____
