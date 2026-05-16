# =============================================================================
# data/bayes_params.R
# Bayesian parameters for renal genetic diagnosis probability estimation
#
# IMPORTANT CLINICAL CAVEAT:
# Likelihood ratios are approximations derived from published literature
# and expert consensus. They are NOT formally validated diagnostic parameters.
# Sources include: Groopman et al. NEJM 2019, Connaughton et al. JASN 2019,
# Savige et al. KI 2022, Vivante & Hildebrandt NRN 2016.
# This tool is for decision support only.
#
# Conditions modelled:
#   ADPKD     — Autosomal dominant polycystic kidney disease (PKD1/PKD2)
#   ARPKD     — Autosomal recessive PKD (PKHD1)
#   Alport    — Alport syndrome / thin basement membrane (COL4A3/4/5)
#   FSGS      — Genetic focal segmental glomerulosclerosis (NPHS1/2, INF2 etc.)
#   CAKUT     — Congenital anomalies of kidney & urinary tract
#   Tubulopathy — Inherited tubulopathies (Bartter, Gitelman, RTA etc.)
#   aHUS      — Atypical haemolytic uraemic syndrome (complement pathway)
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PRIOR PROBABILITIES
#    Based on population prevalence estimates
#    References:
#      ADPKD:      Cornec-Le Gall et al. Lancet 2019 (~1/1000)
#      ARPKD:      Bergmann et al. NRN 2018 (~1/20,000)
#      Alport:     Savige et al. KI 2022 (~1/5,000)
#      FSGS:       Ijpelaar et al. CJASN 2022 (~1/10,000 genetic)
#      CAKUT:      Vivante & Hildebrandt NRN 2016 (~1/500)
#      Tubulopathy: Kleta & Bockenhauer JASN 2006 (~1/50,000 combined)
#      aHUS:       Noris & Remuzzi NEJM 2009 (~1/500,000 per year; stock ~1/100,000)
# -----------------------------------------------------------------------------
condition_priors <- c(
  ADPKD       = 1 / 1000,
  ARPKD       = 1 / 20000,
  Alport      = 1 / 5000,
  FSGS        = 1 / 10000,
  CAKUT       = 1 / 500,
  Tubulopathy = 1 / 50000,
  aHUS        = 1 / 100000
)

# -----------------------------------------------------------------------------
# 2. LIKELIHOOD RATIOS PER HPO TERM
#
#    Each HPO term has a named numeric vector of positive LRs (LR+) per condition.
#    LR+ = sensitivity / (1 - specificity) for that feature given that condition.
#
#    Interpretation:
#      LR  1   = feature uninformative
#      LR  2-5 = weak evidence
#      LR  5-10 = moderate evidence
#      LR >10  = strong evidence
#
#    For HPO terms marked as KEY (*), if the term is ABSENT, apply negative LR:
#      LR- = (1 - sensitivity) / specificity
#    Use lr_negative list below for absent key terms.
#
#    Conditions not meaningfully associated with a term receive LR = 1.0 (neutral).
# -----------------------------------------------------------------------------
hpo_lr_positive <- list(

  "HP:0000113" = list(  # Polycystic kidney (bilateral cysts)
    label       = "Polycystic kidney / bilateral renal cysts",
    key         = TRUE,
    ADPKD       = 120,
    ARPKD       = 80,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 3.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0005584" = list(  # Renal cyst (unilateral or unspecified)
    label       = "Renal cyst (unilateral or unspecified)",
    key         = FALSE,
    ADPKD       = 20,
    ARPKD       = 15,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 4.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0000790" = list(  # Haematuria
    label       = "Haematuria (microscopic or macroscopic)",
    key         = TRUE,
    ADPKD       = 8.0,
    ARPKD       = 2.0,
    Alport      = 25.0,
    FSGS        = 4.0,
    CAKUT       = 2.0,
    Tubulopathy = 1.0,
    aHUS        = 5.0
  ),

  "HP:0000407" = list(  # Sensorineural hearing loss
    label       = "Sensorineural hearing loss",
    key         = TRUE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 18.0,
    FSGS        = 1.0,
    CAKUT       = 1.5,
    Tubulopathy = 2.0,
    aHUS        = 1.0
  ),

  "HP:0000093" = list(  # Proteinuria
    label       = "Proteinuria (sub-nephrotic)",
    key         = TRUE,
    ADPKD       = 4.0,
    ARPKD       = 3.0,
    Alport      = 6.0,
    FSGS        = 35.0,
    CAKUT       = 2.0,
    Tubulopathy = 3.0,
    aHUS        = 8.0
  ),

  "HP:0000100" = list(  # Nephrotic syndrome
    label       = "Nephrotic syndrome",
    key         = TRUE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 3.0,
    FSGS        = 40.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 3.0
  ),

  "HP:0001407" = list(  # Hepatic cysts
    label       = "Hepatic cysts",
    key         = FALSE,
    ADPKD       = 15.0,
    ARPKD       = 25.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0001395" = list(  # Hepatic fibrosis
    label       = "Hepatic fibrosis / congenital hepatic fibrosis",
    key         = FALSE,
    ADPKD       = 2.0,
    ARPKD       = 30.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0002616" = list(  # Aortic root aneurysm
    label       = "Aortic root aneurysm / intracranial aneurysm",
    key         = FALSE,
    ADPKD       = 12.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0000126" = list(  # Hydronephrosis
    label       = "Hydronephrosis",
    key         = FALSE,
    ADPKD       = 2.0,
    ARPKD       = 3.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 18.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0000110" = list(  # Renal dysplasia
    label       = "Renal dysplasia / hypoplasia",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 2.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 22.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0000085" = list(  # Horseshoe kidney
    label       = "Horseshoe kidney",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 30.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0000076" = list(  # Vesicoureteral reflux
    label       = "Vesicoureteral reflux",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.5,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 20.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0002150" = list(  # Hypercalciuria
    label       = "Hypercalciuria",
    key         = TRUE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 22.0,
    aHUS        = 1.0
  ),

  "HP:0002900" = list(  # Hypokalaemia
    label       = "Hypokalaemia",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 18.0,
    aHUS        = 1.0
  ),

  "HP:0002148" = list(  # Hypophosphataemia
    label       = "Hypophosphataemia",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 15.0,
    aHUS        = 1.0
  ),

  "HP:0000121" = list(  # Nephrocalcinosis
    label       = "Nephrocalcinosis",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 2.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.5,
    Tubulopathy = 20.0,
    aHUS        = 1.0
  ),

  "HP:0000787" = list(  # Nephrolithiasis
    label       = "Nephrolithiasis / renal stones",
    key         = FALSE,
    ADPKD       = 4.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 2.0,
    Tubulopathy = 10.0,
    aHUS        = 1.0
  ),

  "HP:0001919" = list(  # Acute kidney injury
    label       = "Acute kidney injury",
    key         = FALSE,
    ADPKD       = 2.0,
    ARPKD       = 2.0,
    Alport      = 3.0,
    FSGS        = 3.0,
    CAKUT       = 2.0,
    Tubulopathy = 2.0,
    aHUS        = 30.0
  ),

  "HP:0001873" = list(  # Thrombocytopenia
    label       = "Thrombocytopenia",
    key         = TRUE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 25.0
  ),

  "HP:0001903" = list(  # Anaemia
    label       = "Anaemia (haemolytic / microangiopathic)",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.5,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 20.0
  ),

  "HP:0005575" = list(  # Haemolytic uraemic syndrome
    label       = "Haemolytic uraemic syndrome",
    key         = TRUE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 80.0
  ),

  "HP:0000504" = list(  # Abnormality of vision / anterior lenticonus
    label       = "Ocular abnormality (anterior lenticonus, macular flecks)",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 14.0,
    FSGS        = 1.0,
    CAKUT       = 2.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  ),

  "HP:0012622" = list(  # Chronic kidney disease
    label       = "Chronic kidney disease",
    key         = FALSE,
    ADPKD       = 5.0,
    ARPKD       = 4.0,
    Alport      = 8.0,
    FSGS        = 7.0,
    CAKUT       = 4.0,
    Tubulopathy = 3.0,
    aHUS        = 5.0
  ),

  "HP:0003774" = list(  # End-stage kidney disease
    label       = "End-stage kidney disease",
    key         = FALSE,
    ADPKD       = 6.0,
    ARPKD       = 5.0,
    Alport      = 10.0,
    FSGS        = 8.0,
    CAKUT       = 4.0,
    Tubulopathy = 2.0,
    aHUS        = 6.0
  ),

  "HP:0000822" = list(  # Hypertension
    label       = "Hypertension (early onset <35 years)",
    key         = FALSE,
    ADPKD       = 6.0,
    ARPKD       = 3.0,
    Alport      = 2.0,
    FSGS        = 2.0,
    CAKUT       = 2.0,
    Tubulopathy = 1.5,
    aHUS        = 3.0
  ),

  "HP:0000969" = list(  # Oedema
    label       = "Oedema (periorbital or peripheral)",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.5,
    FSGS        = 12.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 2.0
  ),

  "HP:0001942" = list(  # Metabolic alkalosis
    label       = "Metabolic alkalosis",
    key         = FALSE,
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 14.0,
    aHUS        = 1.0
  )

)

# -----------------------------------------------------------------------------
# 3. NEGATIVE LIKELIHOOD RATIOS for KEY terms (when absent)
#    Applied when a key HPO term is explicitly absent from confirmed list
#    LR- = (1 - sensitivity) / specificity (approximated)
# -----------------------------------------------------------------------------
hpo_lr_negative <- list(
  "HP:0000113" = c(ADPKD=0.05, ARPKD=0.08, Alport=1.0, FSGS=1.0, CAKUT=0.7, Tubulopathy=1.0, aHUS=1.0),
  "HP:0000790" = c(ADPKD=0.6,  ARPKD=0.9,  Alport=0.2, FSGS=0.7, CAKUT=0.8, Tubulopathy=1.0, aHUS=0.7),
  "HP:0000407" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=0.4, FSGS=1.0, CAKUT=1.0, Tubulopathy=0.9, aHUS=1.0),
  "HP:0000093" = c(ADPKD=0.7,  ARPKD=0.8,  Alport=0.6, FSGS=0.3, CAKUT=0.8, Tubulopathy=0.8, aHUS=0.6),
  "HP:0000100" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=0.8, FSGS=0.2, CAKUT=1.0, Tubulopathy=1.0, aHUS=0.8),
  "HP:0001873" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=1.0, FSGS=1.0, CAKUT=1.0, Tubulopathy=1.0, aHUS=0.3),
  "HP:0005575" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=1.0, FSGS=1.0, CAKUT=1.0, Tubulopathy=1.0, aHUS=0.15),
  "HP:0002150" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=1.0, FSGS=1.0, CAKUT=1.0, Tubulopathy=0.4, aHUS=1.0)
)

# -----------------------------------------------------------------------------
# 4. FAMILY HISTORY MODIFIERS
#    Multiply prior by these factors before applying HPO LRs
# -----------------------------------------------------------------------------
family_history_modifiers <- list(
  "Autosomal dominant" = list(
    ADPKD       = 10,
    ARPKD       = 1.0,
    Alport      = 4.0,
    FSGS        = 5.0,
    CAKUT       = 6.0,
    Tubulopathy = 3.0,
    aHUS        = 4.0
  ),
  "Autosomal recessive" = list(
    ADPKD       = 1.0,
    ARPKD       = 8.0,
    Alport      = 3.0,
    FSGS        = 6.0,
    CAKUT       = 4.0,
    Tubulopathy = 5.0,
    aHUS        = 4.0
  ),
  "X-linked" = list(
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 10.0,
    FSGS        = 2.0,
    CAKUT       = 2.0,
    Tubulopathy = 2.0,
    aHUS        = 1.0
  ),
  "Unknown" = list(
    ADPKD       = 2.0,
    ARPKD       = 1.5,
    Alport      = 2.0,
    FSGS        = 2.0,
    CAKUT       = 2.0,
    Tubulopathy = 1.5,
    aHUS        = 1.5
  ),
  "None" = list(
    ADPKD       = 1.0,
    ARPKD       = 1.0,
    Alport      = 1.0,
    FSGS        = 1.0,
    CAKUT       = 1.0,
    Tubulopathy = 1.0,
    aHUS        = 1.0
  )
)

# -----------------------------------------------------------------------------
# 5. CONSANGUINITY MODIFIER
#    Applied multiplicatively to AR conditions when consanguinity confirmed
# -----------------------------------------------------------------------------
consanguinity_modifiers <- list(
  "Yes" = list(
    ADPKD       = 1.0,
    ARPKD       = 6.0,
    Alport      = 4.0,
    FSGS        = 5.0,
    CAKUT       = 2.0,
    Tubulopathy = 5.0,
    aHUS        = 3.0
  ),
  "No"      = lapply(condition_priors, function(x) 1.0),
  "Unknown" = lapply(condition_priors, function(x) 1.0)
)
# Fix names for No/Unknown
names(consanguinity_modifiers$No)      <- names(condition_priors)
names(consanguinity_modifiers$Unknown) <- names(condition_priors)

# -----------------------------------------------------------------------------
# 6. AGE MODIFIERS
#    Applied multiplicatively based on age at presentation
# -----------------------------------------------------------------------------
age_modifier <- function(age_years) {
  # Returns named numeric vector of multipliers per condition
  mods <- c(ADPKD=1.0, ARPKD=1.0, Alport=1.0, FSGS=1.0, CAKUT=1.0, Tubulopathy=1.0, aHUS=1.0)
  if (is.na(age_years) || is.null(age_years)) return(mods)

  if (age_years < 1) {
    mods["ARPKD"]  <- 15.0
    mods["CAKUT"]  <- 8.0
    mods["FSGS"]   <- 3.0   # congenital nephrotic syndrome
  } else if (age_years < 18) {
    mods["ARPKD"]  <- 8.0
    mods["CAKUT"]  <- 5.0
    mods["Alport"] <- 2.0
    mods["FSGS"]   <- 3.0
    mods["Tubulopathy"] <- 2.0
  } else if (age_years < 30) {
    mods["Alport"] <- 2.0
    mods["FSGS"]   <- 3.0
    mods["CAKUT"]  <- 2.0
    mods["Tubulopathy"] <- 1.5
  } else if (age_years < 50) {
    mods["ADPKD"]  <- 2.0
    mods["Alport"] <- 1.5
  } else {
    mods["ADPKD"]  <- 4.0
  }
  return(mods)
}

# -----------------------------------------------------------------------------
# 7. PANEL–CONDITION MAPPING
#    Links GT Directory panels to the conditions modelled in the Bayesian layer
# -----------------------------------------------------------------------------
panel_condition_map <- list(
  R187 = "CAKUT",
  R188 = "FSGS",
  R189 = "Tubulopathy",
  R190 = "Alport",
  R191 = c("ADPKD", "ARPKD"),
  R192 = "aHUS",
  R370 = c("Alport", "CAKUT", "ADPKD")  # catch-all — show top contributor
)

# -----------------------------------------------------------------------------
# 8. DISPLAY LABELS AND COLOUR PALETTE
# -----------------------------------------------------------------------------
condition_labels <- c(
  ADPKD       = "ADPKD (PKD1/PKD2)",
  ARPKD       = "ARPKD (PKHD1)",
  Alport      = "Alport Syndrome (COL4A3/4/5)",
  FSGS        = "Genetic FSGS / SRNS",
  CAKUT       = "CAKUT",
  Tubulopathy = "Inherited Tubulopathy",
  aHUS        = "Atypical HUS (complement)"
)

condition_colours <- c(
  ADPKD       = "#2E86AB",
  ARPKD       = "#A23B72",
  Alport      = "#F18F01",
  FSGS        = "#C73E1D",
  CAKUT       = "#3B1F2B",
    Tubulopathy = "#44BBA4",
  aHUS        = "#7B2D8B"
)

# -----------------------------------------------------------------------------
# 9. LITERATURE SOURCES (for display in app)
# -----------------------------------------------------------------------------
lr_sources <- list(
  primary = c(
    "Groopman EE et al. Diagnostic Utility of Exome Sequencing for Kidney Disease. NEJM 2019;380:142-151",
    "Connaughton DM et al. Monogenic causes of CKD. JASN 2019;30:2088-2107",
    "Savige J et al. Alport syndrome. KI 2022;101:717-729",
    "Vivante A, Hildebrandt F. Exploring the genetic basis of CKD. Nat Rev Nephrol 2016;12:133-146",
    "Noris M, Remuzzi G. Atypical HUS. NEJM 2009;361:1676-1687",
    "Cornec-Le Gall E et al. Autosomal dominant polycystic kidney disease. Lancet 2019;393:919-935"
  ),
  caveat = "Likelihood ratios are expert approximations informed by published literature. They have not been formally validated in a prospective clinical cohort. Posterior probabilities should be interpreted as decision-support estimates only."
)
