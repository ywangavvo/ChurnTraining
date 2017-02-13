mrr=mrr[order(customer_id,yearmonth),]
excl=unique(mrr[customer_category=="NO ACTIVITY",customer_id])
mrr[,months:=12*((yearmonth-yearmonth%%100)/100-2013)+yearmonth%%100]

### Lagged MRR ###
mrr1<-rbind(mrr[,.(customer_id,months,mrr=mrr_current_month)],
            mrr[yearmonth==201511,.(customer_id,months=34,mrr=mrr_prior_month)])
setnames(mrr1,"mrr","mrr_1")
mrr2<-copy(mrr1)
setnames(mrr2,"mrr_1","mrr_2")
mrr3<-copy(mrr2)
setnames(mrr3,"mrr_2","mrr_3")
mrr1[,months:=months+1]
mrr2[,months:=months+2]
mrr3[,months:=months+3]
mrr_L<-merge(mrr[,.(customer_id,months)],mrr1,by=c("customer_id","months"),all.x=T)
mrr_L<-merge(mrr_L,mrr2,by=c("customer_id","months"),all.x=T)
mrr_L<-merge(mrr_L,mrr3,by=c("customer_id","months"),all.x=T)
# mrr<-merge(mrr,mrr1,by=c("customer_id","months"),all.x=T)
# mrr<-merge(mrr,mrr2,by=c("customer_id","months"),all.x=T)
# mrr<-merge(mrr,mrr3,by=c("customer_id","months"),all.x=T)

### Other Variables ###
mrr[,j:=1:.N,by=customer_id]
mrr[,sec:=j-months]
mrr[,nobs:=.N,by=c("customer_id","sec")]
mrr[,id:=paste(customer_id,"_",yearmonth,sep="")]
#Calculated fields
#mrr[,c("mrr_1","mrr_2","mrr_3"):=NULL]
# mrr[,lag1month:=months-shift(months,1,type="lag"),by=customer_id]
# mrr[,lag2month:=months-shift(months,2,type="lag"),by=customer_id]
# mrr[,lag3month:=months-shift(months,3,type="lag"),by=customer_id]
# mrr[,mrr_1:=shift(mrr_current_month,1,type="lag"),by=customer_id]
# mrr[,mrr_2:=shift(mrr_current_month,2,type="lag"),by=customer_id]
# mrr[,mrr_3:=shift(mrr_current_month,3,type="lag"),by=customer_id]
# mrr[lag1month!=1,mrr_1:=NA]
# mrr[lag2month!=2,mrr_2:=NA]
# mrr[lag3month!=3,mrr_3:=NA]

# mrr<-cbind(mrr[,!names(mrr)%in%c("mrr_1","mrr_2","mrr_3"),with=F],
#            mrr[,lapply(.SD,function(x){ifelse(is.na(x),0,x)}),.SDcols=c("mrr_1","mrr_2","mrr_3")])
mrr[,dollarchange:=mrr_current_month-mrr_prior_month]
mrr[,percentchange:=(mrr_current_month-mrr_prior_month)/mrr_prior_month]

mrr[,avgmrr:=mean(mrr_prior_month),by=customer_id]
mrr[,size:="Medium"]
mrr[avgmrr>=2000,size:="Big"]
mrr[avgmrr<100,size:="Tiny"]
mrr[avgmrr<300&avgmrr>=100,size:="Small"]

dat=merge(dat1,dat2,by=c("customer_id","months"),all.x=TRUE)
dat=merge(dat,dat3,by=c("customer_id","months"),all.x=TRUE)
dat=merge(dat,dat4,by=c("customer_id","months"),all.x=TRUE)
dat=merge(dat,dat5,by=c("customer_id","months"),all.x=TRUE)
dat=merge(dat,dat6,by=c("customer_id","months"),all.x=TRUE)
dat=merge(dat,v2,by=c("customer_id","months"),all.x=TRUE)
dat=merge(dat,dat7,by=c("customer_id","months"),all.x=TRUE)
dat<-merge(dat,offshore,by=c("customer_id","yearmonth"),all.x=T)
dat<-dat[order(customer_id,months),]

setnames(dat,"creditcard_expirationday_3","cc_3")
setnames(dat,"creditcard_expirationday_2","cc_2")
setnames(dat,"creditcard_expirationday_1","cc_1")
setnames(dat,"creditcard_expirationday","cc")

dat[,BothAd:=1*(ad_type_1==9)]
dat[is.na(BothAd),BothAd:=0]
dat[,months_since_claim:=months-claim_month]
dat[,months_since_first_order:=months-lifestart]
dat[,months_since_lastnegreview:=months-months_last_negreview_1]
dat[is.na(months_since_lastnegreview),months_since_lastnegreview:=72]
dat[,cc:=12*(round(cc/100)-2013)+cc%%100]
dat[,cc_1:=12*(round(cc_1/100)-2013)+cc_1%%100]
dat[,cc_2:=12*(round(cc_2/100)-2013)+cc_2%%100]
dat[,cc_3:=12*(round(cc_3/100)-2013)+cc_3%%100]
dat[,ccexp0:=1*(cc_1==months)] #Expires this month
dat[,ccexp_1:=1*(cc_1==(months-1))] #Expires 1 month ago
dat[,ccexp_2:=1*(cc_1==(months-2))] #Expires 2 month ago
dat[,ccexp_3:=1*(cc_1==(months-3))] #Expires 3 month ago
dat[,ccexp1:=1*(cc_1==(months+1))] #Expires next month
dat[,ccexp2:=1*(cc_1==(months+2))] #Expires in two months
dat[,ccexp3:=1*(cc_1==(months+3))] #Expires in three months
dat[is.na(ccexp0),ccexp0:=0]
dat[is.na(ccexp1),ccexp1:=0]
dat[is.na(ccexp2),ccexp2:=0]
dat[is.na(ccexp_1),ccexp_1:=0]
dat[is.na(ccexp_2),ccexp_2:=0]
dat[,ccexp:=1*(cc_1>=(months-2)&cc_1<=(months+2))]
dat[is.na(ccexp),ccexp:=0]

MonthDmy(dat)

dat[,avvo_rating_change:=avvo_rating_1-avvo_rating_3]
dat[is.na(avvo_rating_change),avvo_rating_change:=0]
dat[,avvo_rating_lastmonth:="Unknown"]
dat[avvo_rating_1<6.5,avvo_rating_lastmonth:="LT6.5"]
dat[avvo_rating_1>=6.5&avvo_rating_1<7,avvo_rating_lastmonth:="GE6.5LT7.0"]
dat[avvo_rating_1>=7&avvo_rating_1<8,avvo_rating_lastmonth:="GE7.0LT8.0"]
dat[avvo_rating_1>=8&avvo_rating_1<9,avvo_rating_lastmonth:="GE8.0LT9.0"]
dat[avvo_rating_1>=9&avvo_rating_1<10,avvo_rating_lastmonth:="GE9.0LT10.0"]
dat[avvo_rating_1==10,avvo_rating_lastmonth:="Equal10.0"]
dat$avvo_rating_lastmonth<-as.factor(dat$avvo_rating_lastmonth)
dat<-within(dat,avvo_rating_lastmonth<-relevel(avvo_rating_lastmonth,ref="Equal10.0"))

dat[,PPA:="Other"]
dat[parent_practice_area=="Personal Injury",PPA:="Personal Injury"]
dat[parent_practice_area=="Criminal Defense",PPA:="Criminal Defense"]
dat[parent_practice_area=="Family",PPA:="Family"]
dat[parent_practice_area=="Employment & Labor",PPA:="Employment & Labor"]
dat[parent_practice_area=="Real Estate",PPA:="Real Estate"]
dat[parent_practice_area=="Business",PPA:="Business"]
dat$PPA<-as.factor(dat$PPA)
dat<-within(dat,PPA<-relevel(PPA,ref="Other"))
dat[,New:=(activemonth<=12)*1]
dat[,CriminalDefense:=ifelse(parent_practice_area=="Criminal Defense",1,0)]
dat[,PersonalInjury:=ifelse(parent_practice_area=="Personal Injury",1,0)]
dat[,Family:=ifelse(parent_practice_area=="Family",1,0)]
dat[,Business:=ifelse(parent_practice_area=="Business",1,0)]

### Create sum, mean, and value
#1.Turn negatives to 0s
x<-c("spend","spend_1","spend_2","spend_3","spend_block","spend_block_1","spend_block_2","spend_block_3")
dat<-cbind(dat[,.SD,.SDcols=!names(dat)%in%x],
           dat[,lapply(.SD,function(x){ifelse(x<0,0,x)}),.SDcols=x])
dat[,lapply(.SD,summary),.SDcols=x]

SumList<-unlist(strsplit(names(dat)[grep("_3",names(dat))],'_3'))
SumList<-SumList[!SumList %in% c("ad_type","avvo_rating","ls_participation","cc")]
dat[,grep("sum_",colnames(dat)):=NULL]
for(i in 1:length(SumList)){
  dat$x<-Prior3sum(SumList[i])
  setnames(dat,"x",paste("sum_",SumList[i],sep=""))
}

dat[,grep("mean_",colnames(dat)):=NULL]
for(i in 1:length(MeanList)){
  dat$x<-Prior3mean(MeanList[i])
  setnames(dat,"x",paste("mean_",MeanList[i],sep=""))
}

dat[,grep("value_",colnames(dat)):=NULL]
for(i in 1:length(ValueList)){
  dat$x<-Prior3value(ValueList[i])
  setnames(dat,"x",paste("value_",ValueList[i],sep=""))
}

dat[,pct_spendblock:=sum_spend_block/sum_spend]
dat[,pct_spend_change:=(spend_1-spend_3)/spend_3]
dat[is.na(pct_spend_change)|is.infinite(pct_spend_change),pct_spend_change:=0]
dat[,BlockOnly:=1*(pct_spendblock>=1)]
dat[,anysoldoutmarkets:=1*sum_soldout_markets>0]
dat[,pct_soldoutmarkets:=sum_soldout_markets/sum_markets]
dat[is.na(pct_soldoutmarkets),pct_soldoutmarkets:=0]
dat[,pct_soldoutmarkets_mrr:=sum_mrr_soldout_markets/sum_mrr]
dat[is.na(pct_soldoutmarkets_mrr),pct_soldoutmarkets_mrr:=0]
dat[,pct_networkimps:=sum_network_imps/sum_imps]
dat[,pct_brandimps:=sum_brand_imps/sum_imps]
dat[,pct_adblockimps:=sum_adblock_imps/sum_imps]
#dat[,pct_targetimps:=sum_block_imps/sum_target_imps]
dat[,pct_targetacv:=sum_block_acv/sum_target_acv]
dat[,pct_promo_subscription:=sum_total_promo_subscription/sum_total_subscription]
dat[,pct_promo_mrr:=sum_promo_mrr/sum_mrr]

dat[is.na(pct_promo_mrr)|is.nan(pct_promo_mrr),pct_promo_mrr:=0]
dat[is.na(pct_networkimps),pct_networkimps:=0]
dat[is.na(pct_brandimps),pct_brandimps:=0]
dat[is.na(pct_adblockimps),pct_adblockimps:=0]
dat[,sum_contacts:=rowSums(cbind(sum_emails,sum_websites,sum_calls),na.rm=T)]
dat[,sum_negativereviews_ge1:=1*(sum_negativereviews>=1)]
dat[,sum_reviews_ge1:=1*(sum_reviews>=1)]
dat[,sum_logins_ge1:=1*(sum_logins>=1)]
dat[,logsumlogins:=log(1+sum_logins)]
dat[,sum_endorses_ge1:=1*(sum_endorses>=1)]
dat[,sum_endorseds_ge1:=1*(sum_endorseds>=1)]
dat[,sum_answers_ge1:=1*(sum_answers>=1)]
dat[,sum_emails2am_ge1:=1*(sum_emails2am>=1)]
dat[,sum_calls2am_ge1:=1*(sum_calls2am>=1)]
dat[,sum_failed_payments_ge1:=1*(sum_failed_payments>0)]

dat[sum_target_acv==0|pct_targetacv==0,pct_targetacv_dmy:="Exclusive"]
dat[pct_targetacv>0&pct_targetacv<=1,pct_targetacv_dmy:="<100%"]
dat[pct_targetacv>=1&pct_targetacv<2,pct_targetacv_dmy:="[100%,200%)"]
dat[pct_targetacv>=2&pct_targetacv<3,pct_targetacv_dmy:="[200%,300%)"]
dat[pct_targetacv>=3,pct_targetacv_dmy:=">=300%"]
dat$pct_targetacv_dmy<-as.factor(dat$pct_targetacv_dmy)
dat<-within(dat,pct_targetacv_dmy<-relevel(pct_targetacv_dmy,ref="Exclusive"))
dat[,NotExclusiveOnly:=1*(sum_target_acv>0)]
dat[is.na(pct_targetacv)|is.infinite(pct_targetacv),pct_targetacv:=0]

dat[,c("mrr_1","mrr_2","mrr_3","mrr","pct_promo_mrr","sum_mrr"):=NULL]
dat<-merge(dat,mrr[,.(customer_id,yearmonth,customer_category,avgmrr,size,mrr_current_month)],
           by=c("customer_id","yearmonth"),all.y=T)
dat<-merge(dat,mrr_L,by=c("customer_id","months"),all.x=T)
dat[,sum_mrr:=rowSums(cbind(mrr_1,mrr_2,mrr_3),na.rm=T)]
dat[,pct_promo_mrr:=sum_promo_mrr/sum_mrr]
dat[,logavgmrr:=log(1+avgmrr)]

dat[,pct_mrr_change:=(mrr_1-mrr_3)/mrr_3]
dat[is.na(mrr_3),pct_mrr_change:=(mrr_1-mrr_2)/mrr_2]
dat[,mrr_increased:=1*(pct_mrr_change>=0.05)]
dat[is.na(mrr_increased),mrr_increased:=0]
dat[,mrr_decreased:=1*(pct_mrr_change<=-0.05)]
dat[is.na(mrr_decreased),mrr_decreased:=0]
dat[is.na(pct_mrr_change),pct_mrr_change:=0]
dat[is.infinite(pct_mrr_change),pct_mrr_change:=99]

# dat[,pct_mrr_change_factor:="Inf"]
# dat[abs(pct_mrr_change)<0.05,pct_mrr_change_factor:="Unchanged"]
# dat[pct_mrr_change>=0.05,pct_mrr_change_factor:="Increased"]
# dat[pct_mrr_change<=-0.05,pct_mrr_change_factor:="Decreased"]
# dat$pct_mrr_change_factor<-as.factor(dat$pct_mrr_change_factor)
# dat<-within(dat,pct_mrr_change_factor<-relevel(pct_mrr_change_factor,ref="Unchanged"))
# dat[is.infinite(pct_mrr_change),pct_mrr_change:=99]
# dat[,mrr_unchanged:=1*(abs(pct_mrr_change)<0.05)]

dat[,churned:=1*(customer_category=="CHURNED")]
dat[,Big:=1*(size=="Big")]
dat[,Medium:=1*(size=="Medium")]
dat[,Small:=1*(size=="Small")]
dat[,Tiny:=1*(size=="Tiny")]
dat[,training:=runif(nrow(dat))]
dat<-dat[!customer_id%in% excl,]
dat[,churned:=1*(customer_category=="CHURNED")]

## Define churned using both revenue table and mrr table
# Churn<-dat1[,.(customer_id,yearmonth,months,sect,activemonth)]
# Churn[,churned:=0]
# Churn[,maxmonth:=max(activemonth),by=c("customer_id","sect")]
# Churn[activemonth==maxmonth&yearmonth<201608,churned:=1]
# tmp<-rbind(Churn[yearmonth<201511,.(customer_id,yearmonth,churned)],
#            mrr[,.(customer_id,yearmonth,churned=1*(customer_category=="CHURNED"))])
# dat<-merge(dat[yearmonth<201608,],tmp,by=c("customer_id","yearmonth"),all.x=T)

### Estimation Data for quarter model ###
#
# AggDat<-dat[months==s1months-2,]
# AggDat[,churned:=NULL]
# Churned<-dat[months %between% c(s1months-2,s1months),.(churned=sum(churned,na.rm=T)),by=c("customer_id")]
# MonthList<-unlist(names(dat)[grep("Month",names(dat))])
# AggDat[,c(MonthList):=NULL]
# Month<-dat[months>=(s1months-2)&months<=(s1months),lapply(.SD,sum),by=c("customer_id"),.SDcols=MonthList]
# Month<-Month[,lapply(.SD,function(x){ifelse(x>1,1,x)}),by=customer_id,.SDcols=MonthList]
# AggDat<-merge(AggDat,Churned,by=c("customer_id"),all.x=T)
# AggDat[,churned:=1*(churned>=1)]
# AggDat<-merge(AggDat,Month,by=c("customer_id"))
# AggDat[,training:=runif(nrow(AggDat))]

AggDat<-copy(dat)
MonthList<-unlist(names(AggDat)[grep("Month",names(AggDat))])
Post3sum(AggDat,c("churned",MonthList))
Onesify(AggDat,c("churned",MonthList))
# Agg<-AggDat[months %between% c(s1months-datamonths_Q-2,s1months-3),] # For Out of Time Training later on
# Agg_V<-AggDat[months==s1months-2,] # For Out of Time Validation later on
# AggDat<-AggDat[months %between% c(s1months-datamonths_Q-1,s1months-2),]
