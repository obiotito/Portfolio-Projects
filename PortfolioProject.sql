/*
Author: Otitodilichukwu Obi

Porfolio Project on COVID-19 analyst

THe dataset was gotten from this link: https://ourworldindata.org/covid-deaths on the 08/01/2022

The raw dataset was downloaded as a csv file. 

Using Excel, the csv file was first formatted to a table and two tables were drawn from it: CovidDeaths and CovidVaccinations

Finally, the two tables were imported into the PorfolioProject database.
*/

/*
	Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


--Displaying all the data

SELECT *
	FROM PortfolioProject..CovidDeaths;

SELECT *
	FROM PortfolioProject..CovidVaccinations;



-- Counting the number of rows

SELECT COUNT(*) 
	FROM PortfolioProject..CovidDeaths;

SELECT COUNT(*)
	FROM PortfolioProject..CovidVaccinations;



-- Counting the number of columns

SELECT COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'CovidDeaths';

SELECT COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'CovidVaccinations';


--- Calculating the Death Rate in Ireland (Likelihood of Deading as of 08/01/2022)

SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases) * 100 AS Death_Rate
	FROM PortfolioProject..CovidDeaths
	WHERE location LIKE 'Ireland' AND continent IS NOT NULL
	ORDER BY 2;


---Identifying the percentage of population that contacted COVID as of 08/01/2022

SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population) * 100 AS Population_with_COVID
	FROM PortfolioProject..CovidDeaths
	WHERE location LIKE 'Ireland' AND continent IS NOT NULL
	ORDER BY 2;


---Identifying Highest Infection Rate per Population as of 08/01/2022

SELECT 
	location,
	population,
	MAX(total_cases),
	MAX((total_cases/population) * 100)
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY 4 DESC;


--- Identifying the Highest death count 
/*
NB 
Point 1:
	The dataset included continents in the location field, leaving the continent field NULL. 
	So a good step is adding a WHERE clause (i.e. WHERE continent IS NOT NULL) to remove those invalid records.

Point 2:
	The data type for tota_deaths is in nvarchar(255). it has to be converted to numeric value for any aggregate calculation.
*/

SELECT
	location,
	MAX(CAST(total_deaths AS int)) AS Death_Count,
	RANK() OVER (ORDER BY MAX(CAST(total_deaths AS int)) DESC) AS Ranking
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL 
	GROUP BY location
	ORDER BY Death_Count DESC;



--- Continents with the Highest Death Count

SELECT 
	continent,
	MAX(CAST(Total_deaths AS int)) AS Death_Count
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent
	ORDER BY Death_Count DESC;


--- Looking at Global Numbers
--- Global numbers per day

SELECT 
	date,
	SUM(new_cases) AS Total_Cases,
	SUM(CAST(new_deaths AS int)) AS Total_Deaths,
	(SUM(CAST(new_deaths AS int))/SUM(new_cases)) * 100 AS Death_Percentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY date
	ORDER BY 1;



---Global numbers general
SELECT 
	SUM(new_cases) AS Total_Cases,
	SUM(CAST(new_deaths AS int)) AS Total_Deaths,
	(SUM(CAST(new_deaths AS int))/SUM(new_cases)) * 100 AS Death_Percentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL;
	


SELECT 
	location, 
	SUM(CAST(new_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High Income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC;


---Death Count by Income
SELECT 
	location, 
	SUM(CAST(new_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union', 'International', 'Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY TotalDeathCount DESC;


--- Identifying total number of vaccinations per population

SELECT 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CASE WHEN CONVERT(bigint, vac.new_vaccinations) IS NULL THEN 0 ELSE CONVERT(bigint, vac.new_vaccinations) END) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Cummulative_number_of_vaccinations
	FROM PortfolioProject..CovidDeaths AS dea 
	JOIN PortfolioProject..CovidVaccinations AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3;



---Percentage vaccinated over time using CTE as of 80/01/2022
/*
NB: CTE was created to be able to use the "Cummulative_number_of_vaccinations" column for further calculations
*/ 

WITH Vaccinated_Population(continent, location, date, population, new_vaccinations, Cummulative_number_of_vaccinations) 
	AS (
		SELECT 
			dea.continent, 
			dea.location,
			dea.date,
			dea.population,
			vac.new_vaccinations,
			SUM(CASE WHEN CONVERT(bigint, vac.new_vaccinations) IS NULL THEN 0 ELSE CONVERT(bigint, vac.new_vaccinations) END) 
				OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Cummulative_number_of_vaccinations
		FROM PortfolioProject..CovidDeaths AS dea 
		JOIN PortfolioProject..CovidVaccinations AS vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		)

SELECT 
	*,
	(Cummulative_number_of_vaccinations/Population) * 100 AS Percentage_Vaccinated
	FROM Vaccinated_Population
	ORDER BY 2,3;



---Percentage vaccinated over time using Temp Table as of 80/01/2022
DROP TABLE IF EXISTS Vaccinated_Population
CREATE TABLE Vaccinated_Population(
	continent nvarchar(255), 
	location nvarchar(255), 
	date datetime, 
	population numeric, 
	new_vaccinations numeric, 
	Cummulative_number_of_vaccinations numeric
	)

INSERT INTO Vaccinated_Population
	SELECT 
			dea.continent, 
			dea.location,
			dea.date,
			dea.population,
			vac.new_vaccinations,
			SUM(CASE WHEN CONVERT(bigint, vac.new_vaccinations) IS NULL THEN 0 ELSE CONVERT(bigint, vac.new_vaccinations) END) 
				OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Cummulative_number_of_vaccinations
		FROM PortfolioProject..CovidDeaths AS dea 
		JOIN PortfolioProject..CovidVaccinations AS vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL

SELECT 
	*,
	(Cummulative_number_of_vaccinations/Population) * 100 AS Percentage_Vaccinated
	FROM Vaccinated_Population;



---Creating Views for vizualization

CREATE VIEW Global_Deaths AS
	SELECT 
		SUM(new_cases) AS Total_Cases,
		SUM(CAST(new_deaths AS int)) AS Total_Deaths,
		(SUM(CAST(new_deaths AS int))/SUM(new_cases)) * 100 AS Death_Percentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL;




CREATE VIEW Death_Rate_Ireland AS
	SELECT 
		location,
		date,
		total_cases,
		total_deaths,
		(total_deaths/total_cases) * 100 AS Death_Rate
	FROM PortfolioProject..CovidDeaths
	WHERE location LIKE 'Ireland';
		


CREATE VIEW Infected_Population_Ireland AS
	SELECT 
		location,
		date,
		total_cases,
		population,
		(total_cases/population) * 100 AS Population_with_COVID
	FROM PortfolioProject..CovidDeaths
	WHERE location LIKE 'Ireland';


CREATE VIEW Highest_Infection_Rate AS
	SELECT 
		location,
		population,
		MAX(total_cases) AS Max_Cases,
		MAX((total_cases/population) * 100) AS Highest_Infection_Rate
	FROM PortfolioProject..CovidDeaths
	GROUP BY location, population;


CREATE VIEW Death_Count_by_Continent AS
	SELECT 
		location, 
		SUM(CAST(new_deaths as int)) as TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NULL
		AND location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High Income', 'Lower middle income', 'Low income')
	GROUP BY location;



CREATE VIEW Death_Count_by_Location AS
	SELECT
		location,
		MAX(CAST(total_deaths AS int)) AS Death_Count
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL 
	GROUP BY location;



CREATE VIEW Death_Count_by_Income AS
	SELECT 
		location, 
		SUM(CAST(new_deaths as int)) as TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NULL
		AND location NOT IN ('World', 'European Union', 'International', 'Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
	GROUP BY location;



CREATE VIEW Highest_Infection_Rate AS
	SELECT 
		location,
		population,
		MAX(total_cases) AS Total_Cases,
		MAX((total_cases/population) * 100) AS Highest_Infection_Rate
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location, population;





CREATE VIEW Rate_of_Vaccinated_Population AS
	WITH Vaccinated_Population(continent, location, date, population, new_vaccinations, Cummulative_number_of_vaccinations) 
	AS (
		SELECT 
			dea.continent, 
			dea.location,
			dea.date,
			dea.population,
			vac.new_vaccinations,
			SUM(CASE WHEN CONVERT(bigint, vac.new_vaccinations) IS NULL THEN 0 ELSE CONVERT(bigint, vac.new_vaccinations) END) 
				OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Cummulative_number_of_vaccinations
		FROM PortfolioProject..CovidDeaths AS dea 
		JOIN PortfolioProject..CovidVaccinations AS vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		)

SELECT 
	*,
	(Cummulative_number_of_vaccinations/Population) * 100 AS Percentage_Vaccinated
	FROM Vaccinated_Population;
