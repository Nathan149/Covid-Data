select *
from Covid..CovidDeaths
order by 3,4;

--select *
--from Covid..CovidVaccinations
--order by 3,4

--DELETE DUPLICATE ROWS USING ROW NUMBER FROM CovidDeaths table
WITH cte AS (
	select
		location, continent, date, population,
		ROW_NUMBER() OVER (
		PARTITION BY
			continent,
			location,
			date
		ORDER BY
			continent,
			location,
			date
		)row_num

	from Covid..CovidDeaths
)
delete
from cte
where row_num > 1

--select data
	select location, date, total_cases, new_cases, total_deaths, population
	from Covid..CovidDeaths
	order by 1,2;

-- Total cases vs total deaths
--likelihood of dying from Covid
select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as PercentageDeath
from Covid..CovidDeaths
where location like '%states%'
order by 1,2;

--Total cases vs population
--Percentage of the population infected
select location, date, population, total_cases, (total_cases/population) * 100 as PercentageInfected
from Covid..CovidDeaths
--where location like '%Nigeria%'
order by 1,2;

--Countries with highest Infected

--Percentage of the population infected
select location, population, Max(total_cases) as InfectionCount, Max((total_cases/population)) * 100 as PercentageInfected
from Covid..CovidDeaths
group by location, population
order by PercentageInfected DESC;

--include date
select location, population, date, Max(total_cases) as InfectionCount, Max((total_cases/population)) * 100 as PercentageInfected
from Covid..CovidDeaths
group by location, population, date
order by PercentageInfected DESC;

--showing countries with the highest deaths per population

select location, population, Max(cast(total_deaths as int)) as TotalDeaths
from Covid..CovidDeaths
where continent is not null
Group by location, population
order by TotalDeaths DESC;

--View by continent

select location, Max(cast(total_deaths as int)) as TotalDeaths
from Covid..CovidDeaths
where continent is null and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeaths DESC;

--GLOBAL NUMBERS

select date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, 
SUM(CAST(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
from Covid..CovidDeaths
where continent is not null
Group by date
order by 1,2;

--for the Global summary
select SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, 
SUM(CAST(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
from Covid..CovidDeaths
where continent is not null
--Group by date
order by 1,2;

-- TOTAL POPULATION AND VACCINATION

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
--the sum provides sum of people vaccinated partitioned by location, order by date, creates the continuous sum from everyday
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations
from Covid..CovidDeaths dea
join Covid..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Create a CTE for table above

--WITH PopVacc (Continent, location, date, population, new_vaccinations, TotalVaccinations)
--as
--(
--select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
----the sum provides sum of people vaccinated partitioned by location, order by date, creates the continuous sum from everyday
--SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations
--from Covid..CovidDeaths dea
--join Covid..CovidVaccinations vac
--on dea.location = vac.location
--and dea.date = vac.date
--where dea.continent is not null

--)
--select *, TotalVaccinations/population * 100 as PercentageVaccination
--from PopVacc

----USING A TEMP TABLE IN PLACE OF CTE

Drop table if exists #PopulationVaccinated
create table #PopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
TotalVaccinations numeric
)

insert into #PopulationVaccinated
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations
	from Covid..CovidDeaths dea
	join Covid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	--where dea.continent is not null
	--order by 2,3;

	select *, TotalVaccinations/Population * 100 as PercentageVaccination
	from #PopulationVaccinated
	order by 2,3

	--Creating View
	CREATE VIEW PercentageVaccinated as
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations
	from Covid..CovidDeaths dea
	join Covid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	--order by 2,3;

	select *
	from PercentageVaccinated;
	