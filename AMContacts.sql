with activemonth as (
	select customer_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2
),

Contact_AM as (
select customer_id,12*(year(activitydate)-2013)+month(activitydate) as months,
count(case when subject like '%Email: RE%' or subject like '%Email:RE%' then 1 end) as Emails2AM,
count(case when subject like '%Incoming Call - Sales%' then 1 end) as Calls2AM
from hist_sf_tasks
where assigned_role="Account Manager"
group by 1,2
order by 1,2
)

select a.customer_id,a.months
,c.Emails2AM,c1.Emails2AM as Emails2AM_1,c2.Emails2AM as Emails2AM_2,c3.Emails2AM as Emails2AM_3
,c.Calls2AM,c1.Calls2AM as Calls2AM_1,c2.Calls2AM as Calls2AM_2,c3.Calls2AM as Calls2AM_3
from activemonth a 
left join Contact_AM as c
on a.customer_id=c.customer_id and a.months=c.months
left join Contact_AM as c1
on a.customer_id=c1.customer_id and a.months-1=c1.months
left join Contact_AM as c2
on a.customer_id=c2.customer_id and a.months-2=c2.months
left join Contact_AM as c3
on a.customer_id=c3.customer_id and a.months-3=c3.months
where a.months>=18
order by 1,2