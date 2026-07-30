library(shiny)
library(bslib)
library(shinyWidgets)
library(plotly)
library(httr2)
library(jsonlite)
library(dplyr)

# Load data and logic
source("data/panels.R")
source("data/bayes_params.R")
source("data/strict_criteria.R")
source("R/hpo_extract.R")
source("R/eligibility.R")
source("R/bayes.R")
source("data/variant_interp.R")

# ── Variant interpretation posterior computation ───────────────────────────────
compute_vi_posterior <- function(cond, zygosity, feature_states) {
  prior <- as.numeric(cond$prior[zygosity])
  if (is.na(prior)) return(NULL)
  prior    <- max(0.001, min(0.999, prior))
  log_odds <- log(prior / (1 - prior))
  contribs <- list()

  for (feat in cond$features) {
    state <- feature_states[[feat$id]]
    if (is.null(state) || state == "Not assessed") next
    if (state == "Present" && !is.null(feat$lr_present)) {
      lr       <- feat$lr_present
      log_odds <- log_odds + log(lr)
      contribs <- c(contribs, list(list(label = feat$label, state = "Present", lr = lr)))
    } else if (state == "Absent" && !is.null(feat$lr_absent)) {
      lr       <- feat$lr_absent
      log_odds <- log_odds + log(lr)
      contribs <- c(contribs, list(list(label = feat$label, state = "Absent", lr = lr)))
    }
  }

  posterior <- exp(log_odds) / (1 + exp(log_odds))
  posterior <- max(0.001, min(0.999, posterior))
  list(prior = prior, posterior = posterior, contributions = contribs)
}

# ── Theme ─────────────────────────────────────────────────────────────────────
app_theme <- bs_theme(
  version      = 5,
  bootswatch   = "flatly",
  primary      = "#1a6fa8",
  secondary    = "#4a6fa5",
  bg           = "#f4f7fb",
  fg           = "#1c2a3a",
  font_scale   = 0.95,
  `navbar-bg`  = "#1a6fa8"
) |>
  bs_add_rules("
    .card { border:1px solid #d1dce8; box-shadow:0 1px 4px rgba(26,111,168,.08); }
    .card-header { background:#1a6fa8; color:#fff; font-weight:600; font-size:.9rem; }
    .hpo-badge { display:inline-flex; align-items:center; gap:4px;
                 background:#e8f1fa; border:1px solid #a8c4e0; color:#1a6fa8;
                 border-radius:20px; padding:3px 10px; margin:3px; font-size:.82rem; }
    .hpo-badge.medium { background:#fff8e1; border-color:#ffc107; color:#7a5800; }
    .hpo-badge.low    { background:#fce8e8; border-color:#e57373; color:#8b1a1a; }
    .hpo-badge button { background:none; border:none; color:inherit;
                        font-size:.85rem; cursor:pointer; padding:0 0 0 2px; line-height:1; }
    .disclaimer-footer { background:#fff3cd; border-top:2px solid #ffc107;
                         padding:12px 20px; font-size:.78rem; color:#5a4200; }
    .section-label { font-weight:600; color:#1a6fa8; font-size:.82rem;
                     text-transform:uppercase; letter-spacing:.04em;
                     margin-top:6px; margin-bottom:4px; }
    .output-placeholder { color:#8a99aa; font-style:italic; text-align:center;
                          padding:40px 0; }
    .criteria-pill { display:inline-block; background:#e8f5e9; border:1px solid #81c784;
                     border-radius:4px; padding:1px 7px; font-size:.78rem;
                     color:#1b5e20; margin:1px; }
    .criteria-pill.unmet   { background:#fce4ec; border-color:#e57373; color:#7f0000; }
    .criteria-pill.unknown { background:#fff8e1; border-color:#ffc107; color:#5a4200; }
    .summary-box { background:#e8f1fa; border-left:4px solid #1a6fa8;
                   padding:10px 14px; border-radius:4px; margin-bottom:12px; }
    /* Collapsible form sections */
    .form-section { border:1px solid #d1dce8; border-radius:6px; margin-bottom:6px; }
    .form-section > summary {
      list-style:none; padding:7px 10px; cursor:pointer;
      font-weight:600; font-size:.82rem; color:#1a6fa8;
      background:#f0f5fb; border-radius:6px;
      display:flex; align-items:center; gap:6px;
    }
    .form-section > summary::-webkit-details-marker { display:none; }
    .form-section[open] > summary { border-radius:6px 6px 0 0; border-bottom:1px solid #d1dce8; }
    .form-section .section-body { padding:8px 10px; }
    details > summary { list-style:none; }
    details > summary::-webkit-details-marker { display:none; }
    /* Presentation picker */
    .pres-picker {
      border:2px solid #1a6fa8; border-radius:6px;
      padding:8px 10px; background:#f0f7ff; margin-bottom:6px;
    }
    .pres-picker .pres-label {
      font-weight:700; font-size:.84rem; color:#1c2a3a;
      margin-bottom:6px; display:block;
    }
    /* Branch sections get a slightly different left border to distinguish them */
    .branch-section { border-left:3px solid #1a6fa8; }
    .branch-section > summary { background:#e8f4fd; }
  ")

# ── Helper: collapsible form section ─────────────────────────────────────────
form_section <- function(icon_char, title, ..., open = FALSE, extra_class = "") {
  cls  <- paste("form-section", extra_class)
  args <- if (open) list(open = NA) else list()
  do.call(tags$details, c(
    args,
    list(
      class = cls,
      tags$summary(icon_char, " ", title),
      tags$div(class = "section-body", ...)
    )
  ))
}

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- page_fillable(
  theme = app_theme,
  title = "RenalGenetics Decision Support",

  tags$nav(
    class = "navbar navbar-expand-lg mb-0",
    style = "background:#1a6fa8; padding:8px 20px;",
    tags$span(
      style = "color:#fff; font-size:1.15rem; font-weight:700; letter-spacing:.02em;",
      "RenalGenetics Decision Support"
    ),
    tags$span(
      style = "color:#c8dff5; font-size:.78rem; margin-left:auto;",
      "For clinical decision support only • Not validated for clinical use"
    )
  ),

  layout_sidebar(
    fillable = TRUE,
    sidebar  = sidebar(
      width = 390,
      open  = TRUE,
      bg    = "#ffffff",
      style = "overflow-y:auto; height:calc(100vh - 56px); padding:10px;",

      # ── Universal patient details (always visible) ─────────────────────────
      form_section("\U1F9D1", "Patient details", open = TRUE,
        fluidRow(
          column(6, numericInput("age", "Age at presentation (yrs)",
                                 value = NA, min = 0, max = 120)),
          column(6, selectInput("sex", "Sex",
                                choices = c("Unknown", "Male", "Female")))
        ),
        numericInput("egfr", "eGFR (ml/min/1.73m²)", value = NA, min = 0, max = 200),
        fluidRow(
          column(6, selectInput("family_history", "Family history",
                                choices = c("None", "Autosomal dominant",
                                            "Autosomal recessive", "X-linked",
                                            "Present but pattern unknown" = "Unknown"))),
          column(6, selectInput("consanguinity", "Consanguinity",
                                choices = c("Unknown", "Yes", "No")))
        ),
        checkboxInput("htn_35", "Hypertension onset <35 years", value = FALSE)
      ),

      # ── Primary presentation picker ────────────────────────────────────────
      tags$div(
        class = "pres-picker",
        tags$span(class = "pres-label",
                  "\U1F50D  Primary presentation(s) — tick all that apply"),
        checkboxGroupInput("presentation", label = NULL,
          choices = c(
            "Cysts on imaging",
            "Haematuria",
            "Proteinuria / nephrotic syndrome",
            "Tubulopathy or kidney stones",
            "Unexplained renal impairment / early ESKD",
            "Systemic features (aHUS or amyloidosis)",
            "Kidney donor assessment (APOL1)"
          ),
          selected = character(0)
        )
      ),

      # ── Branch-specific sections (rendered dynamically) ────────────────────
      uiOutput("branch_sections"),

      # ── Clinical context (always visible) ─────────────────────────────────
      form_section("\U1F3E5", "Clinical context",
        tags$p(style = "font-size:.8rem; color:#6c757d; margin-bottom:6px;",
               "Tick all that apply to this patient’s situation."),
        checkboxGroupInput("clinical_context", label = NULL,
          choices = c(
            "Genetic diagnosis required for management",
            "Renal transplant being considered",
            "Complement inhibitory therapy being considered",
            "Being assessed for living kidney donation",
            "Counselled and consented for APOL1 testing"
          ),
          selected = character(0)
        )
      ),

      # ── Clinical vignette (optional, HPO extraction) ───────────────────────
      form_section("\U1F4DD", "Clinical vignette (optional — HPO extraction)",
        tags$p(style = "font-size:.8rem; color:#6c757d; margin-bottom:6px;",
               "Paste a free-text summary to extract additional HPO terms for Bayesian scoring."),
        tags$textarea(
          id          = "vignette",
          class       = "form-control shiny-input-text-area",
          placeholder = "e.g. 32-year-old man with microscopic haematuria, sensorineural hearing loss and family history of renal failure…",
          rows        = 4,
          style       = "font-size:.85rem;"
        ),
        tags$p(
          style = "font-size:.78rem; color:#856404; background:#fff3cd; border:1px solid #ffc107; border-radius:4px; padding:6px 8px; margin-top:6px; margin-bottom:4px;",
          "⚠️ Do not enter real patient identifiers — vignette text is sent to an external AI API (Anthropic) for HPO extraction."
        ),
        actionButton("extract_hpo", "Extract HPO Terms",
                     class = "btn btn-outline-primary btn-sm w-100 mt-2",
                     icon  = icon("dna"))
      ),

      # ── HPO confirmation (appears after extraction) ────────────────────────
      uiOutput("hpo_section"),

      # ── Run Analysis ───────────────────────────────────────────────────────
      tags$div(
        style = "margin-top:10px;",
        actionButton("run_analysis", "Run Analysis",
                     class = "btn btn-success w-100",
                     icon  = icon("magnifying-glass-chart"))
      )
    ),

    # ── Tabbed output area ─────────────────────────────────────────────────────
    navset_tab(
      id = "main_tabs",

      # ── Tab 1: Diagnostic Assessment ───────────────────────────────────────
      nav_panel(
        title = "Diagnostic Assessment",
        icon  = icon("chart-bar"),
        div(
          style = "overflow-y:auto; height:calc(100vh - 100px); padding:16px;",
          uiOutput("output_section"),
          tags$div(
            class = "disclaimer-footer mt-auto",
            tags$strong("Disclaimers: "),
            tags$ul(
              style = "margin:4px 0 0 0; padding-left:18px;",
              tags$li("This tool is for decision support only and does not replace clinical judgement or formal genetics referral."),
              tags$li("Panel criteria based on NHS Rare & Inherited Disease Eligibility Criteria v9 and PanelApp Genomics England."),
              tags$li("Likelihood ratios are approximations from published literature; posterior probabilities are estimates only."),
              tags$li("Developed for educational and clinical aid purposes. Not validated for clinical use.")
            )
          )
        )
      ),

      # ── Tab 2: Variant Interpretation ──────────────────────────────────────
      nav_panel(
        title = "Variant Interpretation",
        icon  = icon("dna"),
        div(
          style = "overflow-y:auto; height:calc(100vh - 100px); padding:16px;",
          uiOutput("vi_panel")
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # NULL-safe input reader — returns `default` when input hasn't been rendered yet
  inp <- function(id, default = character(0)) {
    val <- input[[id]]
    if (is.null(val)) default else val
  }

  rv <- reactiveValues(
    hpo_terms       = list(),
    removed_ids     = character(0),
    analysis_done   = FALSE,
    eligibility     = NULL,
    posterior_df    = NULL,
    p_genetic       = NULL,
    disease_df      = NULL,
    error_msg       = NULL,
    run_error       = NULL,
    loading_hpo     = FALSE,
    n_auto_hpo      = 0L,
    n_extracted_hpo = 0L
  )

  # ── Branch sections (rendered based on presentation selection) ─────────────
  output$branch_sections <- renderUI({
    pres <- inp("presentation")
    if (length(pres) == 0) {
      return(tags$p(
        style = "font-size:.81rem; color:#6c757d; font-style:italic; text-align:center; padding:4px 0 8px;",
        "Select a presentation above to see relevant clinical questions."
      ))
    }

    sections <- list()

    # ── Cysts ────────────────────────────────────────────────────────────────
    if ("Cysts on imaging" %in% pres) {
      sections <- c(sections, list(form_section(
        "\U1F7E2", "Cysts on imaging", open = TRUE, extra_class = "branch-section",
        tags$p(style = "font-size:.81rem; color:#6c757d; margin-bottom:6px;",
               "Cystic renal disease confirmed on imaging. Age, family history, and clinical context (below) are the key additional inputs for R193."),
        checkboxGroupInput("extra_renal_cysts", "Associated features",
          choices = "Liver cysts", selected = character(0))
      )))
    }

    # ── Haematuria ───────────────────────────────────────────────────────────
    if ("Haematuria" %in% pres) {
      sections <- c(sections, list(form_section(
        "\U1FA78", "Haematuria", open = TRUE, extra_class = "branch-section",
        selectInput("haematuria", "Haematuria type",
                    choices = c("Microscopic", "Macroscopic"), selected = "Microscopic"),
        checkboxGroupInput("biopsy_haem", "Biopsy findings (if done)", inline = FALSE,
          choices  = c("GBM thickening with splitting/lamellation on EM (Alport pattern)",
                       "Thin basement membrane disease"),
          selected = character(0)
        ),
        checkboxGroupInput("extra_renal_haem", "Associated features", inline = FALSE,
          choices  = c("Hearing loss", "Ocular abnormality"),
          selected = character(0)
        ),
        checkboxGroupInput("ancestry_haem", "Ancestry", inline = FALSE,
          choices  = "Cypriot or eastern Mediterranean",
          selected = character(0)
        )
      )))
    }

    # ── Proteinuria / nephrotic ───────────────────────────────────────────────
    if ("Proteinuria / nephrotic syndrome" %in% pres) {
      sections <- c(sections, list(form_section(
        "\U1F4A7", "Proteinuria / nephrotic syndrome", open = TRUE, extra_class = "branch-section",
        selectInput("proteinuria", "Proteinuria level",
                    choices  = c("Sub-nephrotic", "Nephrotic-range"),
                    selected = "Sub-nephrotic"),
        checkboxGroupInput("biopsy_prot", "Biopsy findings (if done)", inline = FALSE,
          choices  = c("FSGS or diffuse mesangial sclerosis",
                       "C3 glomerulopathy or MPGN"),
          selected = character(0)
        )
      )))
    }

    # ── Tubulopathy / stones ─────────────────────────────────────────────────
    if ("Tubulopathy or kidney stones" %in% pres) {
      sections <- c(sections, list(form_section(
        "\U1F9EA", "Tubulopathy or kidney stones", open = TRUE, extra_class = "branch-section",
        tags$p(style = "font-size:.81rem; color:#6c757d; margin-bottom:6px;",
               "Tick all electrolyte / tubular patterns confirmed on biochemistry."),
        checkboxGroupInput("tubulopathy_pattern", label = NULL, inline = FALSE,
          choices = c(
            "Hypokalaemia with alkalosis (Bartter / Gitelman)",
            "Hypokalaemia with acidosis (proximal RTA / Fanconi)",
            "Hyperkalaemia with acidosis (pseudohypoaldosteronism)",
            "Hypomagnesaemia",
            "Nephrogenic diabetes insipidus",
            "Hypercalciuria",
            "Nephrocalcinosis",
            "Nephrolithiasis / recurrent kidney stones"
          ),
          selected = character(0)
        )
      )))
    }

    # ── Unexplained renal impairment / early ESKD ─────────────────────────────
    if ("Unexplained renal impairment / early ESKD" %in% pres) {
      sections <- c(sections, list(form_section(
        "\U231B", "Unexplained renal impairment / early ESKD", open = TRUE, extra_class = "branch-section",
        tags$p(style = "font-size:.81rem; color:#6c757d; margin-bottom:4px;",
               "eGFR and age are captured in Patient details above. R257 requires age < 36 and eGFR < 30."),
        checkboxGroupInput("biopsy_renal", "Biopsy findings (if done)", inline = FALSE,
          choices  = "Tubulointerstitial fibrosis (no glomerular lesion)",
          selected = character(0)
        )
      )))
    }

    # ── Systemic features ─────────────────────────────────────────────────────
    if ("Systemic features (aHUS or amyloidosis)" %in% pres) {
      sections <- c(sections, list(form_section(
        "\U2764\UFE0F", "Systemic features", open = TRUE, extra_class = "branch-section",
        tags$div(class = "section-label", style = "margin-top:0;",
                 "Thrombotic microangiopathy (aHUS — R201)"),
        checkboxGroupInput("ahus_features", label = NULL, inline = FALSE,
          choices = c(
            "AKI / acute renal failure",
            "Thrombocytopenia",
            "Microangiopathic haemolytic anaemia (MAHA, Coombs negative)"
          ),
          selected = character(0)
        ),
        tags$hr(style = "margin:6px 0;"),
        tags$div(class = "section-label", "Hereditary amyloidosis (R204)"),
        checkboxGroupInput("amyloid_features", label = NULL, inline = FALSE,
          choices = c(
            "Restrictive cardiomyopathy",
            "Peripheral or autonomic neuropathy"
          ),
          selected = character(0)
        )
      )))
    }

    # ── Donor / APOL1 ─────────────────────────────────────────────────────────
    if ("Kidney donor assessment (APOL1)" %in% pres) {
      sections <- c(sections, list(form_section(
        "\U1FA7A", "Kidney donor assessment (APOL1 — R446)", open = TRUE, extra_class = "branch-section",
        checkboxGroupInput("ancestry_donor", "Ancestry (both parents)", inline = FALSE,
          choices  = "African, African-American, Caribbean or Brazilian",
          selected = character(0)
        ),
        tags$p(style = "font-size:.81rem; color:#6c757d; margin-top:6px; margin-bottom:0;",
               "Also tick ‘Being assessed for living kidney donation’ and ‘Counselled and consented for APOL1 testing’ in Clinical context below.")
      )))
    }

    do.call(tagList, sections)
  })

  # ── Extract HPO terms via API ──────────────────────────────────────────────
  observeEvent(input$extract_hpo, {
    req(nchar(trimws(input$vignette)) > 10)

    rv$error_msg   <- NULL
    rv$loading_hpo <- TRUE
    rv$hpo_terms   <- list()
    rv$removed_ids <- character(0)

    vignette <- input$vignette
    age      <- input$age
    sex      <- input$sex
    egfr     <- input$egfr
    proto    <- inp("proteinuria", "None")
    haem     <- inp("haematuria",  "None")
    fhist    <- input$family_history
    xrenal   <- unique(c(inp("extra_renal_haem"), inp("extra_renal_cysts")))
    if (length(xrenal) == 0) xrenal <- "None"
    consang  <- input$consanguinity

    tryCatch({
      terms <- extract_hpo_terms(vignette, age, sex, egfr, proto, haem, fhist, xrenal, consang)
      rv$hpo_terms   <- terms
      rv$loading_hpo <- FALSE
    }, error = function(e) {
      rv$error_msg   <- paste("API error:", conditionMessage(e))
      rv$loading_hpo <- FALSE
    })
  })

  # ── Remove a term ──────────────────────────────────────────────────────────
  observeEvent(input$remove_term, {
    rv$removed_ids <- c(rv$removed_ids, input$remove_term)
  })

  # ── Add manual HPO term ────────────────────────────────────────────────────
  observeEvent(input$add_hpo_btn, {
    raw <- trimws(input$manual_hpo)
    if (nchar(raw) == 0) return()
    new_term <- list(id = paste0("MANUAL-", gsub("\\s+", "_", raw)),
                     label = raw, confidence = "high")
    rv$hpo_terms <- c(rv$hpo_terms, list(new_term))
    updateTextInput(session, "manual_hpo", value = "")
  })

  # ── Confirmed terms (reactive) ─────────────────────────────────────────────
  confirmed_terms <- reactive({
    Filter(function(t) !(t$id %in% rv$removed_ids), rv$hpo_terms)
  })

  # ── Run analysis ───────────────────────────────────────────────────────────
  observeEvent(input$run_analysis, {
    rv$run_error     <- NULL
    rv$analysis_done <- FALSE

    confirmed_ids <- sapply(confirmed_terms(), `[[`, "id")

    age_val  <- suppressWarnings(as.numeric(input$age))
    egfr_val <- suppressWarnings(as.numeric(input$egfr))

    # Merge branch-specific structured inputs
    haematuria_val  <- inp("haematuria",  "None")
    proteinuria_val <- inp("proteinuria", "None")

    biopsy_val <- unique(c(
      inp("biopsy_haem"),
      inp("biopsy_prot"),
      inp("biopsy_renal")
    ))

    extra_renal_val <- unique(c(
      inp("extra_renal_haem"),
      inp("extra_renal_cysts"),
      if (isTRUE(input$htn_35)) "Hypertension <35yrs" else character(0)
    ))

    ancestry_val <- unique(c(inp("ancestry_haem"), inp("ancestry_donor")))
    context_val  <- inp("clinical_context")

    # Derive HPO IDs from all structured inputs, then merge with any vignette-extracted terms
    auto_hpo_ids <- derive_all_hpo_from_inputs(
      presentation        = inp("presentation"),
      haematuria          = haematuria_val,
      proteinuria         = proteinuria_val,
      extra_renal         = extra_renal_val,
      egfr                = egfr_val,
      tubulopathy_pattern = inp("tubulopathy_pattern"),
      ahus_features       = inp("ahus_features"),
      amyloid_features    = inp("amyloid_features")
    )
    all_hpo_ids <- unique(c(auto_hpo_ids, confirmed_ids))

    rv$n_auto_hpo      <- length(auto_hpo_ids)
    rv$n_extracted_hpo <- length(confirmed_ids)

    tryCatch({
      rv$eligibility <- run_eligibility_all_panels(
        panels            = renal_panels,
        strict_criteria   = panel_strict_criteria,
        confirmed_hpo_ids = all_hpo_ids,
        age               = age_val,
        sex               = input$sex,
        proteinuria       = proteinuria_val,
        haematuria        = haematuria_val,
        family_history    = input$family_history,
        extra_renal       = extra_renal_val,
        egfr              = egfr_val,
        consanguinity     = input$consanguinity,
        biopsy_results    = biopsy_val,
        ancestry          = ancestry_val,
        clinical_context  = context_val
      )

      rv$posterior_df <- run_bayesian_update(
        confirmed_hpo_ids        = all_hpo_ids,
        age                      = age_val,
        sex                      = input$sex,
        family_history           = input$family_history,
        consanguinity            = input$consanguinity,
        biopsy_results           = biopsy_val,
        condition_priors         = condition_priors,
        hpo_lr_positive          = hpo_lr_positive,
        hpo_lr_negative          = hpo_lr_negative,
        family_history_modifiers = family_history_modifiers,
        consanguinity_modifiers  = consanguinity_modifiers,
        biopsy_modifiers         = biopsy_modifiers,
        sex_alport_modifiers     = sex_alport_modifiers,
        age_modifier_fn          = age_modifier
      )

      split               <- split_posterior(rv$posterior_df)
      rv$p_genetic        <- split$p_genetic
      rv$disease_df       <- split$disease_df

      rv$analysis_done <- TRUE
    }, error = function(e) {
      rv$run_error <- conditionMessage(e)
    })
  })

  # ── HPO section UI ─────────────────────────────────────────────────────────
  output$hpo_section <- renderUI({
    if (rv$loading_hpo) {
      return(tags$div(
        class = "mt-2 text-center text-primary",
        tags$div(class = "spinner-border spinner-border-sm me-2"),
        "Extracting HPO terms…"
      ))
    }

    if (!is.null(rv$error_msg)) {
      return(tags$div(
        class = "alert alert-danger mt-2",
        style = "font-size:.82rem;",
        tags$strong("Error: "), rv$error_msg
      ))
    }

    terms <- rv$hpo_terms
    if (length(terms) == 0) return(NULL)

    active <- confirmed_terms()

    badge_list <- lapply(active, function(t) {
      conf_class <- switch(t$confidence, "high" = "", "medium" = "medium", "low" = "low", "")
      tags$span(
        class = paste("hpo-badge", conf_class),
        t$label,
        tags$small(style = "opacity:.7;", paste0(" (", t$id, ")")),
        tags$button(
          "×",
          onclick = sprintf(
            "Shiny.setInputValue('remove_term', '%s', {priority:'event'});",
            t$id
          )
        )
      )
    })

    tagList(
      tags$hr(style = "margin:8px 0;"),
      tags$div(class = "section-label",
               paste0("HPO Terms (", length(active), " active)")),
      tags$div(
        style = "background:#f8fafc; border:1px solid #d1dce8; border-radius:6px; padding:6px; margin-bottom:6px;",
        if (length(active) == 0)
          tags$span(style = "color:#8a99aa; font-style:italic; font-size:.83rem;",
                    "All terms removed. Add terms manually below.")
        else
          do.call(tagList, badge_list)
      ),
      tags$div(
        style = "display:flex; gap:6px;",
        tags$input(id = "manual_hpo", type = "text",
                   class = "form-control form-control-sm",
                   placeholder = "Add HPO term name…"),
        actionButton("add_hpo_btn", "+", class = "btn btn-outline-primary btn-sm")
      )
    )
  })

  # ── Output panel ───────────────────────────────────────────────────────────
  output$output_section <- renderUI({
    if (!is.null(rv$run_error)) {
      return(tags$div(
        class = "alert alert-danger mt-3",
        tags$strong("Analysis error: "),
        tags$br(),
        tags$code(rv$run_error),
        tags$br(),
        tags$small(class = "text-muted",
                   "Check the RStudio console for the full traceback.")
      ))
    }

    if (!rv$analysis_done) {
      return(tags$div(
        class = "output-placeholder",
        tags$div(style = "font-size:2.5rem; margin-bottom:12px;", "\U0001F9EC"),
        tags$div(style = "font-size:1rem; font-weight:600; color:#4a6fa5;",
                 "Select a presentation, fill in the relevant questions, then click Run Analysis"),
        tags$div(style = "font-size:.85rem; margin-top:6px;",
                 "Results will appear here. Clinical vignette / HPO extraction is optional.")
      ))
    }

    tagList(
      card(
        card_header(tags$span("\U0001F4CB NHS Genomic Test Directory — Eligibility Assessment")),
        card_body(style = "overflow-x:auto;", uiOutput("eligibility_table"))
      ),
      card(
        class = "mt-3",
        card_header(tags$span("\U0001F4CA Bayesian Posterior Probability by Condition")),
        card_body(
          uiOutput("bayes_summary"),
          plotlyOutput("posterior_plot", height = "420px")
        )
      )
    )
  })

  # ── Eligibility table ──────────────────────────────────────────────────────
  output$eligibility_table <- renderUI({
    req(rv$eligibility)

    make_pills <- function(items, cls) {
      if (length(items) == 0) return(NULL)
      do.call(tagList, lapply(items, function(x) tags$span(class = cls, x)))
    }

    rows <- lapply(rv$eligibility, function(res) {
      badge_bg  <- switch(res$eligibility,
        "Likely eligible"   = "#198754",
        "Possibly eligible" = "#ffc107",
        "Unlikely eligible" = "#dc3545",
        "#6c757d"
      )
      badge_col <- if (res$eligibility == "Possibly eligible") "#000" else "#fff"
      icon_str  <- eligibility_icon(res$eligibility)

      s_met <- res$strict_met
      s_not <- res$strict_not
      s_unk <- res$strict_unknown

      strict_badge_col <- switch(res$strict_result,
        "met"     = "#198754",
        "partial" = "#fd7e14",
        "not_met" = "#dc3545",
        "#6c757d"
      )

      strict_summary <- tags$div(
        style = "margin-bottom:4px;",
        tags$span(
          style = paste0("background:", strict_badge_col,
                         "; color:#fff; border-radius:10px; padding:2px 8px;",
                         " font-size:.72rem; font-weight:600; margin-right:4px;"),
          paste(strict_icon(res$strict_result), strict_label(res$strict_result))
        )
      )

      strict_detail <- tags$details(
        style = "margin-top:2px;",
        tags$summary(style = "font-size:.74rem; color:#6c757d; cursor:pointer;",
                     "Strict criteria detail"),
        tags$div(
          style = "margin-top:4px;",
          if (length(s_met) > 0) tagList(
            tags$div(style = "font-size:.72rem; font-weight:600; color:#198754; margin-bottom:2px;",
                     "Met:"),
            make_pills(s_met, "criteria-pill")
          ),
          if (length(s_not) > 0) tagList(
            tags$div(style = "font-size:.72rem; font-weight:600; color:#dc3545; margin-top:4px; margin-bottom:2px;",
                     "Not met:"),
            make_pills(s_not, "criteria-pill unmet")
          ),
          if (length(s_unk) > 0) tagList(
            tags$div(style = "font-size:.72rem; font-weight:600; color:#6c757d; margin-top:4px; margin-bottom:2px;",
                     "Requires clinical assessment:"),
            make_pills(s_unk, "criteria-pill unknown")
          )
        )
      )

      hpo_met_pills <- make_pills(res$hpo_criteria_met, "criteria-pill")
      hpo_not_pills <- make_pills(res$hpo_criteria_not, "criteria-pill unmet")

      met_pills <- tagList(
        strict_summary,
        strict_detail,
        if (!is.null(hpo_met_pills) && res$strict_result != "not_met") tagList(
          tags$div(style = "font-size:.72rem; font-weight:600; color:#1a6fa8; margin-top:6px; margin-bottom:2px;",
                   "Supporting criteria:"),
          hpo_met_pills
        )
      )

      unmet_pills <- if (res$strict_result == "not_met") {
        tags$span(style = "color:#aaa; font-size:.8rem;", "—")
      } else if (!is.null(hpo_not_pills)) {
        hpo_not_pills
      } else {
        tags$span(style = "color:#aaa; font-size:.8rem;", "—")
      }

      panel_url   <- renal_panels[[res$code]]$panelapp_url
      panel_genes <- renal_panels[[res$code]]$genes
      n_genes     <- length(panel_genes)
      preview     <- paste(head(panel_genes, 8), collapse = ", ")
      gene_label  <- if (n_genes > 8) paste0(preview, " … +", n_genes - 8, " more") else preview

      tags$tr(
        tags$td(
          style = "white-space:nowrap; font-weight:600;",
          if (!is.null(panel_url) && nchar(panel_url) > 0)
            tags$a(res$code, href = panel_url, target = "_blank",
                   style = "color:#1a6fa8; text-decoration:none;")
          else
            tags$span(res$code, style = "color:#1a6fa8;")
        ),
        tags$td(
          style = "font-size:.85rem;",
          tags$div(res$name),
          tags$details(
            style = "margin-top:3px;",
            tags$summary(style = "font-size:.75rem; color:#6c757d; cursor:pointer;",
                         paste0(n_genes, " green genes")),
            tags$div(style = "font-size:.72rem; color:#444; margin-top:3px; line-height:1.6;",
                     gene_label)
          )
        ),
        tags$td(
          style = "white-space:nowrap;",
          tags$span(
            style = paste0("background:", badge_bg, "; color:", badge_col,
                           "; border-radius:12px; padding:3px 10px;",
                           " font-size:.8rem; font-weight:600;"),
            paste(icon_str, res$eligibility)
          )
        ),
        tags$td(style = "font-size:.8rem;", met_pills),
        tags$td(style = "font-size:.8rem;", unmet_pills)
      )
    })

    tags$table(
      class = "table table-sm table-hover",
      style = "font-size:.85rem;",
      tags$thead(
        class = "table-light",
        tags$tr(
          tags$th("Code"), tags$th("Condition"),
          tags$th("Eligibility"), tags$th("Criteria / Evidence"),
          tags$th("Unmet criteria")
        )
      ),
      tags$tbody(rows)
    )
  })

  # ── Bayesian summary note ──────────────────────────────────────────────────
  output$bayes_summary <- renderUI({
    req(rv$disease_df, rv$p_genetic)
    top <- rv$disease_df[1, ]
    lbl <- condition_labels[top$condition]
    pct_genetic <- round(rv$p_genetic * 100, 1)

    n_auto <- rv$n_auto_hpo
    n_ext  <- rv$n_extracted_hpo
    note <- if (n_auto == 0 && n_ext == 0) {
      "No clinical features entered — estimate shows priors modified by age, family history and consanguinity only."
    } else if (n_ext == 0) {
      paste0("Based on ", n_auto, " HPO term", if (n_auto != 1) "s" else "",
             " derived from structured form inputs.")
    } else if (n_auto == 0) {
      paste0("Based on ", n_ext, " extracted HPO term", if (n_ext != 1) "s" else "", ".")
    } else {
      paste0("Based on ", n_auto, " structured-input HPO term", if (n_auto != 1) "s" else "",
             " + ", n_ext, " extracted term", if (n_ext != 1) "s" else "", ".")
    }

    tags$div(
      class = "summary-box",
      tags$strong("Estimated probability of a modelled genetic cause: "), paste0(pct_genetic, "%"), tags$br(),
      tags$strong("Top-ranked condition if genetic: "), lbl, tags$br(),
      tags$small(class = "text-muted", note),
      tags$br(),
      tags$small(class = "text-muted",
                 style = "font-style:italic;",
                 "Chart below ranks conditions relative to each other, assuming a modelled genetic cause is present — not validated clinical probabilities. A genetic cause outside this list, or co-existing diagnoses, remain possible.")
    )
  })

  # ── Plotly posterior chart ─────────────────────────────────────────────────
  output$posterior_plot <- renderPlotly({
    req(rv$disease_df)
    build_posterior_plot(rv$disease_df, condition_labels, condition_colours)
  })

  # ── Variant Interpretation module ──────────────────────────────────────────
  rv_vi <- reactiveValues(
    gene     = NULL,
    cond_ids = NULL,
    cond_id  = NULL,
    result   = NULL,
    error    = NULL
  )

  observeEvent(input$vi_lookup, {
    gene_raw <- trimws(input$vi_gene)
    if (nchar(gene_raw) == 0) return()
    gene <- toupper(gene_raw)

    rv_vi$result  <- NULL
    rv_vi$error   <- NULL
    rv_vi$cond_id <- NULL

    cond_ids       <- gene_to_condition[[gene]]
    rv_vi$gene     <- gene
    rv_vi$cond_ids <- if (is.null(cond_ids)) character(0) else cond_ids
    if (!is.null(cond_ids) && length(cond_ids) == 1) rv_vi$cond_id <- cond_ids[[1]]
  })

  observeEvent(input$vi_cond_select, {
    rv_vi$cond_id <- input$vi_cond_select
    rv_vi$result  <- NULL
  })

  observeEvent(input$vi_assess, {
    rv_vi$result <- NULL
    rv_vi$error  <- NULL

    cond_id <- rv_vi$cond_id
    if (is.null(cond_id)) { rv_vi$error <- "No condition selected."; return() }

    cond     <- variant_conditions[[cond_id]]
    zygosity <- input$vi_zygosity
    if (is.null(zygosity) || !(zygosity %in% names(cond$prior))) {
      rv_vi$error <- "Please select a valid zygosity."; return()
    }

    feature_states <- list()
    for (feat in cond$features) {
      feature_states[[feat$id]] <- input[[paste0("vi_feat_", feat$id)]]
    }

    rv_vi$result <- compute_vi_posterior(cond, zygosity, feature_states)
  })

  # ── VI panel ───────────────────────────────────────────────────────────────
  output$vi_panel <- renderUI({
    tagList(
      card(
        card_header(tags$span("\U0001F9EC Variant Interpretation — Phenotype-Informed Causativity Assessment")),
        card_body(
          tags$p(
            class = "text-muted", style = "font-size:.82rem; margin-bottom:10px;",
            "Enter the gene symbol from a reported P/LP variant. Select zygosity and indicate which features are present, absent, or not assessed.",
            " The tool estimates the posterior probability that this variant is the primary cause of the patient’s renal disease."
          ),
          fluidRow(
            column(7, textInput("vi_gene", "Gene symbol",
                                placeholder = "e.g. COL4A5, PKD1, UMOD, NPHS1")),
            column(5, br(), actionButton("vi_lookup", "Look up",
                                         class = "btn btn-primary btn-sm w-100",
                                         icon  = icon("search")))
          ),
          uiOutput("vi_condition_ui"),
          uiOutput("vi_zygosity_ui"),
          uiOutput("vi_features_ui"),
          uiOutput("vi_assess_btn")
        )
      ),
      uiOutput("vi_result_ui"),
      tags$div(
        class = "disclaimer-footer mt-3",
        tags$strong("Variant interpretation disclaimer: "),
        "Posterior probabilities assume the variant has been robustly classified P/LP by the reporting laboratory. ",
        "This tool does not replace genetics specialist review and should not be used to reclassify variants or make management decisions without appropriate clinical expertise."
      )
    )
  })

  output$vi_condition_ui <- renderUI({
    gene     <- rv_vi$gene
    cond_ids <- rv_vi$cond_ids
    if (is.null(gene)) return(NULL)

    if (length(cond_ids) == 0) {
      return(tags$div(
        class = "alert alert-warning mt-2", style = "font-size:.83rem;",
        tags$strong(gene), " was not found in the variant interpretation database.",
        " This gene may not be covered by this tool or may appear under a different symbol."
      ))
    }

    if (length(cond_ids) == 1) {
      cond <- variant_conditions[[cond_ids[[1]]]]
      return(tags$div(
        class = "alert alert-success mt-2", style = "font-size:.83rem;",
        tags$strong(gene), " — ", cond$label
      ))
    }

    cond_choices <- setNames(
      cond_ids,
      sapply(cond_ids, function(id) variant_conditions[[id]]$label)
    )
    tagList(
      tags$div(
        class = "alert alert-info mt-2", style = "font-size:.83rem;",
        tags$strong(gene), " maps to multiple condition groups. Select the relevant one based on zygosity and phenotype."
      ),
      selectInput("vi_cond_select", "Condition group", choices = cond_choices)
    )
  })

  output$vi_zygosity_ui <- renderUI({
    cond_id <- rv_vi$cond_id
    if (is.null(cond_id)) return(NULL)
    cond <- variant_conditions[[cond_id]]

    zyg_choices <- setNames(
      cond$zygosity_options,
      zygosity_labels[cond$zygosity_options]
    )
    tags$div(
      class = "mt-2",
      selectInput("vi_zygosity", "Variant zygosity",
                  choices  = zyg_choices,
                  selected = cond$zygosity_options[[1]])
    )
  })

  output$vi_features_ui <- renderUI({
    cond_id <- rv_vi$cond_id
    if (is.null(cond_id)) return(NULL)
    cond <- variant_conditions[[cond_id]]

    rows <- lapply(cond$features, function(feat) {
      key_badge <- if (isTRUE(feat$key))
        tags$span(class = "badge bg-secondary ms-1",
                  style = "font-size:.66rem; vertical-align:middle;", "key")
      else NULL

      caveat_note <- if (!is.null(feat$caveat))
        tags$div(class = "text-muted fst-italic",
                 style = "font-size:.76rem; margin-top:2px;", feat$caveat)
      else NULL

      absent_note <- if (is.null(feat$lr_absent))
        tags$div(class = "text-muted",
                 style = "font-size:.72rem; margin-top:2px;",
                 "Absence does not update the posterior for this feature.")
      else NULL

      tags$div(
        class = "border rounded p-2 mb-2",
        tags$div(
          class = "d-flex justify-content-between align-items-start gap-2",
          tags$div(
            style = "flex:1;",
            tags$span(style = "font-size:.84rem; font-weight:600;", feat$label),
            key_badge,
            caveat_note,
            absent_note
          ),
          radioGroupButtons(
            inputId  = paste0("vi_feat_", feat$id),
            label    = NULL,
            choices  = c("Present", "Absent", "Not assessed"),
            selected = "Not assessed",
            size     = "xs",
            status   = "outline-secondary"
          )
        )
      )
    })

    tagList(
      tags$div(class = "section-label mt-3 mb-1", "Phenotypic features"),
      tags$p(
        style = "font-size:.8rem; color:#6c757d; margin-bottom:8px;",
        "Indicate whether each feature is present, absent, or not assessed.",
        " ", tags$strong("Absent"), " only updates the posterior where absence is diagnostically informative."
      ),
      do.call(tagList, rows)
    )
  })

  output$vi_assess_btn <- renderUI({
    if (is.null(rv_vi$cond_id)) return(NULL)
    tags$div(
      class = "mt-3",
      actionButton("vi_assess", "Assess Variant",
                   class = "btn btn-success w-100",
                   icon  = icon("calculator"))
    )
  })

  output$vi_result_ui <- renderUI({
    err    <- rv_vi$error
    result <- rv_vi$result

    if (!is.null(err)) return(tags$div(class = "alert alert-danger mt-3", err))
    if (is.null(result)) return(NULL)

    cond    <- variant_conditions[[rv_vi$cond_id]]
    verdict <- variant_verdict(result$posterior)

    pct_prior <- round(result$prior    * 100, 1)
    pct_post  <- round(result$posterior * 100, 1)
    alert_cls <- switch(verdict$colour,
      success = "alert-success", warning = "alert-warning",
      danger  = "alert-danger",  "alert-secondary"
    )

    contrib_rows <- if (length(result$contributions) > 0) {
      lapply(result$contributions, function(co) {
        col <- if (co$lr >= 1) "#198754" else "#dc3545"
        arr <- if (co$lr >= 1) "↑" else "↓"
        tags$tr(
          tags$td(style = "font-size:.8rem;", co$label),
          tags$td(style = "font-size:.8rem;", co$state),
          tags$td(style = paste0("font-size:.8rem; color:", col, "; font-weight:600;"),
                  paste0(arr, " LR = ", co$lr))
        )
      })
    } else {
      list(tags$tr(tags$td(
        colspan = "3", style = "color:#6c757d; font-size:.8rem;",
        "No features assessed — posterior equals prior."
      )))
    }

    flag_items <- lapply(cond$flags,       function(f) tags$li(style = "font-size:.8rem;", f))
    ref_items  <- lapply(cond$references,  function(r) tags$li(style = "font-size:.8rem;", r))

    card(
      class = "mt-3",
      card_header(tags$span("\U0001F4CA Assessment result — ", cond$label)),
      card_body(
        tags$div(
          class = "d-flex gap-4 mb-3 flex-wrap",
          tags$div(
            tags$div(class = "text-muted", style = "font-size:.78rem;", "Prior probability"),
            tags$div(style = "font-size:1.5rem; font-weight:700; color:#1a6fa8;",
                     paste0(pct_prior, "%")),
            tags$div(class = "text-muted", style = "font-size:.73rem;",
                     "P/LP in this gene / zygosity")
          ),
          tags$div(style = "font-size:1.8rem; color:#ccc; line-height:2.5rem;", "→"),
          tags$div(
            tags$div(class = "text-muted", style = "font-size:.78rem;", "Posterior probability"),
            tags$div(style = "font-size:1.5rem; font-weight:700; color:#1a6fa8;",
                     paste0(pct_post, "%")),
            tags$div(class = "text-muted", style = "font-size:.73rem;",
                     "after phenotype evidence")
          )
        ),
        tags$div(
          class = paste("alert", alert_cls),
          style = "margin-bottom:12px;",
          tags$strong(verdict$label),
          tags$br(),
          tags$span(style = "font-size:.83rem;", verdict$detail)
        ),
        tags$details(
          tags$summary(
            style = "font-size:.82rem; cursor:pointer; color:#1a6fa8; font-weight:600;",
            "Feature contributions"
          ),
          tags$table(
            class = "table table-sm mt-2",
            tags$thead(tags$tr(
              tags$th("Feature"), tags$th("State"), tags$th("Effect")
            )),
            tags$tbody(do.call(tagList, contrib_rows))
          )
        ),
        if (length(flag_items) > 0) tags$details(
          class = "mt-2",
          tags$summary(
            style = "font-size:.82rem; cursor:pointer; color:#e07000; font-weight:600;",
            paste0("⚠️  Clinical flags (", length(cond$flags), ")")
          ),
          tags$ul(class = "mt-2", do.call(tagList, flag_items))
        ),
        if (length(ref_items) > 0) tags$details(
          class = "mt-2",
          tags$summary(
            style = "font-size:.82rem; cursor:pointer; color:#6c757d; font-weight:600;",
            "Key references"
          ),
          tags$ul(class = "mt-2", do.call(tagList, ref_items))
        )
      )
    )
  })
}

shinyApp(ui = ui, server = server)
