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

train <- read_csv(here("data", "processed", "clean_train.csv"))
test <- read_csv(here("data", "processed", "clean_test.csv"))

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

write_csv(output_df, here("data", "processed", "submission.csv"))