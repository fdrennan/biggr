#' boto
#' @export boto3
boto3 <- function() {
  import("boto3")
}


#' client_cost
#' @export client_cost
client_cost <- function() {
  boto$client("ce")
}

#' client_ec2
#' @export client_ec2
client_ec2 <- function() {
  boto$client("ec2")
}

#' client_s3
#' @export client_s3
client_s3 <- function() {
  boto$client("s3")
}
