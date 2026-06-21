# =============================================================================
# data/strict_criteria.R
# Layer 1 strict eligibility criteria
# Source: NHS Rare & Inherited Disease Eligibility Criteria (Test_criteria.csv)
#
# Parameters now supported in eval_criterion():
#   hpo_terms | age | egfr | proteinuria | haematuria | family_history |
#   extra_renal | biopsy_results | ancestry | clinical_context | free_text
#
# biopsy_results choices (must match UI exactly):
#   "FSGS or diffuse mesangial sclerosis"
#   "GBM thickening with splitting/lamellation on EM (Alport pattern)"
#   "Thin basement membrane disease"
#   "Tubulointerstitial fibrosis (no glomerular lesion)"
#   "C3 glomerulopathy or MPGN"
#
# ancestry choices:
#   "Cypriot or eastern Mediterranean"
#   "African, African-American, Caribbean or Brazilian"
#
# clinical_context choices:
#   "Genetic diagnosis required for management"
#   "Renal transplant being considered"
#   "Complement inhibitory therapy being considered"
#   "Being assessed for living kidney donation"
#   "Counselled and consented for APOL1 testing"
# =============================================================================

panel_strict_criteria <- list(

  R193 = list(
    description = "Non-syndromic cystic renal disease with criteria for genetic testing",
    required = list(
      cystic_disease = list(
        description = "Cystic renal disease on imaging (excluding acquired cystic disease due to CKD/ESKD)",
        parameter   = "hpo_terms",
        value       = c("HP:0000113", "HP:0005584"),
        assessable  = TRUE
      )
    ),
    any_of = list(
      age_under_18 = list(
        description = "Clinically symptomatic disease presenting before age 18",
        parameter   = "age",
        value       = "< 18",
        assessable  = TRUE
      ),
      ad_family_history = list(
        description = "Autosomal dominant or unknown family history (consistent with ADPKD)",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Unknown"),
        assessable  = TRUE
      ),
      management_need = list(
        description = "Genetic diagnosis required for management (not characteristic of ADPKD, or ADPKD where diagnosis influences management)",
        parameter   = "clinical_context",
        value       = "Genetic diagnosis required for management",
        assessable  = TRUE
      )
    )
  ),

  R194 = list(
    description = "Haematuria with at least one feature of hereditary nephritis",
    required = list(
      haematuria = list(
        description = "Haematuria present (microscopic or macroscopic)",
        parameter   = "haematuria",
        value       = c("Microscopic", "Macroscopic"),
        assessable  = TRUE
      )
    ),
    any_of = list(
      family_history = list(
        description = "First-degree relative with haematuria or unexplained chronic renal failure",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive", "X-linked", "Unknown"),
        assessable  = TRUE
      ),
      biopsy_evidence = list(
        description = "Biopsy showing GBM thickening with splitting/lamellation (Alport pattern) or thin basement membrane disease",
        parameter   = "biopsy_results",
        value       = c("GBM thickening with splitting/lamellation on EM (Alport pattern)", "Thin basement membrane disease"),
        assessable  = TRUE
      ),
      alport_features = list(
        description = "Clinical features of Alport syndrome: high-tone SNHL or characteristic ophthalmic signs",
        parameter   = "extra_renal",
        value       = c("Hearing loss", "Ocular abnormality"),
        assessable  = TRUE
      )
    )
  ),

  R195 = list(
    description = "Steroid-resistant nephrotic syndrome or proteinuric disease with FSGS/DMS on biopsy",
    required = list(),
    any_of = list(
      srns = list(
        description = "Steroid-resistant nephrotic syndrome (nephrotic-range proteinuria failing steroids)",
        parameter   = "proteinuria",
        value       = "Nephrotic-range",
        assessable  = TRUE
      ),
      fsgs_biopsy = list(
        description = "Biopsy showing FSGS or diffuse mesangial sclerosis, no identifiable cause, transplant or immunosuppression planned",
        parameter   = "biopsy_results",
        value       = c("FSGS or diffuse mesangial sclerosis"),
        assessable  = TRUE
      )
    )
  ),

  R196 = list(
    description = "C3 glomerulopathy or unexplained haematuria/renal failure in a patient of Cypriot ancestry",
    required = list(
      cypriot_ancestry = list(
        description = "Patient is of Cypriot or eastern Mediterranean ancestry",
        parameter   = "ancestry",
        value       = c("Cypriot or eastern Mediterranean"),
        assessable  = TRUE
      )
    ),
    any_of = list(
      haematuria = list(
        description = "Haematuria present",
        parameter   = "haematuria",
        value       = c("Microscopic", "Macroscopic"),
        assessable  = TRUE
      ),
      renal_failure = list(
        description = "Unexplained renal failure / CKD (eGFR < 60)",
        parameter   = "egfr",
        value       = "< 60",
        assessable  = TRUE
      ),
      c3_glomerulopathy = list(
        description = "Biopsy-proven C3 glomerulopathy or MPGN",
        parameter   = "biopsy_results",
        value       = c("C3 glomerulopathy or MPGN"),
        assessable  = TRUE
      )
    )
  ),

  R197 = list(
    description = "Idiopathic MPGN or C3 glomerulopathy with onset before age 18, plus indication for genetic testing",
    required = list(
      age_under_18 = list(
        description = "Onset before age 18",
        parameter   = "age",
        value       = "< 18",
        assessable  = TRUE
      ),
      mpgn_biopsy = list(
        description = "Biopsy-proven idiopathic MPGN or C3 glomerulopathy",
        parameter   = "biopsy_results",
        value       = c("C3 glomerulopathy or MPGN"),
        assessable  = TRUE
      )
    ),
    any_of = list(
      family_history = list(
        description = "Family history of MPGN or unexplained end-stage renal disease",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive", "Unknown"),
        assessable  = TRUE
      ),
      transplant_planned = list(
        description = "Renal transplant is being considered",
        parameter   = "clinical_context",
        value       = "Renal transplant being considered",
        assessable  = TRUE
      ),
      complement_therapy = list(
        description = "Patient is being considered for complement inhibitory therapies",
        parameter   = "clinical_context",
        value       = "Complement inhibitory therapy being considered",
        assessable  = TRUE
      )
    )
  ),

  R198 = list(
    description = "Primary renal tubulopathy with a recognised biochemical pattern",
    required = list(),
    any_of = list(
      hypokalaemic_alkalosis = list(
        description = "Hypokalaemic alkalosis with normal or low blood pressure (Bartter/Gitelman)",
        parameter   = "hpo_terms",
        value       = c("HP:0002900", "HP:0001942"),
        assessable  = TRUE
      ),
      hypokalaemic_htn = list(
        description = "Hypokalaemic alkalosis with elevated blood pressure (Liddle syndrome)",
        parameter   = "hpo_terms",
        value       = c("HP:0002900"),
        assessable  = TRUE
      ),
      hyperkalaemic_acidosis = list(
        description = "Hyperkalaemic acidosis (pseudohypoaldosteronism type 1 or 2)",
        parameter   = "hpo_terms",
        value       = c("HP:0002153"),
        assessable  = TRUE
      ),
      hypomagnesaemia = list(
        description = "Hypomagnesaemia",
        parameter   = "hpo_terms",
        value       = c("HP:0002917"),
        assessable  = TRUE
      ),
      nephrogenic_di = list(
        description = "Nephrogenic diabetes insipidus",
        parameter   = "hpo_terms",
        value       = c("HP:0000863"),
        assessable  = TRUE
      ),
      hypokalaemic_acidosis = list(
        description = "Hypokalaemic acidosis (proximal RTA or renal Fanconi syndrome)",
        parameter   = "hpo_terms",
        value       = c("HP:0002900"),
        assessable  = TRUE
      ),
      hypercalciuria_stones = list(
        description = "Hypercalciuria or nephrocalcinosis as primary tubulopathy feature",
        parameter   = "hpo_terms",
        value       = c("HP:0002150", "HP:0000121"),
        assessable  = TRUE
      ),
      expert_centre = list(
        description = "Other rare type of renal tubulopathy seen in an expert centre",
        parameter   = "free_text",
        value       = NULL,
        assessable  = FALSE
      )
    )
  ),

  R201 = list(
    description = "Atypical HUS: all three TMA features required, being considered for complement inhibitory therapy",
    required = list(
      aki = list(
        description = "Acute renal failure / AKI",
        parameter   = "hpo_terms",
        value       = c("HP:0001919"),
        assessable  = TRUE
      ),
      thrombocytopenia = list(
        description = "Thrombocytopenia",
        parameter   = "hpo_terms",
        value       = c("HP:0001873"),
        assessable  = TRUE
      ),
      maha = list(
        description = "Microangiopathic haemolytic anaemia (Coombs negative)",
        parameter   = "hpo_terms",
        value       = c("HP:0001903", "HP:0001878", "HP:0005575"),
        assessable  = TRUE
      ),
      complement_therapy = list(
        description = "Being considered for complement inhibitory therapies (eculizumab/ravulizumab)",
        parameter   = "clinical_context",
        value       = "Complement inhibitory therapy being considered",
        assessable  = TRUE
      )
    ),
    any_of = list()
  ),

  R202 = list(
    description = "Tubulointerstitial kidney disease: biopsy-proven TIKD plus family history",
    required = list(
      renal_impairment = list(
        description = "Renal impairment (eGFR < 60 ml/min/1.73m²)",
        parameter   = "egfr",
        value       = "< 60",
        assessable  = TRUE
      ),
      family_history = list(
        description = "First-degree relative with TIKD or unexplained end-stage renal disease",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive", "Unknown"),
        assessable  = TRUE
      ),
      tikd_biopsy = list(
        description = "Biopsy showing tubulointerstitial fibrosis with no glomerular lesion and no identifiable cause",
        parameter   = "biopsy_results",
        value       = c("Tubulointerstitial fibrosis (no glomerular lesion)"),
        assessable  = TRUE
      )
    ),
    any_of = list()
  ),

  R204 = list(
    description = "Clinical features suggestive of hereditary systemic amyloidosis",
    required = list(),
    any_of = list(
      cardiomyopathy = list(
        description = "Restrictive cardiomyopathy",
        parameter   = "hpo_terms",
        value       = c("HP:0001638"),
        assessable  = TRUE
      ),
      neuropathy = list(
        description = "Autonomic or peripheral neuropathy",
        parameter   = "hpo_terms",
        value       = c("HP:0001271"),
        assessable  = TRUE
      ),
      renal_impairment = list(
        description = "Renal impairment (eGFR < 60)",
        parameter   = "egfr",
        value       = "< 60",
        assessable  = TRUE
      ),
      proteinuria = list(
        description = "Proteinuria",
        parameter   = "proteinuria",
        value       = c("Sub-nephrotic", "Nephrotic-range"),
        assessable  = TRUE
      ),
      gi_symptoms = list(
        description = "GI symptoms suggestive of amyloid (autonomic neuropathy, malabsorption)",
        parameter   = "free_text",
        value       = NULL,
        assessable  = FALSE
      )
    )
  ),

  R256 = list(
    description = "Nephrocalcinosis or nephrolithiasis with acquired causes excluded",
    required = list(),
    any_of = list(
      nephrocalcinosis = list(
        description = "Nephrocalcinosis on imaging",
        parameter   = "hpo_terms",
        value       = c("HP:0000121"),
        assessable  = TRUE
      ),
      nephrolithiasis = list(
        description = "Recurrent nephrolithiasis",
        parameter   = "hpo_terms",
        value       = c("HP:0000787"),
        assessable  = TRUE
      )
    )
  ),

  R257 = list(
    description = "End-stage renal disease developing under age 36 with no identifiable cause",
    required = list(
      age_under_36 = list(
        description = "ESKD developing before age 36",
        parameter   = "age",
        value       = "< 36",
        assessable  = TRUE
      ),
      severe_ckd = list(
        description = "End-stage renal disease or eGFR < 30 ml/min/1.73m²",
        parameter   = "egfr",
        value       = "< 30",
        assessable  = TRUE
      ),
      no_identifiable_cause = list(
        description = "No identifiable cause detectable by biopsy, biochemistry, imaging or clinical assessment",
        parameter   = "free_text",
        value       = NULL,
        assessable  = FALSE
      )
    ),
    any_of = list()
  ),

  R446 = list(
    description = "APOL1 testing for potential living kidney donors of African/Caribbean/Brazilian ancestry",
    required = list(
      donor_assessment = list(
        description = "Individual is being assessed for living kidney donation",
        parameter   = "clinical_context",
        value       = "Being assessed for living kidney donation",
        assessable  = TRUE
      ),
      african_ancestry = list(
        description = "Both parents have (or likely have) African, African-American, Caribbean or Brazilian heritage",
        parameter   = "ancestry",
        value       = c("African, African-American, Caribbean or Brazilian"),
        assessable  = TRUE
      ),
      consent = list(
        description = "Individual has undergone counselling, understands implications, and has provided consent",
        parameter   = "clinical_context",
        value       = "Counselled and consented for APOL1 testing",
        assessable  = TRUE
      )
    ),
    any_of = list()
  )

)
