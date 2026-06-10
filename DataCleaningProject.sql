-- DATA CLEANING PROJECT
-- Goal:
-- Clean the raw layoffs dataset by:
-- 1. Removing duplicates
-- 2. Standardizing data formats
-- 3. Handling null and blank values
-- 4. Removing unnecessary rows and columns


-- =========================================================
-- STEP 0: CREATE A STAGING TABLE
-- =========================================================
-- Never clean the raw dataset directly.
-- Create a copy so the original data remains unchanged.

SELECT *
FROM layoffs;

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;


-- =========================================================
-- STEP 1: IDENTIFY DUPLICATES
-- =========================================================
-- Use ROW_NUMBER() to assign a sequence number to rows that
-- have identical values across important columns.
-- row_num = 1 -> keep
-- row_num > 1 -> duplicate

SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company,
                        industry,
                        total_laid_off,
                        percentage_laid_off,
                        `date`
       ) AS row_num
FROM layoffs_staging;


-- Check full duplicate definition using all relevant columns

WITH duplicate_cte AS
(
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


-- =========================================================
-- STEP 2: CREATE A NEW STAGING TABLE WITH ROW NUMBERS
-- =========================================================
-- Since MySQL doesn't allow deleting directly from a CTE,
-- create another staging table to store row numbers.

CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- Insert data along with duplicate row numbers

INSERT INTO layoffs_staging2
(
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
);


-- Delete duplicate records
-- Keep only row_num = 1

DELETE
FROM layoffs_staging2
WHERE row_num > 1;


SELECT *
FROM layoffs_staging2;


-- =========================================================
-- STEP 3: STANDARDIZE DATA
-- =========================================================
-- Make values consistent across the dataset.


-- -----------------------------------
-- 3A. Remove extra spaces from company names
-- -----------------------------------

SELECT
    company,
    TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);


-- -----------------------------------
-- 3B. Standardize industry names
-- -----------------------------------
-- Example:
-- Crypto
-- Cryptocurrency
-- Crypto Currency
-- --> Crypto

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Cryto%';


SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;


-- -----------------------------------
-- 3C. Standardize country names
-- -----------------------------------
-- Example:
-- United States
-- United States.
-- --> United States

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT
    country,
    TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;


-- -----------------------------------
-- 3D. Convert date text into DATE format
-- -----------------------------------

SELECT
    `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');


-- Verify conversion

SELECT `date`
FROM layoffs_staging2;


-- Change column type from TEXT to DATE

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- =========================================================
-- STEP 4: HANDLE NULLS AND BLANK VALUES
-- =========================================================


-- -----------------------------------
-- 4A. Investigate rows with missing layoff information
-- -----------------------------------

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- -----------------------------------
-- 4B. Convert blank industries to NULL
-- -----------------------------------
-- Easier to work with NULL than empty strings

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';


-- Example inspection

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';


-- -----------------------------------
-- 4C. Populate missing industry values
-- -----------------------------------
-- If the same company appears elsewhere with a known industry,
-- copy that value into rows where industry is NULL.

SELECT
    t1.industry,
    t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
   AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;


UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- =========================================================
-- STEP 5: REMOVE UNUSABLE RECORDS
-- =========================================================
-- If both total_laid_off and percentage_laid_off are NULL,
-- the row contains no layoff information and is not useful.

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- =========================================================
-- STEP 6: REMOVE HELPER COLUMNS
-- =========================================================
-- row_num was only needed for duplicate detection.

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- =========================================================
-- FINAL RESULT
-- =========================================================
-- Cleaned dataset:
-- ✓ Duplicates removed
-- ✓ Company names standardized
-- ✓ Industry names standardized
-- ✓ Country names standardized
-- ✓ Dates converted to proper DATE format
-- ✓ Missing values handled where possible
-- ✓ Unusable rows removed
-- ✓ Temporary helper column removed

SELECT *
FROM layoffs_staging2;