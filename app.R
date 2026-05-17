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
    .sidebar-panel { background:#ffffff; border-right:1px solid #d1dce8; }
    .card { border:1px solid #d1dce8; box-shadow:0 1px 4px rgba(26,111,168,.08); }
    .card-header { background:#1a6fa8; color:#fff; font-weight:600; font-size:.9rem; }
    .hpo-badge { display:inline-flex; align-items:center; gap:4px;
                 background:#e8f1fa; border:1px solid #a8c4e0; color:#1a6fa8;
                 border-radius:20px; padding:3px 10px; margin:3px; font-size:.82rem; }
    .hpo-badge.medium { background:#fff8e1; border-color:#ffc107; color:#7a5800; }
    .hpo-badge.low    { background:#fce8e8; border-color:#e57373; color:#8b1a1a; }
    .hpo-badge button { background:none; border:none; color:inherit;
                        font-size:.85rem; cursor:pointer; padding:0 0 0 2px; line-height:1; }
    .badge-Likely   { background:#198754 !important; }
    .badge-Possibly { background:#ffc107 !important; color:#000 !important; }
    .badge-Unlikely { background:#dc3545 !important; }
    .disclaimer-footer { background:#fff3cd; border-top:2px solid #ffc107;
                         padding:12px 20px; font-size:.78rem; color:#5a4200; }
    .section-label { font-weight:600; color:#1a6fa8; font-size:.82rem;
                     text-transform:uppercase; letter-spacing:.04em; margin-top:6px; margin-bottom:4px; }
    .output-placeholder { color:#8a99aa; font-style:italic; text-align:center;
                          padding:40px 0; }
    .criteria-pill { display:inline-block; background:#e8f5e9; border:1px solid #81c784;
                     border-radius:4px; padding:1px 7px; font-size:.78rem;
                     color:#1b5e20; margin:1px; }
    .criteria-pill.unmet { background:#fce4ec; border-color:#e57373; color:#7f0000; }
    .criteria-pill.unknown { background:#fff8e1; border-color:#ffc107; color:#5a4200; }
    .summary-box { background:#e8f1fa; border-left:4px solid #1a6fa8;
                   padding:10px 14px; border-radius:4px; margin-bottom:12px; }
    /* Accordion section styling */
    .form-section { border:1px solid #d1dce8; border-radius:6px; margin-bottom:6px; }
    .form-section summary {
      list-style:none; padding:7px 10px; cursor:pointer;
      font-weight:600; font-size:.82rem; color:#1a6fa8;
      background:#f0f5fb; border-radius:6px;
      display:flex; align-items:center; gap:6px;
    }
    .form-section summary::-webkit-details-marker { display:none; }
    .form-section[open] > summary { border-radius:6px 6px 0 0; border-bottom:1px solid #d1dce8; }
    .form-section .section-body { padding:8px 10px; }
    details > summary { list-style:none; }
    details > summary::-webkit-details-marker { display:none; }
    details[open] > summary { color:#1a6fa8; }
  ")

# ── Helper: collapsible form section ─────────────────────────────────────────
form_section <- function(icon_char, title, ..., open = FALSE) {
  args <- if (open) list(open = NA) else list()
  do.call(tags$details, c(
    args,
    list(
      class = "form-section",
      tags$summary(icon_char, " ", title),
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
      tags$img(src = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/NHS_logo.svg/40px-NHS_logo.svg.png",
               height = "24px", style = "margin-right:10px; vertical-align:middle;"),
      "RenalGenetics Decision Support"
    ),
    tags$span(
      style = "color:#c8dff5; font-size:.78rem; margin-left:auto;",
      "For clinical decision support only • Not validated for clinical use"
    )
  ),

  layout_sidebar(
    fillable = TRUE,
    sidebar = sidebar(
      width = 380,
      open  = TRUE,
      bg    = "#ffffff",
      style = "overflow-y:auto; height:calc(100vh - 56px); padding:10px;",

      # ── Demographics ───────────────────────────────────────────────────────
      form_section("\U1F9D1", "Demographics", open = TRUE,
        fluidRow(
          column(6, numericInput("age", "Age at presentation (yrs)",
                                 value = NA, min = 0, max = 120)),
          column(6, selectInput("sex", "Sex",
                                choices = c("Unknown", "Male", "Female")))
        )
      ),

      # ── Renal presentation ─────────────────────────────────────────────────
      form_section("\U1FAB8", "Renal presentation", open = TRUE,
        fluidRow(
          column(6, numericInput("egfr", "eGFR (ml/min/1.73m²)",
                                 value = NA, min = 0, max = 200)),
          column(6, selectInput("proteinuria", "Proteinuria",
                                choices = c("None", "Sub-nephrotic", "Nephrotic-range")))
        ),
        selectInput("haematuria", "Haematuria",
                    choices = c("None", "Microscopic", "Macroscopic"))
      ),

      # ── Investigations ─────────────────────────────────────────────────────
      form_section("\U1F52C", "Investigations (biopsy findings)",
        tags$p(style = "font-size:.8rem; color:#6c757d; margin-bottom:6px;",
               "Tick all findings confirmed on renal biopsy."),
        checkboxGroupInput("biopsy_results", label = NULL,
          choices = c(
            "FSGS or diffuse mesangial sclerosis",
            "Alport syndrome (GBM thickening/splitting)",
            "Thin basement membrane disease",
            "Tubulointerstitial fibrosis (no glomerular lesion)",
            "C3 glomerulopathy or MPGN"
          ),
          selected = character(0)
        )
      ),

      # ── Family history & ancestry ──────────────────────────────────────────
      form_section("\U1F9EC", "Family history & ancestry", open = TRUE,
        selectInput("family_history", "Family history pattern",
                    choices = c("None", "Autosomal dominant", "Autosomal recessive",
                                "X-linked", "Unknown")),
        selectInput("consanguinity", "Consanguinity",
                    choices = c("Unknown", "Yes", "No")),
        tags$div(style = "font-size:.82rem; font-weight:600; margin-top:8px; margin-bottom:4px;",
                 "Ancestry (tick all that apply)"),
        checkboxGroupInput("ancestry", label = NULL,
          choices = c(
            "Cypriot or eastern Mediterranean",
            "African, African-American, Caribbean or Brazilian"
          ),
          selected = character(0)
        )
      ),

      # ── Extra-renal features ───────────────────────────────────────────────
      form_section("\U1F441", "Extra-renal features",
        checkboxGroupInput("extra_renal", label = NULL,
          choices  = c("Hearing loss", "Ocular abnormality", "Liver cysts",
                       "Hypertension <35yrs", "Cognitive impairment",
                       "Skeletal abnormality"),
          selected = character(0),
          inline   = FALSE
        )
      ),

      # ── Clinical context ───────────────────────────────────────────────────
      form_section("\U1F3E5", "Clinical context",
        tags$p(style = "font-size:.8rem; color:#6c757d; margin-bottom:6px;",
               "Tick all that apply to this patient’s current situation."),
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

      # ── Clinical vignette (optional) ───────────────────────────────────────
      form_section("\U1F4DD", "Clinical vignette (optional — HPO extraction)",
        tags$p(style = "font-size:.8rem; color:#6c757d; margin-bottom:6px;",
               "Paste a free-text summary to extract additional HPO terms for Bayesian scoring."),
        tags$textarea(
          id          = "vignette",
          class       = "form-control shiny-input-text-area",
          placeholder = "e.g. 32-year-old man with microscopic haematuria, sensorineural hearing loss and family history of renal failure...",
          rows        = 4,
          style       = "font-size:.85rem;"
        ),
        actionButton("extract_hpo", "Extract HPO Terms",
                     class = "btn btn-outline-primary btn-sm w-100 mt-2",
                     icon  = icon("dna"))
      ),

      # ── HPO confirmation (appears after extraction) ────────────────────────
      uiOutput("hpo_section"),

      # ── Run Analysis (always visible) ─────────────────────────────────────
      tags$div(
        style = "margin-top:10px;",
        actionButton("run_analysis", "Run Analysis",
                     class = "btn btn-success w-100",
                     icon  = icon("magnifying-glass-chart"))
      )
    ),

    # ── Right output panel ─────────────────────────────────────────────────────
    div(
      style = "overflow-y:auto; height:calc(100vh - 56px); padding:16px;",

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
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  rv <- reactiveValues(
    hpo_terms      = list(),
    removed_ids    = character(0),
    analysis_done  = FALSE,
    eligibility    = NULL,
    posterior_df   = NULL,
    error_msg      = NULL,
    run_error      = NULL,
    loading_hpo    = FALSE
  )

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
    proto    <- input$proteinuria
    haem     <- input$haematuria
    fhist    <- input$family_history
    xrenal   <- if (length(input$extra_renal) == 0) "None" else input$extra_renal
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

    age_val      <- suppressWarnings(as.numeric(input$age))
    egfr_val     <- suppressWarnings(as.numeric(input$egfr))
    xrenal_val   <- if (length(input$extra_renal) == 0) character(0) else input$extra_renal
    biopsy_val   <- if (length(input$biopsy_results) == 0) character(0) else input$biopsy_results
    ancestry_val <- if (length(input$ancestry) == 0) character(0) else input$ancestry
    context_val  <- if (length(input$clinical_context) == 0) character(0) else input$clinical_context

    tryCatch({
      rv$eligibility <- run_eligibility_all_panels(
        panels            = renal_panels,
        strict_criteria   = panel_strict_criteria,
        confirmed_hpo_ids = confirmed_ids,
        age               = age_val,
        sex               = input$sex,
        proteinuria       = input$proteinuria,
        haematuria        = input$haematuria,
        family_history    = input$family_history,
        extra_renal       = xrenal_val,
        egfr              = egfr_val,
        consanguinity     = input$consanguinity,
        biopsy_results    = biopsy_val,
        ancestry          = ancestry_val,
        clinical_context  = context_val
      )

      rv$posterior_df <- run_bayesian_update(
        confirmed_hpo_ids        = confirmed_ids,
        age                      = age_val,
        family_history           = input$family_history,
        consanguinity            = input$consanguinity,
        condition_priors         = condition_priors,
        hpo_lr_positive          = hpo_lr_positive,
        hpo_lr_negative          = hpo_lr_negative,
        family_history_modifiers = family_history_modifiers,
        consanguinity_modifiers  = consanguinity_modifiers,
        age_modifier_fn          = age_modifier
      )

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
        tags$small(style = "opacity:.7;", paste0(" (", t$id, ")")),
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
        if (length(active) == 0) {
          tags$span(style = "color:#8a99aa; font-style:italic; font-size:.83rem;",
                    "All terms removed. Add terms manually below.")
        } else {
          tagList(badge_list)
        }
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

  # ── Output panel UI ────────────────────────────────────────────────────────
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
                 "Complete the clinical form and click Run Analysis"),
        tags$div(style = "font-size:.85rem; margin-top:6px;",
                 "Results will appear here. HPO term extraction is optional.")
      ))
    }

    tagList(
      card(
        card_header(tags$span("\U0001F4CB NHS Genomic Test Directory — Eligibility Assessment")),
        card_body(style = "overflow-x:auto;", uiOutput("eligibility_table"))
      ),
      card(
        class = "mt-3",
        card_header(tags$span("\U0001F4CA Bayesian Posterior Probability by Condition")),
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
            tags$div(style = "font-size:.72rem; font-weight:600; color:#198754; margin-bottom:2px;", "Met:"),
            make_pills(s_met, "criteria-pill")
          ),
          if (length(s_not) > 0) tagList(
            tags$div(style = "font-size:.72rem; font-weight:600; color:#dc3545; margin-top:4px; margin-bottom:2px;", "Not met:"),
            make_pills(s_not, "criteria-pill unmet")
          ),
          if (length(s_unk) > 0) tagList(
            tags$div(style = "font-size:.72rem; font-weight:600; color:#6c757d; margin-top:4px; margin-bottom:2px;", "Requires clinical assessment:"),
            make_pills(s_unk, "criteria-pill unknown")
          )
        )
      )

      hpo_met_pills <- make_pills(res$hpo_criteria_met, "criteria-pill")
      hpo_not_pills <- make_pills(res$hpo_criteria_not, "criteria-pill unmet")

      met_pills <- tagList(strict_summary, strict_detail,
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
                           "; border-radius:12px; padding:3px 10px; font-size:.8rem; font-weight:600;"),
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

  # ── Bayesian summary ───────────────────────────────────────────────────────
  output$bayes_summary <- renderUI({
    req(rv$posterior_df)
    df  <- rv$posterior_df
    top <- df[1, ]
    lbl <- condition_labels[top$condition]
    pct <- round(top$posterior * 100, 1)
    ci_lo <- round(top$ci_lower * 100, 1)
    ci_hi <- round(top$ci_upper * 100, 1)

    n_hpo <- length(confirmed_terms())
    note  <- if (n_hpo == 0)
      "No HPO terms — chart shows priors modified by age, family history and consanguinity only."
    else
      paste0("Based on ", n_hpo, " confirmed HPO term", if (n_hpo > 1) "s" else "", ".")

    tags$div(
      class = "summary-box",
      tags$strong("Highest probability diagnosis: "), lbl, tags$br(),
      tags$span(style = "font-size:.9rem;",
                sprintf("Posterior probability: %.1f%% (approx. 95%% CI: %.1f–%.1f%%)", pct, ci_lo, ci_hi)),
      tags$br(),
      tags$small(class = "text-muted", note)
    )
  })

  # ── Plotly posterior chart ─────────────────────────────────────────────────
  output$posterior_plot <- renderPlotly({
    req(rv$posterior_df)
    build_posterior_plot(rv$posterior_df, condition_labels, condition_colours)
  })
}

shinyApp(ui = ui, server = server)
