/* CREATE TABLE QUERIES */

CREATE TABLE matches(
id int,
city varchar(255),
date date,
player_of_match varchar(255),
venue varchar(255),
neutral_venue int,
team1 varchar(255),
team2 varchar(255),
toss_winner varchar(255),
toss_decision varchar(255),
winner varchar(255),
result varchar(255),
result_margin int,
eliminator varchar(255),
method varchar(255),
umpire1 varchar(255),
umpire2 varchar(255)
);

CREATE TABLE deliveries(
id int,
inning int,
over int,
ball int,
batsman varchar(255),
non_striker varchar(255),
bowler varchar(255),
batsman_runs int,
extra_runs int,
total_runs int,
is_wicket int,
dismissal_kind varchar(255),
player_dismissed varchar(255),
fielder varchar(255),
extras_type varchar(255),
batting_team varchar(255),
bowling_team varchar(255)
);

COPY matches 
FROM 'C:\Program Files\PostgreSQL\16\data\IPL Dataset\IPL_matches.csv'
DELIMITER ','
CSV HEADER;

COPY deliveries
FROM 'C:\Program Files\PostgreSQL\16\data\IPL Dataset\IPL_Ball.csv'
DELIMITER ','
CSV HEADER;

select * from deliveries;

select * from matches;


/*players with good Average who have played more than 2 ipl seasons*/	 

select batsman_name, runs_scored, no_dismissal, (runs_scored/no_dismissal) as average, season from
(select batsman as batsman_name, sum(batsman_runs) as runs_scored,
       sum(is_wicket) as no_dismissal , count(distinct(extract('year' from date))) as season
	   from deliveries as a
	   left join matches as b
	   on a.id = b.id
	   group by 1) as c
	   where c.season > 2
	   order by average desc
	   limit 10;

/*players with high S.R who have faced at least 500 balls*/

select batsman_name, runs_scored, balls_faced, round((cast(runs_scored as decimal)/balls_faced)*100, 0) as strike_rate from 
(select batsman as batsman_name, sum(batsman_runs) as runs_scored,
       count(*) as balls_faced from deliveries where extras_type != 'wides'
	   group by 1) as a where balls_faced >= 500
	   order by 4 desc
	   limit 10;
	   
	   


select sum(batsman_runs),count(batsman_runs) from deliveries where batsman_runs in (4,6) ;

select sum(batsman_runs),count(batsman_runs) from deliveries where batsman_runs = 6;

/* Hard-hitting players who have scored most runs in boundaries and have played more the 2 ipl season */

select batsman_name, total_runs, runs_boundary, round((cast(runs_boundary as decimal)/total_runs)*100, 2) as boundary_percent, season from	   
(select batsman as batsman_name, sum(batsman_runs) as total_runs,
            sum(case when batsman_runs = 4 then 4
		         when batsman_runs = 6 then 6
				 when batsman_runs = 4 then 4
				 else 0 
		         end) as runs_boundary,
       count(distinct(extract('year' from date))) as season      
	   from deliveries as a
	   left join matches as b
	   on a.id = b.id       
	   group by 1) as c 
	   where c. season > 2 
	   order by 4 desc
	   limit 10;
	   
/*bowlers with good economy who have bowled at least 500
balls in IPL so far*/

select bowler as bowler_name, 
(sum(total_runs) / (count(over)/6.0)) as economy       
from deliveries 
group by 1
having count(bowler) >= 500  
order by economy asc
limit 10;	


/* bowlers with the best strike rate and who have bowled at least
500 balls in IPL so far	*/  

select bowler as bowler_name, 
(count(bowler) / sum(is_wicket)) as strike_rate      
from deliveries 
group by 1
having count(bowler) >= 500  
order by strike_rate asc
limit 10;	



/* All_rounders with the best batting as well as bowling strike rate
and who have faced at least 500 balls in IPL so far and have bowled minimum 300
balls */

select Allrounder_name, runs_scored, balls_faced ,balls_bowled, bowler_strike_rate,
       round((cast(runs_scored as decimal)/balls_faced)*100, 0) as batsman_strike_rate from 
(select batsman as Allrounder_name,sum(batsman_runs) as runs_scored,
       count(batsman_runs) as balls_faced , count(bowler) as balls_bowled, 
       (count(bowler) / sum(is_wicket)) as bowler_strike_rate   
       from deliveries where extras_type != 'wides'
	   group by 1 having sum(is_wicket) != 0) as a where balls_faced >= 500 and balls_bowled >= 300
	   order by 6 desc, 5 asc 
	   limit 10;



/* 1. Get the count of cities that have hosted an IPL match */

select count(distinct(city))  from matches;

/* Create table deliveries_v02 with all the columns of the table ‘deliveries’ and an additional
column ball_result containing values boundary, dot or other depending on the total_run */

Create table deliveries_v02 as
select *, case
               when total_runs >= 4 then 'Boundary'
			   when total_runs = 0 then 'Dot'
			   else 'Other'
			   end ball_result
from deliveries;

select * from deliveries_v02;

/* Write a query to fetch the total number of boundaries and dot balls from the
deliveries_v02 table. */

select count(ball_result) from deliveries_v02 where ball_result = 'Boundary';

select count(ball_result) from deliveries_v02 where ball_result = 'Dot';

select count(ball_result) from deliveries_v02 where ball_result = 'Boundary' or ball_result = 'Dot' ;

/* 4. Write a query to fetch the total number of boundaries scored by each team from the
deliveries_v02 table and order it in descending order of the number of boundaries
scored. */

select batting_team, count(ball_result) as boundaries_num 
from deliveries_v02 
where ball_result = 'Boundary'
group by 1
order by 2 desc;

/* 5. Write a query to fetch the total number of dot balls bowled by each team and order it in
descending order of the total number of dot balls bowled. */

select batting_team, count(ball_result) as dot_balls 
from deliveries_v02 
where ball_result = 'Dot'
group by 1
order by 2 desc;

/* 6. Write a query to fetch the total number of dismissals by dismissal kinds where dismissal
kind is not NA */

select dismissal_kind, count(dismissal_kind) 
from deliveries_v02
where dismissal_kind != 'NA'
group by 1
order by 2 desc;

/* 7. Write a query to get the top 5 bowlers who conceded maximum extra runs from the
deliveries table */

select bowler as bowler_name, sum(extra_runs) as total_extras
from deliveries_v02
group by 1
order by 2 desc
limit 5;

/* 8. Write a query to create a table named deliveries_v03 with all the columns of
deliveries_v02 table and two additional column (named venue and match_date) of venue
and date from table matches */

Create table deliveries_v03 as (
select a.*, b.date as match_date, b.venue as venue
from deliveries_v02 as a
left join matches as b
on a.id = b.id);

select * from deliveries_v03;

/* 9. Write a query to fetch the total runs scored for each venue and order it in the descending
order of total runs scored. */


select venue as venue_name, sum(total_runs) as total_runs_venue
from deliveries_v03
group by 1
order by 2 desc;

/* 10. Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the
descending order of total runs scored. */

select  venue as venue_name, sum(total_runs) as total_runs, extract('year' from match_date) as Year_wise
from deliveries_v03
where venue = 'Eden Gardens'
group by 3,1
order by 2 desc;




