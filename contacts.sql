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
	 
contacts as (
with c as (
 select professional_id,months,emails,websites,calls,calls_180s,calls_120s,calls_60s,call_tcu
 from (
 select professional_id, 12*(year(event_date)-2013)+month(event_date) as months
            ,count(case when contact_type='email' then 'email' end) as emails
            ,count(case when contact_type='website' then 'website' end) as websites
            ,count(case when contact_type='phone' then 'phone' end) as calls
			,count(case when duration>=180 then 'phone' end) as calls_180s
			,count(case when duration>=120 then 'phone' end) as calls_120s
			,count(case when duration>=60 then 'phone' end) as calls_60s
			,sum(case when duration<15 then 1
                      when duration between 15 and 44 then 2 
                      when duration between 45 and 119 then 3
                      when duration between 120 and 299 then 7
                      when duration >= 300 then 10
					  else 0 end) as call_tcu
  from src.contact_impression 
  where event_date>='2014-06-01'
  group by 1,2
   ) a
   )

select cp.customer_id,cp.months,sum(c.emails)as emails,sum(c.websites)as websites
  ,sum(c.calls)as calls,sum(c.calls_180s)as calls_180s,sum(c.calls_120s)as calls_120s,sum(c.calls_60s)as calls_60s,sum(c.call_tcu)as call_tcu
from cust_prof as cp
join c
on cp.professional_id=c.professional_id and cp.months=c.months
group by 1,2
),

impressions as (
  select b.customer_id
         ,12*(year(a.event_date)-2013)+month(a.event_date) as months
         ,sum(a.impressions) as imps
  from ( 
    select ad_id,event_date,count(distinct ad_impression_guid) as impressions  
    from src.ad_impression
    where event_date>='2014-06-01'
    group by 1,2) a 
  left join dm.historical_ad_customer_professional_map b
  on a.ad_id=b.ad_id
  and a.event_date>=b.etl_effective_begin_date
  and a.event_date<=b.etl_effective_end_date
  group by 1,2
)

select a.customer_id,a.months
	,c.emails,c1.emails as emails_1,c2.emails as emails_2,c3.emails as emails_3
	,c.websites,c1.websites as websites_1,c2.websites as websites_2,c3.websites as websites_3
	,c.calls,c1.calls as calls_1,c2.calls as calls_2,c3.calls as calls_3
	,c.calls_180s,c1.calls_180s as calls_180s_1,c2.calls_180s as calls_180s_2,c3.calls_180s as calls_180s_3
	,c.calls_120s,c1.calls_120s as calls_120s_1,c2.calls_120s as calls_120s_2,c3.calls_120s as calls_120s_3
    ,c.calls_60s,c1.calls_180s as calls_60s_1,c2.calls_60s as calls_60s_2,c3.calls_60s as calls_60s_3
	,c.call_tcu,c1.call_tcu as call_tcu_1,c2.call_tcu as call_tcu_2,c3.call_tcu as call_tcu_3
	,imps.imps,imps1.imps as imps_1,imps2.imps as imps_2,imps3.imps as imps_3
from activemonth a 
left join contacts as c
on a.customer_id=c.customer_id and a.months=c.months
left join contacts as c1
on a.customer_id=c1.customer_id and a.months-1=c1.months
left join contacts as c2
on a.customer_id=c2.customer_id and a.months-2=c2.months
left join contacts as c3
on a.customer_id=c3.customer_id and a.months-3=c3.months
left join impressions as imps
on a.customer_id=imps.customer_id and a.months=imps.months
left join impressions as imps1
on a.customer_id=imps1.customer_id and a.months-1=imps1.months
left join impressions as imps2
on a.customer_id=imps2.customer_id and a.months-2=imps2.months
left join impressions as imps3
on a.customer_id=imps3.customer_id and a.months-3=imps3.months
where a.months>=18
order by 1,2