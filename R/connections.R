#' client_ec2
#' @export client_ec2
client_ec2 <- function() {
  boto$client("ec2")
}

#' resource_ec2
#' @export resource_ec2
resource_ec2 <- function() {
  boto$resource("ec2")
}

#' client_s3
#' @export client_s3
client_s3 <- function() {
  boto$client("s3")
}

#' resource_s3
#' @export resource_s3
resource_s3 <- function() {
  boto$resource("s3")
}
