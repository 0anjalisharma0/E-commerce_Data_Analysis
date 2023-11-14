-- 1).Analyzing Channel Portofolios
-- - Pull weekly sessions from 22 Aug - 29 Nov for gsearch and bsearch, utm campaign nonbrand 
USE mavenfuzzyfactory;
SELECT
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) AS total_session,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END)  AS gsearch_session,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END)  AS bsearch_session
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29'
    AND utm_source IN ('gsearch', 'bsearch')
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

-- 2). Comparing Channel Characteristics**
-- Pull mobile session from 22 Aug - 30 Nov for gsearch and bsearch, utm campaign nonbrand
SELECT
    utm_source,
    COUNT(DISTINCT website_session_id) AS total_session,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_session,
    ROUND(100*(COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)),2)
        AS percentage_mobile_session
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-30'
    AND utm_source IN ('gsearch', 'bsearch')
    AND utm_campaign = 'nonbrand'
GROUP BY 1;

-- 3). Cross-Channel Bid Optimization**
-- Based on device type, pull gsearch and bsearch nonbrand conversion rates (order/session) from 22 Aug - 18 Sep
SELECT
    device_type,
    utm_source,
    COUNT(DISTINCT w.website_session_id) AS total_session,
    COUNT(DISTINCT order_id) AS total_order,
    ROUND(100*(COUNT(DISTINCT order_id)/COUNT(DISTINCT w.website_session_id)),2)
        AS percentage_cvr
FROM website_sessions w
	LEFT JOIN orders o
		ON w.website_session_id = o.website_session_id
WHERE w.created_at BETWEEN '2012-08-22' AND '2012-09-18'
    AND utm_source IN ('gsearch', 'bsearch')
    AND utm_campaign = 'nonbrand'
GROUP BY 1,2; 

-- 4). Channel Portofolio Trends**
-- Pull weekly sessions gsearch and bsearch nonbrand sessions by device type from 4 Nov - 22 Dec
SELECT
	MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT website_session_id) AS total_session,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS gd_session,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS bd_session,
	ROUND(100*(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END)),2) AS percentage_gd_bd,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS gm_session,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS bm_session,
	ROUND(100*(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END)),2) AS percentage_gm_bm
FROM website_sessions
WHERE created_at BETWEEN '2012-11-04' AND '2012-12-22'
	AND utm_source IN ('gsearch', 'bsearch')
	AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

-- 5). Analyzing Free Channels
-- Analyze organic search, direct type in, and paid brand or nonbrand sessions
CREATE TEMPORARY TABLE channel_cte 
SELECT 
	created_at,
	website_session_id,
	CASE 
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
		WHEN utm_campaign = 'brand' THEN 'paid_brand'
		WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
		WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group
FROM website_sessions
WHERE created_at < '2012-12-23';

SELECT 
	MONTH(created_at) AS months,
	COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS paid_brand,
	COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS paid_nonbrand,
	ROUND(100*(COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END)),2) AS percent_ratio_brand_nonbrand,

	COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic_search,
	ROUND(100*(COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END)),2) AS percent_ratio_organic_nonbrand,

	COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) AS direct,
	ROUND(100*(COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END)),2) AS percent_ratio_direct_nonbrand
FROM channel_cte
GROUP BY MONTH(created_at);

-- 6).Business Patterns & Seasonality: Analyzing Seasonality
-- Pull monthly and weekly orders and sessions in 2012
-- monthly seasons
SELECT
    MONTH(w.created_at) AS months,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(100*(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id)),2) AS cvr
FROM website_sessions w
    LEFT JOIN orders o
        ON w.website_session_id = o.website_session_id
WHERE w.created_at < '2013-01-01'
GROUP BY MONTH(w.created_at);

-- -- weekly seasons
SELECT
    MIN(DATE(w.created_at)) AS week_start_date,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(100*(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id)),2) AS cvr
FROM website_sessions w
    LEFT JOIN orders o
        ON w.website_session_id = o.website_session_id
WHERE w.created_at < '2013-01-01'
GROUP BY WEEK(w.created_at);

-- Analyzing Business Patterns**
-- Pull sessions beside hour and day of the week in 15 Sep - 15 Nov 2012
CREATE TEMPORARY TABLE time_session_cte 
SELECT
    DATE(created_at) AS dt,
    WEEKDAY(created_at) AS wk,
    HOUR(created_at) AS hr,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2,3;

SELECT
    hr,
    ROUND(AVG(CASE WHEN wk = 0 THEN sessions ELSE NULL END),0) AS monday,
    ROUND(AVG(CASE WHEN wk = 1 THEN sessions ELSE NULL END),0) AS tuesday,
    ROUND(AVG(CASE WHEN wk = 2 THEN sessions ELSE NULL END),0) AS wednesday,
    ROUND(AVG(CASE WHEN wk = 3 THEN sessions ELSE NULL END),0) AS thursday,
    ROUND(AVG(CASE WHEN wk = 4 THEN sessions ELSE NULL END),0) AS friday,
    ROUND(AVG(CASE WHEN wk = 5 THEN sessions ELSE NULL END),0) AS saturday,
    ROUND(AVG(CASE WHEN wk = 6 THEN sessions ELSE NULL END),0) AS sunday
FROM time_session_cte
GROUP BY 1
ORDER BY 1;
