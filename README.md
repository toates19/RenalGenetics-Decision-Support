# RenalGenetics Decision Support

An R Shiny decision-support tool for non-genetics clinicians managing patients with suspected inherited renal conditions.

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
shiny::runApp("path/to/Genetics_app")
```

Or open `app.R` in RStudio and click **Run App**.

---

## File structure

```
Genetics_app/
├── app.R                    # Main Shiny app (ui + server)
├── data/
│   ├── panels.R             # NHS GT Directory panel definitions (R193–R446)
│   ├── bayes_params.R       # Prior probabilities, likelihood ratios, modifiers
│   └── strict_criteria.R    # NHS eligibility criteria (Layer 1 strict gate)
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

The sidebar is organised into seven collapsible sections. Fill in as many as are relevant — Run Analysis is always available and does not require HPO term extraction.

| Section | Key inputs |
|---------|-----------|
| Demographics | Age, sex |
| Renal presentation | eGFR, proteinuria level, haematuria |
| Investigations | Biopsy findings (FSGS/DMS, Alport, thin BM, TIKD fibrosis, C3G/MPGN) |
| Family history & ancestry | Inheritance pattern, consanguinity, Cypriot/Mediterranean or African/Caribbean/Brazilian ancestry |
| Extra-renal features | Hearing loss, ocular abnormality, liver cysts, early hypertension, etc. |
| Clinical context | Transplant consideration, complement therapy, management indication, kidney donor assessment, APOL1 consent |
| Clinical vignette *(optional)* | Free-text summary — paste to extract HPO terms for Bayesian scoring |

HPO term extraction uses the Anthropic API. Review extracted terms, remove irrelevant ones, and add missing ones manually before running analysis. If no vignette is provided the Bayesian chart still runs using age, family history and consanguinity modifiers.

---

## How the eligibility scoring works

Eligibility is assessed in two layers:

**Layer 1 — Strict NHS criteria** (`data/strict_criteria.R`)

Each panel has `required` criteria (ALL must be met) and `any_of` criteria (at least ONE must be met), derived directly from the NHS Rare & Inherited Disease Eligibility Criteria. Nearly all criteria are now assessable from the structured form inputs, including biopsy findings, ancestry, and clinical context. Any remaining non-assessable criteria (e.g. "no identifiable cause" for R257, expert-centre tubulopathy for R198) are shown as amber advisory items.

Layer 1 result: `met` / `partial` / `not_met`.

**Layer 2 — HPO and structured parameter matching** (`data/panels.R`, `R/eligibility.R`)

Scores how many of the panel's `major_criteria` are satisfied by confirmed HPO terms and structured inputs, and counts overlap with the panel's `hpo_relevant` HPO list.

**Final verdict:**
- `not_met` at Layer 1 → **Unlikely eligible**
- Layer 1 passed + (≥2 major criteria met OR ≥3 HPO overlaps) → **Likely eligible**
- Layer 1 passed + (≥1 major criterion met OR ≥1 HPO overlap) → **Possibly eligible**
- Layer 1 partial/met, no HPO support → **Possibly eligible**

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

## Bayesian model — conditions modelled (10)

| Condition | Key genes |
|-----------|-----------|
| ADPKD | PKD1, PKD2 |
| ARPKD | PKHD1 |
| Alport syndrome | COL4A3, COL4A4, COL4A5 |
| Genetic FSGS / SRNS | NPHS1, NPHS2, INF2 |
| CAKUT | PAX2, HNF1B, ROBO2 |
| Inherited tubulopathy | SLC12A3, CLCNKB, UMOD |
| Atypical HUS | CFH, CFI, C3, CD46 |
| Tubulointerstitial kidney disease | UMOD, MUC1, REN |
| Hereditary amyloidosis | TTR, APOA1, GSN |
| C3 glomerulopathy / MPGN | CFH, C3, CFHR5 |

Posterior probabilities are updated from population priors using likelihood ratios for confirmed HPO terms, plus modifiers for family history pattern, consanguinity, and age at presentation.

---

## How to update panel criteria

Open `data/panels.R`. Each panel is an entry in the `renal_panels` named list:

- **Add a new panel:** Copy an existing block, change the code, and update all fields.
- **Update gene lists:** Replace the `genes` vector. Source TSV files from PanelApp; filter to `GEL_Status == 3` (green).
- **Update strict criteria:** Edit `data/strict_criteria.R`. Each criterion needs `description`, `parameter`, `value`, and `assessable` fields. Supported parameters: `"hpo_terms"`, `"age"`, `"egfr"`, `"proteinuria"`, `"haematuria"`, `"family_history"`, `"extra_renal"`, `"biopsy_results"`, `"ancestry"`, `"clinical_context"`, `"free_text"`.
- **Modify HPO-level criteria:** Edit the `major_criteria` list in `data/panels.R`. Uses the same parameter names (except `biopsy_results`, `ancestry`, `clinical_context` which are Layer 1 only).
- **Add a new biopsy finding, ancestry, or clinical context option:** Add the choice string to both the `checkboxGroupInput` in `app.R` and the `value` field of the relevant criterion in `data/strict_criteria.R`. The strings must match exactly.

---

## How to update Bayesian parameters

Open `data/bayes_params.R`:

- **Priors** (`condition_priors`): Population prevalence estimates.
- **Likelihood ratios** (`hpo_lr_positive`): Each HPO entry needs a value for all 10 conditions. Set `key = TRUE` for terms where absence is also informative.
- **Negative LRs** (`hpo_lr_negative`): Only required for `key = TRUE` terms.
- **Modifiers** (`family_history_modifiers`, `consanguinity_modifiers`, `age_modifier`): Multipliers applied before HPO updating.

---

## Clinical caveats

- **Not validated for clinical use.** Posterior probabilities are decision-support estimates derived from approximated likelihood ratios.
- Panel criteria are sourced from **NHS Rare & Inherited Disease Eligibility Criteria v9** and PanelApp Genomics England. Always check [PanelApp](https://panelapp.genomicsengland.co.uk) for current gene lists and criteria.
- HPO extraction uses the Anthropic API (`claude-sonnet-4-5`) and requires `ANTHROPIC_API_KEY` to be set. It is optional — the eligibility table is fully functional without it.
- All strict criteria for biopsy findings, ancestry, and clinical context are now captured via the structured form; very few criteria remain non-assessable.
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
