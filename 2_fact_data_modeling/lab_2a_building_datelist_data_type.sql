-- LAB02a: building table to get relevant fields from 'events'--

-- Insight we want out of the 'events':What different kinds of users (daily/weekly/monthly users) are active?

-- checking the data we have in events --
SELECT 
	*
FROM events;

-- checking the period for which we have data --
SELECT 
	MAX(event_time),
	MIN(event_time)
FROM events;

-- designing the table  --
CREATE TABLE users_cumulated(

	user_id TEXT, 
	
    --	The list of dates in the past where the user was active
	dates_active DATE[],
	
    --	The current date for the user
	date DATE,
	PRIMARY KEY (user_id, date)
)

-- loading data into the table --
INSERT INTO users_cumulated

WITH yesterday AS (
	SELECT 
		*
	FROM users_cumulated
	WHERE date::date = '2023-01-30'             --	'date' inserted from '2022-12-31' to '2023-01-30'
    ),

	today AS (
	SELECT 
		CAST(user_id AS TEXT) as user_id,
		event_time::date AS date_active
	FROM events
	WHERE event_time::date = '2023-01-31'       --	'event_date' inserted from '2023-01-01' to '2023-01-31'
		AND user_id IS NOT NULL
	GROUP BY user_id, event_time::date
	)

SELECT 
	COALESCE(t.user_id, y.user_id) AS user_id,
	CASE WHEN y.dates_active IS NULL
		THEN ARRAY[t.date_active]
		WHEN t.date_active IS NULL 
		THEN y.dates_active
	ELSE ARRAY[t.date_active] || y.dates_active 
	END as dates_active,
	COALESCE(t.date_active, y.date + INTERVAL '1 day') AS date
FROM today t FULL OUTER JOIN yesterday y
	ON t.user_id = y.user_id

-- Checking table values --
SELECT * FROM users_cumulated
WHERE date::date = '2023-01-31';

-- continued in LAB02b --
