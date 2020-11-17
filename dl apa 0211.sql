with
    select_date as (
        select
            distinct date(from_unixtime(valid_time-3600)) date
        from
            airpay_vn.airpay_payment_txn_vn_db__txn_order_tab
        where 1=1
            and date(from_unixtime(valid_time-3600)) between current_date - interval '5' day and current_date - interval '1' day
    ),
    order_related as (
        select 
            sd.date,
            -- category
            count(order_id) as txn,
            sum(amount) as gtv, 
            count(distinct uid) as A1_txn,
            count(case when category='telco' then 1 end) as telco_txn,
            count(case when category='bill_uti' then 1 end) as bill_uti_txn,
            count(case when category='bill_fin' then 1 end) as bill_fin_txn,
            count(case when category='gppc' then 1 end) as gppc_txn,
            count(case when category='foody' then 1 end) as foody_txn,
            count(case when category='virtual card' then 1 end) as vcard_txn,
            count(case when category='ocha' then 1 end) as ocha_txn,
            count(case when category in ('other') then 1 end) as other_txn,
            count(case when category in ('other_games') then 1 end) as other_games_txn,

            sum(case when category = 'telco' then amount end) as telco_gtv,
            sum(case when category = 'bill_uti' then amount end) as bill_uti_gtv,
            sum(case when category = 'bill_fin' then amount end) as bill_fin_gtv,
            sum(case when category = 'gppc' then amount end) as gppc_gtv,
            sum(case when category = 'foody' then amount end) as foody_gtv,
            sum(case when category = 'virtual card' then amount end) as vcard_gtv,
            sum(case when category =	'ocha' then amount end) as ocha_gtv,
            sum(case when category in ('other') then amount end) as other_gtv,
            sum(case when category in ('other_games') then amount end) as other_games_gtv,
            
            count(case when category in ('QR') then 1 end) as txn_qr,
            count(case when category in ('P2P') then 1 end) as txn_p2p,
            sum(case when category in ('QR') then amount end) as vol_qr,
            sum(case when category in ('P2P') then amount end) as vol_p2p


            ,sum(case when topup_channel_id in (10004) then 1 end) credit_txn
            ,sum(case when topup_channel_id between 13400 and 13451 then 1 end) giro_txn
            ,sum(case when topup_channel_id in (11000,11030) then 1 end) cash_txn
            ,sum(case when topup_channel_id in (10004) then amount end) credit_gtv
            ,sum(case when topup_channel_id between 13400 and 13451 then amount end) giro_gtv
            ,sum(case when topup_channel_id in (11000,11030) then amount end) cash_gtv

            ,count(case when category in ('Shopee') then 1 end) as shopee_txn
            ,sum(case when category in ('Shopee') then amount end) as shopee_gtv

            ,sum(case when category in ('Shopee') and json_extract_scalar(extra_data,'$.payment.__private__.partner.partner_reference_mct') = '3' then 1 end) shopee_nowfood_txn
            ,sum(case when category in ('Shopee') and json_extract_scalar(extra_data,'$.payment.__private__.partner.partner_reference_mct') = '3' then amount end) shopee_nowfood_gtv
            
            ,sum(case when category in ('bhd') then 1 end) movie_txn
            ,sum(case when category in ('bhd') then amount end) movie_gtv
            --,sum(case when category in ('Shopee') and (amount*23250000000) <10 then 1 end) shopee_game1d_txn

            ,sum(case when category in ('QR') then cashback+topup_coins_amount end) cashback_amount
            ,round(sum(															
            (case when category not in ('QR', 'other_games', 'Shopee', 'foody') then --theo đk câu cũ
                case														
                --when tb1.payment_channel_id in (20001, 20002, 24001, 24004, 24008,310004,310009,24009) and  tb1.item_id not in ('0', '') then (0.95)														
                when (payment_channel_id in (20115,30101) and amount=(10000/23250) and item_id not in ('0', '') )  then (0.98) -- viettel 10K 2%														
                when (payment_channel_id in (20115,30101) and amount>(10000/23250) and item_id not in ('0', '') ) then (0.97) -- other viettel 3%														
                when (payment_channel_id in (20111,30102) and item_id not in ('0', '') ) then (0.954) -- vina 4.6%														
                when (payment_channel_id in (20112,30103) and item_id not in ('0', '') )  then (0.956) -- mobi 4.4%														
                when (payment_channel_id in (20114) and item_id not in ('0', '') ) then (0.94) -- vietnamobile airtime 6%														
                when (payment_channel_id in (30104) and item_id not in ('0', '') ) then (0.93) -- vietnamobile 
                else cast(1 as double) end
            
            end) *
            (payment_payable_amount - currency_amount)),2) +
            round(sum(case when category not in ('QR', 'other_games', 'Shopee', 'foody') then cashback end),2) as inapp_cost

        from
            select_date sd
            left join 
            (
            select 
                date(from_unixtime(payment_valid_time-3600)) as date,
                tb1.uid,
                tb1.order_id,
                tb1.topup_channel_id,
                tb1.topup_payable_amount/1000000/cast(23250 as double) as amount,
                tb1.payment_payable_amount/1000000/cast(23250 as double) as payment_payable_amount,
                tb1.payment_cash_amount/1000000/cast(23250 as double) as cashback,
                currency_amount/1000000/cast(23250 as double) currency_amount,
                topup_coins_amount/1000000/cast(23250 as double) topup_coins_amount,
                payment_coins_num/1000000/cast(23250 as double) payment_coins_num,
                tb1.payment_channel_id,
                case when tb1.payment_channel_id in (20111, 20112, 20113, 20114, 20115, 30101, 30102, 30103, 30104, 30105, 30350, 30351) then 'telco'
                when substr(cast(tb1.payment_channel_id as varchar),1,2) = '32' and tb1.payment_channel_id not in (32033,32034,32037,32078,32079,32080,32081,32148,32149,32150,32158) then 'bill_uti'
                when tb1.payment_channel_id in (32033,32034,32037,32078,32079,32080,32081,32148,32149,32150,32158) then 'bill_fin'
                when tb1.payment_channel_id in (20001, 20002, 24001, 24004, 24008,310004,310009,24009,30024) then 'gppc' -- in-app cost không có 30024 chị Lan check
                when tb1.payment_channel_id in (310005,310007,310021,310028, 310029, 310039) then 'foody'
                when tb1.payment_channel_id in (21030) then 'virtual card'
                when tb1.payment_channel_id in (310010,310053,310054) then 'ocha'
                when tb1.payment_channel_id in (30002,30003,30004,30005,30006,30007,30008,30009,30010,30011,30012,30013,30014,30015,30016,30017,30018,30019,30020,30021,30022,30023) then 'other_games'
                when tb1.payment_channel_id in (500001) then 'Shopee'
                when tb1.payment_channel_id in (21001) then 'P2P'
                when tb1.payment_channel_id in (21071) then 'QR'
                when tb1.payment_channel_id in (35001) then 'bhd'
                else 'other' end as category,
                tb1.extra_data,
                tb1.item_id
            -- from select_date sd
            --     left join airpay_payment_txn_stats_vn_db__order_extra_tab tb2 on sd.date = from_unixtime(payment_valid_time-3600)
            --     left join airpay_vn.airpay_payment_txn_vn_db__txn_order_tab tb1 on tb1.order_id= tb2.order_id
            from airpay_vn.airpay_payment_txn_vn_db__txn_order_tab tb1
                left join airpay_vn.airpay_payment_txn_stats_vn_db__order_extra_tab tb2 on tb1.order_id= tb2.order_id
            where 1=1
                and date(from_unixtime(payment_valid_time-3600)) >= current_date - interval '5' day
                and tb1.memo <> 'test'
                and tb1.topup_channel_id not in (11100,13002,13003,13004,13009,13010,13011,13103) --câu lấy in-app cost không có, chị Lan chek
                and tb1.payment_channel_id not in (21000, 21002,21003,21004,21005,21006,21007,21008,21009,100021011,100021016,
                100021017,100021040,999991,999992,999993,100021018,100021019,100021020,100021021,
                100021022,100021023,100021024,100021025,100021026,100021027,100021028,100021029,
                100021040,100021041,100021042,100021043,100001,110012,210001,210002,210003,210004,
                210005,210006,210007,210008,210009,210010,210011,210013,210014,210015,210016,210017,
                210018,21031,21032,21033,21034,21035,21039,10200077,10200086,10200092,10200097,11000001,11000002,
                310001,310002,11000003,100021013,100021014,100021015,21070,21011,31000,31001,21074,
                379017, --kotoro
                379004, --Payoo CsB Dynamic
                379001, --boft
                379003, --7eleven
                379041, --vufood
                379043, --Kootoro Smart POS
                379047 --BsC 1024746 - AIRPAY-41983
                )
                and not (payment_payable_amount < 2000000000 and tb1.payment_channel_id in (21070))
                and not (payment_payable_amount < 100000000 and tb1.payment_channel_id = 500001)
            ) a on a.date = sd.date
        group by 1
    ),
    login as (
        select
            date(from_unixtime(time-3600)) as date,
            count(distinct uid) A1_login
        from
            select_date sd
            left join
            airpay_vn.airpay_user_account_vn_db__user_login_log_tab a on sd.date = date(from_unixtime(time-3600))           
        where 1=1
            and a.action = 0
        group by 1
    ),
    register as (
        select
            date(from_unixtime(register_time-3600)) as date, 
            count(distinct uid) as new_user
        from
            select_date sd
            left join
            airpay_vn.beepay_vn_db__user_register_tab r on sd.date = date(from_unixtime(register_time-3600))    
        where 1=1
        group by 1
    ),
    new_buyer as (
        select
            sd.date,
            count(distinct uid) new_buyer
        from  select_date sd
        left join
            (
            select
                uid,
                min(date(from_unixtime(valid_time - 3600))) date
            from
                airpay_vn.airpay_payment_txn_vn_db__txn_order_tab a
            where 1=1
                and a.status = 8
                and memo <> 'test'
                and topup_channel_id not in (11100,11001,13002,13003,13004,13009,13010,13011,13103) 
                and payment_channel_id not in (21000,21001,21002,21003,21004,21005,21006,21007,21008,21009,21070,21011,31000,31001,21074)
                --and a.payment_channel_id = 500001
                -- and payment_payable_amount/1000000 > 20
            group by 1
        ) a on sd.date = a.date
        where 1=1
        group by 1
    ),
    a30 as (
        select													
            date,													
            count(distinct uid) AP_A30													
            --from beepay_txn_vn_db__order_tab a 
        from select_date sd 
             left join airpay_vn.airpay_payment_txn_vn_db__txn_order_tab a on date(from_unixtime(a.valid_time-3600))  between date - interval '29' day and date 											                                                 
        where 1=1
            --where date(from_unixtime(valid_time-3600)) between TIMESTAMP '2019-09-01' and TIMESTAMP '2020-08-25'
            --and a.payment_channel_id not in (31001, 31000,21074)													
            and a.memo <> 'test'													
            and a.topup_channel_id not in (11100,13002,13003,13004,13009,13010,13011,13103)													
            and a.payment_channel_id not in (21000, 21002,21003,21004,21005,21006,21007,21008,21009,100021011,100021016,													
            100021017,100021040,999991,999992,999993,100021018,100021019,100021020,100021021,													
            100021022,100021023,100021024,100021025,100021026,100021027,100021028,100021029,													
            100021040,100021041,100021042,100021043,100001,110012,210001,210002,210003,210004,													
            210005,210006,210007,210008,210009,210010,210011,210013,210014,210015,210016,210017,													
            210018,21031,21032,21033,21034,21035,21039,10200077,10200086,10200092,10200097,11000001,11000002,													
            310001,310002,11000003,100021013,100021014,100021015,21070,21011,31000,31001,21074,
            379017, --kotoro
            379004, --Payoo CsB Dynamic
            379001, --boft
            379003, --7eleven
            379041, --vufood
            379043, --Kootoro Smart POS
            379047 --BsC 1024746 - AIRPAY-41983
            )													
            and not (payment_payable_amount < 2000000000 and a.payment_channel_id in (21070,21071))													
            group by 1				
            order by 1
    )
select
*
from order_related 
left join login using (date)
left join register using (date)
left join new_buyer using (date)
left join a30 using (date)