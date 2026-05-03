library(shiny)
library(ggplot2)

# -----------------------------
# HCRS coefficients and SEs
# -----------------------------

beta_hat <- c(
  Intercept = -8.0655,
  Age = 0.0553,
  VisibleHaematuria = 1.3480,
  Male = 0.5762,
  ExSmoker = 0.4133,
  CurrentSmoker = 0.9432
)

se <- c(
  Intercept = 0.4754,
  Age = 0.0059,
  VisibleHaematuria = 0.1946,
  Male = 0.1607,
  ExSmoker = 0.1475,
  CurrentSmoker = 0.2048
)

sigma0 <- 10

# Closed-form posterior under independent Normal summary likelihood
post_var <- (se^2 * sigma0^2) / (se^2 + sigma0^2)
post_mean <- (sigma0^2 / (se^2 + sigma0^2)) * beta_hat
post_sd <- sqrt(post_var)

# -----------------------------
# Helper functions
# -----------------------------

simulate_risk <- function(age, visible, male, smoking, M = 10000) {
  
  beta_draws <- matrix(
    NA,
    nrow = M,
    ncol = length(beta_hat)
  )
  
  for (k in seq_along(beta_hat)) {
    beta_draws[, k] <- rnorm(M, mean = post_mean[k], sd = post_sd[k])
  }
  
  ex_smoker <- ifelse(smoking == "Ex-smoker", 1, 0)
  current_smoker <- ifelse(smoking == "Current smoker", 1, 0)
  
  x <- c(
    Intercept = 1,
    Age = age,
    VisibleHaematuria = visible,
    Male = male,
    ExSmoker = ex_smoker,
    CurrentSmoker = current_smoker
  )
  
  eta <- beta_draws %*% x
  risk <- plogis(eta)
  
  return(as.numeric(risk))
}

# -----------------------------
# UI
# -----------------------------

ui <- fluidPage(
  
  titlePanel("Bayesian HCRS Risk Uncertainty Tool"),
  
  sidebarLayout(
    
    sidebarPanel(
      
      numericInput(
        inputId = "age",
        label = "Age",
        value = 70,
        min = 18,
        max = 100,
        step = 1
      ),
      
      selectInput(
        inputId = "haematuria",
        label = "Haematuria type",
        choices = c(
          "Non-visible haematuria" = 0,
          "Visible haematuria" = 1
        ),
        selected = 1
      ),
      
      selectInput(
        inputId = "sex",
        label = "Sex",
        choices = c(
          "Female" = 0,
          "Male" = 1
        ),
        selected = 1
      ),
      
      selectInput(
        inputId = "smoking",
        label = "Smoking status",
        choices = c(
          "Never smoker",
          "Ex-smoker",
          "Current smoker"
        ),
        selected = "Current smoker"
      ),
      
      sliderInput(
        inputId = "threshold",
        label = "Decision threshold",
        min = 0,
        max = 1,
        value = 0.30,
        step = 0.01
      ),
      
      numericInput(
        inputId = "M",
        label = "Posterior simulations",
        value = 10000,
        min = 1000,
        max = 50000,
        step = 1000
      )
    ),
    
    mainPanel(
      
      h3("Posterior predicted risk"),
      
      verbatimTextOutput("risk_summary"),
      
      plotOutput("risk_plot", height = "300px"),
      
      h3("Threshold-crossing uncertainty"),
      
      verbatimTextOutput("threshold_summary"),
      
      h3("Model note"),
      
      p(
        "This app reconstructs the HCRS using published coefficients and standard errors. ",
        "The default model assumes independent coefficient uncertainty under a Normal summary likelihood. ",
        "Predictions should be interpreted as uncertainty-aware reconstructions of the published model, ",
        "not as newly validated clinical recommendations."
      )
    )
  )
)

# -----------------------------
# Server
# -----------------------------

server <- function(input, output, session) {
  
  risk_draws <- reactive({
    simulate_risk(
      age = input$age,
      visible = as.numeric(input$haematuria),
      male = as.numeric(input$sex),
      smoking = input$smoking,
      M = input$M
    )
  })
  
  output$risk_summary <- renderPrint({
    
    risk <- risk_draws()
    
    risk_mean <- mean(risk)
    risk_median <- median(risk)
    risk_ci <- quantile(risk, probs = c(0.025, 0.975))
    
    cat("Posterior mean risk:   ", round(risk_mean, 3), "\n")
    cat("Posterior median risk: ", round(risk_median, 3), "\n")
    cat("95% credible interval: [",
        round(risk_ci[1], 3), ", ",
        round(risk_ci[2], 3), "]\n", sep = "")
  })
  
  output$risk_plot <- renderPlot({
    
    risk <- risk_draws()
    risk_ci <- quantile(risk, probs = c(0.025, 0.975))
    risk_median <- median(risk)
    
    df <- data.frame(risk = risk)
    
    ggplot(df, aes(x = risk)) +
      geom_histogram(
        aes(y = after_stat(density)),
        bins = 40,
        fill = "grey85",
        colour = "black"
      ) +
      geom_density(linewidth = 0.9) +
      geom_vline(
        xintercept = risk_median,
        linetype = "dashed",
        linewidth = 0.8
      ) +
      geom_vline(
        xintercept = risk_ci,
        linetype = "dotted",
        linewidth = 0.8
      ) +
      labs(
        x = "Predicted cancer risk",
        y = "Density"
      ) +
      theme_classic(base_size = 12)
  })
  
  output$threshold_summary <- renderPrint({
    
    risk <- risk_draws()
    threshold <- input$threshold
    
    q_t <- mean(risk >= threshold)
    
    cat("Threshold t: ", threshold, "\n")
    cat("Pr(risk >= t): ", round(q_t, 3), "\n\n")
    
    if (q_t > 0.95) {
      cat("Classification is highly stable above the threshold.\n")
    } else if (q_t < 0.05) {
      cat("Classification is highly stable below the threshold.\n")
    } else if (q_t > 0.25 && q_t < 0.75) {
      cat("Classification is sensitive to parameter uncertainty.\n")
    } else {
      cat("Classification shows moderate uncertainty.\n")
    }
  })
}

shinyApp(ui = ui, server = server)