with merchant_rev as 
(select distinct
merchant_id,
count_sales_day,
gppc_prevm,
gppc_lam,
calculated_gppc,
gppc_thm,
case 
when count_sales_day = 30 then -- sửa số ngày bán
    case
    when calculated_gppc >= 50000000 then 5
    when calculated_gppc >= 20000000 and calculated_gppc < 50000000 then 4
    when calculated_gppc >= 10000000 and calculated_gppc < 20000000 then 3 
    when calculated_gppc >= 5000000 and calculated_gppc < 10000000 then 2
    when calculated_gppc >= 2000000 and calculated_gppc < 5000000 then 1
    else 0 end
else 0
end as class,
(gppc_thm - calculated_gppc) as extra_rev

from

(SELECT --sửa ngày
o.merchant_id,
count(distinct(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-09-01' then date(from_unixtime(o.payment_time - 3600)) end)) count_sales_day,
coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-07-01'  and o.carrier_name = 'Garena'  then o.total_discount_price end)/100000,0),0) as gppc_prevm,
coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-08-01'  and o.carrier_name = 'Garena'  then o.total_discount_price end)/100000,0),0) as gppc_lam,
greatest(
    coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-07-01'  and o.carrier_name = 'Garena'  then o.total_discount_price end)/100000,0),0),
    coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-08-01'  and o.carrier_name = 'Garena' then o.total_discount_price end)/100000,0),0)
) calculated_gppc,
coalesce(round(sum(case when date_trunc('month', from_unixtime(o.payment_time - 3600)) = date '2020-09-01'  and o.carrier_name = 'Garena' then o.total_discount_price end)/100000,0),0) as gppc_thm
from shopee_vn.apc_dp_vn_db__order_tab o 
where o.status = 'Completed' and o.carrier_name <> 'Ví Việt'
group by 1 ) x
) 
select 
m.merchant_id, u.uid, mi.m_name merchant_name, mi.contact merchant_mobile, mi.address merchant_address, mi.city merchant_city,
count_sales_day,
gppc_prevm,
m.gppc_lam,
calculated_gppc,
m.gppc_thm,
m.class,
m.extra_rev,
a.id agent_id, a.name agent_name,
   CASE
       WHEN a.region = 2 THEN 'North'
       WHEN a.region = 3 THEN 'Central'
       ELSE 'South'
   END region_name,
case when m.extra_rev >= 0 then
         case m.class when 1 then 2
                     when 2 then 4
                     when 3 then 6
                     when 4 then 10
                     when 5 then 20
                     else 0
         end
    else 0
end as bonus,
min_by(real_name, staff_id) merchant_owner_name

from merchant_rev m
left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab mi on m.merchant_id = mi.id
left join airpay_vn.airpay_merchant_info_vn_db__staff_info_tab s on s.merchant_id = mi.id
left JOIN shopee_vn.apc_agent_vn_db__merchant_agent_tab ma ON m.merchant_id = ma.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__agent_tab a ON ma.agent_id = a.id 
LEFT JOIN shopee_vn_s1.apc_account_vn_db__user_tab u ON m.merchant_id = u.merchant_id
where 1=1
-- and m.extra_rev >= 1000000 and m.class <> 0
and u.role = 1 and mi.merchant_source = 60000
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16