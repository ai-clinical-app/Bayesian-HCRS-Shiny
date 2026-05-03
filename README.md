# Bayesian HCRS Risk Uncertainty Tool

This repository contains an R Shiny application for reconstructing the Haematuria Cancer Risk Score (HCRS) with uncertainty using published coefficients and standard errors.

Live app: https://aiclinicallab.shinyapps.io/Bayesian-HCRS-Shiny/

## Overview

This app:

- Reconstructs the HCRS model from published summary statistics
- Simulates posterior uncertainty in coefficients
- Produces uncertainty-aware risk predictions
- Evaluates threshold-based decision stability

This tool is for research and educational purposes only.  
It is not a validated clinical decision tool and should not be used as a standalone basis for clinical decision-making.

---

## Features

- Posterior simulation of model coefficients
- Distribution of predicted cancer risk
- 95% credible intervals
- Threshold-crossing probability
- Interactive inputs for:
  - Age
  - Haematuria type (VH)
  - Sex
  - Smoking status (NonSmk, ExSmk, ExSmk)
  - Decision threshold
  - Number of posterior simulations

## Source model

This app reconstructs the Haematuria Cancer Risk Score (HCRS) described in:

Tan WS, Ahmad A, Feber A, Mostafid H, Cresswell J, Fankhauser CD, Waisbrod S, Hermanns T, Sasieni P, Kelly JD; DETECT I trial collaborators.  
**Development and validation of a haematuria cancer risk score to identify patients at risk of harbouring cancer.**  
*Journal of Internal Medicine.* 2019;285(4):436–445.  
https://pmc.ncbi.nlm.nih.gov/articles/PMC6446724/

## Reconstructed HCRS model

The published HCRS linear predictor is reconstructed as:

HCRS = -8.0655
       + 0.0553 × Age
       + 1.3480 × 
       + 0.5762 × Male
       + 0.4133 × ExSmk
       + 0.9432 × Smk