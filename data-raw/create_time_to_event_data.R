# Generate example time-to-event data for benefit-risk temporal analysis
# This creates synthetic data with:
# - Subjects experiencing both benefit and risk events
# - Subjects with censored data (only benefit OR only risk)

set.seed(123)

n_subjects <- 200

# Study duration for censoring
max_followup <- 200 # 200 days

# Create realistic time-to-event data
# Benefits typically occur earlier (faster onset)
# Risks may occur throughout treatment period

time_event_data <- data.frame(
  subject_id = 1:n_subjects,

  # Benefit types with different timing patterns
  benefit_type = sample(
    c("Symptom Relief", "Clinical Response", "Quality of Life Improvement"),
    n_subjects,
    replace = TRUE,
    prob = c(0.5, 0.3, 0.2)
  ),

  # Risk types with different severity/timing
  risk_type = sample(
    c("Mild AE", "Moderate AE", "Serious AE"),
    n_subjects,
    replace = TRUE,
    prob = c(0.6, 0.3, 0.1)
  )
)

# Generate times based on benefit type
# Symptom Relief: fast (mean 15 days)
# Clinical Response: moderate (mean 40 days)
# QoL Improvement: slower (mean 80 days) - some will be censored
for (i in 1:n_subjects) {
  benefit_rate <- switch(
    time_event_data$benefit_type[i],
    "Symptom Relief" = 1 / 15,
    "Clinical Response" = 1 / 40,
    "Quality of Life Improvement" = 1 / 80
  )
  time_event_data$time_to_benefit[i] <- rexp(1, rate = benefit_rate)
}

# Generate times based on risk type
# Make risks less frequent so more subjects are censored for risk
# Mild AE: later occurrence (mean 60 days)
# Moderate AE: even later (mean 100 days)
# Serious AE: much later (mean 150 days)
for (i in 1:n_subjects) {
  risk_rate <- switch(
    time_event_data$risk_type[i],
    "Mild AE" = 1 / 60,
    "Moderate AE" = 1 / 100,
    "Serious AE" = 1 / 150
  )
  time_event_data$time_to_risk[i] <- rexp(1, rate = risk_rate)
}

# Round to 1 decimal place for cleaner display
time_event_data$time_to_benefit <- round(time_event_data$time_to_benefit, 1)
time_event_data$time_to_risk <- round(time_event_data$time_to_risk, 1)

# Add censoring indicators
# benefit_observed: 1 = observed, 0 = censored
# risk_observed: 1 = observed, 0 = censored
time_event_data$benefit_observed <- ifelse(
  time_event_data$time_to_benefit <= max_followup,
  1,
  0
)
time_event_data$risk_observed <- ifelse(
  time_event_data$time_to_risk <= max_followup,
  1,
  0
)

# For censored events, set time to max_followup
time_event_data$time_to_benefit <- ifelse(
  time_event_data$benefit_observed == 1,
  time_event_data$time_to_benefit,
  max_followup
)
time_event_data$time_to_risk <- ifelse(
  time_event_data$risk_observed == 1,
  time_event_data$time_to_risk,
  max_followup
)

# No additional random censoring - keep only administrative censoring at study end
# This makes interpretation clearer: all censored observations appear at the edges (180 days)

# Add treatment group for potential future use
time_event_data$treatment <- sample(
  c("Drug A", "Drug B"),
  n_subjects,
  replace = TRUE
)

# View summary statistics
cat("\n=== Time-to-Event Data Summary ===\n")
cat("Total subjects:", n_subjects, "\n")
cat("Maximum follow-up:", max_followup, "days\n")
cat("\nBenefit types:\n")
print(table(time_event_data$benefit_type))
cat("\nRisk types:\n")
print(table(time_event_data$risk_type))
cat("\nObservation status:\n")
cat(
  "  Benefits observed:",
  sum(time_event_data$benefit_observed),
  sprintf("(%.1f%%)\n", 100 * mean(time_event_data$benefit_observed))
)
cat(
  "  Risks observed:",
  sum(time_event_data$risk_observed),
  sprintf("(%.1f%%)\n", 100 * mean(time_event_data$risk_observed))
)
cat(
  "  Both observed:",
  sum(
    time_event_data$benefit_observed == 1 & time_event_data$risk_observed == 1
  ),
  sprintf(
    "(%.1f%%)\n",
    100 *
      mean(
        time_event_data$benefit_observed == 1 &
          time_event_data$risk_observed == 1
      )
  )
)
cat(
  "  Only benefit observed:",
  sum(
    time_event_data$benefit_observed == 1 & time_event_data$risk_observed == 0
  ),
  sprintf(
    "(%.1f%%)\n",
    100 *
      mean(
        time_event_data$benefit_observed == 1 &
          time_event_data$risk_observed == 0
      )
  )
)
cat(
  "  Only risk observed:",
  sum(
    time_event_data$benefit_observed == 0 & time_event_data$risk_observed == 1
  ),
  sprintf(
    "(%.1f%%)\n",
    100 *
      mean(
        time_event_data$benefit_observed == 0 &
          time_event_data$risk_observed == 1
      )
  )
)
cat(
  "  Both censored:",
  sum(
    time_event_data$benefit_observed == 0 & time_event_data$risk_observed == 0
  ),
  sprintf(
    "(%.1f%%)\n",
    100 *
      mean(
        time_event_data$benefit_observed == 0 &
          time_event_data$risk_observed == 0
      )
  )
)

# Among subjects with both events observed
both_observed <- time_event_data$benefit_observed == 1 &
  time_event_data$risk_observed == 1
if (sum(both_observed) > 0) {
  cat(
    "\nAmong subjects with BOTH events observed (n =",
    sum(both_observed),
    "):\n"
  )
  cat(
    "  Benefit before risk:",
    sum(
      time_event_data$time_to_benefit[both_observed] <
        time_event_data$time_to_risk[both_observed]
    ),
    sprintf(
      "(%.1f%%)\n",
      100 *
        mean(
          time_event_data$time_to_benefit[both_observed] <
            time_event_data$time_to_risk[both_observed]
        )
    )
  )
  cat(
    "  Mean time to benefit:",
    sprintf("%.1f days\n", mean(time_event_data$time_to_benefit[both_observed]))
  )
  cat(
    "  Mean time to risk:",
    sprintf("%.1f days\n", mean(time_event_data$time_to_risk[both_observed]))
  )
}
cat("\n")

# Save the data
usethis::use_data(time_event_data, overwrite = TRUE)

cat("✓ time_event_data saved to data/time_event_data.rda\n")
