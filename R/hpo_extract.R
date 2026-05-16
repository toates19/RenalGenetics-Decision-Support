# R/hpo_extract.R
# Anthropic API call to extract HPO terms from clinical vignette + structured params

extract_hpo_terms <- function(vignette, age, sex, egfr, proteinuria,
                               haematuria, family_history, extra_renal, consanguinity) {

  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if (nchar(api_key) == 0) stop("ANTHROPIC_API_KEY environment variable not set.")

  structured_summary <- paste0(
    "Structured parameters:\n",
    "- Age at presentation: ", if (is.na(age)) "Not provided" else paste(age, "years"), "\n",
    "- Sex: ", sex, "\n",
    "- eGFR: ", if (is.na(egfr)) "Not provided" else paste(egfr, "ml/min/1.73m²"), "\n",
    "- Proteinuria: ", proteinuria, "\n",
    "- Haematuria: ", haematuria, "\n",
    "- Family history pattern: ", family_history, "\n",
    "- Extra-renal features: ", paste(extra_renal, collapse = ", "), "\n",
    "- Consanguinity: ", consanguinity
  )

  user_content <- paste0(
    "Clinical vignette:\n", vignette, "\n\n", structured_summary
  )

  body <- list(
    model = "claude-sonnet-4-5",
    max_tokens = 1024,
    system = paste0(
      "You are a clinical genetics assistant. Extract HPO (Human Phenotype Ontology) terms ",
      "from the clinical vignette and structured parameters provided. ",
      "Return ONLY a JSON array of objects, each with fields: ",
      "id (HPO ID string e.g. HP:0000123), label (plain English term), confidence (high/medium/low). ",
      "Include 5-15 terms. No markdown, no explanation, just the JSON array."
    ),
    messages = list(
      list(role = "user", content = user_content)
    )
  )

  resp <- httr2::request("https://api.anthropic.com/v1/messages") |>
    httr2::req_headers(
      "x-api-key"         = api_key,
      "anthropic-version" = "2023-06-01",
      "content-type"      = "application/json"
    ) |>
    httr2::req_body_json(body) |>
    httr2::req_timeout(30) |>
    httr2::req_perform()

  result <- httr2::resp_body_json(resp)
  raw_text <- result$content[[1]]$text

  # Strip any accidental markdown fences
  raw_text <- gsub("```json|```", "", raw_text)
  raw_text <- trimws(raw_text)

  terms <- jsonlite::fromJSON(raw_text, simplifyDataFrame = TRUE)

  if (is.data.frame(terms)) {
    terms <- as.list(apply(terms, 1, as.list))
  }

  terms
}
