-- LAB02_B: Incremental SCD model, building up on LAB02_A --

CREATE TYPE scd_type AS (
					scoring_class scoring_class,
					is_active BOOLEAN,
					start_session INTEGER,
					end_season INTEGER
					)

WITH last_season_scd AS (
	SELECT * 
    FROM players_scd
    WHERE current_season = 2021
        AND end_season = 2021
),
	
	historical_scd AS (
		SELECT 
			player_name,
			scoring_class,
			is_active,
			start_season,
			end_season
		FROM players_scd
		WHERE current_season = 2021
		    AND end_season < 2021
	),

	this_season_data AS (
		SELECT * FROM players
		WHERE current_season = 2022
	),

-- Ist version --
	SELECT ts.player_name, 
		ts.scoring_class,ts.is_active,
		ls.scoring_class, ls.is_active
    FROM this_season_data ts 
        LEFT JOIN  last_season_scd ls
            ON ts.player_name = ls.player_name

-- Final version: building up on Ist version --
	unchanged_records AS (
		SELECT 
            ts.player_name, 
            ts.scoring_class,
            ts.is_active,
            ls.start_season, 
            ts.current_season as end_season 
        FROM this_season_data ts 
            JOIN  last_season_scd ls
                ON ts.player_name = ls.player_name
        WHERE ts.scoring_class = ls.scoring_class
            AND ts.is_active = ls.is_active
            ),
	
	changed_records AS (
		SELECT 
            ts.player_name, 
            UNNEST(ARRAY[
                ROW(
                    ls.scoring_class,
                    ls.is_active,
                    ls.start_season,
                    ls.end_season
                
                )::scd_type,
                ROW (
                    ts.scoring_class,
                    ts.is_active,
                    ts.current_season,
                    ts.current_season
                )::scd_type
            ]) as records
        FROM this_season_data ts 
            LEFT JOIN  last_season_scd ls
                ON ts.player_name = ls.player_name
        WHERE (ts.scoring_class <> ls.scoring_class
            OR ts.is_active <> ls.is_active)	
            ),
	
	unnested_changed_records AS (
			SELECT player_name, 
			(records::scd_type).*
			FROM changed_records
	),
	
	new_records AS (
		SELECT 
			ts.player_name,
			ts.scoring_class,
			ts.is_active,
			ts.current_season AS start_season,
			ts.current_season AS end_season
		
		FROM this_season_data ts
		LEFT JOIN last_season_scd ls
			ON ts.player_name = ls.player_name
		WHERE ls.player_name IS NULL
	)

SELECT * FROM historical_scd
UNION ALL
SELECT * FROM unchanged_records
UNION ALL
SELECT * FROM unnested_changed_records
UNION ALL
SELECT * FROM new_records

-- although the query is complex it's consuming less resources.
-- it's querying less data, in other words, processing less data.
-- problem here is data is processed sequentially, it depends on past data so it cannot run parallely.