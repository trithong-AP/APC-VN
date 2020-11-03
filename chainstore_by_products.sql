SELECT --previous 1 day
valid_date,
chainstore_name,
coalesce(product_group, 'All_Total') product_group,
coalesce(product, 'All_Total') product,
count(distinct order_id) txn,
sum(total_discount_price) amt
FROM (
SELECT
date_format(date(from_unixtime(o.complete_time - 3600)), '%Y-%m-%d') as valid_date,
m_name chainstore_name,
CASE
    WHEN product_show_name = 'Games' then 'Game'
    WHEN category_name = 'Utilities' then 'Bill'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product_group,
CASE
    WHEN carrier_name = 'Garena' then 'Game_GPPC'
    WHEN product_show_name = 'Games' then 'Game_Other'
    WHEN product_show_name = 'Financial Services' then 'Bill_Fin'
    WHEN product_show_name = 'Electricity' then 'Bill_Electricity'
    WHEN product_show_name = 'Water' then 'Bill_Water'
    WHEN category_name = 'Utilities' then 'Bill_Other'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product,
order_id,
total_discount_price/100000 total_discount_price
FROM
shopee_vn_s1.apc_dp_vn_db__order_tab o
LEFT JOIN airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on o.merchant_id = m.id
WHERE 1=1
AND m.merchant_source = 60000 and m.m_type = 3
AND date(from_unixtime(o.complete_time - 3600)) = current_date - interval '1' day
)
GROUP BY GROUPING SETS (
    (valid_date, chainstore_name),
    (valid_date, chainstore_name, product_group),
    (valid_date, chainstore_name, product_group, product))

UNION ALL

SELECT --previous 2 days
valid_date,
chainstore_name,
coalesce(product_group, 'All_Total') product_group,
coalesce(product, 'All_Total') product,
count(distinct order_id) txn,
sum(total_discount_price) amt
FROM (
SELECT
date_format(date(from_unixtime(o.complete_time - 3600)), '%Y-%m-%d') as valid_date,
m_name chainstore_name,
CASE
    WHEN product_show_name = 'Games' then 'Game'
    WHEN category_name = 'Utilities' then 'Bill'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product_group,
CASE
    WHEN carrier_name = 'Garena' then 'Game_GPPC'
    WHEN product_show_name = 'Games' then 'Game_Other'
    WHEN product_show_name = 'Financial Services' then 'Bill_Fin'
    WHEN product_show_name = 'Electricity' then 'Bill_Electricity'
    WHEN product_show_name = 'Water' then 'Bill_Water'
    WHEN category_name = 'Utilities' then 'Bill_Other'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product,
order_id,
total_discount_price/100000 total_discount_price
FROM
shopee_vn_s1.apc_dp_vn_db__order_tab o
LEFT JOIN airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on o.merchant_id = m.id
WHERE 1=1
AND m.merchant_source = 60000 and m.m_type = 3
AND date(from_unixtime(o.complete_time - 3600)) = current_date - interval '2' day
)
GROUP BY GROUPING SETS (
    (valid_date, chainstore_name),
    (valid_date, chainstore_name, product_group),
    (valid_date, chainstore_name, product_group, product))

UNION ALL

SELECT --month to date
valid_date,
chainstore_name,
coalesce(product_group, 'All_Total') product_group,
coalesce(product, 'All_Total') product,
count(distinct order_id) txn,
sum(total_discount_price) amt
FROM (
SELECT
'month_to_date' as valid_date,
m_name chainstore_name,
CASE
    WHEN product_show_name = 'Games' then 'Game'
    WHEN category_name = 'Utilities' then 'Bill'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product_group,
CASE
    WHEN carrier_name = 'Garena' then 'Game_GPPC'
    WHEN product_show_name = 'Games' then 'Game_Other'
    WHEN product_show_name = 'Financial Services' then 'Bill_Fin'
    WHEN product_show_name = 'Electricity' then 'Bill_Electricity'
    WHEN product_show_name = 'Water' then 'Bill_Water'
    WHEN category_name = 'Utilities' then 'Bill_Other'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product,
order_id,
total_discount_price/100000 total_discount_price
FROM
shopee_vn_s1.apc_dp_vn_db__order_tab o
LEFT JOIN airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on o.merchant_id = m.id
WHERE 1=1
AND m.merchant_source = 60000 and m.m_type = 3
AND date_trunc('month', date(from_unixtime(o.complete_time - 3600))) = date_trunc('month', current_date - interval '1' day)
)
GROUP BY GROUPING SETS (
    (valid_date, chainstore_name),
    (valid_date, chainstore_name, product_group),
    (valid_date, chainstore_name, product_group, product))

UNION ALL

SELECT --last month
valid_date,
chainstore_name,
coalesce(product_group, 'All_Total') product_group,
coalesce(product, 'All_Total') product,
count(distinct order_id) txn,
sum(total_discount_price) amt
FROM (
SELECT
'last_month' as valid_date,
m_name chainstore_name,
CASE
    WHEN product_show_name = 'Games' then 'Game'
    WHEN category_name = 'Utilities' then 'Bill'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product_group,
CASE
    WHEN carrier_name = 'Garena' then 'Game_GPPC'
    WHEN product_show_name = 'Games' then 'Game_Other'
    WHEN product_show_name = 'Financial Services' then 'Bill_Fin'
    WHEN product_show_name = 'Electricity' then 'Bill_Electricity'
    WHEN product_show_name = 'Water' then 'Bill_Water'
    WHEN category_name = 'Utilities' then 'Bill_Other'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product,
order_id,
total_discount_price/100000 total_discount_price
FROM
shopee_vn_s1.apc_dp_vn_db__order_tab o
LEFT JOIN airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on o.merchant_id = m.id
WHERE 1=1
AND m.merchant_source = 60000 and m.m_type = 3
AND date_trunc('month', date(from_unixtime(o.complete_time - 3600))) = date_trunc('month', current_date - interval '1' month)
)
GROUP BY GROUPING SETS (
    (valid_date, chainstore_name),
    (valid_date, chainstore_name, product_group),
    (valid_date, chainstore_name, product_group, product))

UNION ALL

SELECT --last month to date
valid_date,
chainstore_name,
coalesce(product_group, 'All_Total') product_group,
coalesce(product, 'All_Total') product,
count(distinct order_id) txn,
sum(total_discount_price) amt
FROM (
SELECT
'last_month_to_date' as valid_date,
m_name chainstore_name,
CASE
    WHEN product_show_name = 'Games' then 'Game'
    WHEN category_name = 'Utilities' then 'Bill'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product_group,
CASE
    WHEN carrier_name = 'Garena' then 'Game_GPPC'
    WHEN product_show_name = 'Games' then 'Game_Other'
    WHEN product_show_name = 'Financial Services' then 'Bill_Fin'
    WHEN product_show_name = 'Electricity' then 'Bill_Electricity'
    WHEN product_show_name = 'Water' then 'Bill_Water'
    WHEN category_name = 'Utilities' then 'Bill_Other'
    WHEN category_name = 'Telco' then 'Telco'
    ELSE 'Others'
END product,
order_id,
total_discount_price/100000 total_discount_price
FROM
shopee_vn_s1.apc_dp_vn_db__order_tab o
LEFT JOIN airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on o.merchant_id = m.id
WHERE 1=1
AND m.merchant_source = 60000 and m.m_type = 3
AND date(from_unixtime(o.complete_time - 3600))  BETWEEN date_trunc('month', current_date - interval '1' month) AND date(current_date - interval '1' month - interval '1' day)
)
GROUP BY GROUPING SETS (
    (valid_date, chainstore_name),
    (valid_date, chainstore_name, product_group),
    (valid_date, chainstore_name, product_group, product))