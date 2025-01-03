 -- LAB01: Designing a cumulative table --
  
 CREATE TYPE season_stats AS (
                         season Integer,
                         pts REAL,
                         ast REAL,
                         reb REAL,
                         weight INTEGER
                       );

 CREATE TYPE scoring_class AS
     ENUM ('bad', 'average', 'good', 'star');


 CREATE TABLE players (
     player_name TEXT,
     height TEXT,
     college TEXT,
     country TEXT,
     draft_year TEXT,
     draft_round TEXT,
     draft_number TEXT,
     seasons season_stats[],
     scoring_class scoring_class,
     years_since_last_active INTEGER,
     is_active BOOLEAN,
     current_season INTEGER,
     PRIMARY KEY (player_name, current_season)
 );


WITH last_season AS (
	SELECT * FROM players
	WHERE current_season = 2022			-- ran from 1995-2022
), 
 this_season AS (
	 SELECT * FROM player_seasons
	WHERE season = 2023					-- ran from 1996-2023
)
 INSERT INTO players
	SELECT
        COALESCE(ls.player_name, ts.player_name) as player_name,
        COALESCE(ls.height, ts.height) as height,
        COALESCE(ls.college, ts.college) as college,
        COALESCE(ls.country, ts.country) as country,
        COALESCE(ls.draft_year, ts.draft_year) as draft_year,
        COALESCE(ls.draft_round, ts.draft_round) as draft_round,
        COALESCE(ls.draft_number, ts.draft_number) as draft_number,
        COALESCE(ls.seasons,
            ARRAY[]::season_stats[]
            ) || CASE WHEN ts.season IS NOT NULL THEN
                ARRAY[ROW(
                ts.season,
                ts.pts,
                ts.ast,
                ts.reb, ts.weight)::season_stats]
                ELSE ARRAY[]::season_stats[] 
				END as seasons,
         CASE
             WHEN ts.season IS NOT NULL THEN
                 (CASE WHEN ts.pts > 20 THEN 'star'
                    WHEN ts.pts > 15 THEN 'good'
                    WHEN ts.pts > 10 THEN 'average'
                    ELSE 'bad' END)::scoring_class
             ELSE ls.scoring_class
         END as scoring_class,
		 CASE WHEN ts.season IS NOT NULL THEN 0
			ELSE ls.years_since_last_active+1
		END AS years_since_last_active,
         ts.season IS NOT NULL as is_active,
         COALESCE(ts.season, ls.current_season+1) AS current_season

    FROM last_season ls
    FULL OUTER JOIN this_season ts
    ON ls.player_name = ts.player_name

-- flattening out the nested column values --
WITH unnested AS (
SELECT player_name,
	UNNEST(season_stats) AS season_stats
FROM players WHERE current_season = 2001
)
SELECT player_name,
		(season_stats::season_stats).*
FROM unnested;

-- test example --
SELECT * FROM players 
WHERE current_season = 2001
AND player_name = 'Michael Jordan'

-- test example --
SELECT 
	player_name,
	season_stats[1] AS first_season,
	season_stats[CARDINALITY(season_stats)] AS latest_season
FROM players 
WHERE current_season = 2001

-- Analytics query example --
SELECT 
	player_name,
	(season_stats[CARDINALITY(season_stats)]::season_stats).pts/
        CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1 
        ELSE (season_stats[1]::season_stats).pts END

FROM players 
WHERE current_season = 2001
ORDER BY 2 DESC
