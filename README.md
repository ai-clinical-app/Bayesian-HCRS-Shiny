# Bayesian HCRS Risk Uncertainty Tool

This repository contains an R Shiny application for reconstructing the Haematuria Cancer Risk Score (HCRS) with uncertainty using published coefficients and standard errors.

## Overview

This app:

- Reconstructs the HCRS model from published summary statistics  
- Simulates posterior uncertainty in coefficients  
- Produces uncertainty-aware risk predictions  
- Evaluates threshold-based decision stability  

⚠️ This tool is for research and educational purposes only.  
It is not a validated clinical decision tool.

---

## Features

- Posterior simulation of model coefficients  
- Distribution of predicted cancer risk  
- 95% credible intervals  
- Threshold-crossing probability  
- Interactive inputs (age, haematuria, sex, smoking)  

---

## Requirements

Install required R packages:

```r
install.packages(c("shiny", "ggplot2"))