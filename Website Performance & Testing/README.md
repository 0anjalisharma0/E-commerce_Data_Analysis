
**Analyzing Website Performance**
### 📌  Analyzing Top Website Content
Website content analysis is about **understanding which pages are seen the most by your users, to identify where to focus on improving your business.**

### 📌 Applications of Analyzing Top Website Content
- Finding the most-viewed pages that customers view on your site
- Identifying the most common entry pages to your website – the first thing a user sees
- For most-viewed pages and most common entry pages, understanding how those pages perform for your business objectives

### **Task**
### **1. Identifying Top Website Pages**
**Query :**
```sql
SELECT 
	pageview_url,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY 2 DESC
```
**Result :**
![Screenshot (8)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/c103c78d-6f86-4787-b96a-c029cd73b73f)

### **2. Identifying Top Entry Pages**

**Query :**
```sql
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
GROUP BY landing_page,
```

**Result :**
![Screenshot (9)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/8f57e51c-944a-459a-8fd8-e745929e3424)

 
*INSIGHTS — Homepage is the top landing page. Analyze landing page performance, for the homepage specifically*

### ** Landing Page Performance and Testing**
Landing page analysis and testing is about **understanding the performance of key landing pages and then testing to improve results**

**Applications of Landing Page Performance and Testing**
– high volume pages with higher than expected bounce rates or low conversion rates
- Setting up A/B experiments on live traffic to see if you can improve your bounce rates and conversion rates 

### **3. Calculation of Bounce Rate**
**Query :**
```sql
-- find the first(min.) website_pageview_id for relevant sessions
USE mavenfuzzyfactory;
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
```

**Result :**
![Screenshot (1)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/99ba831e-c21f-4455-9375-c0702f39c6c5)

*INSIGHTS —A 60% bounce rate is pretty high especially for paid search.*

### **4. Analyzing Landing Page Tests**

Analyze a new page that will improve performance, and analyze the results of an A/B split test against the homepage. A/B test on **/lander-1** and **/home** for **gsearch nonbrand** campaign.

**Steps :**
- Find when **/lander-1** was created on the website by use either date or pageview id to limit the results
- Find the first `website_pageview_id` for relavant season with filter by date periode, between **'2012-06-01' and '2012-08-31'**
- Count page views for each session to identify bounces (`website_pageview_id` = 1) each landing page
- Summarize by counting total session and bounced session each landing page

**Query :**
    
```sql
-- Find when `/lander-1` was created on the website
SELECT 
	MIN(created_at),
	MIN(website_pageview_id) AS lander1_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';
```
![Screenshot (10)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/2cefe727-d0bf-4e02-8334-9f125ffa97d6)


```sql
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
GROUP BY 1, 3
```
![Screenshot (11)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/a687d384-f731-4602-9550-4998245db077)


```sql
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
HAVING COUNT(p.website_pageview_id) = 1
```

![Screenshot (12)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/2b892f51-d267-4d1e-b4a2-c078de894d79)


```sql
-- Summarize by counting total session and bounced session each landing page
SELECT
	l.landing_page,
	COUNT(DISTINCT l.website_session_id) AS total_session,
	COUNT(DISTINCT b.website_session_id) AS bounced_session,
	COUNT(DISTINCT b.website_session_id)/COUNT(DISTINCT l.website_session_id) AS bounce_rate
FROM landing_page_test l
LEFT JOIN bounced_test b
	ON l.website_session_id = b.website_session_id
GROUP BY l.landing_page
```

**Result :**


![Screenshot (13)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/316d5cda-1677-4587-9d29-5f0b5c3d13d2)
  
**INSIGHTS — The Lander page has a lower bounce rate than home page. Fewer customers have bounced on the lander page.*

### **5. Landing Page Trend Analysis**


**Steps :**
- Pull paid **gsearch nonbrand** campaign traffic on **/home** and **/lander-1** pages, trended weekly since 2012-06-01 and the bounce rates.
- Find the first `website_pageview_id` for relavant season with select created_at and filter
- Count page views for each session to identify bounces (`website_pageview_id` = 1)
- Summarize sessions, bounced sessions and bounce rate by week

**Query :**

```sql
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
GROUP BY 1, 2, 3
```
![Screenshot (14)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/76bc52e9-e199-4459-8d8e-f91d2ee9596f)


```sql
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
HAVING COUNT(p.website_pageview_id) = 1
```
![Screenshot (15)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/3f22ad0f-f821-40c8-8f49-db4c7c191b73)


```sql
SELECT
	MIN(DATE(l.created_at)) AS week_start,
	COUNT(DISTINCT b.website_session_id)/COUNT(DISTINCT l.website_session_id) AS bounce_rate,
	COUNT(DISTINCT CASE WHEN l.landing_page = '/home' THEN l.website_session_id ELSE NULL END) AS home_sessions,
	COUNT(DISTINCT CASE WHEN l.landing_page = '/lander-1' THEN l.website_session_id ELSE NULL END) AS lander_sessions
FROM landing_page_trend l
	LEFT JOIN bounced_trend b
		ON l.website_session_id = b.website_session_id
GROUP BY WEEK(l.created_at)
```

**Result :**

![Screenshot (16)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/5a42b871-0f36-4cbc-bf07-e446e6dc0b66)
 
 5 — All traffict was directed to home until 2012-06-17, and starting on 2012-08-05, all traffic was directed to lander-1. There has been improvement as the bounce rate decreased. The /lander-1 page changes are operating as well.

 ### **6. Building Conversion Funnels**

### 📌 ** Analyzing and Testing Conversion Funnels**
Conversion funnel analysis is about **understanding and optimizing each step of  user’s experience on their journey toward purchasing  products**

### 📌 **Applications of Analyzing and Testing Conversion Funnels**
- Identifying the most common paths customers take before purchasing your products
- Identifying how many of your users continue on to each next step in your conversion flow, and how many users abandon at each step
- Optimizing critical pain points where users are abandoning, so that you can convert more users and sell more products

**NOTE: When we perform conversion funnel analysis, we will look at each step in our conversion flow to see how many customers drop off and how many continue on at each step.*

### **7. Analyzing Conversion Funnel Test**

Analyze Conversion Funnel Tests for /billing and new /billing-2 pages.

**Steps :**
- Find first time '/billing-2 was seen
- Select all pageviews for relevant session
- Aggregate and summarize the conversion rate

**Query :**

```sql
-- Find first time '/billing-2 was seen
SELECT 
	MIN(created_at) AS first_created,
	MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2'
```
![Screenshot (17)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/e62dfbb2-1118-4a39-9718-7e5078471b10)

```sql
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
```

**Result :**

![Screenshot (18)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/78b62872-c8e8-4194-9d7f-5615f6d2d37c)
  
**INSIGHTS: /billing-2 page has session to order converstion rate at 62%, much better than billing page at 46%.*














