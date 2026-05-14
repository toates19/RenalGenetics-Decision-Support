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
                     text-transform:uppercase; letter-spacing:.04em; margin-top:14px; }
    .output-placeholder { color:#8a99aa; font-style:italic; text-align:center;
                          padding:40px 0; }
    .criteria-pill { display:inline-block; background:#e8f5e9; border:1px solid #81c784;
                     border-radius:4px; padding:1px 7px; font-size:.78rem;
                     color:#1b5e20; margin:1px; }
    .criteria-pill.unmet { background:#fce4ec; border-color:#e57373; color:#7f0000; }
    .summary-box { background:#e8f1fa; border-left:4px solid #1a6fa8;
                   padding:10px 14px; border-radius:4px; margin-bottom:12px; }
  ")

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- page_fillable(
  theme = app_theme,
  title = "RenalGenetics Decision Support",

  # Navbar
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

  # Main layout
  layout_sidebar(
    fillable = TRUE,
    sidebar = sidebar(
      width = 380,
      open  = TRUE,
      bg    = "#ffffff",
      style = "overflow-y:auto; height:calc(100vh - 56px); padding:14px;",

      # ── Step 1 ──────────────────────────────────────────────────────────────
      tags$div(class = "section-label", "Step 1 — Clinical Information"),

      tags$div(
        tags$label("Clinical vignette", class = "form-label fw-semibold"),
        tags$textarea(
          id          = "vignette",
          class       = "form-control shiny-input-text-area",
          placeholder = "e.g. 32-year-old man with microscopic haematuria, sensorineural hearing loss and family history of renal failure in maternal uncle...",
          rows        = 5,
          style       = "min-height:120px; font-size:.88rem;"
        )
      ),

      tags$hr(style = "margin:10px 0;"),

      fluidRow(
        column(6,
          numericInput("age", "Age at presentation (yrs)", value = NA, min = 0, max = 120)
        ),
        column(6,
          selectInput("sex", "Sex", choices = c("Unknown", "Male", "Female"))
        )
      ),
      fluidRow(
        column(6,
          numericInput("egfr", "eGFR (ml/min/1.73m²)", value = NA, min = 0, max = 200)
        ),
        column(6,
          selectInput("proteinuria", "Proteinuria",
                      choices = c("None", "Microalbuminuria", "Nephrotic-range"))
        )
      ),

      selectInput("haematuria", "Haematuria",
                  choices = c("None", "Microscopic", "Macroscopic")),

      selectInput("family_history", "Family history pattern",
                  choices = c("None", "Autosomal dominant", "Autosomal recessive",
                              "X-linked", "Unknown")),

      tags$div(
        class = "form-label fw-semibold mt-2",
        "Extra-renal features"
      ),
      checkboxGroupInput("extra_renal", label = NULL,
        choices  = c("Hearing loss", "Ocular abnormality", "Liver cysts",
                     "Hypertension <35yrs", "Cognitive impairment",
                     "Skeletal abnormality", "None"),
        selected = "None",
        inline   = FALSE
      ),

      selectInput("consanguinity", "Consanguinity",
                  choices = c("Unknown", "Yes", "No")),

      actionButton("extract_hpo", "Extract HPO Terms",
                   class = "btn btn-primary w-100 mt-2",
                   icon  = icon("dna")),

      # ── Step 2: HPO term confirmation ──────────────────────────────────────
      uiOutput("hpo_section")
    ),

    # ── Right output panel ───────────────────────────────────────────────────
    div(
      style = "overflow-y:auto; height:calc(100vh - 56px); padding:16px;",

      uiOutput("output_section"),

      # Footer disclaimer — always visible
      tags$div(
        class = "disclaimer-footer mt-auto",
        tags$strong("Disclaimers: "),
        tags$ul(
          style = "margin:4px 0 0 0; padding-left:18px;",
          tags$li("This tool is for decision support only and does not replace clinical judgement or formal genetics referral."),
          tags$li("GT Directory criteria based on version v7, April 2025."),
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
    hpo_terms      = list(),   # list of list(id, label, confidence)
    removed_ids    = character(0),
    analysis_done  = FALSE,
    eligibility    = NULL,
    posterior_df   = NULL,
    error_msg      = NULL,
    loading_hpo    = FALSE
  )

  # ── Extract HPO terms via API ──────────────────────────────────────────────
  observeEvent(input$extract_hpo, {
    req(nchar(trimws(input$vignette)) > 10)

    rv$error_msg   <- NULL
    rv$loading_hpo <- TRUE
    rv$hpo_terms   <- list()
    rv$removed_ids <- character(0)
    rv$analysis_done <- FALSE

    vignette <- input$vignette
    age      <- input$age
    sex      <- input$sex
    egfr     <- input$egfr
    proto    <- input$proteinuria
    haem     <- input$haematuria
    fhist    <- input$family_history
    xrenal   <- if (length(input$extra_renal) == 0 || "None" %in% input$extra_renal) "None" else input$extra_renal
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
    terms <- confirmed_terms()
    req(length(terms) >= 3)

    confirmed_ids <- sapply(terms, `[[`, "id")

    age_val    <- suppressWarnings(as.numeric(input$age))
    egfr_val   <- suppressWarnings(as.numeric(input$egfr))
    xrenal_val <- if ("None" %in% input$extra_renal || length(input$extra_renal) == 0)
                    character(0) else input$extra_renal

    # Eligibility
    rv$eligibility <- run_eligibility_all_panels(
      panels          = renal_panels,
      confirmed_hpo_ids = confirmed_ids,
      age             = age_val,
      sex             = input$sex,
      proteinuria     = input$proteinuria,
      haematuria      = input$haematuria,
      family_history  = input$family_history,
      extra_renal     = xrenal_val,
      egfr            = egfr_val,
      consanguinity   = input$consanguinity
    )

    # Bayesian update
    rv$posterior_df <- run_bayesian_update(
      confirmed_hpo_ids       = confirmed_ids,
      age                     = age_val,
      family_history          = input$family_history,
      consanguinity           = input$consanguinity,
      condition_priors        = condition_priors,
      hpo_lr_positive         = hpo_lr_positive,
      hpo_lr_negative         = hpo_lr_negative,
      family_history_modifiers = family_history_modifiers,
      consanguinity_modifiers  = consanguinity_modifiers,
      age_modifier_fn         = age_modifier
    )

    rv$analysis_done <- TRUE
  })

  # ── HPO section UI ─────────────────────────────────────────────────────────
  output$hpo_section <- renderUI({
    if (rv$loading_hpo) {
      return(tags$div(
        class = "mt-3 text-center text-primary",
        tags$div(class = "spinner-border spinner-border-sm me-2"),
        "Extracting HPO terms…"
      ))
    }

    if (!is.null(rv$error_msg)) {
      return(tags$div(
        class = "alert alert-danger mt-3",
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

    n_active <- length(active)
    can_run  <- n_active >= 3

    tagList(
      tags$hr(style = "margin:12px 0;"),
      tags$div(class = "section-label",
               paste0("Step 2 — Confirm HPO Terms (", n_active, " active)")),
      tags$div(
        style = "background:#f8fafc; border:1px solid #d1dce8; border-radius:6px; padding:8px; margin-bottom:8px;",
        if (n_active == 0) {
          tags$span(style = "color:#8a99aa; font-style:italic; font-size:.85rem;",
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
      ),
      if (!can_run) {
        tags$div(
          class = "text-muted mt-2",
          style = "font-size:.8rem;",
          paste0("⚠️ ", 3 - n_active, " more term(s) needed to run analysis.")
        )
      },
      actionButton("run_analysis", "Run Analysis",
                   class = paste("btn w-100 mt-2", if (can_run) "btn-success" else "btn-secondary"),
                   disabled = if (can_run) NULL else "disabled",
                   icon = icon("magnifying-glass-chart"))
    )
  })

  # ── Output panel UI ────────────────────────────────────────────────────────
  output$output_section <- renderUI({
    if (!rv$analysis_done) {
      return(tags$div(
        class = "output-placeholder",
        tags$div(style = "font-size:2.5rem; margin-bottom:12px;", "\U0001F9EC"),
        tags$div(style = "font-size:1rem; font-weight:600; color:#4a6fa5;",
                 "Complete Step 1 → Extract HPO Terms → Run Analysis"),
        tags$div(style = "font-size:.85rem; margin-top:6px;",
                 "Results will appear here after running the analysis.")
      ))
    }

    tagList(
      # ── Output A: Eligibility table ───────────────────────────────────────
      card(
        card_header(
          tags$span("\U0001F4CB NHS Genomic Test Directory — Eligibility Assessment")
        ),
        card_body(
          style = "overflow-x:auto;",
          uiOutput("eligibility_table")
        )
      ),

      # ── Output B: Bayesian chart ──────────────────────────────────────────
      card(
        class = "mt-3",
        card_header(
          tags$span("\U0001F4CA Bayesian Posterior Probability by Condition")
        ),
        card_body(
          uiOutput("bayes_summary"),
          plotlyOutput("posterior_plot", height = "320px")
        )
      )
    )
  })

  # ── Eligibility table ──────────────────────────────────────────────────────
  output$eligibility_table <- renderUI({
    req(rv$eligibility)

    rows <- lapply(rv$eligibility, function(res) {
      badge_bg <- switch(res$eligibility,
        "Likely eligible"   = "#198754",
        "Possibly eligible" = "#ffc107",
        "Unlikely eligible" = "#dc3545",
        "#6c757d"
      )
      badge_col <- if (res$eligibility == "Possibly eligible") "#000" else "#fff"
      icon_str  <- eligibility_icon(res$eligibility)

      met_pills <- if (length(res$criteria_met) > 0) {
        lapply(res$criteria_met, function(c)
          tags$span(class = "criteria-pill", c))
      } else tags$span(style = "color:#aaa; font-size:.8rem;", "None")

      unmet_pills <- if (length(res$criteria_not) > 0) {
        lapply(res$criteria_not, function(c)
          tags$span(class = "criteria-pill unmet", c))
      } else tags$span(style = "color:#aaa; font-size:.8rem;", "—")

      tags$tr(
        tags$td(style = "white-space:nowrap; font-weight:600; color:#1a6fa8;", res$code),
        tags$td(style = "font-size:.85rem;", res$name),
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
          tags$th("Eligibility"), tags$th("Key criteria met"), tags$th("Key criteria not met")
        )
      ),
      tags$tbody(rows)
    )
  })

  # ── Bayesian summary sentence ──────────────────────────────────────────────
  output$bayes_summary <- renderUI({
    req(rv$posterior_df)
    df  <- rv$posterior_df
    top <- df[1, ]
    lbl <- condition_labels[top$condition]
    pct <- round(top$posterior * 100, 1)
    ci_lo <- round(top$ci_lower * 100, 1)
    ci_hi <- round(top$ci_upper * 100, 1)

    tags$div(
      class = "summary-box",
      tags$strong("Highest probability diagnosis: "),
      lbl,
      tags$br(),
      tags$span(
        style = "font-size:.9rem;",
        sprintf("Posterior probability: %.1f%% (approx. 95%% CI: %.1f–%.1f%%)", pct, ci_lo, ci_hi)
      ),
      tags$br(),
      tags$small(
        class = "text-muted",
        paste0("Based on ", length(confirmed_terms()), " confirmed HPO terms.")
      )
    )
  })

  # ── Plotly posterior chart ─────────────────────────────────────────────────
  output$posterior_plot <- renderPlotly({
    req(rv$posterior_df)
    build_posterior_plot(rv$posterior_df, condition_labels, condition_colours)
  })
}

shinyApp(ui = ui, server = server)
