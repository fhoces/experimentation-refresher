# ============================================================================
# Module 6 Exercise: Multiple Testing & Subgroups
# ============================================================================
#
# Simulate the multiple comparisons problem and learn to apply corrections.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. The problem: 20 A/A tests ------------------------------------------

# No treatment effect anywhere. 20 independent tests.
run_aa_tests <- function(n_tests = 20, n_per_group = 500) {
  map_dfr(1:n_tests, function(k) {
    control <- rnorm(n_per_group)
    treatment <- rnorm(n_per_group)  # same distribution!
    test <- t.test(treatment, control)
    tibble(test_id = k,
           estimate = test$estimate[1] - test$estimate[2],
           p_value = test$p.value)
  })
}

results <- run_aa_tests()
cat("Number of 'significant' results (raw):", sum(results$p_value < 0.05), "\n")

# Q1: How many would you expect to be significant by chance?
#     Expected = _____

# --- 2. Repeat 1,000 times to see the false positive rate ------------------

sim_false_positives <- function(iter) {
  res <- run_aa_tests()
  sum(res$p_value < 0.05)
}

fp_counts <- map_dbl(1:1000, sim_false_positives)

cat("\nFalse positive distribution across 1,000 simulations:\n")
cat("  Mean # false positives:", round(mean(fp_counts), 2), "\n")
cat("  P(at least 1 FP):", round(mean(fp_counts >= 1), 3), "\n")

# Q2: The theoretical FWER is 1 - (1 - 0.05)^20 = _____.
#     Does the simulation match?

# --- 3. Apply corrections --------------------------------------------------

results <- results |>
  mutate(
    p_bonferroni = p.adjust(p_value, method = "bonferroni"),
    p_holm = p.adjust(p_value, method = "holm"),
    p_bh = p.adjust(p_value, method = "BH")
  )

cat("\nAfter correction (this run):\n")
cat("  Significant (raw):", sum(results$p_value < 0.05), "\n")
cat("  Significant (Bonferroni):", sum(results$p_bonferroni < 0.05), "\n")
cat("  Significant (Holm):", sum(results$p_holm < 0.05), "\n")
cat("  Significant (BH):", sum(results$p_bh < 0.05), "\n")

# Q3: Which method rejected the fewest? Why?

# --- 4. Now add a REAL effect in one subgroup -------------------------------

# 20 tests: test #7 has a real effect of 0.3 SD. The rest are null.
run_mixed_tests <- function(n_tests = 20, n_per_group = 500,
                            real_test = 7, real_effect = 0.3) {
  map_dfr(1:n_tests, function(k) {
    control <- rnorm(n_per_group)
    effect <- if (k == real_test) real_effect else 0
    treatment <- rnorm(n_per_group, mean = effect)
    test <- t.test(treatment, control)
    tibble(test_id = k,
           true_effect = effect,
           estimate = test$estimate[1] - test$estimate[2],
           p_value = test$p.value)
  })
}

mixed <- run_mixed_tests()

mixed <- mixed |>
  mutate(
    p_bonferroni = p.adjust(p_value, method = "bonferroni"),
    p_holm = p.adjust(p_value, method = "holm"),
    p_bh = p.adjust(p_value, method = "BH")
  )

cat("\nMixed tests — test #7 has a real effect:\n")
mixed |>
  filter(test_id == 7) |>
  select(test_id, true_effect, estimate, p_value, p_bonferroni, p_holm, p_bh) |>
  print()

# Q4: Does the real effect (test #7) survive each correction method?
#     Bonferroni: _____
#     Holm: _____
#     BH: _____

# --- 5. Power under corrections (simulation) -------------------------------

# Repeat 1,000 times: how often does the real effect in test #7 survive?
detect_real <- function(iter) {
  res <- run_mixed_tests()
  res <- res |>
    mutate(p_bonf = p.adjust(p_value, method = "bonferroni"),
           p_holm = p.adjust(p_value, method = "holm"),
           p_bh = p.adjust(p_value, method = "BH"))
  res7 <- res |> filter(test_id == 7)
  c(raw = res7$p_value < 0.05,
    bonferroni = res7$p_bonf < 0.05,
    holm = res7$p_holm < 0.05,
    bh = res7$p_bh < 0.05)
}

power_results <- map_dfr(1:1000, detect_real)

cat("\nPower to detect real effect (test #7, effect = 0.3):\n")
cat("  Raw:", round(mean(power_results$raw), 3), "\n")
cat("  Bonferroni:", round(mean(power_results$bonferroni), 3), "\n")
cat("  Holm:", round(mean(power_results$holm), 3), "\n")
cat("  BH:", round(mean(power_results$bh), 3), "\n")

# Q5: How much power do you lose from correction? Which method preserves
#     the most power?

# --- 6. The interaction test -----------------------------------------------

# Simulate an experiment with two subgroups
set.seed(42)
n <- 2000
subgroup_dat <- tibble(
  group = rep(c("A", "B"), each = n/2),
  treated = rep(c(0, 1), times = n/2),
  # Group A: effect = 0.3, Group B: effect = 0.1
  y = case_when(
    group == "A" ~ 0.3 * treated + rnorm(n),
    group == "B" ~ 0.1 * treated + rnorm(n)
  )
)

# Subgroup-specific tests
cat("\nSubgroup-specific results:\n")
subgroup_dat |>
  group_by(group) |>
  summarise(
    effect = mean(y[treated == 1]) - mean(y[treated == 0]),
    p_value = t.test(y[treated == 1], y[treated == 0])$p.value
  ) |>
  print()

# Interaction test
mod <- lm(y ~ treated * group, data = subgroup_dat)
cat("\nInteraction test (does the effect differ between groups?):\n")
print(round(coef(summary(mod))[4, ], 4))

# Q6: The effect is "significant" in Group A but not in Group B.
#     Does the interaction test confirm that the effects are *different*?
#     Your answer: _____

# --- 7. Pre-registered subgroup analysis ------------------------------------

# Scenario: You pre-specified ONE subgroup (group A) in your analysis plan.
# You have 1 primary test + 1 pre-specified subgroup = 2 tests total.
# The correction burden is much smaller than if you tested 20 subgroups.

set.seed(42)
n <- 2000
prereg_dat <- tibble(
  group = sample(LETTERS[1:20], n, replace = TRUE),
  treated = sample(c(0, 1), n, replace = TRUE),
  # Only group A has a real effect (0.4 SD)
  true_effect = if_else(group == "A", 0.4, 0),
  y = true_effect * treated + rnorm(n)
)

# All 20 subgroup tests
all_tests <- prereg_dat |>
  group_by(group) |>
  summarise(
    effect = mean(y[treated == 1]) - mean(y[treated == 0]),
    p_value = t.test(y[treated == 1], y[treated == 0])$p.value,
    .groups = "drop"
  ) |>
  mutate(p_bh_20 = p.adjust(p_value, method = "BH"))

# Pre-registered analysis: only 2 tests (overall + group A)
overall_p <- t.test(y ~ treated, data = prereg_dat)$p.value
group_a_p <- all_tests |> filter(group == "A") |> pull(p_value)

prereg_tests <- tibble(
  test = c("Overall", "Group A (pre-registered)"),
  p_value = c(overall_p, group_a_p),
  p_holm_2 = p.adjust(p_value, method = "holm")
)

cat("\nPre-registered analysis (2 tests, Holm correction):\n")
print(prereg_tests)

cat("\nExploratory analysis (20 tests, BH correction):\n")
all_tests |> filter(p_value < 0.05) |> print()

# Q7: Does Group A survive correction when you pre-registered it (2 tests)?
#     Does it survive when you test all 20 groups?
#     What's the lesson?

# --- 8. Visualize the garden of forking paths (bonus) ----------------------

# Q8: Simulate a null experiment (no effect). Try at least 6 different
#     analysis strategies and collect the p-values. How many are < 0.05?
#     Fill in the blank below.

set.seed(42)
n <- 500
fork_dat <- tibble(
  treated = sample(c(0, 1), n, replace = TRUE),
  y1 = rnorm(n),
  y2 = rnorm(n),
  y3 = rnorm(n),
  covariate = rnorm(n),
  outlier = abs(y1) > 2.5
)

fork_pvals <- c(
  "Y1 raw" = t.test(y1 ~ treated, data = fork_dat)$p.value,
  "Y2 raw" = t.test(y2 ~ treated, data = fork_dat)$p.value,
  "Y3 raw" = t.test(y3 ~ treated, data = fork_dat)$p.value,
  "Y1 + covariate" = summary(lm(y1 ~ treated + covariate, data = fork_dat))$coef[2,4],
  "Y1 no outliers" = t.test(y1 ~ treated,
                             data = fork_dat |> filter(!outlier))$p.value,
  "Y1 covariate>0" = t.test(y1 ~ treated,
                             data = fork_dat |> filter(covariate > 0))$p.value
)

cat("\nGarden of forking paths:\n")
tibble(analysis = names(fork_pvals), p_value = fork_pvals) |>
  mutate(significant = p_value < _____) |>
  print()

# Q9: What fraction of your analyses are "significant"? What does this tell
#     you about the importance of pre-analysis plans?
#
# Your answer:
# _____
