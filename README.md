# Bayesian HCRS Risk Uncertainty Tool

This repository contains an R Shiny application for reconstructing the Haematuria Cancer Risk Score (HCRS) with uncertainty using published model coefficients and standard errors.

Live app: https://aiclinicallab.shinyapps.io/Bayesian-HCRS-Shiny/

---

## Overview

This app reconstructs the Haematuria Cancer Risk Score (HCRS), originally developed and externally validated by Tan, Ahmad, Feber and colleagues, to estimate the risk of bladder cancer in patients presenting with haematuria.

The app:

- Reconstructs the published coefficient-based HCRS model
- Simulates posterior uncertainty in model coefficients
- Produces uncertainty-aware patient-level risk predictions
- Displays 95% credible intervals for predicted risk
- Calculates the probability that predicted risk exceeds a user-defined threshold
- Displays the published points-based HCRS score
- Implements the published HCRS and renal bladder ultrasound (RBUS) triage rule

This tool is for methodological demonstration, research, and educational purposes only.  
It is not a validated clinical decision tool and should not be used as a standalone basis for clinical decision-making.

---

## Features

The Shiny app provides interactive inputs for:

- Age
- Haematuria type:
  - Non-visible haematuria
  - Visible haematuria
- Sex:
  - Female
  - Male
- Smoking status:
  - Non-smoker
  - Ex-smoker
  - Current smoker
- Renal bladder ultrasound result:
  - Not available
  - Normal
  - Suspicious for bladder cancer
- Risk threshold
- Number of posterior simulations

The app displays:

- Posterior mean predicted cancer risk
- Posterior median predicted cancer risk
- 95% credible interval for predicted risk
- Probability that predicted risk exceeds the selected threshold
- Histogram and density plot of simulated predicted risks
- Published HCRS points-based score
- Combined HCRS--RBUS cystoscopy triage recommendation

---

## Source publications

This app is based on two related DETECT I publications.

### 1. HCRS model development and validation

The coefficient-based and points-based Haematuria Cancer Risk Score are based on:

Tan WS, Ahmad A, Feber A, Mostafid H, Cresswell J, Fankhauser CD, Waisbrod S, Hermanns T, Sasieni P, Kelly JD; DETECT I trial collaborators.  
**Development and validation of a haematuria cancer risk score to identify patients at risk of harbouring cancer.**  
*Journal of Internal Medicine.* 2019;285(4):436–445.  
doi: 10.1111/joim.12868  
PMCID: PMC6446724  
PMID: 30521125  

Article: https://pmc.ncbi.nlm.nih.gov/articles/PMC6446724/

### 2. RBUS imaging and haematuria investigation study

The renal bladder ultrasound component and imaging-triage context are based on:

Tan WS, Sarpong R, Khetrapal P, et al.  
**Can Renal and Bladder Ultrasound Replace Computerized Tomography Urogram in Patients Investigated for Microscopic Hematuria?**  
*Journal of Urology.* 2018;200(5):973–980.  
doi: 10.1016/j.juro.2018.05.024  

Article: https://pmc.ncbi.nlm.nih.gov/articles/PMC6179963/

---

## Original study summary

The HCRS was developed using a prospective multicentre UK development cohort of 3,539 patients and externally validated in a Swiss cohort of 656 patients.

The final model used four routinely available clinical predictors:

- Age
- Type of haematuria
- Sex
- Smoking history

In the published study, the HCRS achieved:

- Development cohort AUC: 0.768, 95% CI 0.741–0.795
- Validation cohort AUC: 0.835, 95% CI 0.789–0.880
- Validation calibration slope: 1.215

Using a threshold of HCRS >= 4.015 in the validation cohort produced:

- Sensitivity: 98.6%
- Specificity: 30.5%

The authors reported that this threshold detected additional cancers that would have been missed by NICE referral criteria while reducing the number of patients requiring investigation compared with broader AUA-style referral criteria.

---

## Reconstructed coefficient-based HCRS model

The published coefficient-based HCRS linear predictor is:

```text
HCRS linear predictor =
  0.055 × Age
  + 1.348 × Visible haematuria
  + 0.576 × Male sex
  + 0.413 × Ex-smoker
  + 0.943 × Current smoker
