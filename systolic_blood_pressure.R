rm(list = ls())
#setwd("~/Dropbox/UofT Admin and TA/STA 302/Lectures/Final Project")
install.packages("car")
install.packages('rms')
install.packages('Hmisc')
install.packages('xfun')
install.packages('Rcpp')

library(glmnet)
library(xfun)
library(Hmisc)
library(mvtnorm)
library(rms)

library(car)
library(NHANES)
library(tidyverse)
library(glmnet)
small.nhanes <- na.omit(NHANES[NHANES$SurveyYr=="2011_12"
                               & NHANES$Age > 17,c(1,3,4,8:11,13,17,20,21,25,46,50,51,52,61)])
small.nhanes <- as.data.frame(small.nhanes %>%
  group_by(ID) %>% filter(row_number()==1) )
nrow(small.nhanes)

## Checking whether there are any ID that was repeated. If not ##
## then length(unique(small.nhanes$ID)) and nrow(small.nhanes) are same ##
length(unique(small.nhanes$ID))

## Create training and test set ##
set.seed(1002965776)
train <- small.nhanes[sample(seq_len(nrow(small.nhanes)), size = 400),]
nrow(train)
length(which(small.nhanes$ID %in% train$ID))
test <- small.nhanes[!small.nhanes$ID %in% train$ID,]
nrow(test)

## Running the model ##
### First fit a multiple linear regression ##
model.lm <- lm( BPSysAve ~ ., data = train[, -c(1)])
summary(model.lm)

#plot(model.lm, pch=23 ,bg='orange',cex=2)

p <- dim(model.matrix(model.lm))[2] - 1

## The hat values ###
h <- hatvalues(model.lm)
thresh <- 2 * (p+1)/nrow(train)
w <- which(h > thresh)
w ## leverage points

### The Influential Observations ####
D <- cooks.distance(model.lm)
which(D > qf(0.5, p+1, nrow(train)-p-1))

## DFFITS ##
dfits <- dffits(model.lm)
intera <- which(abs(dfits) > 2*sqrt((p+1)/nrow(train)))

## DFBETAS ##
dfb <- dfbetas(model.lm)
interb <- which(abs(dfb[,1]) > 2/sqrt(nrow(train)))

## Remove outliers ##
remove <- intersect(intera, interb) ## influential observations detected by both DFFITS and DFBETAS
train <- train[-c(remove),]

## fit ##
model.lm <- lm( BPSysAve ~ ., data = train[, -c(1)])

## vif ##
vif(model.lm)


## Variable Selection ##
## Based on AIC ##
summary(model.lm)
sel.var.aic <- step(model.lm, trace = 0, k = 2, direction = "both") 
sel.var.aic<-attr(terms(sel.var.aic), "term.labels")   

## Based on BIC ##
n <- nrow(train)
sel.var.bic <- step(model.lm, trace = 0, k = log(n), direction = "both") 
sel.var.bic<-attr(terms(sel.var.bic), "term.labels")   


### LASSO selection ###

## Perform cross validation to choose lambda ##
#set.seed(1002965776)
cv.out <- cv.glmnet(x = as.matrix(model.matrix( ~ ., data = train[,-c(1,12)])), y = train$BPSysAve, standardize = T, alpha = 1)
plot(cv.out)
best.lambda <- cv.out$lambda.1se
best.lambda
co<-coef(cv.out, s = "lambda.1se")

#Selection of the significant features(predictors)
## threshold for variable selection ##
thresh <- 0.00

# select variables #
inds<-which(abs(co) > thresh )
variables<-row.names(co)[inds]
sel.var.lasso<-variables[!(variables %in% '(Intercept)')]


## Compare ##
sel.var.aic; sel.var.bic; sel.var.lasso

### Cross Validation and prediction performance of AIC based selection ###
ols.aic <- ols(BPSysAve ~ ., data = train[,which(colnames(train) %in% c(sel.var.aic, "BPSysAve"))], 
               x=T, y=T, model = T)

## 10 fold cross validation ##    
aic.cross <- calibrate(ols.aic, method = "crossvalidation", B = 10) 
## Calibration plot ##
pdf("aic_cross.pdf", height = 8, width = 16)
plot(aic.cross, las = 1, xlab = "Predicted BPSysAve", main = "Cross-Validation calibration with AIC")
dev.off()

## Test Error ##
pred.aic <- predict(ols.aic, newdata = test[,which(colnames(train) %in% c(sel.var.aic, "BPSysAve"))])
## Prediction error ##
pred.error.AIC <- mean((test$BPSysAve - pred.aic)^2)


### Cross Validation and prediction performance of BIC based selection ###
ols.bic <- ols(BPSysAve ~ ., data = train[,which(colnames(train) %in% c(sel.var.bic, "BPSysAve"))], 
               x=T, y=T, model = T)

## 10 fold cross validation ##    
bic.cross <- calibrate(ols.bic, method = "crossvalidation", B = 10)
## Calibration plot ##
pdf("bic_cross.pdf", height = 8, width = 16)
plot(bic.cross, las = 1, xlab = "Predicted BPSysAve", main = "Cross-Validation calibration with BIC")
dev.off()

## Test Error ##
pred.bic <- predict(ols.bic, newdata = test[,which(colnames(train) %in% c(sel.var.bic, "BPSysAve"))])
## Prediction error ##
pred.error.BIC <- mean((test$BPSysAve - pred.bic)^2)


### Cross Validation and prediction performance of lasso based selection ###
ols.lasso <- ols(BPSysAve ~ ., data = train[,which(colnames(train) %in% c(sel.var.lasso, "BPSysAve"))], 
                 x=T, y=T, model = T)

## 10 fold cross validation ##    
lasso.cross <- calibrate(ols.lasso, method = "crossvalidation", B = 10)
## Calibration plot ##
pdf("lasso_cross.pdf", height = 8, width = 16)
plot(lasso.cross, las = 1, xlab = "Predicted BPSysAve", main = "Cross-Validation calibration with LASSO")
dev.off()

## Test Error ##
pred.lasso <- predict(ols.lasso, newdata = test[,which(colnames(train) %in% c(sel.var.lasso, "BPSysAve"))])
## Prediction error ##
pred.error.lasso <- mean((test$BPSysAve - pred.lasso)^2)

## Compare ##
print(c(pred.error.AIC, pred.error.BIC, pred.error.lasso))

## Correlation ##
coef.cor <- rcorr(as.matrix(model.matrix( ~ ., data = train[,-c(1,12)])))



## TABLE ##
mod.one<- lm(BPSysAve ~ Age + SmokeNow, data = train[, -c(1)])
mod.fin<- lm(BPSysAve ~ Age, data = train[, -c(1)])

install.packages("sjPlot")
library(sjPlot)
library(sjmisc)
library(sjlabelled)
library(sjstats)

tab_model(mod.one, mod.fin, show.se=TRUE, show.df = TRUE, show.stat = TRUE)

## Graphs ##

plot(BPSysAve ~ Age, data = train[, -c(1)])
abline(lm(BPSysAve ~ Age, data = train[, -c(1)]))

plot(BPSysAve ~ Age + SmokeNow, data = train[, -c(1)])

par(mfrow=c(2,2))
plot(mod.fin, which=1:4)

p <- dim(model.matrix(mod.fin))[2] - 1

### The Influential Observations ####
D <- cooks.distance(mod.fin)
which(D > qf(0.5, p+1, nrow(train)-p-1))

## DFFITS ##
dfits <- dffits(mod.fin)
intera <- which(abs(dfits) > 2*sqrt((p+1)/nrow(train)))

## DFBETAS ##
dfb <- dfbetas(mod.fin)
interb <- which(abs(dfb[,1]) > 2/sqrt(nrow(train)))

## Remove outliers ##
remove <- intersect(intera, interb) ## influential observations detected by both DFFITS and DFBETAS
remove
train <- train[-c(remove),]

## fit ##
mod.fin <- lm(BPSysAve ~ ., data = train[, -c(1)])

## graphs ##
par(mfrow=c(2,2))
plot(mod.fin, which=1:4)
dev.off()

plot(BPSysAve ~ Age, data = train[, -c(1)])
abline(lm(BPSysAve ~ Age, data = train[, -c(1)]))

plot(BPSysAve ~ SmokeNow, data = train[, -c(1)])


## Perform Prediction ##
pred.y <- predict(model.lm, newdata = test, type = "response")

## Prediction error ##
mean((test$BPSysAve - pred.y)^2)

## Fit a ridge penalty ##
model.ridge <- glmnet(x = model.matrix( ~ ., data = train[,-c(1,12)]), y = train$BPSysAve, 
                      standardize = T, alpha = 0)

## Perform Prediction ##
pred.y.ridge <- predict(model.ridge, newx = model.matrix( ~ ., data = test[,-c(1,12)]), type = "response")

## Prediction error ##
mean((test$BPSysAve - pred.y.ridge)^2)


## Fit a LASSO penalty ##
model.lasso <- glmnet(x = model.matrix( ~ ., data = train[,-c(1,12)]), y = train$BPSysAve
                      , standardize = T, alpha = 1)

## Perform Prediction ##
pred.y.lasso <- predict(model.lasso, newx = model.matrix( ~ ., data = test[,-c(1,12)]), type = "response")
## Prediction error ##
mean((test$BPSysAve - pred.y.lasso)^2)
