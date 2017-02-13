with activemonth as (
	select customer_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2
),

cust_prof as (
select customer_id
	,professional_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
from dm.order_line_accumulation_fact
where order_line_begin_date>='2013-01-01'
and professional_id!=-1
and product_line_id in (2,7)
group by 1,2,3
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

activities as( 
with r as (	
	select professional_id
        ,12*(year(created_at)-2013)+month(created_at) as months
		,count(*)as negativereviews
	from src.barrister_professional_review
	where recommended=0
    and to_date(created_at)>='2014-06-01'
	group by 1,2),
 q as (	
	select professional_id
        ,12*(year(created_at)-2013)+month(created_at) as months
		,count(*)as reviews
	from src.barrister_professional_review
    where to_date(created_at)>='2014-06-01'
	group by 1,2),
login as (	
	select pd.professional_id
        ,12*(year(wl.event_date)-2013)+month(wl.event_date) as months
		,count(distinct wl.session_id) as logins
	from src.page_view as wl 
	join dm.professional_dimension pd
	on wl.user_id=pd.professional_user_account_id
	where wl.event_date>='2014-06-01'
	group by 1,2
	),
endorse as (	
	select pd.professional_id
	,12*(year(bpe.created_at)-2013)+month(bpe.created_at) as months
	,count (distinct bpe.id) endorses
	from src.barrister_professional_endorsement bpe
	join dm.professional_dimension pd
	on bpe.endorser_id=cast(pd.professional_user_account_id as int)
    where to_date(bpe.created_at)>='2014-06-01'
	group by 1,2
	),	
endorsed as (	
select pd.professional_id
,12*(year(bpe.created_at)-2013)+month(bpe.created_at) as months
,count (distinct bpe.id) endorseds
from src.barrister_professional_endorsement bpe
join dm.professional_dimension pd
on bpe.endorsee_id=cast(pd.professional_user_account_id as int)
where to_date(bpe.created_at)>='2014-06-01'
group by 1,2
),
answer as (	
	select pd.professional_id
        ,12*(year(ca.created_at)-2013)+month(ca.created_at) as months
		,count (distinct ca.id) answers
	from src.content_answer ca
	join dm.professional_dimension pd
	on ca.created_by=cast(pd.professional_user_account_id as int)
    where to_date(ca.created_at)>='2014-06-01'
	group by 1,2
   )
select grid.customer_id,grid.months
,sum(r.negativereviews) as negativereviews,sum(q.reviews)as reviews,sum(login.logins) as logins
,sum(endorse.endorses)as endorses,sum(endorsed.endorseds)as endorseds,sum(answer.answers) as answers
from grid
left join r
on grid.professional_id=r.professional_id and grid.months=r.months
left join q
on grid.professional_id=q.professional_id and grid.months=q.months
left join login
on grid.professional_id=login.professional_id and grid.months=login.months
left join endorse
on grid.professional_id=endorse.professional_id and grid.months=endorse.months
left join endorsed
on grid.professional_id=endorsed.professional_id and grid.months=endorsed.months
left join answer
on grid.professional_id=answer.professional_id and grid.months=answer.months
group by 1,2
order by 1,2
)

select a.customer_id,a.months
	,coalesce(nr.negativereviews,0)as negativereviews,coalesce(nr1.negativereviews,0) as negativereviews_1
	,coalesce(nr2.negativereviews,0) as negativereviews_2,coalesce(nr3.negativereviews,0) as negativereviews_3
	,coalesce(nr.reviews,0)as reviews,coalesce(nr1.reviews,0) as reviews_1
	,coalesce(nr2.reviews,0) as reviews_2,coalesce(nr3.reviews,0) as reviews_3
	,coalesce(nr.logins,0)as logins,coalesce(nr1.logins,0) as logins_1
	,coalesce(nr2.logins,0) as logins_2,coalesce(nr3.logins,0) as logins_3
	,coalesce(nr.endorses,0)as endorses,coalesce(nr1.endorses,0) as endorses_1
	,coalesce(nr2.endorses,0) as endorses_2,coalesce(nr3.endorses,0) as endorses_3
	,coalesce(nr.endorseds,0)as endorseds,coalesce(nr1.endorseds,0) as endorseds_1
	,coalesce(nr2.endorseds,0) as endorseds_2,coalesce(nr3.endorseds,0) as endorseds_3
	,coalesce(nr.answers,0)as answers,coalesce(nr1.answers,0) as answers_1
	,coalesce(nr2.answers,0) as answers_2,coalesce(nr3.answers,0) as answers_3
from activemonth a 
left join activities as nr
on a.customer_id=nr.customer_id and a.months=nr.months
left join activities as nr1
on a.customer_id=nr1.customer_id and a.months-1=nr1.months
left join activities as nr2
on a.customer_id=nr2.customer_id and a.months-2=nr2.months
left join activities as nr3
on a.customer_id=nr3.customer_id and a.months-3=nr3.months
where a.months>=18
order by 1,2