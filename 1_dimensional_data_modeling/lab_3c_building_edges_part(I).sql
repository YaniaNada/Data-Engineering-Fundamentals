-- Building edges(branches) (I) --

-- Edge: player-to-game connection --
INSERT INTO edges

WITH deduped AS (
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY player_id, game_id) AS row_num
	FROM game_details
)

SELECT 
	player_id AS subject_identifier,
	'player'::vertex_type as subject_type,
	game_id AS object_identifier,
	'game'::vertex_type AS object_type,
	'plays_in'::edge_type AS edge_type,
	JSON_build_object(
		'start_position', start_position,
		'pts',pts,
		'team_id', team_id,
		'team_abbreviation', team_abbreviation
	) as properties

FROM deduped
WHERE row_num = 1;

-- Checking the tables --
SELECT * FROM vertices v JOIN edges e
	ON e.subject_identifier = v.identifier
	AND e.subject_type = t.type

-- Analytics example: Max point collected by each player --
SELECT 
	v.properties->>'player_name',
	MAX(CAST(e.properties->>'pts' AS INTEGER))
FROM vertices v JOIN edges e
	ON v.identifier = e.subject_identifier
	AND v.type = e.subject_type
GROUP BY 1
ORDER BY 2 DESC

