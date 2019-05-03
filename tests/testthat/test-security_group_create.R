library(biggr)
library(stringr)

test_that("resource_s3 return the correct class", {
  sg_id <- security_group_create()
  expect_equal(
    str_detect(sg_id, "sg-"),
    TRUE
  )
})
