with sales as(
    select
        m.id merchant_id,
        sum(case when o.status = 'Completed' and o.carrier_name = 'Garena' and date_trunc('month', from_unixtime(o.complete_time - 3600)) = date '2020-09-01' then total_discount_price else 0 end)/100000 rev_lam,
        sum(case when o.status = 'Completed' and o.carrier_name = 'Garena' and date_trunc('month', from_unixtime(o.complete_time - 3600)) = date '2020-10-01' then total_discount_price else 0 end)/100000 rev_thm
    from
        airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m
        left join
        (select merchant_id, max_by(category, create_time) category
        from airpay_vn.airpay_merchant_info_vn_db__outlet_info_tab 
        group by 1
        ) ou on m.id = ou.merchant_id
        left join
        shopee_vn.apc_dp_vn_db__order_tab o on o.merchant_id = m.id
    where 1=1
        and m.merchant_source = 60000
        and date(from_unixtime(m.create_time - 3600)) < date '2020-10-01'
        and ou.category = 1
        and m.m_type <> 3
    group by 1
),
topup as (
    select
        t.uid,
        sum(t.amount)/100000 top_up_amt_thm
    from shopee_vn.apc_transaction_vn_db__transaction_tab t
        left join shopee_vn_s1.apc_wallet_vn_db__bank_account_tab w on t.uid = w.user_id
    where t.type in (1, 5) and t.status = 4
        and date_trunc('month', t.create_time - interval '1' hour) = date '2020-10-01'
        and w.status in (2,3)
    group by 1
)
select distinct
s.merchant_id,
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
s.rev_lam,
s.rev_thm,
coalesce(t.top_up_amt_thm, 0) top_up_amt_thm,
case
when rev_lam <= 2000000 and top_up_amt_thm >= 2000000 then least(s.rev_thm*0.5/100, 100000) else 0
end bonus
from sales s
left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on s.merchant_id = m.id
left join shopee_vn_s1.apc_account_vn_db__user_tab u on s.merchant_id = u.merchant_id
left join topup t on t.uid = u.uid
left JOIN shopee_vn.apc_agent_vn_db__merchant_agent_tab ma ON m.id = ma.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__agent_tab a ON ma.agent_id = a.id
where m.merchant_source = 60000 and u.role = 1