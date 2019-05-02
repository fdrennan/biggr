#' ec2_get_info
#' @importFrom lubridate ymd_hms
#' @export ec2_get_info
ec2_get_info <- function() {
  ec2_con = client_ec2()
  instances = ec2_con$describe_instances()
  map_df(instances$Reservations, function(x) {
    launch_time <-  ymd_hms(paste0(x$Instances[[1]]$LaunchTime))
    state <-  if_is_null(x$Instances[[1]]$State$Name)
    instance_id <-  if_is_null(x$Instances[[1]]$InstanceId)
    image_id <-  if_is_null(x$Instances[[1]]$ImageId)
    public_ip_address <- if_is_null(x$Instances[[1]]$PublicIpAddress)
    private_ip_address <- if_is_null(x$Instances[[1]]$PrivateIpAddress)
    instance_type <- if_is_null(x$Instances[[1]]$InstanceType)
    tibble(
      public_ip_address = public_ip_address,
      priviate_ip_address = private_ip_address,
      image_id = image_id,
      instance_id = instance_id,
      launch_time,
      instance_type = instance_type,
      state = state
    )
  })
}
