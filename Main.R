path="C:/Users/ywang/Dropbox (Avvo, Inc.)/Analytics/Churn/Yantao/Run8"
setwd(path)
library(RODBC)
library(data.table)
library(ROCR)
source("functions.R")
######

########################
### Input Parameters ###
########################
DataSource = "EDW" # Either 'CSV' or 'EDW'
s1 = 201608 # This is the last yearmonth in the mrr_customer_classification table
s1months = 12*(round(s1/100)-2013)+s1%%100 # Calculated Fields
datamonths_M = 7  # Intended Number of observations for the Month model; Suggested: 1 to 3
datamonths_Q = 7  # Intended number of observations for the Quarter model; Suggested: 1 to 3
EffectList=c("Month","value_acv","value_a_emails","value_a_websites","calls_120s","creased",
  "avvo_rating","calls2am","emails2am","sum_failed_payments","ccexp",
  "logins","answers","endorses","reviews",
  "pct_brandimps","pct_adblockimps","pct_networkimps",
  "pct_spendblock","pct_targetacv",
  "pct_promo_mrr","pct_soldoutmarkets_mrr")
EffectName=c("N-th Active Month","ACV","Email ACV","Website ACV","Calls >= 120 seconds","Change in MRR",
  "Avvo Rating","Calls to AM","Emails to AM","Number of failed payments","Credit card just expired or about to expire",
  "Logins","Questions answered","Endorsements","Consumer Reviews",
  "SEM Brand Impressions as a % of Total Impressions","SEM Adblock Impressions as a % of Total Impressions",
  "SEM Network Impressions as a % of Total Impressions",
  "Block Revenue as a % of Total Revenue","Delivered Block ACV as a % of Target Block ACV",
  "% MRR on Promotion","% of MRR that are from Soldout Markets")
MeanList<-c("imps","emails","websites","calls","calls_60s","calls_120s")
ValueList<-c("imps","acv","a_emails","a_websites","a_calls")

MonthModel<-churned~#months_since_first_order+
  #ls_participation_1+months_since_lastnegreview+months_since_claim
  ccexp+sum_failed_payments+logavgmrr:activemonth+
  pct_targetacv+mrr_increased+mrr_decreased+pct_promo_mrr+pct_soldoutmarkets_mrr+
  #pct_brandimps+pct_adblockimps+pct_networkimps+
  #mean_calls_120s+value_a_websites+value_acv+value_a_emails+
  pct_spendblock+#pct_targetacv_dmy+
  Month_le3+Month4+Month5+Month6+Month7+Month8+Month9+Month10+Month11+Month12+Month_ge25+Month_gt36+
  avvo_rating_1+avvo_rating_change+# BothAd+
  sum_calls2am_ge1+ sum_emails2am_ge1+#sum_negativereviews_ge1+
  sum_endorses_ge1+sum_reviews_ge1+logsumlogins+# sum_logins_ge1+
  Family:value_acv+PersonalInjury:value_acv+ CriminalDefense:value_acv+#Business:value_acv+
  Big:value_acv+Medium:value_a_websites+Small:value_a_emails+Tiny:value_acv+
  Big:value_a_websites+Medium:value_a_websites+Small:value_a_websites+Tiny:value_a_websites+
  Big:mean_calls_120s+Medium:mean_calls_120s+Small:mean_calls_120s+Tiny:mean_calls_120s+
  #logsumlogins:value_a_websites+pct_spendblock:value_acv+pct_spendblock:value_a_calls+
  pct_spendblock:value_a_emails+sum_emails2am_ge1:logsumlogins+sum_calls2am_ge1:logsumlogins

QuarterModel<-churned~#months_since_lastnegreview+#months_since_first_order+
  ccexp+sum_failed_payments+ls_participation_1+#logavgmrr:activemonth+
  pct_targetacv+mrr_increased+mrr_decreased+pct_promo_mrr+pct_soldoutmarkets_mrr+
  pct_brandimps+pct_adblockimps+pct_networkimps+
  #value_a_websites+mean_calls_120s+value_acv+
  #Medium+Tiny+
  pct_spendblock+#pct_targetacv_dmy+
  activemonth+Month_le3+Month4+Month5+Month6+Month7+Month8+Month9+Month10+Month11+Month12+Month_ge25+Month_gt36+
  avvo_rating_1+BothAd+#avvo_rating_change+#
  sum_calls2am_ge1+sum_emails2am_ge1+#sum_negativereviews_ge1+
  sum_reviews_ge1+logsumlogins+#sum_answers_ge1+
  Family:value_acv+PersonalInjury:value_acv+ #CriminalDefense:value_acv+
  Family:mean_calls_120s+PersonalInjury:mean_calls_120s+CriminalDefense:mean_calls_120s+
  Family:value_a_websites+CriminalDefense:value_a_websites+#PersonalInjury:value_a_websites+
  Medium:value_acv+Big:value_acv+Small:value_acv+Tiny:value_acv+
  Medium:value_a_websites+Tiny:value_a_websites+Big:value_a_websites+Small:value_a_websites+
  Medium:mean_calls_120s+Tiny:mean_calls_120s+Small:mean_calls_120s+Big:mean_calls_120s

NeedOutSampleValidation<-1  # 1 for Yes; 0 for No
NeedOutTimeValidation<-1   # 1 for Yes; 0 for No
PrintOutSampleValidationModel_M<-1
PrintOutSampleValidationModel_Q<-1


####################
#### Input Data ####
####################
if (DataSource=="EDW") source("RunSQL.R")
if (DataSource=="CSV"){
  mrr=data.table(read.csv("mrr.csv",stringsAsFactors =F))
  v2=data.table(read.csv("v2.csv",stringsAsFactors =F))
  offshore=data.table(read.csv("offshore.csv",stringsAsFactors =F))
  for (i in 1:7){
    assign(paste("dat",i,sep=""),data.table(read.csv(paste("dat",i,".csv",sep=""),stringsAsFactors=F)))
  }
}


##########################################
#### Estimate Month and Quarter Model ####
##########################################
source("EstimationData.R")

logit_M<-glm(MonthModel
,data=dat[months %between% c(s1months-datamonths_M+1,s1months)&sum_spend>0&is.na(avvo_rating_1)==0&is.na(churned)==0,]
,family=binomial)
summary(logit_M)
pred=prediction(logit_M$fitted.values,logit_M$y)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Month Model AUC = ",round(auc,4),"\n")

logit_Q<-glm(QuarterModel
,data=AggDat[months %between% c(s1months-datamonths_Q-1,s1months-2)&sum_spend>0&is.na(avvo_rating_1)==0,]
,family=binomial
)
summary(logit_Q)
pred=prediction(logit_Q$fitted.values,logit_Q$y)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Quarter Model AUC = ",round(auc,4),"\n")


####################
#### Validation ####
####################
if (NeedOutSampleValidation==1) source("OutSampleValidation.R")
if (NeedOutTimeValidation==1) source("OutTimeValidation.R")


#####################################
#### Predict and Calc Importance ####
#####################################
source("PredictionData.R")
source("Importance.R")


############################
#### Output End Results ####
############################
write.csv(file=paste("ChurnScore",outsample$yearmonth[1],"_M.csv",sep=""),Out_M[order(ChurnRiskRank)],row.names = F)
write.csv(file=paste("ChurnScore",outsample$yearmonth[1],"_Q.csv",sep=""),Out_Q[order(ChurnRiskRank)],row.names = F)
