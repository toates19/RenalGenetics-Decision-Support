# =============================================================================
# data/bayes_params.R
# Bayesian parameters for renal genetic diagnosis probability estimation
#
# Conditions modelled (9 total):
#   ADPKD       — Autosomal dominant PKD (PKD1/PKD2)
#   ARPKD       — Autosomal recessive PKD (PKHD1)
#   Alport      — Alport syndrome / thin BM nephropathy (COL4A3/4/5)
#   FSGS        — Genetic FSGS / SRNS (NPHS1/2, INF2 etc.)
#   Tubulopathy — Inherited tubulopathies (Bartter, Gitelman, RTA etc.)
#   aHUS        — Atypical HUS (complement pathway)
#   TIKD        — Tubulointerstitial kidney disease (UMOD, MUC1, REN etc.)
#   HeredAmyloid— Hereditary systemic amyloidosis (TTR, APOA1 etc.)
#   C3G         — C3 glomerulopathy / MPGN (CFH, C3, CFHR5 etc.)
#
# NOTE: CAKUT (congenital anomalies of kidney & urinary tract) is intentionally
# excluded from the Bayesian model. There is no dedicated NHS GT Directory CAKUT
# panel; CAKUT genes are instead covered by the R257 super-panel (unexplained
# young-onset ESKD). CAKUT-relevant HPO terms (hydronephrosis, renal dysplasia,
# VUR, horseshoe kidney) are therefore mapped to R257 eligibility scoring in
# data/panels.R rather than driving a separate Bayesian condition.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PRIOR PROBABILITIES  (population prevalence estimates)
# -----------------------------------------------------------------------------
condition_priors <- c(
  ADPKD        = 1 / 1000,
  ARPKD        = 1 / 20000,
  Alport       = 1 / 5000,
  FSGS         = 1 / 10000,
  Tubulopathy  = 1 / 50000,
  aHUS         = 1 / 100000,
  TIKD         = 1 / 50000,    # UMOD ~1/1000 of CKD; CKD prevalence ~5%
  HeredAmyloid = 1 / 100000,   # TTR amyloidosis ~1/100,000
  C3G          = 1 / 1000000   # C3 glomerulopathy ~1–3 per million
)

# -----------------------------------------------------------------------------
# 2. LIKELIHOOD RATIOS PER HPO TERM
#    LR+ for each condition when the feature is PRESENT.
#    key = TRUE: absence of this term also updates the posterior (see section 3).
# -----------------------------------------------------------------------------
hpo_lr_positive <- list(

  "HP:0000113" = list(  # Polycystic kidney
    label        = "Polycystic kidney / bilateral renal cysts",
    key          = TRUE,
    ADPKD        = 120,
    ARPKD        = 80,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 3.0,   # DNAJB11 causes ADPKD-like cysts
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0005584" = list(  # Renal cyst (unilateral/unspecified)
    label        = "Renal cyst (unilateral or unspecified)",
    key          = FALSE,
    ADPKD        = 20,
    ARPKD        = 15,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 2.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0000790" = list(  # Haematuria
    label        = "Haematuria (microscopic or macroscopic)",
    key          = TRUE,
    ADPKD        = 8.0,
    ARPKD        = 2.0,
    Alport       = 25.0,
    FSGS         = 4.0,
    Tubulopathy  = 1.0,
    aHUS         = 5.0,
    TIKD         = 2.0,
    HeredAmyloid = 1.0,
    C3G          = 12.0  # synpharyngitic haematuria cardinal in MPGN/C3G
  ),

  "HP:0000407" = list(  # Sensorineural hearing loss
    label        = "Sensorineural hearing loss",
    key          = TRUE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 18.0,
    FSGS         = 1.0,
    Tubulopathy  = 2.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 3.0,  # gelsolin (GSN) amyloidosis causes SNHL
    C3G          = 1.0
  ),

  "HP:0000093" = list(  # Proteinuria (sub-nephrotic)
    label        = "Proteinuria (sub-nephrotic)",
    key          = TRUE,
    ADPKD        = 4.0,
    ARPKD        = 3.0,
    Alport       = 6.0,
    FSGS         = 35.0,
    Tubulopathy  = 3.0,
    aHUS         = 8.0,
    TIKD         = 3.0,
    HeredAmyloid = 8.0,  # amyloid commonly presents with proteinuria
    C3G          = 10.0
  ),

  "HP:0000100" = list(  # Nephrotic syndrome
    label        = "Nephrotic syndrome",
    key          = TRUE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 3.0,
    FSGS         = 40.0,
    Tubulopathy  = 1.0,
    aHUS         = 3.0,
    TIKD         = 1.0,
    HeredAmyloid = 6.0,
    C3G          = 8.0
  ),

  "HP:0001407" = list(  # Hepatic cysts
    label        = "Hepatic cysts",
    key          = FALSE,
    ADPKD        = 15.0,
    ARPKD        = 25.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0001395" = list(  # Hepatic fibrosis
    label        = "Hepatic fibrosis / congenital hepatic fibrosis",
    key          = FALSE,
    ADPKD        = 2.0,
    ARPKD        = 30.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0002616" = list(  # Aortic root aneurysm
    label        = "Aortic root aneurysm / intracranial aneurysm",
    key          = FALSE,
    ADPKD        = 12.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  # HP:0000126 (Hydronephrosis), HP:0000110 (Renal dysplasia),
  # HP:0000085 (Horseshoe kidney), HP:0000076 (VUR) are retained in
  # hpo_lr_positive with neutral LRs for all remaining conditions, so that
  # vignette-extracted structural anomaly terms do not break the model.
  # Their primary role is now to boost R257 eligibility via hpo_relevant
  # matching in data/panels.R.

  "HP:0000126" = list(  # Hydronephrosis
    label        = "Hydronephrosis",
    key          = FALSE,
    ADPKD        = 2.0,
    ARPKD        = 3.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0000110" = list(  # Renal dysplasia
    label        = "Renal dysplasia / hypoplasia",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 2.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0000085" = list(  # Horseshoe kidney
    label        = "Horseshoe kidney",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0000076" = list(  # Vesicoureteral reflux
    label        = "Vesicoureteral reflux",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.5,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0002150" = list(  # Hypercalciuria
    label        = "Hypercalciuria",
    key          = TRUE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 22.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0002900" = list(  # Hypokalaemia
    label        = "Hypokalaemia",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 18.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0002148" = list(  # Hypophosphataemia
    label        = "Hypophosphataemia",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 15.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0000121" = list(  # Nephrocalcinosis
    label        = "Nephrocalcinosis",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 2.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 20.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0000787" = list(  # Nephrolithiasis
    label        = "Nephrolithiasis / renal stones",
    key          = FALSE,
    ADPKD        = 4.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 10.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0001919" = list(  # Acute kidney injury
    label        = "Acute kidney injury",
    key          = FALSE,
    ADPKD        = 2.0,
    ARPKD        = 2.0,
    Alport       = 3.0,
    FSGS         = 3.0,
    Tubulopathy  = 2.0,
    aHUS         = 30.0,
    TIKD         = 2.0,
    HeredAmyloid = 3.0,
    C3G          = 6.0
  ),

  "HP:0001873" = list(  # Thrombocytopenia
    label        = "Thrombocytopenia",
    key          = TRUE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 25.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 2.0
  ),

  "HP:0001903" = list(  # Anaemia
    label        = "Anaemia (haemolytic / microangiopathic)",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.5,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 20.0,
    TIKD         = 3.0,   # anaemia disproportionate to CKD degree (REN mutations)
    HeredAmyloid = 2.0,
    C3G          = 3.0
  ),

  "HP:0005575" = list(  # Haemolytic uraemic syndrome
    label        = "Haemolytic uraemic syndrome",
    key          = TRUE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 80.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 3.0
  ),

  "HP:0000504" = list(  # Ocular abnormality / anterior lenticonus
    label        = "Ocular abnormality (anterior lenticonus, macular flecks)",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 14.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0012622" = list(  # Chronic kidney disease
    label        = "Chronic kidney disease",
    key          = FALSE,
    ADPKD        = 5.0,
    ARPKD        = 4.0,
    Alport       = 8.0,
    FSGS         = 7.0,
    Tubulopathy  = 3.0,
    aHUS         = 5.0,
    TIKD         = 6.0,
    HeredAmyloid = 5.0,
    C3G          = 5.0
  ),

  "HP:0003774" = list(  # End-stage kidney disease
    label        = "End-stage kidney disease",
    key          = FALSE,
    ADPKD        = 6.0,
    ARPKD        = 5.0,
    Alport       = 10.0,
    FSGS         = 8.0,
    Tubulopathy  = 2.0,
    aHUS         = 6.0,
    TIKD         = 5.0,
    HeredAmyloid = 4.0,
    C3G          = 5.0
  ),

  "HP:0000822" = list(  # Hypertension early onset
    label        = "Hypertension (early onset <35 years)",
    key          = FALSE,
    ADPKD        = 6.0,
    ARPKD        = 3.0,
    Alport       = 2.0,
    FSGS         = 2.0,
    Tubulopathy  = 1.5,
    aHUS         = 3.0,
    TIKD         = 3.0,
    HeredAmyloid = 1.0,
    C3G          = 2.0
  ),

  "HP:0000969" = list(  # Oedema
    label        = "Oedema (periorbital or peripheral)",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.5,
    FSGS         = 12.0,
    Tubulopathy  = 1.0,
    aHUS         = 2.0,
    TIKD         = 1.0,
    HeredAmyloid = 3.0,
    C3G          = 5.0
  ),

  "HP:0001942" = list(  # Metabolic alkalosis
    label        = "Metabolic alkalosis",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 14.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  # ── New HPO terms for expanded condition set ──────────────────────────────

  "HP:0001997" = list(  # Gout / hyperuricaemia
    label        = "Gout / hyperuricaemia (disproportionate to renal function)",
    key          = FALSE,
    ADPKD        = 2.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 5.0,
    aHUS         = 1.0,
    TIKD         = 15.0,  # cardinal feature of UMOD/MUC1 mutations
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0001638" = list(  # Cardiomyopathy
    label        = "Cardiomyopathy",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 20.0,  # TTR amyloidosis — cardiomyopathy often dominant
    C3G          = 1.0
  ),

  "HP:0001271" = list(  # Peripheral neuropathy
    label        = "Peripheral neuropathy / polyneuropathy",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 15.0,  # Val30Met TTR — neuropathic phenotype
    C3G          = 1.0
  ),

  "HP:0003159" = list(  # Hyperoxaluria
    label        = "Hyperoxaluria",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 8.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0010934" = list(  # Hyperuricosuria
    label        = "Hyperuricosuria",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 10.0,
    aHUS         = 1.0,
    TIKD         = 5.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  # ── HPO terms generated by structured inputs but previously missing ───────

  "HP:0002153" = list(  # Hyperkalaemia
    label        = "Hyperkalaemia with acidosis (pseudohypoaldosteronism / type 4 RTA)",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 20.0,  # pseudohypoaldosteronism (SCNN1A/B/G, NR3C2), type 4 RTA
    aHUS         = 3.0,   # AKI in TMA can cause hyperkalaemia
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0002917" = list(  # Hypomagnesaemia
    label        = "Hypomagnesaemia",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 25.0,  # cardinal feature of Gitelman (SLC12A3); also CLDN16/19 hypomagnesaemia
    aHUS         = 1.0,
    TIKD         = 2.0,   # some NPHP-related tubulointerstitial disease
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0000863" = list(  # Nephrogenic diabetes insipidus
    label        = "Nephrogenic diabetes insipidus",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 30.0,  # AVPR2 (X-linked NDI), AQP2 (AR NDI) — cardinal
    aHUS         = 1.0,
    TIKD         = 2.0,   # nephronophthisis-related concentrating defect
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),

  "HP:0001878" = list(  # Haemolytic anaemia (microangiopathic)
    label        = "Haemolytic anaemia (microangiopathic / Coombs-negative)",
    key          = FALSE,
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 18.0,  # MAHA is part of the TMA triad in complement-mediated aHUS
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 3.0    # MPGN / C3G with TMA overlap
  )

)

# -----------------------------------------------------------------------------
# 3. NEGATIVE LIKELIHOOD RATIOS for KEY terms (when absent)
# -----------------------------------------------------------------------------
hpo_lr_negative <- list(
  "HP:0000113" = c(ADPKD=0.05, ARPKD=0.08, Alport=1.0,  FSGS=1.0,  Tubulopathy=1.0, aHUS=1.0,  TIKD=0.9,  HeredAmyloid=1.0, C3G=1.0),
  "HP:0000790" = c(ADPKD=0.6,  ARPKD=0.9,  Alport=0.2,  FSGS=0.7,  Tubulopathy=1.0, aHUS=0.7,  TIKD=0.8,  HeredAmyloid=1.0, C3G=0.5),
  "HP:0000407" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=0.4,  FSGS=1.0,  Tubulopathy=0.9, aHUS=1.0,  TIKD=1.0,  HeredAmyloid=0.9, C3G=1.0),
  "HP:0000093" = c(ADPKD=0.7,  ARPKD=0.8,  Alport=0.6,  FSGS=0.3,  Tubulopathy=0.8, aHUS=0.6,  TIKD=0.7,  HeredAmyloid=0.5, C3G=0.4),
  "HP:0000100" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=0.8,  FSGS=0.2,  Tubulopathy=1.0, aHUS=0.8,  TIKD=1.0,  HeredAmyloid=0.7, C3G=0.7),
  "HP:0001873" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=1.0,  FSGS=1.0,  Tubulopathy=1.0, aHUS=0.3,  TIKD=1.0,  HeredAmyloid=1.0, C3G=0.8),
  "HP:0005575" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=1.0,  FSGS=1.0,  Tubulopathy=1.0, aHUS=0.15, TIKD=1.0,  HeredAmyloid=1.0, C3G=0.7),
  "HP:0002150" = c(ADPKD=1.0,  ARPKD=1.0,  Alport=1.0,  FSGS=1.0,  Tubulopathy=0.4, aHUS=1.0,  TIKD=1.0,  HeredAmyloid=1.0, C3G=1.0)
)

# -----------------------------------------------------------------------------
# 4. FAMILY HISTORY MODIFIERS
# -----------------------------------------------------------------------------
family_history_modifiers <- list(
  "Autosomal dominant" = list(
    ADPKD        = 10,
    ARPKD        = 1.0,
    Alport       = 4.0,
    FSGS         = 5.0,
    Tubulopathy  = 3.0,
    aHUS         = 4.0,
    TIKD         = 8.0,   # UMOD, MUC1, REN all AD
    HeredAmyloid = 10.0,  # all hereditary amyloid genes are AD
    C3G          = 4.0
  ),
  "Autosomal recessive" = list(
    ADPKD        = 1.0,
    ARPKD        = 8.0,
    Alport       = 3.0,
    FSGS         = 6.0,
    Tubulopathy  = 5.0,
    aHUS         = 4.0,
    TIKD         = 2.0,   # nephronophthisis (NPHP genes) is AR
    HeredAmyloid = 1.0,
    C3G          = 5.0
  ),
  "X-linked" = list(
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 10.0,
    FSGS         = 2.0,
    Tubulopathy  = 2.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  ),
  "Unknown" = list(
    ADPKD        = 2.0,
    ARPKD        = 1.5,
    Alport       = 2.0,
    FSGS         = 2.0,
    Tubulopathy  = 1.5,
    aHUS         = 1.5,
    TIKD         = 2.0,
    HeredAmyloid = 2.0,
    C3G          = 2.0
  ),
  "None" = list(
    ADPKD        = 1.0,
    ARPKD        = 1.0,
    Alport       = 1.0,
    FSGS         = 1.0,
    Tubulopathy  = 1.0,
    aHUS         = 1.0,
    TIKD         = 1.0,
    HeredAmyloid = 1.0,
    C3G          = 1.0
  )
)

# -----------------------------------------------------------------------------
# 5. CONSANGUINITY MODIFIER
# -----------------------------------------------------------------------------
consanguinity_modifiers <- list(
  "Yes" = list(
    ADPKD        = 1.0,
    ARPKD        = 6.0,
    Alport       = 4.0,
    FSGS         = 5.0,
    Tubulopathy  = 5.0,
    aHUS         = 3.0,
    TIKD         = 2.0,   # NPHP genes are AR
    HeredAmyloid = 1.0,
    C3G          = 4.0
  ),
  "No"      = lapply(condition_priors, function(x) 1.0),
  "Unknown" = lapply(condition_priors, function(x) 1.0)
)
names(consanguinity_modifiers$No)      <- names(condition_priors)
names(consanguinity_modifiers$Unknown) <- names(condition_priors)

# -----------------------------------------------------------------------------
# 6. AGE MODIFIERS
# -----------------------------------------------------------------------------
age_modifier <- function(age_years) {
  mods <- c(ADPKD=1.0, ARPKD=1.0, Alport=1.0, FSGS=1.0,
            Tubulopathy=1.0, aHUS=1.0, TIKD=1.0, HeredAmyloid=1.0, C3G=1.0)
  if (is.na(age_years) || is.null(age_years)) return(mods)

  if (age_years < 1) {
    mods["ARPKD"]  <- 15.0
    mods["FSGS"]   <- 3.0
    mods["C3G"]    <- 2.0
  } else if (age_years < 18) {
    mods["ARPKD"]        <- 8.0
    mods["Alport"]       <- 2.0
    mods["FSGS"]         <- 3.0
    mods["Tubulopathy"]  <- 2.0
    mods["C3G"]          <- 3.0   # MPGN/C3G often presents in childhood
    mods["HeredAmyloid"] <- 0.3   # very rare before 18
  } else if (age_years < 30) {
    mods["Alport"]       <- 2.0
    mods["FSGS"]         <- 3.0
    mods["Tubulopathy"]  <- 1.5
    mods["C3G"]          <- 2.0
    mods["HeredAmyloid"] <- 0.5
  } else if (age_years < 50) {
    mods["ADPKD"]        <- 2.0
    mods["Alport"]       <- 1.5
    mods["TIKD"]         <- 2.0   # UMOD/MUC1 typically presents 30–50
  } else {
    mods["ADPKD"]        <- 4.0
    mods["TIKD"]         <- 3.0
    mods["HeredAmyloid"] <- 4.0   # TTR amyloidosis typically presents >50
  }
  return(mods)
}

# -----------------------------------------------------------------------------
# 7. PANEL–CONDITION MAPPING
# -----------------------------------------------------------------------------
panel_condition_map <- list(
  R193 = c("ADPKD", "ARPKD"),
  R194 = "Alport",
  R195 = "FSGS",
  R196 = "C3G",
  R197 = "C3G",
  R198 = "Tubulopathy",
  R201 = "aHUS",
  R202 = "TIKD",
  R204 = "HeredAmyloid",
  R256 = "Tubulopathy",
  R257 = c("Alport", "ADPKD", "FSGS"),  # super-panel — show top contributor
  R446 = "FSGS"
)

# -----------------------------------------------------------------------------
# 8. DISPLAY LABELS AND COLOUR PALETTE
# -----------------------------------------------------------------------------
condition_labels <- c(
  ADPKD        = "ADPKD (PKD1/PKD2)",
  ARPKD        = "ARPKD (PKHD1)",
  Alport       = "Alport Syndrome (COL4A3/4/5)",
  FSGS         = "Genetic FSGS / SRNS",
  Tubulopathy  = "Inherited Tubulopathy",
  aHUS         = "Atypical HUS (complement)",
  TIKD         = "Tubulointerstitial Kidney Disease",
  HeredAmyloid = "Hereditary Systemic Amyloidosis",
  C3G          = "C3 Glomerulopathy / MPGN"
)

condition_colours <- c(
  ADPKD        = "#2E86AB",
  ARPKD        = "#A23B72",
  Alport       = "#F18F01",
  FSGS         = "#C73E1D",
  Tubulopathy  = "#44BBA4",
  aHUS         = "#7B2D8B",
  TIKD         = "#1D7A4E",
  HeredAmyloid = "#E07B39",
  C3G          = "#5C6BC0"
)

# -----------------------------------------------------------------------------
# 9. LITERATURE SOURCES
# -----------------------------------------------------------------------------
lr_sources <- list(
  primary = c(
    "Groopman EE et al. Diagnostic Utility of Exome Sequencing for Kidney Disease. NEJM 2019;380:142-151",
    "Connaughton DM et al. Monogenic causes of CKD. JASN 2019;30:2088-2107",
    "Savige J et al. Alport syndrome. KI 2022;101:717-729",
    "Vivante A, Hildebrandt F. Exploring the genetic basis of CKD. Nat Rev Nephrol 2016;12:133-146",
    "Noris M, Remuzzi G. Atypical HUS. NEJM 2009;361:1676-1687",
    "Cornec-Le Gall E et al. ADPKD. Lancet 2019;393:919-935",
    "Eckardt KU et al. Autosomal dominant tubulointerstitial kidney disease. Nat Rev Nephrol 2015;11:617-625",
    "Wechalekar AD et al. Systemic amyloidosis. Lancet 2016;387:2641-2654",
    "Nester CM et al. C3 glomerulopathy. Nephrol Dial Transplant 2018;33:i1-i7"
  ),
  caveat = "Likelihood ratios are expert approximations informed by published literature. They have not been formally validated in a prospective clinical cohort. Posterior probabilities should be interpreted as decision-support estimates only."
)
