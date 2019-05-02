library(awsR)

test_that("s3 lists return the correct values", {

  response <- s3_list_buckets()
  expect_equal(
    colnames(response),
    c("name", "creation_date")
  )

  s3_delete_file('fdrennanunittest', 'mtcars')
  expect_equal(
    s3_list_objects('fdrennanunittest'),
    FALSE
  )

  write.csv(mtcars, 'mtcars')
  s3_upload_file(bucket = 'fdrennanunittest',
                 'mtcars',
                 'mtcars')
  expect_equal(
    nrow(s3_list_objects('fdrennanunittest')),
    1
  )

})


