-- IMPORT DATA
CREATE TABLE world_layoffs (
	company varchar,
	location varchar,
	industry varchar,
	total_laid_off varchar,
	percentage_laid_off varchar,
	date varchar,
	stage varchar,
	country varchar,
	funds_raised_millions varchar);
copy world_layoffs from 'C:\Program Files\PostgreSQL\16\layoffs.csv' CSV header ;

select * from world_layoffs;

--copying the original table
create table world_layoffs_cleaned
(like world_layoffs including all);

insert into world_layoffs_cleaned (company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions)
select company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions
from world_layoffs;

select * from world_layoffs_cleaned ;

-- REMOVE DUPLICATES

with ranked_rows as (select * ,ctid, row_number()over (
	partition by company,location,industry,total_laid_off,percentage_laid_off,date,
	stage,country,funds_raised_millions order by ctid) as row_num 
	from world_layoffs_cleaned)
delete from world_layoffs_cleaned
where ctid in (
	select ctid
	from ranked_rows
	where row_num > 1);
	
select * from world_layoffs where company = 'Casper'; --checking the old data
select * from world_layoffs_cleaned where company = 'Casper'; --checking the data after delete duplicate


-- STANDARDIZE THE DATA ---

--trime data--
select * from world_layoffs_cleaned;
update world_layoffs_cleaned 
set company = trim(company),
	location = trim(location),
	industry = trim(industry),
	stage = trim(stage),
	country = trim(country);
	
-- identify different variation in words
select distinct company 
from world_layoffs_cleaned
order by company;

select distinct location
from world_layoffs_cleaned
order by location; --(Düsseldorf, Dusseldorf, Malmo, Malmö)

update world_layoffs_cleaned
set location = 'Dusseldorf'
where location = 'Düsseldorf';

update world_layoffs_cleaned
set location = 'Malmo'
where location = 'Malmö';

select distinct industry
from world_layoffs_cleaned
order by industry; -- multiple variation noticed (Crypto, Crypto Currency and CryptoCurrency)

--make it similar word--
update world_layoffs_cleaned
set industry = 'Crypto'
where industry in ('Crypto Currency' ,'CryptoCurrency');

select distinct stage
from world_layoffs_cleaned
order by stage;

select distinct country
from world_layoffs_cleaned
order by country; --(United States, United States.)

UPDATE world_layoffs_cleaned
SET country = TRIM(TRAILING '.' FROM country);

select * from world_layoffs_cleaned;

--change data type--

alter table world_layoffs_cleaned
alter column total_laid_off type numeric
using nullif (total_laid_off, 'NULL'):: numeric;

select distinct total_laid_off from world_layoffs_cleaned order by total_laid_off;

alter table world_layoffs_cleaned
alter column percentage_laid_off type numeric
using nullif (percentage_laid_off, 'NULL'):: numeric;
select distinct percentage_laid_off from world_layoffs_cleaned order by percentage_laid_off;


alter table world_layoffs_cleaned
alter column funds_raised_millions type numeric
using nullif (funds_raised_millions, 'NULL'):: numeric;
select distinct funds_raised_millions from world_layoffs_cleaned order by funds_raised_millions;

--change the date column--
update world_layoffs_cleaned
set date = null
where date = 'NULL';

ALTER TABLE world_layoffs_cleaned
ADD COLUMN new_date date; 

UPDATE world_layoffs_cleaned
SET new_date = COALESCE(
    NULLIF(TO_DATE(date, 'MM-DD-YYYY'), NULL), 
    '1000-01-01'); --default date value for nulls

ALTER TABLE world_layoffs_cleaned
DROP COLUMN date;

ALTER TABLE world_layoffs_cleaned
rename COLUMN new_date to date;

select distinct date from world_layoffs_cleaned order by date;
select * from world_layoffs_cleaned;


-- NULL VALUES AND BLANK VALUES
SELECT DISTINCT company
FROM world_layoffs_cleaned
ORDER BY company;  -- no null/blank values detected

select * from world_layoffs_cleaned where location = 'NULL'
or location is null
order by location; -- no null/blank values detected

SELECT DISTINCT industry
FROM world_layoffs_cleaned
ORDER BY industry; -- null/blank values detected

select * from world_layoffs_cleaned where 
industry = 'NULL'
or industry is null
order by industry;
	
update world_layoffs_cleaned
set industry = null
where industry = 'NULL'; --- set the 'NULL' with null value

--fill in the null value with similar information
UPDATE world_layoffs_cleaned t1
SET industry = t2.industry
FROM world_layoffs_cleaned t2
WHERE t1.company = t2.company
  AND t1.industry IS NULL
  AND t2.industry IS NOT NULL;
 
--verify the null data (found that still any null data)
select distinct industry from world_layoffs_cleaned;

--convert the null data in varchar type with 'Unknown'
update world_layoffs_cleaned
set industry = 'Unknown'
where industry is NULL;

select * from world_layoffs_cleaned where stage = 'NULL'
or stage is null
order by stage;

update world_layoffs_cleaned
set stage = 'Unknown'
where stage = 'NULL';

select * from world_layoffs_cleaned where country = 'NULL'
or country is null
order by country; --no nulls detected


--convert the null data in numeric type with '0'
update world_layoffs_cleaned
set total_laid_off = '0'
where total_laid_off is NULL;

update world_layoffs_cleaned
set percentage_laid_off = '0'
where percentage_laid_off is NULL;

update world_layoffs_cleaned
set funds_raised_millions = '0'
where funds_raised_millions is NULL;


select * from world_layoffs_cleaned;

-- REMOVE ANY COLUMNS/ROW 


create table null_layoffs_data as (SELECT *
FROM world_layoffs_cleaned
WHERE total_laid_off = '0'
AND percentage_laid_off ='0'
AND funds_raised_millions = '0'); --separate the deleted rows


DELETE FROM world_layoffs_cleaned
WHERE total_laid_off = '0'
AND percentage_laid_off ='0'
AND funds_raised_millions = '0';

select * from null_layoffs_data;
select * from world_layoffs;
select * from world_layoffs_cleaned;
