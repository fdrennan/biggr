ec2_instance_create(ImageId = 'ami-0c55b159cbfafe1f0',
                    KeyName = 'Shiny',
                    InstanceType = 't2.large',
                    SecurityGroupId = 'sg-0e8841d7a144aa628')
instances = ec2_get_info()
instances %>%
  filter(launch_time == max(launch_time)) %>%
  .[1,1] %>%
  as.character()

library(RPostgreSQL)
library(tidyverse)
library(dbplyr)
library(lubridate)
library(DBI)

con <- dbConnect(PostgreSQL(),
                 # dbname   = 'linkedin',
                 host     = "13.58.241.103",
                 port     = 5432,
                 user     = "postgres",
                 password = "myPassword")

dbCreateTable(con, "iris", iris)
dbListTables(con)
