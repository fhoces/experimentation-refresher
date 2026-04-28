# ============================================================================
# Module 8 Exercise: Beyond the A/B Test
# ============================================================================
#
# Three drills:
#   Q1. Detect TWFE bias on staggered data via Goodman-Bacon.
#   Q2. Build a synthetic control by hand (NNLS / quadprog) and compare to SDID.
#   Q3. Fit a causal forest and recover the true treatment heterogeneity.
#
# Required: tidyverse, fixest, quadprog, grf
#   install.packages(c("fixest", "quadprog", "grf"))
# ============================================================================

library(tidyverse)
library(fixest)
library(quadprog)
library(grf)
set.seed(42)


# ===== Q1. Goodman-Bacon — Catch TWFE in the Act =====
#
# Simulate a staggered-adoption panel where the true effect:
#   - is positive on average,
#   - is *larger for earlier-adopting cohorts*,
#   - grows with event time.
#
# Then fit TWFE and compare to Sun-Abraham. The TWFE estimate should be
# noticeably smaller than the truth — sometimes wrong-signed.

n_cities <- 12; n_t <- 24
cohorts <- tibble(
  city = 1:n_cities,
  g = c(rep(8, 3), rep(12, 3), rep(16, 3), rep(Inf, 3))
)
panel <- expand_grid(city = 1:n_cities, t = 1:n_t) |>
  left_join(cohorts, by = "city") |>
  mutate(
    treated = t >= g,
    eff = if_else(treated,
                  0.6 * (1 + 0.05 * (t - g)) *
                    (1 + 0.3 * (g == 8) - 0.2 * (g == 16)),
                  0),
    y = 5 + 0.05 * t + city * 0.1 + eff + rnorm(n(), 0, 0.3)
  )

# True average post-treatment effect:
true_att <- panel |> filter(t >= g, is.finite(g)) |>
  summarise(mean(eff)) |> pull()

# (a) TWFE — biased
fit_twfe <- feols(y ~ treated | city + t, data = panel)
twfe <- coef(fit_twfe)["treatedTRUE"]

# (b) Sun-Abraham — heterogeneity-robust
panel_sa <- panel |> mutate(g_sa = if_else(is.infinite(g), 10000, g))
fit_sa <- feols(y ~ sunab(g_sa, t) | city + t, data = panel_sa)
sa_att <- summary(fit_sa, agg = "att")$coeftable["ATT", "Estimate"]

cat("Truth: ", round(true_att, 3),
    "  TWFE: ", round(twfe, 3),
    "  Sun-Abraham: ", round(sa_att, 3), "\n")

# (c) Hand-coded Goodman-Bacon: how negative is the worst 2x2?
get_2x2 <- function(g_t, g_c, df, t_max) {
  if (is.infinite(g_c)) {
    pre <- 1:(g_t - 1); post <- g_t:t_max
  } else if (g_c > g_t) {
    pre <- 1:(g_t - 1); post <- g_t:(g_c - 1)
  } else {
    pre <- (g_c):(g_t - 1); post <- g_t:t_max
  }
  ya <- mean(df$y[df$g == g_t & df$t %in% pre])
  yb <- mean(df$y[df$g == g_t & df$t %in% post])
  yc <- mean(df$y[df$g == g_c & df$t %in% pre])
  yd <- mean(df$y[df$g == g_c & df$t %in% post])
  (yb - ya) - (yd - yc)
}
expand_grid(g_t = c(8, 12, 16), g_c = c(8, 12, 16, Inf)) |>
  filter(g_t != g_c) |>
  rowwise() |>
  mutate(est = get_2x2(g_t, g_c, panel, n_t),
         kind = if (is.infinite(g_c)) "treated vs never"
                else if (g_c > g_t)   "earlier vs later"
                else                   "later vs earlier (PROBLEM)") |>
  ungroup() |>
  arrange(kind, est) |> print(n = 100)

# >>> What's the smallest ("most negative") 2x2 estimate, and which pair?
# Hint: it should be a "later vs earlier" pair, where the early cohort's
# already-treated post-period acts as the control.


# ===== Q2. Synthetic Control by Hand, Then SDID =====
#
# Single treated unit. Build SC weights via simplex-constrained least squares
# (NNLS + sum-to-one). Then compare the SC gap to a hand-rolled SDID with
# weighted-DiD style.

# DGP: 9 donor cities + 1 treated, 30 periods, treatment at t=21.
n_donor <- 9; n_T <- 30; t_treat <- 21
donors <- matrix(NA, n_T, n_donor)
true_w <- c(0.35, 0.25, 0.15, 0.10, 0.10, 0.05, 0, 0, 0)
for (j in 1:n_donor) {
  donors[, j] <- 5 + 0.04 * (1:n_T) + 0.5 * sin((1:n_T) / 5 + j) +
                 j * 0.15 + rnorm(n_T, 0, 0.2)
}
treated_y <- as.numeric(donors %*% true_w) + rnorm(n_T, 0, 0.15)
treat_effect <- -0.8
treated_y[t_treat:n_T] <- treated_y[t_treat:n_T] + treat_effect

# (a) Synthetic control via solve.QP — minimize pre-period squared error
#     subject to w_j >= 0 and sum w = 1.
pre <- 1:(t_treat - 1)
A <- donors[pre, ]; b <- treated_y[pre]
Dmat <- 2 * t(A) %*% A
dvec <- 2 * t(A) %*% b
Amat <- cbind(rep(1, n_donor), diag(n_donor))   # sum=1, w >= 0
bvec <- c(1, rep(0, n_donor))
w_sc <- solve.QP(Dmat, dvec, Amat, bvec, meq = 1)$solution
synth_y <- as.numeric(donors %*% w_sc)
gap_sc  <- treated_y - synth_y

cat("\nSC weights (truth | est):\n")
print(round(rbind(true_w, w_sc), 3))
cat("Mean post-period SC gap:", round(mean(gap_sc[t_treat:n_T]), 3),
    "  (truth =", treat_effect, ")\n")

# (b) Synthetic DiD (simplified): SC unit-weights * uniform time-weights
#     and a weighted DiD. Real SDID adds an L2 penalty on the weights and
#     fits time-weights from a separate regression — see synthdid pkg.

# Stack the data, build the weighted DiD by hand.
panel_sdid <- bind_rows(
  tibble(unit = 0, t = 1:n_T, y = treated_y, treated_unit = TRUE),
  expand_grid(unit = 1:n_donor, t = 1:n_T) |>
    mutate(y = donors[cbind(t, unit)], treated_unit = FALSE)
) |>
  mutate(post = t >= t_treat,
         D = treated_unit & post,
         w = if_else(treated_unit, 1, w_sc[unit]))
fit_sdid <- lm(y ~ D + factor(unit) + factor(t), data = panel_sdid,
               weights = w)
cat("Hand-rolled SDID estimate:",
    round(coef(fit_sdid)["DTRUE"], 3), "\n")

# >>> Which estimator is closer to the truth?
# >>> Try varying the DGP noise (rnorm sd). Where does each break?


# ===== Q3. Causal Forest — Recover the True HTE =====
#
# The zone-notification HTE depends on driver tenure and city density.
# Truth: tau(x) = 30 + 60*density - 10*min(tenure, 4)

n <- 4000
X <- tibble(
  tenure  = rexp(n, rate = 1/2),
  density = runif(n, 0, 1),
  age     = sample(20:65, n, replace = TRUE)
)
W <- rbinom(n, 1, 0.5)
true_tau <- 30 + 60 * X$density - 10 * pmin(X$tenure, 4)
Y <- 700 + 50 * X$age * 0.5 + true_tau * W + rnorm(n, 0, 80)

# (a) Fit a causal forest.
cf <- causal_forest(X = as.matrix(X), Y = Y, W = W, num.trees = 1000)

# (b) ATE — sanity check.
print(average_treatment_effect(cf))
cat("True ATE:", round(mean(true_tau), 2), "\n")

# (c) Predict tau-hat and check correlation with truth.
tau_hat <- predict(cf)$predictions
cat("cor(tau_hat, true_tau):", round(cor(tau_hat, true_tau), 3), "\n")

# (d) Variable importance — which X drove the splits?
print(variable_importance(cf))

# (e) Plot tau_hat vs density, colored by tenure.
ggplot(bind_cols(X, hat = tau_hat, true = true_tau),
       aes(density, hat, color = pmin(tenure, 5))) +
  geom_point(alpha = 0.3) +
  geom_smooth(aes(y = true), color = "black", linetype = "dashed", se = FALSE) +
  scale_color_viridis_c(name = "Tenure (yrs)") +
  labs(x = "City density", y = expression(hat(tau)(x)))

# >>> Variable importance — is `age` correctly identified as irrelevant?
# >>> Try a smaller n (e.g., 800). Does the forest still recover the HTE?


# ===== End =====
