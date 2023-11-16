
##**Product Sales Analysis**

Analyzing product sales help you understand how each product contributes to business and how product launches impact the overall portfolio

# Application:
- Analyzing sales and revenue by product
- Monitoring the impact of adding a new product to product portfolio
- Watching product sales trend to understand the overall health of your business

# **KEY BUSINESS TERMS**
- Order = Number of orders placed
- Revenue = Money the business brings in from orders
- Margin = Revenue less the cost of goods sold
- AOV(average order value) = Average revenue generated per order

### **Task**
### **1. Finding sales trend**
**Query :**
```sql 
USE mavenfuzzyfactory;
SELECT
YEAR(created_at) AS yr,
MONTH(created_at) AS mon,
COUNT(DISTINCT order_id) AS num_of_sales,
SUM(price_usd) AS revenue,
SUM(price_usd - cogs_usd) AS total_margin

FROM orders
WHERE created_at < '2013-04-01'
GROUP BY 1,2
```
**Result :**

![Screenshot (28)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/b1249166-deec-41ce-8486-fcce75d04140)

## **Product Level Website Analysis**
Product focused website analysis is about learning how customers interact with each of your product and how well each product converts customer.

## **Applications:
- Understanding which of your product generate the most interest on multi-product showcase page
- Analysing the impact on website conversion rates when a new product is launched
- Building product-specific conversion funnels to understand whether certain products convert better than others

### **Task**
### **2.Finding the Impact of new product launch**
**Query :**
```sql 
SELECT
YEAR(w.created_at) AS yr,
MONTH(w.created_at) AS mon,
COUNT(DISTINCT w.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT w.website_session_id) AS cnvr_rate,
SUM(orders.price_usd)/COUNT(DISTINCT w.website_session_id) AS revenue_per_session,
COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_order,
COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_order

FROM website_sessions w
LEFT JOIN orders
ON w.website_session_id = orders.website_session_id
WHERE w.created_at < '2013-04-01'
AND w.created_at > '2012-04-01'
GROUP BY 1,2
```
**Result :**

![Screenshot (29)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/7a4c541a-9c57-451f-94b4-7f3ef4903d23)


### **Task**
### **3). Product Pathing Analysis**
**Query :**
```sql
-- Step 1- Finding the relevant /pageviews we care about
CREATE TEMPORARY TABLE products_pageview 
 -- USE mavenfuzzyfactory;
SELECT 
website_session_id,
website_pageview_id,
created_at,
CASE
   WHEN created_at < '2013-01-06' THEN 'A.Pre_product_2'
   WHEN created_at >= '2013-01-06' THEN 'B.Post_product_2'
   ELSE NULL
   END AS time_period
FROM website_pageviews
WHERE created_at <'2013-04-06' -- date of request
AND created_at > '2012-10-06' -- start of 3 months before product_2 launch
AND pageview_url = '/products';
```
![Screenshot (30)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/22002332-d455-4fca-82cf-07e851facdaa)


```sql
-- step 2 - Find the next pageview_id occurs after the product pageview
CREATE TEMPORARY TABLE session_next_pageview_id
   SELECT
   products_pageview.time_period,
   products_pageview.website_session_id,
   MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
   FROM products_pageview
   LEFT JOIN website_pageviews
   ON website_pageviews.website_session_id = products_pageview.website_session_id
   AND website_pageviews.website_pageview_id > products_pageview.website_pageview_id
   GROUP BY 1,2;
 ```
  
![Screenshot (31)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/aed2f2e1-be57-4c65-b75f-dd65ead0f216)

```sql  
-- step 3 - Fin the pageview url with any applicable next pageview_id
CREATE TEMPORARY TABLE session_w_next_pageview_url
SELECT
session_next_pageview_id.time_period,
session_next_pageview_id.website_session_id,
website_pageviews.pageview_url AS next_pageview_url

FROM session_next_pageview_id
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id  = session_next_pageview_id. min_next_pageview_id;
```

![Screenshot (32)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/54d1c104-4556-4ad7-baa3-b9d1231afbd7)


```sql  
-- step 4 - Summarize the data and analyse the pre v/s post period

SELECT
time_period,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_page,
COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
 COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) /COUNT(DISTINCT website_session_id) AS pct_to_bear

FROM session_w_next_pageview_url
GROUP BY 1
```
**Result :**

![Screenshot (33)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/47abe6e2-19ed-41d1-a078-31e5a4558c55)

## ** CROSS-SELLING PRODUCT ANALYSIS**
cROSS sell analysis is about to underatand which products are most likly to be purchased together and thus offering smart product recommendations.

## **Applications:**
- Understanding which products are often purchase together
- Testing and optimising the ways you cross-sell products on your website
- Understanding the conversion rate impact & the overall revenue impact of trying to cross-sell additional products 
**NOTE: Anlayse order and order_items data to understand which products cross_sell and their impact on revenue


### **Task**
### **4). CROSS SELLING PRODUCTS PERFORMANCE**

**Query :**
```sql

-- Compare the performance of selling products before and after launch of cross selling products on the website
-- step 1 - Identify the relevant /cart pageview and their sessions
-- step2 - See which of those /cart sessions click through to the shipping page
-- step3 - Find the orders associated with the /cart sessions and calculate average order value,AOV
-- step4 - Aggregate and anlayse the summary of your findings
USE mavenfuzzyfactory;
CREATE TEMPORARY TABLE session_seeing_cart
SELECT
CASE
    WHEN created_at < '2013-09-25' THEN 'A_pre_cross_sell'
	WHEN created_at >= '2013-01-11' THEN 'B_post_cross_sell'
     ELSE null
     END AS time_period,
website_session_id AS cart_page_id,
Website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND pageview_url = '/cart';

-- step2 - See which of those /cart sessions click through to the shipping page 
CREATE TEMPORARY TABLE session_seeing_cart_another_page
SELECT
session_seeing_cart.time_period,
session_seeing_cart.cart_page_id,
MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM session_seeing_cart
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = session_seeing_cart.cart_page_id
AND website_pageviews.website_pageview_id  > session_seeing_cart.cart_pageview_id

GROUP BY 1,2
HAVING 
MIN(website_pageviews.website_pageview_id) IS NOT NULL;

-- step3 - Find the orders associated with the /cart sessions and calculate average order value,AOV
CREATE TEMPORARY TABLE pre_post_session_order
SELECT
time_period,
cart_page_id,
order_id,
price_usd,
items_purchased
FROM session_seeing_cart
INNER JOIN orders
ON orders.website_session_id = session_seeing_cart.cart_page_id;

-- step4 - Aggregate and anlayse the summary of your findings
SELECT
time_period,
COUNT(DISTINCT cart_page_id) AS cart_sessions,
SUM(clicked_to_another_page) AS click_through,
SUM(clicked_to_another_page)/COUNT(DISTINCT cart_page_id) AS cart_ctr,
SUM(placed_order) AS orders_placed,
SUM(items_purchased) AS product_purchased,
SUM(items_purchased)/SUM(placed_order) AS prod_per_order,
SUM(price_usd) AS revenue,
SUM(price_usd)/SUM(placed_order) AS aov,
SUM(price_usd)/COUNT(DISTINCT cart_page_id) AS rev_per_cart_session
FROM(
SELECT
 session_seeing_cart.time_period,
 session_seeing_cart.cart_page_id,
 CASE WHEN session_seeing_cart_another_page.cart_page_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
 CASE WHEN pre_post_session_order.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
 pre_post_session_order.price_usd,
 pre_post_session_order.items_purchased
FROM  session_seeing_cart
LEFT JOIN session_seeing_cart_another_page
ON session_seeing_cart.cart_page_id = session_seeing_cart_another_page.cart_page_id
LEFT JOIN pre_post_session_order
ON session_seeing_cart.cart_page_id = pre_post_session_order.cart_page_id

ORDER BY 
cart_page_id
) AS full_data
GROUP BY time_period;
```
**Result :**

![Screenshot (39)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/439750a0-6d25-4154-b453-31b4918107e9)


### **Task**
### **5). Portfolio expansion Analysis (Recent product launch)**
**Query :**
```sql

SELECT
CASE
    WHEN website_sessions.created_at < '2013-12-12' THEN 'A_pre_bear'
	WHEN website_sessions.created_at >= '2013-12-12' THEN 'B_post_bear'
     ELSE null
     END AS time_period,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
SUM(orders.price_usd) AS total_revenue,
SUM(orders.items_purchased) AS total_prod_sold,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS av_order_value,
SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS prod_per_order,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session

FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id

WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1 ;
```
**Result :**

![Screenshot (34)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/d26d8d54-e19e-4598-bfbd-b6af9c1a1ae9)


## ** PRODUCT REFUND ANALYSIS**
Analysing product refund sales is about controlling for quality and underatnding the problem areas

## **APPLICATIONS:**
- Monitoring product from different suppliers
- understanding refund rates for product at different price 

### **Task**
### **6).Product refund analysis (quality issues and refund)**
**Query :**
```sql

SELECT 
YEAR(order_items.created_at) AS yr,
MONTH(order_items.created_at) AS mo,
COUNT(DISTINCT CASE WHEN product_id=1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
COUNT(DISTINCT CASE WHEN product_id=1 THEN order_item_refunds.order_item_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_id=1 THEN order_items.order_item_id ELSE NULL END) AS p1_refund_rate,
COUNT(DISTINCT CASE WHEN product_id=2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
COUNT(DISTINCT CASE WHEN product_id=2 THEN order_item_refunds.order_item_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_id=2 THEN order_items.order_item_id ELSE NULL END) AS p2_refund_rate

FROM order_items
LEFT JOIN order_item_refunds
ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2
```
**Result :**

![Screenshot (35)](https://github.com/anjali971611/E-commerce_Data_Analysis/assets/150220050/53c64875-767f-4bd3-9c05-502ad3b5a8b5)











