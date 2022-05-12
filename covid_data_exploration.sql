/*

Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT * 
FROM `portfolioproject-349716.covid_data.deaths`
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM `portfolioproject-349716.covid_data.deaths`
ORDER BY 1,2

-- Looking at the Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM `portfolioproject-349716.covid_data.deaths`
WHERE location LIKE '%States%'
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, Population, total_cases, (total_deaths/total_cases) * 100  AS PercentPopulationInfected
FROM `portfolioproject-349716.covid_data.deaths`
WHERE location LIKE '%States%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM `portfolioproject-349716.covid_data.deaths`
--WHERE location LIKE '%States%'
GROUP BY population, location
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM `portfolioproject-349716.covid_data.deaths`
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY  location
ORDER BY TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM `portfolioproject-349716.covid_data.deaths`
--WHERE location LIKE '%States%'
WHERE continent IS NULL
GROUP BY  location
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths ,SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM `portfolioproject-349716.covid_data.deaths`
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
, SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `portfolioproject-349716.covid_data.deaths` dea
JOIN `portfolioproject-349716.covid_data.vaccinations` vac
  ON dea.location = vac.location 
  AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac
AS 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM `portfolioproject-349716.covid_data.deaths` AS dea
JOIN `portfolioproject-349716.covid_data.vaccinations`AS vac
    ON dea.location = vac.location 
    and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
)
Select *, (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS `portfolioproject-349716.covid_data.PercentPeopleVaccinated` ;
CREATE TABLE `portfolioproject-349716.covid_data.PercentPeopleVaccinated`
(
'continent' STRING,
'location' STRING,
`date` DATE,
`population` INT64,
`new_vaccinations` INT64,
`rollingpeoplevaccinated` INT64
)

INSERT INTO `portfolioproject-349716.covid_data.PercentPeopleVaccinated`
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (rolling_people_vaccinated/population)*100
FROM `portfolioproject-349716.covid_data.deaths` AS dea
JOIN `portfolioproject-349716.covid_data.vaccinations` AS vac
    ON dea.location = vac.location 
    and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

Select *, (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM `portfolioproject-349716.covid_data.PercentPeopleVaccinated`

-- Creating View to store data for later visualizations

CREATE VIEW `portfolioproject-349716.covid_data.PercentPeopleVaccinatedView` AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM `portfolioproject-349716.covid_data.deaths` AS dea
JOIN `portfolioproject-349716.covid_data.vaccinations` AS vac
    ON dea.location = vac.location 
    and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3