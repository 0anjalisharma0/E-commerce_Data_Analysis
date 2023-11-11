-- 1) What is the TOP traffic source before 4 April 2012?
USE mavenfuzzyfactory;
SELECT utm_source,
utm_campaign,
http_referer,
COUNT(DISTINCT website_session_id) AS number_of_sessions
FROm website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 1,2,3
ORDER BY 4 DESC;

-- the above result shows that gsearch nonbrand campaign received highest traffic 

-- 2) What is the conversion rate from order to session? IF present cvr of the company is 4%,what insights can be drawn based on analysis? 

USE mavenfuzzyfactory;
SELECT 
COUNT(DISTINCT website_sessions.website_session_id) AS number_of_sessions,
COUNT(DISTINCT orders.website_session_id) AS number_of_orders,
COUNT(DISTINCT orders.website_session_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate

FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-04-12'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand';

-- the above result shows that cvr is 2.9% which means company is overbidding.

-- 3)What is the weekly traffic source trend?
SELECT
	MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions 
WHERE created_at < '2012-05-10'
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at), WEEK(created_at);

-- 4) What is the conversion rate from session to order,by device type?
SELECT 
device_type,
COUNT(DISTINCT(website_sessions.website_session_id)) AS session,
COUNT(DISTINCT(orders.order_id)) AS orders,
COUNT(DISTINCT(orders.order_id))/COUNT(DISTINCT(website_sessions.website_session_id)) AS session_to_order_cvr
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at <'2012-04-14'
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY device_type;

-- The above results shows that desktop has high session volume than mobile

-- 5) To analyse the impact on volume,Pull out the weekly trends for both mobile and desktop?
SELECT 
MIN(DATE(created_at)) AS week_start,
COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_session,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_session
FROM website_sessions
WHERE created_at < '2012-06-09'
AND created_at > '2012-04-15'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY 
YEAR(created_at),
WEEK(created_at)