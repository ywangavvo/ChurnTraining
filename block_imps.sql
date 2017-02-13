with activemonth as (
	select customer_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2
),

block as (
	select b.ad_market_id
     ,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
     ,case when sum(block_count)>0 then 1 
           else 0 end as block
	from dm.order_line_accumulation_fact a
    join dm.order_line_ad_market_fact b
    on a.order_line_number=b.order_line_number
    and a.professional_id=b.professional_id
	where order_line_begin_date>='2014-06-01'
	and product_line_id in (2,7)
	and year(order_line_payment_date) IS NOT NULL
	and year(order_line_payment_date) <> 1900
	group by 1,2),

block_imps	as (
with imps as(
select mp.customer_id
    ,amd.ad_market_id
    ,12*(year(imp.event_date)-2013)+month(imp.event_date) as months
    ,count(distinct imp.ad_impression_guid) as impressions
from src.ad_impression imp
join src.ad_request req on req.ad_request_guid = imp.ad_request_guid and imp.event_date=req.event_date
join dm.specialty_dimension sd on req.specialty_id = sd.specialty_id 
join dm.ad_region_dimension ard on req.sales_region_id = ard.ad_region_id
join dm.ad_market_dimension amd on amd.specialty_id = sd.specialty_id and amd.ad_region_id = ard.ad_region_id 
join (select customer_id,ad_id,etl_effective_begin_date,etl_effective_end_date
      from dm.historical_ad_customer_professional_map
      group by 1,2,3,4) as mp
     on imp.ad_id=mp.ad_id
     and imp.event_date>=mp.etl_effective_begin_date
     and imp.event_date<=mp.etl_effective_end_date
where imp.event_date>='2014-06-01'
group by 1,2,3
)
select customer_id,imps.months,sum(impressions) as block_imps
from imps join block on imps.ad_market_id=block.ad_market_id
and imps.months=block.months 
and block.block=1
group by 1,2
order by 1,2
)

select a.customer_id,a.months
	,bi.block_imps,bi1.block_imps as block_imps_1,bi2.block_imps as block_imps_2,bi3.block_imps as block_imps_3
from activemonth a 
left join block_imps as bi 
on a.customer_id=bi.customer_id and a.months=bi.months
left join block_imps as bi1 
on a.customer_id=bi1.customer_id and a.months-1=bi1.months
left join block_imps as bi2 
on a.customer_id=bi2.customer_id and a.months-2=bi2.months
left join block_imps as bi3 
on a.customer_id=bi3.customer_id and a.months-3=bi3.months
where a.months>=18
order by 1,2