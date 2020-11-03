--assume this is calculated on month n, thm is the previous month, lam is the previous month of month thm
With
sales as (
    select
    o.merchant_id,
    
    coalesce(round(sum(case when date_trunc('month', from_unixtime(o.complete_time - 3600)) = date_trunc('month', current_date - interval '3' month) then o.total_discount_price else 0 end)/100000,0),0) as sales_prevm,
    coalesce(round(sum(case when date_trunc('month', from_unixtime(o.complete_time - 3600)) = date_trunc('month', current_date - interval '2' month) then o.total_discount_price else 0 end)/100000,0),0) as sales_lam,
    coalesce(round(sum(case when date_trunc('month', from_unixtime(o.complete_time - 3600)) = date_trunc('month', current_date - interval '1' month) then o.total_discount_price else 0 end)/100000,0),0) as sales_thm
    from shopee_vn_s1.apc_dp_vn_db__order_tab o
    where 1=1
    and o.status = 'Completed' and o.category_name not in ('E-wallet')
    group by 1
),
topup_giro as (
    select
    u.merchant_id,
    round(sum(case when date_trunc('month', t.create_time - interval '1' hour) = date_trunc('month', current_date - interval '3' month) then t.amount else 0 end)/100000, 0) as giro_amt_prevm,
    round(sum(case when date_trunc('month', t.create_time - interval '1' hour) = date_trunc('month', current_date - interval '2' month) then t.amount else 0 end)/100000, 0) as giro_amt_lam,
    round(sum(case when date_trunc('month', t.create_time - interval '1' hour) = date_trunc('month', current_date - interval '1' month) then t.amount else 0 end)/100000, 0) as giro_amt_thm
    from shopee_vn.apc_transaction_vn_db__transaction_tab t
    left join (select user_id, min(date(from_unixtime(create_time - 3600))) first_GIRO_link_date from shopee_vn_s1.apc_wallet_vn_db__bank_account_tab group by 1) w on t.uid = w.user_id
    left join shopee_vn_s1.apc_account_vn_db__user_tab u on t.to_uid = u.uid
    where u.role = 1
    and t.type = 1 and t.status = 4 and t.topup_channel = 1
    and first_GIRO_link_date < date '2020-10-01'
    group by 1
),
calculated_sales as (
    select
    coalesce(sales.merchant_id, topup_giro.merchant_id) merchant_id,
    sales_prevm,
    giro_amt_prevm,
    sales_lam,
    giro_amt_lam,
    greatest(least(sales_lam, giro_amt_lam), least(sales_prevm, giro_amt_prevm)) calculated_sales_history,
    least(sales_thm, giro_amt_thm) calculated_sales_thm,
    sales_thm,
    giro_amt_thm,
    least(sales_thm, giro_amt_thm) - greatest(least(sales_lam, giro_amt_lam), least(sales_prevm, giro_amt_prevm)) as delta
    from sales
    join topup_giro on sales.merchant_id = topup_giro.merchant_id 
)
select distinct
cs.merchant_id,
u.uid,
m.m_name merchant_name,
u.phone merchant_phone,
m.address merhant_address,
m.city merchant_city,
sales_prevm,
giro_amt_prevm,
sales_lam,
giro_amt_lam,
calculated_sales_history,
sales_thm,
giro_amt_thm,
calculated_sales_thm,
delta,
CASE
   WHEN a.region = 2 THEN 'North'
   WHEN a.region = 3 THEN 'Central'
   ELSE 'South'
END region_name,
case
    when calculated_sales_history >= 50000000 then least(floor(greatest(delta, 0)/50000000) * 200000, 200000)
    when calculated_sales_history >= 20000000 and calculated_sales_history < 50000000 then least(floor(greatest(delta, 0)/30000000) * 100000, 100000)
    when calculated_sales_history >= 5000000 and calculated_sales_history < 20000000 then least(floor(greatest(delta, 0)/10000000) * 50000, 100000)    
    else 0
end bonus
from calculated_sales cs
left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on cs.merchant_id = m.id
left join shopee_vn_s1.apc_account_vn_db__user_tab u on cs.merchant_id = u.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__merchant_agent_tab ma ON cs.merchant_id = ma.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__agent_tab a ON ma.agent_id = a.id
where m.merchant_source = 60000 and u.role = 1