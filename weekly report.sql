with
select_date as (
    select distinct
        date(from_unixtime(payment_time)) as valid_date
    from
        shopee_vn_s1.apc_dp_vn_db__order_tab
    where 1=1
        and date(from_unixtime(payment_time)) between date_trunc('month', current_date - interval '2' month) and current_date - interval '1' day
        -- and date(from_unixtime(payment_time)) = date '2020-09-14'
),
non_chainstore as (
    with
    order_related as (
        select
            valid_date,
            count(case when o.status = 'Completed' then o.order_id end) as txn,
            round(sum(case when o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as gross_gtv,
            count(case when o.category_name = 'Voucher' and o.carrier_name = 'Garena' and o.status = 'Completed' then o.order_id end) as gppc_txn,
            0 as gppc_chainstore_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' then o.order_id end) as fin_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name = 'Home Credit' then o.order_id end) as home_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name = 'FE Credit' then o.order_id end) as fe_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name in ('ACS Credit','OCB Credit') then o.order_id end) as acs_ocb_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name not in ('Home Credit','FE Credit','ACS Credit','OCB Credit') then o.order_id end) as otherfin_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name = 'Electricity' and o.status = 'Completed' then o.order_id end) as elec_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name = 'Water' and o.status = 'Completed' then o.order_id end) as water_txn,
            count(case when o.category_name = 'Utilities' and o.product_show_name in ('Telco Postpaid','Internet') and o.status = 'Completed' then o.order_id end) as otherbills_txn,
            count(case when o.category_name = 'Telco' and o.status = 'Completed' then o.order_id end) as telco_txn,
            count(case when o.category_name = 'Telco' and o.carrier_name = 'Mobifone' and o.status = 'Completed' then o.order_id end) as mobi_txn,
            count(case when o.category_name = 'Telco' and o.carrier_name = 'Vinaphone' and o.status = 'Completed' then o.order_id end) as vina_txn,
            count(case when o.category_name = 'Telco' and o.carrier_name = 'Viettel' and o.status = 'Completed' then o.order_id end) as viettel_txn,
            count(case when o.category_name = 'Telco' and o.carrier_name not in ('Vinaphone','Mobifone','Viettel') and o.status = 'Completed' then o.order_id end) as othertelco_txn,
            count(case when o.category_name = 'Voucher' and o.carrier_name not in ('Garena') and o.status = 'Completed' then o.order_id end) as othergames_txn,
            count(case when o.category_name = 'E-wallet' and o.carrier_name in ('Ví Việt') and o.status = 'Completed' then o.order_id end) as ViViet_txn,
            count(case when o.category_name = 'Printer' and o.status = 'Completed' then o.order_id end) as otherproducts_txn,

            round(sum(case when o.category_name = 'Voucher' and o.carrier_name = 'Garena' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as gppc_gtv,
            0 as chainstore_gppc_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as fin_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name = 'Home Credit' then o.total_discount_price end)/100000/23000,0) as home_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name = 'FE Credit' then o.total_discount_price end)/100000/23000,0) as fe_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name in ('ACS Credit','OCB Credit') then o.total_discount_price end)/100000/23000,0) as acs_ocb_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name = 'Financial Services' and o.status = 'Completed' and o.carrier_name not in ('Home Credit','FE Credit','ACS Credit','OCB Credit') then o.total_discount_price end)/100000/23000,0) as otherfin_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name = 'Electricity' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as elec_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name = 'Water' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as water_gtv,
            round(sum(case when o.category_name = 'Utilities' and o.product_show_name in ('Telco Postpaid','Internet') and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as otherbills_gtv,
            round(sum(case when o.category_name = 'Telco' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as telco_gtv,
            round(sum(case when o.category_name = 'Telco' and o.carrier_name = 'Mobifone' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as mobi_gtv,
            round(sum(case when o.category_name = 'Telco' and o.carrier_name = 'Vinaphone' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as vina_gtv,
            round(sum(case when o.category_name = 'Telco' and o.carrier_name = 'Viettel' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as viettel_gtv,
            round(sum(case when o.category_name = 'Telco' and o.carrier_name not in ('Vinaphone','Mobifone','Viettel') and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as othertelco_gtv,
            round(sum(case when o.category_name = 'Voucher' and o.carrier_name not in ('Garena') and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as othergames_gtv,
            round(sum(case when o.category_name = 'E-wallet' and o.carrier_name in ('Ví Việt') and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as ViViet_gtv,
            round(sum(case when o.category_name = 'Printer' and o.status = 'Completed' then o.total_discount_price end)/100000/23000,0) as otherproducts_gtv,
            
            (sum(commission) + sum(product_price - product_discount_price))/100000 commission
        from select_date s
            left join shopee_vn_s1.apc_dp_vn_db__order_tab o on s.valid_date = date(from_unixtime(o.payment_time - 3600))
        group by 1
    ),
    new_merchant as (
        select
            valid_date,
            count(distinct m.id) as new_merchants,
            count(distinct case when b.status = 2 then m.id end) as new_giro_merchants
        from select_date s
            left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on s.valid_date = date(from_unixtime(m.create_time - 3600))
            left join shopee_vn.apc_account_vn_db__user_tab u on u.merchant_id = m.id
            left join shopee_vn.apc_wallet_vn_db__bank_account_tab b on b.user_id = u.uid
        where m.merchant_source = 60000 and u.role = 1 and m.m_status = 1
        group by 1
    ),
    a1 as (
        select
            valid_date,
            count(distinct(o1.merchant_id)) a1_w_txn
        from select_date s
            left join shopee_vn_s1.apc_dp_vn_db__order_tab o1 on s.valid_date = date(from_unixtime(o1.payment_time - 3600))
        where
            o1.status = 'Completed' and o1.carrier_name <> 'Ví Việt'
        group by 1
    ),
    a7 as (
        select
            valid_date,
            count(distinct(o7.merchant_id)) a7_w_txn
        from select_date s
            left join shopee_vn_s1.apc_dp_vn_db__order_tab o7 on s.valid_date >= date(from_unixtime(o7.payment_time - 3600)) and s.valid_date - interval '7' day < date(from_unixtime(o7.payment_time - 3600))
        where
            o7.status = 'Completed' and o7.carrier_name <> 'Ví Việt'
        group by 1
    ),
    a30 as (
        select
            valid_date,
            count(distinct(o30.merchant_id)) a30_w_txn
        from select_date s
           left join shopee_vn_s1.apc_dp_vn_db__order_tab o30 on s.valid_date >= date(from_unixtime(o30.payment_time - 3600)) and s.valid_date - interval '30' day < date(from_unixtime(o30.payment_time - 3600))
        where
            o30.status = 'Completed' and o30.carrier_name <> 'Ví Việt'
        group by 1
    ),
    refund as (
        select
            valid_date,
            count(distinct(o.order_id)) as refund_txn,
            round(sum(o.total_discount_price)/100000/23000,0) as refund_amt
        from select_date s
            left join shopee_vn_s1.apc_dp_vn_db__order_tab o on s.valid_date = date(from_unixtime(o.payment_time - 3600))
        where o.status = 'Refunded'
        group by 1
    ),
    total_merchant as (
        select
            valid_date,
            count(distinct m.id) as total_merchants,
            count(distinct case when b.status = 2 then m.id end) as GIRO_merchants
        from select_date s
        left join airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on date(from_unixtime(m.create_time - 3600)) <= s.valid_date
        left join shopee_vn.apc_account_vn_db__user_tab u on u.merchant_id = m.id
        left join shopee_vn.apc_wallet_vn_db__bank_account_tab b on b.user_id = u.uid
        where 1=1
            and m.merchant_source = 60000 and m.m_status = 1 and u.role = 1
        group by 1 
    ),
    topup as (
        select
            valid_date,
            round(sum(case when t.type in (1,5) and t.status = 4 then t.amount end)/100000/23000,0) as topup_gtv,
            count(distinct case when t.type in (1,5) and t.status = 4 then t.txn_id end) as topup_txn,
            round(sum(case when t.type = 1 and t.status = 4 and t.topup_channel = 1 then t.amount end)/100000/23000,0) as channel_gtv_GIRO,
            round(sum(case when t.type = 1 and t.status = 4 and t.topup_channel in (2,3) then t.amount end)/100000/23000,0) as channel_gtv_Bank_transfer,
            round(sum(case when t.type = 5 and t.status = 4 then t.amount end)/100000/23000,0) as channel_gtv_Cash_collection, -- Dealer transfers to merchants

            count(distinct case when t.type = 1 and t.status = 4 and t.topup_channel = 1 then t.txn_id end) as channel_txn_GIRO,
            count(distinct case when t.type = 1 and t.status = 4 and t.topup_channel in (2,3) then t.txn_id end) as channel_txn_Bank_transfer,
            count(distinct case when t.type = 5 and t.status = 4 then t.txn_id end) as channel_txn_Cash_collection -- Dealer transfers to merchants
        from select_date s
            left join shopee_vn.apc_transaction_vn_db__transaction_tab t on date(t.update_time - interval '1' hour) = s.valid_date
            left join shopee_vn_s1.apc_account_vn_db__user_tab u on t.uid = u.uid
        where u.role <> 3 -- excld. agent topup to personal bank accnt
        group by 1
    )
    select
        valid_date,
        o.*,
        new_merchants,
        new_giro_merchants,
        a1.a1_w_txn,
        a7.a7_w_txn,
        a30.a30_w_txn,
        r.refund_txn,
        r.refund_amt,
        tm.total_merchants,
        tm.GIRO_merchants,
        t.*
    from order_related o
        left join new_merchant nm using(valid_date)
        left join a1 a1 using(valid_date)
        left join a7 a7 using(valid_date)
        left join a30 a30 using(valid_date)
        left join refund r using(valid_date)
        left join total_merchant tm using(valid_date)
        left join topup t using(valid_date)
),
chainstore as (
    with
    order_related as (
        select
            valid_date,
            count(distinct p.id) as txn,
            round(sum(p.base_price)/23000,0) as gross_gtv,
            count(case when gl_code = 'GPPC' then 1 end) as gppc_txn,
            count(case when gl_code = 'GPPC' then 1 end) as gppc_chainstore_txn,
            count(case when gl_code = 'BILL' and category in ('CREDIT') then 1 end) as fin_txn,
            count(case when gl_code = 'BILL' and category in ('CREDIT') and regexp_like(name, 'Home') then 1 end) as home_txn,
            count(case when gl_code = 'BILL' and category in ('CREDIT') and regexp_like(name, 'FE') then 1 end) as fe_txn,
            count(case when gl_code = 'BILL' and category in ('CREDIT') and regexp_like(name, 'ACS|OCB') then 1 end) as acs_ocb_txn,
            count(case when gl_code = 'BILL' and category in ('CREDIT') and not regexp_like(name, 'ACS|OCB|Home|FE') then 1 end) as otherfin_txn,
            count(case when gl_code = 'BILL' and category in ('ELECTRICITY') or regexp_like(category, 'NPC|SPC|CPC') then 1 end) as elec_txn,
            count(case when gl_code = 'BILL' and category in ('WATER') then 1 end) as water_txn,
            count(case when gl_code = 'BILL' and not regexp_like(category, 'WATER|ELECTRICITY|CREDIT|NPC|SPC|CPC') then 1 end) as otherbills_txn,
            count(case when gl_code = 'TELC' then 1 end) as telco_txn,
            count(case when gl_code = 'TELC' and regexp_like(category, 'Mobi') then 1 end) as mobi_txn,
            count(case when gl_code = 'TELC' and regexp_like(category, 'Vina') then 1 end) as vina_txn,
            count(case when gl_code = 'TELC' and regexp_like(category, 'Viettel') then 1 end) as viettel_txn,
            count(case when gl_code = 'TELC' and not regexp_like(category, 'Viettel|Vina|Mobi') then 1 end) as othertelco_txn,
            count(case when gl_code = 'GAME' then 1 end) as othergames_txn,
            count(case when gl_code = 'TOPUP' then 1 end) as ViViet_txn,
            count(case when gl_code = 'GCA' or gl_code = 'MCD' or gl_code = 'OTH' or gl_code = 'dummy' then 1 end) as otherproducts_txn,
            round(sum(case when gl_code = 'GPPC' then p.base_price end)/23000,0) as gppc_gtv,
            round(sum(case when gl_code = 'GPPC' then p.base_price end)/23000,0) as chainstore_gppc_gtv,
            round(sum(case when gl_code = 'BILL' and category in ('CREDIT') then p.base_price end)/23000,0) as fin_gtv,
            round(sum(case when gl_code = 'BILL' and category in ('CREDIT') and regexp_like(name, 'Home') then p.base_price end)/23000,0) as home_gtv,
            round(sum(case when gl_code = 'BILL' and category in ('CREDIT') and regexp_like(name, 'FE') then p.base_price end)/23000,0) as fe_gtv,
            round(sum(case when gl_code = 'BILL' and category in ('CREDIT') and regexp_like(name, 'ACS|OCB') then p.base_price end)/23000,0) as acs_ocb_gtv,
            round(sum(case when gl_code = 'BILL' and category in ('CREDIT') and not regexp_like(name, 'ACS|OCB|FE|Home') then p.base_price end)/23000,0) as otherfin_gtv,
            round(sum(case when gl_code = 'BILL' and category in ('ELECTRICITY') or regexp_like(category, 'NPC|SPC|CPC') then p.base_price end)/23000,0) as elec_gtv,
            round(sum(case when gl_code = 'BILL' and category in ('WATER') then p.base_price end)/23000,0) as water_gtv,
            round(sum(case when gl_code = 'BILL' and not regexp_like(category, 'WATER|ELECTRICITY|CREDIT|NPC|SPC|CPC') then p.base_price end)/23000,0) as otherbills_gtv,
            round(sum(case when gl_code = 'TELC' then p.base_price end)/23000,0) as telco_gtv,
            round(sum(case when gl_code = 'TELC' and regexp_like(category, 'Mobi') then p.base_price end)/23000,0) as mobi_gtv,
            round(sum(case when gl_code = 'TELC' and regexp_like(category, 'Vina') then p.base_price end)/23000,0) as vina_gtv,
            round(sum(case when gl_code = 'TELC' and regexp_like(category, 'Vina') then p.base_price end)/23000,0) as viettel_gtv,
            round(sum(case when gl_code = 'TELC' and not regexp_like(category, 'Viettel|Vina|Mobi') then p.base_price end)/23000,0) as othertelco_gtv,
            round(sum(case when gl_code = 'GAME' then p.base_price end)/23000,0) as othergames_gtv,
            round(sum(case when gl_code = 'TOPUP' then p.base_price end)/23000,0) as ViViet_gtv,
            round(sum(case when gl_code = 'GCA' or gl_code = 'MCD' or gl_code = 'OTH' or gl_code = 'dummy' then p.base_price end)/23000,0) as otherproducts_gtv,
            
            0 as commission
        from select_date s
            left join airpay_vn.vpay_vn__purchase_tab p on date(time_stamp + interval '7' hour) = s.valid_date
            left join airpay_vn.vpay_vn__product_tab pp on pp.id=p.product_id
            left join airpay_vn.vpay_vn__retailer_tab r on p.retailer_id=r.id
        where 1=1
            and (regexp_like(lower(first_name),'chainstore|chuỗi') or regexp_like(lower(last_name),'chainstore|chuỗi'))
        group by 1
    ),
    new_merchant as (
        select
            valid_date,
            count(distinct(a.id)) as new_retailers
        from select_date s
            left join airpay_vn.vpay_vn__retailer_tab a on date(a.date_created + interval '7' hour) = s.valid_date
        where a.balance > 0
        and (regexp_like(lower(a.first_name),'chainstore|chuỗi') or regexp_like(lower(a.last_name),'chainstore|chuỗi'))
        group by 1
    ),
    active as (
        select
            valid_date,
            count(distinct retailer_id) as a1_w_txn,
            count(distinct retailer_id) as a7_w_txn, -- sửa sau
            count(distinct retailer_id) as a30_w_txn -- sửa sau
        from select_date s
            left join airpay_vn.vpay_vn__purchase_tab p on date(time_stamp + interval'7'hour) = valid_date
            left join airpay_vn.vpay_vn__retailer_tab r on p.retailer_id = r.id
        where regexp_like(lower(first_name),'chainstore|chuỗi') or regexp_like(lower(last_name),'chainstore|chuỗi')
        group by 1
    )
    -- refund as (
    --     select
    --         0 as refund_orders,
    --         0 as refund_amt
    -- ),
    -- total_merchant as (
    --     select
    --         0 as total_merchants,
    --         0 as GIRO_merchants

    -- ),
    -- topup as (
    --     select
    --         0 as total_topup_gtv,
    --         0 as total_topup_txn,
    --         0 as channel_gtv_GIRO,
    --         0 as channel_gtv_Bank_transfer,
    --         0 as channel_gtv_Cash_collection,
    --         0 as channel_txn_GIRO,
    --         0 as channel_txn_Bank_transfer,
    --         0 as channel_txn_Cash_collection)
    select
        valid_date,
        o.*,
        0 as new_merchants,
        0 as new_giro_merchants,
        a.a1_w_txn,
        a.a7_w_txn,
        a.a30_w_txn,
        0 as refund_txn,
        0 as refund_amt,
        0 as total_merchants,
        0 as GIRO_merchants,
        0 as topup_gtv,
        0 as topup_txn,
        0 as channel_gtv_GIRO,
        0 as channel_gtv_Bank_transfer,
        0 as channel_gtv_Cash_collection,
        0 as channel_txn_GIRO,
        0 as channel_txn_Bank_transfer,
        0 as channel_txn_Cash_collection
    from order_related o
        left join new_merchant nm using(valid_date)
        left join active a using(valid_date)
        -- left join refund r using(valid_date)
        -- left join total_merchant tm using(valid_date)
        -- left join topup t using(valid_date)
)
select
    current_date report_run_at,
    year(valid_date) year,
    month(valid_date) month,
    day(valid_date) day,
    valid_date,
    sum(txn) as txn,
    sum(gross_gtv) as gross_gtv,
    sum(gppc_txn) as gppc_txn,
    sum(gppc_chainstore_txn) as gppc_chainstore_txn,
    sum(fin_txn) as fin_txn,
    sum(home_txn) as home_txn,
    sum(fe_txn) as fe_txn,
    sum(acs_ocb_txn) as acs_ocb_txn,
    sum(otherfin_txn) as otherfin_txn,
    sum(elec_txn) as elec_txn,
    sum(water_txn) as water_txn,
    sum(otherbills_txn) as otherbills_txn,
    sum(telco_txn) as telco_txn,
    sum(mobi_txn) as mobi_txn,
    sum(vina_txn) as vina_txn,
    sum(viettel_txn) as viettel_txn,
    sum(othertelco_txn) as othertelco_txn,
    sum(othergames_txn) as othergames_txn,
    sum(ViViet_txn) as ViViet_txn,
    sum(otherproducts_txn) as otherproducts_txn,
    sum(gppc_gtv) as gppc_gtv,
    sum(chainstore_gppc_gtv) as chainstore_gppc_gtv,
    sum(fin_gtv) as fin_gtv,
    sum(home_gtv) as home_gtv,
    sum(fe_gtv) as fe_gtv,
    sum(acs_ocb_gtv) as acs_ocb_gtv,
    sum(otherfin_gtv) as otherfin_gtv,
    sum(elec_gtv) as elec_gtv,
    sum(water_gtv) as water_gtv,
    sum(otherbills_gtv) as otherbills_gtv,
    sum(telco_gtv) as telco_gtv,
    sum(mobi_gtv) as mobi_gtv,
    sum(vina_gtv) as vina_gtv,
    sum(viettel_gtv) as viettel_gtv,
    sum(othertelco_gtv) as othertelco_gtv,
    sum(othergames_gtv) as othergames_gtv,
    sum(ViViet_gtv) as ViViet_gtv,
    sum(otherproducts_gtv) as otherproducts_gtv,
    sum(commission) as commission,
    sum(new_merchants) as new_merchants,
    sum(new_giro_merchants) as new_giro_merchants,
    sum(a1_w_txn) as a1_w_txn,
    sum(a7_w_txn) as a7_w_txn,
    sum(a30_w_txn) as a30_w_txn,
    sum(refund_txn) as refund_txn,
    sum(refund_amt) as refund_amt ,
    sum(total_merchants) as total_merchants,
    sum(GIRO_merchants) as GIRO_merchants,
    sum(topup_gtv) as topup_gtv,
    sum(topup_txn) as topup_txn,
    sum(channel_gtv_GIRO) as channel_gtv_GIRO,
    sum(channel_gtv_Bank_transfer) as channel_gtv_Bank_transfer,
    sum(channel_gtv_Cash_collection) as channel_gtv_Cash_collection,
    sum(channel_txn_GIRO) as channel_txn_GIRO,
    sum(channel_txn_Bank_transfer) as channel_txn_Bank_transfer,
    sum(channel_txn_Cash_collection) as channel_txn_Cash_collection
from
    (
    (select * from non_chainstore)
        union
    (select * from chainstore)
    )
group by 1, 2, 3, 4, 5