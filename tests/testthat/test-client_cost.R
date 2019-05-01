library(awsR)

test_that("connections return the correct class", {
  expect_equal(class(client_cost())[[1]], "botocore.client.CostExplorer")
})
