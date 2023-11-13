-- 1) Identifying the top website pages
USE mavenfuzzyfactory;
SELECT 
pageview_url,
Count(distinct website_session_id) AS sessions
FRom website_pageviews
WHERE created_at < '2012-06-09'
Group by 1
order by 2 DESC;

-- 2) Identifying top entry pages
CREATE TEMPORARY TABLE first_entry 
	SELECT
		website_session_id,
		MIN(website_pageview_id) AS first_pageview
	FROM website_pageviews
	WHERE created_at < '2012-06-12'
	GROUP BY 1;
    
SELECT 
	website_pageviews.pageview_url AS landing_page,
	COUNT(first_entry.website_session_id) AS session_hitting_this_landing_page
FROM first_entry 
	LEFT JOIN website_pageviews 
		ON first_entry.first_pageview = website_pageviews.website_pageview_id
GROUP BY landing_page;

-- 3) Calculation of bounce rate
-- find the first(min.) website_pageview_id for relevant sessions

CREATE TEMPORARY TABLE first_pageview_demo
SELECT 
website_pageviews.website_session_id,
min(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id = website_pageviews.website_session_id
AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-02-01'
GROUp BY
website_pageviews.website_session_id;

-- identify the landing page of each session
-- website_pageview is the landing page

CREATE TEMPORARY TABLE landing_page_demo
SELECT
first_pageview_demo.website_session_id,
website_pageviews.pageview_url AS landing_page
FROM first_pageview_demo
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_pageview_demo.min_pageview_id;

-- counting pageviews for each session,to ientify "bounces"
-- make a table to include a count of pageviews per session
-- for identifying bounces count of pageview = 1

CREATE TEMPORARY TABLE bounce_session_only
SELECT
landing_page_demo.website_session_id,
landing_page_demo.landing_page,
COUNT(website_pageviews.website_pageview_id) AS count_of_page_viewed
FROM landing_page_demo
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = landing_page_demo.website_session_id
GROUP BY
landing_page_demo.website_session_id,
landing_page_demo.landing_page
HAVING
count_of_page_viewed = 1;

-- create a table to identify bounce_session_website_id
SELECT
landing_page_demo.website_session_id,
landing_page_demo.landing_page,
bounce_session_only.website_session_id AS bounced_session_website_id
FROM landing_page_demo
LEFT JOIN bounce_session_only
ON landing_page_demo.website_session_id = bounce_session_only.website_session_id
ORDER BY 
landing_page_demo.website_session_id;

-- calculating bounce rate
SELECT
landing_page_demo.landing_page,
COUNT(DISTINCT landing_page_demo.website_session_id) AS sessions,
COUNT(DISTINCT bounce_session_only.website_session_id) AS bounced_session,
COUNT(DISTINCT bounce_session_only.website_session_id)/COUNT(DISTINCT landing_page_demo.website_session_id) AS bounce_rate
FROM landing_page_demo
LEFT JOIN bounce_session_only
ON landing_page_demo.website_session_id = bounce_session_only.website_session_id
GROUP BY 
landing_page_demo.landing_page;

-- 4). Analyzing Landing Page Tests
-- Find when `/lander-1` was created on the website
USE mavenfuzzyfactory;
SELECT 
	MIN(created_at),
	MIN(website_pageview_id) AS lander1_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1'; 
-- Find the first website_pageview_id for relavant season with filter
CREATE TEMPORARY TABLE landing_page_test
SELECT
	p.website_session_id,
	MIN(p.website_pageview_id) AS first_landing_page,
	p.pageview_url AS landing_page
FROM website_pageviews p
	JOIN website_sessions s
		ON s.website_session_id = p.website_session_id
		AND s.created_at BETWEEN '2012-06-19' AND '2012-07-28'  -- lander-1 displayed to user at 2012-06-19
		AND utm_source = 'gsearch'
		AND utm_campaign ='nonbrand'
		AND p.pageview_url IN ('/home', '/lander-1')
GROUP BY 1, 3;

-- Count page views for each session to identify bounces (website_pageview_id = 1) each landing page
CREATE TEMPORARY TABLE bounced_test
SELECT
	l.website_session_id,
	l.landing_page,
	COUNT(p.website_pageview_id) AS count_of_page_viewed
FROM landing_page_test l
	LEFT JOIN website_pageviews p
		ON l.website_session_id = p.website_session_id
GROUP BY 1, 2
HAVING COUNT(p.website_pageview_id) = 1;

-- Summarize by counting total session and bounced session each landing page
SELECT
	l.landing_page,
	COUNT(DISTINCT l.website_session_id) AS total_session,
	COUNT(DISTINCT b.website_session_id) AS bounced_session,
	COUNT(DISTINCT b.website_session_id)/COUNT(DISTINCT l.website_session_id) AS bounce_rate
FROM landing_page_test l
LEFT JOIN bounced_test b
	ON l.website_session_id = b.website_session_id
GROUP BY l.landing_page;

-- 5). Landing Page Trend Analysis
-- Find the first website_pageview_id for relavant season with select created_at and filter
CREATE TEMPORARY TABLE landing_page_trend
SELECT
	p.created_at,
	p.website_session_id,
	p.pageview_url AS landing_page,
	MIN(p.website_pageview_id) AS first_landing_page
FROM website_pageviews p
	JOIN website_sessions s
		ON s.website_session_id = p.website_session_id
		AND s.created_at BETWEEN '2012-06-01' AND '2012-08-31' 
		AND utm_source = 'gsearch'
		AND utm_campaign ='nonbrand'
		AND p.pageview_url IN ('/home', '/lander-1')
GROUP BY 1, 2, 3;

-- Count page views for each session to identify bounces (website_pageview_id = 1)
CREATE TEMPORARY TABLE bounced_trend
SELECT
	l.website_session_id,
	l.landing_page,
	COUNT(p.website_pageview_id) AS count_of_page_viewed
FROM landing_page_trend l
	LEFT JOIN website_pageviews p
		ON l.website_session_id = p.website_session_id
GROUP BY 1, 2
HAVING COUNT(p.website_pageview_id) = 1;

SELECT
	MIN(DATE(l.created_at)) AS week_start,
	COUNT(DISTINCT b.website_session_id)/COUNT(DISTINCT l.website_session_id) AS bounce_rate,
	COUNT(DISTINCT CASE WHEN l.landing_page = '/home' THEN l.website_session_id ELSE NULL END) AS home_sessions,
	COUNT(DISTINCT CASE WHEN l.landing_page = '/lander-1' THEN l.website_session_id ELSE NULL END) AS lander_sessions
FROM landing_page_trend l
	LEFT JOIN bounced_trend b
		ON l.website_session_id = b.website_session_id
GROUP BY WEEK(l.created_at);

-- 7)Analyze Conversion Funnel Tests for /billing and new /billing-2 pages.
-- Find first time '/billing-2 was seen
SELECT 
	MIN(created_at) AS first_created,
	MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2';

-- Select all pageviews for relevant session
-- Aggregate and summarize the conversion rate
SELECT 
	billing_test.pageview_url AS billing_version,
	COUNT(DISTINCT billing_test.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders,
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT billing_test.website_session_id) AS session_to_order_rate
FROM 
(SELECT
		s.website_session_id,
		p.pageview_url
	FROM website_sessions s
		LEFT JOIN website_pageviews p
			ON s.website_session_id = p.website_session_id
	WHERE p.website_pageview_id >= 53550 -- first pageview when '/billing-2' was created
		AND s.created_at < '2012-11-10'
		AND p.pageview_url IN ('/billing', '/billing-2')
        ) AS billing_test 
	LEFT JOIN orders o
		ON billing_test.website_session_id = o.website_session_id
GROUP BY 1


