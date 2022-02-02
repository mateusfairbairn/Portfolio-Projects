/*
Covid-19 Data Exploration 
Skills used: Aggregate Functions, Converting Data types, Joins, CTE's, Temp Tables, Windows Functions, Creating Views
*/



-- Data with basic information to begin with:

SELECT location, date, population , total_cases, total_deaths
FROM deathcovid
WHERE continent != ''
-- Whenever the rows of data represent aggregated continent data, the location column has the respective continent and the continent column is = ''. However, we are interested in country-specific data, so we will be looking where continent != ''. If the data were NULL as opposed to = '', we would use "WHERE continent is NOT NULL" instead.
ORDER BY date

-- UNITED STATES DATA
SELECT location, date, population , total_cases, total_deaths
FROM deathcovid
WHERE location like '%States%'
	AND continent != ''
ORDER BY date

-- Percent of U.S. population that has contracted the virus (most recent records first)
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentInfected
FROM deathcovid
WHERE location LIKE '%states'
	AND continent != ''
ORDER BY date DESC

-- Percent of U.S. Covid-19 cases that resulted in death (most recent records first)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPct
FROM deathcovid
WHERE location like '%States%'
	AND continent != ''
ORDER BY date DESC


-- Since the previous query shows the death percentage in a cumulative manner (total_deaths/total_cases), it is useful to also look at death percentage in daily terms by using new deaths and new cases, so we can have a better idea of the current death percentage.
SELECT location, date, new_cases, new_deaths, (new_deaths/new_cases)*100 AS DeathPctDaily
FROM deathcovid
WHERE location like '%States%'
	AND continent != ''
ORDER BY date DESC 


-- Since the data may vary wildly day-to-day, we should also group the data by month, so we can see how the death percentage progressed over several months (most recent records first)
SELECT (sum(new_deaths)/sum(new_cases))*100 AS DeathPctMonthlyUnitedStates, DATE_FORMAT(date, '%Y %m') AS YearMonth
FROM deathcovid 
WHERE continent != ''
 	AND location like '%States%'
GROUP BY DATE_FORMAT(date, '%Y %m')
ORDER BY DATE_FORMAT(date, '%Y %m') DESC



-- In order to see which countries have highest death percentages in the last 14 days:
SELECT location, (sum(new_deaths)/sum(new_cases))*100 AS DeathPctLast14days
FROM deathcovid 
WHERE date BETWEEN '2021-12-28' AND '2022-01-10' 
	AND continent != ''
GROUP BY location
ORDER BY DeathPctLast14days DESC


-- In order to see which countries have highest death count overall, in absolute terms (also adding a ranking column). Upon examination, total_deaths was imported as a TEXT data type. In order to use MAX(), we convert the data type to UNSIGNED:
SELECT Location, MAX(cast(total_deaths as UNSIGNED)) as TotalDeathCount, RANK() OVER(ORDER BY MAX(cast(total_deaths as UNSIGNED)) DESC) AS DeathCountRank
FROM deathcovid
WHERE continent != ''
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- From the new vaccinations column in the vaccovid dataset, we can figure out what the rolling vaccination count in the U.S. is:
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations_smoothed, SUM(CAST(new_vaccinations_smoothed AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingCountVaccinations
FROM deathcovid AS dea 
	JOIN vaccovid AS vac 
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.location LIKE '%States%'
ORDER BY dea.location, dea.date

-- Using CTE, we can perform a calculation on RollingCountVaccinated:
With VaccinesPerPerson AS 
(
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations_smoothed, SUM(CAST(new_vaccinations_smoothed AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingCountVaccinations
FROM deathcovid AS dea 
	JOIN vaccovid AS vac 
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.location LIKE '%States%'
ORDER BY dea.location, dea.date
)
SELECT *, (RollingCountVaccinations/population)*100 VaccineDosesPerHundredPeople
FROM VaccinesPerPerson


-- It is also possible to do the previous operation, but using a temp table instead:

DROP TABLE IF EXISTS VaccineDosesPerHundredPeople
CREATE TABLE VaccineDosesPerHundredPeople
(Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric, 
RollingCountVaccinations numeric)


INSERT INTO VaccineDosesPerHundredPeople
SELECT dea.location, dea.date, CAST(dea.population AS UNSIGNED), CAST(vac.new_vaccinations_smoothed AS UNSIGNED), SUM(CAST(new_vaccinations_smoothed AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingCountVaccinations
FROM deathcovid AS dea 
	JOIN vaccovid AS vac 
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.location LIKE '%States%'


Select *, (RollingCountVaccinations/Population)*100
From VaccineDosesPerHundredPeople



-- Create a view
CREATE VIEW VaccinesPerHundred AS
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations_smoothed, SUM(CAST(new_vaccinations_smoothed AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingCountVaccinations
FROM deathcovid AS dea 
	JOIN vaccovid AS vac 
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.location LIKE '%States%'




-- A few Queries for TABLEAU:


-- Latest Overall Percent Infected by country
SELECT location, MAX(total_cases/population)*100 AS PercentInfected
FROM deathcovid
WHERE continent != ''
GROUP BY location
ORDER BY PercentInfected DESC

-- Case count, death count, and death percentage by Country
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeaths, MAX(CAST(total_cases AS UNSIGNED)) AS TotalCases
FROM deathcovid 
WHERE continent != ''
GROUP BY location

-- Overal Global Numbers
WITH CountByCountry AS 
(
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeaths, MAX(CAST(total_cases AS UNSIGNED)) AS TotalCasesCountry
FROM deathcovid 
WHERE continent != ''
GROUP BY location
)

SELECT SUM(TotalDeaths) AS DeathTollGlobal, SUM(TotalCasesCountry) AS TotalCasesGlobal, SUM(TotalDeaths)/SUM(TotalCasesCountry)*100 AS DeathPercentageGlobal
FROM CountByCountry

-- 10 Countries with the highest Death toll
SELECT Location, MAX(cast(total_deaths as UNSIGNED)) as TotalDeathCount
FROM deathcovid
WHERE continent != ''
GROUP BY Location
ORDER BY TotalDeathCount DESC
LIMIT 10

-- Global death percentage by Month
SELECT (sum(new_deaths)/sum(new_cases))*100 AS DeathPctMonthly, DATE_FORMAT(date, '%Y %m') AS YearMonth
FROM deathcovid 
WHERE continent != ''
--	AND location like '%States%'
GROUP BY DATE_FORMAT(date, '%Y %m')
ORDER BY DATE_FORMAT(date, '%Y %m') DESC