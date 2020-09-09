with tb1 as
(select distinct
merchant_id,
bill_prevm,
bill_lam,
calculated_bill,
bill_thm,

case 
-- when calculated_bill >= 30 then 4 
when calculated_bill > 20 and calculated_bill < 30 then 3
when calculated_bill > 10 and calculated_bill <= 20 then 2 
when calculated_bill >= 1 and calculated_bill <= 10 then 1
else 0 end as class
from
(SELECT
o.merchant_id,
coalesce(count(distinct case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-06-01' then o.order_id end), 0) as bill_prevm,
coalesce(count(distinct case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-07-01' then o.order_id end), 0) as bill_lam,
greatest(
    coalesce(count(distinct case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-06-01' then o.order_id end), 0),
    coalesce(count(distinct case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-07-01' then o.order_id end), 0)) calculated_bill,
coalesce(count(distinct case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-08-01' then o.order_id end), 0) as bill_thm
from shopee_vn.apc_dp_vn_db__order_tab o
where o.status = 'Completed' and o.category_name = 'Utilities' and total_discount_price/100000 >= 20000
group by 1) x
)

select distinct
tb1.merchant_id,
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
tb1.bill_prevm,
tb1.bill_lam,
tb1.calculated_bill,
tb1.bill_thm,
class,
case
when tb1.class = 1 then least(floor(greatest(tb1.bill_thm - tb1.calculated_bill, 0)/5)*10000, 20000)
when tb1.class = 2 then least(floor(greatest(tb1.bill_thm - tb1.calculated_bill, 0)/10)*20000, 40000)
when tb1.class = 3 then least(floor(greatest(tb1.bill_thm - tb1.calculated_bill, 0)/20)*40000, 80000)
-- else least(floor(greatest(tb1.bill_thm - tb1.calculated_bill,0)/30)*40000, 80000) 
else 0
end as bonus

from tb1
left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on tb1.merchant_id = m.id
left join shopee_vn_s1.apc_account_vn_db__user_tab u on tb1.merchant_id = u.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__merchant_agent_tab ma ON m.id = ma.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__agent_tab a ON ma.agent_id = a.id
where m.merchant_source = 60000 and u.role = 1
--test change