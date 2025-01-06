-- Building vertices(nodes) --

-- Vertice: GAME --
INSERT INTO vertices
SELECT 
	game_id AS identifier,
	'game'::vertex_type AS type,
	JSON_build_object(
		'pts_home', pts_home,
		'pts_away', pts_away,
		'winning_team',  CASE WHEN home_team_wins = 1 THEN home_team_id ELSE visitor_team_id END 
			) AS properties

FROM games;

-- Vertice: PLAYER --
INSERT INTO vertices
WITH players_agg AS (
	SELECT 
		player_id AS identifier,
		MAX(player_name) AS player_name,
		COUNT(1) as number_of_games,
		SUM(pts) as total_points,
		ARRAY_AGG(DISTINCT team_id) AS teams
	FROM game_details
	GROUP BY player_id
	)

SELECT identifier, 
		'player'::vertex_type,
		JSON_build_object(
			'player_name', player_name,
			'number_of_games', number_of_games,
			'total_points', total_points,
			'teams', teams
		)
FROM players_agg;

-- Vertice: TEAM --
INSERT INTO vertices

WITH teams_deduped AS (
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY team_id) as row_num
	FROM teams
)
SELECT 
	team_id AS identifier,
	'team'::vertex_type AS type,
	JSON_build_object(
		'abbreviation', abbreviation,
		'nickname', nickname,
		'year_founded', yearfounded,
		'city', city,
		'arena', arena
	)
FROM teams_deduped
WHERE row_num =1;

-- checking table values --
SELECT type, COUNT(1)
FROM vertices
GROUP BY 1

