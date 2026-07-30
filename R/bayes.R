# R/bayes.R
# Bayesian posterior probability calculation for renal genetic diagnoses

# Map all structured form inputs to HPO IDs for Bayesian and eligibility scoring.
derive_all_hpo_from_inputs <- function(
  presentation        = character(0),
  haematuria          = "None",
  proteinuria         = "None",
  extra_renal         = character(0),
  egfr                = NA_real_,
  tubulopathy_pattern = character(0),
  ahus_features       = character(0),
  amyloid_features    = character(0)
) {
  ids <- character(0)

  # Cysts on imaging — implies cystic kidney disease HPO terms
  if ("Cysts on imaging" %in% presentation)
    ids <- c(ids, "HP:0000113", "HP:0005584")

  # Haematuria
  if (haematuria %in% c("Microscopic", "Macroscopic"))
    ids <- c(ids, "HP:0000790")

  # Proteinuria
  if (proteinuria == "Sub-nephrotic")
    ids <- c(ids, "HP:0000093")
  else if (proteinuria == "Nephrotic-range")
    ids <- c(ids, "HP:0000093", "HP:0000100")

  # Extra-renal features
  if ("Hearing loss"        %in% extra_renal) ids <- c(ids, "HP:0000407")
  if ("Ocular abnormality"  %in% extra_renal) ids <- c(ids, "HP:0000504")
  if ("Liver cysts"         %in% extra_renal) ids <- c(ids, "HP:0001407")
  if ("Hypertension <35yrs" %in% extra_renal) ids <- c(ids, "HP:0000822")

  # eGFR-derived CKD severity
  if (!is.na(egfr) && is.numeric(egfr)) {
    if (egfr < 60) ids <- c(ids, "HP:0012622")
    if (egfr < 15) ids <- c(ids, "HP:0003774")
  }

  # Tubulopathy / stone patterns
  if ("Hypokalaemia with alkalosis (Bartter / Gitelman)"        %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0002900", "HP:0001942")
  if ("Hypokalaemia with acidosis (proximal RTA / Fanconi)"     %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0002900")
  if ("Hyperkalaemia with acidosis (pseudohypoaldosteronism)"   %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0002153")
  if ("Hypomagnesaemia"                                         %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0002917")
  if ("Nephrogenic diabetes insipidus"                          %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0000863")
  if ("Hypercalciuria"                                          %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0002150")
  if ("Nephrocalcinosis"                                        %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0000121")
  if ("Nephrolithiasis / recurrent kidney stones"               %in% tubulopathy_pattern)
    ids <- c(ids, "HP:0000787")

  # aHUS / thrombotic microangiopathy features
  if ("AKI / acute renal failure"                               %in% ahus_features)
    ids <- c(ids, "HP:0001919")
  if ("Thrombocytopenia"                                        %in% ahus_features)
    ids <- c(ids, "HP:0001873")
  if ("Microangiopathic haemolytic anaemia (MAHA, Coombs negative)" %in% ahus_features)
    ids <- c(ids, "HP:0001903", "HP:0001878", "HP:0005575")

  # Hereditary amyloidosis features
  if ("Restrictive cardiomyopathy"                              %in% amyloid_features)
    ids <- c(ids, "HP:0001638")
  if ("Peripheral or autonomic neuropathy"                      %in% amyloid_features)
    ids <- c(ids, "HP:0001271")

  unique(ids)
}

run_bayesian_update <- function(confirmed_hpo_ids, age, sex, family_history,
                                 consanguinity, biopsy_results,
                                 condition_priors,
                                 hpo_lr_positive, hpo_lr_negative,
                                 family_history_modifiers, consanguinity_modifiers,
                                 biopsy_modifiers, sex_alport_modifiers,
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

  # Apply biopsy modifiers
  for (finding in biopsy_results) {
    mods <- biopsy_modifiers[[finding]]
    if (!is.null(mods)) {
      for (cond in conditions) {
        m <- mods[[cond]]
        if (!is.null(m)) posterior[cond] <- posterior[cond] * m
      }
    }
  }

  # Apply sex modifier (Alport XL vs AR discrimination)
  sex_key <- if (!is.null(sex) && sex %in% names(sex_alport_modifiers)) sex else "Unknown"
  sex_mod <- sex_alport_modifiers[[sex_key]]
  if (!is.null(sex_mod)) {
    for (cond in conditions) {
      m <- sex_mod[[cond]]
      if (!is.null(m)) posterior[cond] <- posterior[cond] * m
    }
  }

  # Apply age modifier
  age_val  <- suppressWarnings(as.numeric(age))
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


# Split the joint posterior (23 conditions + NoGenetic) into:
#   p_genetic   — probability a modelled genetic cause explains the presentation
#   disease_df  — the 23 disease conditions only, renormalised to sum to 1,
#                 i.e. the differential *conditional on* a modelled genetic cause
split_posterior <- function(posterior_df) {
  ng_row    <- posterior_df[posterior_df$condition == "NoGenetic", ]
  p_genetic <- if (nrow(ng_row) == 1) 1 - ng_row$posterior else NA_real_

  disease_df <- posterior_df[posterior_df$condition != "NoGenetic", ]
  denom <- sum(disease_df$posterior)
  if (denom > 0) {
    disease_df$posterior <- disease_df$posterior / denom
    disease_df$ci_lower  <- pmax(0, disease_df$ci_lower / denom)
    disease_df$ci_upper  <- pmin(1, disease_df$ci_upper / denom)
  }
  disease_df <- disease_df[order(disease_df$posterior, decreasing = TRUE), ]
  rownames(disease_df) <- NULL

  list(p_genetic = p_genetic, disease_df = disease_df)
}

build_posterior_plot <- function(posterior_df, condition_labels, condition_colours) {

  df <- posterior_df
  df$label  <- condition_labels[df$condition]
  df$colour <- condition_colours[df$condition]
  df$pct    <- round(df$posterior * 100, 1)
  df$rank   <- seq_len(nrow(df))
  df$label  <- factor(df$label, levels = rev(df$label))

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
    hovertemplate = paste0(
      "<b>%{y}</b><br>",
      "Ranked %{customdata} most likely<br>",
      "<extra></extra>"
    ),
    customdata = ~rank
  ) |>
    plotly::layout(
      xaxis = list(
        title           = "Relative ranking among modelled genetic conditions, if genetic (bar length only — not a clinical probability)",
        showticklabels  = FALSE,
        range           = c(0, min(100, max(df$pct) * 1.35 + 5))
      ),
      yaxis  = list(title = ""),
      margin = list(l = 10, r = 20, t = 10, b = 40),
      showlegend    = FALSE,
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)"
    )
}
