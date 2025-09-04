-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

SELECT * 
FROM world_layoff.layoffs;

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. 
-- We want a table with the raw data in case something happens
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways

-- 1. Remove Duplicates

# First let's check for duplicates
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT * FROM duplicate_cte 
WHERE row_num > 1;

WITH duplicate_cte AS
(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
DELETE 
FROM duplicate_cte 
WHERE row_num > 1;

-- one solution, which I think is a good one. Is to create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_Staging2;

INSERT INTO layoffs_Staging2
SELECT *, 
	ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
    percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_Staging2
WHERE row_num >1;

SELECT * FROM layoffs_Staging2;

----------------------------------------------------------------------------------------------------------------

-- 2. Standardize the data

SELECT company, TRIM(company) FROM layoffs_Staging2;
UPDATE layoffs_Staging2
SET company = TRIM(company);

-- I noticed the Crypto has multiple different variations. We need to standardize that - let's say all to Crypto

SELECT DISTINCT industry FROM layoffs_Staging2;
UPDATE layoffs_Staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
----------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT industry FROM layoffs_Staging2;

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_Staging2
ORDER BY 1;

UPDATE layoffs_Staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country FROM layoffs_Staging2
ORDER BY 1;

-- Date fixing
-- Let's also fix the date columns:
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_Staging2;

UPDATE layoffs_Staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_Staging2
MODIFY COLUMN `date` DATE;

SELECT * FROM layoffs_Staging2;


-- industry fixing

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these
SELECT * FROM layoffs_Staging2
WHERE industry IS NULL OR industry = '' ;

-- let's take a look at these
SELECT * FROM layoffs_Staging2
WHERE company LIKE 'Airb%';
-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- we should set the blanks to nulls since those are typically easier to work with
UPDATE layoffs_Staging2
SET industry = NULL
WHERE industry = '';

-- now if we check those are all nul
SELECT * FROM layoffs_Staging2
WHERE industry IS NULL OR industry = '' 
ORDER BY industry;

-- now we need to populate those nulls if possible
UPDATE layoffs_Staging2 AS t1
JOIN layoffs_Staging2 AS t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- and if we check it looks like Bally's was the only one without a populated row to populate this null values
SELECT * FROM layoffs_Staging2
WHERE industry IS NULL;

SELECT * FROM layoffs_Staging2
WHERE company LIKE 'bally%';

-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- so there isn't anything I want to change with the null values


-- 4. remove any columns and rows we need to
SELECT * FROM layoffs_Staging2
WHERE total_laid_off IS NULL;

SELECT * FROM layoffs_Staging2
WHERE percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM layoffs_Staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_Staging2;

ALTER TABLE layoffs_Staging2
DROP COLUMN row_num;
