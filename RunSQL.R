#############################
### Executing SQL Scripts ###
#############################
chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste("select * from dm.mrr_customer_classification",collapse=' ')))
mrr=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/attr_contacts.sql",sep="")),collapse=' ')))
dat1=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

# chim=odbcConnect('Impala','ywang','#')
# query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/block_imps.sql",sep="")),collapse=' ')))
# dat1=data.table(sqlQuery(chim,query,believeNRows=F))
# odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/contacts.sql",sep="")),collapse=' ')))
dat2=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/avvo_rating.sql",sep="")),collapse=' ')))
dat3=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/semimps.sql",sep="")),collapse=' ')))
dat4=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/months_last_negreview.sql",sep="")),collapse=' ')))
dat5=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/activity.sql",sep="")),collapse=' ')))
dat6=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/v2.sql",sep="")),collapse=' ')))
v2=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste(readLines(paste(path,"/AMContacts.sql",sep="")),collapse=' ')))
dat7=data.table(sqlQuery(chim,query,believeNRows=F))
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste("select customer_id,yearmonth,months_since_licensed
,ls_participation,ls_participation_1,ls_participation_2,ls_participation_3
,total_subscription ,total_subscription_1 ,total_subscription_2 ,total_subscription_3
,total_promo_subscription,total_promo_subscription_1,total_promo_subscription_2 ,total_promo_subscription_3
,promo_mrr,promo_mrr_1,promo_mrr_2,promo_mrr_3,mrr,mrr_1,mrr_2,mrr_3
,creditcard_expirationday,creditcard_expirationday_1,creditcard_expirationday_2,creditcard_expirationday_3
from tmp_data_src.customer_month_v2_metrics",collapse=' ')))
offshore=data.table(sqlQuery(chim,query,believeNRows=F)) #,rows_at_time = 1
odbcClose(chim)

chim=odbcConnect('Impala','ywang','#')
query=gsub('\t',' ',gsub('\n',' ',paste("select customer_id
,professional_id
,12*(year(order_line_begin_date)-2013)+month(order_line_begin_date) as months
from dm.order_line_accumulation_fact
where order_line_begin_date>='2013-01-01'
and professional_id!=-1
and product_line_id in (2,7)
group by 1,2,3",collapse=' ')))
cust_prof=data.table(sqlQuery(chim,query,believeNRows=F)) #,rows_at_time = 1
odbcClose(chim)
