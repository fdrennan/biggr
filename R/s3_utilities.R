#' s3_create_bucket
#' @param bucket_name A name for the bucket
#' @param location An AWS region. Defaults to us-east-2
#' @export s3_create_bucket
s3_create_bucket <- function(bucket_name = NA, location = 'us-east-2') {
  message(
    'Bucket name should conform with DNS requirements:
    - Should not contain uppercase characters
    - Should not contain underscores (_)
    - Should be between 3 and 63 characters long
    - Should not end with a dash
    - Cannot contain two, adjacent periods
    - Cannot contain dashes next to periods (e.g., "my-.bucket.com" and "my.-bucket" are invalid)'
  )
  s3 = client_s3()
  response <-
    s3$create_bucket(Bucket=bucket_name,
                     CreateBucketConfiguration=list(LocationConstraint= location))

  response$Location

}

#' s3_create_bucket
#' @param bucket_name A name for the bucket
#' @export s3_delete_bucket
s3_delete_bucket <- function(bucket_name = NA) {
  s3 = client_s3()
  response <-
    try(s3$delete_bucket(Bucket = bucket_name))
  if(
    response$ResponseMetadata$HTTPStatusCode == 204
  ) {
    return(TRUE)
  }
}


#' s3_download_file
#' @param bucket Bucket to upload to
#' @param from S3 object name.
#' @param to File path
#' @export s3_download_file
s3_download_file <- function(bucket, from, to) {

  s3 = client_s3()
  s3$download_file(Bucket = bucket,
                   Filename = to,
                   Key = from)

  TRUE
}

#' s3_list_buckets
#' @importFrom purrr map_df
#' @importFrom tibble tibble
#' @export s3_list_buckets
s3_list_buckets <- function() {
  s3 = client_s3()
  s3$list_buckets()$Buckets %>%
    map_df(function(x) {
      tibble(name = x$Name,
             creation_date = as.character(x$CreationDate))
    })
}

#' s3_list_objects
#' @param bucket_name bucket_name
#' @importFrom dplyr if_else
#' @importFrom dplyr transmute
#' @importFrom purrr map_df
#' @importFrom tibble tibble
#' @importFrom tibble as_tibble
#' @export s3_list_objects
s3_list_objects <- function(bucket_name = NA) {

  s3 = client_s3()

  results <-
    s3$list_objects(Bucket=bucket_name)

  if(is.null(results$Contents)) {
    return(FALSE)
  }

  results$Contents %>%
    map_df(function(x) {
    as.data.frame(lapply(unlist(x), as.character))
      }) %>%
      transmute(
        key = as.character(Key),
        size = as.character(Size),
        etag = as.character(ETag),
        storage_class = as.character(StorageClass),
        owner_id = as.character(Owner.ID),
        last_modified = as.character(LastModified)
      ) %>%
    as_tibble
}

#' s3_put_object_acl
#' @param bucket bucket_name
#' @param file file name
#' @param ACL  permissions type
#' @export s3_put_object_acl
s3_put_object_acl <- function(bucket = NA,
                              file   = NA,
                              ACL    = 'public-read') {

  s3 = client_s3()

  s3$put_object_acl(ACL    ='public-read',
                    Bucket = bucket,
                    Key    = file)
}

#' upload_file
#' @param bucket Bucket to upload to
#' @param from File to upload
#' @param to S3 object name.
#' @param make_public boolean
#' @param region To create url for file
#' @export s3_upload_file
s3_upload_file <- function(bucket,
                           from,
                           to,
                           make_public = FALSE,
                           region = "us-east-2") {

  s3 = client_s3()

  s3$upload_file(Filename = from,
                 Bucket   = bucket,
                 Key      = to)

  if(make_public) {
    s3_put_object_acl(bucket = bucket, file = to)
  }


  message(
    paste(
      "You may need to change the region in the url",
      paste0('https://s3.', region,'.amazonaws.com/', bucket,'/', to),
      sep = "\n"
    )
  )

  paste0('https://s3.us-east-2.amazonaws.com/', bucket,'/', to)

}

#' s3_delete_file
#' @param bucket Bucket to upload to
#' @param file File to delete
#' @export s3_delete_file
s3_delete_file <- function(bucket,
                           file) {

  s3 = client_s3()

  response <-
    s3$delete_object(Bucket   = bucket,
                     Key      = file)

  if(response$ResponseMetadata$HTTPStatusCode == 204) {
    TRUE
  }

}
