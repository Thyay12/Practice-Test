#Q1:Generate monthly reports of Shopee PnL, Revenue, Cost, DAU (daily unique login users), MAU (monthly unique login users), Average Daily orders, Average Daily GMV, & G2N (Gross to Net Ratio).
#PnL, Revenue, Cost:
SELECT 
    DATE_TRUNC('month', create_datetime) AS month,
    main_category,
    SUM(gmv_usd) AS revenue,
    SUM(cogs_usd) AS cost,
    SUM(gmv_usd - cogs_usd) AS pnl
FROM 
    order_item_mart
WHERE 
    is_net_order = '1'
GROUP BY 
    month, main_category
ORDER BY 
    month, main_category;

#DAU (Daily Active Users):
SELECT 
    DATE_TRUNC('day', login_datetime) AS day,
    COUNT(DISTINCT user_id) AS dau
FROM 
    dwd_login_event
GROUP BY 
    day
ORDER BY 
    day;

#MAU (Monthly Active Users):
SELECT 
    DATE_TRUNC('month', login_datetime) AS month,
    COUNT(DISTINCT user_id) AS mau
FROM 
    dwd_login_event
GROUP BY 
    month
ORDER BY 
    month;

#Average Daily Orders:
SELECT 
    DATE_TRUNC('month', create_datetime) AS month,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT DATE(create_datetime)) AS avg_daily_orders
FROM 
    order_item_mart
WHERE 
    is_net_order = '1'
GROUP BY 
    month
ORDER BY 
    month;

#Average Daily GMV:
SELECT 
    DATE_TRUNC('month', create_datetime) AS month,
    SUM(gmv_usd) / COUNT(DISTINCT DATE(create_datetime)) AS avg_daily_gmv
FROM 
    order_item_mart
WHERE 
    is_net_order = '1'
GROUP BY 
    month
ORDER BY 
    month;

#G2N (Gross to Net Ratio):
SELECT 
    DATE_TRUNC('month', create_datetime) AS month,
    main_category,
    SUM(gmv_usd) / SUM(gmv_usd - cogs_usd) AS g2n_ratio
FROM 
    order_item_mart
WHERE 
    is_net_order = '1'
GROUP BY 
    month, main_category
ORDER BY 
    month, main_category;


#Q2:New Seller Flow (NSF) is a program to incubate new sellers to sell on Shopee. Each batch include 200-300 new sellers and will be incubated for 1 month.
Generate a cohort analysis since their first join in the program to see the growth in Orders and GMV over time from each batch on a monthly basis.

 SELECT
    batch,
    DATE_TRUNC('month', create_datetime) AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(gmv_usd) AS total_gmv
FROM 
    order_item_mart AS oi
JOIN 
    nsf_batch_seller AS ns ON oi.shop_id = ns.shop_id
GROUP BY 
    batch, month
ORDER BY 
    batch, month;

#Q3: Find out top 10 items by orders per earch seller segment by month, together with average selling price/item, min price, max price, and orders and GMV coverage

WITH AVG_Daily_Orders AS (
    SELECT
          shop_id,
          COUNT(DISTINCT order_id)/COUNT(DISTINCT DATE(create_datetime)) AS avg_daily_orders
    FROM 
          order_item_mart
    GROUP BY 
          shop_id;)
, Seller_segment AS(
    SELECT
         shop_id,
         CASE WHEN avg_daily_orders > 20 THEN "Short Tail"
              WHEN avg_daily_orders BETWEEN 10 AND 20 THEN "Mid Tail"
              ELSE "Long Tail"
         END AS seller_segment
    FROM 
        AVG_Daily_Orders;)

SELECT
    ss.seller_segment,
    DATE_TRUNC('month', oi.create_datetime) AS month,
    oi.item_id,
    AVG(oi.gmv_usd/oi.item_amount) AS avg_selling_price,
    MIN(oi.gmv_usd/oi.item_amount) AS min_selling_price,
    MAX(oi.gmv_usd/oi.item_amount) AS max_selling_price,
    COUNT(oi.order_id) AS total_order,
    SUM(oi.gmv_usd) AS GMV
FROM
    order_item_mart AS oi
JOIN 
    seller_segment AS ss ON oi.shop_id = ss.shop_id
WHERE
    is_net_order = "1"
GROUP BY
    ss.seller_segment, month, oi.item_id
ORDER BY
    ss.seller_segment, month, total_order DESC
LIMIT 10;
    

--Q4 Segment platform orders, GMV of platform by buyers segment
WITH RFM_Calculation AS (
    SELECT 
        buyer_id,
        DATEDIFF('day', MAX(create_datetime), '2024-08-01') AS recency,  -- Days since last purchase
        COUNT(DISTINCT order_id) AS frequency,  -- Number of unique orders
        SUM(gmv_usd) AS monetary  -- Total GMV in USD
    FROM 
        order_item_mart
    WHERE 
        is_net_order = '1'
    GROUP BY 
        buyer_id
)
, RFM_Scored AS (
    SELECT 
        buyer_id,
        NTILE(5) OVER (ORDER BY recency ASC) AS recency_score, 
        NTILE(5) OVER (ORDER BY frequency DESC) AS frequency_score,  
        NTILE(5) OVER (ORDER BY monetary DESC) AS monetary_score  
    FROM 
        RFM_Calculation
)
, BuyerSegments AS (
    SELECT 
        buyer_id,
        recency_score,
        frequency_score,
        monetary_score,
        CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score,
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Top Buyers'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Buyers'
            WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'At-Risk Buyers'
            ELSE 'Other'
        END AS buyer_segment
    FROM 
        RFM_Scored
)
SELECT 
    buyer_segment,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(gmv_usd) AS total_gmv,
    AVG(gmv_usd) AS avg_order_value
FROM 
    order_item_mart oi
JOIN 
    BuyerSegments bs ON oi.buyer_id = bs.buyer_id
WHERE 
    oi.is_net_order = '1'
GROUP BY 
    buyer_segment
ORDER BY 
    total_gmv DESC;


-Q5 Calculate the actual monthly revenue gained from that seller program
WITH Revenue_Calculated AS (
    SELECT 
        DATE_TRUNC('month', create_datetime) AS month,
        item_id,
        model_id,
        LEAST(cogs_usd * 0.07, 20000) AS revenue_before_vat,
        LEAST(cogs_usd * 0.07, 20000) * 0.90 AS actual_revenue
    FROM 
        order_item_mart
    WHERE 
        is_net_order = '1'
)
SELECT 
    month,
    SUM(actual_revenue) AS total_revenue
FROM 
    Revenue_Calculated
GROUP BY 
    month
ORDER BY 
    month;

--Q6 Calculate the average lead-time from when buyer placed an order till the order is completed or cancelled. Segment the lead-time bucket and find out the time bucket when buyers cancel the most. 
WITH Lead_Time_Calculated AS (
    SELECT 
        order_id,
        buyer_id,
        DATE_TRUNC('day', create_datetime) AS order_date,
        DATE_TRUNC('day', complete_datetime) AS complete_date,
        DATE_TRUNC('day', cancel_datetime) AS cancel_date,
        CASE
            WHEN complete_datetime IS NOT NULL THEN DATE_PART('day', complete_datetime - create_datetime)
            WHEN cancel_datetime IS NOT NULL THEN DATE_PART('day', cancel_datetime - create_datetime)
        END AS lead_time
    FROM 
        order_item_mart
)
, Lead_Time_Buckets AS (
    SELECT 
        order_id,
        buyer_id,
        lead_time,
        CASE
            WHEN lead_time <= 1 THEN '0-1 days'
            WHEN lead_time BETWEEN 2 AND 7 THEN '2-7 days'
            WHEN lead_time BETWEEN 8 AND 14 THEN '8-14 days'
            ELSE '14+ days'
        END AS lead_time_bucket
    FROM 
        Lead_Time_Calculated
)
SELECT 
    lead_time_bucket,
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN cancel_date IS NOT NULL THEN 1 END) AS canceled_orders,
    ROUND((COUNT(CASE WHEN cancel_datetime IS NOT NULL THEN 1 END) / COUNT(order_id)) * 100, 2) AS cancel_rate
FROM 
    Lead_Time_Buckets
GROUP BY 
    lead_time_bucket
ORDER BY 
    lead_time_bucket;







