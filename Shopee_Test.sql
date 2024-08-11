#Q1:Generate monthly reports of Shopee PnL, Revenue, Cost, DAU (daily unique login users), MAU (monthly unique login users), Average Daily orders, Average Daily GMV, & G2N (Gross to Net Ratio).
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


