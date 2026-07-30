# =============================================================================
# data/variant_interp.R
# Parameters for the Variant Interpretation Module
#
# For each condition group:
#   - genes:            all R257 green genes mapping to this condition
#   - label:            display name
#   - inheritance:      primary inheritance pattern
#   - zygosity_options: which zygosity inputs are relevant
#   - prior:            P(variant causative | P/LP classified, zygosity)
#                       before phenotype evidence is applied.
#                       Bakes in: lab classification accuracy, penetrance,
#                       and baseline phenotype-gene concordance.
#   - features:         list of discriminating phenotypic features with LRs
#   - flags:            clinical uncertainties flagged for expert review
#   - references:       key literature
#
# LR conventions:
#   lr_present  — applied when feature IS present
#   lr_absent   — applied when feature is explicitly ABSENT (key features only)
#   key = TRUE  — absence of this feature updates posterior
#
# UNCERTAIN: comments mark parameters that need clinical review
# =============================================================================

variant_conditions <- list(

  # ---------------------------------------------------------------------------
  # 1. ADPKD
  # ---------------------------------------------------------------------------
  ADPKD = list(
    label     = "Autosomal dominant polycystic kidney disease (ADPKD)",
    genes     = c("PKD1", "PKD2", "ALG5", "ALG8", "ALG9", "GANAB",
                  "DNAJB11", "PRKCSH", "SEC63", "IFT140"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.88   # High penetrance; nearly all PKD1/2 carriers have cysts by 40
                            # UNCERTAIN: ALG5/8/9/GANAB have lower penetrance for kidney cysts
                            # vs liver cysts — pooled prior may be too high for these genes
    ),
    features = list(
      list(id="bilateral_cysts",    label="Bilateral renal cysts on imaging",
           lr_present=25.0, lr_absent=0.04, key=TRUE,
           caveat="In patients <20 yrs absent cysts may not exclude — consider age"),
      list(id="family_hx_pkd",     label="Family history of cystic kidney disease (AD pattern)",
           lr_present=6.0,  lr_absent=0.7,  key=FALSE),
      list(id="liver_cysts",        label="Hepatic cysts",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="enlarged_kidneys",   label="Enlarged kidneys on imaging",
           lr_present=12.0, lr_absent=0.5,  key=FALSE),
      list(id="intracranial_aneurysm", label="Intracranial aneurysm (incidental or symptomatic)",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "ALG5/8/9 primarily cause polycystic LIVER disease; kidney cysts less penetrant — prior of 0.88 may overestimate for these genes",
      "DNAJB11 causes atypical ADPKD with smaller cysts and earlier fibrosis — bilateral cysts may be subtle",
      "Young patients (<20 yrs) may not yet have Ravine/Pei criteria-meeting cysts even with PKD1; age caveat applies"
    ),
    references = c(
      "Cornec-Le Gall E et al. Lancet 2019;393:919-935",
      "Pei Y et al. JASN 2009;20:205-212"
    )
  ),

  # ---------------------------------------------------------------------------
  # 2. ARPKD
  # ---------------------------------------------------------------------------
  ARPKD = list(
    label     = "Autosomal recessive polycystic kidney disease (ARPKD)",
    genes     = c("PKHD1"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.90,  # High penetrance; neonatal/childhood presentation typical
      Heterozygous = 0.02   # Carriers essentially unaffected
    ),
    features = list(
      list(id="childhood_onset",      label="Onset in childhood or neonatal period",
           lr_present=20.0, lr_absent=0.05, key=TRUE,
           caveat="Adult presentation of ARPKD is rare; if adult with no prior renal history, reconsider"),
      list(id="echogenic_kidneys",    label="Enlarged echogenic kidneys (neonatal/childhood imaging)",
           lr_present=15.0, lr_absent=0.2,  key=TRUE),
      list(id="hepatic_fibrosis",     label="Congenital hepatic fibrosis or portal hypertension",
           lr_present=15.0, lr_absent=0.3,  key=FALSE),
      list(id="oligohydramnios",      label="Oligohydramnios or pulmonary hypoplasia (antenatal/neonatal)",
           lr_present=12.0, lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Adult presentation of ARPKD is well-documented but rare — a single het PKHD1 variant in an adult with ESKD is almost certainly not causative",
      "PKHD1 has many VUS; ensure variant is robustly classified P/LP before applying this tool"
    ),
    references = c(
      "Bergmann C et al. Nat Rev Dis Primers 2018;4:18035"
    )
  ),

  # ---------------------------------------------------------------------------
  # 3. Nephronophthisis
  # ---------------------------------------------------------------------------
  Nephronophthisis = list(
    label     = "Nephronophthisis / ciliopathy",
    genes     = c("NPHP1", "NPHP3", "NPHP4", "ANKS6", "CEP83", "CEP164",
                  "SDCCAG8", "TRAF3IP1", "NEK8", "GLIS2", "TBC1D8B",
                  "MAPKBP1", "XPNPEP3", "WDR73", "LAGE3", "GON7",
                  "TP53RK", "TPRKB", "PSKH1", "DYNC2H1"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.80,
      Heterozygous = 0.03
    ),
    features = list(
      list(id="juvenile_ckd",         label="CKD or ESKD presenting in childhood or adolescence (<20 yrs)",
           lr_present=15.0, lr_absent=0.1,  key=TRUE),
      list(id="bland_urinalysis",     label="Bland urinalysis (no or minimal haematuria/proteinuria)",
           lr_present=5.0,  lr_absent=0.5,  key=FALSE,
           caveat="NPHP characteristically has bland urinalysis — its presence supports the diagnosis"),
      list(id="small_kidneys",        label="Normal or small kidneys on imaging (not enlarged)",
           lr_present=6.0,  lr_absent=0.4,  key=FALSE),
      list(id="retinal_dystrophy",    label="Retinal dystrophy or visual impairment (Senior-Loken syndrome)",
           lr_present=6.0,  lr_absent=NULL, key=FALSE),
      list(id="liver_fibrosis_nphp",  label="Hepatic fibrosis",
           lr_present=4.0,  lr_absent=NULL, key=FALSE),
      list(id="echogenic_loss_cmd",   label="Loss of corticomedullary differentiation on renal ultrasound",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Penetrance varies significantly between NPHP genes — NPHP1 deletion is very high penetrance; many other genes (e.g. MAPKBP1, GON7, TPRKB) are based on very limited case series",
      "Digenic/oligogenic inheritance is described in ciliopathies — a single biallelic hit may not be sufficient for all genes",
      "Adult-onset NPHP is recognised (NPHP3, ANKS6) but median ESKD in most forms is <30 yrs"
    ),
    references = c(
      "Braun DA, Hildebrandt F. Clin J Am Soc Nephrol 2017;12:674-685"
    )
  ),

  # ---------------------------------------------------------------------------
  # 4. Bardet-Biedl syndrome
  # ---------------------------------------------------------------------------
  BardetBiedl = list(
    label     = "Bardet-Biedl syndrome",
    genes     = c("BBS1", "BBS2", "BBS4", "BBS5", "BBS7", "BBS9",
                  "BBS10", "BBS12", "ARL6", "MKKS", "LZTFL1", "TTC8",
                  "WDPCP", "SDCCAG8"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.85,
      Heterozygous = 0.03
    ),
    features = list(
      list(id="retinal_dystrophy_bbs", label="Pigmentary retinopathy / retinal dystrophy",
           lr_present=15.0, lr_absent=0.08, key=TRUE,
           caveat="Present in >90% of BBS — absence strongly argues against"),
      list(id="obesity_bbs",           label="Truncal obesity",
           lr_present=10.0, lr_absent=0.15, key=TRUE),
      list(id="polydactyly",           label="Post-axial polydactyly (history or examination)",
           lr_present=12.0, lr_absent=0.4,  key=FALSE),
      list(id="learning_difficulties", label="Intellectual disability or learning difficulties",
           lr_present=6.0,  lr_absent=0.5,  key=FALSE),
      list(id="hypogonadism",          label="Hypogonadism",
           lr_present=5.0,  lr_absent=NULL, key=FALSE),
      list(id="renal_anomaly_bbs",     label="Renal structural anomaly or cysts",
           lr_present=4.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Isolated renal disease without other BBS features should prompt reconsideration — BBS is a multisystem diagnosis",
      "SDCCAG8 is shared with nephronophthisis gene list — consider both"
    ),
    references = c(
      "Forsythe E, Beales PL. Eur J Hum Genet 2013;21:8-13"
    )
  ),

  # ---------------------------------------------------------------------------
  # 5. Joubert syndrome
  # ---------------------------------------------------------------------------
  JoubertSyndrome = list(
    label     = "Joubert syndrome",
    genes     = c("AHI1", "ARL13B", "INPP5E", "ARMC9", "CEP290", "CC2D2A",
                  "CEP41", "CEP104", "B9D2", "C5orf42", "KIAA0586", "KIAA0753",
                  "CSPP1", "RPGRIP1L", "TCTN1", "TCTN2", "TCTN3", "TMEM67",
                  "TMEM107", "TMEM138", "TMEM216", "TMEM231", "TMEM237",
                  "TXNDC15", "DDX59", "HYLS1", "KIF7", "MKS1", "CENPF",
                  "ICK", "IFT172", "TULP3"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.82,
      Heterozygous = 0.03
    ),
    features = list(
      list(id="molar_tooth_sign",    label="Molar tooth sign on brain MRI (cerebellar vermis hypoplasia)",
           lr_present=30.0, lr_absent=0.05, key=TRUE,
           caveat="Near-pathognomonic when present; absence makes Joubert very unlikely"),
      list(id="developmental_delay", label="Intellectual disability or developmental delay",
           lr_present=8.0,  lr_absent=0.2,  key=FALSE),
      list(id="ataxia_hypotonia",    label="Ataxia or neonatal hypotonia",
           lr_present=8.0,  lr_absent=0.3,  key=FALSE),
      list(id="retinal_dystrophy_js",label="Retinal dystrophy",
           lr_present=5.0,  lr_absent=NULL, key=FALSE),
      list(id="renal_cysts_js",      label="Renal cysts or nephronophthisis",
           lr_present=4.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Joubert syndrome presenting to a nephrology service without prior neurology diagnosis is unusual — if MRI has not been done, this should be arranged",
      "Many Joubert genes also appear in nephronophthisis/MKS panels — variant in CEP290, RPGRIP1L etc. may cause nephronophthisis without brain malformation"
    ),
    references = c(
      "Romani M et al. Nat Rev Dis Primers 2013;1:13001"
    )
  ),

  # ---------------------------------------------------------------------------
  # 6. Alport — X-linked (COL4A5)
  # ---------------------------------------------------------------------------
  AlportXL = list(
    label     = "Alport syndrome — X-linked (COL4A5)",
    genes     = c("COL4A5"),
    inheritance      = "XL",
    zygosity_options = c("Hemizygous_male", "Heterozygous_female"),
    prior = c(
      Hemizygous_male     = 0.92,  # Near-complete penetrance for haematuria; ESKD in ~90% males by 40
      Heterozygous_female = 0.60   # Variable penetrance; haematuria in ~95% but ESKD in ~15-30%
                                   # UNCERTAIN: exact ESKD penetrance in females varies widely by study
    ),
    features = list(
      list(id="haematuria_alport",   label="Microscopic or macroscopic haematuria",
           lr_present=20.0, lr_absent=0.05, key=TRUE,
           caveat="Haematuria is universal in hemizygous males — absence should prompt variant re-review"),
      list(id="hearing_loss_alport", label="Sensorineural hearing loss",
           lr_present=15.0, lr_absent=0.4,  key=FALSE,
           caveat="Hearing loss in 80% of males; less common and later in females"),
      list(id="ocular_alport",       label="Anterior lenticonus or macular flecks",
           lr_present=20.0, lr_absent=0.6,  key=FALSE),
      list(id="gbm_em",              label="GBM thickening/splitting/thinning on EM biopsy",
           lr_present=20.0, lr_absent=0.15, key=FALSE),
      list(id="family_hx_alport",    label="Family history of haematuria, renal failure, or deafness (X-linked pattern)",
           lr_present=10.0, lr_absent=0.5,  key=FALSE),
      list(id="ckd_alport",          label="CKD or ESKD",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "COL4A5 truncating variants are generally higher penetrance than missense in males",
      "Heterozygous female penetrance for ESKD is highly variable (15-80% in different cohorts depending on ascertainment)"
    ),
    references = c(
      "Savige J et al. Kidney Int 2022;101:717-729",
      "Jais JP et al. JASN 2003;14:2603-2610"
    )
  ),

  # ---------------------------------------------------------------------------
  # 7. Alport — biallelic (COL4A3/COL4A4)
  # ---------------------------------------------------------------------------
  AlportAR = list(
    label     = "Alport syndrome — biallelic (COL4A3/COL4A4)",
    genes     = c("COL4A3", "COL4A4"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic"),
    prior = c(
      Biallelic = 0.90
    ),
    features = list(
      list(id="haematuria_ar",    label="Microscopic or macroscopic haematuria",
           lr_present=20.0, lr_absent=0.05, key=TRUE),
      list(id="hearing_loss_ar",  label="Sensorineural hearing loss",
           lr_present=12.0, lr_absent=0.4,  key=FALSE),
      list(id="ocular_ar",        label="Anterior lenticonus or macular flecks",
           lr_present=8.0,  lr_absent=0.7,  key=FALSE),
      list(id="consanguinity_ar", label="Consanguinity",
           lr_present=5.0,  lr_absent=NULL, key=FALSE),
      list(id="ar_family_hx",     label="Family history consistent with AR pattern",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="proteinuria_ar",   label="Proteinuria",
           lr_present=5.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "COL4A3/4 compound heterozygous: confirm both variants are in trans (not cis) — requires parental testing or phasing"
    ),
    references = c(
      "Savige J et al. Kidney Int 2022;101:717-729"
    )
  ),

  # ---------------------------------------------------------------------------
  # 8. COL4 heterozygote (COL4A3/COL4A4 monoallelic)
  # ---------------------------------------------------------------------------
  COL4het = list(
    label     = "COL4 heterozygote (COL4A3/COL4A4 — monoallelic)",
    genes     = c("COL4A3", "COL4A4"),
    inheritance      = "AD_het",
    zygosity_options = c("Heterozygous"),
    prior = c(
      # Changed 2026-07-30: was 0.40 (~haematuria penetrance). Recalibrated to
      # 0.03, the population-based (non-hospital-biased) ESKF-by-age-60
      # penetrance estimate (Savige et al. KIR 2022, PMID 36090501), to align
      # with the same ESKD-causation framing used for the sibling COL4_het
      # prior in data/bayes_params.R. Note this is a stricter endpoint than
      # "any clinically apparent phenotype" — if the presenting question is
      # isolated haematuria rather than progressive CKD/ESKD, 0.40 may be the
      # more appropriate baseline; the per-feature LRs below (haematuria, GBM
      # thinning, eGFR) still do most of the case-specific adjustment either way.
      Heterozygous = 0.03
    ),
    features = list(
      # lr_absent strengthened 0.25 -> 0.1 (4x -> 10x reduction if absent),
      # matching the bayes_params.R change: haematuria is a near-universal
      # cardinal feature of symptomatic carriers, so its absence should be
      # about as specific against causation as it is for Alport_XL/AR.
      list(id="haematuria_col4het",  label="Microscopic haematuria",
           lr_present=15.0, lr_absent=0.1, key=TRUE),
      list(id="no_hearing_loss",     label="Absence of hearing loss",
           lr_present=2.0,  lr_absent=NULL, key=FALSE,
           caveat="Hearing loss is uncommon in COL4 hets — its presence should prompt reconsideration of biallelic disease or X-linked Alport"),
      list(id="family_hx_haem",      label="Family history of isolated haematuria",
           lr_present=6.0,  lr_absent=0.5,  key=FALSE),
      list(id="thinned_gbm",         label="Diffusely thinned GBM on EM biopsy (thin basement membrane nephropathy)",
           lr_present=12.0, lr_absent=0.3,  key=FALSE),
      list(id="low_eskd_risk",       label="Normal or near-normal eGFR",
           lr_present=2.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Prior of 0.03 reflects population-based ESKD-by-60 penetrance (Savige KI Rep 2022) — if the clinical question is whether this variant explains isolated haematuria rather than progressive CKD/ESKD, a higher prior (~0.40, haematuria penetrance) may be more appropriate for that framing",
      "Hearing loss and ocular features occur uncommonly if at all — their presence should prompt consideration of biallelic disease (Savige KI Rep 2022)",
      "The distinction between COL4_het as incidental finding vs true cause of isolated haematuria is often academic — management is similar (monitoring)"
    ),
    references = c(
      "Gibson J et al. JASN 2021;32:2273-2290",
      "Savige J. Kidney Int Rep 2022;7:2254-2263"
    )
  ),

  # ---------------------------------------------------------------------------
  # 9. COL4A1 disease
  # ---------------------------------------------------------------------------
  COL4A1disease = list(
    label     = "COL4A1-related disease",
    genes     = c("COL4A1"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.72   # UNCERTAIN: penetrance data limited; expressivity highly variable
    ),
    features = list(
      list(id="haematuria_col4a1",      label="Haematuria",
           lr_present=8.0,  lr_absent=0.4,  key=FALSE),
      list(id="exophytic_renal_cysts",  label="Exophytic or parapelvic renal cysts",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="cerebrovascular",        label="Cerebrovascular disease or intracranial aneurysm",
           lr_present=10.0, lr_absent=NULL, key=FALSE),
      list(id="muscle_cramps_ck",       label="Muscle cramps or elevated CK",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="raynauds",               label="Raynaud phenomenon",
           lr_present=5.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "COL4A1 penetrance and expressivity are highly variable — same variant in a family can cause anything from asymptomatic to severe porencephaly",
      "Prior of 0.72 is uncertain — limited large natural history studies",
      "Renal manifestations alone (haematuria, exophytic cysts) may be mild and discovered incidentally on broad panels"
    ),
    references = c(
      "Plaisier E et al. JASN 2007;18:2272-2281"
    )
  ),

  # ---------------------------------------------------------------------------
  # 10. Congenital nephrotic syndrome / AR FSGS
  # ---------------------------------------------------------------------------
  CongenitalNephroticAR = list(
    label     = "Congenital nephrotic syndrome / AR FSGS (NPHS1, NPHS2, LAMB2, ARHGDIA)",
    genes     = c("NPHS1", "NPHS2", "LAMB2", "ARHGDIA", "CD2AP", "AMN",
                  "CUBN", "ITGA3", "CD151"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.85,
      Heterozygous = 0.04   # Single het in AR gene rarely causative
                            # UNCERTAIN: NPHS2 p.R229Q (mild variant) in compound het context
                            # is a specific exception — not captured here
    ),
    features = list(
      list(id="nephrotic_syndrome",   label="Nephrotic syndrome (heavy proteinuria, hypoalbuminaemia, oedema)",
           lr_present=25.0, lr_absent=0.04, key=TRUE),
      list(id="childhood_onset_ns",   label="Onset in infancy or childhood (<10 years)",
           lr_present=15.0, lr_absent=0.15, key=FALSE,
           caveat="NPHS1 = congenital (first weeks of life); NPHS2 = childhood peak 3-8 yrs"),
      list(id="steroid_resistant",    label="Steroid-resistant nephrotic syndrome",
           lr_present=12.0, lr_absent=0.1,  key=FALSE),
      list(id="fsgs_dms_biopsy",      label="FSGS or diffuse mesangial sclerosis on biopsy",
           lr_present=10.0, lr_absent=0.2,  key=FALSE),
      list(id="consanguinity_ns",     label="Consanguinity",
           lr_present=5.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "NPHS2 p.R229Q is a mild variant that contributes to disease only in compound het with another NPHS2 variant — a single p.R229Q in trans with a P/LP variant requires specialist interpretation",
      "Single heterozygous NPHS1 or NPHS2 variant in an adult with sub-nephrotic proteinuria: prior is 0.04 — phenotype concordance is very important",
      "LAMB2 (Pierson syndrome) also causes ocular abnormalities — if absent, reconsider",
      "CD151, ITGA3 also cause epidermolysis bullosa — extra-renal features are discriminating"
    ),
    references = c(
      "Hinkes BG et al. Nat Genet 2007;39:1018-1024",
      "Trautmann A et al. Pediatr Nephrol 2020;35:1529-1561"
    )
  ),

  # ---------------------------------------------------------------------------
  # 11. WT1-related disease
  # ---------------------------------------------------------------------------
  WT1disease = list(
    label     = "WT1-related disease (Denys-Drash / Frasier / WAGR)",
    genes     = c("WT1"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.82  # UNCERTAIN: penetrance depends heavily on variant type
                           # Intronic splice variants (Frasier) vs missense/truncating (Denys-Drash)
                           # have very different phenotypes
    ),
    features = list(
      list(id="nephrotic_wt1",      label="Nephrotic syndrome or proteinuria",
           lr_present=15.0, lr_absent=0.1,  key=TRUE),
      list(id="wilms_tumour",       label="Wilms tumour (history)",
           lr_present=15.0, lr_absent=NULL, key=FALSE),
      list(id="gonadal_dysgenesis", label="Gonadal dysgenesis or 46XY DSD",
           lr_present=15.0, lr_absent=NULL, key=FALSE),
      list(id="drash_biopsy",       label="Diffuse mesangial sclerosis on biopsy",
           lr_present=12.0, lr_absent=0.4,  key=FALSE),
      list(id="frasier_biopsy",     label="FSGS on biopsy (in adolescent/young adult)",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "WT1 variant type is critical: Frasier syndrome (intronic splice) = FSGS + DSD; Denys-Drash (missense zinc finger) = DMS + Wilms; WAGR (deletion) = aniridia",
      "Variant class should inform which phenotype to expect — tool cannot fully capture this distinction",
      "A P/LP WT1 variant without any nephrotic, gonadal, or Wilms tumour features should prompt reconsideration"
    ),
    references = c(
      "Lipska BS et al. J Am Soc Nephrol 2014;25:2764-2775"
    )
  ),

  # ---------------------------------------------------------------------------
  # 12. AD FSGS
  # ---------------------------------------------------------------------------
  ADFSGS = list(
    label     = "AD focal segmental glomerulosclerosis (ACTN4, TRPC6, INF2, MYO1E, others)",
    genes     = c("ACTN4", "TRPC6", "INF2", "MYO1E", "PLCE1", "PODXL",
                  "FAT1", "TNS2", "DAAM2", "PRDM15", "CRB2", "NOS1AP"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.68  # UNCERTAIN: varies significantly by gene
                           # ACTN4/TRPC6/INF2 have reasonable penetrance data
                           # FAT1, TNS2, DAAM2, PRDM15 have very limited evidence
    ),
    features = list(
      list(id="proteinuria_adfsgs", label="Proteinuria (nephrotic or sub-nephrotic)",
           lr_present=15.0, lr_absent=0.05, key=TRUE),
      list(id="fsgs_biopsy",       label="FSGS on renal biopsy",
           lr_present=12.0, lr_absent=0.2,  key=FALSE),
      list(id="ad_family_hx_fsgs", label="AD family history of proteinuria or renal failure",
           lr_present=8.0,  lr_absent=0.4,  key=FALSE),
      list(id="neuropathy_inf2",   label="Peripheral neuropathy (Charcot-Marie-Tooth disease)",
           lr_present=12.0, lr_absent=NULL, key=FALSE,
           caveat="Neuropathy with FSGS is near-pathognomonic for INF2"),
      list(id="adult_onset_fsgs",  label="Onset in adulthood (>18 years)",
           lr_present=4.0,  lr_absent=0.5,  key=FALSE)
    ),
    flags = c(
      "FAT1, TNS2, DAAM2, PODXL, NOS1AP: evidence for monogenic FSGS is limited — these may be susceptibility variants rather than high-penetrance monogenic causes. Prior of 0.68 likely too high for these genes",
      "PLCE1: biallelic causes AR FSGS; monoallelic may act as susceptibility factor — zygosity is critical",
      "CD2AP (also in AR FSGS list): single het may act as modifier rather than monogenic cause",
      "TRPC6: gains-of-function cause FSGS; some variants in databases may be misclassified"
    ),
    references = c(
      "Pollak MR. Annu Rev Med 2020;71:263-276",
      "Boyer O et al. N Engl J Med 2011;365:2377-2388"
    )
  ),

  # ---------------------------------------------------------------------------
  # 13. NUP-associated SRNS
  # ---------------------------------------------------------------------------
  NUP_SRNS = list(
    label     = "Nucleoporin-associated steroid-resistant nephrotic syndrome",
    genes     = c("NUP107", "NUP133", "NUP85", "NUP93", "NUP160",
                  "NUP37", "RRAGD"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.80,
      Heterozygous = 0.03   # UNCERTAIN: MAGED2 is X-linked and causes transient neonatal Bartter — different phenotype
    ),
    features = list(
      list(id="srns_nup",          label="Steroid-resistant nephrotic syndrome",
           lr_present=20.0, lr_absent=0.05, key=TRUE),
      list(id="fsgs_dms_nup",      label="FSGS or DMS on biopsy",
           lr_present=12.0, lr_absent=0.2,  key=FALSE),
      list(id="childhood_nup",     label="Childhood or adolescent onset",
           lr_present=10.0, lr_absent=0.2,  key=FALSE)
    ),
    flags = c(
      "MAGED2 has been removed from this group — it causes transient neonatal Bartter syndrome (X-linked), not FSGS; see Bartter condition",
      "RRAGD causes a distinct mTOR-related FSGS — may respond differently to treatment",
      "Evidence base for several NUP genes is small (<10 families)"
    ),
    references = c(
      "Braun DA et al. Nat Genet 2018;50:1490-1497"
    )
  ),

  # ---------------------------------------------------------------------------
  # 14. TIKD — Tubulointerstitial kidney disease
  # ---------------------------------------------------------------------------
  TIKD = list(
    label     = "Autosomal dominant tubulointerstitial kidney disease (UMOD, MUC1, REN)",
    genes     = c("UMOD", "MUC1", "REN", "SEC61A1", "DNAJB11"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.83
    ),
    features = list(
      list(id="gout_hyperuricaemia",   label="Gout or disproportionate hyperuricaemia (relative to eGFR)",
           lr_present=15.0, lr_absent=0.3,  key=FALSE,
           caveat="Hyperuricaemia/gout is characteristic of UMOD and REN disease but not always present"),
      list(id="slow_progressive_ckd",  label="Slowly progressive CKD",
           lr_present=6.0,  lr_absent=0.2,  key=TRUE),
      list(id="bland_urine_tikd",      label="Bland urinalysis (no haematuria, no significant proteinuria)",
           lr_present=5.0,  lr_absent=0.3,  key=FALSE),
      list(id="ad_family_hx_ckd",      label="AD family history of CKD or gout",
           lr_present=10.0, lr_absent=0.4,  key=FALSE),
      list(id="small_kidneys_tikd",    label="Small echogenic kidneys without cysts",
           lr_present=5.0,  lr_absent=NULL, key=FALSE),
      list(id="anaemia_disproportionate", label="Anaemia disproportionate to level of CKD",
           lr_present=4.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "MUC1 variants are notoriously difficult to detect by standard NGS due to the VNTR region — a 'P/LP' MUC1 variant should be verified by specialist laboratory",
      "SEC61A1 evidence base is very limited",
      "DNAJB11 is also listed under ADPKD — it can cause atypical PKD with tubulointerstitial features"
    ),
    references = c(
      "Eckardt KU et al. Nat Rev Nephrol 2015;11:617-625",
      "Bleyer AJ et al. Kidney Int 2020;98:826-840"
    )
  ),

  # ---------------------------------------------------------------------------
  # 15. Gitelman syndrome and related hypomagnesaemia
  # ---------------------------------------------------------------------------
  Gitelman = list(
    label     = "Gitelman syndrome / hereditary hypomagnesaemia (SLC12A3, CLDN16, CLDN19, CNNM2)",
    genes     = c("SLC12A3", "CLDN16", "CLDN19", "CNNM2", "KCNJ10",
                  "ATP1A1", "TRPM6"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.90,
      Heterozygous = 0.04
    ),
    features = list(
      list(id="hypokalaemia_alkalosis", label="Hypokalaemia with metabolic alkalosis",
           lr_present=20.0, lr_absent=0.04, key=TRUE),
      list(id="hypomagnesaemia_git",    label="Hypomagnesaemia",
           lr_present=15.0, lr_absent=0.2,  key=FALSE,
           caveat="More prominent in Gitelman/CLDN16 than Bartter; hypocalciuria distinguishes from Bartter"),
      list(id="hypocalciuria",          label="Hypocalciuria (24hr urine calcium low)",
           lr_present=10.0, lr_absent=0.2,  key=FALSE,
           caveat="Distinguishes Gitelman from Bartter — Bartter has hypercalciuria"),
      list(id="normal_bp_git",          label="Normal or low blood pressure",
           lr_present=5.0,  lr_absent=0.3,  key=FALSE),
      list(id="muscle_cramps_git",      label="Muscle cramps or tetany",
           lr_present=6.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "CNNM2 biallelic causes severe hypomagnesaemia with epilepsy and intellectual disability — very different from Gitelman. ATP1A1 also has neurological features. Prior may be too high for these genes",
      "TRPM6 variants cause primary hypomagnesaemia with secondary hypocalcaemia — may overlap but distinct from Gitelman",
      "Single het SLC12A3: prior of 0.04 reflects that carriers can have mild biochemical abnormalities but do not generally have overt Gitelman syndrome"
    ),
    references = c(
      "Knoers NV, Levtchenko EN. Orphanet J Rare Dis 2008;3:22"
    )
  ),

  # ---------------------------------------------------------------------------
  # 16. Bartter syndrome
  # ---------------------------------------------------------------------------
  Bartter = list(
    label     = "Bartter syndrome (CLCNKB, BSND, SLC12A1, KCNJ1, CLDN10)",
    genes     = c("CLCNKB", "BSND", "SLC12A1", "KCNJ1", "CLDN10",
                  "CASR", "KCNJ16", "MAGED2"),
    # MAGED2 is X-linked and causes a TRANSIENT neonatal Bartter-like syndrome —
    # distinct from classical Bartter. Grouped here as nearest phenotypic match.
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.88,
      Heterozygous = 0.04
    ),
    features = list(
      list(id="hypokalaemia_bartter",   label="Hypokalaemia with metabolic alkalosis",
           lr_present=20.0, lr_absent=0.04, key=TRUE),
      list(id="hypercalciuria_bartter", label="Hypercalciuria (distinguishes from Gitelman)",
           lr_present=12.0, lr_absent=0.2,  key=FALSE),
      list(id="nephrocalcinosis_bartter", label="Nephrocalcinosis",
           lr_present=10.0, lr_absent=NULL, key=FALSE),
      list(id="polyuria_bartter",       label="Polyuria or polydipsia",
           lr_present=8.0,  lr_absent=0.3,  key=FALSE),
      list(id="antenatal_bartter",      label="Antenatal or neonatal presentation (polyhydramnios, prematurity)",
           lr_present=15.0, lr_absent=NULL, key=FALSE,
           caveat="Types 1/2 (SLC12A1/KCNJ1) typically present antenatally; type 3 (CLCNKB) later"),
      list(id="hearing_loss_bartter",   label="Sensorineural hearing loss",
           lr_present=20.0, lr_absent=0.5,  key=FALSE,
           caveat="Specific to BSND (type 4 Bartter) — its presence strongly points to BSND")
    ),
    flags = c(
      "CASR gain-of-function causes autosomal dominant hypocalcaemia with Bartter-like biochemistry — inheritance pattern is AD, not AR; prior incorrect if applied to CASR het",
      "CLCNKB (type 3) has the widest phenotypic spectrum — can mimic Gitelman in older presentation",
      "MAGED2 (X-linked): causes transient neonatal Bartter that resolves spontaneously — phenotype and management completely different from classical Bartter; specialist interpretation required"
    ),
    references = c(
      "Konrad M et al. Pediatr Nephrol 2008;23:1175-1185"
    )
  ),

  # ---------------------------------------------------------------------------
  # 17. Distal renal tubular acidosis
  # ---------------------------------------------------------------------------
  DistalRTA = list(
    label     = "Distal renal tubular acidosis (ATP6V0A4, ATP6V1B1, SLC4A1, CA2)",
    genes     = c("ATP6V0A4", "ATP6V1B1", "SLC4A1", "CA2"),
    inheritance      = "AR",   # primary; SLC4A1 also AD
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.88,
      Heterozygous = 0.25   # SLC4A1 AD causes dRTA; AR causes haemolytic anaemia+dRTA
                            # UNCERTAIN: AD SLC4A1 penetrance varies by variant
    ),
    features = list(
      list(id="hyperchloraemic_acidosis", label="Normal anion gap (hyperchloraemic) metabolic acidosis with alkaline urine",
           lr_present=20.0, lr_absent=0.04, key=TRUE),
      list(id="nephrocalcinosis_rta",     label="Nephrocalcinosis",
           lr_present=15.0, lr_absent=0.2,  key=FALSE),
      list(id="nephrolithiasis_rta",      label="Calcium phosphate or mixed nephrolithiasis",
           lr_present=12.0, lr_absent=NULL, key=FALSE),
      list(id="hearing_loss_rta",         label="Sensorineural hearing loss",
           lr_present=15.0, lr_absent=0.4,  key=FALSE,
           caveat="Specific to ATP6V1B1 (type 2 with deafness) — helps distinguish"),
      list(id="growth_retardation",       label="Growth retardation or failure to thrive (childhood)",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="osteomalacia",             label="Rickets or osteomalacia",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "SLC4A1 het (AD) causes dRTA; biallelic (AR) causes severe haemolytic anaemia + dRTA — zygosity critical",
      "CA2 biallelic causes osteopetrosis + RTA — bone density/skeletal findings expected"
    ),
    references = c(
      "Stover EH et al. Nat Genet 2002;32:450-453"
    )
  ),

  # ---------------------------------------------------------------------------
  # 18. Primary hyperoxaluria
  # ---------------------------------------------------------------------------
  PrimaryHyperoxaluria = list(
    label     = "Primary hyperoxaluria (AGXT, GRHPR, HOGA1)",
    genes     = c("AGXT", "GRHPR", "HOGA1", "HAAO", "KYNU"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.90,
      Heterozygous = 0.03
    ),
    features = list(
      list(id="calcium_oxalate_stones", label="Recurrent calcium oxalate nephrolithiasis",
           lr_present=15.0, lr_absent=0.08, key=TRUE),
      list(id="nephrocalcinosis_ox",    label="Nephrocalcinosis",
           lr_present=12.0, lr_absent=NULL, key=FALSE),
      list(id="elevated_urinary_ox",   label="Elevated urinary oxalate (>0.5 mmol/1.73m²/day)",
           lr_present=25.0, lr_absent=0.05, key=FALSE),
      list(id="systemic_oxalosis",     label="Systemic oxalosis (retina, heart, bone — late ESKD)",
           lr_present=15.0, lr_absent=NULL, key=FALSE),
      list(id="childhood_onset_ox",    label="Onset in childhood or adolescence",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "HAAO and KYNU are very recently described PH causes with limited evidence",
      "Urinary oxalate measurement is key — without it, phenotype cannot be fully confirmed",
      "Distinction between PH types 1/2/3 matters for treatment (liver transplant indication)"
    ),
    references = c(
      "Hoppe B. Nat Rev Nephrol 2012;8:467-475"
    )
  ),

  # ---------------------------------------------------------------------------
  # 19. Dent disease
  # ---------------------------------------------------------------------------
  DentDisease = list(
    label     = "Dent disease (CLCN5, OCRL)",
    genes     = c("CLCN5", "OCRL"),
    inheritance      = "XL",
    zygosity_options = c("Hemizygous_male", "Heterozygous_female"),
    prior = c(
      Hemizygous_male     = 0.88,
      Heterozygous_female = 0.18   # UNCERTAIN: female carriers can be affected but penetrance variable
    ),
    features = list(
      list(id="lmw_proteinuria",     label="Low molecular weight proteinuria (urine beta-2 microglobulin elevated)",
           lr_present=20.0, lr_absent=0.04, key=TRUE),
      list(id="hypercalciuria_dent", label="Hypercalciuria",
           lr_present=15.0, lr_absent=0.1,  key=FALSE),
      list(id="nephrolithiasis_dent",label="Nephrolithiasis or nephrocalcinosis",
           lr_present=12.0, lr_absent=NULL, key=FALSE),
      list(id="hypophosphataemia_rickets", label="Hypophosphataemia or rickets",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="male_sex_dent",       label="Male sex",
           lr_present=4.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "OCRL also causes Lowe syndrome (oculocerebrorenal) — if intellectual disability and cataracts present, consider full Lowe rather than Dent disease 2",
      "Female carriers of CLCN5 usually have milder disease — significant renal involvement should prompt search for skewed X-inactivation"
    ),
    references = c(
      "Devuyst O, Thakker RV. Nephron Physiol 2010;116:22-26"
    )
  ),

  # ---------------------------------------------------------------------------
  # 20. Nephrogenic diabetes insipidus
  # ---------------------------------------------------------------------------
  NephrogenicDI = list(
    label     = "Congenital nephrogenic diabetes insipidus (AVPR2, AQP2)",
    genes     = c("AVPR2", "AQP2"),
    inheritance      = "XL",   # AVPR2; AQP2 is AR/AD
    zygosity_options = c("Hemizygous_male", "Heterozygous_female", "Biallelic"),
    prior = c(
      Hemizygous_male     = 0.95,
      Heterozygous_female = 0.30,  # AVPR2 carrier females can have variable NDI
      Biallelic           = 0.90   # AQP2 AR
    ),
    features = list(
      list(id="polyuria_polydipsia", label="Severe polyuria and polydipsia",
           lr_present=25.0, lr_absent=0.02, key=TRUE),
      list(id="no_concentration",   label="Failure to concentrate urine after desmopressin (osmolality <300 mOsm/kg)",
           lr_present=25.0, lr_absent=0.02, key=FALSE),
      list(id="hypernatraemia",     label="Hypernatraemia or dehydration episodes",
           lr_present=12.0, lr_absent=NULL, key=FALSE),
      list(id="childhood_ndi",      label="Presentation in infancy or childhood",
           lr_present=15.0, lr_absent=0.1,  key=FALSE)
    ),
    flags = c(
      "AQP2 AD (monoallelic gain-of-function) is a distinct and rarer form — prior for het AQP2 not included here; if het AQP2 variant, flag for specialist review"
    ),
    references = c(
      "Bockenhauer D, Bichet DG. Nat Rev Nephrol 2015;11:576-588"
    )
  ),

  # ---------------------------------------------------------------------------
  # 21. aHUS / complement-mediated
  # ---------------------------------------------------------------------------
  aHUS = list(
    label     = "aHUS / complement-mediated TMA (CFH, CFI, C3, CFB, CD46, DGKE)",
    genes     = c("CFH", "CFI", "C3", "CFB", "CD46", "DGKE",
                  "CFHR1", "CFHR2"),
    inheritance      = "AD",   # most; DGKE is AR; CFH biallelic causes C3G not aHUS
    zygosity_options = c("Heterozygous", "Biallelic"),
    prior = c(
      Heterozygous = 0.35,   # Complement variants are susceptibility alleles — penetrance ~50% lifetime
                             # UNCERTAIN: wide range; CFH het penetrance ~50%, CD46 lower
      Biallelic    = 0.70    # Biallelic CFH → C3G phenotype rather than aHUS typically
    ),
    features = list(
      list(id="tma_triad",          label="TMA triad: microangiopathic haemolytic anaemia + thrombocytopenia + AKI",
           lr_present=25.0, lr_absent=0.04, key=TRUE),
      list(id="no_stec",            label="Absence of Shiga-toxin producing E. coli infection",
           lr_present=5.0,  lr_absent=NULL, key=FALSE),
      list(id="recurrent_tma",      label="Recurrent episodes of TMA",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="low_c3_complement",  label="Low C3 complement level",
           lr_present=8.0,  lr_absent=0.4,  key=FALSE),
      list(id="pregnancy_trigger",  label="Triggered by pregnancy or post-partum",
           lr_present=5.0,  lr_absent=NULL, key=FALSE),
      list(id="family_hx_ahus",     label="Family history of HUS or unexplained renal failure",
           lr_present=6.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Complement variants are susceptibility alleles with incomplete penetrance — ~50% of CFH P/LP variant carriers never develop aHUS. Prior of 0.35 reflects this",
      "A P/LP complement variant found on broad panel screening of a patient WITHOUT TMA features should be interpreted very cautiously",
      "DGKE is AR and causes a distinct form of aHUS with onset in infancy — AD prior does not apply",
      "CFHR1/CFHR2 variants: evidence base for pathogenicity weaker than CFH; some variants may be misclassified",
      "CFH biallelic → C3 glomerulopathy phenotype rather than aHUS — see C3G condition"
    ),
    references = c(
      "Noris M, Remuzzi G. N Engl J Med 2009;361:1676-1687",
      "Fremeaux-Bacchi V et al. Clin J Am Soc Nephrol 2013;8:554-562"
    )
  ),

  # ---------------------------------------------------------------------------
  # 22. C3 glomerulopathy / MPGN
  # ---------------------------------------------------------------------------
  C3G = list(
    label     = "C3 glomerulopathy / MPGN (CFHR5, CFH biallelic, CFI, C3, CFB)",
    genes     = c("CFHR5", "CFHR1", "CFHR2", "CFH", "CFI", "C3", "CFB"),
    inheritance      = "AD",   # CFHR5 monoallelic; others variable
    zygosity_options = c("Heterozygous", "Biallelic"),
    prior = c(
      Heterozygous = 0.50,   # UNCERTAIN: varies widely by gene — CFHR5 duplication in Cypriot high penetrance
      Biallelic    = 0.78    # CFH biallelic → C3 deficiency/C3G
    ),
    features = list(
      list(id="c3g_biopsy",         label="C3 glomerulopathy or MPGN pattern on biopsy",
           lr_present=25.0, lr_absent=0.05, key=TRUE),
      list(id="low_c3_c3g",         label="Low C3 complement (with normal C4)",
           lr_present=12.0, lr_absent=0.3,  key=FALSE),
      list(id="haematuria_c3g",     label="Haematuria",
           lr_present=6.0,  lr_absent=0.3,  key=FALSE),
      list(id="cypriot_ancestry",   label="Cypriot or eastern Mediterranean ancestry",
           lr_present=10.0, lr_absent=NULL, key=FALSE,
           caveat="Specific to CFHR5 nephropathy — strongly supports if present"),
      list(id="proteinuria_c3g",    label="Proteinuria",
           lr_present=5.0,  lr_absent=0.2,  key=FALSE)
    ),
    flags = c(
      "CFHR5 duplication is highly prevalent in Cypriot population — if non-Cypriot ancestry, reconsider significance",
      "Complement gene variants found without biopsy confirmation of C3G should be interpreted very cautiously",
      "CFHR1/CFHR2: copy number variants rather than SNVs are the typical pathogenic mechanism — ensure variant type is appropriate"
    ),
    references = c(
      "Nester CM et al. Nephrol Dial Transplant 2018;33:i1-i7",
      "Gale DP et al. N Engl J Med 2010;363:2357-2359"
    )
  ),

  # ---------------------------------------------------------------------------
  # 23. Amyloidosis
  # ---------------------------------------------------------------------------
  Amyloidosis = list(
    label     = "Hereditary amyloidosis (TTR, APOA1, GSN, LYZ, FGA)",
    genes     = c("TTR", "APOA1", "GSN", "LYZ", "FGA", "APOE",
                  "APOA2", "APOC2"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.78   # TTR high penetrance (age-dependent); others variable
                            # UNCERTAIN: APOA2, APOC2 extremely rare — very limited evidence
    ),
    features = list(
      list(id="amyloid_biopsy",     label="Amyloid confirmed on biopsy (Congo red positive)",
           lr_present=30.0, lr_absent=0.05, key=TRUE),
      list(id="cardiomyopathy_amy", label="Restrictive cardiomyopathy",
           lr_present=15.0, lr_absent=0.4,  key=FALSE,
           caveat="Cardinal feature of TTR amyloidosis"),
      list(id="neuropathy_amy",     label="Peripheral or autonomic neuropathy",
           lr_present=12.0, lr_absent=0.4,  key=FALSE),
      list(id="proteinuria_amy",    label="Proteinuria / nephrotic syndrome",
           lr_present=8.0,  lr_absent=0.2,  key=FALSE),
      list(id="age_over50",         label="Age >50 years",
           lr_present=5.0,  lr_absent=0.3,  key=FALSE),
      list(id="family_hx_amy",      label="Family history of amyloidosis, cardiomyopathy, or neuropathy",
           lr_present=8.0,  lr_absent=0.4,  key=FALSE),
      list(id="corneal_gelsolin",   label="Lattice corneal dystrophy (GSN-specific)",
           lr_present=20.0, lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "APOA2 and APOC2: extremely rare amyloidosis types with very limited published penetrance data — prior unreliable for these genes",
      "TTR penetrance is strongly age-dependent (rare before 50, common after 60-70 for some variants e.g. Val30Met in non-endemic populations)",
      "Without biopsy confirming amyloid subtype, variant alone is insufficient for diagnosis"
    ),
    references = c(
      "Wechalekar AD et al. Lancet 2016;387:2641-2654",
      "Benson MD et al. Amyloid 2020;27:217-222"
    )
  ),

  # ---------------------------------------------------------------------------
  # 24. Tuberous sclerosis
  # ---------------------------------------------------------------------------
  TuberousSclerosis = list(
    label     = "Tuberous sclerosis complex (TSC1, TSC2)",
    genes     = c("TSC1", "TSC2"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.90   # High penetrance; ~50% de novo
    ),
    features = list(
      list(id="angiomyolipoma",     label="Renal angiomyolipoma",
           lr_present=20.0, lr_absent=0.1,  key=FALSE),
      list(id="renal_cysts_tsc",    label="Renal cysts",
           lr_present=5.0,  lr_absent=NULL, key=FALSE),
      list(id="skin_tsc",           label="Facial angiofibromas, ash-leaf macules, or shagreen patches",
           lr_present=15.0, lr_absent=0.15, key=FALSE),
      list(id="cns_tsc",            label="Cortical tubers, subependymal nodules, or SEGA on brain imaging",
           lr_present=15.0, lr_absent=0.15, key=FALSE),
      list(id="lam",                label="Lymphangioleiomyomatosis (females)",
           lr_present=12.0, lr_absent=NULL, key=FALSE),
      list(id="seizures_tsc",       label="Seizures",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "TSC2 tends to be more severe than TSC1 — but individual variant penetrance is highly variable",
      "PKD1/TSC2 contiguous gene deletion syndrome causes severe early-onset PKD + TSC — check if in chromosomal proximity"
    ),
    references = c(
      "Northrup H et al. Pediatr Neurol 2013;49:243-254"
    )
  ),

  # ---------------------------------------------------------------------------
  # 25. Fabry disease
  # ---------------------------------------------------------------------------
  FabryDisease = list(
    label     = "Fabry disease (GLA)",
    genes     = c("GLA"),
    inheritance      = "XL",
    zygosity_options = c("Hemizygous_male", "Heterozygous_female"),
    prior = c(
      Hemizygous_male     = 0.88,  # Classic Fabry high penetrance in males
      Heterozygous_female = 0.55   # UNCERTAIN: female penetrance ranges from asymptomatic to severe
    ),
    features = list(
      list(id="neuropathic_pain",    label="Neuropathic pain / acroparaesthesiae",
           lr_present=15.0, lr_absent=0.3,  key=FALSE),
      list(id="angiokeratoma",       label="Angiokeratoma (skin)",
           lr_present=15.0, lr_absent=0.5,  key=FALSE),
      list(id="corneal_verticillata",label="Corneal verticillata (slit-lamp examination)",
           lr_present=12.0, lr_absent=0.4,  key=FALSE),
      list(id="lge_cardiac",         label="Hypertrophic cardiomyopathy or LGE on cardiac MRI",
           lr_present=10.0, lr_absent=0.3,  key=FALSE),
      list(id="young_stroke",        label="Stroke or TIA in young person (<50 yrs)",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="low_agalactosidase",  label="Reduced alpha-galactosidase A enzyme activity",
           lr_present=25.0, lr_absent=0.05, key=TRUE,
           caveat="Enzyme activity unreliable in females — females can have normal activity despite pathogenic variant"),
      list(id="proteinuria_fabry",   label="Proteinuria or CKD",
           lr_present=5.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Many GLA variants of uncertain significance are found on broad panel screening — benign variants (e.g. p.A143T, p.D313Y) can be misclassified as P/LP",
      "Female penetrance is highly variable — some heterozygous females are severely affected, others entirely asymptomatic",
      "Enzyme activity is unreliable in females; lyso-Gb3 plasma biomarker is more informative",
      "Late-onset cardiac variants (e.g. p.IVS4+919) have restricted phenotype — no neuropathic pain/angiokeratoma expected"
    ),
    references = c(
      "Mehta A et al. Eur J Hum Genet 2009;17:491-499"
    )
  ),

  # ---------------------------------------------------------------------------
  # 26. Cystinosis
  # ---------------------------------------------------------------------------
  Cystinosis = list(
    label     = "Cystinosis (CTNS)",
    genes     = c("CTNS"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.90,
      Heterozygous = 0.02
    ),
    features = list(
      list(id="fanconi_syndrome",   label="Fanconi syndrome (phosphaturia, glycosuria, aminoaciduria, proximal RTA)",
           lr_present=20.0, lr_absent=0.05, key=TRUE),
      list(id="corneal_crystals",   label="Corneal cystine crystals on slit-lamp",
           lr_present=20.0, lr_absent=0.1,  key=FALSE),
      list(id="photophobia",        label="Photophobia",
           lr_present=15.0, lr_absent=0.3,  key=FALSE),
      list(id="childhood_onset_cyst", label="Presentation in childhood (typically <1 year)",
           lr_present=15.0, lr_absent=0.05, key=FALSE),
      list(id="hypothyroidism",     label="Hypothyroidism",
           lr_present=5.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Nephropathic cystinosis almost always presents in the first year of life — a de novo diagnosis of cystinosis in an adult should be scrutinised carefully",
      "Intermediate/ocular cystinosis (milder variants) may present later with mainly ocular features"
    ),
    references = c(
      "Nesterova G, Gahl W. Pediatr Nephrol 2008;23:2013-2023"
    )
  ),

  # ---------------------------------------------------------------------------
  # 27. HNF1B disease
  # ---------------------------------------------------------------------------
  HNF1Bdisease = list(
    label     = "HNF1B-related disease (renal cysts and diabetes syndrome)",
    genes     = c("HNF1B"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.80   # ~50% de novo; high penetrance but variable expressivity
    ),
    features = list(
      list(id="renal_cysts_hnf1b",  label="Renal cysts (often irregular / asymmetric)",
           lr_present=10.0, lr_absent=0.2,  key=FALSE),
      list(id="mody5_diabetes",     label="Diabetes mellitus (MODY5 pattern: young onset, non-obese, strong family history)",
           lr_present=10.0, lr_absent=NULL, key=FALSE),
      list(id="structural_anomaly", label="Structural renal anomaly (hypoplasia, horseshoe kidney, agenesis)",
           lr_present=10.0, lr_absent=NULL, key=FALSE),
      list(id="hypomagnesaemia_hnf",label="Hypomagnesaemia",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="abnormal_lft",       label="Abnormal liver function (hepatic cysts or biliary abnormality)",
           lr_present=6.0,  lr_absent=NULL, key=FALSE),
      list(id="low_bicarbonate",    label="Low serum bicarbonate",
           lr_present=4.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "HNF1B phenotype is highly variable — some patients have only one manifestation (e.g. cysts alone or diabetes alone)",
      "Whole gene deletion is the most common mechanism (~50%) — point variants may be less penetrant",
      "Pancreatic abnormalities (atrophy) are characteristic but not always assessed"
    ),
    references = c(
      "Clissold RL et al. Nat Rev Nephrol 2015;11:657-669"
    )
  ),

  # ---------------------------------------------------------------------------
  # 28. Renal coloboma / PAX2 disease
  # ---------------------------------------------------------------------------
  PAX2disease = list(
    label     = "PAX2-related disease (renal coloboma syndrome)",
    genes     = c("PAX2"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.78   # High penetrance but variable expressivity
    ),
    features = list(
      list(id="optic_coloboma",     label="Optic nerve coloboma or other optic nerve anomaly",
           lr_present=20.0, lr_absent=0.15, key=FALSE,
           caveat="Coloboma is present in ~70% but not all — renal anomaly alone is well recognised"),
      list(id="renal_hypoplasia_pax", label="Renal hypoplasia or dysplasia",
           lr_present=12.0, lr_absent=0.1,  key=TRUE),
      list(id="high_myopia",        label="High myopia",
           lr_present=6.0,  lr_absent=NULL, key=FALSE),
      list(id="vesicoureteral_reflux_pax", label="Vesicoureteral reflux",
           lr_present=5.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "PAX2 expressivity is broad — isolated renal hypoplasia without ophthalmological features is well recognised",
      "Ophthalmology assessment should be arranged if not already done when PAX2 variant found"
    ),
    references = c(
      "Bower M et al. Hum Mutat 2012;33:1573-1578"
    )
  ),

  # ---------------------------------------------------------------------------
  # 29. BOR / EYA1 (branchio-oto-renal syndrome)
  # ---------------------------------------------------------------------------
  BORsyndrome = list(
    label     = "Branchio-oto-renal syndrome (EYA1, SIX1, SIX5)",
    genes     = c("EYA1"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.88   # High penetrance
    ),
    features = list(
      list(id="preauricular_pits",  label="Preauricular pits or tags",
           lr_present=15.0, lr_absent=0.3,  key=FALSE),
      list(id="hearing_loss_bor",   label="Sensorineural, conductive, or mixed hearing loss",
           lr_present=12.0, lr_absent=0.15, key=FALSE),
      list(id="branchial_cysts",    label="Branchial cysts or fistulae",
           lr_present=12.0, lr_absent=0.5,  key=FALSE),
      list(id="renal_anomaly_bor",  label="Renal structural anomaly (hypoplasia, duplex system, VUR)",
           lr_present=10.0, lr_absent=0.15, key=TRUE)
    ),
    flags = c(
      "BOR is a clinical diagnosis based on major/minor criteria — a P/LP EYA1 variant found without otological or branchial features should prompt ENT assessment"
    ),
    references = c(
      "Chang EH et al. Am J Hum Genet 2004;74:1065-1071"
    )
  ),

  # ---------------------------------------------------------------------------
  # 30. CAKUT / structural renal anomalies
  # ---------------------------------------------------------------------------
  CAKUT = list(
    label     = "CAKUT / structural renal anomalies (SALL1, RET, GATA3, FRAS1, FREM1/2, others)",
    genes     = c("SALL1", "RET", "GATA3", "FRAS1", "FREM1", "FREM2",
                  "GRIP1", "BNC2", "DSTYK", "ITGA8", "FAM20A", "LRIG2",
                  "HPSE2", "ACTG2", "CHRM3", "TBX18", "PBX1"),
    inheritance      = "AD",   # most; some AR
    zygosity_options = c("Heterozygous", "Biallelic"),
    prior = c(
      Heterozygous = 0.65,   # UNCERTAIN: highly variable by gene
      Biallelic    = 0.78
    ),
    features = list(
      list(id="structural_renal",   label="Renal structural anomaly on imaging (hypoplasia, agenesis, duplex, horseshoe)",
           lr_present=15.0, lr_absent=0.04, key=TRUE),
      list(id="vur_cakut",          label="Vesicoureteral reflux",
           lr_present=6.0,  lr_absent=NULL, key=FALSE),
      list(id="bladder_anomaly",    label="Bladder dysfunction or structural anomaly",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="extra_renal_features", label="Syndrome-specific extra-renal features",
           lr_present=10.0, lr_absent=NULL, key=FALSE,
           caveat="SALL1 = Townes-Brocks (ears, anus); RET = Hirschsprung; GATA3 = HDR syndrome; ACTG2/CHRM3 = prune belly / megacystis")
    ),
    flags = c(
      "CAKUT is genetically extremely heterogeneous — penetrance and expressivity vary enormously between genes and variants",
      "Many listed genes have limited penetrance evidence; prior of 0.65 is uncertain across the group",
      "GATA3 causes HDR syndrome (hypoparathyroidism, deafness, renal dysplasia) — deafness and calcium should be assessed",
      "RET variants cause Hirschsprung disease — colonic phenotype should be assessed",
      "HPSE2 causes urofacial (Ochoa) syndrome — facial grimacing with micturition is pathognomonic",
      "FAM20A causes amelogenesis imperfecta with renal stones — dental phenotype is key"
    ),
    references = c(
      "van der Ven AT et al. JASN 2018;29:2213-2226"
    )
  ),

  # ---------------------------------------------------------------------------
  # 31. Alstrom syndrome
  # ---------------------------------------------------------------------------
  AlstromSyndrome = list(
    label     = "Alstrom syndrome (ALMS1)",
    genes     = c("ALMS1"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.85,
      Heterozygous = 0.02
    ),
    features = list(
      list(id="retinal_dystrophy_alms", label="Retinal dystrophy (nystagmus in infancy, visual loss)",
           lr_present=15.0, lr_absent=0.08, key=TRUE),
      list(id="obesity_alms",           label="Obesity",
           lr_present=10.0, lr_absent=0.2,  key=FALSE),
      list(id="diabetes_alms",          label="Type 2 diabetes (often early onset)",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="cardiomyopathy_alms",    label="Dilated cardiomyopathy",
           lr_present=10.0, lr_absent=NULL, key=FALSE),
      list(id="hearing_loss_alms",      label="Sensorineural hearing loss",
           lr_present=8.0,  lr_absent=0.3,  key=FALSE)
    ),
    flags = c(
      "Alstrom shares features with BBS — the key distinguishing features are cardiomyopathy (Alstrom) and polydactyly (BBS, not Alstrom)"
    ),
    references = c(
      "Marshall JD et al. Eur J Hum Genet 2011;19:1110-1117"
    )
  ),

  # ---------------------------------------------------------------------------
  # 32. Nail-patella syndrome (LMX1B)
  # ---------------------------------------------------------------------------
  NailPatella = list(
    label     = "Nail-patella syndrome (LMX1B)",
    genes     = c("LMX1B"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.85   # High penetrance; nephropathy in ~30-40%
    ),
    features = list(
      list(id="nail_dysplasia",   label="Nail dysplasia (triangular lunulae, hypoplastic/absent nails)",
           lr_present=20.0, lr_absent=0.1,  key=TRUE),
      list(id="absent_patellae",  label="Absent or hypoplastic patellae",
           lr_present=20.0, lr_absent=0.1,  key=FALSE),
      list(id="iliac_horns",      label="Iliac horns on imaging",
           lr_present=15.0, lr_absent=0.4,  key=FALSE),
      list(id="proteinuria_nps",  label="Proteinuria or haematuria",
           lr_present=6.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "The diagnosis of nail-patella syndrome is primarily clinical — a P/LP LMX1B variant without nail or skeletal features should prompt orthopaedic/dermatological review"
    ),
    references = c(
      "Sweeney E et al. J Med Genet 2003;40:153-162"
    )
  ),

  # ---------------------------------------------------------------------------
  # 33. VHL disease
  # ---------------------------------------------------------------------------
  VHLdisease = list(
    label     = "Von Hippel-Lindau disease (VHL)",
    genes     = c("VHL"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.90   # Very high penetrance; >90% manifest by age 65
    ),
    features = list(
      list(id="clear_cell_rcc",     label="Clear cell renal cell carcinoma",
           lr_present=20.0, lr_absent=0.1,  key=FALSE),
      list(id="renal_cysts_vhl",    label="Renal cysts (often bilateral, multiple)",
           lr_present=8.0,  lr_absent=NULL, key=FALSE),
      list(id="haemangioblastoma",  label="Haemangioblastoma (cerebellar, spinal, retinal)",
           lr_present=20.0, lr_absent=0.2,  key=FALSE),
      list(id="phaeochromocytoma",  label="Phaeochromocytoma or paraganglioma",
           lr_present=12.0, lr_absent=NULL, key=FALSE),
      list(id="pancreatic_lesions", label="Pancreatic cysts or neuroendocrine tumours",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "VHL diagnosis is unlikely to be the primary reason for R257 referral — but variants may be returned incidentally",
      "Somatic VHL variants in tumour tissue only are not the same as germline — confirm germline status"
    ),
    references = c(
      "Lonser RR et al. Lancet 2003;361:2059-2067"
    )
  ),

  # ---------------------------------------------------------------------------
  # 34. FLCN (Birt-Hogg-Dubé)
  # ---------------------------------------------------------------------------
  BirtHoggDube = list(
    label     = "Birt-Hogg-Dubé syndrome (FLCN)",
    genes     = c("FLCN"),
    inheritance      = "AD",
    zygosity_options = c("Heterozygous"),
    prior = c(
      Heterozygous = 0.88
    ),
    features = list(
      list(id="fibrofolliculomas",   label="Fibrofolliculomas or trichodiscomas (skin)",
           lr_present=20.0, lr_absent=0.3,  key=FALSE),
      list(id="pulmonary_cysts_bhd", label="Pulmonary cysts (basal, bilateral)",
           lr_present=15.0, lr_absent=0.2,  key=FALSE),
      list(id="chromophobe_rcc",     label="Renal cell carcinoma (chromophobe or oncocytoma)",
           lr_present=15.0, lr_absent=NULL, key=FALSE),
      list(id="pneumothorax",        label="Spontaneous pneumothorax",
           lr_present=10.0, lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "Renal manifestations alone without skin or pulmonary features are unusual — dermatological assessment should be arranged"
    ),
    references = c(
      "Menko FH et al. Lancet Oncol 2009;10:1199-1206"
    )
  ),

  # ---------------------------------------------------------------------------
  # 35. Renal tubular dysgenesis (ACE, AGT, AGTR1)
  # ---------------------------------------------------------------------------
  RenalTubularDysgenesis = list(
    label     = "Renal tubular dysgenesis (ACE, AGT, AGTR1)",
    genes     = c("ACE", "AGT", "AGTR1"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.88,
      Heterozygous = 0.02
    ),
    features = list(
      list(id="neonatal_anuria",    label="Neonatal anuria or severe oliguria",
           lr_present=25.0, lr_absent=0.02, key=TRUE,
           caveat="Renal tubular dysgenesis presents in the neonatal period — incompatible with adult presentation without prior history"),
      list(id="oligohydramnios_rtd",label="Oligohydramnios (antenatal)",
           lr_present=20.0, lr_absent=0.05, key=FALSE),
      list(id="pulmonary_hypoplasia",label="Pulmonary hypoplasia (neonatal)",
           lr_present=15.0, lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "RTD is a severe neonatal condition — a variant in ACE/AGT/AGTR1 found in an adult with young ESKD of unknown cause is extremely unlikely to be causative",
      "ACE inhibitor use in pregnancy causes an acquired RTD-like phenotype — gene variants in this context need careful interpretation"
    ),
    references = c(
      "Gribouval O et al. Nat Genet 2005;37:964-968"
    )
  ),

  # ---------------------------------------------------------------------------
  # 36. Lesch-Nyhan / primary hyperuricaemia (HPRT1)
  # ---------------------------------------------------------------------------
  LeschNyhan = list(
    label     = "Lesch-Nyhan syndrome / primary hyperuricaemia (HPRT1)",
    genes     = c("HPRT1", "MOCOS"),
    inheritance      = "XL",
    zygosity_options = c("Hemizygous_male", "Heterozygous"),
    prior = c(
      Hemizygous_male = 0.88,
      Heterozygous    = 0.05
    ),
    features = list(
      list(id="disproportionate_hyperuricaemia", label="Markedly elevated serum uric acid (disproportionate to renal function)",
           lr_present=20.0, lr_absent=0.05, key=TRUE),
      list(id="early_gout",        label="Early-onset gout or tophi (<30 years)",
           lr_present=15.0, lr_absent=0.2,  key=FALSE),
      list(id="uric_acid_stones",  label="Uric acid urolithiasis",
           lr_present=12.0, lr_absent=NULL, key=FALSE),
      list(id="self_mutilation",   label="Self-mutilation or neurological features (Lesch-Nyhan)",
           lr_present=25.0, lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "HPRT1 causes a spectrum: severe Lesch-Nyhan (self-mutilation, intellectual disability) to milder Kelley-Seegmiller (gout only) depending on residual enzyme activity",
      "MOCOS (molybdenum cofactor deficiency) is extremely rare — evidence base very limited"
    ),
    references = c(
      "Torres RJ, Puig JG. Orphanet J Rare Dis 2007;2:48"
    )
  ),

  # ---------------------------------------------------------------------------
  # 37. Renal hypouricaemia (SLC22A12, SLC2A9, XDH)
  # ---------------------------------------------------------------------------
  RenalHypouricaemia = list(
    label     = "Renal hypouricaemia / xanthinuria (SLC22A12, SLC2A9, XDH)",
    genes     = c("SLC22A12", "SLC2A9", "XDH", "XDH"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.85,
      Heterozygous = 0.04
    ),
    features = list(
      list(id="hypouricaemia",       label="Very low or undetectable serum uric acid (<1 mg/dL)",
           lr_present=25.0, lr_absent=0.02, key=TRUE),
      list(id="exercise_aki",        label="Exercise-induced acute kidney injury",
           lr_present=20.0, lr_absent=NULL, key=FALSE),
      list(id="uric_acid_stones_hypo", label="Uric acid or xanthine urolithiasis",
           lr_present=10.0, lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "This condition causes LOW uric acid — the opposite of gout/Lesch-Nyhan. A P/LP SLC22A12 or SLC2A9 variant returned in a patient with hyperuricaemia or gout is likely incidental",
      "XDH biallelic → xanthinuria type 1 (xanthine stones, very low uric acid)"
    ),
    references = c(
      "Ichida K et al. Nat Genet 2004;36:1238-1241"
    )
  ),

  # ---------------------------------------------------------------------------
  # 38. Cystinuria (SLC3A1, SLC7A9)
  # ---------------------------------------------------------------------------
  Cystinuria = list(
    label     = "Cystinuria (SLC3A1, SLC7A9)",
    genes     = c("SLC3A1", "SLC7A9"),
    inheritance      = "AR",
    zygosity_options = c("Biallelic", "Heterozygous"),
    prior = c(
      Biallelic    = 0.88,
      Heterozygous = 0.10   # SLC7A9 het can cause milder cystinuria (type B)
                            # UNCERTAIN: exact penetrance of SLC7A9 het
    ),
    features = list(
      list(id="cystine_stones",     label="Recurrent cystine urolithiasis",
           lr_present=25.0, lr_absent=0.04, key=TRUE),
      list(id="hexagonal_crystals", label="Hexagonal crystals on urine microscopy",
           lr_present=20.0, lr_absent=NULL, key=FALSE),
      list(id="elevated_urinary_cystine", label="Elevated urinary cystine on amino acid screen",
           lr_present=25.0, lr_absent=0.04, key=FALSE),
      list(id="childhood_stones",   label="Onset of stones in childhood or adolescence",
           lr_present=8.0,  lr_absent=NULL, key=FALSE)
    ),
    flags = c(
      "SLC7A9 heterozygotes (type B cystinuria) can have elevated urinary cystine and occasional stones — het prior of 0.10 reflects this",
      "Cystinuria does not cause CKD directly unless obstructive nephropathy develops — if P/LP variant found in patient with ESKD without stone history, reconsider"
    ),
    references = c(
      "Dello Strologo L et al. J Nephrol 2002;15:44-49"
    )
  )

)

# =============================================================================
# Gene → Condition mapping
# Allows tool to identify condition group from gene symbol entered by user
# =============================================================================
gene_to_condition <- local({
  mapping <- list()
  for (cond_id in names(variant_conditions)) {
    cond <- variant_conditions[[cond_id]]
    for (gene in cond$genes) {
      if (is.null(mapping[[gene]])) {
        mapping[[gene]] <- cond_id
      } else {
        mapping[[gene]] <- c(mapping[[gene]], cond_id)
      }
    }
  }
  mapping
})
# COL4A3 and COL4A4 intentionally map to TWO conditions: AlportAR (biallelic)
# and COL4het (heterozygous). The UI must disambiguate by zygosity:
#   Biallelic → AlportAR
#   Heterozygous → COL4het

# =============================================================================
# Verdict thresholds and labels
# =============================================================================
variant_verdict <- function(posterior) {
  if (posterior >= 0.75) {
    list(
      label = "Phenotype strongly supports this variant as causative",
      colour = "success",
      detail = "The clinical features are highly consistent with this genetic diagnosis."
    )
  } else if (posterior >= 0.50) {
    list(
      label = "Phenotype is consistent with this variant being causative",
      colour = "warning",
      detail = "The clinical features support this diagnosis, but specialist genetics review is advised before clinical decisions are made."
    )
  } else if (posterior >= 0.25) {
    list(
      label = "Phenotype partially supports this variant — specialist review recommended",
      colour = "warning",
      detail = "Some clinical features are consistent but the overall picture is not typical. Do not act on this result without specialist genetics input."
    )
  } else {
    list(
      label = "Phenotype is inconsistent with this variant as the primary diagnosis",
      colour = "danger",
      detail = "The clinical features do not fit the expected phenotype for this gene. Seek specialist genetics review before acting on this result. The variant may be incidental to the presenting condition."
    )
  }
}

# =============================================================================
# Zygosity display labels
# =============================================================================
zygosity_labels <- c(
  Heterozygous        = "Heterozygous (one copy, monoallelic)",
  Biallelic           = "Biallelic (homozygous or compound heterozygous)",
  Hemizygous_male     = "Hemizygous (male, X-linked)",
  Heterozygous_female = "Heterozygous carrier (female, X-linked)"
)
