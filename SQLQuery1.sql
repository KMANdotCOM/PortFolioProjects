ALTER TABLE Portfolio..CovidDeaths
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE Portfolio..CovidDeaths
ALTER COLUMN population FLOAT;

ALTER TABLE Portfolio..CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE Portfolio..CovidDeaths
ALTER COLUMN new_cases FLOAT;

ALTER TABLE Portfolio..CovidDeaths
ALTER COLUMN new_deaths FLOAT;

ALTER TABLE Portfolio..CovidVaccinations
ALTER COLUMN new_vaccinations FLOAT;


--SELECT *
--FROM PortFolio..CovidDeaths
--ORDER BY 3,4

----# selected data to be used

--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM PortFolio..CovidDeaths
--ORDER BY 1,2


-- looking at total_cases vs total_deaths

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS Perc_death
FROM PortFolio..CovidDeaths
WHERE location = 'South Africa'
ORDER BY 1,2 


-- % infected in South Africa
SELECT location, date, total_cases, population, (CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS Perc_infected
FROM PortFolio..CovidDeaths
WHERE location = 'South Africa'
ORDER BY 1,2 

--Averages per month for South Africa
WITH avg_cases AS(
	SELECT location, 
	DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month,
	CAST(total_cases AS FLOAT) AS deaths
	FROM PortFolio..CovidDeaths
)

SELECT location, 
	   month, 
	   AVG(deaths) AS Avg_cases
FROM avg_cases
WHERE location = 'South Africa'
GROUP BY location, Month
ORDER BY location, Month

-- changed columns to floats to avoid uneccessary sub querries
SELECT population, date, AVG(total_deaths) AS Avg_deaths
FROM PortFolio..CovidDeaths
WHERE location = 'South Africa'
GROUP BY population, date
ORDER BY population, date;

-- averageing totals via month, then calucating increase or decrease of average from month to month
WITH MonthlyDeaths AS(
SELECT population, 
	   DATEADD(MONTH, DATEDIFF(MONTH, 0,date),0) AS month, 
	   AVG(total_deaths) AS Avg_deaths
FROM PortFolio..CovidDeaths
WHERE location = 'South Africa'
GROUP BY population, DATEADD(MONTH, DATEDIFF(MONTH, 0,date),0)
)

SELECT population,
	   month,
	   Avg_deaths,
	   Avg_deaths - LAG(Avg_deaths, 1, 0) OVER (PARTITION BY population ORDER BY month) AS increase_in_monthly_deaths
FROM MonthlyDeaths
ORDER BY population, month;

--% deaths in SA
SELECT location, date, population, total_deaths,  (total_deaths/population)*100 AS Death_Percentage
FROM PortFolio..CovidDeaths
WHERE location = 'South Africa' AND total_deaths IS NOT NULL AND population IS NOT NULL 
ORDER BY location, date

-- Higest infection rate compared to population for SA
SELECT location, population, MAX(total_cases) as Highest_infection_Count, MAX((total_cases/population))*100 AS Percentage_Pop_Infected
FROM PortFolio..CovidDeaths
WHERE location = 'South Africa'
GROUP BY location, population
ORDER BY Percentage_Pop_Infected

--Showing (10) highest death count per population
SELECT TOP(10) location, date, MAX(total_deaths) AS Highest_Death_Count
FROM PortFolio..CovidDeaths
WHERE location = 'South Africa'
GROUP BY location, date
ORDER BY Highest_Death_Count DESC


-- higest deaths per country 
SELECT location, ISNULL(MAX(total_deaths), 0) AS Highest_Death_Count
FROM PortFolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC

--continent with highest death counts 
SELECT continent, MAX(total_deaths) AS Highest_Death_Count
FROM PortFolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Highest_Death_Count DESC

--Total pop vs total vac
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_vac
FROM PortFolio..CovidDeaths d
JOIN PortFolio..CovidVaccinations v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.continent, d.location, d.date

-- rolling count of vac
WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_vac)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_vac
FROM PortFolio..CovidDeaths d
JOIN PortFolio..CovidVaccinations v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (Rolling_vac/population)*100 AS Rolling_Vac_Totals
FROM PopvsVac

--TEMP table
DROP TABLE IF EXISTS #PercentagePopVac;
CREATE TABLE #PercentagePopVac
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    Rolling_vac numeric
);

INSERT INTO #PercentagePopVac
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
    SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_vac
FROM PortFolio..CovidDeaths d
JOIN PortFolio..CovidVaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT 
    *, (Rolling_vac / population) * 100 AS Rolling_Vac_Totals
FROM #PercentagePopVac;




--Creating view for visualisation 
CREATE VIEW PercentagePopVac as
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
    SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_vac
FROM PortFolio..CovidDeaths d
JOIN PortFolio..CovidVaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *
FROM PercentagePopVac