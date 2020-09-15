with first_topup as 
    (
        select
        t.uid,
        min_by(t.amount/100000, t.txn_id) first_topup_amt
        from shopee_vn.apc_transaction_vn_db__transaction_tab t
        left join shopee_vn_s1.apc_wallet_vn_db__bank_account_tab w on t.uid = w.user_id
        where t.type = 1 and t.status = 4
        and t.topup_channel = 1
        and t.bank_id not in (5,8)
        and date_trunc('month', t.create_time - interval '1' hour) = date '2020-09-01'
        and w.status in (2) 
        and date_trunc('month', from_unixtime(w.create_time - 3600)) = date '2020-09-01'
        -- and t.uid = 300041744
        group by 1
    ),
first_date_topup as
    (
        select
        t.uid,
        sum(case when date(t.create_time - interval '1' hour) = first_topup_date then t.amount/100000 end) first_topup_amt
        from shopee_vn.apc_transaction_vn_db__transaction_tab t
        left join (select uid, min(date(create_time - interval '1' hour)) first_topup_date 
                from shopee_vn.apc_transaction_vn_db__transaction_tab
                where type = 1 and status = 4 and topup_channel = 1 and bank_id in (5, 8)
                and date_trunc('month', create_time - interval '1' hour) = date '2020-09-01'
                group by 1) t1 on t.uid = t1.uid
        left join shopee_vn_s1.apc_wallet_vn_db__bank_account_tab w on t.uid = w.user_id
        where t.type = 1 and t.status = 4
        and t.topup_channel = 1
        and t.bank_id in (5,8)
        and date_trunc('month', t.create_time - interval '1' hour) = date '2020-09-01'
        and w.status in (2) 
        and date_trunc('month', from_unixtime(w.create_time - 3600)) = date '2020-09-01'
        -- and t.uid = 300041744
        group by 1
    )

select distinct
u.merchant_id,
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
coalesce(fd.first_topup_amt, f.first_topup_amt) first_topup_amt,
case when coalesce(fd.first_topup_amt, f.first_topup_amt) >= 5000000 then 200000
     when coalesce(fd.first_topup_amt, f.first_topup_amt) >= 2000000 then 100000
     else 0
end bonus
from first_topup f
full join first_date_topup fd on f.uid = fd.uid
left join shopee_vn_s1.apc_account_vn_db__user_tab u on coalesce(f.uid, fd.uid) = u.uid
left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on u.merchant_id = m.id
left JOIN shopee_vn.apc_agent_vn_db__merchant_agent_tab ma ON m.id = ma.merchant_id
left JOIN shopee_vn.apc_agent_vn_db__agent_tab a ON ma.agent_id = a.id
left join (select merchant_id, max_by(category, create_time) category from airpay_vn.airpay_merchant_info_vn_db__outlet_info_tab group by 1) ou on ou.merchant_id = u.merchant_id
where 1=1
-- and u.merchant_id in (300041744)
and u.role = 1 and merchant_source = 60000
and ou.category <> 6