#' ec2_get_info
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


#' ec2_instance_stop
#' @param ids An aws ec2 id: i.e., 'i-034e6090b1eb879e7'
#' @param terminate An boolean to specify whether to stop or terminate
#' @export ec2_instance_stop
ec2_instance_stop = function(ids, terminate = FALSE) {

  if(terminate) {
    resp <- readline(prompt="Are you sure you want to terminate this instace? All data will be destroyed - y/n: ")
    if(resp != 'y') {
      stop()
    }
  }
  resource = resource_ec2()
  ids = list(ids)
  instances = resource$instances
  if(terminate) {
    instances$filter(InstanceIds = ids)$terminate()
  } else {
    instances$filter(InstanceIds = ids)$stop()
  }
}

#' ec2_instance_create
#' @param ImageId An aws ec2 id: i.e., 'ami-0174e69c12bae5410'
#' @param InstanceType See \url{https://aws.amazon.com/ec2/instance-types/}
#' @param min min instances
#' @param max max instances
#' @param KeyName A .pem file to ssh
#' @param SecurityGroupId SecurityGroupId of security group you have created in UI
#' @param InstanceStorage Size of the box in gb
#' @param postgres_password password for postgres database. username is postgres
#' @param phone_number For notification of completion
#' @param DeviceName  "/dev/sda1"
#' @export ec2_instance_create
ec2_instance_create <- function(ImageId = NA,
                                InstanceType='t2.nano',
                                min = 1,
                                max = 1,
                                KeyName = NA,
                                SecurityGroupId = NA,
                                InstanceStorage = 50,
                                postgres_password = 'password',
                                phone_number = NA,
                                DeviceName = "/dev/sda1") {
  if(is.na(KeyName)) {
    stop("Please input a KeyName or create one using the AWS UI.")
  }

  if(is.na(SecurityGroupId)) {
    SecurityGroupId <- security_group_create()
    message(SecurityGroupId)
  }

  user_data <- user_data_gen(postgres_password = postgres_password,
                             phone_number = phone_number)

  resource = resource_ec2()

  resource$create_instances(ImageId = ImageId,
                            MinCount = as.integer(min),
                            MaxCount = as.integer(max),
                            InstanceType=InstanceType,
                            UserData = user_data,
                            KeyName = KeyName,
                            SecurityGroupIds = list(SecurityGroupId),
                            BlockDeviceMappings = list(
                              list(
                                Ebs = list(
                                  VolumeSize = as.integer(InstanceStorage)
                                ),
                                DeviceName = DeviceName
                              )
                            )
  )
}

