with activemonth as (
 with tmp as (
  select *
	,months-row_number()over(partition by customer_id order by months) sect
  from (
	select customer_id
	,100*year(order_line_begin_date)+month(order_line_begin_date) as yearmonth
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	,sum(block_count)*100 as target_imps
	,sum(order_line_package_price_amount_usd*block_count) as target_acv
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2,3) a	
  )	
  select d.customer_id,d.yearmonth,d.months,d.sect
    ,d.months-b.sect_min+1 as activemonth
	,lifestart,d.target_imps,d.target_acv
  from tmp as d
  left join (
    select customer_id,sect,min(months) as sect_min
    from tmp
    group by 1,2) b
  on d.customer_id=b.customer_id and d.sect=b.sect
  left join (
    select customer_id,min(months) as lifestart
    from tmp
    group by 1) c
  on d.customer_id=c.customer_id
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

ad as (
	select c.customer_id,c.months,sum(c.product_line_id) as ad_type
    from (
	select customer_id,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months,product_line_id
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and year(order_line_payment_date) IS NOT NULL
	and year(order_line_payment_date) <> 1900
	group by 1,2,3) c
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
 
attributed_contacts as (
select customer_id
  ,12*(year(attribution_date)-2013)+month(attribution_date) as months
  ,sum(email_attributed_count) as attributed_emails
  ,sum(website_attributed_count)+sum(ad_click_count) as attributed_websites
  ,sum(phone_attributed_count) as attributed_calls
  ,sum(adjusted_attribution_value) as acv
from dm.webanalytics_ad_attribution_v0
where attribution_date>='2014-06-01'
group by 1,2),

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
	
block_acv as (
select customer_id,w.months,sum(acv) as block_acv  
from (
    select customer_id
    ,ad_market_id
    ,12*(year(attribution_date)-2013)+month(attribution_date) as months
    ,sum(adjusted_attribution_value) as acv
    from dm.webanalytics_ad_attribution_v0
	where attribution_date>='2014-06-01'
    group by 1,2,3) as w
join block as c
on w.ad_market_id=c.ad_market_id 
and w.months=c.months
and c.block=1
group by 1,2
order by 1,2
),

claim_month as (
with r as(
	select professional_id, min(12*(year(professional_claim_date)-2013)+month(professional_claim_date) )as claim_month
	from dm.historical_professional_dimension
	where professional_claim_date is not null
	and professional_id>0
	group by 1) 
select cp.customer_id,min(r.claim_month) as claim_month
from cust_prof as cp
left join r
on cp.professional_id=r.professional_id
group by 1)
 
select a.*
	,cm.claim_month
	,am1.target_imps as target_imps_1,am2.target_imps as target_imps_2,am3.target_imps as target_imps_3
	,am1.target_acv as target_acv_1, am2.target_acv as target_acv_2, am3.target_acv as target_acv_3
    ,ad.ad_type,ad1.ad_type as ad_type_1,ad2.ad_type as ad_type_2,ad3.ad_type as ad_type_3	
	,ac.acv,ac1.acv as acv_1,ac2.acv as acv_2,ac3.acv as acv_3
	,ac.attributed_emails as a_emails,ac1.attributed_emails as a_emails_1,ac2.attributed_emails as a_emails_2
	,ac3.attributed_emails as a_emails_3
	,ac.attributed_websites as a_websites,ac1.attributed_websites as a_websites_1,ac2.attributed_websites as a_websites_2
	,ac3.attributed_websites as a_websites_3	
	,ac.attributed_calls as a_calls,ac1.attributed_calls as a_calls_1,ac2.attributed_calls as a_calls_2
	,ac3.attributed_calls as a_calls_3
	,ba.block_acv,ba1.block_acv as block_acv_1,ba2.block_acv as block_acv_2,ba3.block_acv as block_acv_3
from activemonth a 
left join claim_month cm
on a.customer_id=cm.customer_id
left join activemonth as am1 
on a.customer_id=am1.customer_id and a.months-1=am1.months
left join activemonth as am2 
on a.customer_id=am2.customer_id and a.months-2=am2.months
left join activemonth as am3 
on a.customer_id=am3.customer_id and a.months-3=am3.months

left join ad 
on a.customer_id=ad.customer_id and a.months=ad.months
left join ad as ad1 
on a.customer_id=ad1.customer_id and a.months-1=ad1.months
left join ad as ad2 
on a.customer_id=ad2.customer_id and a.months-2=ad2.months
left join ad as ad3 
on a.customer_id=ad3.customer_id and a.months-3=ad3.months

left join attributed_contacts as ac
on a.customer_id=ac.customer_id and a.months=ac.months
left join attributed_contacts as ac1
on a.customer_id=ac1.customer_id and a.months-1=ac1.months
left join attributed_contacts as ac2
on a.customer_id=ac2.customer_id and a.months-2=ac2.months
left join attributed_contacts as ac3
on a.customer_id=ac3.customer_id and a.months-3=ac3.months

left join block_acv as ba 
on a.customer_id=ba.customer_id and a.months=ba.months
left join block_acv as ba1 
on a.customer_id=ba1.customer_id and a.months-1=ba1.months
left join block_acv as ba2 
on a.customer_id=ba2.customer_id and a.months-2=ba2.months
left join block_acv as ba3 
on a.customer_id=ba3.customer_id and a.months-3=ba3.months

where a.months>=18
order by 1,2