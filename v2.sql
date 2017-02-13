with activemonth as (
	select customer_id
	,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
	from dm.order_line_accumulation_fact
	where order_line_begin_date>='2013-01-01'
	and product_line_id in (2,7)
	and order_line_net_price_amount_usd>0
	group by 1,2
),

monthly_spend as(
select customer_id
   ,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
   ,sum(order_line_net_price_amount_usd) as spend
   ,coalesce(sum(order_line_net_price_amount_usd*(block_count/block_count)),0) as spend_block
from dm.order_line_accumulation_fact
where order_line_begin_date>='2014-09-01'
and product_line_id in (2,7)
and year(order_line_payment_date) IS NOT NULL
and year(order_line_payment_date) <> 1900
group by 1,2
),

parent_practice_area as(
select customer_id, parent_specialty_name as parent_practice_area, spend as totalspend
from (
	select customer_id,sd.parent_specialty_name,sum(order_line_net_price_amount_usd) spend
  
    ,row_number() OVER (PARTITION BY customer_id ORDER BY sum(order_line_net_price_amount_usd) DESC) rankNum
  
	from dm.order_line_accumulation_fact olaf
	left join dm.order_line_ad_market_fact olamf 
	on olaf.order_line_number = olamf.order_line_number
	left join dm.ad_market_dimension amd
	on olamf.ad_market_id = amd.ad_market_id
	left join dm.specialty_dimension sd
	on amd.specialty_id=sd.specialty_id
	where olaf.order_line_begin_date>='2014-06-01'
	and year(order_line_payment_date) IS NOT NULL
	and year(order_line_payment_date) <> 1900
	and olaf.product_line_id in (2,7)
	group by 1,2
  ) a
where ranknum=1
),

/* soldout_market as
(
	select a.customer_id
		  ,a.months
          ,sum(case when mi.ad_unsold_value <= 0 then 1 else 0 end) soldout_markets
          ,count(*) markets
	from(
		select customer_id
			,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
			,ad_market_id
		from dm.order_line_accumulation_fact olaf
		left join dm.order_line_ad_market_fact olamf 
		on olaf.order_line_number = olamf.order_line_number
		where olaf.order_line_begin_date>='2014-06-01'
		group by 1,2,3) a
	left join dm.mi_ad_market_detail as mi
	on a.ad_market_id=mi.ad_market_id
	and a.months=12*(round(mi.year_month/100)-2013)+mi.year_month%100
    group by 1,2
	), */
	
soldout_market as
(
	select customer_id
		  ,12*(round(yearmonth/100)-2013)+yearmonth%100 as months
          ,sum(case when mi.ad_unsold_value <= 0 then 1 else 0 end) soldout_markets
          ,sum(case when mi.ad_unsold_value <= 0 then 1*mrr_current_month else 0 end) mrr_soldout_markets 
          ,count(*) markets		  
		from dm.mrr_market_classification as mmk
		join dm.mi_ad_market_detail as mi 
		on mmk.market_id = mi.ad_market_id
		and mmk.yearmonth = mi.year_month
		group by 1,2
    union
		select customer_id
		  ,34 as months
          ,sum(case when mi.ad_unsold_value <= 0 then 1 else 0 end) soldout_markets
          ,sum(case when mi.ad_unsold_value <= 0 then 1*mrr_prior_month else 0 end) mrr_soldout_markets 
          ,count(*) markets	
		from dm.mrr_market_classification as mmk
		join dm.mi_ad_market_detail as mi 
		on mmk.market_id = mi.ad_market_id
		and mmk.yearmonth = mi.year_month + 1
		where mmk.yearmonth=201511
		group by 1,2
	),	
	
	
Failed_Payments as
(select b.customer_id, 12*(year(a.created_at)-2013)+month(a.created_at) as months,count(*) as failed_payments
from src.nrt_payment_failure as a join src.nrt_invoice as b
on a.invoice_id=b.id
where year(a.created_at)<>1900
group by 1,2
order by 1,2
)
	
select a.customer_id,a.months,ppa.parent_practice_area,ppa.totalspend
       ,ms.spend,ms.spend_block
       ,ms1.spend as spend_1,ms1.spend_block as spend_block_1
       ,ms2.spend as spend_2,ms2.spend_block as spend_block_2
       ,ms3.spend as spend_3,ms3.spend_block as spend_block_3
	   ,sm.soldout_markets
	   ,sm1.soldout_markets as soldout_markets_1
	   ,sm2.soldout_markets as soldout_markets_2
	   ,sm3.soldout_markets as soldout_markets_3
	   ,sm.mrr_soldout_markets
	   ,sm1.mrr_soldout_markets as mrr_soldout_markets_1
	   ,sm2.mrr_soldout_markets as mrr_soldout_markets_2
	   ,sm3.mrr_soldout_markets as mrr_soldout_markets_3
	   ,sm.markets as markets
	   ,sm1.markets as markets_1
	   ,sm2.markets as markets_2
	   ,sm3.markets as markets_3
	   ,fp.failed_payments 
	   ,fp1.failed_payments as failed_payments_1
	   ,fp2.failed_payments as failed_payments_2
	   ,fp3.failed_payments as failed_payments_3
from activemonth as a
left join parent_practice_area as ppa
on a.customer_id=ppa.customer_id
left join monthly_spend as ms
on a.customer_id=ms.customer_id
and a.months=ms.months
left join monthly_spend as ms1
on a.customer_id=ms1.customer_id
and a.months-1=ms1.months
left join monthly_spend as ms2
on a.customer_id=ms2.customer_id
and a.months-2=ms2.months	  
left join monthly_spend as ms3
on a.customer_id=ms3.customer_id
and a.months-3=ms3.months 
left join soldout_market as sm
on a.customer_id=sm.customer_id
and a.months=sm.months
left join soldout_market as sm1
on a.customer_id=sm1.customer_id
and a.months-1=sm1.months
left join soldout_market as sm2
on a.customer_id=sm2.customer_id
and a.months-2=sm2.months	  
left join soldout_market as sm3
on a.customer_id=sm3.customer_id
and a.months-3=sm3.months 
left join failed_payments as fp
on a.customer_id=fp.customer_id
and a.months=fp.months 
left join failed_payments as fp1
on a.customer_id=fp1.customer_id
and a.months-1=fp1.months 
left join failed_payments as fp2
on a.customer_id=fp2.customer_id
and a.months-2=fp2.months 
left join failed_payments as fp3
on a.customer_id=fp3.customer_id
and a.months-3=fp3.months 
where a.months>=18
order by 1,2