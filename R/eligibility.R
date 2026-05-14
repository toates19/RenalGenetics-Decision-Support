# R/eligibility.R
# NHS Genomic Test Directory eligibility scoring against renal_panels

score_panel_eligibility <- function(panel, confirmed_hpo_ids, age, sex,
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
      next  # cannot assess free-text criteria programmatically
    }

    if (met) {
      major_met <- c(major_met, crit$description)
    } else {
      major_not_met <- c(major_not_met, crit$description)
    }
  }

  # HPO overlap contribution
  hpo_overlap <- intersect(confirmed_hpo_ids, panel$hpo_relevant)
  if (length(hpo_overlap) >= 2 && length(major_met) == 0) {
    major_met <- c(major_met, paste0("HPO term overlap: ", length(hpo_overlap), " relevant terms matched"))
  }

  n_met <- length(major_met)

  eligibility <- if (n_met >= 2) {
    "Likely eligible"
  } else if (n_met == 1 || length(hpo_overlap) >= 1) {
    "Possibly eligible"
  } else {
    "Unlikely eligible"
  }

  list(
    code          = panel$code,
    name          = panel$name,
    eligibility   = eligibility,
    criteria_met  = major_met,
    criteria_not  = major_not_met,
    hpo_overlap   = hpo_overlap,
    notes         = panel$notes
  )
}

eval_age_criterion <- function(age, val_string) {
  # val_string like "< 18", "< 30", "< 60", "> 50"
  val_string <- trimws(val_string)
  if (grepl("^<\\s*\\d+", val_string)) {
    threshold <- as.numeric(gsub("[^0-9]", "", val_string))
    return(age < threshold)
  }
  if (grepl("^>\\s*\\d+", val_string)) {
    threshold <- as.numeric(gsub("[^0-9]", "", val_string))
    return(age > threshold)
  }
  FALSE
}

eval_egfr_criterion <- function(egfr, val_string) {
  val_string <- trimws(val_string)
  if (grepl("^<\\s*\\d+", val_string)) {
    threshold <- as.numeric(gsub("[^0-9]", "", val_string))
    return(egfr < threshold)
  }
  if (grepl("^>\\s*\\d+", val_string)) {
    threshold <- as.numeric(gsub("[^0-9]", "", val_string))
    return(egfr > threshold)
  }
  FALSE
}

run_eligibility_all_panels <- function(panels, confirmed_hpo_ids, age, sex,
                                        proteinuria, haematuria, family_history,
                                        extra_renal, egfr, consanguinity) {
  results <- lapply(panels, function(p) {
    score_panel_eligibility(p, confirmed_hpo_ids, age, sex,
                            proteinuria, haematuria, family_history,
                            extra_renal, egfr, consanguinity)
  })
  results
}

eligibility_badge_class <- function(label) {
  switch(label,
    "Likely eligible"   = "success",
    "Possibly eligible" = "warning",
    "Unlikely eligible" = "danger",
    "secondary"
  )
}

eligibility_icon <- function(label) {
  switch(label,
    "Likely eligible"   = "\U1F7E2",
    "Possibly eligible" = "\U1F7E1",
    "Unlikely eligible" = "\U1F534",
    ""
  )
}
