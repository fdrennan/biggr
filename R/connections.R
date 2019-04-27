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
