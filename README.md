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

**Windows (PowerShell, per session):**
```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
```

**Windows (permanent, via System Properties → Environment Variables):**
Add `ANTHROPIC_API_KEY` as a User variable.

**macOS / Linux:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Or add the line to your `.Renviron` file:
```
ANTHROPIC_API_KEY=sk-ant-...
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
├── app.R                  # Main Shiny app (ui + server)
├── data/
│   ├── panels.R           # NHS GT Directory panel definitions (R187–R370)
│   └── bayes_params.R     # Prior probabilities, likelihood ratios, modifiers
├── R/
│   ├── hpo_extract.R      # Anthropic API call — HPO term extraction
│   ├── eligibility.R      # Panel eligibility scoring logic
│   └── bayes.R            # Bayesian posterior calculation + Plotly chart
└── README.md
```

---

## How to update panel criteria

Open `data/panels.R`. Each panel is an entry in the `renal_panels` named list. To update:

1. **Add a new panel:** Copy an existing panel block, change the code (e.g. `R999`), and update all fields.
2. **Modify criteria:** Edit the `major_criteria` or `supportive_criteria` lists. Each criterion has:
   - `description` — shown to the user in the results table
   - `parameter` — which input drives the check (`"hpo_terms"`, `"age"`, `"proteinuria"`, `"haematuria"`, `"family_history"`, `"extra_renal"`, `"egfr"`, `"consanguinity"`, or `"free_text"` for criteria only assessable from the vignette)
   - `value` — the matching value(s)
3. **Update HPO relevance:** Add/remove HPO IDs from the `hpo_relevant` vector.

---

## How to update Bayesian parameters

Open `data/bayes_params.R`:

- **Priors** (`condition_priors`): Population prevalence estimates. Update as new epidemiological data emerge.
- **Likelihood ratios** (`hpo_lr_positive`): Add new HPO terms or adjust LR values. Each entry needs a value for every condition in `condition_priors`.
- **Negative LRs** (`hpo_lr_negative`): Only for KEY terms (those with `key = TRUE`). Update when absent findings meaningfully change probability.
- **Modifiers** (`family_history_modifiers`, `consanguinity_modifiers`, `age_modifier`): Adjust the multipliers applied before HPO-based updating.

---

## Clinical caveats

- **Not validated for clinical use.** Posterior probabilities are decision-support estimates derived from approximated likelihood ratios.
- Panel criteria are sourced from **NHS Rare & Inherited Disease Eligibility Criteria v9** and PanelApp Genomics England. Check [PanelApp](https://panelapp.genomicsengland.co.uk) for current gene lists and criteria.
- HPO extraction depends on the Anthropic API. Review extracted terms before running analysis — remove irrelevant terms and add missing ones.
- The Bayesian model assumes conditional independence of HPO features given the diagnosis, which is a simplification.
- Always refer patients to a clinical genetics service for formal assessment and testing.

---

## Key literature

- Groopman EE et al. Diagnostic Utility of Exome Sequencing for Kidney Disease. *NEJM* 2019;380:142–151
- Connaughton DM et al. Monogenic causes of CKD. *JASN* 2019;30:2088–2107
- Savige J et al. Alport syndrome. *Kidney Int* 2022;101:717–729
- Vivante A, Hildebrandt F. Exploring the genetic basis of CKD. *Nat Rev Nephrol* 2016;12:133–146
- Cornec-Le Gall E et al. ADPKD. *Lancet* 2019;393:919–935
