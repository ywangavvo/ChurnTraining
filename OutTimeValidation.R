##############################################
### Out of Time Validation for month model ###
##############################################
OutTimeValidation_M<-glm(MonthModel
,data=dat[months %between% c(s1months-datamonths_M,s1months-1)&sum_spend>0&is.na(avvo_rating_1)==0&is.na(churned)==0,]
,family=binomial)
if (PrintOutSampleValidationModel_M==1) print(summary(OutTimeValidation_M))

pred=prediction(OutTimeValidation_M$fitted.values,OutTimeValidation_M$y)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Time Training AUC for the Month Model =",round(auc,4),"\n")

yhat=predict(OutTimeValidation_M,newdata=dat[months==s1months,])
Yhat=data.table(cbind(customer_id=dat[months==s1months,customer_id],yhat,y=dat[months==s1months,churned]))
pred=prediction(Yhat[!is.na(yhat)&!is.na(y),yhat],Yhat[!is.na(yhat)&!is.na(y),y])
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Time Validation AUC for the Month Model =",round(auc,4),"\n")
roc<-performance(pred,"tpr","fpr")
plot(roc, main=paste("Out of Time Validation AUC for Month Model = ",round(auc,4),sep=""))
abline(h=seq(0,1,0.05),v=seq(0,1,0.05),col = "lightgray", lty = 3)

################################################
### Out of Time Validation for quarter model ###
################################################
# Agg<-dat[months==(s1months-3),]
# Churned<-dat[months>=(s1months-3)&months<=(s1months-1),
#              .(churned=sum(churned,na.rm=T)),by=c("customer_id")]
# MonthList<-unlist(names(dat)[grep("Month",names(dat))])
# Agg[,c(MonthList):=NULL]
# Agg[,churned:=NULL]
# Month<-dat[months>=(s1months-3)&months<=(s1months-1),lapply(.SD,sum),by=customer_id,.SDcols=MonthList]
# Month<-Month[,lapply(.SD,function(x){ifelse(x>1,1,x)}),by=customer_id,.SDcols=MonthList]
# Agg<-merge(Agg,Churned,by="customer_id",all.x=T)
# Agg[,churned:=1*(churned>=1)]
# Agg<-merge(Agg,Month,by="customer_id",all.x=T)
#
Agg<-AggDat[months %between% c(s1months-datamonths_Q-2,s1months-3),] # For Out of Time Training later on
Agg_V<-AggDat[months==s1months-2,] # For Out of Time Validation later on

OutTimeValidation_Q<-glm(QuarterModel
,data=Agg[sum_spend>0&is.na(avvo_rating_1)==0,]
,family=binomial
)
if (PrintOutSampleValidationModel_Q==1) print(summary(OutTimeValidation_Q))
pred=prediction(OutTimeValidation_Q$fitted.values,OutTimeValidation_Q$y)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Time Training AUC for the Quarter Model =",round(auc,4),"\n")

# Agg_V<-dat[months==(s1months-2),]
# Churned<-dat[months>=(s1months-2)&months<=(s1months),
#  .(churned=sum(churned,na.rm=T)),by=c("customer_id")]
# MonthList<-unlist(names(dat)[grep("Month",names(dat))])
# Agg_V[,c(MonthList):=NULL]
# Agg_V[,churned:=NULL]
# Month<-dat[months>=(s1months-2)&months<=(s1months),lapply(.SD,sum),by=customer_id,.SDcols=MonthList]
# Month<-Month[,lapply(.SD,function(x){ifelse(x>1,1,x)}),by=customer_id,.SDcols=MonthList]
# Agg_V<-merge(Agg_V,Churned,by="customer_id",all.x=T)
# Agg_V[,churned:=1*(churned>=1)]
# Agg_V<-merge(Agg_V,Month,by="customer_id",all.x=T)
yhat<-predict(OutTimeValidation_Q,newdata=Agg_V)
pred=prediction(yhat,Agg_V$churned)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Time Validation AUC for the Quarter Model =",round(auc,4),"\n")
roc<-performance(pred,"tpr","fpr")
plot(roc, main=paste("Out of Time Validation AUC for the Quarter Model = ",round(auc,4),sep=""))
abline(h=seq(0,1,0.05),v=seq(0,1,0.05),col = "lightgray", lty = 3)
