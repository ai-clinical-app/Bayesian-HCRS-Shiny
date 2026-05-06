library(shiny)
library(ggplot2)

# Published reconstructed HCRS logistic-regression coefficients
# Order: Intercept, Age, Visible haematuria, Male, Ex-smoker, Current smoker
beta_hat <- c(
  Intercept = -8.0655,
  Age = 0.0553,
  VisibleHaematuria = 1.3480,
  Male = 0.5762,
  ExSmoker = 0.4133,
  CurrentSmoker = 0.9432
)

se_hat <- c(
  Intercept = 0.4754,
  Age = 0.0059,
  VisibleHaematuria = 0.1946,
  Male = 0.1607,
  ExSmoker = 0.1475,
  CurrentSmoker = 0.2048
)

# Weakly informative prior SD used in the paper
prior_sd <- 10

inv_logit <- function(x) {
  1 / (1 + exp(-x))
}

posterior_params_independent <- function(beta_hat, se_hat, prior_sd = 10) {
  prior_var <- prior_sd^2
  se_var <- se_hat^2

  post_var <- (se_var * prior_var) / (se_var + prior_var)
  post_mean <- (prior_var / (se_var + prior_var)) * beta_hat

  list(mean = post_mean, sd = sqrt(post_var))
}

simulate_hcrs_risk <- function(age, haematuria, sex, smoking, n_sim, threshold) {
  post <- posterior_params_independent(beta_hat, se_hat, prior_sd)

  beta_draws <- matrix(
    rnorm(
      n = n_sim * length(beta_hat),
      mean = rep(post$mean, each = n_sim),
      sd = rep(post$sd, each = n_sim)
    ),
    nrow = n_sim,
    ncol = length(beta_hat)
  )

  colnames(beta_draws) <- names(beta_hat)

  x <- c(
    Intercept = 1,
    Age = age,
    VisibleHaematuria = ifelse(haematuria == "Visible", 1, 0),
    Male = ifelse(sex == "Male", 1, 0),
    ExSmoker = ifelse(smoking == "Ex-smoker", 1, 0),
    CurrentSmoker = ifelse(smoking == "Current smoker", 1, 0)
  )

  eta <- as.numeric(beta_draws %*% x)
  p <- inv_logit(eta)

  list(
    draws = p,
    mean = mean(p),
    median = median(p),
    lower = quantile(p, 0.025),
    upper = quantile(p, 0.975),
    threshold_prob = mean(p >= threshold)
  )
}

calculate_hcrs_points <- function(age, haematuria, sex, smoking) {
  age_points <- age

  haematuria_points <- ifelse(haematuria == "Visible", 24.5, 0)
  sex_points <- ifelse(sex == "Male", 10.5, 0)

  smoking_points <- switch(
    smoking,
    "Non-smoker" = 0,
    "Ex-smoker" = 7.5,
    "Current smoker" = 17.1,
    0
  )

  age_points + haematuria_points + sex_points + smoking_points
}

ui <- fluidPage(
  titlePanel("Bayesian HCRS Risk Uncertainty Tool"),

  sidebarLayout(
    sidebarPanel(
      h4("Patient profile"),

      numericInput(
        "age",
        "Age",
        value = 70,
        min = 18,
        max = 100,
        step = 1
      ),

      selectInput(
        "haematuria",
        "Haematuria type",
        choices = c("Non-visible", "Visible"),
        selected = "Visible"
      ),

      selectInput(
        "sex",
        "Sex",
        choices = c("Female", "Male"),
        selected = "Male"
      ),

      selectInput(
        "smoking",
        "Smoking status",
        choices = c("Non-smoker", "Ex-smoker", "Current smoker"),
        selected = "Current smoker"
      ),

      hr(),

      h4("RBUS result"),

      selectInput(
        "rbus",
        "Renal bladder ultrasound result",
        choices = c(
          "Not available",
          "Normal",
          "Suspicious for bladder cancer"
        ),
        selected = "Not available"
      ),

      hr(),

      h4("Bayesian uncertainty settings"),

      numericInput(
        "threshold",
        "Risk threshold",
        value = 0.30,
        min = 0.01,
        max = 0.99,
        step = 0.01
      ),

      numericInput(
        "n_sim",
        "Number of posterior simulations",
        value = 8000,
        min = 1000,
        max = 100000,
        step = 1000
      ),

      actionButton("run", "Update calculation")
    ),

    mainPanel(
      h3("Uncertainty-aware predicted cancer risk"),

      verbatimTextOutput("risk_summary"),

      plotOutput("risk_plot", height = "350px"),

      hr(),

      h3("Published HCRS points-based score"),

      verbatimTextOutput("hcrs_points_output"),

      hr(),

      h3("Combined HCRS--RBUS triage rule"),

      verbatimTextOutput("hcrs_rbus_rule_output"),

      hr(),

      h4("Interpretation and disclaimer"),

      p(
        "This application reconstructs the coefficient-based HCRS model using ",
        "published regression coefficients and standard errors. It propagates ",
        "coefficient uncertainty to patient-level predicted cancer risk using a ",
        "Bayesian summary-likelihood approximation."
      ),

      p(
        "The app also displays the published points-based HCRS and the ",
        "HCRS--RBUS cystoscopy triage rule. In the published validation study, ",
        "cystoscopy was recommended for patients with HCRS >= 82 and/or suspicious RBUS."
      ),

      p(
        strong("Important: "),
        "This tool is for methodological demonstration and research use only. ",
        "It is not a clinical decision tool and should not replace clinician assessment, ",
        "local guidelines, or validated diagnostic pathways."
      )
    )
  )
)

server <- function(input, output, session) {

  results <- eventReactive(input$run, {
    set.seed(123)

    simulate_hcrs_risk(
      age = input$age,
      haematuria = input$haematuria,
      sex = input$sex,
      smoking = input$smoking,
      n_sim = input$n_sim,
      threshold = input$threshold
    )
  }, ignoreNULL = FALSE)

  hcrs_points <- reactive({
    calculate_hcrs_points(
      age = input$age,
      haematuria = input$haematuria,
      sex = input$sex,
      smoking = input$smoking
    )
  })

  output$risk_summary <- renderText({
    res <- results()

    paste0(
      "Posterior mean predicted risk: ", round(res$mean, 3), "\n",
      "Posterior median predicted risk: ", round(res$median, 3), "\n",
      "95% credible interval: [",
      round(res$lower, 3), ", ", round(res$upper, 3), "]\n",
      "Decision threshold: ", round(input$threshold, 3), "\n",
      "Pr(predicted risk >= threshold): ",
      round(res$threshold_prob, 3)
    )
  })

  output$risk_plot <- renderPlot({
    res <- results()

    df <- data.frame(risk = res$draws)

    ggplot(df, aes(x = risk)) +
      geom_histogram(
        aes(y = after_stat(density)),
        bins = 40,
        fill = "grey80",
        colour = "grey30"
      ) +
      geom_density(linewidth = 1) +
      geom_vline(
        xintercept = res$median,
        linetype = "dashed",
        linewidth = 1
      ) +
      geom_vline(
        xintercept = c(res$lower, res$upper),
        linetype = "dotted",
        linewidth = 1
      ) +
      geom_vline(
        xintercept = input$threshold,
        colour = "red",
        linetype = "longdash",
        linewidth = 1
      ) +
      labs(
        x = "Predicted cancer risk",
        y = "Density",
        title = "Posterior distribution of predicted cancer risk",
        subtitle = "Dashed = median; dotted = 95% credible interval; red = selected threshold"
      ) +
      theme_minimal(base_size = 14)
  })

  output$hcrs_points_output <- renderText({
    pts <- hcrs_points()

    paste0(
      "Published HCRS points score = ", round(pts, 1), "\n",
      "Published HCRS cutoff = 82\n\n",
      "Point components:\n",
      "Age: ", input$age, "\n",
      "Visible haematuria: ",
      ifelse(input$haematuria == "Visible", "24.5", "0"), "\n",
      "Male sex: ",
      ifelse(input$sex == "Male", "10.5", "0"), "\n",
      "Smoking: ",
      switch(
        input$smoking,
        "Non-smoker" = "0",
        "Ex-smoker" = "7.5",
        "Current smoker" = "17.1"
      ),
      "\n\n",
      "HCRS-only recommendation: ",
      ifelse(
        pts >= 82,
        "Cystoscopy recommended based on HCRS points.",
        "Below HCRS points cutoff."
      )
    )
  })

  output$hcrs_rbus_rule_output <- renderText({
    pts <- hcrs_points()

    hcrs_positive <- pts >= 82
    rbus_positive <- input$rbus == "Suspicious for bladder cancer"

    combined_positive <- hcrs_positive || rbus_positive

    paste0(
      "Combined HCRS--RBUS rule:\n",
      "Cystoscopy recommended if HCRS >= 82 and/or RBUS is suspicious.\n\n",
      "Current HCRS points score: ", round(pts, 1), "\n",
      "RBUS result: ", input$rbus, "\n\n",
      "Combined recommendation: ",
      ifelse(
        combined_positive,
        "Cystoscopy recommended under the published HCRS--RBUS triage rule.",
        "Cystoscopy may be omitted under the published HCRS--RBUS triage rule, subject to clinical judgement."
      ),
      "\n\n",
      "Note: The Bayesian uncertainty interval above applies to the reconstructed ",
      "coefficient-based HCRS logistic model. The RBUS result is implemented here ",
      "as a deterministic rule-based triage modifier."
    )
  })
}

shinyApp(ui = ui, server = server)
