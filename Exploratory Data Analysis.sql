-- EXPLORATORY DATA ANALYSIS (EDA)
-- Goal:
-- Explore the cleaned layoffs dataset to identify trends,
-- patterns, outliers, and key business insights.
--
-- Typical EDA questions:
-- - Which companies had the most layoffs?
-- - Which industries were hit hardest?
-- - Which countries experienced the largest layoffs?
-- - How did layoffs change over time?
-- - Who were the top companies by layoffs each year?


-- =========================================================
-- 1. VIEW CLEANED DATASET
-- =========================================================

SELECT *
FROM layoffs_staging2;


-- =========================================================
-- 2. FIND MAXIMUM LAYOFF VALUES
-- =========================================================
-- Understand the largest layoff event in the dataset.

SELECT
    MAX(total_laid_off) AS max_laid_off,
    MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2;


-- =========================================================
-- 3. COMPANIES WITH 100% LAYOFFS
-- =========================================================
-- percentage_laid_off = 1 means the entire workforce
-- was laid off.

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;


-- =========================================================
-- 4. TOTAL LAYOFFS BY COMPANY
-- =========================================================
-- Identify companies responsible for the largest total layoffs.

SELECT
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


-- =========================================================
-- 5. DATASET DATE RANGE
-- =========================================================
-- Determine the time span covered by the dataset.

SELECT
    MIN(`date`) AS earliest_date,
    MAX(`date`) AS latest_date
FROM layoffs_staging2;


-- =========================================================
-- 6. TOTAL LAYOFFS BY INDUSTRY
-- =========================================================
-- Which industries experienced the most layoffs?

SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;


-- =========================================================
-- 7. TOTAL LAYOFFS BY COUNTRY
-- =========================================================
-- Compare layoffs across countries.

SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;


-- =========================================================
-- 8. TOTAL LAYOFFS BY YEAR
-- =========================================================
-- Analyze yearly layoff trends.

SELECT
    YEAR(`date`) AS layoff_year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY layoff_year DESC;


-- =========================================================
-- 9. TOTAL LAYOFFS BY FUNDING STAGE
-- =========================================================
-- Determine which company stages were most affected.

SELECT
    stage,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;


-- =========================================================
-- 10. MONTHLY LAYOFF TOTALS
-- =========================================================
-- Aggregate layoffs by month.

SELECT
    SUBSTRING(`date`, 1, 7) AS `Month`,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `Month`
ORDER BY `Month` DESC;


-- =========================================================
-- 11. ROLLING (CUMULATIVE) LAYOFF TOTAL
-- =========================================================
-- Shows how layoffs accumulated over time.

WITH Rolling_Total AS
(
    SELECT
        SUBSTRING(`date`, 1, 7) AS `Month`,
        SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `Month`
)

SELECT
    `Month`,
    total_off,

    -- Running total from earliest month onward
    SUM(total_off) OVER (
        ORDER BY `Month`
    ) AS rolling_total

FROM Rolling_Total;


-- =========================================================
-- 12. TOTAL LAYOFFS BY COMPANY
-- =========================================================
-- Repeat analysis focused solely on company rankings.

SELECT
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


-- =========================================================
-- 13. COMPANY LAYOFFS BY YEAR
-- =========================================================
-- Calculate yearly layoffs for each company.

SELECT
    company,
    YEAR(`date`) AS layoff_year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY total_laid_off DESC;


-- =========================================================
-- 14. TOP 5 COMPANIES BY LAYOFFS EACH YEAR
-- =========================================================
-- Step 1:
-- Compute total layoffs for each company per year.
--
-- Step 2:
-- Rank companies within each year using DENSE_RANK().
--
-- Step 3:
-- Keep only the top 5 companies for every year.

WITH Company_Year (company, years, total_laid_off) AS
(
    SELECT
        company,
        YEAR(`date`),
        SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),

Company_Year_Rank AS
(
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY years
               ORDER BY total_laid_off DESC
           ) AS ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)

SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;


-- =========================================================
-- KEY SQL CONCEPTS USED IN THIS EDA
-- =========================================================
--
-- AGGREGATIONS
--   SUM()
--   MAX()
--   MIN()
--
-- GROUPING
--   GROUP BY
--
-- SORTING
--   ORDER BY
--
-- DATE FUNCTIONS
--   YEAR()
--   SUBSTRING()
--
-- WINDOW FUNCTIONS
--   SUM() OVER()
--   DENSE_RANK() OVER()
--
-- CTEs
--   WITH ... AS (...)
--
-- BUSINESS QUESTIONS ANSWERED
-- ✓ Largest layoff event
-- ✓ Companies with complete workforce layoffs
-- ✓ Most affected companies
-- ✓ Most affected industries
-- ✓ Most affected countries
-- ✓ Yearly layoff trends
-- ✓ Monthly layoff trends
-- ✓ Running cumulative layoffs
-- ✓ Top companies by layoffs each year