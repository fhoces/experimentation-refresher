# ============================================================================
# Module 5 Exercise: Analyzing Experiments
# ============================================================================
#
# Implement CUPED from scratch, compare analysis methods, and work through
# ITT vs LATE with non-compliance.
#
# Instructions: work through each section, run the code, answer the
# questions in comments. Fill in blanks marked with _____.

library(tidyverse)
set.seed(42)

# --- 1. Setup: Simulate a ride-sharing experiment ----------------------------

n <- 3000
drivers <- tibble(
  id = 1:n,
  city = sample(c("SF", "LA", "NYC", "CHI"), n, replace = TRUE),
  tenure_months = rpois(n, lambda = 12),
  pre_trips = rpois(n, lambda = 30),
  bonus = rep(c(0, 1), each = n / 2),
  # True effect: 3 extra trips. Outcome is noisy and correlated with pre_trips.
  post_trips = pre_trips + 3 * bonus + rnorm(n, sd = 12)
)

# --- 2. Difference in means --------------------------------------------------

dim_estimate <- mean(drivers$post_trips[drivers$bonus == 1]) -
                mean(drivers$post_trips[drivers$bonus == 0])
cat("Difference in means:", round(dim_estimate, 3), "\n")

# Verify: regression gives the same answer
fit_simple <- lm(post_trips ~ bonus, data = drivers)
cat("Regression coef:   ", round(coef(fit_simple)["bonus"], 3), "\n")

# Q1: Are these the same? Why?

# --- 3. Implement CUPED from scratch -----------------------------------------

# Step 1: Estimate theta
theta <- cov(drivers$post_trips, drivers$pre_trips) / var(drivers$pre_trips)
cat("Theta:", round(theta, 3), "\n")

# Step 2: Create the CUPED-adjusted outcome
drivers <- drivers |>
  mutate(y_cuped = _____)

# Step 3: Estimate the treatment effect using the adjusted outcome
cuped_estimate <- _____
cat("CUPED estimate:", round(cuped_estimate, 3), "\n")

# Step 4: Compare variance
cat("Var(raw):  ", round(var(drivers$post_trips), 1), "\n")
cat("Var(CUPED):", round(var(drivers$y_cuped), 1), "\n")
cat("Variance reduction:", round(1 - var(drivers$y_cuped) / var(drivers$post_trips), 3), "\n")

# --- 4. Verify: CUPED = regression -------------------------------------------

fit_covar <- lm(post_trips ~ bonus + pre_trips, data = drivers)
reg_estimate <- coef(fit_covar)["bonus"]
cat("\nCUPED estimate:     ", round(cuped_estimate, 3), "\n")
cat("Regression estimate:", round(reg_estimate, 3), "\n")

# Q2: Are these the same? Why does CUPED equal regression?

# --- 5. Simulation: Compare precision ----------------------------------------

sim_compare <- function(i) {
  pre <- rpois(3000, lambda = 30)
  treat <- rep(c(0, 1), each = 1500)
  post <- pre + 3 * treat + rnorm(3000, sd = 12)

  # Raw difference in means
  raw <- mean(post[treat == 1]) - mean(post[treat == 0])

  # CUPED
  th <- cov(post, pre) / var(pre)
  y_adj <- post - th * (pre - mean(pre))
  cuped <- mean(y_adj[treat == 1]) - mean(y_adj[treat == 0])

  tibble(raw = raw, cuped = cuped)
}

results <- map_dfr(1:1000, sim_compare)

cat("\n--- 1,000 simulations ---\n")
cat("SD(raw):  ", round(sd(results$raw), 3), "\n")
cat("SD(CUPED):", round(sd(results$cuped), 3), "\n")
cat("Precision gain:", round((1 - sd(results$cuped)/sd(results$raw)) * 100), "%\n")

# Q3: How much narrower are the CUPED estimates? What does this correspond
#     to in terms of "equivalent extra sample size"?

# Visualize
results |>
  pivot_longer(everything(), names_to = "method", values_to = "estimate") |>
  ggplot(aes(estimate, fill = method)) +
  geom_histogram(bins = 50, alpha = 0.6, position = "identity") +
  geom_vline(xintercept = 3, linetype = "dashed", color = "firebrick") +
  labs(title = "Raw vs CUPED: 1,000 simulated experiments",
       x = "Estimated treatment effect", y = "Count") +
  theme(legend.position = "top")

# --- 6. Lin (2013) estimator -------------------------------------------------

# Standard covariate adjustment
fit_naive_covar <- lm(post_trips ~ bonus + pre_trips, data = drivers)

# Lin's estimator: interact demeaned covariate with treatment
drivers <- drivers |>
  mutate(pre_trips_dm = pre_trips - mean(pre_trips))
fit_lin <- lm(post_trips ~ bonus * pre_trips_dm, data = drivers)

cat("\n--- Covariate adjustment comparison ---\n")
cat("Naive covariate adj:", round(coef(fit_naive_covar)["bonus"], 3), "\n")
cat("Lin (2013):         ", round(coef(fit_lin)["bonus"], 3), "\n")
cat("SE naive:           ", round(summary(fit_naive_covar)$coefficients["bonus", "Std. Error"], 3), "\n")
cat("SE Lin:             ", round(summary(fit_lin)$coefficients["bonus", "Std. Error"], 3), "\n")

# Q4: Are the estimates and SEs similar? When would Lin's estimator differ
#     more from the naive approach?

# --- 7. HC2 robust standard errors -------------------------------------------

# Compute HC2 standard errors manually
compute_hc2_se <- function(fit) {
  X <- model.matrix(fit)
  e <- residuals(fit)
  h <- hatvalues(fit)
  meat <- t(X) %*% diag(e^2 / (1 - h)) %*% X
  bread <- solve(t(X) %*% X)
  vcov_hc2 <- bread %*% meat %*% bread
  sqrt(diag(vcov_hc2))
}

se_ols <- summary(fit_covar)$coefficients[, "Std. Error"]
se_hc2 <- compute_hc2_se(fit_covar)

cat("\n--- Standard errors ---\n")
cat("OLS SE(bonus):", round(se_ols["bonus"], 3), "\n")
cat("HC2 SE(bonus):", round(se_hc2["bonus"], 3), "\n")

# Q5: Are they similar here? Why might they differ in other settings?

# --- 8. ITT vs LATE: Non-compliance ------------------------------------------

experiment <- tibble(
  id = 1:n,
  assigned = rep(c(0, 1), each = n / 2),
  # Only 65% of assigned drivers actually use the bonus
  complied = if_else(assigned == 1,
                     rbinom(n / 2, 1, prob = 0.65), 0L),
  pre_trips = rpois(n, lambda = 30),
  # True effect of USING the bonus: 5 extra trips
  post_trips = pre_trips + 5 * complied + rnorm(n, sd = 10)
)

# ITT: effect of assignment
itt <- mean(experiment$post_trips[experiment$assigned == 1]) -
       mean(experiment$post_trips[experiment$assigned == 0])
cat("\n--- ITT vs LATE ---\n")
cat("ITT:", round(itt, 2), "\n")

# Compliance rate
compliance <- mean(experiment$complied[experiment$assigned == 1])
cat("Compliance rate:", round(compliance, 2), "\n")

# LATE (Wald estimator)
late <- _____
cat("LATE:", round(late, 2), "\n")

# Naive (WRONG): regress on actual compliance
naive_wrong <- coef(lm(post_trips ~ complied, data = experiment))["complied"]
cat("Naive (biased):", round(naive_wrong, 2), "\n")

# Q6: Why is the naive estimate biased? What would cause compliance to be
#     endogenous?

# Q7: The ITT is "diluted" by non-compliance. By how much?
#     How does ITT / compliance_rate relate to the true effect (5 trips)?

# --- 9. DiD: Pre/Post with simulated study data ------------------------------

n_studies <- 200
studies <- tibble(
  study_id = 1:n_studies,
  has_pap = rbinom(n_studies, 1, 0.4),
  arm = sample(rep(c("T0", "T1", "T2", "T3"), each = n_studies / 4)),
  # Pre-period reporting rate: ~42% on average
  y_pre = rbeta(n_studies, shape1 = 3, shape2 = 4),
  # Treatment effects
  effect = case_when(
    arm == "T0" ~ 0,
    arm == "T1" ~ 0.03,
    arm == "T2" ~ 0.06,
    arm == "T3" ~ 0.10
  ),
  y_post = pmin(1, y_pre + effect + rnorm(n_studies, sd = 0.08))
)

# Reshape to panel
panel <- studies |>
  pivot_longer(cols = c(y_pre, y_post), names_to = "period",
               values_to = "y", names_prefix = "y_") |>
  mutate(post = if_else(period == "post", 1, 0))

# Q8: Run a DiD regression with study fixed effects.
# The interaction terms post:arm capture the treatment effects.
fit_did <- lm(y ~ factor(study_id) + _____,  data = panel)

# Extract treatment effects
did_coefs <- coef(fit_did)
treat_idx <- grep("post:factor\\(arm\\)", names(did_coefs))
cat("\n--- DiD estimates ---\n")
cat("True effects: T1=0.03, T2=0.06, T3=0.10\n")
round(did_coefs[treat_idx], 3)

# Q9: How close are the DiD estimates to the true effects?
#     What assumption must hold for DiD to be unbiased here?

# --- 10. Putting it together: Full analysis pipeline -------------------------

# Q10: You're asked to analyze a ride-sharing driver bonus experiment.
#      3,000 drivers, 50/50 split, 70% compliance. You have pre-treatment
#      trip counts. Walk through your analysis plan:
#
#      a) What is your primary estimating equation?
#      b) What covariates would you include?
#      c) How would you compute standard errors?
#      d) Would you report ITT, LATE, or both?
#      e) What would you pre-register?
#
# Your answer:
# _____
