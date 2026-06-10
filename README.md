#  Tech Layoffs — MySQL Data Cleaning & EDA

A two-part SQL project that takes a raw tech layoffs dataset through a full data pipeline: cleaning, standardisation, and exploratory analysis.

---

##  Project Overview

| Part | File | Description |
|------|------|-------------|
| 1 | `layoffs_data_cleaning.sql` | Remove duplicates, standardise formats, handle nulls |
| 2 | `layoffs_eda.sql` | Answer business questions through SQL queries |

**Tool:** MySQL  
**Dataset:** [Tech Layoffs — Alex the Analyst](https://github.com/AlexTheAnalyst/MySQL-YouTube-Series)

---

##  Dataset

The raw dataset contains records of tech company layoffs with the following columns:

| Column | Description |
|--------|-------------|
| `company` | Company name |
| `location` | Office location |
| `industry` | Sector/industry |
| `total_laid_off` | Number of employees laid off |
| `percentage_laid_off` | Share of workforce laid off (0–1) |
| `date` | Date of layoff event |
| `stage` | Funding stage (e.g. Series B, Post-IPO) |
| `country` | Country of the company |
| `funds_raised_millions` | Total funding raised (USD millions) |

---

##  Part 1: Data Cleaning

**File:** `layoffs_data_cleaning.sql`

The raw data had several quality issues that needed resolving before any analysis could be trusted.

### Steps taken

**1. Staging table**  
Copied the raw table into `layoffs_staging` before making any changes — preserving the original data.

**2. Duplicate removal**  
Used `ROW_NUMBER()` with `PARTITION BY` across all key columns to identify exact duplicates. Because MySQL doesn't support `DELETE` directly on a CTE, a second staging table (`layoffs_staging2`) was created to hold the row numbers as a physical column, enabling a clean `DELETE WHERE row_num > 1`.

**3. Standardisation**
- Trimmed leading/trailing whitespace from `company` names
- Normalised industry variants (`Crypto`, `Cryptocurrency`, `Crypto Currency` → `Crypto`)
- Removed trailing periods from country names (`United States.` → `United States`)
- Converted `date` from `TEXT` (MM/DD/YYYY) to a proper `DATE` type using `STR_TO_DATE()`

**4. Null handling**
- Converted blank `industry` strings to `NULL` for consistent filtering
- Used a self-join to backfill `NULL` industry values where the same company appeared elsewhere with a known industry
- Removed rows where both `total_laid_off` and `percentage_laid_off` were `NULL` (no usable data)

**5. Cleanup**  
Dropped the `row_num` helper column once deduplication was complete.

---

##  Part 2: Exploratory Data Analysis

**File:** `layoffs_eda.sql`

With clean data in place, SQL was used to answer key business questions.

### Questions answered

| Question | Technique |
|----------|-----------|
| What is the largest single layoff event? | `MAX()` |
| Which companies shut down entirely? | `WHERE percentage_laid_off = 1` |
| Which companies had the most total layoffs? | `SUM()` + `GROUP BY` |
| Which industries were hit hardest? | `SUM()` + `GROUP BY` |
| Which countries had the most layoffs? | `SUM()` + `GROUP BY` |
| How did layoffs change year-over-year? | `YEAR()` + `GROUP BY` |
| How did layoffs change month-over-month? | `SUBSTRING(date, 1, 7)` + `GROUP BY` |
| What does the cumulative layoff trend look like? | `SUM() OVER (ORDER BY month)` |
| Who were the top 5 companies per year? | `DENSE_RANK() OVER (PARTITION BY year)` + CTE |

### Key SQL concepts used
- Aggregate functions: `SUM()`, `MAX()`, `MIN()`
- Window functions: `ROW_NUMBER()`, `DENSE_RANK()`, `SUM() OVER()`
- Common Table Expressions (CTEs)
- Date functions: `YEAR()`, `SUBSTRING()`, `STR_TO_DATE()`
- Self-joins for data backfilling

---

##  How to Run

1. Import the raw `layoffs.csv` dataset into a MySQL schema
2. Run `layoffs_data_cleaning.sql` first — this produces the cleaned table `layoffs_staging2`
3. Run `layoffs_eda.sql` against `layoffs_staging2`

> Tested on MySQL 8.0+

---

##  What I Learned

- How to safely clean data without touching the raw source (staging table pattern)
- Why `ROW_NUMBER()` + a physical staging table is needed for deduplication in MySQL
- How to backfill missing values using a self-join
- How window functions like `SUM() OVER()` and `DENSE_RANK()` enable running totals and rankings without subqueries

---

##  Repository Structure

```
├── layoffs_data_cleaning.sql   # Part 1: Data cleaning pipeline
├── layoffs_eda.sql             # Part 2: Exploratory analysis
└── README.md
```

---

## About

Built as part of a guided MySQL portfolio project. All analysis and improvements to the original code are my own.  
