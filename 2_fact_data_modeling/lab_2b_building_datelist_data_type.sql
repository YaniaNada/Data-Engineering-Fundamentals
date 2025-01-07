-- LAB02b: getting the daily, weekly, monthly active users --

WITH users AS (
	SELECT * FROM users_cumulated
	WHERE date::DATE = '2023-01-31'
    ),


    --	generating a date series --
	series AS (
		SELECT * 
		FROM generate_series('2023-01-02','2023-01-31', INTERVAL '1 day') 
			as series_date
	),

    -- getting the dates a user was active in a binary format, where 1 & 0 indicates active & inactive days.
    -- The numbers are ordered in 'most recent' -> 'oldest' dates.
    -- For example between 2023-01-30 to 2023-01-20, if the 'placeholder_int_value' = 00110010011,
    -- this means the user was active on 28, 27, 24, 21, and 20.

	place_holder_ints AS (
		SELECT 
			CAST(CASE WHEN dates_active @> ARRAY[series_date::DATE]
				THEN CAST(POW(2, 32 - (date - series_date::DATE)) AS BIGINT)
				ELSE 0
			END AS BIT(32)) as placeholder_int_value,
			*
		FROM users CROSS JOIN series
	)

SELECT 
	user_id,

    --	If case: to store value as an integer -> SUM(CAST(placeholder_int_value AS BIGINT))
	placeholder_int_value, 
	
    -- to count no. of active days -> BIT_COUNT(placeholder_int_value) --
	BIT_COUNT(placeholder_int_value) > 0 
		AS dim_is_monthly_active,

    -- checking if user was active in last 7 days --
	BIT_COUNT(CAST('111111100000000000000000000000' AS BIT(32)) &
		placeholder_int_value) > 0
			AS dim_is_weekly_active,

    -- checking if user was active yesterday --
	BIT_COUNT(CAST('100000000000000000000000000000' AS BIT(32)) &
		placeholder_int_value) > 0
			AS dim_is_daily_active

FROM place_holder_ints
GROUP BY user_id, placeholder_int_value