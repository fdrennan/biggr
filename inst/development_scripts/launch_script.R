library(biggr)
library(tidyverse)


s3_upload_file(bucket = 'fdrennancsv',
               from   = 'inst/csv/library.zip',
               to     = 'library.zip',
               make_public = TRUE)

s3_upload_file(bucket = 'shellscriptsfdrennan',
               from   = 'inst/server_scripts/main_server.sh',
               to     = 'main_server.sh',
               make_public = TRUE)

user_data = paste("#!/bin/bash",
                  "whoami >> /tmp/whoami",
                  "pwd >> /tmp/whoami",
                  "wget https://s3.us-east-2.amazonaws.com/shellscriptsfdrennan/main_server.sh",
                  "sh main_server.sh",
                  sep = "\n")

ec2_instance_create(ImageId = 'ami-0c55b159cbfafe1f0',
                    KeyName = "Shiny",
                    InstanceStorage = 20L,
                    SecurityGroupId = 'sg-0e8841d7a144aa628',
                    user_data = user_data,
                    InstanceType = 't2.large')

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



library(RPostgreSQL)
library(dbplyr)
library(lubridate)
library(DBI)
con <- dbConnect(PostgreSQL(),
                 # dbname   = 'linkedin',
                 host     = public_ip,
                 port     = 5432,
                 user     = "postgres",
                 password = "password")

dbListTables(con)
# tbl(con, in_schema('public', 'mtcars'))

if(FALSE) {
  ec2_instance_terminate(instance_id)
}
