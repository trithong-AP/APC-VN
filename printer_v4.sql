WITH sample AS
(SELECT 
        u.uid,
        m.city,
        m.contact,
        u.merchant_id,
        from_unixtime(m.create_time) merchant_create_time,
        least(from_unixtime(m.create_time), first_GIRO_link_date) adjusted_merchant_create_time, --due to wrong data of the new system
        first_GIRO_link_date,
        first_printer_order_id,
        first_printer_create_time,
        first_printer_delivered_time,
        case when date_trunc('month', first_printer_create_time) = date_trunc('month', least(from_unixtime(m.create_time), first_GIRO_link_date)) and date_trunc('month', first_printer_create_time) = date_trunc('month', first_GIRO_link_date) then True
             when date_trunc('month', first_printer_create_time) > date_trunc('month', least(from_unixtime(m.create_time), first_GIRO_link_date)) and date_trunc('month', first_printer_create_time) > date_trunc('month', first_GIRO_link_date) then False
             else Null -- nhận biết các case k thỏa đk về thời gian
        end is_new,
        case when m.city in ('TP Hồ Chí Minh', 'Hà Nội', 'Bắc Giang', 'Nghệ An', 'Bình Định', 'Đồng Nai', 'Tiền Giang', 'Trà Vinh', 'Cà Mau', 'Hậu Giang') then True else False end special_area,
        product_name
FROM 
    (SELECT user_id, status, row_number() over (partition by user_id order by create_time DESC) rn
    FROM shopee_vn.apc_wallet_vn_db__bank_account_tab
    WHERE status not in (1, 5)) last_status_bank_account
LEFT JOIN (SELECT user_id, from_unixtime(create_time) first_GIRO_link_date, row_number() over (partition by user_id order by create_time ASC) rn_first_linked FROM shopee_vn.apc_wallet_vn_db__bank_account_tab WHERE status = 2) first_linked on last_status_bank_account.user_id = first_linked.user_id
INNER JOIN shopee_vn.apc_account_vn_db__user_tab u ON last_status_bank_account.user_id = u.uid
INNER JOIN --get first printer order
    (SELECT fo.merchant_id,
            first_printer_order_id,
            product_name,
            from_unixtime(create_time - 3600) first_printer_create_time,
            from_unixtime(update_time - 3600) first_printer_delivered_time
    FROM
    (SELECT merchant_id, min(order_id) first_printer_order_id FROM shopee_vn_s1.apc_dp_vn_db__order_tab WHERE category_name = 'Printer'
        AND status = 'Completed' 
        AND from_unixtime(create_time - 3600) >= CURRENT_DATE - interval '+8' MONTH
    GROUP BY 1) fo
    LEFT JOIN shopee_vn_s1.apc_dp_vn_db__order_tab o ON fo.first_printer_order_id = o.order_id) foo ON u.merchant_id = foo.merchant_id
    INNER JOIN airpay_vn.airpay_merchant_info_vn_db__merchant_info_tab m on u.merchant_id = m.id
WHERE 1=1
    -- AND u.merchant_id = 2028246  --check merchant_id here
    -- AND foo.first_printer_order_id = 'APC1591625492681765200' --check printer order id here
    AND first_linked.rn_first_linked = 1 --get first day link GIRO
    AND last_status_bank_account.status = 2 and last_status_bank_account.rn = 1 --get GIRO linked merchant currently
    AND u.role = 1), 
count_GIRO as ( --count if in the period the merchant changes GIRO link
SELECT
    s.merchant_id,
    count(case when b.status in (3, 4) and from_unixtime(b.create_time) between  s.first_printer_delivered_time AND  s.first_printer_delivered_time + interval '30' DAY then account_id end) count_p1,
    count(case when b.status in (3, 4) and from_unixtime(b.create_time) between  s.first_printer_delivered_time + interval '31' DAY AND  s.first_printer_delivered_time + interval '60' DAY then account_id end) count_p2,
    count(case when b.status in (3, 4) and from_unixtime(b.create_time) between  s.first_printer_delivered_time + interval '61' DAY AND  s.first_printer_delivered_time + interval '90' DAY then account_id end) count_p3,
    count(case when b.status in (3, 4) and from_unixtime(b.create_time) between  s.first_printer_delivered_time + interval '91' DAY AND  s.first_printer_delivered_time + interval '120' DAY then account_id end) count_p4,
    count(case when b.status in (3, 4) and from_unixtime(b.create_time) between  s.first_printer_delivered_time + interval '121' DAY AND  s.first_printer_delivered_time + interval '150' DAY then account_id end) count_p5
FROM sample s
    INNER JOIN shopee_vn.apc_account_vn_db__user_tab u ON s.merchant_id = u.merchant_id
    INNER JOIN shopee_vn_s1.apc_wallet_vn_db__bank_account_tab b ON u.uid = b.user_id
--   WHERE b.status = 2
GROUP BY 1
),
revenue as (
    SELECT
    s.merchant_id,
    SUM(case when from_unixtime(o.payment_time - 3600) BETWEEN  s.first_printer_delivered_time AND  s.first_printer_delivered_time + interval '30' DAY then total_discount_price else 0 end)/100000 revenue_p1,
    SUM(case when from_unixtime(o.payment_time - 3600) BETWEEN  s.first_printer_delivered_time + interval '31' DAY AND  s.first_printer_delivered_time + interval '60' DAY then total_discount_price else 0 end)/100000 revenue_p2,
    SUM(case when from_unixtime(o.payment_time - 3600) BETWEEN  s.first_printer_delivered_time + interval '61' DAY AND  s.first_printer_delivered_time + interval '90' DAY then total_discount_price else 0 end)/100000 revenue_p3,
    SUM(case when from_unixtime(o.payment_time - 3600) BETWEEN  s.first_printer_delivered_time + interval '91' DAY AND  s.first_printer_delivered_time + interval '120' DAY then total_discount_price else 0 end)/100000 revenue_p4,
    SUM(case when from_unixtime(o.payment_time - 3600) BETWEEN  s.first_printer_delivered_time + interval '121' DAY AND  s.first_printer_delivered_time + interval '150' DAY then total_discount_price else 0 end)/100000 revenue_p5
FROM sample s
INNER JOIN shopee_vn_s1.apc_dp_vn_db__order_tab o ON s.merchant_id = o.merchant_id
WHERE o.status = 'Completed'
    AND o.order_id <> s.first_printer_order_id
    AND o.carrier_name <> 'Ví Việt'
GROUP BY 1
)
SELECT
CURRENT_DATE ngay_tinh_thuong,
merchant_id,
sample.*,
case  when product_name = 'Máy in Bluetooth' then 1000000 else 800000 end price,
case 
        when is_new = True and special_area = True  and product_name = 'Máy in Bluetooth'  then 5
        when is_new = True and special_area = True  and product_name <> 'Máy in Bluetooth' then 0
        when is_new = True and special_area = False and product_name = 'Máy in Bluetooth'  then 2
        when is_new = True and special_area = False and product_name <> 'Máy in Bluetooth' then 0
        when is_new = False                         and product_name = 'Máy in Bluetooth'  then 2
        when is_new = False                         and product_name <> 'Máy in Bluetooth' then 0
end max_p,
case
        when is_new = True and special_area = True  and product_name = 'Máy in Bluetooth'  then 0.2
        when is_new = True and special_area = True  and product_name <> 'Máy in Bluetooth' then 0
        when is_new = True and special_area = False and product_name = 'Máy in Bluetooth'  then 0.2
        when is_new = True and special_area = False and product_name <> 'Máy in Bluetooth' then 0
        when is_new = False                         and product_name = 'Máy in Bluetooth'  then 0.2
        when is_new = False                         and product_name <> 'Máy in Bluetooth' then 0
end percent_bonus,
case when revenue_p1 > 2000000 and count_p1 = 0 
            and date_diff('day', first_printer_delivered_time, CURRENT_TIMESTAMP) >= 30 
then 'Yes' else 'No' end eli_30,
case when revenue_p1 > 2000000 and count_p1 = 0 and revenue_p2 > 2000000 and count_p2 = 0 
            and date_diff('day', first_printer_delivered_time, CURRENT_TIMESTAMP) >= 60 
then 'Yes' else 'No' end eli_60,
case when revenue_p1 > 2000000 and count_p1 = 0 and revenue_p2 > 2000000 and count_p2 = 0 and revenue_p3 > 2000000 and count_p3 = 0 
            and date_diff('day', first_printer_delivered_time, CURRENT_TIMESTAMP) >= 90 
then 'Yes' else 'No' end eli_90,
case when revenue_p1 > 2000000 and count_p1 = 0 and revenue_p2 > 2000000 and count_p2 = 0 and revenue_p3 > 2000000 and count_p3 = 0 and revenue_p4 > 2000000 and count_p4 = 0
            and date_diff('day', first_printer_delivered_time, CURRENT_TIMESTAMP) >= 120 
then 'Yes' else 'No' end eli_120,
case when revenue_p1 > 2000000 and count_p1 = 0 and revenue_p2 > 2000000 and count_p2 = 0 and revenue_p3 > 2000000 and count_p3 = 0 and revenue_p4 > 2000000 and count_p4 = 0 and revenue_p5 > 2000000 and count_p5 = 0
            and date_diff('day', first_printer_delivered_time, CURRENT_TIMESTAMP) >= 150 
then 'Yes' else 'No' end eli_150

/*muốn check số thì dùng phần dưới này
,revenue_p1,
count_p1,
revenue_p2,
count_p2,
revenue_p3,
count_p3,
revenue_p4,
count_p4,
revenue_p5,
count_p5,
case when revenue_p1 > 2000000 and count_p1 = 0 then
        case when is_new = True and special_area = True  and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = True and special_area = True  and product_name <> 'Máy in Bluetooth' then 0.4 * 800000
             when is_new = True and special_area = False and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = True and special_area = False and product_name <> 'Máy in Bluetooth' then 0.4 * 800000
             when is_new = False                         and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = False                         and product_name <> 'Máy in Bluetooth' then 0.4 * 800000
        else 0 end
else 0 end bonus_p1,
case when revenue_p2 > 2000000 and count_p2 = 0 and revenue_p1 > 2000000 and count_p1 = 0 then
        case when is_new = True and special_area = True  and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = True and special_area = True  and product_name <> 'Máy in Bluetooth' then 0
             when is_new = True and special_area = False and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = True and special_area = False and product_name <> 'Máy in Bluetooth' then 0
             when is_new = False                         and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = False                         and product_name <> 'Máy in Bluetooth' then 0
        else 0 end
else 0 end bonus_p2,
case when revenue_p3 > 2000000 and count_p3 = 0 and revenue_p2 > 2000000 and count_p2 = 0 and revenue_p1 > 2000000 and count_p1 = 0 then
        case when is_new = True and special_area = True  and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = True and special_area = True  and product_name <> 'Máy in Bluetooth' then 0
             when is_new = True and special_area = False and product_name = 'Máy in Bluetooth'  then 0
             when is_new = True and special_area = False and product_name <> 'Máy in Bluetooth' then 0
             when is_new = False                         and product_name = 'Máy in Bluetooth'  then 0
             when is_new = False                         and product_name <> 'Máy in Bluetooth' then 0
        else 0 end
else 0 end bonus_p3,
case when revenue_p4 > 2000000 and count_p4 = 0 and revenue_p3 > 2000000 and count_p3 = 0 and revenue_p2 > 2000000 and count_p2 = 0 and revenue_p1 > 2000000 and count_p1 = 0 then
        case when is_new = True and special_area = True  and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = True and special_area = True  and product_name <> 'Máy in Bluetooth' then 0
             when is_new = True and special_area = False and product_name = 'Máy in Bluetooth'  then 0
             when is_new = True and special_area = False and product_name <> 'Máy in Bluetooth' then 0
             when is_new = False                         and product_name = 'Máy in Bluetooth'  then 0
             when is_new = False                         and product_name <> 'Máy in Bluetooth' then 0
        else 0 end
else 0 end bonus_p4,
case when revenue_p5 > 2000000 and count_p5 = 0 and revenue_p4 > 2000000 and count_p4 = 0 and revenue_p3 > 2000000 and count_p3 = 0 and revenue_p2 > 2000000 and count_p2 = 0 and revenue_p1 > 2000000 and count_p1 = 0 then
        case when is_new = True and special_area = True  and product_name = 'Máy in Bluetooth'  then 0.2 * 1000000
             when is_new = True and special_area = True  and product_name <> 'Máy in Bluetooth' then 0
             when is_new = True and special_area = False and product_name = 'Máy in Bluetooth'  then 0
             when is_new = True and special_area = False and product_name <> 'Máy in Bluetooth' then 0
             when is_new = False                         and product_name = 'Máy in Bluetooth'  then 0
             when is_new = False                         and product_name <> 'Máy in Bluetooth' then 0
        else 0 end
else 0 end bonus_p5 
-- */
FROM sample
LEFT JOIN revenue using(merchant_id)
LEFT JOIN count_GIRO using(merchant_id)