#' security_group_create
#' @export security_group_create
security_group_create <- function() {

  resource <- resource_ec2()
  client <- client_ec2()

  security_group_names <-
    keep(client$describe_security_groups(), function(x) {
      # browser()
      if(!is.na(x[[1]]['GroupName'])) {
        x[[1]]['GroupName'] == "prog_r"
      } else {
        FALSE
      }
    })

  if(length(security_group_names) == 0) {
    create_security <-
      resource$create_security_group(
        GroupName='prog_r',Description='for automated server'
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
    security_group_id = security_group_names$SecurityGroups[[1]]$GroupId
  }

  security_group_id
}


