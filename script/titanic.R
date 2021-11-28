# Kaggle competition: Titanic
# Following tutorial from Data Science Dojo
# Source: https://www.youtube.com/watch?v=Zx2TguRHrJE
# Adapting tutorial to in Tidyverse

# clear memory ----

rm(list=ls()) 

# load libraries ----

library(httr)
library(dplyr)
library(readr)
library(here)
library(janitor)
library(tibble)
library(tidyr)
library(randomForest)

# load data ----

raw_train <- read_csv(here("data", "raw", "train.csv")) %>% clean_names()
raw_test <- read_csv(here("data", "raw", "test.csv")) %>% clean_names()

# clean the data ----

# tutorial suggest to clean the two data files together
# asking myself if this is reasonable

dim(raw_train)
dim(raw_test)

median(raw_train$age, na.rm = TRUE)
median(raw_test$age, na.rm = TRUE)

# the datasets are indeed different
# checking if they have same columns
# already know that the train set has 12 columns and the test set has 11 columns

compare_df_cols(raw_train, raw_test)

# the train set is missing a survived column
# makes sense that the test file does not have it as this is what we want to predict
# so the same cleaning steps are likely to be applicable to both test and train
# ok to follow procedure as long we can reconstruct the train and test files afterwards

train <- raw_train %>%
  add_column(dataset = "train")

test <- raw_test %>%
  add_column(dataset = "test") %>%
  add_column(survived = as.numeric(""), .before = "pclass") 

compare_df_cols(train, test)

# now they both have the same columns and they are of the same class
# combining the datasets to clean them

all <- bind_rows(train, test)

# checking that the data is correct

all %>%
  group_by(dataset) %>%
  tally()

# this returned the expected number of rows

# clean up the NAs ----
# there are missing values
# in the embarked column: 
# C = Cherbourg, Q = Queenstown, S = Southampton

all %>%
  group_by(embarked) %>%
  tally()

# there are two NAs in there
# those can be replaced by the mode which here is S
# this is simply saying we don't know where these people embarked
# most likely they did from Southampton (this is an assumption)
# so let's replace the NAs in this column with S
# ASSUMPTION: missing embarked values are S

all <- all %>%
  replace_na(list(embarked = "S"))
  
all %>%
  group_by(embarked) %>%
  tally()

# there are also a lot of missing values in the age column

sum(is.na(all$age))

# there are 263 missing values for age, that is a lot (20%)

hist(all$age)
mean(all$age, na.rm = TRUE)
median(all$age, na.rm = TRUE)

# does not look normally distributed so could replace with the median (instead of mean) age
# those are close any way

all <- all %>%
  replace_na(list(age = median(all$age, na.rm = TRUE)))

sum(is.na(all$age))

# all missing values in age are gone

# let's have a look at fare

sum(is.na(all$fare))

# there is one missing value
# let's replace by the median as well for now

all <- all %>%
  replace_na(list(fare = median(all$fare, na.rm = TRUE)))

sum(is.na(all$fare))

# ok no fare missing

# categorical casting ----
# will do it for all columns except survived

str(all)

all <- all %>%
  mutate(
    pclass = factor(pclass, levels = c("1", "2", "3")),
    sex = factor(sex),
    embarked = factor(embarked)
  )

# split datasets back out into train and test ----

train <- all %>%
  filter(dataset == "train")

dim(train)
dim(raw_train)

test <- all %>%
  filter(dataset == "test")

dim(test)
dim(raw_test)

# those are the same rows as the raw datasets
# the number of columns are different as intended

# training model ----

train <- train %>%
  mutate(
    survived = factor(survived)
  )

# identify what to use in the model
# identify the predictors

survived_equation <- "survived ~ pclass + sex + age + sib_sp + fare + embarked"
survived_formula <- as.formula(survived_equation)

# skipping the 30/70 split for now
# building model

model <- randomForest(
  formula = survived_formula, 
  data = train, 
  ntree = 500, 
  mtry = 3, 
  nodesize = 0.01 * nrow(test)
  )

# apply the predictive model
# specify features to use

features_equation <- "pclass + sex + age + sib_sp + fare + embarked"

predictions <- predict(model, newdata = test)

PassengerId <- test$passenger_id

output_df <- as.data.frame(PassengerId)

output_df <- output_df %>%
  add_column(Survived = predictions)

write_csv(output_df, here("data", "processed", "kaggle_submission.csv"))
