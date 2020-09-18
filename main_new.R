library(biggr)
library(dbx)
library(ndexssh)


stop_all <- function() {
   servers <- grab_servers()
   map(servers, ~ try(.$stop()))
}

terminate_all <- function() {
   servers <- grab_servers()
   map(servers, ~ try(.$terminate()))
}

# SET PARAMETERS ----------------------------------------------------------


stages <- c('dev', 'beta', 'master')
security_group_name <- 'production'
security_group_description <- 'Ports for Production'
key_name <- 'fdren'
open_ports <- c(
   22, 80,
   3000,
   5432, 5439,
   6000,
   8000:8020, 8080, 8787
)
open_ips <- get_ip()


# CREATE SECURITY CREATE --------------------------------------------------
security_group_create(security_group_name = security_group_name,
                      description = security_group_description)

security_group_id <-
   security_group_envoke(sg_name = security_group_name,
                         ports = open_ports,
                         ips = open_ips)


# CREATE KEYFILE ----------------------------------------------------------

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

Sys.sleep(60)

dns_names <- map_chr(servers_objects, function(x) {x$public_dns_name})

initial_script_complete <-
   checking_if_complete(dns_names = dns_names,
                        username = "ubuntu",
                        follow_file = 'user_data_running',
                        unique_file = 'user_data_complete',
                        keyfile = "/Users/fdrennan/fdren.pem")

stage_scripts <-
   map(
      stages,
      function(stage) {
         command_block <-c(
            "#!/bin/bash",
            "exec &> /home/ubuntu/productor_logs.txt",
            "rm /home/ubuntu/productor_logs_complete",
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
                        follow_file = 'productor_logs.txt',
                        unique_file = 'productor_logs_complete',
                        keyfile = "/Users/fdrennan/fdren.pem")


stage_scripts <-
   map(
      stages,
      function(branch) {
         command_block <-c(
            "#!/bin/bash",
            "exec &> /home/ubuntu/productor_logs.txt",
            "git clone https://github.com/fdrennan/productor.git",
            glue('cd /home/ubuntu/productor && echo SERVER={branch} >> .env'),
            glue("cd /home/ubuntu/productor && echo SERVER={branch} >> .Renviron"),
            glue('cd productor && git reset --hard'),
            glue("cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R"),
            glue('cd ~/productor && git checkout {branch} && git pull origin {branch} && git branch'),
            command = glue('cd ~/productor && cat .env'),
            command = glue('cd ~/productor && cat .Renviron'),
            glue('cd ~/productor && cat nginx*'),
            glue('cd ~/productor && cat nginx/nginx.conf'),
            glue('cd ~/productor && docker-compose -f docker-compose-{branch}.yaml pull'),
            glue('cd ~/productor && docker-compose -f docker-compose-{branch}.yaml up -d'),
            "touch /home/ubuntu/git_commands_complete"
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
                        follow_file =  "productor_logs.txt",
                        unique_file = 'git_commands_complete',
                        keyfile = "/Users/fdrennan/fdren.pem")



# # system('rm ec2*.sh')
