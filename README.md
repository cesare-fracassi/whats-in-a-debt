# Replication Package

## Paper

**"What's in a Debt? Rating Agency Methodologies and Firms' Financing and Investment Decisions"**

**Authors:** Cesare Fracassi and Gregory Weitzner

**Published in:** *Review of Corporate Finance Studies*

---

## Overview

This package contains all code required to replicate the tables and figures in the paper and online appendix. Because most of the underlying data are proprietary and distributed by commercial vendors, the raw data files are **not** included. Section 3 below provides detailed instructions on how to obtain each dataset.

---

## Package Structure

```
ReplicationPackage/
├── README.md                  ← this file
├── Code/
│   ├── Master_clean.do        ← Step 1: builds all datasets from raw data
│   └── Regressions_clean.do   ← Step 2: produces all tables and figures
├── Data/
│   ├── Raw/                   ← place raw data files here (see Section 3)
│   │   ├── Compustat/
│   │   ├── CRSP/
│   │   ├── Eikon/
│   │   ├── ICE-BAML/
│   │   ├── CDS/
│   │   ├── Market/            ← S&P 500 and 10Y Treasury (included, see Section 7)
│   │   └── Manual/
│   ├── Intermediate/          ← created automatically during Step 1
│   └── Processed/             ← created automatically during Step 1
└── Output/
    ├── Tables/                ← .tex files created during Step 2
    └── Figures/               ← .png files created during Step 2
```

---

## Replication Instructions

### Requirements

- **Stata** 14 or later (MP edition recommended for speed)
- The following Stata packages (install via `ssc install` if not already present):
  - `reghdfe`
  - `ftools`
  - `esttab` / `estout`
  - `iebaltab`
  - `mahapick`
  - `winsor2`
  - `listtex`

### Step 1 — Set the root path

Open `Code/Master_clean.do` and set the `global root` on line 26 to the path of the `ReplicationPackage/` folder on your machine:

```stata
global root "C:/path/to/ReplicationPackage"
```

Do the same in `Code/Regressions_clean.do` (line 16). All other paths are derived automatically.

### Step 2 — Place raw data files

Download the raw data (see Section 3) and place the files in the corresponding subfolders under `Data/Raw/`. The exact filenames expected by the code are listed in Section 3.

### Step 3 — Run the data pipeline

Run `Code/Master_clean.do` in Stata. This script:
- Loads and cleans Compustat quarterly data
- Constructs all variables (leverage ratios, controls, event indicators)
- Merges in ratings (Eikon), equity returns (CRSP), convertible debt (Manual), credit spreads (ICE-BAML), and CDS spreads
- Performs propensity-score matching
- Computes equity and credit spread event-study CARs
- Computes financial constraint indices (Whited-Wu, Kaplan-Zingales, Size-Age)
- Saves all processed datasets to `Data/Processed/` and `Data/Intermediate/`

A log file is saved to `Code/Master_clean.log`.

Estimated runtime: approximately 5–10 minutes.

### Step 4 — Run the analysis

Run `Code/Regressions_clean.do` in Stata. This script produces all tables (`.tex`) and figures (`.png`) in the paper and online appendix, saved to `Output/Tables/` and `Output/Figures/` respectively.

A log file is saved to `Code/Regressions_clean.log`.

---

## Data Sources

The following datasets must be obtained independently from their respective vendors and placed in the indicated subfolders.

### 1. Compustat Quarterly (`Data/Raw/Compustat/`)

**Source:** S&P Global Market Intelligence via Wharton Research Data Services (WRDS) — [wrds.wharton.upenn.edu](https://wrds.wharton.upenn.edu)

**Dataset:** Compustat North America — Fundamentals Quarterly

**Coverage:** US firms, 2006Q1–2015Q4. Exclude financial firms (SIC 6000–6999) and utilities (SIC 4900–4999).

**Key variables:** `gvkey`, `datadate`, `atq`, `dlttq`, `dlcq`, `seqq`, `ibq`, `dpq`, `saleq`, `ppentq`, `cheq`, `cshoq`, `prccq`, `cdvcy`, `pdvcy`, `ltq`, `sic`, `tic`, `cusip`, `conm`, `fyearq`, `fqtr`, `datacqtr`

**Expected filename:** `CompustatQ_v2.dta`

---

### 2. CRSP Daily Returns (`Data/Raw/CRSP/`)

**Source:** Center for Research in Security Prices via WRDS — [wrds.wharton.upenn.edu](https://wrds.wharton.upenn.edu)

**Dataset:** CRSP Daily Stock File

**Coverage:** All US common shares (share codes 10, 11), 2012–2015.

**Key variables:** `permno`, `date`, `ret`, `shrout`, `prc`, `ticker` (`tic`), `cusip`

**Expected filenames:**
- `Crsp Daily_v1.dta` — daily returns used for equity event-study CARs
- `Two year return_v1.dta` — 2-year buy-and-hold returns merged by CUSIP
- `Two year return_v1 Tic.dta` — same, merged by ticker

---

### 3. Eikon Ratings (`Data/Raw/Eikon/`)

**Source:** London Stock Exchange Group (LSEG) Eikon/Refinitiv Workspace

**Dataset:** Historical credit ratings — Moody's and S&P issuer ratings

**Coverage:** All firms in the Compustat sample, quarterly, 2006–2015.

**Key variables:** `gvkey`, `year`, `month`, Moody's rating, S&P rating

**Expected filename:** `Thomson Eikon_v2.dta`

---

### 4. ICE BofA (ICE-BAML) Credit Spreads (`Data/Raw/ICE-BAML/`)

**Source:** ICE Data Services — ICE BofA US High Yield Index constituents

**Dataset:** Daily option-adjusted spreads (OAS) for individual bonds in the US High Yield Index, used to compute credit spread CARs around the Moody's announcement.

**Coverage:** All bonds issued by firms in the sample, 2013.

**Key variables:** `sixdigitcusip`, date, OAS

**Expected filename:** `BAMLCAR_v1.dta`

---

### 5. CDS Spreads (`Data/Raw/CDS/`)

**Source:** Markit via WRDS or direct subscription — [ihsmarkit.com](https://ihsmarkit.com)

**Dataset:** Monthly CDS spreads for 5-year senior unsecured contracts.

**Coverage:** All firms in the sample for which CDS data are available.

**Key variables:** `gvkey`, `year`, `month`, CDS spread

**Expected filename:** `CDS Monthly.dta`

---

### 6. Market Data (`Data/Raw/Market/`)

**Source:** Yahoo Finance (^GSPC for S&P 500, ^TNX for 10-year Treasury yield)

**Dataset:** Daily closing prices/yields, June–September 2013. Used to compute cumulative market returns and Treasury yield changes around the July 31, 2013 announcement (Table A.15).

**Coverage:** June 1 – September 30, 2013.

**Expected filenames:**
- `SP500.csv` — S&P 500 daily closing prices (`observation_date`, `SP500`)
- `TNX.csv` — 10-year Treasury daily yields in percent (`observation_date`, `TNX`)

These files are **included** in the package (`Data/Raw/Market/`) and do not need to be obtained separately.

---

### 7. Manual Data (`Data/Raw/Manual/`)

These files were hand-collected by the authors and are available upon request.

- **`Preferred Manual_v1.dta`** — hand-collected preferred stock amounts and characteristics for treated firms, matched by CUSIP.
- **`Preferred Manual Foreign_v1.dta`** — same, for foreign-incorporated treated firms.
- **`Convert_v2.dta`** — hand-collected convertible debt data matched by Compustat `gvkey`.

---

## Output Files

Running both scripts in sequence produces the following outputs:

### Tables (`Output/Tables/`)

| File | Paper location |
|------|---------------|
| `summary.tex` | Table 2: Summary Statistics |
| `placebo.tex` | Table 4: Yearly Placebo Tests |
| `debt.tex` | Table 3: Effect on Debt Levels |
| `leverage.tex` | Table 5: Effect on Leverage |
| `real.tex` | Table 6: Effect on Balance Sheet |
| `combinedplacebo.tex` | Table 7: Placebo Tests: Alternate Treatment Groups |
| `car.tex` | Table 8: Stock Price Response |
| `carspreadsNewMatch.tex` | Table 9: Credit Spread Response |
| `converts.tex` | Table 10: Effect of Convertible Debt |
| `preferred2.tex` | Table 11: Effect on Preferred Stock |
| `ratings.tex` | Table 12: Effect on Credit Ratings |
| `list.tex` | Table A.1: List of Treated Firms |
| `fin_constraints_balance.tex` | Table A.2: Financial Constraint Measures |
| `rating.tex` | Table A.3: Ratings and LevGAAP |
| `3diff2.tex` | Table A.4: Triple Diff — S&P Rated |
| `3diff.tex` | Table A.4 (variant): Triple Diff — S&P Positive |
| `debtunmatched.tex` | Table A.5: Debt — Full Sample |
| `placebounmatched.tex` | Table A.6: Yearly Placebo — Full Sample |
| `leveragefullsample.tex` | Table A.7: Leverage — Full Sample |
| `realfullsample.tex` | Table A.8: Balance Sheet — Full Sample |
| `carunmatched.tex` | Table A.9: Stock Price CAR — Full Sample |
| `carspreadsUnMatched.tex` | Table A.10: Credit Spread CAR — Full Sample |
| `convertsunmatched.tex` | Table A.11: Convertibles — Full Sample |
| `ratingsfullsample.tex` | Table A.12: Credit Ratings — Full Sample |
| `diffcontrols.tex` | Table A.13: GAAP Leverage — IG Control |
| `debttoassets2.tex` | Table A.14: Debt-to-Assets |
| `prefdet.tex` | Table A.16: Determinants of Preferred Stock |
| `convertdet.tex` | Table A.17: Determinants of Convertibles |
| `convertIGplacebo.tex` | Table A.18: Convertibles — IG Firms as Control |
| `debt_1norep.tex` | Table A.19: Debt — 1 Match, No Replacement |
| `leverage_1norep.tex` | Table A.20: Leverage — 1 Match, No Replacement |
| `real_1norep.tex` | Table A.21: Balance Sheet — 1 Match, No Replacement |
| `ppe_asinh.tex` | Table A.22: PPE — Inverse Hyperbolic Sine |
| `converts_dummy.tex` | Table A.23: Convertibles — Dummy Variable |
| `markettrends.tex` | Table A.15: Market Trends around Announcement |

### Figures (`Output/Figures/`)

| File | Paper location |
|------|---------------|
| `RALev_Histogram.png` | Figure 1: Preferred Stock Histogram |
| `RL TS Continous Matched.png` | Figure 2: Time Trends — Debt Levels |
| `Logdebt TS Continous Matched.png` | Figure 3: Time Trends — Leverage |
| `Assets TS Continous Matched.png` | Figure 4: Time Trends — Assets |
| `PPE TS Continous Matched.png` | Figure 4: Time Trends — PP&E |
| `WW_w_density.png` | Figure A.1: Financial Constraints (Whited-Wu) |
| `KZ_w_density.png` | Figure A.1: Financial Constraints (Kaplan-Zingales) |
| `SA_w_density.png` | Figure A.1: Financial Constraints (Size-Age) |

---

## Contact

For questions about the data or code, please contact the authors.
