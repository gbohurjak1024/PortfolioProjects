--select	*
--from	PortfolioProject..CovidVaccinations
--order by 3,4

--select	*
--from	PortfolioProject..CovidDeaths
--order by 3,4

--select Data that we are going to be using

select	Location, date, total_cases, new_cases, total_deaths, population
from	PortfolioProject..CovidDeaths
order by 1,2;


--looking at total cases vs total deaths
--shows likelihood of dying if you contract covid in your country
select	Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
from	PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
order by 1,2;

--looking at total cases vs population
--shows what percentage of population got covid

select	Location, date, population, total_cases, (total_cases/population)*100 AS CasePercentage
from	PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
order by 1,2;

--looking at countries with highest infection rate vs population

select	Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionPercentage
from	PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY location, population
order by InfectionPercentage DESC

--showing countries with highest death count per population

select	Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
from	PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
order by TotalDeathCount DESC

--lets break things down by continent 
--showing continents with highest death count per population

select	continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
from	PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
order by TotalDeathCount DESC

--Global numbers

select SUM(new_cases) AS Totalcases, SUM(CAST(new_deaths AS INT)) AS Totaldeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100  AS DeathPercentage
from	PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
order by 1,2;

--Looking at total population vs vaccinations (new vaccinations per day)

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT null
ORDER BY 2, 3

--now want to add new vaccinations per day into rolling number and % vaccinated by population

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(bigINT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
	-- cant use created column (RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT null
ORDER BY 2, 3

--Use CTE (allows you to use created column in another equation)

WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingVaccinations)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(bigINT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
	-- cant use created column (RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT null
--ORDER BY 2, 3
)
SELECT *, (RollingVaccinations/population)*100
FROM PopvsVac

--Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
LOCATION NVARCHAR(255),
DATE DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingVaccinations NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(bigINT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
	-- cant use created column (RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
--WHERE cd.continent IS NOT null
--ORDER BY 2, 3

SELECT *, (RollingVaccinations/population)*100
FROM #PercentPopulationVaccinated



--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(bigINT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT null
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated