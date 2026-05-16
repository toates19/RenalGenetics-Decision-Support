# =============================================================================
# data/panels.R
# NHS Genomic Test Directory — Renal Panels
# Source: PanelApp Genomics England (https://panelapp.genomicsengland.co.uk)
#         NHS Rare & Inherited Disease Eligibility Criteria v9
#
# Structure per panel:
#   $code         — GT Directory panel code
#   $name         — Full condition name
#   $genes        — Key green-rated genes (illustrative; super-panels may have many more)
#   $inheritance  — Expected inheritance pattern(s)
#   $major_criteria — Named list; each criterion has:
#                     $description, $parameter (which input field), $value (matching value(s))
#   $supportive_criteria — Same structure
#   $hpo_relevant — HPO IDs relevant/supportive for this panel
#   $notes        — Free-text clinical notes
#   $panelapp_url — PanelApp panel page
# =============================================================================

renal_panels <- list(

  R193 = list(
    code        = "R193",
    name        = "Cystic renal disease",
    genes       = c("PKD1", "PKD2", "PKHD1", "HNF1B", "GANAB", "PRKCSH", "DNAJB11",
                    "FLCN", "VHL", "TSC1", "TSC2", "MUC1", "UMOD", "REN",
                    "BBS1", "BBS2", "BBS4", "BBS5", "BBS7", "BBS9", "BBS10", "BBS12",
                    "CEP290", "NPHP1", "INVS", "NPHP3", "NPHP4", "IQCB1", "SDCCAG8"),
    inheritance = c("Autosomal dominant", "Autosomal recessive"),
    major_criteria = list(
      bilateral_cysts = list(
        description = "Bilateral renal cysts on imaging (USS, CT or MRI)",
        parameter   = "hpo_terms",
        value       = c("HP:0000113", "HP:0005584")
      ),
      family_history = list(
        description = "First-degree family history of PKD or ESKD",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      )
    ),
    supportive_criteria = list(
      liver_cysts = list(
        description = "Hepatic cysts (polycystic liver disease)",
        parameter   = "extra_renal",
        value       = "Liver cysts"
      ),
      intracranial_aneurysm = list(
        description = "Intracranial aneurysm or aortic root dilatation",
        parameter   = "hpo_terms",
        value       = c("HP:0002616", "HP:0012518")
      ),
      early_hypertension = list(
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
      "HP:0000822",  # Hypertension
      "HP:0003774"   # End-stage renal disease
    ),
    notes       = "Super-panel covering ADPKD (PKD1 > PKD2, earlier/more severe disease), ARPKD (PKHD1, infantile onset with congenital hepatic fibrosis), HNF1B deletions (cysts + MODY5 diabetes — check glucose), and renal ciliopathies (nephronophthisis, Bardet-Biedl, Joubert). VHL and TSC1/2 cause syndromic cystic disease.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/487/"
  ),

  R194 = list(
    code        = "R194",
    name        = "Haematuria",
    genes       = c("COL4A1", "COL4A3", "COL4A4", "COL4A5", "MYH9"),
    inheritance = c("X-linked", "Autosomal recessive", "Autosomal dominant"),
    major_criteria = list(
      persistent_haematuria = list(
        description = "Persistent microscopic haematuria on ≥2 occasions (exclude UTI, stones, malignancy)",
        parameter   = "haematuria",
        value       = c("Microscopic", "Macroscopic")
      ),
      family_history = list(
        description = "Family history of haematuria, CKD, or Alport syndrome",
        parameter   = "family_history",
        value       = c("X-linked", "Autosomal recessive", "Autosomal dominant")
      )
    ),
    supportive_criteria = list(
      snhl = list(
        description = "Sensorineural hearing loss (bilateral, high-frequency, progressive)",
        parameter   = "extra_renal",
        value       = "Hearing loss"
      ),
      lenticonus = list(
        description = "Anterior lenticonus or macular flecks on ophthalmological examination",
        parameter   = "extra_renal",
        value       = "Ocular abnormality"
      ),
      egfr_decline = list(
        description = "Progressive CKD or declining eGFR",
        parameter   = "egfr",
        value       = "< 60"
      )
    ),
    hpo_relevant = c(
      "HP:0000790",  # Haematuria
      "HP:0000407",  # Sensorineural hearing loss
      "HP:0000504",  # Anterior lenticonus / visual abnormality
      "HP:0003774",  # End-stage renal disease
      "HP:0012622",  # Chronic kidney disease
      "HP:0000365"   # Hearing impairment
    ),
    notes       = "X-linked Alport (COL4A5) is most common — males progress to ESKD in 20s–30s; carrier females variable. Haematuria + SNHL + family history = high prior probability. Thin basement membrane nephropathy (COL4A3/4 heterozygous) is milder. MYH9 mutations (Epstein/Fechtner syndromes) cause macrothrombocytopenia with haematuria.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/99/"
  ),

  R195 = list(
    code        = "R195",
    name        = "Proteinuric renal disease",
    genes       = c("NPHS1", "NPHS2", "WT1", "LAMB2", "PLCE1", "INF2", "TRPC6",
                    "COQ2", "COQ6", "COQ8B", "CD2AP", "ACTN4", "MYH9", "LMX1B",
                    "NUP93", "NUP107", "NUP85", "NUP133", "OSGEP", "SMARCAL1",
                    "DGKE", "GLA", "SCARB2", "CUBN", "AMN", "LCAT", "APOE",
                    "PAX2", "COL4A3", "COL4A4", "COL4A5", "CRB2", "OCRL",
                    "SGPL1", "ARHGDIA", "PODXL", "MAGI2", "ITGA3", "LAMB2"),
    inheritance = c("Autosomal recessive", "Autosomal dominant", "X-linked"),
    major_criteria = list(
      proteinuria = list(
        description = "Nephrotic-range or persistent sub-nephrotic proteinuria (uPCR >100 mg/mmol)",
        parameter   = "proteinuria",
        value       = c("Nephrotic-range", "Sub-nephrotic")
      )
    ),
    supportive_criteria = list(
      age_onset = list(
        description = "Age at onset <30 years (congenital, infantile, or childhood onset increases yield)",
        parameter   = "age",
        value       = "< 30"
      ),
      family_history = list(
        description = "Family history of nephrotic syndrome or ESKD",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      ),
      consanguinity = list(
        description = "Consanguineous parents",
        parameter   = "consanguinity",
        value       = "Yes"
      ),
      steroid_resistance = list(
        description = "Steroid-resistant or steroid-dependent nephrotic syndrome",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    hpo_relevant = c(
      "HP:0000093",  # Proteinuria
      "HP:0000100",  # Nephrotic syndrome
      "HP:0000969",  # Oedema
      "HP:0012622",  # Chronic kidney disease
      "HP:0003774",  # End-stage renal disease
      "HP:0001944"   # Dehydration (from hypoalbuminaemia)
    ),
    notes       = "Broad panel for inherited causes of proteinuria. Congenital nephrotic syndrome (<3 months) is almost always monogenic — prioritise NPHS1 (Finnish type) and LAMB2 (Pierson syndrome). NPHS2 (podocin) is most common AR cause beyond infancy. COQ genes cause steroid-resistant NS with mitochondrial features. GLA (Fabry) should prompt alpha-galactosidase A assay.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/106/"
  ),

  R196 = list(
    code        = "R196",
    name        = "CFHR5 nephropathy",
    genes       = c("CFHR5"),
    inheritance = c("Autosomal dominant"),
    major_criteria = list(
      haematuria_proteinuria = list(
        description = "Persistent microscopic haematuria with or without proteinuria",
        parameter   = "haematuria",
        value       = c("Microscopic", "Macroscopic")
      ),
      biopsy = list(
        description = "Renal biopsy showing C3 glomerulopathy / MPGN pattern with dominant C3 deposition and CFHR5 on immunostaining",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      cypriot_ancestry = list(
        description = "Cypriot or eastern Mediterranean ancestry (founder duplication in CFHR5 in this population)",
        parameter   = "free_text",
        value       = NULL
      ),
      family_history = list(
        description = "Family history of haematuria, CKD, or ESKD",
        parameter   = "family_history",
        value       = "Autosomal dominant"
      ),
      low_c3 = list(
        description = "Low serum C3 or abnormal complement screen",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    hpo_relevant = c(
      "HP:0000790",  # Haematuria
      "HP:0000093",  # Proteinuria
      "HP:0012622",  # Chronic kidney disease
      "HP:0003774",  # End-stage renal disease
      "HP:0000100"   # Nephrotic syndrome
    ),
    notes       = "Caused by an internal duplication of exons 2–3 of CFHR5, first described in Cypriot families. Presents with synpharyngitic haematuria and MPGN-pattern nephritis with isolated C3 staining (C3 glomerulopathy). Males progress to ESKD in middle age; females milder. Complement pathway dysregulation distinct from CFH/CFI mutations.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/83/"
  ),

  R197 = list(
    code        = "R197",
    name        = "Membranoproliferative glomerulonephritis (MPGN) including C3 glomerulopathy",
    genes       = c("CFH", "CFI", "CFB", "C3", "CFHR1", "CFHR2", "CFHR5", "DGKE"),
    inheritance = c("Autosomal dominant", "Autosomal recessive"),
    major_criteria = list(
      mpgn_biopsy = list(
        description = "Renal biopsy showing MPGN pattern or C3 glomerulopathy (C3 glomerulonephritis or dense deposit disease)",
        parameter   = "hpo_terms",
        value       = "HP:0000100"
      ),
      complement_abnormality = list(
        description = "Low serum C3 or abnormal complement screen (low factor H/I, anti-CFH antibodies, C3 nephritic factor)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      family_history = list(
        description = "Family history of MPGN, C3 glomerulopathy, or aHUS",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      ),
      age_onset = list(
        description = "Onset in childhood or young adulthood",
        parameter   = "age",
        value       = "< 40"
      ),
      recurrent = list(
        description = "Recurrent disease post-transplant",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    hpo_relevant = c(
      "HP:0000100",  # Nephrotic syndrome
      "HP:0000093",  # Proteinuria
      "HP:0000790",  # Haematuria
      "HP:0012622",  # Chronic kidney disease
      "HP:0003774"   # End-stage renal disease
    ),
    notes       = "C3 glomerulopathy is defined by dominant C3 staining on immunofluorescence with absent/trace Ig. Causes: complement regulatory gene mutations (CFH, CFI, CFB, C3), CFHR deletions/rearrangements, anti-CFH autoantibodies, or C3 nephritic factor. Dense deposit disease has characteristic osmiophilic deposits on EM. Eculizumab used in refractory cases.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/83/"
  ),

  R198 = list(
    code        = "R198",
    name        = "Renal tubulopathies",
    genes       = c("SLC12A1", "KCNJ1", "CLCNKB", "BSND", "SLC12A3", "CLDN16", "CLDN19",
                    "ATP6V1B1", "ATP6V0A4", "SLC4A1", "CA2", "CASR", "GNA11",
                    "HNF1B", "HNF4A", "SLC2A2", "REN", "KCNJ10", "KCNJ16",
                    "TRPM6", "CNNM2", "SCNN1A", "SCNN1B", "SCNN1G", "NR3C2",
                    "CUL3", "KLHL3", "WNK4", "SLC34A1", "SLC34A3", "CYP24A1",
                    "AVPR2", "AQP2", "OCRL", "CTNS", "RRAGD", "MAGED2"),
    inheritance = c("Autosomal recessive", "Autosomal dominant", "X-linked"),
    major_criteria = list(
      electrolyte_abnormality = list(
        description = "Persistent unexplained electrolyte disturbance: hypokalaemia, hypomagnesaemia, hypercalciuria, hypophosphataemia, or metabolic alkalosis/acidosis",
        parameter   = "hpo_terms",
        value       = c("HP:0002900", "HP:0002150", "HP:0002148", "HP:0001942")
      ),
      tubular_dysfunction = list(
        description = "Biochemical evidence of tubular dysfunction (fractional electrolyte excretion inappropriately high, abnormal urine pH, low TmP/GFR)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      nephrocalcinosis = list(
        description = "Nephrocalcinosis or recurrent nephrolithiasis",
        parameter   = "hpo_terms",
        value       = c("HP:0000121", "HP:0000787")
      ),
      early_onset = list(
        description = "Onset in childhood or early adulthood",
        parameter   = "age",
        value       = "< 30"
      ),
      family_history = list(
        description = "Family history of electrolyte disorder, renal stones, or CKD",
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
      "HP:0002153"   # Hyperkalaemia (distal RTA / pseudohypoaldosteronism)
    ),
    notes       = "Bartter syndrome (SLC12A1/KCNJ1/CLCNKB/BSND/CLDN16/19): salt-wasting, hypokalaemia, alkalosis, hypercalciuria. Gitelman (SLC12A3): milder, hypomagnesaemia, hypocalciuria. Distal RTA (ATP6V genes/CA2): nephrocalcinosis, alkaline urine. CASR/GNA11 mutations cause hypercalcaemia or hypocalcaemia. MAGED2 causes antenatal Bartter. CYP24A1 mutations cause hypercalcaemia/nephrocalcinosis.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/292/"
  ),

  R199 = list(
    code        = "R199",
    name        = "Steroid-resistant nephrotic syndrome (SRNS) / focal segmental glomerulosclerosis (FSGS)",
    genes       = c("NPHS1", "NPHS2", "WT1", "LAMB2", "PLCE1", "INF2", "TRPC6",
                    "COQ2", "COQ6", "COQ8B", "CD2AP", "ACTN4", "MYH9", "LMX1B",
                    "NUP93", "NUP107", "NUP85", "NUP133", "OSGEP", "SMARCAL1",
                    "DGKE", "CRB2", "ARHGDIA", "ADCK4"),
    inheritance = c("Autosomal recessive", "Autosomal dominant"),
    major_criteria = list(
      nephrotic_proteinuria = list(
        description = "Nephrotic-range proteinuria (uPCR >300 mg/mmol or urine protein >3.5 g/24h)",
        parameter   = "proteinuria",
        value       = "Nephrotic-range"
      ),
      steroid_resistance = list(
        description = "Failure to achieve complete remission after ≥8 weeks of adequate corticosteroid therapy",
        parameter   = "free_text",
        value       = NULL
      ),
      biopsy_fsgs = list(
        description = "Biopsy showing FSGS, minimal change disease, or diffuse mesangial sclerosis",
        parameter   = "hpo_terms",
        value       = c("HP:0000100", "HP:0012622")
      )
    ),
    supportive_criteria = list(
      age_onset = list(
        description = "Age at onset <25 years (congenital or infantile onset especially high yield)",
        parameter   = "age",
        value       = "< 25"
      ),
      family_history = list(
        description = "Family history of nephrotic syndrome or ESKD",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      ),
      consanguinity = list(
        description = "Consanguineous parents",
        parameter   = "consanguinity",
        value       = "Yes"
      )
    ),
    hpo_relevant = c(
      "HP:0000100",  # Nephrotic syndrome
      "HP:0000093",  # Proteinuria
      "HP:0000969",  # Oedema
      "HP:0003774",  # End-stage renal disease
      "HP:0012622",  # Chronic kidney disease
      "HP:0001944"   # Dehydration
    ),
    notes       = "Congenital NS (<3 months) is almost always genetic — NPHS1 or LAMB2 most likely. NPHS2 (podocin) is the most common AR cause in older children; p.R229Q is a hypomorphic allele. WT1 mutations cause Denys-Drash (ambiguous genitalia, Wilms tumour risk) and Frasier syndrome (gonadoblastoma risk in 46XY). COQ gene mutations cause NS with mitochondrial features — trial CoQ10. NUP mutations characteristically resistant to all immunosuppression.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/1077/"
  ),

  R201 = list(
    code        = "R201",
    name        = "Atypical haemolytic uraemic syndrome (aHUS)",
    genes       = c("CFH", "CFI", "CFB", "C3", "CD46", "CFHR1", "CFHR3", "DGKE", "MMACHC"),
    inheritance = c("Autosomal dominant", "Autosomal recessive"),
    major_criteria = list(
      microangiopathic_haemolysis = list(
        description = "Microangiopathic haemolytic anaemia (low Hb, elevated LDH, low haptoglobin, schistocytes on film)",
        parameter   = "hpo_terms",
        value       = c("HP:0001903", "HP:0001878")
      ),
      thrombocytopenia = list(
        description = "Thrombocytopenia (platelets <150 × 10⁹/L)",
        parameter   = "hpo_terms",
        value       = "HP:0001873"
      ),
      aki = list(
        description = "Acute kidney injury — often severe, may require dialysis",
        parameter   = "hpo_terms",
        value       = "HP:0001919"
      ),
      atypical = list(
        description = "Atypical — STEC/Shiga toxin excluded; ADAMTS13 activity ≥10% (excludes TTP)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      complement_screen = list(
        description = "Abnormal complement screen (low C3, low factor H or I, anti-CFH antibodies)",
        parameter   = "free_text",
        value       = NULL
      ),
      recurrent = list(
        description = "Recurrent or relapsing TMA episodes",
        parameter   = "free_text",
        value       = NULL
      ),
      family_history = list(
        description = "Family history of HUS or TMA",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
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
    notes       = "Complement pathway mutations account for ~60% of aHUS: CFH most common (~25%), then CD46, CFI, C3, CFB. Anti-CFH antibodies (associated with CFHR1/3 deletion) require immunosuppression. DGKE mutations cause childhood aHUS through non-complement mechanism. MMACHC (cblC defect) causes aHUS with methylmalonic aciduria — check plasma amino acids and urine organic acids. Eculizumab/ravulizumab are licensed; genetic result guides duration.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/139/"
  ),

  R202 = list(
    code        = "R202",
    name        = "Tubulointerstitial kidney disease (TIKD)",
    genes       = c("UMOD", "MUC1", "REN", "HNF1B", "NPHP1", "NPHP3", "NPHP4",
                    "ANKS6", "CEP164", "CEP83", "DNAJB11", "GATM", "INVS",
                    "MAPKBP1", "SEC61A1", "TMEM67", "TTC21B", "WDR19", "XPNPEP3"),
    inheritance = c("Autosomal dominant", "Autosomal recessive"),
    major_criteria = list(
      ckd_no_cause = list(
        description = "CKD (eGFR <60 ml/min/1.73m²) without clear glomerular or obstructive cause",
        parameter   = "egfr",
        value       = "< 60"
      ),
      tubulointerstitial_biopsy = list(
        description = "Biopsy showing tubulointerstitial fibrosis and tubular atrophy without prominent glomerular disease",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      hyperuricaemia = list(
        description = "Gout or hyperuricaemia disproportionate to renal function (UMOD, REN mutations)",
        parameter   = "free_text",
        value       = NULL
      ),
      anaemia = list(
        description = "Anaemia out of proportion to degree of CKD",
        parameter   = "free_text",
        value       = NULL
      ),
      family_history = list(
        description = "Family history of CKD or ESKD (often autosomal dominant in UMOD/MUC1)",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      ),
      age_ckd = list(
        description = "CKD presenting before age 50",
        parameter   = "age",
        value       = "< 50"
      )
    ),
    hpo_relevant = c(
      "HP:0012622",  # Chronic kidney disease
      "HP:0003774",  # End-stage renal disease
      "HP:0000822",  # Hypertension
      "HP:0001903",  # Anaemia
      "HP:0001907"   # Thromboembolism (REN mutations cause renovascular hypertension)
    ),
    notes       = "Formerly termed medullary cystic kidney disease (MCKD). UMOD (uromodulin) mutations cause hyperuricaemia and gout early — trial allopurinol. MUC1 mutations are detected by a dedicated sequencing assay (VNTR region). REN mutations cause hyperkalaemia and anaemia from low renin. NPHP genes (nephronophthisis) cause AR TIKD with small kidneys and medullary cysts — childhood onset. DNAJB11 causes ADPKD-like disease with tubular cysts.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/548/"
  ),

  R204 = list(
    code        = "R204",
    name        = "Hereditary systemic amyloidosis",
    genes       = c("TTR", "APOA1", "APOA2", "APOC2", "FGA", "GSN", "LYZ"),
    inheritance = c("Autosomal dominant"),
    major_criteria = list(
      biopsy_amyloid = list(
        description = "Biopsy-proven amyloid deposits (Congo red positive) in kidney or other organ",
        parameter   = "free_text",
        value       = NULL
      ),
      family_history = list(
        description = "Family history of amyloidosis, CKD, neuropathy, or cardiomyopathy",
        parameter   = "family_history",
        value       = "Autosomal dominant"
      )
    ),
    supportive_criteria = list(
      proteinuria = list(
        description = "Nephrotic-range or sub-nephrotic proteinuria",
        parameter   = "proteinuria",
        value       = c("Nephrotic-range", "Sub-nephrotic")
      ),
      extra_renal = list(
        description = "Cardiomyopathy, peripheral neuropathy, or autonomic neuropathy",
        parameter   = "extra_renal",
        value       = c("Cardiac disease", "Peripheral neuropathy")
      ),
      age_onset = list(
        description = "Onset typically in 4th–6th decade",
        parameter   = "age",
        value       = "< 70"
      )
    ),
    hpo_relevant = c(
      "HP:0000093",  # Proteinuria
      "HP:0012622",  # Chronic kidney disease
      "HP:0003774",  # End-stage renal disease
      "HP:0001638",  # Cardiomyopathy
      "HP:0001271",  # Peripheral neuropathy
      "HP:0000407"   # Sensorineural hearing loss (gelsolin/GSN type)
    ),
    notes       = "TTR amyloidosis (ATTR) is most common — Val122Ile prevalent in Afro-Caribbean patients (cardiomyopathy dominant); Val30Met is the classic neuropathic form. Tafamidis and inotersen/patisiran are licensed for ATTR. APOA1/LYZ/GSN/FGA cause renal-predominant amyloidosis. Serum amyloid P (SAP) scan useful for extent of disease. Distinguish from AL amyloidosis (immunoglobulin light chain — not genetic panel).",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/502/"
  ),

  R256 = list(
    code        = "R256",
    name        = "Nephrocalcinosis or nephrolithiasis",
    genes       = c("AGXT", "GRHPR", "HOGA1", "SLC3A1", "SLC7A9", "OCRL", "CLCN5",
                    "CASR", "CYP24A1", "SLC34A1", "SLC34A3", "ATP6V1B1", "ATP6V0A4",
                    "SLC12A1", "KCNJ1", "CLCNKB", "CLDN16", "CLDN19", "HNF4A",
                    "APRT", "HPRT1", "XDH", "MOCOS", "FAM20A", "PHEX",
                    "SLC4A1", "CA2", "RRAGD", "VIPAS39", "VPS33B", "WDR72", "STRADA"),
    inheritance = c("Autosomal recessive", "Autosomal dominant", "X-linked"),
    major_criteria = list(
      nephrocalcinosis = list(
        description = "Nephrocalcinosis on imaging (medullary or cortical calcium deposition)",
        parameter   = "hpo_terms",
        value       = "HP:0000121"
      ),
      recurrent_stones = list(
        description = "Recurrent nephrolithiasis (≥2 episodes, or stone composition suggesting metabolic cause: oxalate, urate, cystine, 2,8-dihydroxyadenine)",
        parameter   = "hpo_terms",
        value       = "HP:0000787"
      )
    ),
    supportive_criteria = list(
      metabolic_abnormality = list(
        description = "Hypercalciuria, hyperoxaluria, hypocitraturia, hyperuricosuria, or cystinuria on 24h urine collection",
        parameter   = "hpo_terms",
        value       = c("HP:0002150", "HP:0003159", "HP:0010934")
      ),
      early_onset = list(
        description = "First stone or nephrocalcinosis before age 25",
        parameter   = "age",
        value       = "< 25"
      ),
      family_history = list(
        description = "Family history of renal stones or nephrocalcinosis",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive")
      )
    ),
    hpo_relevant = c(
      "HP:0000121",  # Nephrocalcinosis
      "HP:0000787",  # Nephrolithiasis
      "HP:0002150",  # Hypercalciuria
      "HP:0003159",  # Hyperoxaluria
      "HP:0010934",  # Hyperuricosuria
      "HP:0012622",  # CKD
      "HP:0003774"   # ESKD
    ),
    notes       = "Primary hyperoxaluria (AGXT/GRHPR/HOGA1) presents with recurrent calcium oxalate stones and nephrocalcinosis — combined liver-kidney transplant curative for PH1. Cystinuria (SLC3A1/SLC7A9) causes large staghorn calculi — alkalinise urine, tiopronin. Dent disease (CLCN5/OCRL) is X-linked with LMW proteinuria, hypercalciuria, nephrocalcinosis, and Fanconi syndrome. CASR activating mutations cause hypercalciuria. CYP24A1 mutations cause hypercalcaemia/hypercalciuria from vitamin D excess.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/149/"
  ),

  R257 = list(
    code        = "R257",
    name        = "Unexplained young-onset end-stage renal disease",
    genes       = c("COL4A3", "COL4A4", "COL4A5", "PKD1", "PKD2", "PKHD1",
                    "UMOD", "MUC1", "REN", "HNF1B", "NPHP1", "NPHP3", "NPHP4",
                    "NPHS1", "NPHS2", "WT1", "PLCE1", "INF2", "TRPC6",
                    "CFH", "CFI", "C3", "CD46", "DGKE",
                    "AGXT", "SLC3A1", "SLC7A9", "OCRL", "CLCN5",
                    "GLA", "TTR", "ACE", "AGT", "AGTR1",
                    "PAX2", "EYA1", "GATA3", "SALL1",
                    "TSC1", "TSC2", "VHL", "FLCN",
                    "MMACHC", "PMM2"),
    inheritance = c("Autosomal dominant", "Autosomal recessive", "X-linked"),
    major_criteria = list(
      young_eskd = list(
        description = "ESKD or eGFR <30 ml/min/1.73m² before age 50 without clear acquired cause",
        parameter   = "egfr",
        value       = "< 30"
      ),
      no_acquired_cause = list(
        description = "Standard workup has not identified diabetic nephropathy, chronic obstruction, or vasculitis as the primary cause",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    supportive_criteria = list(
      family_history = list(
        description = "Family history of CKD or ESKD in first- or second-degree relative",
        parameter   = "family_history",
        value       = c("Autosomal dominant", "Autosomal recessive", "X-linked")
      ),
      extra_renal = list(
        description = "Extra-renal features suggesting syndromic diagnosis (hearing loss, ocular abnormality, hepatic fibrosis, skeletal, neurological)",
        parameter   = "extra_renal",
        value       = c("Hearing loss", "Ocular abnormality", "Liver cysts", "Skeletal abnormality", "Cognitive impairment")
      ),
      small_kidneys = list(
        description = "Small echogenic kidneys on USS (suggests chronic interstitial disease or hereditary nephritis)",
        parameter   = "free_text",
        value       = NULL
      )
    ),
    hpo_relevant = c(
      "HP:0003774",  # End-stage renal disease
      "HP:0012622",  # Chronic kidney disease
      "HP:0000093",  # Proteinuria
      "HP:0000790",  # Haematuria
      "HP:0000407",  # Sensorineural hearing loss
      "HP:0001395",  # Hepatic fibrosis
      "HP:0000478"   # Abnormality of the eye
    ),
    notes       = "Virtual super-panel used when a specific diagnosis has not been reached through targeted testing (R193–R202) but genetic aetiology is suspected. Contains genes from all major inherited renal disease categories. Genome-wide sequencing (WGS) is often used for this indication. Collagen IV nephropathy (Alport) and ADPKD account for a large proportion of treatable diagnoses found.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/678/"
  ),

  R446 = list(
    code        = "R446",
    name        = "APOL1-associated nephropathy",
    genes       = c("APOL1"),
    inheritance = c("Autosomal recessive (risk genotype)"),
    major_criteria = list(
      high_risk_genotype = list(
        description = "APOL1 high-risk genotype: two copies of G1 (p.S342G/I384M) or G2 (del388-389) risk alleles (G1/G1, G2/G2, or G1/G2)",
        parameter   = "free_text",
        value       = NULL
      ),
      fsgs_or_collapsing = list(
        description = "Biopsy showing FSGS (any variant) or collapsing nephropathy",
        parameter   = "hpo_terms",
        value       = c("HP:0000093", "HP:0012622")
      )
    ),
    supportive_criteria = list(
      african_ancestry = list(
        description = "West African or Afro-Caribbean ancestry (G1/G2 alleles at high frequency in this population)",
        parameter   = "free_text",
        value       = NULL
      ),
      rapid_ckd_progression = list(
        description = "Rapid progression to ESKD without clear alternative cause (hypertensive FSGS, HIV nephropathy, other 'second hit')",
        parameter   = "free_text",
        value       = NULL
      ),
      proteinuria = list(
        description = "Nephrotic or sub-nephrotic proteinuria",
        parameter   = "proteinuria",
        value       = c("Nephrotic-range", "Sub-nephrotic")
      )
    ),
    hpo_relevant = c(
      "HP:0000093",  # Proteinuria
      "HP:0012622",  # Chronic kidney disease
      "HP:0003774",  # End-stage renal disease
      "HP:0000100"   # Nephrotic syndrome
    ),
    notes       = "APOL1 G1 and G2 variants are West African founder alleles that protect against Trypanosoma brucei rhodesiense but confer ~10-fold increased risk of FSGS and collapsing nephropathy in homozygous/compound heterozygous carriers. Penetrance is incomplete — a 'second hit' (infection, interferon, medication) is usually required. Accounts for a large proportion of ESKD disparity between African-ancestry and European-ancestry populations. Not a classical Mendelian disorder; testing is for risk stratification rather than diagnosis.",
    panelapp_url = "https://panelapp.genomicsengland.co.uk/panels/"
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
