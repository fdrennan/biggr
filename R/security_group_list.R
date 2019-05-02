#' security_group_list
#' @importFrom purrr map_df
#' @importFrom tibble tibble
#' @export security_group_list
security_group_list <- function() {
  resource <- resource_ec2()
  client <- client_ec2()

  response <- client$describe_security_groups()
  response <- response$SecurityGroups

  security_group_list <-
    map_df(response, function(x) {
      tibble(group_name = x$GroupName,
             group_id = x$GroupId)
    })

  security_group_list
}
