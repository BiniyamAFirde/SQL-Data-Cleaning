SELECT * FROM biniyam-452918.movies.movie2;
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
WHERE age_limit IN ('A', 'TV-MA', 'PG', 'X', 'Unknown', 'Approved', '12A', '16', 'PG-13', 'Not rated', 'U', 'Rejected', '12', 'R', '18', 'AA');

UPDATE `biniyam-452918.movies.movie2`
SET age_limit = 'Unknown'
WHERE age_limit IS NULL;



ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN Metascore_status STRING;

ALTER TABLE `biniyam-452918.movies.movie2`
DROP COLUMN Metascore_status;

  


WITH DurationParsed AS (
  SELECT *,
         CAST(REGEXP_EXTRACT(duration, r'(\d+)h') AS INT64) AS hours,
         CAST(REGEXP_EXTRACT(duration, r'(\d+)m') AS INT64) AS minutes
  FROM `biniyam-452918.movies.movie2`
)
UPDATE `biniyam-452918.movies.movie2`
SET duration = (hours * 60 + minutes)
WHERE hours IS NOT NULL OR minutes IS NOT NULL;






-- Add a new column to store cleaned duration in minutes (optional if you want to keep the original column)
ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN duration_minutes INT64;

-- Now update duration_minutes based on duration string
UPDATE `biniyam-452918.movies.movie2`
SET duration_minutes = 
    CASE 
        WHEN REGEXP_CONTAINS(duration, r'(\d+)h (\d+)m') THEN 
            CAST(REGEXP_EXTRACT(duration, r'(\d+)h') AS INT64) * 60 + CAST(REGEXP_EXTRACT(duration, r'(\d+)m') AS INT64)
        WHEN REGEXP_CONTAINS(duration, r'(\d+)h') THEN 
            CAST(REGEXP_EXTRACT(duration, r'(\d+)h') AS INT64) * 60
        WHEN REGEXP_CONTAINS(duration, r'(\d+)m') THEN 
            CAST(REGEXP_EXTRACT(duration, r'(\d+)m') AS INT64)
        ELSE NULL  -- Handle any unexpected cases gracefully
    END
WHERE duration IS NOT NULL;

-- OPTIONAL: If you want to drop the old 'duration' column and rename the new one
-- ALTER TABLE `biniyam-452918.movies.movie2` DROP COLUMN duration;
-- ALTER TABLE `biniyam-452918.movies.movie2` RENAME COLUMN duration_minutes TO duration;

ALTER TABLE `biniyam-452918.movies.movie2` DROP COLUMN duration;

-- standardized rounding
UPDATE `biniyam-452918.movies.movie2`
SET rating = ROUND(rating, 2)
WHERE rating IS NOT NULL;

-- removing duplicates:
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY rank, year, duration, rating ORDER BY numberof_ratings DESC) AS rn
    FROM `biniyam-452918.movies.movie2`
)
DELETE FROM `biniyam-452918.movies.movie2`
WHERE rn > 1;

SELECT * FROM biniyam-452918.movies.movie2;
-- new column for cleaned value





ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN number_of_ratings_clean INT64;



UPDATE `biniyam-452918.movies.movie2`
SET number_of_ratings_clean = 
    CASE 
        WHEN numberof_ratings LIKE '%K%' THEN 
            CAST(REPLACE(REPLACE(REPLACE(REPLACE(numberof_ratings, 'K', ''), 'M', ''), '(', ''), ')', '') AS FLOAT64) * 1000
        WHEN numberof_ratings LIKE '%M%' THEN 
            CAST(REPLACE(REPLACE(REPLACE(REPLACE(numberof_ratings, 'K', ''), 'M', ''), '(', ''), ')', '') AS FLOAT64) * 1000000
        ELSE 
            CAST(REPLACE(REPLACE(REPLACE(REPLACE(numberof_ratings, 'K', ''), 'M', ''), '(', ''), ')', '') AS INT64)
    END
WHERE numberof_ratings IS NOT NULL;

ALTER TABLE `biniyam-452918.movies.movie2`
DROP COLUMN numberof_ratings;


-- Rename name column to tile
ALTER TABLE `biniyam-452918.movies.movie2`
RENAME COLUMN name TO Title;

-- Rename number of ratings clean to number of ratings

ALTER TABLE `biniyam-452918.movies.movie2`
RENAME COLUMN number_of_ratings_clean TO Number_of_ratings;

-- Rename number of rank to Rank

ALTER TABLE `biniyam-452918.movies.movie2`
RENAME COLUMN rank TO Movie_Rank;


-- Feature Engineering
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
END
where True;


-- Add a new column for Rating Buckets
ALTER TABLE `biniyam-452918.movies.movie2`
ADD COLUMN rating_category STRING;

-- Update the column with rating buckets
-- Update the rating_category column with rating buckets
UPDATE `biniyam-452918.movies.movie2`
SET rating_category = 
    CASE
        WHEN rating >= 9 THEN '9.0+ (Masterpieces)'
        WHEN rating >= 8 THEN '8.0 - 8.9 (Great)'
        WHEN rating >= 7 THEN '7.0 - 7.9 (Good)'
        ELSE 'Below 7 (Average)'
    END
WHERE TRUE;




-- sorting movie rank
-- Update Movie_Rank to be sorted in ascending order
-- Update Movie_Rank to be sorted in ascending order
MERGE INTO `biniyam-452918.movies.movie2` AS m
USING (
  SELECT 
    Movie_Rank, 
    ROW_NUMBER() OVER (ORDER BY Movie_Rank ASC) AS new_rank
  FROM `biniyam-452918.movies.movie2`
) AS ranked_movies
ON m.Movie_Rank = ranked_movies.Movie_Rank
WHEN MATCHED THEN
  UPDATE SET m.Movie_Rank = ranked_movies.new_rank;



-- Create a new table with sorted Movie_Rank in ascending order
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

SELECT column_name
FROM `biniyam-452918.movies.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'movie2';

