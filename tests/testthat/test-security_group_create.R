library(awsR)
library(stringr)

test_that("resource_s3 return the correct class", {

  sg_id <- security_group_create()
  expect_equal(
    str_detect(sg_id, "sg-"),
    TRUE
  )

  expect_equal(
    {
      security_group_delete(sg_id);
      str_detect(security_group_create(), "sg-")
    },
    TRUE
  )

  sg_id <- security_group_create()
  expect_equal(
    {
      security_group_delete(sg_id)
    },
    200
  )

})
