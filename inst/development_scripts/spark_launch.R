# devtools::install_github("fdrennan/biggr")

library(biggr)
library(reticulate)
library(tidyverse)
# install_python(envname = 'biggr')
use_virtualenv('biggr')
# configure_aws(
#   aws_access_key_id     = "XXXX",
#   aws_secret_access_key = "XXX",
#   default.region        = "us-east-2"
# )

spark_master <- function(
  InstanceType='t2.medium',
  KeyName = NA,
  SecurityGroupId = NA,
  InstanceStorage = 50
) {

  running_instances <- ec2_instance_info()

  user_data_ami = paste("#!/bin/bash",
                        "/home/ubuntu/spark-2.1.0-bin-hadoop2.7/sbin/start-master.sh",
                        sep = "\n")

  ec2_instance_create(ImageId = 'ami-00c36ebbb7d6aa249',
                      KeyName = KeyName,
                      InstanceStorage = InstanceStorage,
                      SecurityGroupId = SecurityGroupId,
                      user_data = user_data_ami,
                      InstanceType = InstanceType)


  updated_running_instances <- ec2_instance_info()

  master_data <- filter(
    updated_running_instances,
    !updated_running_instances$instance_id %in% running_instances$instance_id
  )

  master_data
}


spark_slave <- function(
  InstanceType='t2.medium',
  KeyName = NA,
  SecurityGroupId = NA,
  InstanceStorage = 50,
  n_instances = 2,
  master_ip = NULL
) {

  running_instances <- ec2_instance_info()

  user_data_ami = paste("#!/bin/bash",
                        paste0("/home/ubuntu/spark-2.1.0-bin-hadoop2.7/sbin/start-slave.sh ", master_ip, ":7077"),
                        sep = "\n")

  for(instance in 1:n_instances) {
    ec2_instance_create(ImageId = 'ami-00c36ebbb7d6aa249',
                        KeyName = KeyName,
                        InstanceStorage = InstanceStorage,
                        SecurityGroupId = SecurityGroupId,
                        user_data = user_data_ami,
                        InstanceType = InstanceType)
  }

  updated_running_instances <- ec2_instance_info()

  slave_data <- filter(
    updated_running_instances,
    !updated_running_instances$instance_id %in% running_instances$instance_id
  )

  slave_data
}


master_data <- spark_master(
  KeyName = "Shiny",
  InstanceStorage = 35L,
  SecurityGroupId = 'sg-0e8841d7a144aa628',
  InstanceType = 't2.medium'
)

slave_data <- spark_slave(
  KeyName = "Shiny",
  InstanceStorage = 35L,
  SecurityGroupId = 'sg-0e8841d7a144aa628',
  InstanceType = 't2.medium',
  n_instances = 30,
  master_ip = master_data$public_ip_address
)

slave_data$public_ip_address[1] %>%
  str_replace_all("\\.", "\\-") %>%
  paste0('ssh -i "Shiny.pem" ubuntu@ec2-', ., '.us-east-2.compute.amazonaws.com') %>%
  cat

master_data$public_ip_address

if(TRUE) {
  for(i in c(master_data$instance_id, slave_data$instance_id)) {
    print(i)
    ec2_instance_terminate(i, force = TRUE)
  }
}









