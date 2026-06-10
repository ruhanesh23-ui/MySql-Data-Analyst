-- ============================================================
-- PROJECT: Tech Layoffs Dataset — Exploratory Data Analysis
-- Author:  Ruhanesh Suthan
-- Tool:    MySQL
-- Dataset: https://github.com/AlexTheAnalyst/MySQL-YouTube-Series
-- ============================================================
-- Goal:
--   Explore the cleaned layoffs dataset to uncover trends,
--   patterns, and key business insights.
--
-- Questions answered:
--   - Which companies had the most total layoffs?
--   - Which industries were hit hardest?
--   - Which countries had the largest layoffs?
--   - How did layoffs change month-over-month and year-over-year?
--   - Who were the top 5 companies by layoffs each year?
-- ============================================================


-- ============================================================
-- 1. VIEW CLEANED DATASET
-- ============================================================

SELECT *
FROM layoffs_staging2;


-- ============================================================
-- 2. OVERALL MAXIMUMS
-- ============================================================
-- Quick sanity check — what are the largest individual events?

SELECT
    MAX(total_laid_off)      AS max_laid_off,
    MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2;


-- ============================================================
-- 3. COMPANIES WITH 100% WORKFORCE LAID OFF
-- ============================================================
-- percentage_laid_off = 1 → entire company was shut down.
-- Ordered by size to see the biggest closures first.

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;


-- ============================================================
-- 4. TOTAL LAYOFFS BY COMPANY (all time)
-- ============================================================

SELECT
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


-- ============================================================
-- 5. DATASET DATE RANGE
-- ============================================================

SELECT
    MIN(`date`) AS earliest_date,
    MAX(`date`) AS latest_date
FROM layoffs_staging2;


-- ============================================================
-- 6. TOTAL LAYOFFS BY INDUSTRY
-- ============================================================

SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;


-- ============================================================
-- 7. TOTAL LAYOFFS BY COUNTRY
-- ============================================================

SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;


-- ============================================================
-- 8. TOTAL LAYOFFS BY YEAR
-- ============================================================

SELECT
    YEAR(`date`)        AS layoff_year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY layoff_year ASC;


-- ============================================================
-- 9. TOTAL LAYOFFS BY FUNDING STAGE
-- ============================================================
-- Are later-stage (Post-IPO) companies laying off more people
-- in absolute numbers than early-stage startups?

SELECT
    stage,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;


-- ============================================================
-- 10. MONTHLY LAYOFF TOTALS
-- ============================================================
-- Aggregate by YYYY-MM to see month-over-month trends.

SELECT
    SUBSTRING(`date`, 1, 7) AS `month`,
    SUM(total_laid_off)     AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;


-- ============================================================
-- 11. ROLLING (CUMULATIVE) LAYOFF TOTAL
-- ============================================================
-- Shows how total layoffs accumulated over the entire period.
-- Useful for visualising the overall trajectory.

WITH monthly_totals AS (
    SELECT
        SUBSTRING(`date`, 1, 7) AS `month`,
        SUM(total_laid_off)     AS monthly_laid_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `month`
)
SELECT
    `month`,
    monthly_laid_off,
    SUM(monthly_laid_off) OVER (
        ORDER BY `month`
    ) AS rolling_total
FROM monthly_totals
ORDER BY `month` ASC;


-- ============================================================
-- 12. COMPANY LAYOFFS BROKEN DOWN BY YEAR
-- ============================================================

SELECT
    company,
    YEAR(`date`)        AS layoff_year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY total_laid_off DESC;


-- ============================================================
-- 13. TOP 5 COMPANIES BY LAYOFFS — PER YEAR
-- ============================================================
-- Multi-step CTE approach:
--   Step 1 (Company_Year):      Sum layoffs per company per year.
--   Step 2 (Company_Year_Rank): Rank companies within each year
--                               using DENSE_RANK().
--   Step 3:                     Filter to top 5 per year.

WITH Company_Year AS (
    SELECT
        company,
        YEAR(`date`)        AS `year`,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS (
    SELECT
        company,
        `year`,
        total_laid_off,
        DENSE_RANK() OVER (
            PARTITION BY `year`
            ORDER BY total_laid_off DESC
        ) AS ranking
    FROM Company_Year
    WHERE `year` IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5
ORDER BY `year` ASC, ranking ASC;


-- ============================================================
-- SQL CONCEPTS USED IN THIS EDA
-- ============================================================
--
-- AGGREGATE FUNCTIONS  → SUM(), MAX(), MIN()
-- GROUPING             → GROUP BY
-- SORTING              → ORDER BY
-- DATE FUNCTIONS       → YEAR(), SUBSTRING()
-- WINDOW FUNCTIONS     → SUM() OVER(), DENSE_RANK() OVER()
-- CTEs                 → WITH ... AS (...)
--
-- ============================================================
-- BUSINESS QUESTIONS ANSWERED
-- ============================================================
-- ✓ Largest single layoff event
-- ✓ Companies that shut down completely
-- ✓ Most affected companies (all-time)
-- ✓ Most affected industries
-- ✓ Most affected countries
-- ✓ Year-over-year layoff trends
-- ✓ Month-over-month layoff trends
-- ✓ Running cumulative layoff total
-- ✓ Top 5 companies by layoffs each year
