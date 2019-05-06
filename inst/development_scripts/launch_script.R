library(biggr)
library(tidyverse)

s3_upload_file(
  'shellscriptsfdrennan',
  'inst/server_scripts/main_server.sh',
  'main_server.sh',
  make_public = TRUE
)

user_data = paste("#!/bin/bash",
                  "whoami >> /tmp/whoami",
                  "pwd >> /tmp/whoami",
                  "wget https://s3.us-east-2.amazonaws.com/shellscriptsfdrennan/main_server.sh",
                  "sh main_server.sh >> /home/ubuntu/progress",
                  sep = "\n")

ec2_instance_create(ImageId = 'ami-0c55b159cbfafe1f0',
                    KeyName = "Shiny",
                    InstanceStorage = 100L,
                    SecurityGroupId = 'sg-0e8841d7a144aa628',
                    user_data = user_data,
                    InstanceType = 'r5.xlarge')

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
nyc <- tbl(con, in_schema('public', 'nyc'))

nyc <-
  nyc %>%
  rename_all(
    function(x) {
      str_replace_all(x, " ", "_") %>%
        str_to_lower()
    }
  )

nyc %>%
  group_by(plate_id) %>%
  count %>%
  arrange(desc(n))

if(FALSE) {
  ec2_instance_terminate(instance_id)
}
