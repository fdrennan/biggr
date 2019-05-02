library(awsR)

test_that("resource_s3 return the correct class", {
  sg_id <- security_group_create()
  expect_equal(
    stringr::str_detect(sg_id, "sg-"),
    TRUE
  )
  expect_equal(
    {
      security_group_delete(sg_id);
      stringr::str_detect(security_group_create(), "sg-")
    },
    TRUE
  )
})
