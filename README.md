# ICA-Catastrophe-Analysis-Oct2025-AmirahAlyaaAlya
Power BI dashboards, R scripts, and data analysis for Catastrophe ICA (October dataset). Includes frequency–severity , trend analysis, heatmaps, and catastrophe claim profiling. For CAS ARECA Competition 2025

# Catastrophe Claims Analysis (ICA – October Dataset)

This project contains my full analysis of catastrophe-related insurance claims using **Power BI** and **R**.  
The dataset includes multiple catastrophe types (Flood, Cyclone, Bushfire, Hail, Storm, Earthquake) with breakdowns by commercial and domestic claim categories.

The objective of this analysis is to understand:
- Claim patterns by catastrophe type  
- Severity and frequency trends  
- Changes in total claims over time  
- Which claim categories dominate for each peril  
- Data quality issues and preprocessing considerations  

This repository includes **Power BI dashboards**, **R scripts**, **cleaned datasets**, and documented methodology to support catastrophe modeling and actuarial insights.

---

# Data Cleaning & Pre-processing (Excel)

The dataset required several preprocessing steps before loading into Power BI and R.

### 1. Removed records with missing Loss Values **  
Rows with both empty Normalized Loss values & Original Normalized Values were deleted because:
- They distort severity calculations  
- They cannot be reliably imputed  
- They impact year-to-year comparisons  

### 2. Converted monetary fields to numeric values**  
Actions taken:
- Removed `$` symbols  
- Removed comma separators  
- Converted to **Number** format  
- Standardized to **two decimal places**

This ensures compatibility with:
- R numeric processing  
- Power BI measures  
- Aggregations and charts  

### 3. Replaced “–” with actual blanks**  
Dashes were originally used to represent missing values.  
They were replaced with empty cells so that:
- Power BI reads them as null  
- R reads them as NA  
- Visualisations and summary stats aren’t skewed

---

#  Power BI Dashboards

### 1.Claims Type by Catastrophe (100% stacked bar)**  
- Shows distribution of claim categories within each catastrophe  
- Highlights which claim types dominate (e.g., domestic motor for hail)

### 2. Total Claims Received by Year**  
- Aggregated total claims from 2016–2024  
- Reveals spikes in disaster-heavy periods (2020–2022)

### 3. Additional visuals include:**  
- Peril trends over time  
- Claim severity per peril  
- Claim frequency patterns  
- Normalized vs Original loss comparison  

Screenshots available in `/Figures`.

---

# R Analysis

### **Tools Used**
- `dplyr`  
- `ggplot2`  
- `lubridate`  
- `scales`  

### 1.Frequency Analysis**
- Counts number of claims per year/peril  
- Identifies peak catastrophe periods  

### 2. Severity Analysis**
- Calculates total claim cost  
- Can be done by year, type, or peril  
- Supports understanding of loss distribution patterns  

### 3. Trend Visualisation**
Includes:
- Line charts for severity over time  
- Bar charts for frequency  
- Dual plots combining normalized & original values  

R scripts are included in the `/R` folder.

---
The dataset was cleaned, transformed, visualised, and modelled mainly to:
- Understand historical patterns  
- Support better catastrophe pricing  
- Identify dominant claim drivers  
- Provide input to catastrophe reinsurance discussions  






