############################################################
# Whole Game of Causal Inference in R — Annotated Walkthrough
# Source workflow: https://www.r-causal.org/chapters/02-whole-game
# This script follows the “whole game”:
#   1) Explore data
#   2) Model propensity scores
#   3) Create IPW weights
#   4) Check overlap & covariate balance
#   5) Estimate ATE with weights
#   6) Bootstrap uncertainty
#   7) Sensitivity analysis (tipr)
############################################################

# ----------------------------------------------------------
# 0) Install + load packages (first time only for pak line)
# ----------------------------------------------------------
# install.packages("pak")
pak::pak(c(
  "r-causal/causalworkshop",  # demo data
  "r-causal/ggdag",
  "r-causal/halfmoon",        # mirror histograms
  "r-causal/propensity",      # weights + balance tools
  "r-causal/tipr",            # sensitivity analysis
  "LucyMcGowan/touringplans"
))

library(causalworkshop)
library(tidyverse)
library(broom)
library(propensity)
library(halfmoon)
library(rsample)
library(tipr)

# ----------------------------------------------------------
# 1) Load + quickly explore data
#    net_data is provided by causalworkshop:
#    - net (logical/0-1): whether a net was used (treatment)
#    - malaria_risk: numeric outcome
#    - income, health, temperature: covariates
# ----------------------------------------------------------
net_data
dim(net_data)

# Distribution of outcome by treatment group (fast visual check)
net_data |>
  ggplot(aes(malaria_risk, fill = net)) +
  geom_density(color = NA, alpha = 0.8)

# Unadjusted (naïve) difference in means — NOT causal yet
net_data |>
  group_by(net) |> 
  summarize(malaria_risk = mean(malaria_risk), .groups = "drop")

# ----------------------------------------------------------
# 2) Propensity score model
#    Goal: estimate P(T=1 | X) so we can reweight observations.
# ----------------------------------------------------------
propensity_model <- glm(
  net ~ income + health + temperature,
  data   = net_data,
  family = binomial()
)

# Peek at a few propensity scores (probability of treatment)
head(predict(propensity_model, type = "response"))

# (Sanity check) Naïve OLS of outcome on treatment only
# This is biased if groups differ on covariates.
net_data |>
  lm(malaria_risk ~ net, data = _) |>
  tidy()

# ----------------------------------------------------------
# 3) Build IPW (Inverse Probability Weighting) for ATE
#    wt_ate() = 1/p(X) for treated and 1/(1-p(X)) for control
# ----------------------------------------------------------
net_data_wts <- propensity_model |>
  augment(data = net_data, type.predict = "response") |>
  # .fitted = propensity score for each row
  mutate(wts = wt_ate(.fitted, net))

# Inspect treatment, propensity, and weight
net_data_wts |>
  select(net, .fitted, wts) |>
  head()

# ----------------------------------------------------------
# 4) Overlap diagnostics (do groups share similar PS ranges?)
#    Mirrored hist shows treated vs control PS distributions.
# ----------------------------------------------------------
ggplot(net_data_wts, aes(.fitted)) +
  geom_mirror_histogram(aes(fill = net), bins = 50) +
  scale_y_continuous(labels = abs) +
  labs(x = "propensity score")

# Before-vs-after weighting: did reweighting improve overlap?
ggplot(net_data_wts, aes(.fitted)) +
  geom_mirror_histogram(aes(group = net), bins = 50) +
  geom_mirror_histogram(aes(fill = net, weight = wts), bins = 50, alpha = .5) +
  scale_y_continuous(labels = abs) +
  labs(x = "propensity score")

# ----------------------------------------------------------
# 5) Balance diagnostics (Love plot with SMDs)
#    We want |SMD| < 0.1 after weighting as a rule of thumb.
# ----------------------------------------------------------
plot_df <- tidy_smd(
  net_data_wts,
  c(income, health, temperature),
  .group = net,
  .wts   = wts
)

ggplot(
  plot_df,
  aes(x = abs(smd), y = variable, group = method, color = method)
) + geom_love()

# Optional: how heavy are the weights? (extreme values inflate variance)
net_data_wts |>
  ggplot(aes(wts)) +
  geom_density(fill = "#CC79A7", color = NA, alpha = 0.8)

# ----------------------------------------------------------
# 6) Weighted outcome model (IPW ATE estimate with CI)
#    Interpret the coefficient on `net` as the ATE.
# ----------------------------------------------------------
net_data_wts |>
  lm(malaria_risk ~ net, data = _, weights = wts) |>
  tidy(conf.int = TRUE)

# ----------------------------------------------------------
# 7) Bootstrap: quantify uncertainty correctly for IPW
#    (a) “Not quite right” version reuses weights — shown for pedagogy
#    (b) Correct version recomputes PS + weights inside each bootstrap
# ----------------------------------------------------------

# (a) Not quite right: uses existing wts inside splits (underestimates uncertainty)
fit_ipw_not_quite_rightly <- function(.split, ...) {
  .df <- as.data.frame(.split)  # bootstrapped data
  lm(malaria_risk ~ net, data = .df, weights = wts) |>
    tidy()
}

# (b) Correct: refit PS and rebuild weights inside each bootstrap split
fit_ipw <- function(.split, ...) {
  .df <- as.data.frame(.split)
  
  # Refit PS model inside the bootstrap sample
  propensity_model <- glm(
    net ~ income + health + temperature,
    data   = .df,
    family = binomial()
  )
  
  # Recompute weights inside bootstrap
  .df <- propensity_model |>
    augment(type.predict = "response", data = .df) |>
    mutate(wts = wt_ate(.fitted, net))
  
  # Weighted regression for ATE on the resampled data
  lm(malaria_risk ~ net, data = .df, weights = wts) |>
    tidy()
}

# Create 1000 bootstrap resamples (include “Apparent” = original data)
bootstrapped_net_data <- bootstraps(
  net_data,
  times    = 1000,
  apparent = TRUE
)

bootstrapped_net_data
fit_ipw(bootstrapped_net_data$splits[[1]])  # run once as a test

# Fit across all splits and store tidy results
ipw_results <- bootstrapped_net_data |>
  mutate(boot_fits = map(splits, fit_ipw))

ipw_results
ipw_results$boot_fits[[1]]  # example of one result

# Pull the net effect estimates (exclude "Apparent") and visualize
ipw_results |>
  filter(id != "Apparent") |> 
  mutate(
    estimate = map_dbl(
      boot_fits,
      \(fit_tbl) fit_tbl |>
        filter(term == "netTRUE") |>
        pull(estimate)
    )
  ) |>
  ggplot(aes(estimate)) +
  geom_histogram(fill = "#D55E00FF", color = "white", alpha = 0.8)

# Bootstrap T-based CIs for the treatment coefficient
boot_estimate <- ipw_results |>
  int_t(boot_fits) |>
  filter(term == "netTRUE")

boot_estimate

# ----------------------------------------------------------
# 8) Sensitivity analysis (tipr)
#    How strong would an unmeasured confounder need to be
#    to “tip” our conclusion (nullify the effect)?
# ----------------------------------------------------------
tipping_points <- tip_coef(
  boot_estimate$.upper,
  exposure_confounder_effect = 1:5
)

tipping_points |>
  ggplot(aes(confounder_outcome_effect, exposure_confounder_effect)) +
  geom_line(color = "#009E73", linewidth = 1.1) +
  geom_point(fill = "#009E73", color = "white", size = 2.5, shape = 21) +
  labs(
    x = "Confounder-Outcome Effect",
    y = "Scaled mean differences in\nconfounder between exposure groups"
  )

# Example: manually adjust estimate under assumed confounding
adjusted_estimates <- boot_estimate |>
  select(.estimate, .lower, .upper) |>
  unlist() |>
  adjust_coef_with_binary(
    exposed_confounder_prev   = 0.26,  # prevalence of confounder among treated
    unexposed_confounder_prev = 0.05,  # prevalence among control
    confounder_outcome_effect = -10    # effect of confounder on outcome
  )

adjusted_estimates
