library(awsR)
library(stringr)

result <- security_group_create()

test_that("resource_s3 return the correct class", {
  expect_equal(
    {
      security_group_delete(result)
    },
    200
  )
})
