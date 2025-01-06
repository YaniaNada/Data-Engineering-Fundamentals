-- Building edges(branches) (II) --

-- Edge: player-to-player connection --
INSERT INTO edges

WITH deduped AS (
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY player_id, game_id) AS row_num
	FROM game_details
	),
	
	filtered AS (
		SELECT * FROM deduped
		WHERE row_num = 1
	),
	
	aggregated AS (
		SELECT 
			f1.player_id as subject_player_id,
			f2.player_id as object_player_id,
			CASE WHEN f1.team_abbreviation = f2.team_abbreviation
				THEN 'shares_team'::edge_type
			ELSE 'plays_against'::edge_type
			END as edge_type,
			MAX(f1.player_name) AS subject_player_name,
			MAX(f2.player_name) AS object_player_name,
			COUNT(1) AS num_games,
			SUM(f1.pts) AS subject_points,
			SUM(f2.pts) AS object_points
		FROM filtered f1 JOIN filtered f2
			ON f1.game_id = f2.game_id
			AND f1.player_name <> f2.player_name
		WHERE f1.player_id > f2.player_id
		GROUP BY subject_player_id,
			object_player_id,
			CASE WHEN f1.team_abbreviation = f2.team_abbreviation
				THEN 'shares_team'::edge_type
			ELSE 'plays_against'::edge_type
			END
	)

SELECT 
	subject_player_id AS subject_identifier,
	'player'::vertex_type AS subject_type,
	object_player_id AS object_identifier,
	'player'::vertex_type AS object_type,
	edge_type AS edge_type,
	JSON_build_object(
	'num_games', num_games,
	'subject_points', subject_points,
	'object_points', object_points
	)
FROM aggregated

-- Checking the table values --
SELECT * 
FROM vertices v JOIN edges e
	ON v.identifier = e.subject_identifier
		AND v.type = e.subject_type
WHERE e.object_type = 'player'::vertex_type

-- Analytics example: Average points of players in a game against each other --
SELECT 
	v.properties->>'player_name' as player_1,
	e.properties->>'subject_points' as player1_pts,
	e.object_identifier as player_2,
	e.properties->>'object_points' as player2_pts,
	e.properties->>'num_games' as num_games,
	CAST(e.properties->>'subject_points' as REAL)/
	CAST(e.properties->>'num_games' as REAL) as player1_games_avg,
	CAST(e.properties->>'object_points' as REAL)/
	CAST(e.properties->>'num_games' as REAL) as player2_games_avg
FROM vertices v JOIN edges e
	ON v.identifier = e.subject_identifier
		AND v.type = e.subject_type
WHERE e.object_type = 'player'::vertex_type 
GROUP BY player_1, 
	player1_pts,
	player_2, 
	player2_pts,
	num_games,
	player1_games_avg,  
	player2_games_avg
ORDER BY num_games DESC
