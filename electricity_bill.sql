with data as (
    select
    merchant_id,
    count(distinct o.order_id) count_order
    from
    shopee_vn_s1.apc_dp_vn_db__order_tab o
    left join
    shopee_vn.apc_dp_vn_db__refund_tab r on o.order_id = r.order_id
    where 1=1
    and r.order_id is null --loai don hang refund
    and date_trunc('month', from_unixtime(o.payment_time) - interval '1' hour) = date '2020-09-01'
    and lower(o.product_show_name) in ('electricity')
    and total_discount_price/100000 >= 20000
    and o.status = 'Completed'
    group by 1
)
select distinct
d.merchant_id,
u.uid,
m.m_name merchant_name,
u.phone merchant_phone,
m.address merhant_address,
m.city merchant_city,
CASE
   WHEN a.region = 2 THEN 'North'
   WHEN a.region = 3 THEN 'Central'
   ELSE 'South'
END region_name,
count_order,
case when m.city in ('TP Hồ Chí Minh','Hà Nội','Hà Tây') then least(floor(count_order/30)*75000, 1500000)
     else least(floor(count_order/30)*60000, 1000000) end bonus
from data d
left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on d.merchant_id = m.id
left join shopee_vn_s1.apc_account_vn_db__user_tab u on d.merchant_id = u.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__merchant_agent_tab ma ON m.id = ma.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__agent_tab a ON ma.agent_id = a.id
where d.merchant_id not in (2000005,2000006,2000015,2000014,2016945,2013241,2000017,2014288,2020316,2000008,2000004)
and u.role = 1 and m.merchant_source = 60000