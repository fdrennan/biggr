#' get_ec2_info
#' @export get_ec2_info
get_ec2_info <- function() {
  ec2_con = client_ec2()
  instances = ec2_con$describe_instances()

  map_df(instances$Reservations, function(x) {
    launch_time = ymd_hms(paste0(x$Instances[[1]]$LaunchTime))
    state = if_is_null(x$Instances[[1]]$State$Name)
    instance_id = if_is_null(x$Instances[[1]]$InstanceId)
    image_id = if_is_null(x$Instances[[1]]$ImageId)
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

#' instance_ec2_create
#' @param resource The result of resource_ec2
#' @param ids An aws ec2 id: i.e., 'i-034e6090b1eb879e7'
#' @param terminate An boolean to specify whether to stop or terminate
#' @export instance_ec2_stop
instance_ec2_stop = function(resource, ids, terminate = FALSE) {
  ids = list(ids)
  instances = resource$instances
  if(terminate) {
    instances$filter(InstanceIds = ids)$terminate()
  } else {
    instances$filter(InstanceIds = ids)$stop()
  }
}

#' instance_ec2_create
#' @param resource The result of resource_ec2
#' @param ImageId An aws ec2 id: i.e., 'ami-0174e69c12bae5410'
#' @param InstanceType See \url{https://aws.amazon.com/ec2/instance-types/}
#' @export instance_ec2_create
instance_ec2_create <- function(resource, ImageId = NA, InstanceType='t2.nano', min = 1, max = 1) {
  resource$create_instances(ImageId = ImageId,
                            MinCount = as.integer(min),
                            MaxCount = as.integer(max),
                            InstanceType='t3.micro')
}
