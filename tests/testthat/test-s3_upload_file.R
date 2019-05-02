library(awsR)

test_that("s3 upload and delete return the correct values", {

  expect_equal(
    s3_upload_file(bucket = 'fdrennanunittest',
                   from   = 'mtcars',
                   to     ='mtcars'),
    "https://s3.us-east-2.amazonaws.com/fdrennanunittest/mtcars"
  )

  expect_equal(
    s3_download_file('fdrennanunittest', 'mtcars', 'mtcars.csv'),
    TRUE
  )

  expect_equal(
    s3_delete_file(bucket = 'fdrennanunittest',
                   file   = 'mtcars'),
    TRUE
  )
})
