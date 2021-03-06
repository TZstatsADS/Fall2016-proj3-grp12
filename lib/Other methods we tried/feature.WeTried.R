#####################################################
### Other feature selction methods we have tried ###
#####################################################

# 1. based on variance(cut off)
# 2. Random forest to choose important features

#############################     method1: based on variance     #############################

variance_cut_off <- function(data, cutoff){
  # cutoff: the variance cutoff value
  
  variance <-  apply(data, 2, var)
  min(variance)
  max(variance)
  
  # count the number of variables left
  # if variance > 0.5e-6, we keep the feature, then there are 1968(n) features remaining
  n=0
  for(i in 1:5000){
    if(variance[i] >= cutoff){n=n+1}
    else{n=n}
  }
  
  # remove the features with small variance
  cut <- rep(cutoff,5000)
  getcol <-  variance - cut >= 0
  return(data[,getcol])
}

#############################     method2: random forest     ################################
# since the permutation variable importance is affected by collinearity
# it's necessary to handle collinearity prior to running random forest for extracting important variables.

########### 1.deal with collinearity
# sessionInfo(): R version 3.2.2 (caret only available for version > 3.2.5)

# load required libraries

random_forest <- function(data, label, n){
  # n: number of features to keep
  
  install.packages("caret", dependencies = c("Depends", "Suggests"))
  library(caret)
  install.packages("corrplot")
  library(corrplot)
  library(plyr)
  
  # Give each feature a "name" and Calculate correlation matrix
  feature1 <- data
  colnames(feature1)[1:5000] <- as.character(seq(1,5000,by=1))
  descrCor <- cor(feature1)
  
  # Print correlation matrix and look at max correlation
  summary(descrCor[upper.tri(descrCor)])
  
  # Find attributes that are highly corrected
  highlyCorrelated <- findCorrelation(descrCor, cutoff=0.6)
  
  # Print indexes of highly correlated attributes
  print(highlyCorrelated)
  
  # Indentifying Variable Names of Highly Correlated Variables
  highlyCorCol <- colnames(feature1)[highlyCorrelated]
  
  # Print highly correlated attributes
  highlyCorCol
  
  # Remove highly correlated variables and create a new dataset
  features1 <- feature1[, -which(colnames(feature1) %in% highlyCorCol)]
  dim(features1)
  # after remove highly corelated variables, there are still 4913 features remaining.
  
  ########### 2.Use random forest
  # ensure the results are repeatable
  install.packages("randomForest")
  library(randomForest)
  
  df <- as.data.frame(cbind(features1,label))
  allX <- paste("X",1:ncol(features1),sep="")
  names(df) <- c(allX,"label")
  
  #Train Random Forest
  time <- system.time(rf <- randomForest(as.factor(label)~.,data = df, importance = TRUE,ntree = 500))
  
  #Evaluate variable importance
  imp <- importance(rf, type=1)
  imp <- data.frame(predictors=rownames(imp),imp)
  
  # Order the predictor levels by importance
  imp.sort <- arrange(imp,desc(MeanDecreaseAccuracy))
  imp.sort$predictors <- factor(imp.sort$predictors,levels=imp.sort$predictors)
  
  # Select the top n predictors
  imp.100=imp.sort[1:n,]
  print(imp.100)
  
  # Plot Important Variables
  varImpPlot(rf, type=1)
  
  return(df[,c(imp.100$predictors)])
}



