-- Lab 01: Building a fact table --

-- Step 1: Checking for duplicates --
SELECT 
	game_id, team_id, player_id, COUNT(1)
FROM game_details
GROUP BY game_id, team_id, player_id
HAVING COUNT(1) > 1

-- Step 2: Deduping --
WITH deduped AS (
	SELECT 
		g.game_date_est,
		gd.*,
		ROW_NUMBER() OVER(PARTITION BY gd.game_id, team_id, player_id ORDER BY g.game_date_est) as row_num
	FROM game_details gd
	JOIN games g ON gd.game_id = g.game_id
	)

SELECT * 
FROM deduped
WHERE row_num = 1

-- Step 3: Feature engineering (Version 1) --
WITH deduped AS (
	SELECT 
		g.game_date_est,
		g.season,
		g.home_team_id,
		gd.*,
		ROW_NUMBER() OVER(PARTITION BY gd.game_id, team_id, player_id ORDER BY g.game_date_est) as row_num
	FROM game_details gd
	JOIN games g ON gd.game_id = g.game_id
	WHERE g.game_date_est = '2016-10-04'
	)

SELECT 
	game_date_est,
	season,
	team_id,
	team_id = home_team_id AS dim_is_playing_at_home,
	player_id,
	player_name,
	start_position,
	comment,
	"min" AS minutes,
	fgm,
	fga,
	fg3m,
	fg3a,
	ftm,
	fta,
	oreb,
	dreb,
	reb,
	ast,
	stl,
	blk,
	"TO" AS turnovers,
	pf,
	pts,
	plus_minus
FROM deduped
WHERE row_num = 1

-- Step 3: Feature engineering (Version 2) --
WITH deduped AS (
	SELECT 
		g.game_date_est,
		g.season,
		g.home_team_id,
		gd.*,
		ROW_NUMBER() OVER(PARTITION BY gd.game_id, team_id, player_id ORDER BY g.game_date_est) as row_num
	FROM game_details gd
	JOIN games g ON gd.game_id = g.game_id
	WHERE g.game_date_est = '2016-10-04'
	)

SELECT 
	game_date_est,
	season,
	team_id,
	team_id = home_team_id AS dim_is_playing_at_home,
	player_id,
	player_name,
	start_position,
	COALESCE(POSITION('DNP' in comment), 0)>0 as dim_did_not_play,
	COALESCE(POSITION('DND' in comment), 0)>0 as dim_did_not_dress,
	COALESCE(POSITION('NWT' in comment), 0)>0 as dim_not_with_team,
	CAST(SPLIT_PART(min, ':',1) AS REAL)
		+ CAST(SPLIT_PART(min, ':',2) AS REAL)/60 
		AS minutes,
	fgm,
	fga,
	fg3m,
	fg3a,
	ftm,
	fta,
	oreb,
	dreb,
	reb,
	ast,
	stl,
	blk,
	"TO" AS turnovers,
	pf,
	pts,
	plus_minus
FROM deduped
WHERE row_num = 1

-- Step 4: Creating the Fact table -- 
CREATE TABLE fct_game_details(
	dim_game_date DATE,
	dim_season INTEGER,
	dim_team_id INTEGER,
	dim_player_id INTEGER,
	dim_player_name TEXT,
	dim_start_position TEXT,
	dim_is_playing_at_home BOOLEAN,
	dim_did_not_play BOOLEAN,
	dim_did_not_dress BOOLEAN,
	dim_not_with_team BOOLEAN,
	m_minutes REAL,
	m_fgm INTEGER,
	m_fga INTEGER,
	m_fg3m INTEGER,
	m_fg3a INTEGER,
	m_ftm INTEGER,
	m_fta INTEGER,
	m_oreb INTEGER,
	m_dreb INTEGER,
	m_reb INTEGER,
	m_ast INTEGER,
	m_stl INTEGER,
	m_blk INTEGER,
	m_turnovers INTEGER,
	m_pf INTEGER,
	m_pts INTEGER,
	m_plus_minus INTEGER,
	PRIMARY KEY (dim_game_date, dim_team_id, dim_player_id)
);

-- Inserting data into the Fact table --
INSERT INTO fct_game_details
WITH deduped AS (
	SELECT 
		g.game_date_est,
		g.season,
		g.home_team_id,
		gd.*,
		ROW_NUMBER() OVER(PARTITION BY gd.game_id, team_id, player_id ORDER BY g.game_date_est) as row_num
	FROM game_details gd
	JOIN games g ON gd.game_id = g.game_id
	)

SELECT 
	game_date_est as dim_game_date,
	season AS dim_season,
	team_id AS dim_team_id,
	player_id AS dim_player_id,
	player_name AS dim_player_name,
	start_position AS dim_start_position,
	team_id = home_team_id AS dim_is_playing_at_home,
	
	COALESCE(POSITION('DNP' in comment), 0)>0 as dim_did_not_play,
	COALESCE(POSITION('DND' in comment), 0)>0 as dim_did_not_dress,
	COALESCE(POSITION('NWT' in comment), 0)>0 as dim_not_with_team,
	CAST(SPLIT_PART(min, ':',1) AS REAL)
		+ CAST(SPLIT_PART(min, ':',2) AS REAL)/60 
		AS m_minutes,
	fgm AS m_fgm,
	fga AS m_fga,
	fg3m AS m_fg3m,
	fg3a AS m_gf3a,
	ftm AS m_ftm,
	fta AS m_fta,
	oreb AS m_oreb,
	dreb AS m_dreb,
	reb AS m_reb,
	ast AS m_ast,
	stl AS m_stl,
	blk AS m_blk,
	"TO" AS m_turnovers,
	pf AS m_pf,
	pts AS m_pts,
	plus_minus AS m_plus_minus
FROM deduped
WHERE row_num = 1

-- checking table values --
SELECT * FROM fct_game_details

-- Analytics example: Player that bailed out on most games --
SELECT
	dim_player_name,
	COUNT(CASE WHEN dim_not_with_team THEN 1 END) AS bailed_num
FROM fct_game_details
GROUP BY dim_player_name
ORDER BY bailed_num DESC

-- The above case with more detail to get an accurate picture of the bail out numbers --
SELECT
	dim_player_name,
	COUNT(1) AS num_games,
	COUNT(CASE WHEN dim_not_with_team THEN 1 END) AS bailed_num,
	CAST(COUNT(CASE WHEN dim_not_with_team THEN 1 END) AS REAL)/COUNT(1) AS bail_percent
FROM fct_game_details
GROUP BY dim_player_name
ORDER BY bail_percent DESC