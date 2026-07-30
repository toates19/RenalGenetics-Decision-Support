# =============================================================================
# data/bayes_params.R
# Bayesian parameters for renal genetic diagnosis probability estimation
#
# Conditions modelled (24 total):
#   PKD1          — ADPKD due to PKD1
#   PKD2          — ADPKD due to PKD2
#   ARPKD         — Autosomal recessive PKD (PKHD1)
#   Alport_XL     — X-linked Alport syndrome (COL4A5)
#   Alport_AR     — AR/AD Alport syndrome (COL4A3/COL4A4) biallelic
#   COL4_het      — COL4 heterozygote (heterozygous COL4A3/COL4A4)
#   NPHS1         — FSGS/SRNS due to NPHS1 (nephrin) — congenital nephrotic
#   NPHS2         — FSGS/SRNS due to NPHS2 (podocin) — childhood SRNS
#   INF2          — FSGS/SRNS due to INF2 — AD, often with CMT
#   Gitelman      — Gitelman syndrome (SLC12A3)
#   Bartter       — Bartter syndrome (SLC12A1/KCNJ1/CLCNKB) incl. pseudohypoaldosteronism
#   Distal_RTA    — Distal (type 1) RTA (ATP6V1B1/ATP6V0A4/SLC4A1)
#   PrimaryHyperoxaluria — Primary hyperoxaluria (AGXT/GRHPR/HOGA1)
#   NephrogenicDI — Congenital nephrogenic DI (AVPR2/AQP2)
#   CFH_aHUS      — aHUS due to CFH (complement factor H)
#   CD46_MCP      — aHUS due to CD46/MCP (membrane cofactor protein)
#   CFI_aHUS      — aHUS due to CFI (complement factor I)
#   C3_CFB        — aHUS due to C3 or CFB
#   TIKD          — Tubulointerstitial kidney disease (UMOD, MUC1, REN etc.)
#   TTR_Amyloid   — Hereditary TTR amyloidosis
#   APOA1_Amyloid — Hereditary APOA1 amyloidosis
#   GSN_Amyloid   — Hereditary gelsolin (GSN) amyloidosis
#   C3G           — C3 glomerulopathy / MPGN
#   NoGenetic     — No monogenic diagnosis from modelled conditions
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PRIOR PROBABILITIES  (population prevalence estimates)
# -----------------------------------------------------------------------------
condition_priors <- c(
  PKD1          = 1 / 1300,     # ~78% of ADPKD cases
  PKD2          = 1 / 5500,     # ~18% of ADPKD cases; later / milder
  ARPKD         = 1 / 20000,
  Alport_XL     = 1 / 6000,     # ~85% of Alport are X-linked (COL4A5)
  Alport_AR     = 1 / 33000,    # biallelic COL4A3/COL4A4 (severe AR/digenic)
  # COL4_het: population carrier frequency of a P/LP-classified heterozygous
  # COL4A3/COL4A4 variant is 1/106 (Gibson et al. JASN 2021) — but that is
  # carriage, not clinically apparent disease, and most carriers never reach
  # a nephrology genetic differential. Recalibrated here as carrier frequency
  # x penetrance, using the population-based (non-hospital-biased) estimate
  # that <3% of carriers reach ESKF by age 60 (Savige et al. KIR 2022,
  # PMID 36090501) as the penetrance proxy for "clinically significant
  # disease", since hospital-ascertained cohorts (14-30% ESKF) overestimate
  # penetrance by selecting for already-symptomatic patients. This is a
  # simplifying assumption (ESKF-by-60 is a stricter endpoint than "any
  # clinical phenotype") — flagged in variant_interp_uncertainties for
  # review; see also the analogous open item for data/variant_interp.R.
  COL4_het      = (1 / 106) * 0.03,   # = 1/3533; was 1/106 (uncorrected carrier freq)
  NPHS1         = 1 / 200000,   # congenital nephrotic syndrome; rare in general nephrology
  NPHS2         = 1 / 25000,    # most common monogenic childhood FSGS/SRNS
  INF2          = 1 / 67000,    # AD FSGS; often with Charcot-Marie-Tooth
  Gitelman          = 1 / 40000,    # most common hereditary tubulopathy (Knoers & Levtchenko 2008)
  Bartter           = 1 / 1000000,  # rarer; incl. pseudohypoaldosteronism (bundled)
  Distal_RTA        = 1 / 200000,
  PrimaryHyperoxaluria = 1 / 300000,  # primary hyperoxaluria types 1–3
  NephrogenicDI     = 1 / 300000,
  CFH_aHUS      = 1 / 350000,   # ~30% of genetic aHUS; most common complement gene
  CD46_MCP      = 1 / 650000,   # ~15% of genetic aHUS; predominantly paediatric
  CFI_aHUS      = 1 / 1250000,  # ~8% of genetic aHUS
  C3_CFB        = 1 / 1000000,  # ~10% of genetic aHUS (C3 + CFB combined)
  TIKD          = 1 / 50000,
  TTR_Amyloid   = 1 / 110000,   # ~90% of hereditary systemic amyloidosis
  APOA1_Amyloid = 1 / 2000000,  # ~5% of hereditary systemic amyloidosis
  GSN_Amyloid   = 1 / 5000000,  # ~2% of hereditary systemic amyloidosis
  C3G           = 1 / 1000000,
  NoGenetic     = 0.85           # ~85% prior at baseline; calibrated to nephrology referral
                                 # population considering genetic testing (Groopman NEJM 2019)
)

# -----------------------------------------------------------------------------
# 2. LIKELIHOOD RATIOS PER HPO TERM
#    LR+ for each condition when the feature is PRESENT.
#    key = TRUE: absence of this term also updates the posterior (see section 3).
# -----------------------------------------------------------------------------
hpo_lr_positive <- list(

  "HP:0000113" = list(  # Polycystic kidney
    label         = "Polycystic kidney / bilateral renal cysts",
    key           = TRUE,
    PKD1          = 120,
    PKD2          = 120,
    ARPKD         = 80,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 3.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.05   # bilateral cysts in nephrology → almost always genetic
  ),

  "HP:0005584" = list(  # Renal cyst (unilateral/unspecified)
    label         = "Renal cyst (unilateral or unspecified)",
    key           = FALSE,
    PKD1          = 20,
    PKD2          = 20,
    ARPKD         = 15,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 2.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.3    # unilateral/unspecified cysts less specific
  ),

  "HP:0000790" = list(  # Haematuria
    label         = "Haematuria (microscopic or macroscopic)",
    key           = TRUE,
    PKD1          = 3.5,   # haematuria in PKD is secondary to cysts; without cysts it is non-informative
    PKD2          = 2.5,   # PKD2 even milder
    ARPKD         = 2.0,
    Alport_XL     = 25.0,
    Alport_AR     = 20.0,
    COL4_het      = 20.0,  # cardinal feature; most COL4 het carriers presenting to nephrology have haematuria
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 5.0,
    CD46_MCP      = 5.0,
    CFI_aHUS      = 5.0,
    C3_CFB        = 5.0,
    TIKD          = 2.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.5,
    GSN_Amyloid   = 1.0,
    C3G           = 12.0,
    NoGenetic     = 0.65   # haematuria has many non-genetic causes
  ),

  "HP:0000407" = list(  # Sensorineural hearing loss
    label         = "Sensorineural hearing loss",
    key           = TRUE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 20.0,
    Alport_AR     = 15.0,
    COL4_het      = 0.4,   # occurs uncommonly if at all in COL4 hets (Savige 2022)
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 2.0,
    Distal_RTA        = 8.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 3.0,   # cranial nerve (CN VIII) involvement in gelsolin amyloidosis
    C3G           = 1.0,
    NoGenetic     = 0.12   # hearing loss in nephrology → almost always Alport
  ),

  "HP:0000093" = list(  # Proteinuria (sub-nephrotic)
    label         = "Proteinuria (sub-nephrotic)",
    key           = TRUE,
    PKD1          = 4.0,
    PKD2          = 3.0,
    ARPKD         = 3.0,
    Alport_XL     = 6.0,
    Alport_AR     = 6.0,
    COL4_het      = 3.0,   # minority of carriers develop proteinuria as disease progresses
    NPHS1         = 40.0,  # always massive proteinuria (congenital nephrotic)
    NPHS2         = 35.0,
    INF2          = 25.0,
    Gitelman          = 2.0,
    Bartter           = 3.0,
    Distal_RTA        = 5.0,
    PrimaryHyperoxaluria = 5.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 8.0,
    CD46_MCP      = 8.0,
    CFI_aHUS      = 8.0,
    C3_CFB        = 8.0,
    TIKD          = 3.0,
    TTR_Amyloid   = 8.0,
    APOA1_Amyloid = 12.0,
    GSN_Amyloid   = 5.0,
    C3G           = 10.0,
    NoGenetic     = 0.85   # sub-nephrotic proteinuria very non-specific
  ),

  "HP:0000100" = list(  # Nephrotic syndrome
    label         = "Nephrotic syndrome",
    key           = TRUE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 3.0,
    Alport_AR     = 3.0,
    COL4_het      = 1.0,
    NPHS1         = 60.0,  # defining feature of congenital nephrotic syndrome
    NPHS2         = 40.0,
    INF2          = 25.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 3.0,
    CD46_MCP      = 3.0,
    CFI_aHUS      = 3.0,
    C3_CFB        = 3.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 6.0,
    APOA1_Amyloid = 10.0,
    GSN_Amyloid   = 4.0,
    C3G           = 8.0,
    NoGenetic     = 0.55   # nephrotic syndrome: MCD/membranous are common non-genetic causes
  ),

  "HP:0001407" = list(  # Hepatic cysts
    label         = "Hepatic cysts",
    key           = FALSE,
    PKD1          = 15.0,
    PKD2          = 15.0,
    ARPKD         = 25.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.08   # hepatic + renal cysts → PKD virtually certain
  ),

  "HP:0001395" = list(  # Hepatic fibrosis
    label         = "Hepatic fibrosis / congenital hepatic fibrosis",
    key           = FALSE,
    PKD1          = 2.0,
    PKD2          = 2.0,
    ARPKD         = 30.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.05   # congenital hepatic fibrosis almost pathognomonic for ARPKD
  ),

  "HP:0002616" = list(  # Aortic root / intracranial aneurysm
    label         = "Aortic root aneurysm / intracranial aneurysm",
    key           = FALSE,
    PKD1          = 15.0,  # intracranial aneurysms ~8% PKD1 vs ~3% PKD2
    PKD2          = 6.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.3    # intracranial aneurysm much more common in PKD1
  ),

  "HP:0000126" = list(  # Hydronephrosis
    label         = "Hydronephrosis",
    key           = FALSE,
    PKD1          = 2.0,
    PKD2          = 2.0,
    ARPKD         = 3.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 2.0,
    NephrogenicDI     = 2.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.7    # hydronephrosis often obstructive/non-genetic
  ),

  "HP:0000110" = list(  # Renal dysplasia
    label         = "Renal dysplasia / hypoplasia",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 2.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.55   # renal dysplasia often genetic but not always modelled conditions
  ),

  "HP:0000085" = list(  # Horseshoe kidney
    label         = "Horseshoe kidney",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.85   # horseshoe kidney rarely attributable to modelled conditions
  ),

  "HP:0000076" = list(  # Vesicoureteral reflux
    label         = "Vesicoureteral reflux",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.5,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.9    # VUR very non-specific for modelled conditions
  ),

  "HP:0002150" = list(  # Hypercalciuria
    label         = "Hypercalciuria",
    key           = TRUE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 0.1,
    Bartter           = 30.0,
    Distal_RTA        = 20.0,
    PrimaryHyperoxaluria = 8.0,
    NephrogenicDI     = 5.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.45   # idiopathic hypercalciuria common but tubulopathy specific in context
  ),

  "HP:0002900" = list(  # Hypokalaemia
    label         = "Hypokalaemia",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 25.0,
    Bartter           = 25.0,
    Distal_RTA        = 15.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.55   # hypokalaemia: many non-genetic causes but informative in clinic
  ),

  "HP:0002148" = list(  # Hypophosphataemia
    label         = "Hypophosphataemia",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 5.0,
    Bartter           = 5.0,
    Distal_RTA        = 20.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.45   # hypophosphataemia → proximal RTA / Fanconi fairly specific
  ),

  "HP:0000121" = list(  # Nephrocalcinosis
    label         = "Nephrocalcinosis",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 2.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 0.5,
    Bartter           = 15.0,
    Distal_RTA        = 30.0,
    PrimaryHyperoxaluria = 25.0,
    NephrogenicDI     = 5.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.3    # nephrocalcinosis → metabolic tubulopathy likely in nephrology
  ),

  "HP:0000787" = list(  # Nephrolithiasis
    label         = "Nephrolithiasis / renal stones",
    key           = FALSE,
    PKD1          = 4.0,
    PKD2          = 4.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 3.0,
    Bartter           = 8.0,
    Distal_RTA        = 15.0,
    PrimaryHyperoxaluria = 30.0,
    NephrogenicDI     = 5.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.85   # calcium oxalate stones mostly non-genetic
  ),

  "HP:0001919" = list(  # Acute kidney injury
    label         = "Acute kidney injury",
    key           = FALSE,
    PKD1          = 2.0,
    PKD2          = 2.0,
    ARPKD         = 2.0,
    Alport_XL     = 3.0,
    Alport_AR     = 3.0,
    COL4_het      = 1.5,
    NPHS1         = 3.0,
    NPHS2         = 3.0,
    INF2          = 3.0,
    Gitelman          = 2.0,
    Bartter           = 2.0,
    Distal_RTA        = 3.0,
    PrimaryHyperoxaluria = 15.0,
    NephrogenicDI     = 5.0,
    CFH_aHUS      = 30.0,
    CD46_MCP      = 30.0,
    CFI_aHUS      = 30.0,
    C3_CFB        = 30.0,
    TIKD          = 2.0,
    TTR_Amyloid   = 3.0,
    APOA1_Amyloid = 3.0,
    GSN_Amyloid   = 2.0,
    C3G           = 6.0,
    NoGenetic     = 0.8    # AKI very non-specific; most is non-genetic
  ),

  "HP:0001873" = list(  # Thrombocytopenia
    label         = "Thrombocytopenia",
    key           = TRUE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 25.0,
    CD46_MCP      = 25.0,
    CFI_aHUS      = 25.0,
    C3_CFB        = 25.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 2.0,
    NoGenetic     = 0.3    # thrombocytopenia in nephrology = TMA → aHUS (genetic or TTP)
  ),

  "HP:0001903" = list(  # Anaemia (haemolytic / microangiopathic)
    label         = "Anaemia (haemolytic / microangiopathic)",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.5,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 20.0,
    CD46_MCP      = 20.0,
    CFI_aHUS      = 20.0,
    C3_CFB        = 20.0,
    TIKD          = 3.0,
    TTR_Amyloid   = 2.0,
    APOA1_Amyloid = 2.0,
    GSN_Amyloid   = 1.5,
    C3G           = 3.0,
    NoGenetic     = 0.75   # anaemia non-specific; common in CKD of any cause
  ),

  "HP:0005575" = list(  # Haemolytic uraemic syndrome
    label         = "Haemolytic uraemic syndrome",
    key           = TRUE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 80.0,
    CD46_MCP      = 80.0,
    CFI_aHUS      = 80.0,
    C3_CFB        = 80.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 3.0,
    NoGenetic     = 0.12   # HUS/TMA in nephrology → complement-mediated aHUS
  ),

  "HP:0000504" = list(  # Ocular abnormality
    label         = "Ocular abnormality (anterior lenticonus, macular flecks)",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 22.0,
    Alport_AR     = 6.0,
    COL4_het      = 0.4,   # occurs uncommonly if at all in COL4 hets (Savige 2022)
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 5.0,   # lattice corneal dystrophy pathognomonic for gelsolin amyloidosis
    C3G           = 1.0,
    NoGenetic     = 0.1    # anterior lenticonus / lattice corneal dystrophy → genetic
  ),

  "HP:0012622" = list(  # Chronic kidney disease
    label         = "Chronic kidney disease",
    key           = FALSE,
    PKD1          = 5.0,
    PKD2          = 5.0,
    ARPKD         = 4.0,
    Alport_XL     = 8.0,
    Alport_AR     = 7.0,
    COL4_het      = 3.0,   # minority of carriers develop CKD
    NPHS1         = 7.0,
    NPHS2         = 7.0,
    INF2          = 6.0,
    Gitelman          = 3.0,
    Bartter           = 4.0,
    Distal_RTA        = 5.0,
    PrimaryHyperoxaluria = 10.0,
    NephrogenicDI     = 4.0,
    CFH_aHUS      = 5.0,
    CD46_MCP      = 5.0,
    CFI_aHUS      = 5.0,
    C3_CFB        = 5.0,
    TIKD          = 6.0,
    TTR_Amyloid   = 5.0,
    APOA1_Amyloid = 5.0,
    GSN_Amyloid   = 4.0,
    C3G           = 5.0,
    NoGenetic     = 0.9    # CKD extremely non-specific
  ),

  "HP:0003774" = list(  # End-stage kidney disease
    label         = "End-stage kidney disease",
    key           = FALSE,
    PKD1          = 6.0,
    PKD2          = 6.0,
    ARPKD         = 5.0,
    Alport_XL     = 10.0,
    Alport_AR     = 9.0,
    COL4_het      = 2.0,   # ~3% reach ESKD by age 60 (Savige 2022) — low but non-zero
    NPHS1         = 8.0,
    NPHS2         = 8.0,
    INF2          = 7.0,
    Gitelman          = 2.0,
    Bartter           = 4.0,
    Distal_RTA        = 8.0,
    PrimaryHyperoxaluria = 15.0,
    NephrogenicDI     = 5.0,
    CFH_aHUS      = 6.0,
    CD46_MCP      = 6.0,
    CFI_aHUS      = 6.0,
    C3_CFB        = 6.0,
    TIKD          = 5.0,
    TTR_Amyloid   = 4.0,
    APOA1_Amyloid = 4.0,
    GSN_Amyloid   = 3.0,
    C3G           = 5.0,
    NoGenetic     = 0.65   # ESKD raises genetic probability; age captured separately
  ),

  "HP:0000822" = list(  # Hypertension early onset
    label         = "Hypertension (early onset <35 years)",
    key           = FALSE,
    PKD1          = 8.0,   # early HTN strongly associated with PKD1 (larger kidneys, earlier compression)
    PKD2          = 4.0,
    ARPKD         = 3.0,
    Alport_XL     = 2.0,
    Alport_AR     = 2.0,
    COL4_het      = 1.5,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 0.3,
    Bartter           = 0.3,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 3.0,
    CD46_MCP      = 3.0,
    CFI_aHUS      = 3.0,
    C3_CFB        = 3.0,
    TIKD          = 3.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 2.0,
    NoGenetic     = 0.8    # early HTN also common in non-genetic essential hypertension
  ),

  "HP:0000969" = list(  # Oedema
    label         = "Oedema (periorbital or peripheral)",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.5,
    Alport_AR     = 1.5,
    COL4_het      = 1.0,
    NPHS1         = 15.0,  # universal in congenital nephrotic syndrome
    NPHS2         = 12.0,
    INF2          = 8.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 2.0,
    CD46_MCP      = 2.0,
    CFI_aHUS      = 2.0,
    C3_CFB        = 2.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 3.0,
    APOA1_Amyloid = 3.0,
    GSN_Amyloid   = 2.0,
    C3G           = 5.0,
    NoGenetic     = 0.8    # oedema non-specific
  ),

  "HP:0001942" = list(  # Metabolic alkalosis
    label         = "Metabolic alkalosis",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 25.0,
    Bartter           = 25.0,
    Distal_RTA        = 0.1,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.4    # metabolic alkalosis without cause → Bartter/Gitelman fairly specific
  ),

  "HP:0001997" = list(  # Gout / hyperuricaemia
    label         = "Gout / hyperuricaemia (disproportionate to renal function)",
    key           = FALSE,
    PKD1          = 2.0,
    PKD2          = 2.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 3.0,
    Bartter           = 3.0,
    Distal_RTA        = 3.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 15.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.6    # gout: TIKD is genetic cause but gout very common non-genetically
  ),

  "HP:0001638" = list(  # Cardiomyopathy
    label         = "Cardiomyopathy",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 25.0,  # restrictive cardiomyopathy cardinal in TTR amyloidosis
    APOA1_Amyloid = 5.0,
    GSN_Amyloid   = 3.0,
    C3G           = 1.0,
    NoGenetic     = 0.12   # restrictive cardiomyopathy → amyloidosis, likely genetic
  ),

  "HP:0001271" = list(  # Peripheral neuropathy
    label         = "Peripheral neuropathy / polyneuropathy",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 8.0,   # INF2 is associated with Charcot-Marie-Tooth (~70% of INF2 FSGS cases)
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 18.0,
    APOA1_Amyloid = 8.0,
    GSN_Amyloid   = 12.0,
    C3G           = 1.0,
    NoGenetic     = 0.18   # peripheral neuropathy + renal → amyloidosis or INF2/CMT
  ),

  "HP:0003159" = list(  # Hyperoxaluria
    label         = "Hyperoxaluria",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 80.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.15   # primary hyperoxaluria is genetic; almost always genetic in nephrology
  ),

  "HP:0010934" = list(  # Hyperuricosuria
    label         = "Hyperuricosuria",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 8.0,
    Bartter           = 5.0,
    Distal_RTA        = 5.0,
    PrimaryHyperoxaluria = 2.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 5.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.45   # hyperuricosuria: TIKD/tubulopathy specific in context
  ),

  # ── HPO terms generated by structured inputs ─────────────────────────────────

  "HP:0002153" = list(  # Hyperkalaemia
    label         = "Hyperkalaemia with acidosis (pseudohypoaldosteronism / type 4 RTA)",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 0.1,
    Bartter           = 15.0,
    Distal_RTA        = 0.2,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 3.0,
    CD46_MCP      = 3.0,
    CFI_aHUS      = 3.0,
    C3_CFB        = 3.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.75   # type 4 RTA common in diabetic/obstructive CKD
  ),

  "HP:0002917" = list(  # Hypomagnesaemia
    label         = "Hypomagnesaemia",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 35.0,
    Bartter           = 3.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 2.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.25   # isolated hypomagnesaemia → Gitelman/Bartter fairly specific
  ),

  "HP:0000863" = list(  # Nephrogenic diabetes insipidus
    label         = "Nephrogenic diabetes insipidus",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 5.0,
    Distal_RTA        = 2.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 90.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 2.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.2    # nephrogenic DI in nephrology → genetic tubulopathy likely
  ),

  "HP:0001878" = list(  # Haemolytic anaemia (microangiopathic)
    label         = "Haemolytic anaemia (microangiopathic / Coombs-negative)",
    key           = FALSE,
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 18.0,
    CD46_MCP      = 18.0,
    CFI_aHUS      = 18.0,
    C3_CFB        = 18.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 3.0,
    NoGenetic     = 0.18   # Coombs-negative MAHA → TMA → aHUS; strongly genetic in context
  )

)

# -----------------------------------------------------------------------------
# 3. NEGATIVE LIKELIHOOD RATIOS for KEY terms (when absent)
# -----------------------------------------------------------------------------
hpo_lr_negative <- list(
  "HP:0000113" = c(PKD1=0.015, PKD2=0.015, ARPKD=0.03, Alport_XL=1.0,  Alport_AR=1.0,  COL4_het=1.0,  NPHS1=1.0, NPHS2=1.0, INF2=1.0, Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0, CFH_aHUS=1.0,  CD46_MCP=1.0,  CFI_aHUS=1.0,  C3_CFB=1.0,  TIKD=0.9,  TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0, C3G=1.0,  NoGenetic=1.10),
  # COL4_het strengthened 0.2 -> 0.1 (5x -> 10x reduction if absent): haematuria
  # is described above as a cardinal, near-universal feature of symptomatic
  # carriers, so its absence should be about as specific against COL4_het as
  # against Alport_XL/AR, not markedly weaker. See note above prior recalibration.
  "HP:0000790" = c(PKD1=0.6,  PKD2=0.7,  ARPKD=0.9,  Alport_XL=0.15, Alport_AR=0.25, COL4_het=0.1,  NPHS1=0.8, NPHS2=0.7, INF2=0.8, Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0, CFH_aHUS=0.7,  CD46_MCP=0.7,  CFI_aHUS=0.7,  C3_CFB=0.7,  TIKD=0.8,  TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0, C3G=0.5,  NoGenetic=1.05),
  "HP:0000407" = c(PKD1=1.0,  PKD2=1.0,  ARPKD=1.0,  Alport_XL=0.35, Alport_AR=0.45, COL4_het=1.1,  NPHS1=1.0, NPHS2=1.0, INF2=1.0, Gitelman=1.0, Bartter=1.0, Distal_RTA=0.8, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0, CFH_aHUS=1.0,  CD46_MCP=1.0,  CFI_aHUS=1.0,  C3_CFB=1.0,  TIKD=1.0,  TTR_Amyloid=0.9, APOA1_Amyloid=1.0, GSN_Amyloid=0.7, C3G=1.0,  NoGenetic=1.08),
  "HP:0000093" = c(PKD1=0.7,  PKD2=0.8,  ARPKD=0.8,  Alport_XL=0.6,  Alport_AR=0.6,  COL4_het=0.8,  NPHS1=0.2, NPHS2=0.3, INF2=0.4, Gitelman=0.8, Bartter=0.8, Distal_RTA=0.7, PrimaryHyperoxaluria=0.7, NephrogenicDI=0.9, CFH_aHUS=0.6,  CD46_MCP=0.6,  CFI_aHUS=0.6,  C3_CFB=0.6,  TIKD=0.7,  TTR_Amyloid=0.5, APOA1_Amyloid=0.3, GSN_Amyloid=0.6, C3G=0.4,  NoGenetic=1.03),
  "HP:0000100" = c(PKD1=1.0,  PKD2=1.0,  ARPKD=1.0,  Alport_XL=0.8,  Alport_AR=0.8,  COL4_het=1.0,  NPHS1=0.1, NPHS2=0.2, INF2=0.4, Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0, CFH_aHUS=0.8,  CD46_MCP=0.8,  CFI_aHUS=0.8,  C3_CFB=0.8,  TIKD=1.0,  TTR_Amyloid=0.7, APOA1_Amyloid=0.5, GSN_Amyloid=0.8, C3G=0.7,  NoGenetic=1.05),
  "HP:0001873" = c(PKD1=1.0,  PKD2=1.0,  ARPKD=1.0,  Alport_XL=1.0,  Alport_AR=1.0,  COL4_het=1.0,  NPHS1=1.0, NPHS2=1.0, INF2=1.0, Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0, CFH_aHUS=0.3,  CD46_MCP=0.3,  CFI_aHUS=0.3,  C3_CFB=0.3,  TIKD=1.0,  TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0, C3G=0.8,  NoGenetic=1.10),
  "HP:0005575" = c(PKD1=1.0,  PKD2=1.0,  ARPKD=1.0,  Alport_XL=1.0,  Alport_AR=1.0,  COL4_het=1.0,  NPHS1=1.0, NPHS2=1.0, INF2=1.0, Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0, CFH_aHUS=0.15, CD46_MCP=0.15, CFI_aHUS=0.15, C3_CFB=0.15, TIKD=1.0,  TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0, C3G=0.7,  NoGenetic=1.12),
  "HP:0002150" = c(PKD1=1.0,  PKD2=1.0,  ARPKD=1.0,  Alport_XL=1.0,  Alport_AR=1.0,  COL4_het=1.0,  NPHS1=1.0, NPHS2=1.0, INF2=1.0, Gitelman=1.1, Bartter=0.2, Distal_RTA=0.3, PrimaryHyperoxaluria=0.7, NephrogenicDI=0.7, CFH_aHUS=1.0,  CD46_MCP=1.0,  CFI_aHUS=1.0,  C3_CFB=1.0,  TIKD=1.0,  TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0, C3G=1.0,  NoGenetic=1.05)
)

# -----------------------------------------------------------------------------
# 4. FAMILY HISTORY MODIFIERS
# -----------------------------------------------------------------------------
family_history_modifiers <- list(
  "Autosomal dominant" = list(
    PKD1          = 10.0,
    PKD2          = 10.0,
    ARPKD         = 1.0,
    Alport_XL     = 3.0,
    Alport_AR     = 4.0,
    COL4_het      = 8.0,   # fits AD inheritance pattern
    NPHS1         = 1.5,   # NPHS1 is AR; AD FH makes it less likely
    NPHS2         = 1.5,   # NPHS2 is AR; AD FH makes it less likely
    INF2          = 8.0,   # INF2 is classically AD
    Gitelman          = 1.0,
    Bartter           = 2.0,
    Distal_RTA        = 3.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 2.0,
    CFH_aHUS      = 4.0,
    CD46_MCP      = 3.0,
    CFI_aHUS      = 4.0,
    C3_CFB        = 4.0,
    TIKD          = 8.0,
    TTR_Amyloid   = 10.0,
    APOA1_Amyloid = 8.0,
    GSN_Amyloid   = 8.0,
    C3G           = 4.0,
    NoGenetic     = 0.12   # dominant family history very strongly implies genetic cause
  ),
  "Autosomal recessive" = list(
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 8.0,
    Alport_XL     = 1.0,
    Alport_AR     = 10.0,
    COL4_het      = 0.5,   # AR pattern suggests biallelic → Alport_AR more likely than het
    NPHS1         = 8.0,   # NPHS1 is AR
    NPHS2         = 8.0,   # NPHS2 is AR
    INF2          = 1.0,
    Gitelman          = 8.0,
    Bartter           = 5.0,
    Distal_RTA        = 5.0,
    PrimaryHyperoxaluria = 8.0,
    NephrogenicDI     = 3.0,
    CFH_aHUS      = 2.0,
    CD46_MCP      = 1.5,
    CFI_aHUS      = 2.0,
    C3_CFB        = 2.0,
    TIKD          = 2.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 5.0,
    NoGenetic     = 0.08   # clear recessive pattern almost excludes non-genetic cause
  ),
  "X-linked" = list(
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 15.0,
    Alport_AR     = 1.0,
    COL4_het      = 0.3,   # X-linked pattern points away from autosomal COL4A3/4
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 10.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 0.08   # X-linked inheritance pattern is highly specific for genetic disease
  ),
  "Unknown" = list(
    PKD1          = 2.0,
    PKD2          = 2.0,
    ARPKD         = 1.5,
    Alport_XL     = 2.0,
    Alport_AR     = 2.0,
    COL4_het      = 2.0,
    NPHS1         = 2.0,
    NPHS2         = 2.0,
    INF2          = 2.0,
    Gitelman          = 2.0,
    Bartter           = 2.0,
    Distal_RTA        = 2.0,
    PrimaryHyperoxaluria = 2.0,
    NephrogenicDI     = 2.0,
    CFH_aHUS      = 1.5,
    CD46_MCP      = 1.5,
    CFI_aHUS      = 1.5,
    C3_CFB        = 1.5,
    TIKD          = 2.0,
    TTR_Amyloid   = 2.0,
    APOA1_Amyloid = 2.0,
    GSN_Amyloid   = 2.0,
    C3G           = 2.0,
    NoGenetic     = 0.60   # family history present but pattern unknown → lowers NoGenetic
  ),
  "None" = list(
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,   # de novo variants occur — no family history is neutral
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 1.0    # no family history → neutral for NoGenetic
  )
)

# -----------------------------------------------------------------------------
# 5. CONSANGUINITY MODIFIER
# -----------------------------------------------------------------------------
consanguinity_modifiers <- list(
  "Yes" = list(
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 6.0,
    Alport_XL     = 1.0,
    Alport_AR     = 8.0,
    COL4_het      = 0.5,   # consanguinity raises probability of biallelic → Alport_AR more likely
    NPHS1         = 6.0,   # AR condition
    NPHS2         = 6.0,   # AR condition
    INF2          = 1.0,   # AD — consanguinity not informative
    Gitelman          = 5.0,
    Bartter           = 4.0,
    Distal_RTA        = 4.0,
    PrimaryHyperoxaluria = 6.0,
    NephrogenicDI     = 3.0,
    CFH_aHUS      = 2.0,
    CD46_MCP      = 1.5,
    CFI_aHUS      = 2.0,
    C3_CFB        = 2.0,
    TIKD          = 2.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 4.0,
    NoGenetic     = 0.20   # consanguinity strongly raises AR probability
  ),
  "No"      = lapply(condition_priors, function(x) 1.0),
  "Unknown" = lapply(condition_priors, function(x) 1.0)
)
names(consanguinity_modifiers$No)      <- names(condition_priors)
names(consanguinity_modifiers$Unknown) <- names(condition_priors)

# -----------------------------------------------------------------------------
# 5b. SEX MODIFIER (Alport subtype discrimination)
# -----------------------------------------------------------------------------
sex_alport_modifiers <- list(
  "Male" = list(
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.8,
    Alport_AR     = 0.6,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 2.5,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 1.0
  ),
  "Female" = list(
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 0.6,
    Alport_AR     = 1.8,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 0.5,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 1.0
  ),
  "Unknown" = list(
    PKD1          = 1.0,
    PKD2          = 1.0,
    ARPKD         = 1.0,
    Alport_XL     = 1.0,
    Alport_AR     = 1.0,
    COL4_het      = 1.0,
    NPHS1         = 1.0,
    NPHS2         = 1.0,
    INF2          = 1.0,
    Gitelman          = 2.0,
    Bartter           = 2.0,
    Distal_RTA        = 2.0,
    PrimaryHyperoxaluria = 2.0,
    NephrogenicDI     = 2.0,
    CFH_aHUS      = 1.0,
    CD46_MCP      = 1.0,
    CFI_aHUS      = 1.0,
    C3_CFB        = 1.0,
    TIKD          = 1.0,
    TTR_Amyloid   = 1.0,
    APOA1_Amyloid = 1.0,
    GSN_Amyloid   = 1.0,
    C3G           = 1.0,
    NoGenetic     = 1.0
  )
)

# -----------------------------------------------------------------------------
# 6. BIOPSY MODIFIERS
# Each entry is a named list of LR multipliers applied when the finding is
# present in biopsy_results. Findings absent from biopsy_results are ignored
# (not treated as negative evidence — EM may not have been done).
# -----------------------------------------------------------------------------
biopsy_modifiers <- list(

  "GBM thickening with splitting/lamellation on EM (Alport pattern)" = list(
    PKD1=1.0, PKD2=1.0, ARPKD=1.0,
    Alport_XL=15.0,  # lamellation is cardinal for X-linked Alport in affected males and severe females
    Alport_AR=10.0,  # biallelic disease shows the same EM pattern
    COL4_het=2.0,    # minority of heterozygotes develop GBM changes with age/progression
    NPHS1=1.0, NPHS2=1.0, INF2=1.0,
    Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0,
    CFH_aHUS=1.0, CD46_MCP=1.0, CFI_aHUS=1.0, C3_CFB=1.0,
    TIKD=1.0,
    TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0,
    C3G=1.0,
    NoGenetic=1.0
  ),

  "Thin basement membrane disease" = list(
    PKD1=1.0, PKD2=1.0, ARPKD=1.0,
    Alport_XL=5.0,   # female COL4A5 carriers and early/juvenile disease often show TBM on EM
    Alport_AR=4.0,   # early or mild biallelic disease; also carrier parents of AR probands
    COL4_het=12.0,   # cardinal biopsy finding for heterozygous COL4A3/COL4A4 (Savige 2022)
    NPHS1=1.0, NPHS2=1.0, INF2=1.0,
    Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0,
    CFH_aHUS=1.0, CD46_MCP=1.0, CFI_aHUS=1.0, C3_CFB=1.0,
    TIKD=1.0,
    TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0,
    C3G=1.0,
    NoGenetic=1.0
  ),

  "FSGS or diffuse mesangial sclerosis" = list(
    PKD1=1.0, PKD2=1.0, ARPKD=1.0,
    Alport_XL=1.0, Alport_AR=1.0, COL4_het=1.0,
    NPHS1=8.0,   # congenital NS / diffuse mesangial sclerosis; FSGS is a common histological endpoint
    NPHS2=6.0,   # podocin SRNS typically presents as FSGS
    INF2=5.0,    # AD FSGS; INF2 variants strongly associated with collapsing or classic FSGS
    Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0,
    CFH_aHUS=1.0, CD46_MCP=1.0, CFI_aHUS=1.0, C3_CFB=1.0,
    TIKD=1.0,
    TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0,
    C3G=1.0,
    NoGenetic=1.0
  ),

  "C3 glomerulopathy or MPGN" = list(
    PKD1=1.0, PKD2=1.0, ARPKD=1.0,
    Alport_XL=1.0, Alport_AR=1.0, COL4_het=1.0,
    NPHS1=1.0, NPHS2=1.0, INF2=1.0,
    Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0,
    CFH_aHUS=1.5,  # some overlap with aHUS complement spectrum
    CD46_MCP=1.0, CFI_aHUS=1.5, C3_CFB=1.5,
    TIKD=1.0,
    TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0,
    C3G=20.0,    # isolated C3 staining / MPGN pattern is the defining biopsy appearance of C3G
    NoGenetic=1.0
  ),

  "Tubulointerstitial kidney disease" = list(
    PKD1=1.0, PKD2=1.0, ARPKD=1.0,
    Alport_XL=1.0, Alport_AR=1.0, COL4_het=1.0,
    NPHS1=1.0, NPHS2=1.0, INF2=1.0,
    Gitelman=1.0, Bartter=1.0, Distal_RTA=1.0, PrimaryHyperoxaluria=1.0, NephrogenicDI=1.0,
    CFH_aHUS=1.0, CD46_MCP=1.0, CFI_aHUS=1.0, C3_CFB=1.0,
    TIKD=15.0,   # tubulointerstitial pattern without significant glomerular lesion is the hallmark of ADTKD
    TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0,
    C3G=1.0,
    NoGenetic=1.0
  )
)

# -----------------------------------------------------------------------------
# 7. AGE MODIFIERS
# -----------------------------------------------------------------------------
age_modifier <- function(age_years) {
  mods <- c(
    PKD1=1.0, PKD2=1.0, ARPKD=1.0,
    Alport_XL=1.0, Alport_AR=1.0, COL4_het=1.0,
    NPHS1=1.0, NPHS2=1.0, INF2=1.0,
    Gitelman          = 1.0,
    Bartter           = 1.0,
    Distal_RTA        = 1.0,
    PrimaryHyperoxaluria = 1.0,
    NephrogenicDI     = 1.0,
    CFH_aHUS=1.0, CD46_MCP=1.0, CFI_aHUS=1.0, C3_CFB=1.0,
    TIKD=1.0,
    NoGenetic=1.0,
    TTR_Amyloid=1.0, APOA1_Amyloid=1.0, GSN_Amyloid=1.0,
    C3G=1.0
  )
  if (is.na(age_years) || is.null(age_years)) return(mods)

  if (age_years < 1) {
    mods["ARPKD"]        <- 15.0
    mods["Bartter"]      <- 15.0   # antenatal/neonatal Bartter
    mods["NephrogenicDI"] <- 15.0  # X-linked NDI presents in infancy
    mods["PrimaryHyperoxaluria"] <- 5.0
    mods["NPHS1"]        <- 20.0   # congenital nephrotic syndrome presents at birth
    mods["NPHS2"]        <- 3.0
    mods["INF2"]         <- 0.2
    mods["C3G"]          <- 2.0
    mods["COL4_het"]     <- 1.0    # haematuria from COL4 hets can present in infancy
    mods["NoGenetic"]    <- 0.10   # neonatal kidney disease almost exclusively genetic
  } else if (age_years < 18) {
    mods["ARPKD"]         <- 8.0
    mods["Bartter"]       <- 8.0
    mods["NephrogenicDI"] <- 5.0
    mods["PrimaryHyperoxaluria"] <- 8.0
    mods["Gitelman"]      <- 1.5   # Gitelman rarely presents in childhood
    mods["Alport_XL"]     <- 2.5
    mods["Alport_AR"]     <- 2.0
    mods["NPHS1"]         <- 5.0
    mods["NPHS2"]         <- 6.0   # childhood SRNS; peak 3–8 years
    mods["INF2"]          <- 0.5
    mods["Tubulopathy"]   <- 2.0
    mods["CD46_MCP"]      <- 3.0   # MCP/CD46 aHUS predominantly paediatric
    mods["CFH_aHUS"]      <- 2.0
    mods["CFI_aHUS"]      <- 1.5
    mods["C3_CFB"]        <- 1.5
    mods["C3G"]           <- 3.0
    mods["TTR_Amyloid"]   <- 0.3
    mods["APOA1_Amyloid"] <- 0.3
    mods["GSN_Amyloid"]   <- 0.3
    mods["PKD1"]          <- 2.0   # PKD1 can manifest in childhood; PKD2 rarely symptomatic
    mods["PKD2"]          <- 0.5
    mods["COL4_het"]      <- 2.0   # haematuria from COL4 hets commonly first detected in childhood/adolescence
    mods["NoGenetic"]     <- 0.30  # paediatric nephrology → genetic cause very likely
  } else if (age_years < 30) {
    mods["Alport_XL"]     <- 2.5
    mods["Alport_AR"]     <- 2.0
    mods["NPHS1"]         <- 1.0
    mods["NPHS2"]         <- 3.0
    mods["INF2"]          <- 2.0
    mods["Tubulopathy"]   <- 1.5
    mods["CD46_MCP"]      <- 2.0
    mods["CFH_aHUS"]      <- 1.5
    mods["C3G"]           <- 2.0
    mods["TTR_Amyloid"]   <- 0.5
    mods["APOA1_Amyloid"] <- 0.5
    mods["GSN_Amyloid"]   <- 0.5
    mods["PKD1"]          <- 2.5   # young ADPKD presentation strongly suggests PKD1
    mods["Gitelman"]      <- 2.0   # Gitelman commonly first detected in young adults
    mods["PrimaryHyperoxaluria"] <- 5.0
    mods["NephrogenicDI"] <- 1.5
    mods["PKD2"]          <- 0.8
    mods["COL4_het"]      <- 1.5
    mods["NoGenetic"]     <- 0.65  # young adult → still pre-selected for genetic
  } else if (age_years < 50) {
    mods["PKD1"]          <- 3.0   # peak PKD1 progression and diagnosis decade
    mods["PKD2"]          <- 1.0
    mods["Alport_XL"]     <- 1.5
    mods["Alport_AR"]     <- 1.5
    mods["NPHS1"]         <- 0.5
    mods["NPHS2"]         <- 1.5
    mods["INF2"]          <- 3.0   # INF2 most commonly presents 20–50
    mods["TIKD"]          <- 2.0
    mods["TTR_Amyloid"]   <- 1.5
    mods["APOA1_Amyloid"] <- 1.5
    mods["Gitelman"]      <- 2.0   # peak presentation decade
    mods["COL4_het"]      <- 1.5
    # NoGenetic stays at 1.0 — neutral for peak genetic diagnosis decade
  } else {
    mods["PKD1"]          <- 2.0
    mods["PKD2"]          <- 4.0   # PKD2 ESKD at ~75; over-50 presentation strongly favours PKD2
    mods["TIKD"]          <- 3.0
    mods["NPHS1"]         <- 0.2
    mods["NPHS2"]         <- 0.5
    mods["INF2"]          <- 2.0
    mods["TTR_Amyloid"]   <- 5.0
    mods["APOA1_Amyloid"] <- 4.0
    mods["GSN_Amyloid"]   <- 4.0
    mods["Gitelman"]      <- 1.5   # late incidental diagnosis
    mods["NephrogenicDI"] <- 0.5
    mods["Bartter"]       <- 0.5
    mods["NoGenetic"]     <- 1.60  # over 50 → acquired CKD much more common
  }
  return(mods)
}

# -----------------------------------------------------------------------------
# 8. PANEL–CONDITION MAPPING
# -----------------------------------------------------------------------------
panel_condition_map <- list(
  R193 = c("PKD1", "PKD2", "ARPKD"),
  R194 = c("Alport_XL", "Alport_AR", "COL4_het"),
  R195 = c("NPHS1", "NPHS2", "INF2"),
  R196 = "C3G",
  R197 = "C3G",
  R198 = c("Gitelman", "Bartter", "Distal_RTA", "NephrogenicDI"),
  R201 = c("CFH_aHUS", "CD46_MCP", "CFI_aHUS", "C3_CFB"),
  R202 = "TIKD",
  R204 = c("TTR_Amyloid", "APOA1_Amyloid", "GSN_Amyloid"),
  R256 = c("Distal_RTA", "PrimaryHyperoxaluria", "Bartter", "NephrogenicDI"),
  R257 = c("Alport_XL", "Alport_AR", "PKD1", "PKD2", "NPHS1", "NPHS2", "INF2"),
  R446 = c("NPHS1", "NPHS2", "INF2")
)

# -----------------------------------------------------------------------------
# 9. DISPLAY LABELS AND COLOUR PALETTE
# -----------------------------------------------------------------------------
condition_labels <- c(
  PKD1          = "ADPKD — PKD1",
  PKD2          = "ADPKD — PKD2",
  ARPKD         = "ARPKD (PKHD1)",
  Alport_XL     = "Alport — X-linked (COL4A5)",
  Alport_AR     = "Alport — biallelic (COL4A3/4)",
  COL4_het      = "COL4 heterozygote (COL4A3/COL4A4)",
  NPHS1         = "FSGS/SRNS — NPHS1 (nephrin)",
  NPHS2         = "FSGS/SRNS — NPHS2 (podocin)",
  INF2          = "FSGS/SRNS — INF2",
  Gitelman          = "Gitelman syndrome (SLC12A3)",
  Bartter           = "Bartter syndrome (incl. pseudohypoaldosteronism)",
  Distal_RTA        = "Distal RTA (ATP6V1B1/ATP6V0A4/SLC4A1)",
  PrimaryHyperoxaluria = "Primary hyperoxaluria (AGXT/GRHPR/HOGA1)",
  NephrogenicDI     = "Congenital nephrogenic DI (AVPR2/AQP2)",
  CFH_aHUS      = "aHUS — CFH",
  CD46_MCP      = "aHUS — CD46/MCP",
  CFI_aHUS      = "aHUS — CFI",
  C3_CFB        = "aHUS — C3 / CFB",
  TIKD          = "Tubulointerstitial Kidney Disease",
  TTR_Amyloid   = "Amyloidosis — TTR",
  APOA1_Amyloid = "Amyloidosis — APOA1",
  GSN_Amyloid   = "Amyloidosis — Gelsolin (GSN)",
  C3G           = "C3 Glomerulopathy / MPGN",
  NoGenetic     = "No genetic diagnosis (modelled conditions)"
)

condition_colours <- c(
  PKD1          = "#2E86AB",   # blue family for ADPKD
  PKD2          = "#5BB5D5",
  ARPKD         = "#A23B72",
  Alport_XL     = "#F18F01",   # orange family for Alport / COL4
  Alport_AR     = "#B85C00",
  COL4_het      = "#E8C84A",   # amber/gold — distinct from biallelic Alport, reflects milder phenotype
  NPHS1         = "#8B1A00",   # red family for FSGS/SRNS
  NPHS2         = "#C73E1D",
  INF2          = "#E05A3A",
  Gitelman          = "#44BBA4",   # teal family for tubulopathies
  Bartter           = "#2A9D8F",
  Distal_RTA        = "#1B7A6E",
  PrimaryHyperoxaluria = "#E76F51",  # orange — distinct disease class
  NephrogenicDI     = "#5B8DB8",   # blue
  CFH_aHUS      = "#7B2D8B",   # purple family for aHUS
  CD46_MCP      = "#A855B5",
  CFI_aHUS      = "#5A1068",
  C3_CFB        = "#C084D4",
  TIKD          = "#1D7A4E",
  TTR_Amyloid   = "#E07B39",   # amber family for amyloidosis
  APOA1_Amyloid = "#C4622A",
  GSN_Amyloid   = "#F4A261",
  C3G           = "#5C6BC0",
  NoGenetic     = "#9E9E9E"    # neutral grey
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
    "Fremeaux-Bacchi V et al. Genetics and outcome of atypical HUS. CJASN 2013;8:554-562",
    "Cornec-Le Gall E et al. ADPKD. Lancet 2019;393:919-935",
    "Grantham JJ et al. PKD1 vs PKD2: volume, function, symptoms. JASN 2006;17:2429-2436",
    "Hinkes BG et al. Nephrotic syndrome in the first year of life. Nat Genet 2007;39:1018-1024",
    "Boyer O et al. INF2 mutations in Charcot-Marie-Tooth disease with glomerulopathy. NEJM 2011;365:2377-2388",
    "Eckardt KU et al. Autosomal dominant tubulointerstitial kidney disease. Nat Rev Nephrol 2015;11:617-625",
    "Wechalekar AD et al. Systemic amyloidosis. Lancet 2016;387:2641-2654",
    "Benson MD et al. Amyloid nomenclature 2020. Amyloid 2020;27:217-222",
    "Nester CM et al. C3 glomerulopathy. Nephrol Dial Transplant 2018;33:i1-i7"
  ),
  caveat = "Likelihood ratios are expert approximations informed by published literature. They have not been formally validated in a prospective clinical cohort. Posterior probabilities should be interpreted as decision-support estimates only."
)
