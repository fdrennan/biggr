
library(rsample)
library(broom)
library(purrr)
library(tictoc)

data("attrition")
names(attrition)

set.seed(4622)
rs_obj <- vfold_cv(attrition, v = 20, repeats = 100)
rs_obj

mod_form <- as.formula(Attrition ~ JobSatisfaction + Gender + MonthlyIncome)


## splits will be the `rsplit` object with the 90/10 partition
holdout_results <- function(splits, ...) {
  # Fit the model to the 90%
  mod <- glm(..., data = analysis(splits), family = binomial)
  # Save the 10%
  holdout <- assessment(splits)
  # `augment` will save the predictions with the holdout data set
  res <- broom::augment(mod, newdata = holdout)
  # Class predictions on the assessment set from class probs
  lvls <- levels(holdout$Attrition)
  predictions <- factor(ifelse(res$.fitted > 0, lvls[2], lvls[1]),
                        levels = lvls)
  # Calculate whether the prediction was correct
  res$correct <- predictions == holdout$Attrition
  # Return the assessment data set with the additional columns
  res
}

library(purrr)
library(tictoc)

tic()
rs_obj$results <- map(rs_obj$splits, holdout_results, mod_form)
toc()
#> 30.095 sec elapsed

library(furrr)
plan(multiprocess)

tic()
rs_obj$results <- future_map(rs_obj$splits, holdout_results, mod_form)
toc()
