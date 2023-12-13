SELECT *
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
ORDER BY 3,4

--DELETE FROM PortfolioProject..CovidDeaths$
--WHERE continent is NULL

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

-- Select Data that is going to be used
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2

--ALTER TABLE PortfolioProject..CovidDeaths$
--ALTER COLUMN total_cases bigint

-- Total cases vs Total Deaths
SELECT Location, 
	date, 
	total_cases, 
	total_deaths,
	(total_deaths*1.0/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location ='Poland'
ORDER BY 1,2

-- Total Cases vs Population
SELECT
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE location = 'Poland'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population
SELECT
	location,
	population,
	MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases/population)*100) as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population
SELECT
	location,
	MAX(total_deaths) TotalDeathCount,
	(MAX(total_deaths)/MAX(population))*100 DeathCountPerPopulation
FROM
	PortfolioProject..CovidDeaths$ 
WHERE
	continent is not null
GROUP BY
	location, population
ORDER BY
	TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

SELECT
	location,
	MAX(total_deaths) TotalDeathCount,
	(MAX(total_deaths)/MAX(population))*100 DeathCountPerPopulation
FROM
	PortfolioProject..CovidDeaths$ 
WHERE
	continent is null
GROUP BY
	location
ORDER BY
	TotalDeathCount DESC


--Continents with the highest death count

SELECT
	continent,
	MAX(total_deaths) TotalDeathCount,
	(MAX(total_deaths)/MAX(population))*100 DeathCountPerPopulation
FROM
	PortfolioProject..CovidDeaths$ 
WHERE
	continent is not null
GROUP BY
	continent
ORDER BY
	TotalDeathCount DESC

--GLOBAL NUMBERS
SELECT
	date, 
	SUM(new_cases) total_cases,
	SUM(new_deaths) total_deaths,
	CASE
		WHEN SUM(new_cases)<>0 THEN SUM(new_deaths)/SUM(new_cases)*100 
		ELSE NULL
	END DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2

SELECT
	SUM(new_cases) total_cases,
	SUM(new_deaths) total_deaths,
	CASE
		WHEN SUM(new_cases)<>0 THEN SUM(new_deaths)/SUM(new_cases)*100 
		ELSE NULL
	END DeathPercentage
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2


--Population vs vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location= vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location= vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
)
SELECT *,
	(RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous quer
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location= vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations

SELECT *,
	(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinatedView as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location= vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL

SELECT *
FROM PercentPopulationVaccinated