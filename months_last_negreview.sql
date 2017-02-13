with activemonth as (
	select customer_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2
),

nr as (
with grid as (
with cpm as (    
	select customer_id, professional_id
	,min(12*(year(etl_effective_begin_date)-2013)+month(etl_effective_begin_date))-3 as minmonths
	,max(12*(year(etl_effective_end_date)-2013)+month(etl_effective_end_date)) as maxmonths
	from dm.historical_ad_customer_professional_map
	where professional_id!=-1
	group by 1,2)

select cpm.customer_id,cpm.professional_id,b.months
from cpm  
cross join (
	select 12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2014-06-01'
	group by 1) b
where b.months between cpm.minmonths and cpm.maxmonths
order by 1,2,3
),

r as (	
	select professional_id
        ,12*(year(created_at)-2013)+month(created_at) as months
		,count(*)as negativereviews
	from src.barrister_professional_review
	where recommended=0
    and to_date(created_at)>='2013-01-01'
	group by 1,2
  )

select grid.customer_id,r.months
from grid
right join r 
on grid.professional_id=r.professional_id
and grid.months=r.months
group by 1,2
)

select am.customer_id,am.months,max(nr.months) as months_last_negreview,max(nr1.months) as months_last_negreview_1
,max(nr2.months) as months_last_negreview_2,max(nr3.months) as months_last_negreview_3
from activemonth as am
left join nr as nr
on am.customer_id=nr.customer_id
and am.months>nr.months
left join nr as nr1
on am.customer_id=nr1.customer_id
and am.months-1>nr1.months
left join nr as nr2
on am.customer_id=nr2.customer_id
and am.months-2>nr2.months
left join nr as nr3
on am.customer_id=nr3.customer_id
and am.months-3>nr3.months
where am.months>=18
group by 1,2
order by 1,2
