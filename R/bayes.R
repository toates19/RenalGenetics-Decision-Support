# R/bayes.R
# Bayesian posterior probability calculation for renal genetic diagnoses

run_bayesian_update <- function(confirmed_hpo_ids, age, family_history,
                                 consanguinity, condition_priors,
                                 hpo_lr_positive, hpo_lr_negative,
                                 family_history_modifiers, consanguinity_modifiers,
                                 age_modifier_fn) {

  conditions <- names(condition_priors)
  posterior  <- setNames(as.numeric(condition_priors), conditions)

  # Apply family history modifier
  fh_mod <- family_history_modifiers[[family_history]]
  if (!is.null(fh_mod)) {
    for (cond in conditions) {
      m <- fh_mod[[cond]]
      if (!is.null(m)) posterior[cond] <- posterior[cond] * m
    }
  }

  # Apply consanguinity modifier
  cons_mod <- consanguinity_modifiers[[consanguinity]]
  if (!is.null(cons_mod)) {
    for (cond in conditions) {
      m <- cons_mod[[cond]]
      if (!is.null(m)) posterior[cond] <- posterior[cond] * m
    }
  }

  # Apply age modifier
  age_val <- suppressWarnings(as.numeric(age))
  age_mods <- age_modifier_fn(age_val)
  for (cond in conditions) {
    posterior[cond] <- posterior[cond] * age_mods[cond]
  }

  # Apply positive LRs for confirmed HPO terms
  all_key_hpo <- names(Filter(function(x) isTRUE(x$key), hpo_lr_positive))

  for (hpo_id in confirmed_hpo_ids) {
    lr_entry <- hpo_lr_positive[[hpo_id]]
    if (is.null(lr_entry)) next
    for (cond in conditions) {
      lr_val <- lr_entry[[cond]]
      if (!is.null(lr_val) && is.numeric(lr_val)) {
        posterior[cond] <- posterior[cond] * lr_val
      }
    }
  }

  # Apply negative LRs for KEY terms that are absent
  absent_key_hpo <- setdiff(all_key_hpo, confirmed_hpo_ids)
  for (hpo_id in absent_key_hpo) {
    neg_lrs <- hpo_lr_negative[[hpo_id]]
    if (is.null(neg_lrs)) next
    for (cond in conditions) {
      lr_val <- neg_lrs[cond]
      if (!is.na(lr_val) && is.numeric(lr_val)) {
        posterior[cond] <- posterior[cond] * lr_val
      }
    }
  }

  # Normalise to sum to 1
  total <- sum(posterior)
  if (total > 0) posterior <- posterior / total

  # Approximate 95% credible interval: ±1.96 * sqrt(p(1-p)/n)
  n <- max(length(confirmed_hpo_ids), 1)
  ci_df <- data.frame(
    condition = conditions,
    posterior = as.numeric(posterior),
    ci_lower  = pmax(0, as.numeric(posterior) - 1.96 * sqrt(as.numeric(posterior) * (1 - as.numeric(posterior)) / n)),
    ci_upper  = pmin(1, as.numeric(posterior) + 1.96 * sqrt(as.numeric(posterior) * (1 - as.numeric(posterior)) / n)),
    stringsAsFactors = FALSE
  )

  ci_df <- ci_df[order(ci_df$posterior, decreasing = TRUE), ]
  rownames(ci_df) <- NULL
  ci_df
}

build_posterior_plot <- function(posterior_df, condition_labels, condition_colours) {

  df <- posterior_df
  df$label      <- condition_labels[df$condition]
  df$colour     <- condition_colours[df$condition]
  df$pct        <- round(df$posterior * 100, 1)
  df$pct_label  <- paste0(df$pct, "%")
  df$label      <- factor(df$label, levels = rev(df$label))

  plotly::plot_ly(
    data        = df,
    y           = ~label,
    x           = ~pct,
    type        = "bar",
    orientation = "h",
    marker      = list(color = ~colour),
    error_x     = list(
      type      = "data",
      symmetric = FALSE,
      plus      = ~pmax(0, (ci_upper - posterior) * 100),
      minus     = ~pmax(0, (posterior - ci_lower) * 100),
      color     = "#555555",
      thickness = 1.5,
      width     = 4
    ),
    text        = ~pct_label,
    textposition = "outside",
    hovertemplate = paste0(
      "<b>%{y}</b><br>",
      "Posterior: %{x:.1f}%<br>",
      "<extra></extra>"
    )
  ) |>
    plotly::layout(
      xaxis = list(
        title      = "Posterior Probability (%)",
        range      = c(0, min(100, max(df$pct) * 1.3 + 5)),
        ticksuffix = "%"
      ),
      yaxis  = list(title = ""),
      margin = list(l = 10, r = 60, t = 10, b = 40),
      showlegend = FALSE,
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)"
    )
}
