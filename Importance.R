################################################
### Prediction and Imortance for Month Model ###
################################################
score=predict(logit_M,newdata=outsample)
prob=exp(score)/(exp(score)+1)
coef<-logit_M$coefficients[names(logit_M$coefficients)!="(Intercept)"]
Main<-names(coef)[grep(":",names(coef),invert=T)]
Int<-strsplit(names(coef)[grep(":",names(coef))],":")
Int_outsample<-NULL;Int_insample<-NULL;tmp=NULL
for ( i in 1:length(Int)){
  Int_outsample<-cbind(Int_outsample,rowProd(as.matrix(outsample[,names(outsample) %in% Int[[i]],with=F])))
  Int_insample<-cbind(Int_insample,rowProd(as.matrix(insample[,names(insample) %in% Int[[i]],with=F])))
  tmp<-c(tmp,paste(Int[[i]][1],":",Int[[i]][2],sep=""))
  }
colnames(Int_outsample)<-tmp
colnames(Int_insample)<-tmp
out_newdata<-cbind.data.frame(outsample[,names(outsample)%in%Main,with=F],Int_outsample)
in_newdata<-cbind.data.frame(insample[,names(insample)%in%Main,with=F],Int_insample)
out_newdata<-setcolorder(out_newdata,names(coef))
in_newdata<-setcolorder(in_newdata,names(coef))
in_newdata<-cbind(customer_id=insample$customer_id,in_newdata)
in_newdata<-merge(in_newdata,outsample[,.(customer_id)],by="customer_id",all.y=T)

### Effect Size by Buckets
Importance=NULL
for (i in 1:length(EffectList)){
  if (sum(grep(EffectList[i],names(out_newdata)))>0){
    tmp=as.matrix(rowSums(sweep(out_newdata[,grep(EffectList[i],names(out_newdata)),with=F],2,
                                coef[grep(EffectList[i],names(coef))])) -
                    rowSums(sweep(in_newdata[,grep(EffectList[i],names(in_newdata)),with=F],2,
                                  coef[grep(EffectList[i],names(coef))])))
    colnames(tmp)=EffectName[i]
    Importance<-cbind(Importance,tmp)
  }
  # Importance<-cbind(Importance,rowSums(sweep(out_newdata[,grep(i,names(out_newdata)),with=F],2,
  #                                            coef[grep(i,names(coef))])) -
  #                     rowSums(sweep(in_newdata[,grep(i,names(in_newdata)),with=F],2,
  #                                   coef[grep(i,names(coef))])))
}
ValidEffectList_M<-colnames(Importance)
ImportanceRank<-t(round(apply(-Importance,1,rank)))
Out_M<-cbind.data.frame(customer_id=Demos$customer_id,ChurnRiskRank=rank(-score),ChurnProb=prob,
                        Demos[,-1,with=F],ImportanceRank)

##################################################
### Prediction and Imortance for Quarter Model ###
##################################################
score<-predict(logit_Q,outsample)
prob=exp(score)/(exp(score)+1)
insample<-dat[months==s1months-2&sum_spend>0&sum_imps>0&is.na(avvo_rating)==0&customer_category!="CHURNED",]
### Generate Model Data
coef<-logit_Q$coefficients[names(logit_Q$coefficients)!="(Intercept)"]
Main<-names(coef)[grep(":",names(coef),invert=T)]
Int<-strsplit(names(coef)[grep(":",names(coef))],":")
Int_outsample<-NULL;Int_insample<-NULL;tmp=NULL
for ( i in 1:length(Int)){
  Int_outsample<-cbind(Int_outsample,rowProd(as.matrix(outsample[,names(outsample) %in% Int[[i]],with=F])))
  Int_insample<-cbind(Int_insample,rowProd(as.matrix(insample[,names(insample) %in% Int[[i]],with=F])))
  tmp<-c(tmp,paste(Int[[i]][1],":",Int[[i]][2],sep=""))
}
colnames(Int_outsample)<-tmp
colnames(Int_insample)<-tmp
out_newdata<-cbind.data.frame(outsample[,names(outsample)%in%Main,with=F],Int_outsample)
in_newdata<-cbind.data.frame(insample[,names(insample)%in%Main,with=F],Int_insample)
out_newdata<-setcolorder(out_newdata,names(coef))
in_newdata<-setcolorder(in_newdata,names(coef))
in_newdata<-cbind(customer_id=insample$customer_id,in_newdata)
in_newdata<-merge(in_newdata,outsample[,.(customer_id)],by="customer_id",all.y=T)

### Effect Size by Buckets
Importance=NULL
for (i in 1:length(EffectList)){
  if (sum(grep(EffectList[i],names(out_newdata)))>0){
    tmp=as.matrix(rowSums(sweep(out_newdata[,grep(EffectList[i],names(out_newdata)),with=F],2,
                    coef[grep(EffectList[i],names(coef))])) -
                  rowSums(sweep(in_newdata[,grep(EffectList[i],names(in_newdata)),with=F],2,
                                coef[grep(EffectList[i],names(coef))])))
    colnames(tmp)=EffectName[i]
  Importance<-cbind(Importance,tmp)
  }
  # Importance<-cbind(Importance,parse(text=parse(i))=rowSums(sweep(out_newdata[,grep(i,names(out_newdata)),with=F],2,
  #                                            coef[grep(i,names(coef))])) -
  #                              rowSums(sweep(in_newdata[,grep(i,names(in_newdata)),with=F],2,
  #                                            coef[grep(i,names(coef))])))
  #
}
ValidEffectList_Q<-colnames(Importance)
ImportanceRank<-t(round(apply(-Importance,1,rank)))
Out_Q<-cbind.data.frame(customer_id=Demos$customer_id,ChurnRiskRank=rank(-score),ChurnProb=prob,
                        Demos[,-1,with=F],ImportanceRank)
