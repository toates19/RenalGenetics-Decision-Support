# R/eligibility.R
# Two-layer eligibility scoring:
#   Layer 1 — strict NHS eligibility criteria (data/strict_criteria.R)
#   Layer 2 — HPO term and structured parameter matching (data/panels.R)

# -----------------------------------------------------------------------------
# Layer 1: strict criteria check
# -----------------------------------------------------------------------------
check_strict_layer <- function(strict, confirmed_hpo_ids, age, egfr,
                                proteinuria, haematuria, family_history,
                                extra_renal, biopsy_results, ancestry,
                                clinical_context) {

  eval_criterion <- function(crit) {
    if (!crit$assessable) return(NA)
    p <- crit$parameter
    v <- crit$value

    switch(p,
      hpo_terms        = any(v %in% confirmed_hpo_ids),
      age              = !is.na(age) && eval_age_criterion(age, v),
      egfr             = !is.na(egfr) && eval_egfr_criterion(egfr, v),
      proteinuria      = proteinuria %in% v,
      haematuria       = haematuria %in% v,
      family_history   = family_history %in% v,
      extra_renal      = any(v %in% extra_renal),
      biopsy_results   = any(v %in% biopsy_results),
      ancestry         = any(v %in% ancestry),
      clinical_context = any(v %in% clinical_context),
      free_text        = NA,
      NA
    )
  }

  # Evaluate required criteria
  req_results  <- lapply(strict$required, eval_criterion)
  req_desc     <- lapply(strict$required, `[[`, "description")

  # Evaluate any_of criteria
  any_results  <- lapply(strict$any_of, eval_criterion)
  any_desc     <- lapply(strict$any_of, `[[`, "description")

  # Classify each (vapply guarantees logical vector even for empty lists)
  req_met      <- vapply(req_results, isTRUE,  logical(1))
  req_failed   <- vapply(req_results, isFALSE, logical(1))
  req_unknown  <- is.na(unlist(req_results))

  any_met      <- vapply(any_results, isTRUE,  logical(1))
  any_failed   <- vapply(any_results, isFALSE, logical(1))
  any_unknown  <- is.na(unlist(any_results))

  # Strict gate
  has_required <- length(strict$required) > 0
  has_any_of   <- length(strict$any_of)   > 0

  required_ok <- if (has_required) !any(req_failed) else TRUE
  any_ok      <- if (has_any_of) {
    if (any(any_met)) TRUE
    else if (all(any_unknown)) NA
    else FALSE
  } else TRUE

  strict_result <- if (!required_ok) {
    "not_met"
  } else if (is.na(any_ok)) {
    "partial"
  } else if (!any_ok) {
    "not_met"
  } else if (any(req_unknown) || any(any_unknown)) {
    "partial"
  } else {
    "met"
  }

  # Build human-readable lists
  strict_met <- c(
    unlist(req_desc[req_met]),
    unlist(any_desc[any_met])
  )
  strict_not <- c(
    unlist(req_desc[req_failed]),
    if (!any(any_met) && has_any_of) "(No required alternative criterion met)" else NULL
  )
  strict_unknown <- c(
    unlist(req_desc[req_unknown]),
    unlist(any_desc[any_unknown])
  )

  list(
    result           = strict_result,
    criteria_met     = strict_met,
    criteria_not     = strict_not,
    criteria_unknown = strict_unknown
  )
}

# -----------------------------------------------------------------------------
# Layer 2: HPO + structured parameter matching
# -----------------------------------------------------------------------------
score_hpo_layer <- function(panel, confirmed_hpo_ids, age, sex,
                             proteinuria, haematuria, family_history,
                             extra_renal, egfr, consanguinity) {
  major_met     <- character(0)
  major_not_met <- character(0)

  for (crit_name in names(panel$major_criteria)) {
    crit  <- panel$major_criteria[[crit_name]]
    param <- crit$parameter
    val   <- crit$value
    met   <- FALSE

    if (param == "hpo_terms" && !is.null(val)) {
      met <- any(val %in% confirmed_hpo_ids)
    } else if (param == "age" && !is.null(val) && !is.na(age)) {
      met <- eval_age_criterion(age, val)
    } else if (param == "proteinuria" && !is.null(val)) {
      met <- proteinuria %in% val
    } else if (param == "haematuria" && !is.null(val)) {
      met <- haematuria %in% val
    } else if (param == "family_history" && !is.null(val)) {
      met <- family_history %in% val
    } else if (param == "extra_renal" && !is.null(val)) {
      met <- any(val %in% extra_renal)
    } else if (param == "egfr" && !is.null(val) && !is.na(egfr)) {
      met <- eval_egfr_criterion(egfr, val)
    } else if (param == "consanguinity" && !is.null(val)) {
      met <- consanguinity %in% val
    } else if (param == "free_text") {
      next
    }

    if (met) major_met <- c(major_met, crit$description)
    else     major_not_met <- c(major_not_met, crit$description)
  }

  hpo_overlap <- intersect(confirmed_hpo_ids, panel$hpo_relevant)

  list(
    criteria_met = major_met,
    criteria_not = major_not_met,
    hpo_overlap  = hpo_overlap,
    n_met        = length(major_met),
    n_overlap    = length(hpo_overlap)
  )
}

# -----------------------------------------------------------------------------
# Combined scoring
# -----------------------------------------------------------------------------
score_panel_eligibility <- function(panel, strict, confirmed_hpo_ids, age, sex,
                                     proteinuria, haematuria, family_history,
                                     extra_renal, egfr, consanguinity,
                                     biopsy_results, ancestry, clinical_context) {

  layer1 <- check_strict_layer(strict, confirmed_hpo_ids, age, egfr,
                                proteinuria, haematuria, family_history,
                                extra_renal, biopsy_results, ancestry,
                                clinical_context)

  layer2 <- score_hpo_layer(panel, confirmed_hpo_ids, age, sex,
                             proteinuria, haematuria, family_history,
                             extra_renal, egfr, consanguinity)

  eligibility <- if (layer1$result == "not_met") {
    "Unlikely eligible"
  } else {
    if (layer2$n_met >= 2 || layer2$n_overlap >= 3) {
      "Likely eligible"
    } else if (layer1$result == "met") {
      # Strict criteria fully met with no contradicting evidence → already qualifies
      "Likely eligible"
    } else if (layer2$n_met >= 1 || layer2$n_overlap >= 1) {
      "Possibly eligible"
    } else {
      # layer1 == "partial" and no supportive layer2 hits
      "Possibly eligible"
    }
  }

  list(
    code              = panel$code,
    name              = panel$name,
    eligibility       = eligibility,
    strict_result     = layer1$result,
    strict_met        = layer1$criteria_met,
    strict_not        = layer1$criteria_not,
    strict_unknown    = layer1$criteria_unknown,
    hpo_criteria_met  = layer2$criteria_met,
    hpo_criteria_not  = layer2$criteria_not,
    hpo_overlap       = layer2$hpo_overlap,
    notes             = panel$notes
  )
}

# -----------------------------------------------------------------------------
# Run all panels
# -----------------------------------------------------------------------------
run_eligibility_all_panels <- function(panels, strict_criteria,
                                        confirmed_hpo_ids, age, sex,
                                        proteinuria, haematuria, family_history,
                                        extra_renal, egfr, consanguinity,
                                        biopsy_results, ancestry, clinical_context) {
  lapply(names(panels), function(code) {
    panel  <- panels[[code]]
    strict <- strict_criteria[[code]]
    if (is.null(strict)) strict <- list(required = list(), any_of = list())
    score_panel_eligibility(panel, strict, confirmed_hpo_ids, age, sex,
                            proteinuria, haematuria, family_history,
                            extra_renal, egfr, consanguinity,
                            biopsy_results, ancestry, clinical_context)
  })
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
eval_age_criterion <- function(age, val_string) {
  val_string <- trimws(val_string)
  threshold  <- as.numeric(gsub("[^0-9]", "", val_string))
  if (grepl("^<", val_string)) return(age < threshold)
  if (grepl("^>", val_string)) return(age > threshold)
  FALSE
}

eval_egfr_criterion <- function(egfr, val_string) {
  val_string <- trimws(val_string)
  threshold  <- as.numeric(gsub("[^0-9]", "", val_string))
  if (grepl("^<", val_string)) return(egfr < threshold)
  if (grepl("^>", val_string)) return(egfr > threshold)
  FALSE
}

eligibility_icon <- function(label) {
  switch(label,
    "Likely eligible"   = "\U1F7E2",
    "Possibly eligible" = "\U1F7E1",
    "Unlikely eligible" = "\U1F534",
    ""
  )
}

strict_icon <- function(result) {
  switch(result,
    "met"     = "✅",
    "partial" = "⚠️",
    "not_met" = "❌",
    "❓"
  )
}

strict_label <- function(result) {
  switch(result,
    "met"     = "Strict criteria met",
    "partial" = "Partially assessable",
    "not_met" = "Strict criteria not met",
    "Unknown"
  )
}
