#' security_group_create
#' @importFrom purrr keep
#' @importFrom dplyr filter
#' @importFrom dplyr pull
#' @param  group_name Name of security group
#' @export security_group_create
security_group_create <- function(group_name = NA) {

  resource <- resource_ec2()
  client <- client_ec2()

  security_group_df <- security_group_list()

  if(!any(security_group_df$group_name == group_name)) {
    create_security <-
      resource$create_security_group(
        GroupName=group_name,
        Description='for automated server'
      )

    create_security$authorize_ingress(
      IpProtocol = "tcp",
      CidrIp     = "0.0.0.0/0",
      FromPort   = 0L,
      ToPort     = 65535L
    )

    security_group_id <-
      create_security$id

  } else {
    security_group_id = security_group_df %>%
      filter(group_name == group_name) %>%
      pull(group_id)
  }

  security_group_id
}
