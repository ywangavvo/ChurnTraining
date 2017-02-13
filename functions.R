rowProd<-function(X){X[,1]*X[,2]}

### Prior 3 months metrics
Prior3sum<-function(x){
  X=cbind(eval(parse(text=paste("dat$",x,"_1",sep=""))),
            eval(parse(text=paste("dat$",x,"_2",sep=""))),
            eval(parse(text=paste("dat$",x,"_3",sep=""))))
  return(rowSums(X,na.rm=T))
}

Prior3mean<-function(x){
  X=cbind(eval(parse(text=paste("dat$",x,"_1",sep=""))),
          eval(parse(text=paste("dat$",x,"_2",sep=""))),
          eval(parse(text=paste("dat$",x,"_3",sep=""))))
   Y=X!=0&is.na(X)==0
  tmp<-rowSums(X,na.rm=T)/rowSums(Y)
  tmp[is.na(tmp)]=0
  return(tmp)
}

Prior3value<-function(x){
  X=cbind(eval(parse(text=paste("dat$",x,"_1",sep=""))),
          eval(parse(text=paste("dat$",x,"_2",sep=""))),
          eval(parse(text=paste("dat$",x,"_3",sep=""))))
  return(rowSums(X,na.rm=T)/dat$sum_spend)
}

### Prior 3 months metrics for prediction
Prior3sumP<-function(x){
  X=cbind(eval(parse(text=paste("outsample$",x,"_1",sep=""))),
          eval(parse(text=paste("outsample$",x,"_2",sep=""))),
          eval(parse(text=paste("outsample$",x,sep=""))))
  return(rowSums(X,na.rm=T))
}

Prior3meanP<-function(x){
  X=cbind(eval(parse(text=paste("outsample$",x,"_1",sep=""))),
          eval(parse(text=paste("outsample$",x,"_2",sep=""))),
          eval(parse(text=paste("outsample$",x,sep=""))))
  Y=X!=0&is.na(X)==0
  tmp<-rowSums(X,na.rm=T)/rowSums(Y)
  tmp[is.na(tmp)]=0
  return(tmp)
}

Prior3valueP<-function(x){
  X=cbind(eval(parse(text=paste("outsample$",x,"_1",sep=""))),
          eval(parse(text=paste("outsample$",x,"_2",sep=""))),
          eval(parse(text=paste("outsample$",x,sep=""))))
  return(rowSums(X,na.rm=T)/outsample$sum_spend)
}

### Month Treatment for Month Model ###
MonthDmy<-function(x){
x[,Month_le3:=1*(activemonth<=3)]
x[,Month4:=1*(activemonth==4)]
x[,Month5:=1*(activemonth==5)]
x[,Month6:=1*(activemonth==6)]
x[,Month7:=1*(activemonth==7)]
x[,Month8:=1*(activemonth==8)]
x[,Month9:=1*(activemonth==9)]
x[,Month10:=1*(activemonth==10)]
x[,Month11:=1*(activemonth==11)]
x[,Month12:=1*(activemonth==12)]
x[,Month_ge13:=1*(activemonth>=13&activemonth<=24)]
x[,Month_ge25:=1*(activemonth>=25&activemonth<=36)]
x[,Month_gt36:=1*(activemonth>36)]
}

### Sums over next three months for QUarter Model ###
Post3sum<-function(x,L){
  for (l in L){
  x[,eval(parse(text=paste(l))):=rowSums(cbind(eval(parse(text=paste(l))),
     shift(eval(parse(text=paste(l))),1L,type="lead"),
     shift(eval(parse(text=paste(l))),2L,type="lead")),na.rm=T),by=customer_id]
  }
}

Onesify<-function(x,L){
  for (l in L){
    x[,eval(parse(text=paste(l))):=
       ifelse(eval(parse(text=paste(l)))>1,1,eval(parse(text=paste(l)))),by=customer_id]
  }
}

readimpala<-function (file = "", query = "", user = "", dsn = "Cloudera Impala",
          type = "file")
{
  library(RODBC)
  library(data.table)
  odbcCloseAll()
  ch = odbcConnect(dsn, user, "#")
  print("connected to impala")
  if (file == "")
    if (query == "")
      stop("No file or string provided with sql query",
           call. = F)
  else {
    file = query
    type = "string"
  }
  else type = "file"
  x = sqlQuery(channel = ch, query = onelineq(file, type),
               believeNRows = F)
  if (typeof(x) != "list")
    stop("Data not returned, check query syntax.", call. = F)
  setDT(x)
  x
}

# Post3sum<-function(x,L){
#   for (l in L){
#     x[,l:=rowSums(cbind(l,
#      shift(l,1L,type="lead"),
#      shift(l,2L,type="lead")),na.rm=T),by=customer_id]
#   }
# }

# ### Prior 2 months metrics
# Prior2sum<-function(x){
#   X=cbind(eval(parse(text=paste("dat$",x,"_2",sep=""))),
#           eval(parse(text=paste("dat$",x,"_3",sep=""))))
#   return(rowSums(X,na.rm=T))
# }
#
# Prior2mean<-function(x){
#   X=cbind(eval(parse(text=paste("dat$",x,"_2",sep=""))),
#           eval(parse(text=paste("dat$",x,"_3",sep=""))))
#   Y=X!=0&is.na(X)==0
#   tmp<-rowSums(X,na.rm=T)/rowSums(Y)
#   tmp[is.na(tmp)]=0
#   return(tmp)
# }
#
# Prior2value<-function(x){
#   X=cbind(eval(parse(text=paste("dat$",x,"_2",sep=""))),
#           eval(parse(text=paste("dat$",x,"_3",sep=""))))
#   return(rowSums(X,na.rm=T)/dat$sum_spend)
# }
