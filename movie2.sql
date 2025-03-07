-- Step 1: Review initial data (optional sanity check)
SELECT * FROM `biniyam-452918.movies.movie2`;

-- Step 2: Standardize 'age_limit' column for consistency
UPDATE `biniyam-452918.movies.movie2`
SET age_limit = CASE
    WHEN age_limit = 'A' THEN '18'
    WHEN age_limit = 'TV-MA' THEN '17'
    WHEN age_limit = 'PG' THEN '10'
    WHEN age_limit = 'X' THEN '18'
    WHEN age_limit = 'Unknown' THEN '-1'
    WHEN age_limit = 'Approved' THEN '0'
    WHEN age_limit = '12A' THEN '12'
    WHEN age_limit = '16' THEN '16'
    WHEN age_limit = 'PG-13' THEN '13'
    WHEN age_limit = 'Not rated' THEN '-1'
    WHEN age_limit = 'U' THEN '0'
    WHEN age_limit = 'Rejected' THEN '-1'
    WHEN age_limit = '12' THEN '12'
    WHEN age_limit = 'R' THEN '17'
    WHEN age_limit = '18' THEN '18'
    WHEN age_limit = 'AA' THEN '18'
    ELSE age_limit
END
WHERE age_limit IN (
    'A', 'TV-MA', 'PG', 'X', 'Unknown', 'Approved', 
    '12A', '16', 'PG-13', 'Not rated', 'U', 'Rejected', 
    '12', 'R', '18', 'AA'
);

-- Set NULL age limits to 'Unknown' for consistency
UPDATE `biniyam-452918.movies.movie2`
SET age_limit = 'Unknown'
WHERE age_limit IS NULL;

-- Step 3: Remove temporary column (if created earlier)
ALTER TABLE `biniyam-452918.movies.movie2`
DROP COLUMN IF EXISTS Metascore_status;

-- Step 4: Parse and convert 'duration' to minutes (duration cleanup)
ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN duration_minutes INT64;

UPDATE `biniyam-452918.movies.movie2`
SET duration_minutes = 
    CASE 
        WHEN REGEXP_CONTAINS(duration, r'(\d+)h (\d+)m') THEN 
            CAST(REGEXP_EXTRACT(duration, r'(\d+)h') AS INT64) * 60 
            + CAST(REGEXP_EXTRACT(duration, r'(\d+)m') AS INT64)
        WHEN REGEXP_CONTAINS(duration, r'(\d+)h') THEN 
            CAST(REGEXP_EXTRACT(duration, r'(\d+)h') AS INT64) * 60
        WHEN REGEXP_CONTAINS(duration, r'(\d+)m') THEN 
            CAST(REGEXP_EXTRACT(duration, r'(\d+)m') AS INT64)
        ELSE NULL
    END
WHERE duration IS NOT NULL;

-- Drop the original duration column (optional)
ALTER TABLE `biniyam-452918.movies.movie2`
DROP COLUMN duration;

-- Step 5: Standardize 'rating' column to 2 decimal places
UPDATE `biniyam-452918.movies.movie2`
SET rating = ROUND(rating, 2)
WHERE rating IS NOT NULL;

-- Step 6: Remove duplicates based on key attributes (keeping the record with highest number of ratings)
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY rank, year, duration_minutes, rating 
                                 ORDER BY numberof_ratings DESC) AS rn
    FROM `biniyam-452918.movies.movie2`
)
DELETE FROM `biniyam-452918.movies.movie2`
WHERE rn > 1;

-- Step 7: Cleanup 'numberof_ratings' and convert to numeric (handling 'K' and 'M' abbreviations)
ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN number_of_ratings_clean INT64;

UPDATE `biniyam-452918.movies.movie2`
SET number_of_ratings_clean = 
    CASE 
        WHEN numberof_ratings LIKE '%K%' THEN 
            CAST(REPLACE(REPLACE(numberof_ratings, 'K', ''), 'M', '') AS FLOAT64) * 1000
        WHEN numberof_ratings LIKE '%M%' THEN 
            CAST(REPLACE(REPLACE(numberof_ratings, 'K', ''), 'M', '') AS FLOAT64) * 1000000
        ELSE 
            CAST(numberof_ratings AS INT64)
    END
WHERE numberof_ratings IS NOT NULL;

-- Drop old column and rename cleaned column
ALTER TABLE `biniyam-452918.movies.movie2`
DROP COLUMN numberof_ratings;

ALTER TABLE `biniyam-452918.movies.movie2`
RENAME COLUMN number_of_ratings_clean TO Number_of_ratings;

-- Step 8: Rename columns for clarity
ALTER TABLE `biniyam-452918.movies.movie2`
RENAME COLUMN name TO Title;

ALTER TABLE `biniyam-452918.movies.movie2`
RENAME COLUMN rank TO Movie_Rank;

-- Step 9: Add 'decade' column for feature engineering
ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN decade STRING;

UPDATE `biniyam-452918.movies.movie2`
SET decade = CASE 
    WHEN year BETWEEN 1920 AND 1929 THEN '1920s'
    WHEN year BETWEEN 1930 AND 1939 THEN '1930s'
    WHEN year BETWEEN 1940 AND 1949 THEN '1940s'
    WHEN year BETWEEN 1950 AND 1959 THEN '1950s'
    WHEN year BETWEEN 1960 AND 1969 THEN '1960s'
    WHEN year BETWEEN 1970 AND 1979 THEN '1970s'
    WHEN year BETWEEN 1980 AND 1989 THEN '1980s'
    WHEN year BETWEEN 1990 AND 1999 THEN '1990s'
    WHEN year BETWEEN 2000 AND 2009 THEN '2000s'
    WHEN year BETWEEN 2010 AND 2019 THEN '2010s'
    WHEN year BETWEEN 2020 AND 2024 THEN '2020s'
    ELSE 'Out of Range'
END;

-- Step 10: Add rating categories for easier analysis
ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN rating_category STRING;

UPDATE `biniyam-452918.movies.movie2`
SET rating_category = 
    CASE
        WHEN rating >= 9 THEN '9.0+ (Masterpieces)'
        WHEN rating >= 8 THEN '8.0 - 8.9 (Great)'
        WHEN rating >= 7 THEN '7.0 - 7.9 (Good)'
        ELSE 'Below 7 (Average)'
    END;

-- Step 11: Reorder Movie_Rank to be sequentially correct after cleaning
MERGE INTO `biniyam-452918.movies.movie2` AS m
USING (
  SELECT Movie_Rank, ROW_NUMBER() OVER (ORDER BY Movie_Rank ASC) AS new_rank
  FROM `biniyam-452918.movies.movie2`
) AS ranked_movies
ON m.Movie_Rank = ranked_movies.Movie_Rank
WHEN MATCHED THEN
  UPDATE SET m.Movie_Rank = ranked_movies.new_rank;

-- Step 12: Rebuild table to enforce ordered Movie_Rank (optional but cleaner)
CREATE OR REPLACE TABLE `biniyam-452918.movies.movie2` AS
SELECT 
  ROW_NUMBER() OVER (ORDER BY Movie_Rank ASC) AS Movie_Rank,
  year,
  duration_minutes,
  age_limit,
  rating,
  Number_of_ratings,
  description,
  Title,
  rating_category,
  decade
FROM `biniyam-452918.movies.movie2`;

-- Final check: Validate table structure
SELECT column_name
FROM `biniyam-452918.movies.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'movie2';

-- Optional final preview
SELECT * FROM `biniyam-452918.movies.movie2`;
