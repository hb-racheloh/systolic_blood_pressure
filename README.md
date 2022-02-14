# Is Systolic Blood Pressure Associated with Age and Smoking? A Population-Based Study of American Adults

## Introduction

Blood pressure is read in two numbers, systolic over diastolic, and measured in
millimeters of mercury. Systolic blood pressure (SBP) represents the pressure at the maximum
part of your heartbeat when the heart chambers contract to push blood through your blood
vessels. High blood pressure is defined as SBP of 130 or higher. It is a major public health
problem around the world and the leading risk factor for global disease burden, caused nearly
half a million deaths in the United States in 2017. Therefore, it is important to know what
causes high SBP.


On average, SBP rises with age. While a certain amount of blood pressure increase is
unavoidable as we age, blood pressure health can still be maintained by following the same
lifestyle recommendations as younger people. However, the relationship between smoking and
BP are equivocal, as some studies show a positive association while others show that there is no
relationship. In this study, we are going to investigate the association between age and smoking
and SBP in adults in the U.S.

## Methods

**Study Population**\
This analysis was conducted using data from NHANES, which includes a series of crosssectional
nationally representative health examination surveys. Data are collected from a
representative sample of the civilian noninstitutionalized U.S. population, by in-home personal
interviews and physical examinations.

**Data**\
A representative sample includes 743 Americans older than 17 years. 400 observations were
randomly selected from the data and this set is going to be referred to as train data. The rest of
the data will be used as a test set (343 observations).

**Model Violations/Diagnostics**\
According to Cook’s Distance, there was no influential observation in the train data. However,
when used DFFITS and DFBETAS, there were some influential observations, so the common influential observations detected both by DFFITS and DFBETAS were excluded from the train data. The updated train data that now has 387 observations is going to be used for variable selection.

**Variable Selection**\
Variable selection based on AIC selected three predictors, ‘Age’, ‘Race3’ and ‘MaritalStatus’.
For BIC and LASSO, only one variable, ‘Age’ was selected. Although we are mainly interested
in the effect of ‘SmokeNow’ on ‘BPSysAve’, this variable was not selected in any of the
methods above. In order to check the relationship between ‘SmokeNow’ and ‘BPSysAve’, we
first have to figure out if we can fit a Simple Linear Regression model by checking the
correlation between ‘SmokeNow’ and other variables. However, ‘SmokeNow’ had high
correlation with some variables such as ‘EducationSome’, so SLR could not be progressed.
Hence, the final model would only include ‘Age’ as a predictor, but we will also see the results
of a model including ‘SmokeNow’.

**Model Validation**\
10-fold cross validation and prediction performance of AIC, BIC and LASSO based selection was done. The prediction error using the test data was 232.7677 for AIC and 224.7722 for both BIC and LASSO. The lowest prediction error value among these was 224.7722, which is from BIC and LASSO that selected ‘Age’ as the only predictor.\
![](https://github.com/hb-racheloh/systolic_blood_pressure/blob/main/Cross-Validation%20calibration%20with%20AIC.jpg)
![](https://github.com/hb-racheloh/systolic_blood_pressure/blob/main/Cross-Validation%20calibration%20with%20BIC.jpg)
![](https://github.com/hb-racheloh/systolic_blood_pressure/blob/main/Cross-Validation%20calibration%20with%20LASSO.jpg)
As you can see from the graphs above, for AIC based, the line is not as close to the 45-degree line as the ones for BIC and LASSO based, which again conveys that including ‘Age’ as the only predictor is the best option.

**Results**\
We are going to see the summary table for two models, the first one (left) with two predictors,
age and current smoking (SmokeNow), and the second one (right) with just one predictor, age.\
For the first model (two predictors), the following hypotheses are tested:\
• H0: There is no linear association between BPSysAve and Age and SmokeNow.\
• Ha: There is a linear association between BPSysAve and Age and SmokeNow.\
![](https://github.com/hb-racheloh/systolic_blood_pressure/blob/main/Predictors.jpg)
