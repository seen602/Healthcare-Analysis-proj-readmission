# 🏥 Patient 30-Day Readmission Analysis
### End-to-End Healthcare Data Analysis Portfolio Project

![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)
![SQL](https://img.shields.io/badge/SQL-SQLite-orange?logo=sqlite)
![pandas](https://img.shields.io/badge/Analysis-pandas%20%2F%20scipy-150458?logo=pandas)
![Power BI](https://img.shields.io/badge/BI-Power%20BI%20%2F%20Tableau-F2C811?logo=powerbi)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 📌 Overview

This project performs a complete end-to-end healthcare data analysis on **101,766 real diabetic patient encounters** from 130 US hospitals to identify who is at highest risk of 30-day readmission — using SQL, statistical testing, and a transparent rule-based risk scoring system.

> **No machine learning used.** All findings are derived from SQL queries, descriptive statistics, t-tests, chi-square tests, and a fully auditable rule-based score — explainable to any clinical stakeholder.

**Business context:** Under the CMS Hospital Readmissions Reduction Program (HRRP), hospitals face penalties of up to 3% of base Medicare payments for excess readmissions. Proactive risk stratification at discharge can significantly reduce this exposure.

---

## 📊 Real Results

| Metric | Value |
|--------|-------|
| Raw records | 101,766 |
| Records after cleaning | 69,987 |
| Overall readmission rate | 9.0% |
| Patients with 3+ prior stays | 26.5% readmission rate **(3.3x lift)** |
| Critical-tier readmission rate | 21.1% |
| Patients flagged Critical | 521 (0.7% of cohort) |

---

## 🗂️ Project Structure

```
healthcare-readmission/
│
├── 📓 healthcare_readmission_analysis.ipynb   ← Main analysis notebook
├── 📄 readmission_analysis_report.docx        ← Written report
├── 🗄️ sql/
│   └── analysis_queries.sql                   ← All SQL queries standalone
├── 📁 visuals/
│   ├── 01_cleaning_summary.png
│   ├── 02_eda_charts.png
│   ├── 03_segment_analysis.png
│   └── 04_risk_scoring.png
├── scored_patients.csv                        ← Power BI / Tableau data source
├── .gitignore
└── README.md
```

---

## 🔬 Dataset

| Property | Detail |
|----------|--------|
| **Source** | [UCI ML Repository — Diabetes 130-US Hospitals (1999–2008)](https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008) |
| **Download** | `diabetic_data.csv` → place in project root |
| **Size** | 101,766 encounters × 50 features |
| **Target** | Readmitted within 30 days (binary) |

---

## 🧹 Data Cleaning Steps

| Step | Issue | Action | Records Affected |
|------|-------|--------|-----------------|
| 1 | `?` placeholders | Replaced with NaN | All columns |
| 2 | `weight` (97% missing), `max_glu_serum` (95% missing) | Dropped | 2 columns |
| 3 | Zero-variance cols (`examide`, `citoglipton`) | Dropped | 2 columns |
| 4 | Deceased / hospice patients | Removed | 2,423 rows |
| 5 | Invalid gender entries | Removed | 3 rows |
| 6 | Duplicate patient encounters | Kept first visit only | 29,353 rows |
| 7 | Remaining missing categoricals | Filled with 'Unknown' | — |

**Final clean dataset: 69,987 rows × 48 columns**

---

## 🔄 Analysis Pipeline

```
diabetic_data.csv
      ↓
Data Cleaning (pandas)   ── 7 cleaning steps, 31,779 rows removed
      ↓
SQL Analysis (SQLite)    ── 10 queries: cohort profiles, utilization, LOS buckets
      ↓
EDA (matplotlib/seaborn) ── Distributions, heatmaps, age segmentation
      ↓
Statistical Testing      ── t-test (numeric), chi-square + Cramér's V (categorical)
(scipy.stats)
      ↓
Segment Analysis         ── Diverging bars, stacked cohorts, bubble charts
      ↓
Rule-Based Risk Scoring  ── 0–10 point score → 4 tiers, validated vs actual rates
      ↓
scored_patients.csv      ── Power BI / Tableau dashboard data source
```

---

## 📈 Key Findings

### Significant Factors (t-test, p < 0.05)

| Variable | Readmitted | Not Readmitted | Difference |
|----------|-----------|----------------|------------|
| Prior Inpatient Visits | 0.37 | 0.16 | **+131%** |
| Prior Emergency Visits | 0.15 | 0.10 | **+50%** |
| Length of Stay | 4.79 days | 4.22 days | +14% |
| Num Medications | 16.62 | 15.57 | +7% |
| Number of Diagnoses | 7.51 | 7.20 | +4% |

### Readmission Rate by Age Group (Real Data)

| Age | Rate | Age | Rate |
|-----|------|-----|------|
| [0-10) | 2.0% | [60-70) | 9.0% |
| [50-60) | 7.1% | [70-80) | 10.2% |
| [80-90) | **10.8%** | [90-100) | 9.5% |

---

## 🚦 Rule-Based Risk Score

| Rule | Basis | Points |
|------|-------|--------|
| Prior inpatient stays × 2 (max 4) | Strongest predictor | 0–4 |
| Prior emergency visits (max 2) | Second strongest | 0–2 |
| LOS ≥ 7 days | Statistically significant | +1 |
| LOS ≥ 10 days | Extended stay risk | +1 |
| Medication changed at discharge | Chi-square significant | +1 |
| ≥ 20 medications | Polypharmacy risk | +1 |

### Tier Validation (Real Data)

| Tier | Score | % Patients | Actual Readmission Rate |
|------|-------|------------|------------------------|
| Low | 0–1 | ~67% | ~7.5% |
| Medium | 2–3 | ~25% | ~10.5% |
| High | 4–6 | ~7% | ~16.0% |
| Critical | 7–10 | ~0.7% | **~21.1%** |

---

## ⚙️ Setup & Usage

```bash
# Clone the repo
git clone https://github.com/seen602/healthcare-readmission.git
cd healthcare-readmission

# Install dependencies
pip install pandas numpy matplotlib seaborn scipy jupyter

# Download dataset
# → https://archive.ics.uci.edu/dataset/296
# → Place diabetic_data.csv in this folder

# Run notebook
jupyter notebook healthcare_readmission_analysis.ipynb
# OR in VS Code: open .ipynb directly
```

---

## 📈 Dashboard (Power BI)

Connect `scored_patients.csv` to your BI tool for an interactive dashboard.

**Recommended views:**
- KPI strip: total patients, readmission rate, % Critical tier
- Risk tier bar chart with patient drillthrough
- Readmission rate by age group (filterable by gender, race)
- Prior utilization heatmap
- High-risk patient outreach table (sorted by risk score)

---

## 💡 Clinical Recommendations

1. Prioritise discharge planning for all patients with **2+ prior inpatient stays**
2. Flag patients whose **medication was changed at discharge** for 48-hour follow-up call
3. Assign dedicated care coordinators to all **Critical-tier patients** before discharge
4. Implement structured **post-discharge phone calls** within 48–72 hours for High/Critical tiers
5. Review **insulin protocols** for patients with frequent emergency visits
6. **Embed risk score in EHR** discharge workflow as a real-time decision-support alert

---

## 👤 Author

**Kathe Sai Sreenivas** | Data Analyst  
📧 kathesreenivas.16@gmail.com.com | 🔗 [LinkedIn](https://linkedin.com/in/kathe-sreenivas) 

---

