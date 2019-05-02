library(awsR)

bucket <- 'fdrennanunittest'
response <- s3_list_objects(bucket_name = bucket)
if(!is.data.frame(response)) {
  if(is.data.frame(response)) {
    has_mtcars <- "mtcars" %in% response$key
  } else {
    has_mtcars <- FALSE
  }
  if(!has_mtcars) {
    write.csv(mtcars, 'mtcars')
    s3_upload_file(bucket, 'mtcars', 'mtcars')
  }
}
test_that("s3_download_files downloads files", {

  expect_equal(
    s3_download_file(bucket = bucket,
                     from   = 'mtcars',
                     to     = '/tmp/mtcars'),
    TRUE
  )

})
