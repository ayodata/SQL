--Portfolio Project 1
--SQL Data Exploration

--select the data to be used:
SELECT location, date, population, total_cases, new_cases, total_deaths
FROM covid..CovidDeath
ORDER BY 1, 2, 3 

--Total Cases vs New Death:
SELECT location, date, total_cases, total_deaths, 
	round((total_deaths/total_cases) * 100, 2) as DeathPercent
FROM covid..CovidDeath
WHERE continent is not null
ORDER BY 1, 2 

-- Total Cases vs Population
-- shows what percentage of Population who got Covid
SELECT location, date, population, total_cases, 
	(total_cases/population) * 100 as PercentPopulationInfected
FROM covid..CovidDeath
WHERE continent is not null
ORDER BY 1, 2

-- Countries with Highest infected compared with Population
SELECT location, population, Max(total_cases) as HighestInfectedCount, 
	 Max((total_cases/population) * 100) as PercentPopulationInfected
FROM covid..CovidDeath
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 desc

--Countries with highest DeathCount per Population
SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM covid..CovidDeath
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

--BREAKING THE DATA DOWN BY CONTINENT
SELECT continent, Max(cast(total_deaths as int)) as TotalDeathCount
FROM covid..CovidDeath
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM covid..CovidDeath
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc

--GLOBAL COUNT
SELECT date, SUM(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths, 
	SUM(cast(new_deaths as int))/sum(new_cases) * 100 as DeathPercentage
FROM covid..CovidDeath
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

SELECT SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
FROM covid..CovidDeath
WHERE continent is not null
ORDER BY 1, 2

-- JOIN CONCEPT:
-- Looking at Total Population vs Vaccination

SELECT * FROM covid..CovidDeath dea
JOIN covid..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
FROM covid..CovidDeath dea
JOIN covid..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
	and vac.new_vaccinations is not null
ORDER BY 2, 3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int, vac.new_vaccinations)) over(Partition by dea.location order by dea.location, 
	dea.date ) as rolling_people_vaccinated
FROM covid..CovidDeath dea
JOIN covid..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
	--and vac.new_vaccinations is not null
ORDER BY 2, 3

--Commom Table Expression: CTE
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(convert(int, vac.new_vaccinations)) over(Partition by dea.location order by dea.location, 
	dea.date ) as rolling_people_vaccinated
FROM covid..CovidDeath dea
JOIN covid..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (rolling_people_vaccinated/population) * 100 roll_per_pop
FROM popvsvac

--Temp Table
DROP TABLE IF EXISTS #percentage_population_vaccinated
CREATE TABLE #percentage_population_vaccinated
(
continent nvarchar(225),
location nvarchar (225),
date datetime,
population numeric,
new_vaccinated numeric,
rolling_people_vaccinated numeric,
)

INSERT INTO #percentage_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(convert(int, vac.new_vaccinations)) over(Partition by dea.location order by dea.location, 
	dea.date ) as rolling_people_vaccinated
FROM covid..CovidDeath dea
JOIN covid..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null

SELECT *, (rolling_people_vaccinated/population) * 100
FROM #percentage_population_vaccinated

--Creating views to assist during visualization

GO 
CREATE VIEW percentage_pop_vaccinate
as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(convert(int, vac.new_vaccinations)) over(Partition by dea.location order by dea.location, 
		dea.date ) as rolling_people_vaccinated
	from covid..CovidDeath dea
	join covid..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null