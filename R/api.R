#' @export api_instance_start
api_instance_start <- function(instance_type = NULL,
                           key_name = NULL,
                           image_id = 'ami-0fc20dd1da406780b',
                           security_group_id = 'sg-0221bdbcdc66ac93c',
                           instance_storage = 50,
                           to_json = TRUE) {

  use_data <-
    paste( '#!/bin/bash',
           'cd /home/ubuntu',
           'wget https://s3.us-east-2.amazonaws.com/ndexr-files/startup.sh -P /home/ubuntu',
           'su ubuntu -c \'. /home/ubuntu/startup.sh &\'',
           # Something else
           sep = "\n")

  resp <-
    ec2_instance_create(ImageId = image_id,
                        InstanceType = instance_type,
                        KeyName = key_name,
                        SecurityGroupId = security_group_id,
                        InstanceStorage = instance_storage,
                        user_data = use_data)

  tibble(
    creation_time = Sys.time(),
    id = resp[[1]]$id,
    instance_type = instance_type,
    image_id = image_id,
    security_group_id = security_group_id,
    instance_storage = instance_storage
  )
}
