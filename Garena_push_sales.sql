with tb1 as
(select distinct
merchant_id,
gppc_prevm,
gppc_lam,
calculated_gppc,
gppc_thm,
case when calculated_gppc >= 50000000 then 4
when calculated_gppc >= 20000000 and calculated_gppc < 50000000 then 3
when calculated_gppc >= 10000000 and calculated_gppc < 20000000 then 2
when calculated_gppc >= 5000000 and calculated_gppc < 10000000 then 1
-- when calculated_gppc >= 2000000 and calculated_gppc < 5000000 then 1
else 0 end as class,
gppc_thm - calculated_gppc extra_rev
from
(SELECT
o.merchant_id,
coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-07-01' then o.total_discount_price end)/100000,0),0) as gppc_prevm,
coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-08-01' then o.total_discount_price end)/100000,0),0) as gppc_lam,
greatest(
   coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-07-01' then o.total_discount_price end)/100000,0),0),
   coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-08-01' then o.total_discount_price end)/100000,0),0)
) calculated_gppc,
coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-09-01' then o.total_discount_price end)/100000,0),0) as gppc_thm
from shopee_vn.apc_dp_vn_db__order_tab o
where o.status = 'Completed' and o.carrier_name = 'Garena'
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
ma.agent_id,
a.name agent_name,
tb1.gppc_prevm,
tb1.gppc_lam,
tb1.calculated_gppc,
tb1.gppc_thm,
extra_rev,
class,
case
when tb1.class = 1 and extra_rev >= 5000000 then 1
when tb1.class = 2 and extra_rev >= 10000000 then 2
when tb1.class = 3 and extra_rev >= 20000000 then 3
when tb1.class = 4 and extra_rev >= 50000000 then 5
else 0
end bonus
from tb1
left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on tb1.merchant_id = m.id
left join shopee_vn_s1.apc_account_vn_db__user_tab u on tb1.merchant_id = u.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__merchant_agent_tab ma ON m.id = ma.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__agent_tab a ON ma.agent_id = a.id
left join (select merchant_id, max_by(category, create_time) category from airpay_vn.airpay_merchant_info_vn_db__outlet_info_tab group by 1) ou on ou.merchant_id = m.id
where m.merchant_source = 60000 and u.role = 1 
and ou.category = 1