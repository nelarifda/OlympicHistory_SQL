-- Olympics history dataset

-- 1. How many olympics games have been held?
select *
from athlete_events

select count(distinct Games) as total_olympic_games
from athlete_events

-- 2. List down all the olympics games held so far
select distinct Year, Season, City
from athlete_events
order by Year

-- 3. Mention the total no of nations who participated in each olympics game?
select *
from athlete_events

select distinct Games, count(distinct NOC) as total_countries
from athlete_events
group by Games


-- 4. Which year saw the highest and lowest number of countries participating in olympics?

with lowhighcountries_cte as 
(select Games, count(distinct NOC) as total_countries
from athlete_events
group by Games
)
select distinct concat(first_value(Games) over (order by total_countries), 
'-',
first_value(total_countries) over(order by total_countries)) as lowest_countries,
concat(first_value(Games) over (order by total_countries desc), 
'-',
first_value(total_countries) over(order by total_countries desc)) as highest_countries
from lowhighcountries_cte

-- 5. Which nation has participated in all of the olympic games?
select *
from athlete_events

select *
from noc_regions

select noc_regions.region as country, count(distinct Games) as total_games
from athlete_events
inner join noc_regions
	on athlete_events.NOC = noc_regions.NOC
group by noc_regions.region
having count(distinct Games) = 51

-- 6. Identify the sport which was played in all summer olympics
select *
from athlete_events

with totalsummer_cte as
(select count (distinct Games) as total_games
from athlete_events
where Games like '%Summer%'),
nogames_cte as 
(select Sport, Season, count(distinct Games) as no_of_games
from athlete_events
where Season = 'Summer'
group by Sport, Season)

select Sport, no_of_games, total_games
from nogames_cte
join totalsummer_cte
	ON total_games=no_of_games


-- 7. Which Sports were just played only once in the olympics?
with oneplay_cte as
(select Sport, count(distinct Games) as no_of_games
from athlete_events
group by Sport),
games_cte as
(select distinct (Games), Sport
from athlete_events)

select oneplay_cte.Sport, no_of_games, Games
from oneplay_cte
join games_cte
	on oneplay_cte.Sport = games_cte.Sport
where no_of_games = 1
order by Games


-- 8. Fetch the total no of sports played in each olympic games.
select *
from athlete_events

select distinct (Games), count(distinct Sport) as no_of_sport
from athlete_events
group by Games 
order by no_of_sport desc

-- 9. Fetch details of the oldest athletes to win a gold medal.
--- name, sex, age, team, games, city, event, medals
select *
from athlete_events

with gold_cte as
(select Name, Sex, Age, Team, Games, City, Event, Medal
from athlete_events
where Medal='Gold' and Age <> 'NA'
group by Name, Sex, Age, Team, Games, City, Event, Medal),
oldest_cte as
(select *, rank() over (order by Age desc) as rnk
from gold_cte
where Medal = 'Gold')

select *
from oldest_cte
where rnk = 1



-- 10. Find the Ratio of male and female athletes participated in all olympic games.
with countsex_cte as
(select Sex, count(Sex) as countsex, row_number() over (order by Sex) as rownum
from athlete_events
group by Sex),
min_cte as
(select * 
from countsex_cte
where rownum = 1),
max_cte as 
(select *
from countsex_cte
where rownum = 2)

select concat('1:', round(cast(max_cte.countsex as decimal)/min_cte.countsex,2)) as Ratio
from max_cte, min_cte


-- 11. Fetch the top 5 athletes who have won the most gold medals.
with gold_cte as
(select Name, Team, count(Medal) as total_gold
from athlete_events
where Medal='Gold'
group by Name, Team
--order by total_medal desc
),
rank5_cte as
(select *, dense_rank() over(order by total_gold desc) as rnk
from gold_cte)

select Name, Team, total_gold
from rank5_cte
where rnk<=5


-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with medal_cte as
(select Name, Team, count(Medal) as total_medal
from athlete_events
where Medal in ('Gold','Silver','Bronze')
group by Name, Team
),
rank_cte as
(select *, dense_rank() over (order by total_medal desc) as rnk
from medal_cte)

select Name, Team, total_medal
from rank_cte
where rnk<= 5

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with medals_cte as
(select noc_regions.region, COUNT(Medal) as total_medals
from athlete_events
join noc_regions
	on noc_regions.NOC = athlete_events.NOC
where Medal in ('Gold','Silver','Bronze')
group by noc_regions.region
), 
rankmed_cte as
(select *, dense_rank() over(order by total_medals desc) as rnk
from medals_cte)

select *
from rankmed_cte
where rnk<= 5

-- 14. List down total gold, silver and broze medals won by each country.
with gold_cte as
(select noc_regions.region as Country, count(Medal) as Gold
from athlete_events
join noc_regions
	on noc_regions.NOC = athlete_events.NOC
where Medal='Gold'
group by noc_regions.region),
silver_cte as
(select noc_regions.region as Country, count(Medal) as Silver
from athlete_events
join noc_regions
	on noc_regions.NOC = athlete_events.NOC
where Medal='Silver'
group by noc_regions.region),
bronze_cte as
(select noc_regions.region as Country, count(Medal) as Bronze
from athlete_events
join noc_regions
	on noc_regions.NOC = athlete_events.NOC
where Medal='Bronze'
group by noc_regions.region)

select gold_cte.Country, Gold, Silver, Bronze
from gold_cte 
join silver_cte
	on gold_cte.Country = silver_cte.Country
join bronze_cte
	on bronze_cte.Country = gold_cte.Country
order by Gold desc


-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
with data_cte as
(select noc_regions.region as Country, Games, Medal
from athlete_events
join noc_regions
	on athlete_events.NOC = noc_regions.NOC)

select Games, Country, 
sum(case when Medal = 'Gold' then 1 else 0 end) as Gold,
sum(case when Medal = 'Silver' then 1 else 0 end) as Silver,
sum(case when Medal = 'Bronze' then 1 else 0 end) as Bronze
from data_cte
group by Games,Country
order by Games,Country


-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with countrymedal_cte as
(select Games, noc_regions.region as Country,
count (case when Medal = 'Gold' then Medal end) as Gold_medal,
count(case when Medal = 'Silver' then Medal end) as Silver_medal,
count(case when Medal = 'Bronze' then Medal end) as Bronze_medal
from athlete_events
join noc_regions
	on athlete_events.NOC = noc_regions.NOC
group by Games, noc_regions.region
)

select distinct Games, 
concat (first_value (Country) over (partition by Games order by Gold_medal desc), '-',
first_value(Gold_medal) over (partition by Games order by Gold_medal desc)) as Max_gold,
concat (first_value (Country) over (partition by Games order by Silver_medal desc), '-',
first_value(Silver_medal) over (partition by Games order by Silver_medal desc)) as Max_silver,
concat (first_value (Country) over (partition by Games order by Bronze_medal desc), '-',
first_value(Bronze_medal) over (partition by Games order by Bronze_medal desc)) as Max_bronze
from countrymedal_cte
order by Games


-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
with countrymedal_cte as
(select Games, noc_regions.region as Country,
count (case when Medal = 'Gold' then Medal end) as Gold_medal,
count(case when Medal = 'Silver' then Medal end) as Silver_medal,
count(case when Medal = 'Bronze' then Medal end) as Bronze_medal,
count(case when Medal<> 'NA' then Medal end) as total_medals
from athlete_events
join noc_regions
	on athlete_events.NOC = noc_regions.NOC
group by Games, noc_regions.region
)

select distinct Games, 
concat (first_value (Country) over (partition by Games order by Gold_medal desc), '-',
first_value(Gold_medal) over (partition by Games order by Gold_medal desc)) as Max_gold,
concat (first_value (Country) over (partition by Games order by Silver_medal desc), '-',
first_value(Silver_medal) over (partition by Games order by Silver_medal desc)) as Max_silver,
concat (first_value (Country) over (partition by Games order by Bronze_medal desc), '-',
first_value(Bronze_medal) over (partition by Games order by Bronze_medal desc)) as Max_bronze,
concat (first_value (Country) over (partition by Games order by total_medals desc), '-',
first_value(total_medals) over (partition by Games order by total_medals desc)) as Total_medal
from countrymedal_cte
order by Games


-- 18. Which countries have never won gold medal but have won silver/bronze medals?
with silverbronze_cte as
(select noc_regions.region as Country,
count (case when Medal = 'Gold' then Medal end) as Gold_medal,
count(case when Medal = 'Silver' then Medal end) as Silver_medal,
count(case when Medal = 'Bronze' then Medal end) as Bronze_medal
from athlete_events
join noc_regions
	on athlete_events.NOC = noc_regions.NOC
where Medal <> 'NA'
group by noc_regions.region
)
select *
from silverbronze_cte
where Gold_medal = 0
order by Silver_medal desc, Bronze_medal desc


-- 19. In which Sport and event, Indonesia has won highest medals.
select *
from athlete_events

select Sport, Event, Count(Medal) as total_medals
from athlete_events
where Team = 'Indonesia'
and Medal <> 'NA'
group by Sport, Event
order by total_medals desc


-- 20. Break down all olympic games where indonesia won medal for Badminton and how many medals in each olympic games.
select *
from athlete_events
where Team = 'Indonesia'

select Games, Sport, count(Medal) as total_medals
from athlete_events
Where Team = 'Indonesia'
and Sport = 'Badminton'
and Medal <> 'NA'
group by Games, Sport