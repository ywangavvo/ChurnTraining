create table tmp_data_dm.yw_imp as (
	select hacpm.customer_id
	,12*(year(g.event_date)-2013)+month(g.event_date) as months
	   -- ,sum(g.imps) as imps
	   -- ,sum(CASE g.medium WHEN 'sem' THEN g.imps else 0 END) AS sem_imps
	   ,sum(CASE g.medium WHEN 'nonsem' THEN g.imps else 0 END) AS nonsem_imps
  	   ,sum(CASE g.medium WHEN 'brand' THEN g.imps else 0 END) AS brand_imps
   	   ,sum(CASE g.medium WHEN 'pls' THEN g.imps else 0 END) AS pls_imps
       ,sum(CASE g.medium WHEN 'adblock' THEN g.imps else 0 END) AS adblock_imps
       ,sum(CASE g.medium WHEN 'network' THEN g.imps else 0 END) AS network_imps
	from (
		select a.ad_id, a.event_date,b.medium
		 ,count(distinct a.ad_impression_guid) as imps
		from (select ai.ad_id,ai.event_date,ai.ad_impression_guid
			,pv.session_id
			from src.ad_impression ai
			join src.ad_request ar
			on ai.ad_request_guid=ar.ad_request_guid and ai.event_date=ar.event_date
			join src.page_view pv
			on ar.render_instance_guid=pv.render_instance_guid and ar.event_date=pv.event_date
			WHERE pv.session_id IS NOT NULL 
			AND pv.persistent_session_id IS NOT NULL
			AND pv.render_instance_guid IS NOT NULL
			and pv.event_date between '2014-06-01' and '2016-08-31'
			and ai.event_date between '2014-06-01' and '2016-08-31'
			and ar.event_date between '2014-06-01' and '2016-08-31') a
		join (
			select event_date,session_id,medium
			from (
				select event_date,session_id
-- 					,CASE WHEN regexp_extract(url, 'utm_medium=(\\w|%)*', 0) = 'utm_medium=sem' THEN 'sem'
-- 						ELSE 'nonsem' END AS medium
                    ,case when url like '%utm_campaign=brand%' then 'brand'              
                         when url like '%utm_campaign=pls%'  then 'pls'
                          when url like '%utm_content=sgt%' then 'network'
                          when url like '%utm_campaign=adblock%' then 'adblock'
                          else 'nonsem' end as medium            
					,row_number() OVER (PARTITION BY session_id ORDER BY gmt_timestamp ASC) rankNum
				from src.page_view
				WHERE session_id IS NOT NULL 
				AND persistent_session_id IS NOT NULL
				AND render_instance_guid IS NOT NULL
				and event_date between '2014-06-01' and '2016-08-31') c
			where rankNum=1) b
		on a.session_id=b.session_id
		and a.event_date=b.event_date
		group by 1,2,3
		order by 1,2,3
		)g 
	join dm.historical_ad_customer_professional_map hacpm
	on g.ad_id=hacpm.ad_id
	and g.event_date>=hacpm.etl_effective_begin_date
	and g.event_date<=hacpm.etl_effective_end_date
-- 	where hacpm.professional_id!=-1
	group by 1,2
	order by 1,2
  )
  
create table tmp_data_dm.yw_imp as
SELECT *
FROM tmp_data_dm.yw_imp
UNION
SELECT *
FROM tmp_data_dm.yw_imp0
UNION
SELECT *
FROM tmp_data_dm.yw_imp3