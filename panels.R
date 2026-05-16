# =============================================================================
# data/panels.R
# NHS Genomic Test Directory — Renal Panels
# Version: v7, April 2025
# Source: https://www.england.nhs.uk/publication/national-genomic-test-directories/
#
# Structure per panel:
#   $code         — GT Directory panel code
#   $name         — Full condition name
#   $genes        — Key genes tested (illustrative, not exhaustive)
#   $inheritance  — Expected inheritance pattern(s)
#   $major_criteria — Named list; each criterion has:
#                     $description, $parameter (which input field), $value (matching value(s))
#   $hpo_relevant — HPO IDs that are relevant/supportive for this panel
#   $notes        — Free-text clinical notes for display
#   $nhs_url      — Direct link to GT Directory entry
# =============================================================================

renal_panels <- list(

  R187 = list(
    code        = "R187",
    name        = "Congenital anomalies of the kidney and urinary tract (CAKUT)",
    genes       = c("HNF1B", "PAX2", "GATA3", "EYA1", "SIX1", "SIX2", "SALL1", "UPK3A"),
    inheritance = c("Autosomal dominant", "Autosomal recessive"),
    major_criteria = list(
      structural_anomaly = list(
        description = "Structural renal anomaly confirmed on imaging (horseshoe kidney, renal dysplasia, duplex system, PUJ obstruction, VUR grade III+)",
        parameter   = "hpo_terms",
        value       = c("HP:0000085", "HP:0000126", "HP:0000110", "HP:0001231", "HP:0000076")
      ),
      age_presentation = list(
        description = "Age at presentation <18 years OR antenatal diagnosis",
        parameter   = "age",
        value       = "< 18"
      ),
      exclude_acquired = list(
        description = "Acquired causes excluded (obstruction, infection, reflux nephropathy without structural basis)",
        parameter   = "free_text",
        value       = NULL  # assessed via vignette
      )
    ),
    supportive_criteria = list(
      family_history = list(
        description = "Family history of renal tract anomaly",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      ),
      extra_renal = list(
        description = "Extra-renal features (ear anomalies, hearing loss, branchial cysts — suggest HNF1B or EYA1)",
        parameter   = "extra_renal",
        value       = c("Hearing loss", "Skeletal abnormality")
      )
    ),
    hpo_relevant = c(
      "HP:0000085",  # Horseshoe kidney
      "HP:0000126",  # Hydronephrosis
      "HP:0000110",  # Renal dysplasia
      "HP:0001231",  # Pelviureteric junction obstruction
      "HP:0000076",  # Vesicoureteral reflux
      "HP:0000079",  # Abnormality of urinary system
      "HP:0000104"   # Renal agenesis
    ),
    notes   = "Most common indication is bilateral or complex structural anomaly. Isolated unilateral VUR without family history is a lower priority. HNF1B deletions account for ~15% and may show diabetes and pancreatic hypoplasia.",
    nhs_url = "https://www.england.nhs.uk/publication/national-genomic-test-directories/"
  ),

  R188 = list(
    code        = "R188",
    name        = "Steroid-resistant nephrotic syndrome (SRNS) / FSGS",
    genes       = c("NPHS1", "NPHS2", "WT1", "LAMB2", "PLCE1", "COQ2", "COQ6", "ADCK4", "INF2", "TRPC6"),
    inheritance = c("Autosomal recessive", "Autosomal dominant"),
    major_criteria = list(
      nephrotic_range_proteinuria = list(
        description = "Nephrotic-range proteinuria (uPCR >300 mg/mmol or urine protein >3.5g/24h in adults)",
        parameter   = "proteinuria",
        value       = "Nephrotic-range"
      ),
      steroid_resistance = list(
        description = "Failure to achieve complete remission after ≥8 weeks of adequate steroid therapy",
        parameter   = "free_text",
        value       = NULL
      ),
      biopsy_findings = list(
        description = "Biopsy showing FSGS, minimal change disease, or diffuse mesangial sclerosis",
        parameter   = "hpo_terms",
        value       = c("HP:0012622", "HP:0000100")
      )
    ),
    supportive_criteria = list(
      age_onset = list(
        description = "Age at onset <25 years (especially congenital or infantile nephrotic syndrome)",
        parameter   = "age",
        value       = "< 25"
      ),
      family_history = list(
        description = "Family history of nephrotic syndrome or ESKD",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      ),
      consanguinity = list(
        description = "Consanguineous parents (increases prior for AR forms: NPHS1, NPHS2)",
        parameter   = "consanguinity",
        value       = "Yes"
      )
    ),
    hpo_relevant = c(
      "HP:0000100",  # Nephrotic syndrome
      "HP:0000093",  # Proteinuria
      "HP:0012622",  # FSGS
      "HP:0000969",  # Oedema
      "HP:0003774",  # ESKD
      "HP:0001944"   # Dehydration (from hypoalbuminaemia)
    ),
    notes   = "Congenital nephrotic syndrome (onset <3 months) is almost always genetic — prioritise. NPHS2 (podocin) most common AR cause. WT1 mutations associated with Denys-Drash syndrome (ambiguous genitalia, Wilms tumour risk) — check for extra-renal features.",
    nhs_url = "https://www.england.nhs.uk/publication/national-genomic-test-directories/"
  ),

  R189 = list(
    code        = "R189",
    name        = "Inherited renal tubulopathies",
    genes       = c("SLC12A1", "KCNJ1", "CLCNKB", "BSND", "SLC12A3", "CLDN16", "CLDN19",
                    "SLC34A1", "SLC34A3", "ATP6V1B1", "ATP6V0A4", "SLC4A1", "UMOD",
                    "REN", "HNF4A", "SLC2A2"),
    inheritance = c("Autosomal recessive", "Autosomal dominant"),
    major_criteria = list(
      electrolyte_abnormality = list(
        description = "Persistent unexplained electrolyte disturbance: hypokalaemia, hypomagnesaemia, hypercalciuria, hypophosphataemia, or metabolic alkalosis/acidosis",
        parameter   = "hpo_terms",
        value       = c("HP:0002900", "HP:0002150", "HP:0002148", "HP:0002153", "HP:0001942")
      ),
      tubular_dysfunction = list(
        description = "Biochemical evidence of tubular dysfunction (low TmP/GFR, fractional excretion of electrolytes inappropriately high, urine pH abnormality)",
        parameter   = "free_text",
        value       = NULL
      ),
      exclude_acquired = list(
        description = "Acquired causes excluded (loop diuretics, PPIs, coeliac disease, primary hyperaldosteronism)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      nephrocalcinosis = list(
        description = "Nephrocalcinosis or nephrolithiasis on imaging",
        parameter   = "hpo_terms",
        value       = c("HP:0000121", "HP:0000787")
      ),
      early_onset = list(
        description = "Onset in childhood or early adulthood",
        parameter   = "age",
        value       = "< 30"
      ),
      family_history = list(
        description = "Family history of electrolyte disorder or CKD",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      )
    ),
    hpo_relevant = c(
      "HP:0002900",  # Hypokalaemia
      "HP:0002150",  # Hypercalciuria
      "HP:0002148",  # Hypophosphataemia
      "HP:0000121",  # Nephrocalcinosis
      "HP:0000787",  # Nephrolithiasis
      "HP:0001942",  # Metabolic alkalosis
      "HP:0002153"   # Hyperkalaemia (distal RTA)
    ),
    notes   = "Consider Bartter (salt-wasting, hypokalaemia, alkalosis, hypercalciuria) vs Gitelman (milder, hypomagnesaemia, hypocalciuria). Distal RTA (ATP6V) often presents with nephrocalcinosis. UMOD mutations cause medullary cystic disease type 2 — may look like early CKD with hyperuricaemia.",
    nhs_url = "https://www.england.nhs.uk/publication/national-genomic-test-directories/"
  ),

  R190 = list(
    code        = "R190",
    name        = "Alport syndrome and familial haematuria",
    genes       = c("COL4A3", "COL4A4", "COL4A5", "MYH9"),
    inheritance = c("X-linked", "Autosomal recessive", "Autosomal dominant"),
    major_criteria = list(
      persistent_haematuria = list(
        description = "Persistent microscopic haematuria on ≥2 occasions (exclude UTI, stones, malignancy)",
        parameter   = "haematuria",
        value       = c("Microscopic", "Macroscopic")
      ),
      family_history_haematuria = list(
        description = "Family history of haematuria, renal failure, or Alport syndrome",
        parameter   = "family_history",
        value       = c("X-linked", "Autosomal recessive", "Autosomal dominant")
      ),
      snhl = list(
        description = "Sensorineural hearing loss (bilateral, high-frequency, progressive)",
        parameter   = "extra_renal",
        value       = "Hearing loss"
      )
    ),
    supportive_criteria = list(
      ocular = list(
        description = "Ocular abnormality: anterior lenticonus, macular flecks, posterior polymorphous corneal dystrophy",
        parameter   = "extra_renal",
        value       = "Ocular abnormality"
      ),
      biopsy = list(
        description = "Renal biopsy showing GBM thinning or splitting on electron microscopy",
        parameter   = "free_text",
        value       = NULL
      ),
      egfr_decline = list(
        description = "Progressive CKD / declining eGFR without alternative explanation",
        parameter   = "egfr",
        value       = "< 60"
      )
    ),
    hpo_relevant = c(
      "HP:0000790",  # Haematuria
      "HP:0000407",  # Sensorineural hearing loss
      "HP:0000504",  # Abnormality of vision / anterior lenticonus
      "HP:0003774",  # End-stage renal disease
      "HP:0012622",  # CKD
      "HP:0000365"   # Hearing impairment
    ),
    notes   = "X-linked Alport (COL4A5) most common — affected males progress to ESKD by 20–30s, carrier females variable. Haematuria + SNHL + family history = high prior. Thin basement membrane nephropathy (COL4A3/4 heterozygous) is a milder allelic condition. MYH9 mutations cause Epstein/Fechtner syndromes with macrothrombocytopenia.",
    nhs_url = "https://www.england.nhs.uk/publication/national-genomic-test-directories/"
  ),

  R191 = list(
    code        = "R191",
    name        = "Renal cysts and polycystic kidney disease",
    genes       = c("PKD1", "PKD2", "PKHD1", "HNF1B", "MUC1", "UMOD", "REN",
                    "SEC63", "PRKCSH", "ALG8", "GANAB"),
    inheritance = c("Autosomal dominant", "Autosomal recessive"),
    major_criteria = list(
      bilateral_cysts = list(
        description = "Bilateral renal cysts on imaging (ultrasound, CT or MRI)",
        parameter   = "hpo_terms",
        value       = c("HP:0000113", "HP:0005584")
      ),
      ravine_criteria = list(
        description = "Age-adjusted Ravine criteria met on ultrasound (e.g. age 15–39: ≥3 cysts total; age 40–59: ≥2 per kidney; age ≥60: ≥4 per kidney)",
        parameter   = "age",
        value       = NULL  # assessed contextually
      ),
      family_history_pkd = list(
        description = "First-degree family history of PKD or ESKD",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      )
    ),
    supportive_criteria = list(
      hepatic_cysts = list(
        description = "Hepatic cysts (polycystic liver disease — common in ADPKD PKD1/2 and SEC63/PRKCSH)",
        parameter   = "extra_renal",
        value       = "Liver cysts"
      ),
      intracranial_aneurysm = list(
        description = "Intracranial aneurysm or aortic root dilatation (cardiovascular associations of ADPKD)",
        parameter   = "hpo_terms",
        value       = c("HP:0002616", "HP:0012518")
      ),
      hypertension = list(
        description = "Hypertension presenting before age 35",
        parameter   = "extra_renal",
        value       = "Hypertension <35yrs"
      )
    ),
    hpo_relevant = c(
      "HP:0000113",  # Polycystic kidney dysplasia
      "HP:0005584",  # Renal cyst
      "HP:0001407",  # Hepatic cysts
      "HP:0002616",  # Aortic root aneurysm
      "HP:0012518",  # Intracranial aneurysm
      "HP:0000822"   # Hypertension
    ),
    notes   = "ADPKD (PKD1 > PKD2) is the most common inherited renal condition. PKD1 mutations cause earlier and more severe disease. ARPKD (PKHD1) presents in infancy/childhood with enlarged echogenic kidneys and congenital hepatic fibrosis. HNF1B deletions can cause cysts + MODY5 diabetes — check blood glucose.",
    nhs_url = "https://www.england.nhs.uk/publication/national-genomic-test-directories/"
  ),

  R192 = list(
    code        = "R192",
    name        = "Haemolytic uraemic syndrome / thrombotic microangiopathy (aHUS/TMA)",
    genes       = c("CFH", "CFI", "CFB", "C3", "MCP", "THBD", "DGKE", "INF2",
                    "CFHR1", "CFHR3", "CFHR4", "CFHR5"),
    inheritance = c("Autosomal dominant", "Autosomal recessive"),
    major_criteria = list(
      microangiopathic_haemolysis = list(
        description = "Microangiopathic haemolytic anaemia (low Hb, high LDH, low haptoglobin, schistocytes on film)",
        parameter   = "hpo_terms",
        value       = c("HP:0001903", "HP:0001878")
      ),
      thrombocytopenia = list(
        description = "Thrombocytopenia (platelets <150 × 10⁹/L)",
        parameter   = "hpo_terms",
        value       = "HP:0001873"
      ),
      aki = list(
        description = "Acute kidney injury (AKI) — often severe, may require dialysis",
        parameter   = "hpo_terms",
        value       = "HP:0001919"
      ),
      atypical = list(
        description = "Atypical HUS — STEC/Shiga toxin excluded; ADAMTS13 activity normal (excludes TTP)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      recurrent = list(
        description = "Recurrent episodes of TMA",
        parameter   = "free_text",
        value       = NULL
      ),
      family_history = list(
        description = "Family history of HUS or TMA",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      ),
      complement_screen = list(
        description = "Abnormal complement screen (low C3, low factor H/I, anti-CFH antibodies)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    hpo_relevant = c(
      "HP:0001919",  # Acute kidney injury
      "HP:0001903",  # Anaemia
      "HP:0001873",  # Thrombocytopenia
      "HP:0005575",  # Haemolytic uraemic syndrome
      "HP:0001878",  # Haemolytic anaemia
      "HP:0001977"   # Abnormal thrombosis
    ),
    notes   = "Complement pathway mutations account for ~60% of aHUS. CFH mutations most common (~25%). Anti-CFH antibodies (associated with CFHR1/3 deletion) are important to test as they respond to immunosuppression. Eculizumab/ravulizumab are licensed treatments — genetic diagnosis guides long-term management.",
    nhs_url = "https://www.england.nhs.uk/publication/national-genomic-test-directories/"
  ),

  R370 = list(
    code        = "R370",
    name        = "Unexplained CKD with extra-renal features",
    genes       = c("COL4A3", "COL4A4", "COL4A5", "HNF1B", "UMOD", "MUC1", "REN",
                    "PAX2", "EYA1", "GATA3", "WT1", "LMX1B"),
    inheritance = c("Autosomal dominant", "Autosomal recessive", "X-linked"),
    major_criteria = list(
      unexplained_ckd = list(
        description = "CKD (eGFR <60 ml/min/1.73m²) without clear acquired cause after standard workup",
        parameter   = "egfr",
        value       = "< 60"
      ),
      extra_renal_feature = list(
        description = "At least one extra-renal feature: hearing loss, ocular abnormality, hepatic fibrosis, neurological, skeletal, haematological",
        parameter   = "extra_renal",
        value       = c("Hearing loss", "Ocular abnormality", "Liver cysts", "Cognitive impairment", "Skeletal abnormality")
      )
    ),
    supportive_criteria = list(
      age = list(
        description = "Age at CKD diagnosis <50 years (genetic causes more likely in younger patients)",
        parameter   = "age",
        value       = "< 50"
      ),
      family_history = list(
        description = "Family history of CKD or ESKD",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive", "X-linked")
      ),
      no_traditional_risk = list(
        description = "Absence of traditional CKD risk factors (diabetes, hypertension, obstruction, NSAID use)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    hpo_relevant = c(
      "HP:0012622",  # Chronic kidney disease
      "HP:0000407",  # Sensorineural hearing loss
      "HP:0001395",  # Hepatic fibrosis
      "HP:0000478",  # Abnormality of the eye
      "HP:0002011",  # Morphological abnormality of CNS
      "HP:0000924",  # Skeletal abnormality
      "HP:0003774"   # End-stage renal disease
    ),
    notes   = "This is a 'catch-all' panel for patients who don't fit neatly into R187–R192 but have strong features suggesting a genetic aetiology. Nail-patella syndrome (LMX1B), Townes-Brocks (SALL1), and branchio-oto-renal syndrome (EYA1) may present here. Useful when phenotype is incomplete or diagnosis unclear.",
    nhs_url = "https://www.england.nhs.uk/publication/national-genomic-test-directories/"
  )

)

# =============================================================================
# Helper: get all unique HPO IDs across all panels
# =============================================================================
all_panel_hpo_ids <- function() {
  unique(unlist(lapply(renal_panels, `[[`, "hpo_relevant")))
}

# =============================================================================
# Helper: get panels relevant to a given HPO term
# =============================================================================
panels_for_hpo <- function(hpo_id) {
  names(Filter(function(p) hpo_id %in% p$hpo_relevant, renal_panels))
}
