library(awsR)

test_that("s3 bucket creation/deletion works", {
  bucket_name = "fdrennantestbucket"
  try(s3_create_bucket(bucket_name))
  expect_equal(
    s3_delete_bucket(bucket_name),
    TRUE
  )
})



