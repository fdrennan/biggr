library(awsR)

buckets <- s3_list_buckets()
bucket_name <- 'fdrennantestbucket'
bucket_exists <- bucket_name %in% buckets$name
if(bucket_exists) {
  s3_delete_bucket(bucket_name = bucket_name)
}

test_that("s3 bucket creation/deletion works", {
    expect_equal(
      s3_create_bucket(bucket_name),
      "http://fdrennantestbucket.s3.amazonaws.com/"
    )
})

