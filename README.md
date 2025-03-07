
# SQL Data Cleaning Project

## Overview
This project focuses on **data cleaning using SQL**, specifically in **Google BigQuery**.  
The dataset contains movies data that required extensive cleaning to improve quality, consistency, and structure.

## Technologies Used
- SQL (BigQuery SQL dialect)
- Google BigQuery

## Dataset Description
| Column               | Description                                         |
|----------------------|-----------------------------------------------------|
| Title                 | Movie Title                                        |
| Year                  | Release Year                                       |
| Duration (minutes)    | Duration converted to minutes                      |
| Age Limit             | Standardized age classification                    |
| Rating                | IMDb-style rating (2 decimal places)               |
| Number of Ratings     | Total ratings count (converted from 'K', 'M')      |
| Description           | Short movie summary                               |
| Rating Category       | Grouped rating bucket (Great, Good, etc.)          |
| Decade                | Release decade                                     |

## Cleaning Steps
### 1. Age Limit Standardization
- Cleaned inconsistent values (e.g., 'A' to '18')
- Filled nulls with 'Unknown'

### 2. Duration Parsing and Conversion
- Converted durations to minutes (e.g., '2h 30m' ➡️ 150 minutes)

### 3. Number of Ratings Conversion
- Transformed 'K' and 'M' to full numbers (e.g., '1.2M' ➡️ 1200000)

### 4. Column Renaming
- Applied consistent naming conventions

### 5. Duplicate Removal
- Removed duplicates based on key columns

### 6. Feature Engineering
- Added columns: `decade`, `rating_category`

### 7. Sorting and Reordering
- Re-ranked movies after cleaning

## SQL Workflow
1. Initial inspection (`SELECT *`)
2. Standardization and parsing
3. Null handling
4. Renaming and conversions
5. Duplicate removal
6. Feature engineering
7. Sorting and ranking
8. Final table creation

## Why This Matters
Data cleaning is a crucial step for accurate analysis.  
This project shows how to handle **real-world messy data** using SQL in a structured way.

## How to Use
- Clone this repository
- Run `data_cleaning.sql` in BigQuery
- Use the cleaned table for analysis, dashboards, or modeling

## Author
**Biniyam Awalachew Firde**  
Data Analysis Student | SQL Enthusiast  
[LinkedIn](https://www.linkedin.com/in/biniyam-awalachew)

## License
MIT License - see `LICENSE`
