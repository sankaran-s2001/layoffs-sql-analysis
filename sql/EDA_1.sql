-- EDA
-- Here I am just going to explore the data and find trends or patterns or anything interesting like outliers
-- normally when you start the EDA process you have some idea of what you're looking for
-- with this info we are just going to look around and see what we find!

SELECT * FROM world_layoff.layoffs_staging2;

SELECT MAX(total_laid_off) FROM layoffs_staging2;

-- Looking at Percentage to see how big these layoffs were
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off) FROM layoffs_staging2;

-- Which companies had 1 which is basically 100 percent of they company laid off
SELECT * FROM layoffs_staging2
WHERE percentage_laid_off = 1;
-- these are mostly startups it looks like who all went out of business during this time

-- if we order by funds_raised_millions we can see how big some of these companies were
SELECT * FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- Britishvolt was a UK startup manufacturer of lithium-ion batteries.
-- Quibi was an American short-form streaming platform

-- Companies with the biggest single Layoff
SELECT company, total_laid_off FROM layoffs_staging2
ORDER BY total_laid_off DESC
LIMIT 5;
-- now that's just on a single day

-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off) AS total_layoff FROM layoffs_staging2
GROUP BY company
ORDER BY total_layoff DESC
LIMIT 5;

-- by location
SELECT location, SUM(total_laid_off) AS total_layoff FROM layoffs_staging2
GROUP BY location
ORDER BY total_layoff DESC
LIMIT 5;

-- by year
SELECT YEAR(`date`) AS `by_year`, SUM(total_laid_off) AS total_layoff FROM layoffs_staging2
GROUP BY `by_year`
ORDER BY total_layoff DESC
LIMIT 5;

-- by industry
SELECT industry, SUM(total_laid_off) AS total_layoff FROM layoffs_staging2
GROUP BY industry
ORDER BY total_layoff DESC
LIMIT 5;

-- by stage
SELECT stage, SUM(total_laid_off) AS total_layoff FROM layoffs_staging2
GROUP BY stage
ORDER BY total_layoff DESC
LIMIT 5;


WITH company_year AS
(
	SELECT company, YEAR(`date`) AS `by_year`, SUM(total_laid_off) AS total_layoff FROM layoffs_staging2
	GROUP BY company, `by_year`
),

company_year_rank AS 
(
	SELECT company, by_year, total_layoff, DENSE_RANK() OVER(PARTITION BY by_year ORDER BY total_layoff DESC) AS den_rank
	FROM company_year
)
SELECT company, by_year, total_layoff, den_rank FROM company_year_rank
WHERE den_rank <= 3
AND by_year IS NOT NULL
ORDER BY by_year, total_layoff DESC;

-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off)  FROM layoffs_staging2
GROUP BY `Month`, total_laid_off
ORDER BY `Month`;

WITH DATE_CTE AS 
(
	SELECT SUBSTRING(date, 1, 7) AS dates, SUM(total_laid_off) AS sum_total_laid_off FROM layoffs_staging2
	GROUP BY dates, total_laid_off
	ORDER BY dates
)
SELECT dates, SUM(sum_total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs FROM DATE_CTE
ORDER BY dates ASC;









