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










