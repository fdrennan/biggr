library(reticulate)
use_python('/Users/digitalfirstmedia/.virtualenvs/r-reticulate/bin/python')
library(biggr)
library(tidyverse)

user_data_ami = paste("#!/bin/bash",
                  # "wget https://s3.us-east-2.amazonaws.com/shellscriptsfdrennan/spark_base.sh",
                  # "sh spark_base.sh >> /home/ubuntu/progress",
                  sep = "\n")

ec2_instance_create(ImageId = 'ami-013662bffdad2c895',
                    KeyName = "Shiny",
                    InstanceStorage = 35L,
                    SecurityGroupId = 'sg-0e8841d7a144aa628',
                    user_data = user_data_ami,
                    InstanceType = 't2.medium')


instances <- ec2_instance_info()

public_ip <-
  instances %>%
  filter(launch_time == max(launch_time),
         public_ip_address != "18.217.102.18") %>%
  pull(public_ip_address)

public_ip %>%
  str_replace_all("\\.", "\\-") %>%
  paste0('ssh -i "Shiny.pem" ubuntu@ec2-', ., '.us-east-2.compute.amazonaws.com') %>%
  cat

instance_id <-
  instances %>%
  filter(launch_time == max(launch_time),
         public_ip_address != "18.217.102.18") %>%
  pull(instance_id)

#master
# ssh -i "Shiny.pem" ubuntu@ec2-3-17-181-8.us-east-2.compute.amazonaws.com

# slave
# ssh -i "Shiny.pem" ubuntu@ec2-52-15-187-229.us-east-2.compute.amazonaws.com

# spark-2.1.0-bin-hadoop2.7/sbin/start-master.sh
# spark-2.1.0-bin-hadoop2.7/sbin/start-slave.sh 3.15.15.174:7077


library(sparklyr)

conf <- spark_config()
conf$spark.executor.memory <- "2GB"
conf$spark.memory.fraction <- 0.9

sc <- spark_connect(master="spark://18.221.87.238:7077",
                    version = "2.1.0",
                    config = conf,
                    spark_home = "/Users/digitalfirstmedia/spark/spark-2.4.0-bin-hadoop2.7/")


# sudo passwd ubuntu
if(FALSE) {
  for(i in instance_id) {
    ec2_instance_terminate(i)
  }
}

