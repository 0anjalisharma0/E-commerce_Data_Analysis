

##  **Analysis for Channel Management**
###  **Business Concept: Channel Portofolio Optimization**
Analyzing a portfolio of marketing channels is about **bidding efficiently and using data to maximize the effectiveness of your marketing budget.**

### **Applications of Channel Portofolio Optimization**
- Understanding which marketing channels are driving the most sessions and orders through website
- Understanding differences in user characteristics and conversion performance across marketing channels
- Optimizing bids and allocating marketing spend across a multi-channel portfolio to achieve maximum performance

### **Task**
### **1. Analyzing Channel Portofolios**
**Channel Portofolio Analysis** : to identify traffic coming from multiple marketing channels, we will use utm parameters stored in our sessions table


**Steps :**
- Pull weekly sessions from 22 Aug - 29 Nov for gsearch and bsearch, utm campaign nonbrand

**Query :**
```sql
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
```

**Result :**
![Screenshot (19)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/a3840497-3c05-4bd5-8530-2dbae38ba4ff)

### **2. Comparing Channel Characteristics**

**Steps :**
- Pull mobile session from 22 Aug - 30 Nov for gsearch and bsearch, utm campaign nonbrand

**Query :**
```sql
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
```
**Result :**

![Screenshot (20)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/b237eae7-14d1-4fdb-889e-f7861946618a)

### **3. Cross-Channel Bid Optimization**
**Steps :**
- Based on device type, pull gsearch and bsearch nonbrand conversion rates (order/session) from 22 Aug - 18 Sep

**Query :**
```sql
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
```

**Result :**
![Screenshot (21)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/f00b8fbb-1ac4-4854-b012-d7dd3b5c5a5d)

### **4. Channel Portofolio Trends**

**Steps :**
- Pull weekly sessions gsearch and bsearch nonbrand sessions by device type from 4 Nov - 22 Dec

**Query :**
```sql
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
```
**Result :**
![Screenshot (22)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/2e35a0f9-a2e9-4e76-89b4-6efc330b8d70)

  4 — The desktop bsearch sessions stayed at 40% of gsearch sessions but dropped after bids were lowered in weeks 2-3 of December. This drop could also be influenced by events like Black Friday, Cyber Monday, and other seasonal factors. For mobile sessions, there was a significant decline after bid reduction, but it varied during December, making it difficult to determine if the decline was solely due to reduced bids or other factors too.

### ** Analyzing Direct Traffic**
Analyzing your branded or direct traffic is about **keeping a pulse on how well your brand is doing with consumers, and how well your brand drives business.**

### 📌 **Applications of Direct Traffic Analysis **
- Identifying how much revenue is generating from direct traffic – this is high  margin revenue without a direct cost of customer acquisition
- Understanding whether or not  paid traffic is generating a “halo” effect, and promoting additional direct traffic
- Assessing the impact of various initiatives on  how many customers seek out the business

### **5. Analyzing Free Channels**
**Free Traffic Analysis** : to identify traffic coming to the website which is not being paid for  marketing campaigns (use utm params).

**Steps :**
- Analyze organic search, direct type in, and paid brand or nonbrand sessions
- Pull monthly organic search, direct type in, and paid brand sessions, present in % of paid nonbrand.


**Query :**
```sql
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
WHERE created_at < '2012-12-23'

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
GROUP BY MONTH(created_at)
```
<br>

**Result :**

![Screenshot (23)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/5bbbd511-d166-43ab-be25-f3465d7cb64d)

**INSIGHTS: They are growing as a percentage of paid traffic volume*

##  **Business Patterns & Seasonality**
###  ** Analyzing Seasonality & Business Patterns**
Analyzing business patterns is about **generating insights to help you maximize efficiency and anticipate future trends.**


### 📌 **Common Use Cases: Analyzing Seasonality & Business Patterns**
- Day-parting analysis to understand how much support staff you should have at different times of day or days of the week
- Analyzing seasonality to better prepare for upcoming spikes or slowdowns in demand
### **Task**
### *6. Analyzing Seasonality**

**Steps :**
- Pull monthly and weekly orders and sessions in 2012

**Query :**
```sql
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
```
<br>

**Result :**
![Screenshot (24)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/d552beb8-9b0c-496b-8bc1-b8acd9df2a68)

**Query :**
```sql
-- weekly seasons
SELECT
    MIN(DATE(w.created_at)) AS week_start_date,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
    ROUND(100*(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id)),2) AS cvr
FROM website_sessions w
    LEFT JOIN orders o
        ON w.website_session_id = o.website_session_id
WHERE w.created_at < '2013-01-01'
GROUP BY WEEK(w.created_at);
```

**Result :**
![Screenshot (25)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/dbb74313-7ef3-4fbb-9735-49fd426a9aba)

### **7. Analyzing Business Patterns**

**Steps :**
- Pull sessions beside hour and day of the week in 15 Sep - 15 Nov 2012

**Query :**
```sql
WITH time_session_cte AS(
SELECT
    DATE(created_at) AS dt,
    WEEKDAY(created_at) AS wk,
    HOUR(created_at) AS hr,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2,3)

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
```

**Result :**
![Screenshot (27)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/7f9eec85-4045-4c67-96a3-9772f0b04c5c)

**INSIGHTS: Plan on one support staff around the clock and then we should double up to two staff members from 8 am to 8 pm Monday through Friday*



