with activemonth as (
	select customer_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2
),

grid as (
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

ar as (
	with r as (
		select professional_id
			  ,avvo_rating
			  ,months as start_month
			  ,coalesce(lead(months) over (partition by professional_id order by months ASC),100) as end_month
		from (
		  select
			  sd.professional_id
			 ,12*(year(score_date)-2013)+month(score_date) as months
			 ,avg(case when sd.displayable_score>10 then 10
					   when sd.displayable_score<1 then 1 
					   else sd.displayable_score end ) avvo_rating
		  from(
			  select opsl.professional_id,opsl.score_date,round(sum(opsl.displayable_score)+5,1) displayable_score
			  from src.history_barrister_professional_scoring_log  opsl
			  join src.barrister_scoring_category_attribute  osca 
			  on opsl.scoring_category_attribute_id=osca.id
			  join src.barrister_scoring_category osc 
			  on osca.scoring_category_id=osc.id
			  and osc.name='Overall'
			  group by opsl.professional_id,opsl.score_date
			  )sd
		  group by 1,2 ) ab
	 )
	select grid.customer_id
		,grid.months
		,avg(r.avvo_rating)as avvo_rating
	from grid
	join r 
	on r.professional_id=grid.professional_id  
	and grid.months>=r.start_month
	and grid.months<r.end_month
	group by 1,2
	order by 1,2
) 
 
select a.customer_id,a.months
       ,ar.avvo_rating
       ,ar1.avvo_rating as avvo_rating_1
       ,ar2.avvo_rating as avvo_rating_2
       ,ar3.avvo_rating as avvo_rating_3
from activemonth a
left join ar
on a.customer_id=ar.customer_id and a.months=ar.months
left join ar as ar1
on a.customer_id=ar1.customer_id and a.months-1=ar1.months
left join ar as ar2
on a.customer_id=ar2.customer_id and a.months-2=ar2.months
left join ar as ar3
on a.customer_id=ar3.customer_id and a.months-3=ar3.months 
where a.months>=18
order by 1,2