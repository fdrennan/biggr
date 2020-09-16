#' @importFrom purrr map_df
#' @importFrom tibble tibble
#' @export grab_servers
grab_servers <- function() {
  servers_list <- resource_ec2()$instances$all()
  servers <- map_df(
    iterate(servers_list$all()),
    function(x) {
      servers <- tibble(
        public_ip_address = ifelse(is.null(x$public_ip_address), 'missing', x$public_ip_address),
        id = x$id,
        image_id = x$image_id,
        instance_id = x$instance_id,
        instance_type = x$instance_type,
        launch_time = as.numeric(x$launch_time),
        public_dns_name = x$public_dns_name,
        state = x$state$Name
      )
      servers
    }
  )
  list(servers, servers_list)
}
