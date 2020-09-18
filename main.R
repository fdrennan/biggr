

library(biggr)
library(dbx)
library(ndexssh)
# library(furrr)
# plan(multiprocess)

stages <- c('dev', 'beta', 'master')


# Create Security Group
security_group_name <- 'production'
security_group_description <- 'Ports for Production'
key_name <- 'fdren'
open_ports <- c(22, 80, 6000, 8000:8020, 8787, 5432, 5439, 3000, 8080)
open_ips <- get_ip()

security_group_create(security_group_name = security_group_name,
                      description = security_group_description)


security_group_id <-
   security_group_envoke(sg_name = security_group_name,
                         ports = open_ports)

# Create Keyfile
keyfile_creation <- tryCatch(expr = {
   keyfile_create(keyname = key_name)
}, error =  function(err) {
   message(glue('Keyfile {key_name} Already Exists'))
})

servers_objects <-
   ec2_instance_create(ImageId = 'ami-0010d386b82bc06f0',
                       InstanceType='t2.xlarge',
                       min = length(stages),
                       max = length(stages),
                       KeyName = key_name,
                       SecurityGroupId = security_group_id,
                       InstanceStorage = 30,
                       DeviceName = "/dev/sda1",
                       user_data  = readr::read_file('instance.sh'))



sleep_a_sec <- function(sleep_steps = 3,
                        sleep_time = 2) {

   sleep_quote <- function(sleep_time) {
      quote <- statquotes::statquote()
      message(quote$text)
      message(quote$source)
      Sys.sleep(sleep_time)
   }
   walk(
      sleep_steps:1,
      function(x) {
         message(glue('Sleeping for {x*sleep_time} more seconds\n\n'))
         sleep_quote(sleep_time = sleep_time)
      }
   )
}

sleep_a_sec(sleep_time = 10)

dns_names <- map_chr(servers_objects, function(x) {x$public_dns_name})


# CHECK IF INSTALLATION SCRIPT IS COMPLETE --------------------------------


initial_script_complete <-
   checking_if_complete(dns_names = dns_names,
                        username = "ubuntu",
                        follow_file = '/home/ubuntu/logfile.txt',
                        unique_file = 'user_data_complete',
                        keyfile = "/Users/fdrennan/fdren.pem")

# SET UP POSTGRES ---------------------------------------------------------


stage_scripts <-
   map(
      stages,
      function(stage) {
         command_block <-c(
            "#!/bin/bash",

            "sudo rm /home/ubuntu/logfile.txt",
            "exec &> /home/ubuntu/logfile.txt",

            "ls -lah",
            "sudo apt-get update -y",
            "git clone https://github.com/fdrennan/docker_pull_postgres.git || echo 'Directory already exists...'",
            "docker-compose -f docker_pull_postgres/docker-compose.yml pull",
            "docker-compose -f docker_pull_postgres/docker-compose.yml down",
            "docker-compose -f docker_pull_postgres/docker-compose.yml up -d",


            "touch /home/ubuntu/productor_logs_complete"
         )
      }
   )

response <-
   map2(
      stage_scripts,
      dns_names,
      function(script, dns) {
         script_name <- glue('{dns}script.sh')
         writeLines(text = script, con = script_name)
         message(glue('Building {dns}'))
         send_file(hostname = dns,
                   username = "ubuntu",
                   keyfile = "/Users/fdrennan/fdren.pem",
                   local_path = script_name,
                   remote_path = glue('/home/ubuntu/{script_name}'))
         cmd_response <- execute_command_to_server(
            command = glue('. /home/ubuntu/{script_name}'),
            hostname = dns
         )
         fs::file_delete(script_name)
         cmd_response
      }
   )

dockerlogs_script_complete <-
   checking_if_complete(dns_names = dns_names,
                        username = "ubuntu",
                        follow_file = 'logfile.txt',
                        unique_file = 'productor_logs_complete',
                        keyfile = "/Users/fdrennan/fdren.pem")



# INSTALL R AND UPDATE ENVIRONMENT ----------------------------------------


stage_scripts <-
   map(
      stages,
      function(branch) {
         command_block <-c(
            "#!/bin/bash",

            "sudo rm /home/ubuntu/logfile.txt",
            "sudo rm /home/ubuntu/productor_logs_complete",
            "exec &> /home/ubuntu/logfile.txt",

            "git clone https://github.com/fdrennan/productor.git",
            glue('cd /home/ubuntu/productor && echo SERVER={branch} >> .env'),
            glue("cd /home/ubuntu/productor && echo SERVER={branch} >> .Renviron"),
            glue('cd productor && git reset --hard'),
            glue("cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R"),
            glue('cd ~/productor && git checkout {branch} && git pull origin {branch} && git branch'),

            "touch /home/ubuntu/productor_logs_complete"
         )
      }
   )

response <-
   map2(
      stage_scripts,
      dns_names,
      function(script, dns) {
         script_name <- glue('{dns}script.sh')
         writeLines(text = script, con = script_name)
         message(glue('Building {dns}'))
         send_file(hostname = dns,
                   username = "ubuntu",
                   keyfile = "/Users/fdrennan/fdren.pem",
                   local_path = script_name,
                   remote_path = glue('/home/ubuntu/{script_name}'))
         cmd_response <- execute_command_to_server(
            command = glue('. /home/ubuntu/{script_name}'),
            hostname = dns
         )
         fs::file_delete(script_name)
         cmd_response
      }
   )


dockerlogs_script_complete <-
   checking_if_complete(dns_names = dns_names,
                        username = "ubuntu",
                        follow_file = 'logfile.txt',
                        unique_file = 'productor_logs_complete',
                        keyfile = "/Users/fdrennan/fdren.pem")


# BUILD DOCKER SERVICE


stage_scripts <-
   map(
      stages,
      function(branch) {
         command_block <-c(
            "#!/bin/bash",

            "sudo rm /home/ubuntu/logfile.txt",
            "sudo rm /home/ubuntu/productor_logs_complete",
            "exec &> /home/ubuntu/logfile.txt",

            glue("cd /home/ubuntu/productor && docker-compose -f docker-compose-{branch}.yaml pull"),
            glue("cd /home/ubuntu/productor && docker-compose -f docker-compose-{branch}.yaml up -d --build productor_postgres"),
            glue("cd /home/ubuntu/productor && docker-compose -f docker-compose-{branch}.yaml up -d --build productor_initdb"),
            glue("cd /home/ubuntu/productor && docker-compose -f docker-compose-{branch}.yaml up -d"),

            "touch /home/ubuntu/productor_logs_complete"

         )
      }
   )

response <-
   map2(
      stage_scripts,
      dns_names,
      function(script, dns) {
         script_name <- glue('{dns}script.sh')
         writeLines(text = script, con = script_name)
         message(glue('Building {dns}'))
         send_file(hostname = dns,
                   username = "ubuntu",
                   keyfile = "/Users/fdrennan/fdren.pem",
                   local_path = script_name,
                   remote_path = glue('/home/ubuntu/{script_name}'))
         cmd_response <- execute_command_to_server(
            command = glue('. /home/ubuntu/{script_name}'),
            hostname = dns
         )
         fs::file_delete(script_name)
         cmd_response
      }
   )


dockerlogs_script_complete <-
   checking_if_complete(dns_names = dns_names,
                        username = "ubuntu",
                        follow_file = 'logfile.txt',
                        unique_file = 'productor_logs_complete',
                        keyfile = "/Users/fdrennan/fdren.pem")








# servers <- grab_servers()
# map(servers, ~ try(.$terminate()))
# system('rm ec2*.sh')
