with activemonth as (
	select customer_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2
)

select a.customer_id,a.months
	,b.nonsem_imps,b1.nonsem_imps as nonsem_imps_1,b2.nonsem_imps as nonsem_imps_2,b3.nonsem_imps as nonsem_imps_3
	,b.brand_imps,b1.brand_imps as brand_imps_1,b2.brand_imps as brand_imps_2,b3.brand_imps as brand_imps_3	
	,b.adblock_imps,b1.adblock_imps as adblock_imps_1,b2.adblock_imps as adblock_imps_2,b3.adblock_imps as adblock_imps_3	
	,b.network_imps,b1.network_imps as network_imps_1,b2.network_imps as network_imps_2,b3.network_imps as network_imps_3
    ,b.pls_imps,b1.pls_imps as pls_imps_1,b2.pls_imps as pls_imps_2,b3.pls_imps as pls_imps_3
from activemonth a 
left join tmp_data_dm.yw_imp b
on a.customer_id=b.customer_id and a.months=b.months
left join tmp_data_dm.yw_imp b1
on a.customer_id=b1.customer_id and a.months-1=b1.months
left join tmp_data_dm.yw_imp b2
on a.customer_id=b2.customer_id and a.months-2=b2.months
left join tmp_data_dm.yw_imp b3
on a.customer_id=b3.customer_id and a.months-3=b3.months
where a.months>=18
order by 1,2