# ------------------------------------------------------------------------
# Evan Rhodes
# 11/30/2025
#
# Poke_Prediction.R
# This file is used to develop prediction models for Pokemon popularity
# rankings and compare evaluation metrics
# ------------------------------------------------------------------------

library(tidyverse)
library(glmnet)
library(randomForest)


##############################################################
# Load data
##############################################################

df <- readRDS("Analysis_DF.rds")


##############################################################
# Partition into 75% training, 25% testing splits 
# (~ 750, 250 ids)
##############################################################
set.seed(1130161)

n <- nrow(df)
train_idx <- sample(n, size = floor(0.75 * n))

train <- df[train_idx, ]
test  <- df[-train_idx, ]


##############################################################
# Simple linear model predictions for baseline consideration
##############################################################

base <- rank ~ height + weight + stats_hp + stats_attack + stats_defense + 
        stats_special_attack + stats_special_defense + stats_speed + gender_rate + 
        capture_rate + base_happiness + is_baby + is_legendary + is_mythical + 
        growth_rate + color + shape + has_gender_differences + forms_switchable + 
        generation + num_forms + num_moves

# Need to remove types, 171 unique type combos not feasible for the scope of this
# dataset
selected <- rank ~ stats_attack +  
            gender_rate + 
            capture_rate + base_happiness +
            color + shape + forms_switchable + 
            generation + num_moves

mod1 <- lm(selected, data = train)

mod1_pred <- predict(mod1, newdata = test)

mod1_cor <- cor(test$rank, mod1_pred, method = "spearman")


##############################################################
# Lasso Regression model
##############################################################

y_train <- train$rank
y_test  <- test$rank

x_train <- model.matrix(~ height + weight + stats_hp + stats_attack + stats_defense + 
                          stats_special_attack + stats_special_defense + stats_speed + 
                          gender_rate + capture_rate + base_happiness + is_baby + 
                          is_legendary + is_mythical + growth_rate + color + shape + 
                          has_gender_differences + forms_switchable + generation + 
                          num_forms + num_moves,
                        data = train)[, -1]

x_test <- model.matrix(~ height + weight + stats_hp + stats_attack + stats_defense + 
                         stats_special_attack + stats_special_defense + stats_speed + 
                         gender_rate + capture_rate + base_happiness + is_baby + 
                         is_legendary + is_mythical + growth_rate + color + shape + 
                         has_gender_differences + forms_switchable + generation + 
                         num_forms + num_moves,
                       data = test)[, -1]

set.seed(1130161)
lasso_cv <- cv.glmnet(x_train, y_train, alpha = 1, nfolds = 10, standardize = TRUE)
lambda_min <- lasso_cv$lambda.min
mod2 <- glmnet(x_train, y_train, alpha = 1, lambda = lambda_min)
mod2_pred <- predict(mod2, newx = x_test, s = lambda_min)

mod2_cor <- cor(y_test, as.vector(mod2_pred), method = "spearman")


##############################################################
# Random Forest model 
##############################################################

set.seed(1130161)

# By %IncMSE metric, remove is_legendary, has_gender_differences, & num_forms.
# they increase MSE and make model worst according to importance metrics
# also is_mythical
mod3 <- randomForest(
  rank ~ height + weight + stats_hp + stats_attack + stats_defense +
    stats_special_attack + stats_special_defense + stats_speed +
    gender_rate + capture_rate + base_happiness + is_baby +
    growth_rate + color + shape +
    forms_switchable + generation + num_moves,
  data = train,
  ntree = 500,
  importance = TRUE 
)

mod3_pred <- predict(mod3, newdata = test)

mod3_cor <- cor(test$rank, mod3_pred, method = "spearman")


##############################################################
# Feature importance plot from random forest model
##############################################################

importance_df <- as.data.frame(importance(mod3))
importance_df$Feature <- rownames(importance_df)
importance_df <- importance_df[order(importance_df$`%IncMSE`, decreasing = TRUE), ]

implot <- ggplot(importance_df, aes(x = reorder(Feature, `%IncMSE`), y = `%IncMSE`)) +
  geom_col(fill = "steelblue") +
  coord_flip() +  
  labs(title = "Random Forest Model Pokemon Feature Importance",
       x = "Feature",
       y = "% Increase in MSE") +
  theme_minimal()

ggsave("RF_Importance_Plot.jpg", plot = implot, width = 10, height = 8, dpi = 300)


##############################################################
# Combine model results for table
##############################################################

lasso_coef <- coef(mod2)
dropped_features <- rownames(lasso_coef)[lasso_coef[, 1] == 0]
dropped_features <- dropped_features[dropped_features != "(Intercept)"]
dropped_features_str <- paste(dropped_features, collapse = ", ")

summary_table <- data.frame(
  Model = c("General Linear Model", "Lasso Regression", "Random Forest"),
  Features = c("Attack Stat, Gender Rate, Capture Rate, Base Happiness, Color, Shape, Switchable Forms, Generation, Number of Moves", 
               "All base features excluding special stats, mythical flag, gender differences flag, number of forms, and various specific levels of growth rate, color, and shape",
               "Height, Weight, all Stats, Gender Rate, Capture Rate, Base Hapiness, Baby Flag, Growth Rate, Color, Shape, Switchable Forms, Generation, Number of Moves"),
  Correlation = c(mod1_cor, mod2_cor, mod3_cor)
)

saveRDS(summary_table, "Model_Comparisons.rds")

