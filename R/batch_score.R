# R/batch_score.R
# -----------------------------------------------------------------------------
# Batch scoring harness for the validation study.
#
# Runs the eligibility scorer and the Bayesian differential over rows extracted
# into RenalGenetics_Validation_Template.xlsx, without going through the Shiny
# reactive layer.
#
# FIDELITY RULE
# -------------
# This harness must reproduce exactly what the app would compute for the same
# patient. The app builds its branch-specific inputs conditionally: a control
# such as `haematuria` or `biopsy_haem` only exists once the matching box is
# ticked in the "Primary presentation(s)" picker, and `inp(id, default)` falls
# back to the default when the control is absent (app.R ~line 279). So a
# recorded feature that sits under an unticked presentation is invisible to the
# app.
#
# We mirror that gating rather than "improving" on it — otherwise the harness
# would score a patient more favourably than the tool being validated. Rows
# where a recorded feature is dropped by the gate are reported in the `warnings`
# column so the discrepancy is visible rather than silent.
#
# Usage:
#   source("R/batch_score.R")
#   res <- batch_score_file("RenalGenetics_Validation_Template.xlsx")
#   summ <- summarise_validation(res)
# -----------------------------------------------------------------------------

# --- Vocabularies, copied verbatim from the app UI ---------------------------
# Any drift between these and app.R silently invalidates the study, so they are
# asserted against the model parameters in check_harness_fidelity() below.

PRESENTATION_CHOICES <- c(
  "Cysts on imaging",
  "Haematuria",
  "Proteinuria / nephrotic syndrome",
  "Tubulopathy or kidney stones",
  "Unexplained renal impairment / early ESKD",
  "Systemic features (aHUS or amyloidosis)",
  "Kidney donor assessment (APOL1)"
)

CLINICAL_CONTEXT_CHOICES <- c(
  "Genetic diagnosis required for management",
  "Renal transplant being considered",
  "Complement inhibitory therapy being considered",
  "Being assessed for living kidney donation",
  "Counselled and consented for APOL1 testing"
)

BIOPSY_TIKD_UI <- "Tubulointerstitial fibrosis (no glomerular lesion)"

# --- Small helpers -----------------------------------------------------------

is_yes <- function(x) {
  if (is.null(x) || length(x) == 0) return(FALSE)
  x <- toupper(trimws(as.character(x[1])))
  !is.na(x) && x %in% c("Y", "YES", "TRUE", "1")
}

blank_to_na <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  x <- trimws(as.character(x[1]))
  if (is.na(x) || x == "") NA_character_ else x
}

num_or_na <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_real_)
  suppressWarnings(as.numeric(x[1]))
}

# -----------------------------------------------------------------------------
# Map one template row to the app's input set.
#
# Returns a list with the same shape the app assembles before calling
# run_eligibility_all_panels() and run_bayesian_update(), plus a character
# vector of warnings describing anything the presentation gate discarded.
# -----------------------------------------------------------------------------
template_row_to_inputs <- function(row) {
  g <- function(col) if (col %in% names(row)) row[[col]] else NULL
  warn <- character(0)

  # ---- presentation picker -------------------------------------------------
  presentation <- character(0)
  if (is_yes(g("Pres_Cysts")))            presentation <- c(presentation, "Cysts on imaging")
  if (is_yes(g("Pres_Haematuria")))       presentation <- c(presentation, "Haematuria")
  if (is_yes(g("Pres_Proteinuria")))      presentation <- c(presentation, "Proteinuria / nephrotic syndrome")
  if (is_yes(g("Pres_Tubulopathy_Stones"))) presentation <- c(presentation, "Tubulopathy or kidney stones")
  if (is_yes(g("Pres_Unexplained_ESKD"))) presentation <- c(presentation, "Unexplained renal impairment / early ESKD")
  if (is_yes(g("Pres_Systemic")))         presentation <- c(presentation, "Systemic features (aHUS or amyloidosis)")
  if (is_yes(g("Pres_APOL1_Donor")))      presentation <- c(presentation, "Kidney donor assessment (APOL1)")

  has_cysts   <- "Cysts on imaging" %in% presentation
  has_haem    <- "Haematuria" %in% presentation
  has_prot    <- "Proteinuria / nephrotic syndrome" %in% presentation
  has_tubulo  <- "Tubulopathy or kidney stones" %in% presentation
  has_eskd    <- "Unexplained renal impairment / early ESKD" %in% presentation
  has_systemic<- "Systemic features (aHUS or amyloidosis)" %in% presentation
  has_donor   <- "Kidney donor assessment (APOL1)" %in% presentation

  # Warn when a recorded feature sits under an unticked presentation. The app
  # would not see it, so neither do we — but the extractor should know.
  gate_warn <- function(cond_present, cols, branch) {
    if (cond_present) return(invisible(NULL))
    live <- cols[vapply(cols, function(cc) {
      v <- g(cc)
      if (is.null(v)) return(FALSE)
      if (cc == "Haematuria_type" || cc == "Proteinuria_level") return(!is.na(blank_to_na(v)))
      is_yes(v)
    }, logical(1))]
    if (length(live)) {
      warn <<- c(warn, sprintf("%s recorded but %s not ticked - ignored by the app: %s",
                               if (length(live) == 1) "feature" else "features",
                               branch, paste(live, collapse = ", ")))
    }
  }

  gate_warn(has_haem, c("Haematuria_type", "Biopsy_Alport_GBM", "Biopsy_TBMD",
                        "Hearing_loss", "Ocular_abnormality", "Ancestry_Cypriot"),
            "Pres_Haematuria")
  gate_warn(has_cysts, c("Liver_cysts"), "Pres_Cysts")
  gate_warn(has_prot, c("Proteinuria_level", "Biopsy_FSGS", "Biopsy_C3G_MPGN"),
            "Pres_Proteinuria")
  gate_warn(has_tubulo, c("Tubulo_HypoK_alkalosis", "Tubulo_HypoK_acidosis",
                          "Tubulo_HyperK_acidosis", "Tubulo_Hypomagnesaemia",
                          "Tubulo_NDI", "Tubulo_Hypercalciuria",
                          "Tubulo_Nephrocalcinosis", "Tubulo_Nephrolithiasis"),
            "Pres_Tubulopathy_Stones")
  gate_warn(has_eskd, c("Biopsy_TIKD"), "Pres_Unexplained_ESKD")
  gate_warn(has_systemic, c("aHUS_AKI", "aHUS_Thrombocytopenia", "aHUS_MAHA",
                            "Amyloid_Cardiomyopathy", "Amyloid_Neuropathy"),
            "Pres_Systemic")
  gate_warn(has_donor, c("Ancestry_African_Carib"), "Pres_APOL1_Donor")

  # ---- branch-gated inputs -------------------------------------------------
  haematuria <- "None"
  if (has_haem) {
    ht <- blank_to_na(g("Haematuria_type"))
    haematuria <- if (!is.na(ht) && ht %in% c("Microscopic", "Macroscopic")) ht else "Microscopic"
  }

  proteinuria <- "None"
  if (has_prot) {
    pl <- blank_to_na(g("Proteinuria_level"))
    proteinuria <- if (!is.na(pl) && pl %in% c("Sub-nephrotic", "Nephrotic-range")) pl else "Sub-nephrotic"
  }

  biopsy <- character(0)
  if (has_haem) {
    if (is_yes(g("Biopsy_Alport_GBM")))
      biopsy <- c(biopsy, "GBM thickening with splitting/lamellation on EM (Alport pattern)")
    if (is_yes(g("Biopsy_TBMD")))
      biopsy <- c(biopsy, "Thin basement membrane disease")
  }
  if (has_prot) {
    if (is_yes(g("Biopsy_FSGS")))      biopsy <- c(biopsy, "FSGS or diffuse mesangial sclerosis")
    if (is_yes(g("Biopsy_C3G_MPGN")))  biopsy <- c(biopsy, "C3 glomerulopathy or MPGN")
  }
  if (has_eskd && is_yes(g("Biopsy_TIKD"))) biopsy <- c(biopsy, BIOPSY_TIKD_UI)
  biopsy <- unique(biopsy)

  extra_renal <- character(0)
  if (has_haem) {
    if (is_yes(g("Hearing_loss")))       extra_renal <- c(extra_renal, "Hearing loss")
    if (is_yes(g("Ocular_abnormality"))) extra_renal <- c(extra_renal, "Ocular abnormality")
  }
  if (has_cysts && is_yes(g("Liver_cysts"))) extra_renal <- c(extra_renal, "Liver cysts")
  if (is_yes(g("HTN_onset_under35")))        extra_renal <- c(extra_renal, "Hypertension <35yrs")
  extra_renal <- unique(extra_renal)

  ancestry <- character(0)
  if (has_haem  && is_yes(g("Ancestry_Cypriot")))
    ancestry <- c(ancestry, "Cypriot or eastern Mediterranean")
  if (has_donor && is_yes(g("Ancestry_African_Carib")))
    ancestry <- c(ancestry, "African, African-American, Caribbean or Brazilian")

  tubulo <- character(0)
  if (has_tubulo) {
    if (is_yes(g("Tubulo_HypoK_alkalosis")))  tubulo <- c(tubulo, "Hypokalaemia with alkalosis (Bartter / Gitelman)")
    if (is_yes(g("Tubulo_HypoK_acidosis")))   tubulo <- c(tubulo, "Hypokalaemia with acidosis (proximal RTA / Fanconi)")
    if (is_yes(g("Tubulo_HyperK_acidosis")))  tubulo <- c(tubulo, "Hyperkalaemia with acidosis (pseudohypoaldosteronism)")
    if (is_yes(g("Tubulo_Hypomagnesaemia")))  tubulo <- c(tubulo, "Hypomagnesaemia")
    if (is_yes(g("Tubulo_NDI")))              tubulo <- c(tubulo, "Nephrogenic diabetes insipidus")
    if (is_yes(g("Tubulo_Hypercalciuria")))   tubulo <- c(tubulo, "Hypercalciuria")
    if (is_yes(g("Tubulo_Nephrocalcinosis"))) tubulo <- c(tubulo, "Nephrocalcinosis")
    if (is_yes(g("Tubulo_Nephrolithiasis")))  tubulo <- c(tubulo, "Nephrolithiasis / recurrent kidney stones")
  }

  ahus <- character(0)
  amyloid <- character(0)
  if (has_systemic) {
    if (is_yes(g("aHUS_AKI")))              ahus <- c(ahus, "AKI / acute renal failure")
    if (is_yes(g("aHUS_Thrombocytopenia"))) ahus <- c(ahus, "Thrombocytopenia")
    if (is_yes(g("aHUS_MAHA")))             ahus <- c(ahus, "Microangiopathic haemolytic anaemia (MAHA, Coombs negative)")
    if (is_yes(g("Amyloid_Cardiomyopathy"))) amyloid <- c(amyloid, "Restrictive cardiomyopathy")
    if (is_yes(g("Amyloid_Neuropathy")))     amyloid <- c(amyloid, "Peripheral or autonomic neuropathy")
  }

  context <- character(0)
  if (is_yes(g("Ctx_Genetic_dx_for_mgmt")))     context <- c(context, "Genetic diagnosis required for management")
  if (is_yes(g("Ctx_Transplant_considered")))   context <- c(context, "Renal transplant being considered")
  if (is_yes(g("Ctx_Complement_therapy")))      context <- c(context, "Complement inhibitory therapy being considered")
  if (is_yes(g("Ctx_Living_donor_assessment"))) context <- c(context, "Being assessed for living kidney donation")
  if (is_yes(g("Ctx_APOL1_consented")))         context <- c(context, "Counselled and consented for APOL1 testing")

  # ---- universal fields ----------------------------------------------------
  sex <- blank_to_na(g("Sex"))
  if (is.na(sex) || !sex %in% c("Male", "Female", "Unknown")) sex <- "Unknown"

  fh <- blank_to_na(g("Family_history"))
  # The app's selectInput labels the fifth option "Present but pattern unknown"
  # but its VALUE is "Unknown" — extractors write the label, so accept both.
  if (identical(fh, "Present but pattern unknown")) fh <- "Unknown"
  if (is.na(fh) || !fh %in% c("None", "Autosomal dominant", "Autosomal recessive",
                              "X-linked", "Unknown")) fh <- "None"

  cons <- blank_to_na(g("Consanguinity"))
  if (is.na(cons) || !cons %in% c("Yes", "No", "Unknown")) cons <- "Unknown"

  if (length(presentation) == 0)
    warn <- c(warn, "no presentation ticked - the app would have nothing to score")

  list(
    presentation        = presentation,
    age                 = num_or_na(g("Age_presentation_yrs")),
    sex                 = sex,
    egfr                = num_or_na(g("eGFR_mLmin")),
    family_history      = fh,
    consanguinity       = cons,
    haematuria          = haematuria,
    proteinuria         = proteinuria,
    biopsy_results      = biopsy,
    extra_renal         = extra_renal,
    ancestry            = ancestry,
    clinical_context    = context,
    tubulopathy_pattern = tubulo,
    ahus_features       = ahus,
    amyloid_features    = amyloid,
    warnings            = warn
  )
}

# -----------------------------------------------------------------------------
# Score a single patient. Returns a one-row data.frame.
# -----------------------------------------------------------------------------
score_one <- function(inp, patient_id = NA_character_,
                      panel_tested = NA_character_,
                      model_condition = NA_character_) {

  hpo <- derive_all_hpo_from_inputs(
    presentation        = inp$presentation,
    haematuria          = inp$haematuria,
    proteinuria         = inp$proteinuria,
    extra_renal         = inp$extra_renal,
    egfr                = inp$egfr,
    tubulopathy_pattern = inp$tubulopathy_pattern,
    ahus_features       = inp$ahus_features,
    amyloid_features    = inp$amyloid_features
  )

  elig <- run_eligibility_all_panels(
    panels            = renal_panels,
    strict_criteria   = panel_strict_criteria,
    confirmed_hpo_ids = hpo,
    age               = inp$age,
    sex               = inp$sex,
    proteinuria       = inp$proteinuria,
    haematuria        = inp$haematuria,
    family_history    = inp$family_history,
    extra_renal       = inp$extra_renal,
    egfr              = inp$egfr,
    consanguinity     = inp$consanguinity,
    biopsy_results    = inp$biopsy_results,
    ancestry          = inp$ancestry,
    clinical_context  = inp$clinical_context
  )

  elig_code  <- vapply(elig, `[[`, character(1), "code")
  elig_label <- vapply(elig, `[[`, character(1), "eligibility")
  likely     <- elig_code[elig_label == "Likely eligible"]
  possibly   <- elig_code[elig_label == "Possibly eligible"]

  post <- run_bayesian_update(
    confirmed_hpo_ids        = hpo,
    age                      = inp$age,
    sex                      = inp$sex,
    family_history           = inp$family_history,
    consanguinity            = inp$consanguinity,
    biopsy_results           = inp$biopsy_results,
    condition_priors         = condition_priors,
    hpo_lr_positive          = hpo_lr_positive,
    hpo_lr_negative          = hpo_lr_negative,
    family_history_modifiers = family_history_modifiers,
    consanguinity_modifiers  = consanguinity_modifiers,
    biopsy_modifiers         = biopsy_modifiers,
    sex_alport_modifiers     = sex_alport_modifiers,
    age_modifier_fn          = age_modifier
  )

  split <- split_posterior(post)
  dd    <- split$disease_df
  dd    <- dd[order(-dd$posterior), ]
  ranked <- as.character(dd[[1]])

  # Rank of the confirmed diagnosis within the disease-only differential.
  # NoGenetic and Not_modelled have no rank by construction.
  true_cond <- blank_to_na(model_condition)
  rank_true <- NA_integer_
  if (!is.na(true_cond) && true_cond %in% ranked) {
    rank_true <- which(ranked == true_cond)[1]
  }

  # Was the panel actually sent flagged as reachable by the app?
  sent <- blank_to_na(panel_tested)
  sent_codes <- if (is.na(sent)) character(0) else trimws(strsplit(sent, ",")[[1]])
  panel_hit <- if (!length(sent_codes)) NA
               else all(sent_codes %in% c(likely, possibly))

  data.frame(
    Patient_ID       = patient_id,
    n_hpo            = length(hpo),
    hpo_ids          = paste(hpo, collapse = ";"),
    p_genetic        = split$p_genetic,
    top1             = if (length(ranked) >= 1) ranked[1] else NA_character_,
    top1_p           = if (nrow(dd) >= 1) dd$posterior[1] else NA_real_,
    top2             = if (length(ranked) >= 2) ranked[2] else NA_character_,
    top3             = if (length(ranked) >= 3) ranked[3] else NA_character_,
    true_condition   = true_cond,
    rank_true        = rank_true,
    top1_correct     = if (is.na(rank_true)) NA else rank_true == 1L,
    top3_correct     = if (is.na(rank_true)) NA else rank_true <= 3L,
    panel_tested     = sent,
    panels_likely    = paste(likely, collapse = ";"),
    panels_possible  = paste(possibly, collapse = ";"),
    panel_flagged    = panel_hit,
    warnings         = paste(inp$warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
}

# -----------------------------------------------------------------------------
# Score a whole extraction sheet.
# -----------------------------------------------------------------------------
batch_score <- function(df) {
  stopifnot(is.data.frame(df))
  if (!"Patient_ID" %in% names(df))
    stop("input has no Patient_ID column - is this the Data Entry sheet?")

  df <- df[!is.na(df$Patient_ID) & trimws(as.character(df$Patient_ID)) != "", , drop = FALSE]
  if (nrow(df) == 0) stop("no data rows found (Patient_ID is blank on every row)")

  out <- lapply(seq_len(nrow(df)), function(i) {
    row <- as.list(df[i, , drop = FALSE])
    inp <- template_row_to_inputs(row)
    score_one(inp,
              patient_id      = as.character(row$Patient_ID),
              panel_tested    = row$Panel_tested,
              model_condition = row$Model_condition)
  })
  do.call(rbind, out)
}

batch_score_file <- function(path = "RenalGenetics_Validation_Template.xlsx",
                             sheet = "Data Entry") {
  if (!requireNamespace("openxlsx", quietly = TRUE))
    stop("package 'openxlsx' is required to read the template")
  # Row 1 is the group banner; row 2 holds the real column names.
  df <- openxlsx::read.xlsx(path, sheet = sheet, startRow = 2, colNames = TRUE)
  batch_score(df)
}

# -----------------------------------------------------------------------------
# Study-level metrics, matching the pre-specified analysis plan.
# -----------------------------------------------------------------------------
summarise_validation <- function(res) {
  n <- nrow(res)

  # --- Primary endpoint: calibration of p(genetic) --------------------------
  # A patient counts as genetically positive if a P/LP variant was found —
  # including one in a gene the model does not cover (Not_modelled). Treating
  # those as negatives would bias observed yield downward.
  tc <- res$true_condition
  known <- !is.na(tc)
  positive <- known & tc != "NoGenetic"
  observed_yield <- if (any(known)) mean(positive[known]) else NA_real_
  mean_predicted <- mean(res$p_genetic, na.rm = TRUE)

  ci <- function(p, n) {
    if (is.na(p) || n == 0) return(c(NA_real_, NA_real_))
    se <- sqrt(p * (1 - p) / n)
    c(max(0, p - 1.96 * se), min(1, p + 1.96 * se))
  }
  yield_ci <- ci(observed_yield, sum(known))

  # Brier score of the headline probability against the binary outcome
  brier <- if (any(known)) mean((res$p_genetic[known] - as.numeric(positive[known]))^2) else NA_real_

  # --- Secondary: differential ranking --------------------------------------
  # Denominator is gene-positive patients whose diagnosis the model can express.
  rankable <- !is.na(res$rank_true)
  n_rankable <- sum(rankable)
  n_not_modelled <- sum(known & tc == "Not_modelled", na.rm = TRUE)
  top1 <- if (n_rankable) mean(res$top1_correct[rankable]) else NA_real_
  top3 <- if (n_rankable) mean(res$top3_correct[rankable]) else NA_real_

  # --- Secondary: eligibility ----------------------------------------------
  pf <- res$panel_flagged
  assessable <- !is.na(pf)
  panel_agreement <- if (any(assessable)) mean(as.logical(pf[assessable])) else NA_real_

  structure(list(
    n_patients        = n,
    n_with_result     = sum(known),
    observed_yield    = observed_yield,
    yield_ci          = yield_ci,
    mean_predicted    = mean_predicted,
    brier             = brier,
    n_rankable        = n_rankable,
    n_not_modelled    = n_not_modelled,
    top1_accuracy     = top1,
    top1_ci           = ci(top1, n_rankable),
    top3_accuracy     = top3,
    top3_ci           = ci(top3, n_rankable),
    panel_agreement   = panel_agreement,
    n_panel_assessable = sum(assessable),
    n_with_warnings   = sum(nzchar(res$warnings))
  ), class = "renalgenetics_validation")
}

print.renalgenetics_validation <- function(x, ...) {
  pc <- function(v) if (is.na(v)) "  n/a" else sprintf("%5.1f%%", 100 * v)
  cat("\nRenalGenetics validation summary\n")
  cat(strrep("-", 62), "\n")
  cat(sprintf("Patients scored                    %d (%d with a recorded result)\n",
              x$n_patients, x$n_with_result))
  cat("\nPRIMARY - calibration of p(genetic)\n")
  cat(sprintf("  Observed diagnostic yield        %s  (95%% CI %s - %s)\n",
              pc(x$observed_yield), pc(x$yield_ci[1]), pc(x$yield_ci[2])))
  cat(sprintf("  Mean predicted p(genetic)        %s\n", pc(x$mean_predicted)))
  cat(sprintf("  Brier score                      %s\n",
              if (is.na(x$brier)) "  n/a" else sprintf("%5.3f", x$brier)))
  if (!is.na(x$observed_yield) && !is.na(x$mean_predicted)) {
    if (x$observed_yield > x$yield_ci[1] && x$mean_predicted < x$yield_ci[1])
      cat("  -> model UNDER-predicts: observed yield exceeds the predicted mean\n")
    else if (x$mean_predicted > x$yield_ci[2])
      cat("  -> model OVER-predicts: predicted mean exceeds the observed CI\n")
    else
      cat("  -> predicted mean lies within the observed CI\n")
  }
  cat("\nSECONDARY - differential ranking (exploratory at pilot size)\n")
  cat(sprintf("  Rankable gene-positive cases     %d", x$n_rankable))
  if (x$n_not_modelled > 0)
    cat(sprintf("  (+%d Not_modelled, excluded)", x$n_not_modelled))
  cat("\n")
  cat(sprintf("  Top-1 accuracy                   %s  (95%% CI %s - %s)\n",
              pc(x$top1_accuracy), pc(x$top1_ci[1]), pc(x$top1_ci[2])))
  cat(sprintf("  Top-3 accuracy                   %s  (95%% CI %s - %s)\n",
              pc(x$top3_accuracy), pc(x$top3_ci[1]), pc(x$top3_ci[2])))
  cat("\nSECONDARY - eligibility\n")
  cat(sprintf("  Panel sent was flagged by app    %s  (n = %d assessable)\n",
              pc(x$panel_agreement), x$n_panel_assessable))
  if (x$n_with_warnings > 0)
    cat(sprintf("\n%d row(s) carry extraction warnings - review the warnings column.\n",
                x$n_with_warnings))
  cat("\n")
  invisible(x)
}

# -----------------------------------------------------------------------------
# Fidelity check. Run before trusting any results: catches the case where the
# app's vocabulary has drifted away from the model parameter keys, which would
# silently disable a modifier rather than raise an error.
# -----------------------------------------------------------------------------
check_harness_fidelity <- function(verbose = TRUE) {
  problems <- character(0)

  ui_biopsy <- c("GBM thickening with splitting/lamellation on EM (Alport pattern)",
                 "Thin basement membrane disease",
                 "FSGS or diffuse mesangial sclerosis",
                 "C3 glomerulopathy or MPGN",
                 BIOPSY_TIKD_UI)
  dead_ui <- setdiff(ui_biopsy, names(biopsy_modifiers))
  if (length(dead_ui))
    problems <- c(problems, sprintf(
      "biopsy option(s) the UI can emit but biopsy_modifiers does not key, so they never update the posterior: %s",
      paste(dead_ui, collapse = "; ")))

  orphan_mod <- setdiff(names(biopsy_modifiers), ui_biopsy)
  if (length(orphan_mod))
    problems <- c(problems, sprintf(
      "biopsy_modifiers key(s) no UI option produces: %s",
      paste(orphan_mod, collapse = "; ")))

  fh_needed <- c("None", "Autosomal dominant", "Autosomal recessive", "X-linked", "Unknown")
  missing_fh <- setdiff(fh_needed, names(family_history_modifiers))
  if (length(missing_fh))
    problems <- c(problems, sprintf("family_history_modifiers missing: %s",
                                    paste(missing_fh, collapse = "; ")))

  missing_sex <- setdiff(c("Male", "Female", "Unknown"), names(sex_alport_modifiers))
  if (length(missing_sex))
    problems <- c(problems, sprintf("sex_alport_modifiers missing: %s",
                                    paste(missing_sex, collapse = "; ")))

  if (verbose) {
    if (length(problems) == 0) {
      cat("Fidelity check: OK - harness vocabulary matches model parameter keys.\n")
    } else {
      cat("Fidelity check: ", length(problems), " problem(s) found\n", sep = "")
      for (p in problems) cat("  - ", p, "\n", sep = "")
    }
  }
  invisible(problems)
}
