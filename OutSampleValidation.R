### Out of Sample Validation for Month Model ###
OutSampleValidation_M<-glm(MonthModel
,data=dat[training<=0.75&months %between% c(s1months-datamonths_M+1,s1months)&sum_spend>0&is.na(avvo_rating_1)==0&is.na(churned)==0,]
,family=binomial
)
summary(OutSampleValidation_M)
pred=prediction(OutSampleValidation_M$fitted.values,OutSampleValidation_M$y)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Sample Training AUC for the Month Model =",round(auc,4),"\n")
validation<-dat[training>0.75&months %between% c(s1months-datamonths_M+1,s1months)&sum_spend>0&is.na(avvo_rating_1)==0&is.na(churned)==0,]
yhat<-predict(OutSampleValidation_M,validation)
pred=prediction(yhat,validation$churned)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Sample Validation AUC for the Month Model is ",round(auc,4),"\n")
roc<-performance(pred,"tpr","fpr")
plot(roc, main=paste("Out of Sample Validation AUC for the Month Model = ",round(auc,4),sep=""))
abline(h=seq(0,1,0.05),v=seq(0,1,0.05),col = "lightgray", lty = 3)

### Out of Sample Validation for Quarter Model ###
OutSampleValidation_Q<-glm(QuarterModel
,data=AggDat[training<=0.75&months %between% c(s1months-datamonths_Q-1,s1months-2)&sum_spend>0&is.na(avvo_rating_1)==0&is.na(churned)==0,]
,family=binomial
)
summary(OutSampleValidation_M)
pred=prediction(OutSampleValidation_Q$fitted.values,OutSampleValidation_Q$y)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Sample Training AUC for the Quarter Model is",round(auc,4),"\n")
validation<-AggDat[training>0.75&months %between% c(s1months-datamonths_Q-1,s1months-2)&is.na(avvo_rating_1)==0&is.na(churned)==0,]
yhat<-predict(OutSampleValidation_Q,validation)
pred=prediction(yhat,validation$churned)
auc=as.numeric(performance(pred,"auc")@y.values)
cat("Out of Sample Validation AUC for the Quarter Model is",round(auc,4),"\n")
roc<-performance(pred,"tpr","fpr")
plot(roc, main=paste("Out of Sample Validation AUC for the Quarter Model = ",round(auc,4),sep=""))
abline(h=seq(0,1,0.05),v=seq(0,1,0.05),col = "lightgray", lty = 3)
