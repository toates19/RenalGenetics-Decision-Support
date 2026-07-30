# RenalGenetics Decision Support

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21622189.svg)](https://doi.org/10.5281/zenodo.21622189)

An R Shiny decision-support tool for non-genetics clinicians managing patients with suspected inherited renal conditions. The app has three integrated modules:

1. **NHS GT Directory eligibility** — two-layer scoring against NHS Rare & Inherited Disease criteria for 12 genomic test panels (R193–R446)
2. **Bayesian diagnostic model** — posterior probability ranking across 24 inherited renal conditions, updated by HPO terms, family history, consanguinity, age, sex, and biopsy findings
3. **Variant interpretation** — phenotype-informed causativity assessment for P/LP variants returned from panel testing, covering 38 condition groups and 196 genes

---

## Quick start

### Prerequisites

```r
install.packages(c("shiny", "bslib", "shinyWidgets", "plotly",
                   "httr2", "jsonlite", "dplyr"))
```

### Set your Anthropic API key

Add the following line to your `.Renviron` file (run `usethis::edit_r_environ()` to open it):
```
ANTHROPIC_API_KEY=sk-ant-...
```

**Windows (per session in RStudio console):**
```r
Sys.setenv(ANTHROPIC_API_KEY = "sk-ant-...")
```

### Run the app

```r
shiny::runApp("path/to/RenalGenetics-Decision-Support")
```

Or open `app.R` in RStudio and click **Run App**.

A hosted version is available at: **https://toates19.shinyapps.io/RenalGenetics/**

---

## File structure

```
RenalGenetics-Decision-Support/
├── app.R                    # Main Shiny app (ui + server)
├── data/
│   ├── panels.R             # NHS GT Directory panel definitions (R193–R446)
│   ├── bayes_params.R       # Prior probabilities, likelihood ratios, modifiers
│   ├── strict_criteria.R    # NHS eligibility criteria (Layer 1 strict gate)
│   └── variant_interp.R     # Variant interpretation module — 38 condition groups
├── R/
│   ├── hpo_extract.R        # Anthropic API call — HPO term extraction
│   ├── eligibility.R        # Two-layer eligibility scoring logic
│   └── bayes.R              # Bayesian posterior calculation + Plotly chart
├── Gene_lists/              # PanelApp TSV exports (green-rated genes)
├── Test_criteria.csv        # Source NHS eligibility criteria text
└── README.md
```

---

## How to use the app

The sidebar is organised into three fixed sections plus dynamic branch sections that appear based on the patient's presentation.

### 1 — Patient details (always visible)

Age, sex, eGFR, family history pattern, consanguinity, and early-onset hypertension. These fields feed every panel and every Bayesian modifier, so they are always shown.

### 2 — Primary presentation picker

A multi-select checklist. Tick **all** that apply to the patient — the app then renders only the relevant branch sections below. Selecting multiple presentations shows the union of their questions, so a patient with both haematuria and heavy proteinuria gets both branches.

| Presentation | Panels triggered | Branch-specific inputs |
|---|---|---|
| Cysts on imaging | R193 | Liver cysts |
| Haematuria | R194, R196 | Haematuria type, biopsy (Alport / TBMD), hearing loss, ocular signs, Cypriot ancestry |
| Proteinuria / nephrotic syndrome | R195, R197 | Proteinuria level, biopsy (FSGS, C3G/MPGN) |
| Tubulopathy or kidney stones | R198, R256 | Electrolyte / tubular pattern (8 options) |
| Unexplained renal impairment / early ESKD | R202, R257 | Biopsy (TIKD) |
| Systemic features (aHUS or amyloidosis) | R201, R204 | TMA triad (AKI, thrombocytopenia, MAHA), cardiomyopathy, neuropathy |
| Kidney donor assessment (APOL1) | R446 | African / Caribbean / Brazilian ancestry |

### 3 — Clinical context (always visible, collapsible)

Management indication, transplant, complement therapy, donor assessment, APOL1 consent.

### 4 — Clinical vignette *(optional)*

Paste a free-text summary to extract HPO terms via the Anthropic API. Extracted terms can be reviewed, removed, or supplemented manually. The vignette is entirely optional — all eligibility criteria and the Bayesian model are fully populated from the structured inputs alone.

Run Analysis is always available and requires no minimum input.

---

## How the eligibility scoring works

Eligibility is assessed in two layers:

**Layer 1 — Strict NHS criteria** (`data/strict_criteria.R`)

Each panel has `required` criteria (ALL must be met) and `any_of` criteria (at least ONE must be met), derived directly from the NHS Rare & Inherited Disease Eligibility Criteria. All criteria are assessable from structured inputs. Any non-assessable criteria (e.g. "no identifiable cause" for R257, expert-centre tubulopathy for R198) are shown as amber advisory items.

Layer 1 result: `met` / `partial` / `not_met`.

**Layer 2 — HPO and structured parameter matching** (`data/panels.R`, `R/eligibility.R`)

Scores how many of the panel's `major_criteria` are satisfied by confirmed HPO terms and structured inputs, and counts overlap with the panel's `hpo_relevant` HPO list.

**Final verdict:**
- `not_met` at Layer 1 → **Unlikely eligible**
- Layer 1 passed + (≥2 major criteria met OR ≥3 HPO overlaps) → **Likely eligible**
- Layer 1 passed + (≥1 major criterion met OR ≥1 HPO overlap) → **Possibly eligible**
- Layer 1 partial/met, no HPO support → **Possibly eligible**

---

## How HPO terms are derived

`R/bayes.R` contains `derive_all_hpo_from_inputs()`, which maps every structured input to HPO IDs automatically. These auto-derived IDs are merged with any vignette-extracted HPO terms and passed to **both** the eligibility scorer and the Bayesian model. The mappings cover:

| Input | HPO IDs derived |
|---|---|
| Cysts on imaging (presentation) | HP:0000113, HP:0005584 |
| Microscopic / macroscopic haematuria | HP:0000790 |
| Sub-nephrotic proteinuria | HP:0000093 |
| Nephrotic-range proteinuria | HP:0000093, HP:0000100 |
| eGFR < 60 | HP:0012622 |
| eGFR < 15 | HP:0003774 |
| Hearing loss | HP:0000407 |
| Ocular abnormality | HP:0000504 |
| Liver cysts | HP:0001407 |
| Hypertension <35 yrs | HP:0000822 |
| Hypokalaemia with alkalosis | HP:0002900, HP:0001942 |
| Hypokalaemia with acidosis (RTA/Fanconi) | HP:0002900 |
| Hyperkalaemia with acidosis | HP:0002153 |
| Hypomagnesaemia | HP:0002917 |
| Nephrogenic diabetes insipidus | HP:0000863 |
| Hypercalciuria | HP:0002150 |
| Nephrocalcinosis | HP:0000121 |
| Nephrolithiasis | HP:0000787 |
| AKI / acute renal failure | HP:0001919 |
| Thrombocytopenia | HP:0001873 |
| MAHA (Coombs negative) | HP:0001903, HP:0001878, HP:0005575 |
| Restrictive cardiomyopathy | HP:0001638 |
| Peripheral / autonomic neuropathy | HP:0001271 |

This means R198 (tubulopathy), R201 (aHUS), and R204 (amyloidosis) strict criteria are fully assessable from the structured form without requiring HPO extraction.

---

## Panels covered (12)

| Code | Condition |
|------|-----------|
| R193 | Cystic renal disease |
| R194 | Haematuria (hereditary nephritis / Alport) |
| R195 | Steroid-resistant nephrotic syndrome / FSGS |
| R196 | C3 glomerulopathy (Cypriot ancestry) |
| R197 | Idiopathic MPGN / C3 glomerulopathy |
| R198 | Primary renal tubulopathy |
| R201 | Atypical HUS |
| R202 | Tubulointerstitial kidney disease (TIKD) |
| R204 | Hereditary systemic amyloidosis |
| R256 | Nephrocalcinosis / nephrolithiasis |
| R257 | Early-onset ESKD (under 36) |
| R446 | APOL1 testing (living kidney donors) |

Gene lists sourced from PanelApp Genomics England; only green-rated (GEL_Status = 3) genes are shown.

---

## Bayesian model — conditions modelled (24)

Each condition is modelled as a separate entity with its own prior, likelihood ratios, and modifiers. Gene-level splits allow the model to discriminate between subtypes that differ in age of onset, sex effect, and family history pattern.

| Condition | Key gene(s) | Notes |
|-----------|-------------|-------|
| ADPKD — PKD1 | *PKD1* | ~78% of ADPKD; earlier onset, more severe |
| ADPKD — PKD2 | *PKD2* | ~18% of ADPKD; later onset, milder course |
| ARPKD | *PKHD1* | Recessive; typically presents in childhood |
| Alport — X-linked | *COL4A5* | ~85% of Alport; X-linked, affects males most severely |
| Alport — biallelic | *COL4A3/COL4A4* | ~15% of Alport; autosomal recessive or dominant |
| COL4 heterozygote | *COL4A3/COL4A4* | Thin basement membrane nephropathy / carrier state; prior 1/106 |
| FSGS/SRNS — NPHS1 | *NPHS1* | Congenital nephrotic syndrome (nephrin) |
| FSGS/SRNS — NPHS2 | *NPHS2* | Childhood SRNS (podocin) |
| FSGS/SRNS — INF2 | *INF2* | AD FSGS; often with Charcot-Marie-Tooth |
| Gitelman syndrome | *SLC12A3* | Most common hereditary tubulopathy |
| Bartter syndrome | *CLCNKB, SLC12A1, KCNJ1* | Includes pseudohypoaldosteronism (bundled) |
| Distal RTA | *ATP6V1B1, ATP6V0A4, SLC4A1* | Autosomal recessive and dominant forms |
| Primary hyperoxaluria | *AGXT, GRHPR, HOGA1* | Types 1–3; nephrocalcinosis / nephrolithiasis |
| Congenital nephrogenic DI | *AVPR2, AQP2* | X-linked (AVPR2) and AR (AQP2) |
| aHUS — CFH | *CFH* | ~30% of genetic aHUS |
| aHUS — CD46/MCP | *CD46* | ~15% of genetic aHUS; predominantly paediatric |
| aHUS — CFI | *CFI* | ~8% of genetic aHUS |
| aHUS — C3/CFB | *C3, CFB* | ~10% of genetic aHUS |
| Tubulointerstitial kidney disease | *UMOD, MUC1, REN* | ADTKD; often with hyperuricaemia/gout |
| Amyloidosis — TTR | *TTR* | ~90% of hereditary systemic amyloidosis |
| Amyloidosis — APOA1 | *APOA1* | Renal and hepatic amyloid |
| Amyloidosis — Gelsolin | *GSN* | Finnish-type; corneal lattice dystrophy |
| C3 glomerulopathy / MPGN | *CFH, C3, CFHR5* | Includes CFHR5 nephropathy (Cypriot ancestry) |
| No genetic diagnosis | — | Calibration condition (~85% prior at baseline) |

CAKUT is intentionally excluded from the Bayesian model. There is no dedicated NHS GT Directory CAKUT panel; genes implicated in CAKUT (PAX2, HNF1B, EYA1, SALL1, RET etc.) are covered by the R257 super-panel. Structural anomaly HPO terms (hydronephrosis, renal dysplasia, horseshoe kidney, VUR) therefore feed R257 eligibility scoring rather than a separate Bayesian condition.

Posterior probabilities are updated from population priors using likelihood ratios for confirmed HPO terms, plus modifiers for family history pattern, consanguinity, age at presentation, sex (Alport XL vs AR discrimination), and biopsy findings (GBM splitting/lamellation, thin basement membrane, FSGS, C3G/MPGN, tubulointerstitial pattern).

**Display:** Output is split into two parts so "is this likely genetic at all" doesn't get conflated with "which condition." A headline stat gives the estimated probability of a modelled genetic cause (`1 − posterior(NoGenetic)`) — this is the one place an exact percentage is shown, since it's a coarse two-way split rather than a 24-way ranking and is more defensible at that precision. Below it, the chart shows the remaining 23 conditions renormalised to sum to 1, ranked by relative posterior *conditional on* a modelled genetic cause being present. Numeric percentages are intentionally not displayed on the chart itself — bar length conveys relative magnitude only; hover shows rank. This split is designed to sit next to the eligibility table above it, so a clinician can compare "eligibility: unlikely" against "estimated probability of genetic cause: X%" directly, rather than inferring the latter from bar length in a single mixed ranking.

---

## Variant interpretation module

`data/variant_interp.R` provides the data layer for a second Bayesian module that addresses a different question: **given that a P/LP variant has been identified in a gene, how likely is it to be causative for this patient's phenotype?**

This is distinct from the eligibility/diagnostic probability model above, which asks whether a patient is likely to have an inherited renal condition at all.

The module covers **38 condition groups** spanning the full breadth of inherited renal disease (not limited to the 12 NHS GT Directory panels):

| Group | Key genes |
|-------|-----------|
| ADPKD | *PKD1, PKD2, GANAB, DNAJB11* + others |
| ARPKD | *PKHD1* |
| Nephronophthisis | *NPHP1, NPHP3, NPHP4, CEP290* + others |
| Bardet-Biedl syndrome | *BBS1, BBS2, BBS4* + others |
| Joubert syndrome | *AHI1, CEP290, INPP5E* + others |
| Alport — X-linked | *COL4A5* |
| Alport — biallelic | *COL4A3, COL4A4* |
| COL4 heterozygote | *COL4A3, COL4A4* |
| COL4A1 disease | *COL4A1* |
| Congenital nephrotic syndrome (AR) | *NPHS1, NPHS2, LAMB2, CD2AP* + others |
| WT1-related disease | *WT1* |
| AD FSGS | *ACTN4, TRPC6, INF2, MYO1E* + others |
| Nucleoporin SRNS | *NUP107, NUP133, NUP85, NUP93* + others |
| Tubulointerstitial kidney disease | *UMOD, MUC1, REN, SEC61A1* |
| Gitelman syndrome | *SLC12A3, CLDN16, CLDN19* + others |
| Bartter syndrome | *CLCNKB, BSND, SLC12A1, KCNJ1* + others |
| Distal RTA | *ATP6V0A4, ATP6V1B1, SLC4A1, CA2* |
| Primary hyperoxaluria | *AGXT, GRHPR, HOGA1* + others |
| Dent disease | *CLCN5, OCRL* |
| Nephrogenic DI | *AVPR2, AQP2* |
| aHUS | *CFH, CFI, C3, CFB, CD46, DGKE* + others |
| C3 glomerulopathy | *CFHR5, CFH, CFI, C3* + others |
| Amyloidosis | *TTR, APOA1, GSN, LYZ, FGA* + others |
| Tuberous sclerosis | *TSC1, TSC2* |
| Fabry disease | *GLA* |
| Cystinosis | *CTNS* |
| HNF1B disease | *HNF1B* |
| PAX2-related disease | *PAX2* |
| Branchio-oto-renal syndrome | *EYA1* |
| CAKUT (other) | *SALL1, RET, GATA3, FRAS1* + others |
| Alström syndrome | *ALMS1* |
| Nail-patella syndrome | *LMX1B* |
| VHL disease | *VHL* |
| Birt-Hogg-Dubé | *FLCN* |
| Renal tubular dysgenesis | *ACE, AGT, AGTR1* |
| Lesch-Nyhan disease | *HPRT1, MOCOS* |
| Renal hypouricaemia | *SLC22A12, SLC2A9* |
| Cystinuria | *SLC3A1, SLC7A9* |

Each group defines:
- **Prior probability** that a P/LP-classified variant is causative given zygosity (baking in lab classification accuracy, penetrance, and baseline phenotype-gene concordance)
- **Phenotypic feature likelihood ratios** (`lr_present` / `lr_absent`) for discriminating features
- **Clinical flags** marking parameters with meaningful uncertainty, for expert review

### Using the variant interpretation module

The module is on the **Variant Interpretation** tab in the right panel (alongside **Diagnostic Assessment**).

1. Enter a gene symbol and click **Look up** — the tool identifies the condition group. Genes mapping to multiple conditions (e.g. *COL4A3/COL4A4*, which can cause biallelic Alport or monoallelic COL4 het disease) prompt a condition picker.
2. Select the variant **zygosity** from the options available for that condition.
3. For each phenotypic feature, toggle **Present**, **Absent**, or **Not assessed**. Absence updates the posterior only where `lr_absent` is defined (shown as "key" features or with an informative absence note).
4. Click **Assess Variant**.

The posterior is computed via log-odds Bayesian update: prior odds × product of applicable LRs. The result shows prior → posterior, a colour-coded verdict (≥75% strongly supports; 50–75% consistent; 25–50% partial / review; <25% inconsistent), an expandable feature contributions table, clinical flags, and key references.

**Posterior probabilities assume the variant has been robustly classified P/LP by the reporting laboratory.** This module does not replace genetics specialist review.

---

## How to update panel criteria

Open `data/panels.R`. Each panel is an entry in the `renal_panels` named list:

- **Add a new panel:** Copy an existing block, change the code, and update all fields.
- **Update gene lists:** Replace the `genes` vector. Source TSV files from PanelApp; filter to `GEL_Status == 3` (green).
- **Update strict criteria:** Edit `data/strict_criteria.R`. Each criterion needs `description`, `parameter`, `value`, and `assessable` fields. Supported parameters: `"hpo_terms"`, `"age"`, `"egfr"`, `"proteinuria"`, `"haematuria"`, `"family_history"`, `"extra_renal"`, `"biopsy_results"`, `"ancestry"`, `"clinical_context"`, `"free_text"`.
- **Modify HPO-level criteria:** Edit the `major_criteria` list in `data/panels.R`. Uses the same parameter names (except `biopsy_results`, `ancestry`, `clinical_context` which are Layer 1 only).
- **Add a new biopsy finding, ancestry, or clinical context option:** Add the choice string to the relevant `checkboxGroupInput` in `app.R` (inside `output$branch_sections`) and to the `value` field of the criterion in `data/strict_criteria.R`. Strings must match exactly.
- **Add a new branch-specific HPO mapping:** Add the input choice to the `checkboxGroupInput` in `app.R` and the corresponding HPO mapping to `derive_all_hpo_from_inputs()` in `R/bayes.R`.

---

## How to update Bayesian parameters

Open `data/bayes_params.R`:

- **Priors** (`condition_priors`): Population prevalence estimates.
- **Likelihood ratios** (`hpo_lr_positive`): Each HPO entry needs a value for all modelled conditions. Set `key = TRUE` for terms where absence is also informative.
- **Negative LRs** (`hpo_lr_negative`): Only required for `key = TRUE` terms.
- **Modifiers** (`family_history_modifiers`, `consanguinity_modifiers`, `age_modifier`): Multipliers applied before HPO updating.

---

## Clinical caveats

- **Not validated for clinical use.** Posterior probabilities are decision-support estimates derived from approximated likelihood ratios.
- Panel criteria are sourced from **NHS Rare & Inherited Disease Eligibility Criteria v9** and PanelApp Genomics England. Always check [PanelApp](https://panelapp.genomicsengland.co.uk) for current gene lists and criteria.
- HPO extraction uses the Anthropic API (`claude-sonnet-4-6`) and requires `ANTHROPIC_API_KEY` to be set. It is optional — all eligibility criteria and the Bayesian model are fully functional without it.
- The Bayesian model assumes conditional independence of HPO features given the diagnosis, which is a simplification.
- Always refer patients to a clinical genetics service for formal assessment and testing.

---

## Key literature

- Groopman EE et al. Diagnostic Utility of Exome Sequencing for Kidney Disease. *NEJM* 2019;380:142–151
- Connaughton DM et al. Monogenic causes of CKD. *JASN* 2019;30:2088–2107
- Savige J et al. Alport syndrome. *Kidney Int* 2022;101:717–729
- Vivante A, Hildebrandt F. Exploring the genetic basis of CKD. *Nat Rev Nephrol* 2016;12:133–146
- Cornec-Le Gall E et al. ADPKD. *Lancet* 2019;393:919–935
- Eckardt KU et al. Autosomal dominant tubulointerstitial kidney disease. *Nat Rev Nephrol* 2015;11:617–625
- Wechalekar AD et al. Systemic amyloidosis. *Lancet* 2016;387:2641–2654
- Nester CM et al. C3 glomerulopathy. *Nephrol Dial Transplant* 2018;33:i1–i7
