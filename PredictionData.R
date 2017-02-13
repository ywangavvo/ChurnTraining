insample<-dat[months==s1months&sum_spend>0&is.na(avvo_rating)==0&
                !customer_category %in% c("CHURNED"),]
outsample<-copy(insample)

#### Data Transformation ####
outsample[,BothAd:=1*(ad_type==9)]
outsample[is.na(BothAd),BothAd:=0]
outsample[,months:=months+1]
outsample[,yearmonth:=yearmonth+1]
outsample[,activemonth:=activemonth+1]
MonthDmy(outsample)
outsample[,New:=(activemonth<=12)*1]
outsample[,months_since_claim:=months_since_claim+1]
outsample[,months_since_lastnegreview:=months-months_last_negreview]
outsample[is.na(months_since_lastnegreview),months_since_lastnegreview:=72]
outsample[,months_since_first_order:=months-lifestart]
outsample[,ls_participation_1:=ls_participation]

outsample[,mrr_3:=mrr_2]
outsample[,mrr_2:=mrr_1]
outsample[,mrr_1:=mrr_current_month]
outsample[,pct_mrr_change:=(mrr_1-mrr_3)/mrr_3]
outsample[is.na(mrr_3),pct_mrr_change:=(mrr_1-mrr_2)/mrr_2]
outsample[,mrr_increased:=1*(pct_mrr_change>=0.05)]
outsample[is.na(mrr_increased),mrr_increased:=0]
outsample[,mrr_decreased:=1*(pct_mrr_change<=-0.05)]
outsample[is.na(mrr_decreased),mrr_decreased:=0]
outsample[is.na(pct_mrr_change),pct_mrr_change:=0]
outsample[is.infinite(pct_mrr_change),pct_mrr_change:=99]

outsample[,avvo_rating_1:=avvo_rating]
outsample[,avvo_rating_change:=avvo_rating-avvo_rating_2]
outsample[is.na(avvo_rating_change),avvo_rating_change:=0]
outsample[,ccexp0:=1*(cc==months)] #Expires this month
outsample[,ccexp_1:=1*(cc==(months-1))] #Expires 1 month ago
outsample[,ccexp_2:=1*(cc==(months-2))] #Expires 2 month ago
outsample[,ccexp1:=1*(cc==(months+1))] #Expires next month
outsample[,ccexp2:=1*(cc==(months+2))] #Expires in two months
outsample[is.na(ccexp0),ccexp0:=0]
outsample[is.na(ccexp1),ccexp1:=0]
outsample[is.na(ccexp2),ccexp2:=0]
outsample[is.na(ccexp_1),ccexp_1:=0]
outsample[is.na(ccexp_2),ccexp_2:=0]
outsample[,ccexp:=1*(cc>=(months-2)&cc<=(months+2))]
outsample[is.na(ccexp),ccexp:=0]

### Create sum, mean and value
outsample[,grep("sum_",colnames(outsample)):=NULL]
for(i in 1:length(SumList)){
  outsample$x<-Prior3sumP(SumList[i])
  setnames(outsample,"x",paste("sum_",SumList[i],sep=""))
}

outsample[,grep("mean_",colnames(outsample)):=NULL]
for(i in 1:length(MeanList)){
  outsample$x<-Prior3meanP(MeanList[i])
  setnames(outsample,"x",paste("mean_",MeanList[i],sep=""))
}

outsample[,grep("value_",colnames(outsample)):=NULL]
for(i in 1:length(ValueList)){
  outsample$x<-Prior3valueP(ValueList[i])
  setnames(outsample,"x",paste("value_",ValueList[i],sep=""))
}

### Other Variables
outsample[,pct_spendblock:=sum_spend_block/sum_spend]
outsample[,pct_spend_change:=(spend_1-spend_3)/spend_3]
outsample[is.na(pct_spend_change)|is.infinite(pct_spend_change),pct_spend_change:=0]
outsample[,BlockOnly:=1*(pct_spendblock>=1)]
outsample[,anysoldoutmarkets:=1*sum_soldout_markets>0]
outsample[,pct_soldoutmarkets:=sum_soldout_markets/sum_markets]
outsample[,pct_networkimps:=sum_network_imps/sum_imps]
outsample[,pct_brandimps:=sum_brand_imps/sum_imps]
outsample[,pct_adblockimps:=sum_adblock_imps/sum_imps]
#outsample[,pct_targetimps:=sum_block_imps/sum_target_imps]
outsample[,pct_targetacv:=sum_block_acv/sum_target_acv]
outsample[is.na(pct_targetacv)|is.infinite(pct_targetacv),pct_targetacv:=0]
outsample[,pct_promo_subscription:=sum_total_promo_subscription/sum_total_subscription]
outsample[,pct_promo_mrr:=sum_promo_mrr/sum_mrr]
outsample[,sum_contacts:=rowSums(cbind(sum_emails,sum_websites,sum_calls),na.rm=T)]
outsample[,sum_negativereviews_ge1:=1*(sum_negativereviews>=1)]
outsample[,sum_reviews_ge1:=1*(sum_reviews>=1)]
outsample[,sum_logins_ge1:=1*(sum_logins>=1)]
outsample[,logsumlogins:=log(1+sum_logins)]
outsample[,sum_endorses_ge1:=1*(sum_endorses>=1)]
outsample[,sum_endorseds_ge1:=1*(sum_endorseds>=1)]
outsample[,sum_answers_ge1:=1*(sum_answers>=1)]
outsample[,sum_emails2am_ge1:=1*(sum_emails2am>=1)]
outsample[,sum_calls2am_ge1:=1*(sum_calls2am>=1)]
outsample[,sum_failed_payments_ge1:=1*(sum_failed_payments>0)]

Demos<-outsample[,.(customer_id,PPA,mrr_1,activemonth,avvo_rating_1,avvo_rating_change,ccexp,value_acv,
        sum_calls_120s,sum_a_emails,sum_a_websites,sum_acv,
        sum_failed_payments,sum_calls2am,sum_emails2am,
        sum_logins,sum_answers,sum_reviews,sum_negativereviews,sum_endorses,sum_endorseds,
        pct_promo_mrr,pct_mrr_change,pct_soldoutmarkets,pct_targetacv,
        pct_brandimps,pct_adblockimps,pct_networkimps)]
colnames(Demos)<-c('customer_id',
       'Revenue based PPA',
       'MRR at risk',
       'N-th active month',
       'Avvo rating',
       'Avvo rating change in prior three months',
       'Credit card just expired or about to expire',
       'ROI (ACV divided by Ad Spending)',
       'Sum of calls greater than 120s in previous three months',
       'Sum of email ACVs in previous three months',
       'Sum of websites ACVs in previous three months',
       'Sum of ACVs in previous three months',
       'Counts of failed payments in previous three months',
       'Sum of inbound calls to AM in previous three months',
       'Sum of inbount emails to AM in previous three months',
       'Sum of logins in previous three months',
       'Sum of questions answered in previous three months',
       'Sum of consumer reviews in previous three months',
       'Sum of negative consumer reviews in previous three months',
       'sum of endorsements in previous three months',
       'Sum of times being endorsed in previous three months',
       '% MRR on Promotion',
       '% Change in MRR',
       'Soldout ad markets as a % of total Number of ad markets',
       'Delivered Block ACV as % of Target Block ACV ',
       'Brand SEM Impressions as a % of Impressions',
       'SEM Adblock Impressions as a % of Impressions',
       'SEM Network Impressions as a % of Impressions')


### Data for Quarter Model Prediction
# AggDat<-copy(outsample)
# MonthList<-unlist(names(dat)[grep("Month",names(dat))])
# AggDat[,c(MonthList):=NULL]
#
# Month1<-outsample[,.(customer_id,activemonth)]
# MonthDmy(Month1)
# Month2<-outsample[,.(customer_id,activemonth=activemonth+1L)]
# MonthDmy(Month2)
# Month3<-outsample[,.(customer_id,activemonth=activemonth+2L)]
# MonthDmy(Month3)
# Month=Month1[,.SD,.SDcols=MonthList]+Month2[,.SD,.SDcols=MonthList]+Month3[,.SD,.SDcols=MonthList]
# Month<-Month[,lapply(.SD,function(x){ifelse(x>1,1,x)}),.SDcols=MonthList]
# AggDat<-cbind(AggDat,Month)

