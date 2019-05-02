#' security_group_create
#' @importFrom purrr keep
#' @importFrom dplyr filter
#' @importFrom dplyr pull
#' @export security_group_create
security_group_create <- function() {

  resource <- resource_ec2()
  client <- client_ec2()

  security_group_df <- security_group_list()

  if(!any(security_group_df$group_name == "prog_r")) {
    create_security <-
      resource$create_security_group(
        GroupName='prog_r',
        Description='for automated server'
      )

    create_security$authorize_ingress(
      IpProtocol="tcp",
      CidrIp="0.0.0.0/0",
      FromPort=0L,
      ToPort=65535L
    )

    security_group_id <-
      create_security$id

  } else {
    security_group_id = security_group_df %>%
      filter(group_name == "prog_r") %>%
      pull(group_id)
  }

  security_group_id
}
