-- ============================================================
-- PROJECT: Tech Layoffs Dataset — Data Cleaning
-- Author:  Ruhanesh Suthan
-- Tool:    MySQL
-- Dataset: https://github.com/AlexTheAnalyst/MySQL-YouTube-Series
-- ============================================================
-- Goal:
--   Clean the raw layoffs dataset by:
--   1. Removing duplicates
--   2. Standardizing data formats
--   3. Handling null and blank values
--   4. Removing unnecessary rows and columns
-- ============================================================
 
 
-- ============================================================
-- STEP 0: CREATE A STAGING TABLE
-- ============================================================
-- Best practice: never modify the raw table directly.
-- Always work on a copy so the original data is preserved.
 
SELECT *
FROM layoffs;
 
CREATE TABLE layoffs_staging
LIKE layoffs;
 
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;
 
SELECT *
FROM layoffs_staging;
 
 
-- ============================================================
-- STEP 1: IDENTIFY DUPLICATES
-- ============================================================
-- Use ROW_NUMBER() to flag rows that share identical values
-- across all key columns.
--   row_num = 1 → keep (first occurrence)
--   row_num > 1 → duplicate (to be removed)
 
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company,
                            location,
                            industry,
                            total_laid_off,
                            percentage_laid_off,
                            `date`,
                            stage,
                            country,
                            funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
 
 
-- ============================================================
-- STEP 2: CREATE STAGING TABLE WITH ROW NUMBERS
-- ============================================================
-- MySQL does not support DELETE directly from a CTE,
-- so we create a second staging table that includes row_num
-- as a physical column for easy deletion.
 
CREATE TABLE layoffs_staging2 (
    company               TEXT,
    location              TEXT,
    industry              TEXT,
    total_laid_off        INT          DEFAULT NULL,
    percentage_laid_off   TEXT,
    `date`                TEXT,
    stage                 TEXT,
    country               TEXT,
    funds_raised_millions INT          DEFAULT NULL,
    row_num               INT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;
 
 
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company,
                        location,
                        industry,
                        total_laid_off,
                        percentage_laid_off,
                        `date`,
                        stage,
                        country,
                        funds_raised_millions
       ) AS row_num
FROM layoffs_staging;
 
 
-- Remove duplicates (keep only row_num = 1)
DELETE
FROM layoffs_staging2
WHERE row_num > 1;
 
SELECT *
FROM layoffs_staging2;
 
 
-- ============================================================
-- STEP 3: STANDARDIZE DATA
-- ============================================================
-- Ensure consistent formatting across text columns.
 
 
-- 3A. Trim leading/trailing whitespace from company names
-- -------------------------------------------------------
SELECT company, TRIM(company)
FROM layoffs_staging2;
 
UPDATE layoffs_staging2
SET company = TRIM(company);
 
 
-- 3B. Standardize industry names
-- -------------------------------------------------------
-- Problem: 'Crypto', 'Cryptocurrency', 'Crypto Currency'
--          are all the same industry.
-- Solution: Normalise everything matching 'Crypto%' → 'Crypto'
 
SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';
 
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
 
-- Verify
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;
 
 
-- 3C. Standardize country names
-- -------------------------------------------------------
-- Problem: 'United States' vs 'United States.' (trailing dot)
-- Solution: Strip trailing period from affected rows.
 
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;
 
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
 
-- Verify
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
 
 
-- 3D. Convert date column from TEXT to proper DATE type
-- -------------------------------------------------------
-- Raw format: MM/DD/YYYY (stored as text)
 
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;
 
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
 
-- Change the column data type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
 
-- Verify
SELECT `date` FROM layoffs_staging2 LIMIT 10;
 
 
-- ============================================================
-- STEP 4: HANDLE NULLS AND BLANK VALUES
-- ============================================================
 
 
-- 4A. Inspect rows missing both layoff columns
-- -------------------------------------------------------
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
 
 
-- 4B. Convert blank industry strings to NULL
-- -------------------------------------------------------
-- NULL is easier to filter and join on than empty strings.
 
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
 
-- Verify
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;
 
 
-- 4C. Backfill missing industry values via self-join
-- -------------------------------------------------------
-- Logic: if the same company appears elsewhere with a known
-- industry, copy that value into NULL-industry rows.
 
SELECT t1.company, t1.industry AS missing, t2.industry AS known
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON  t1.company  = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
 
UPDATE layoffs_staging2 AS t1
JOIN  layoffs_staging2 AS t2
    ON  t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
 
 
-- ============================================================
-- STEP 5: REMOVE UNUSABLE RECORDS
-- ============================================================
-- Rows where BOTH total_laid_off AND percentage_laid_off are
-- NULL carry no actionable layoff data → remove them.
 
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
 
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
 
 
-- ============================================================
-- STEP 6: DROP HELPER COLUMN
-- ============================================================
-- row_num was only needed for duplicate detection.
 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
 
 
-- ============================================================
-- FINAL RESULT
-- ============================================================
-- ✓ Duplicates removed
-- ✓ Company names trimmed
-- ✓ Industry names normalised
-- ✓ Country names normalised
-- ✓ Dates converted to DATE type
-- ✓ Blank strings converted to NULL
-- ✓ Missing industries backfilled via self-join
-- ✓ Unusable rows deleted
-- ✓ Temporary helper column removed
 
SELECT *
FROM layoffs_staging2;
