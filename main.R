library(biggr)
library(dbx)
library(ndexssh)

# KILL EVERYTHING OFF -----------------------------------------------------
stop_service <- function(wait = TRUE) {
   map(iterate(resource_ec2()$instances$all()), ~ try(.$stop()))
   if(wait) {
      map(iterate(resource_ec2()$instances$all()), ~ try(.$wait_until_stopped()))
   }
}

start_service <- function(wait = TRUE) {
   map(iterate(resource_ec2()$instances$all()), ~ try(.$start()))
   if (wait) {
      map(iterate(resource_ec2()$instances$all()), ~ try(.$wait_until_running()))
   }
}

terminate_service <- function(wait = TRUE) {
   map(iterate(resource_ec2()$instances$all()), ~ try(.$terminate()))
   if (wait) {
      map(iterate(resource_ec2()$instances$all()), ~ try(.$wait_until_terminated()))
   }
}


stages <- c('BUILD', 'STARTUP', 'STOP')
BUILD_STAGE = stages[1]

# Build The Damn Things
build_service <- function(dns_names = NULL, stages = NULL) {
   stage_scripts <-
      map(stages,
          function(stage) {
             command_block <- c(
                "#!/bin/bash",
                "exec &> /home/ubuntu/post_install.txt",
                "ls -lah",
                "sudo apt-get update -y",
                "git clone https://github.com/fdrennan/docker_pull_postgres.git || echo 'Directory already exists...'",
                "docker-compose -f docker_pull_postgres/docker-compose.yml pull",
                "docker-compose -f docker_pull_postgres/docker-compose.yml down",
                "docker-compose -f docker_pull_postgres/docker-compose.yml up -d",
                "git clone https://github.com/fdrennan/productor.git",
                glue('cd /home/ubuntu/productor && echo SERVER={stage} >> .env'),
                glue(
                   'cd /home/ubuntu/productor && echo SERVER={stage} >> .bashrc'
                ),
                glue(
                   "cd /home/ubuntu/productor && echo SERVER={stage} >> .Renviron"
                ),
                glue('cd productor && git reset --hard'),
                glue(
                   "cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R"
                ),
                glue(
                   'cd /home/ubuntu/productor && git checkout {stage} && git pull origin {stage} && git branch'
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml pull"
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d --build productor_postgres"
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d --build productor_initdb"
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d"
                ),
                "touch /home/ubuntu/productor_logs_complete"
             )
          })

   response <-
      future_map2(stage_scripts,
                  dns_names,
                  function(script, dns) {
                     script_name <- glue('{dns}script.sh')
                     message(script)
                     writeLines(text = script, con = script_name)
                     message(glue('Building: ssh -i "~/fdren.pem" ubuntu@{dns}'))
                     send_file(
                        hostname = dns,
                        username = "ubuntu",
                        keyfile = "/Users/fdrennan/fdren.pem",
                        local_path = script_name,
                        remote_path = glue('/home/ubuntu/{script_name}')
                     )
                     cmd_response <- execute_command_to_server(command = glue('. /home/ubuntu/{script_name}'),
                                                               hostname = dns)
                     fs::file_delete(script_name)
                     cmd_response
                  }, .progress = TRUE)

}


# Build The Damn Things

rebuild_service <- function(dns_names = NULL, stages = NULL) {
   stage_scripts <-
      map(stages,
          function(stage) {
             command_block <- c(
                "#!/bin/bash",
                "rm /home/ubuntu/last_git_update_complete || echo 'last_git_update_complete does not exist'",
                "rm /home/ubuntu/last_git_update.txt || echo 'last_git_update does not exist'",
                "exec &> /home/ubuntu/last_git_update.txt",
                "docker-compose -f docker_pull_postgres/docker-compose.yml pull",
                "docker-compose -f docker_pull_postgres/docker-compose.yml down",
                "docker-compose -f docker_pull_postgres/docker-compose.yml up -d",
                glue('cd productor && git reset --hard'),
                glue(
                   "cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R"
                ),
                glue(
                   'cd /home/ubuntu/productor && git pull origin {stage} && git branch'
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml pull"
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d --build productor_postgres"
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d --build productor_initdb"
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml down"
                ),
                glue(
                   "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d"
                ),
                "touch /home/ubuntu/last_git_update_complete"
             )
          })

   library(furrr)
   plan(multiprocess)
   response <-
      future_map2(stage_scripts,
                  dns_names,
                  function(script, dns) {
                     script_name <- glue('{dns}script.sh')
                     writeLines(text = script, con = script_name)
                     message(glue('Building: ssh -i "~/fdren.pem" ubuntu@{dns}'))
                     send_file(
                        hostname = dns,
                        username = "ubuntu",
                        keyfile = "/Users/fdrennan/fdren.pem",
                        local_path = script_name,
                        remote_path = glue('/home/ubuntu/{script_name}')
                     )
                     cmd_response <- execute_command_to_server(command = glue('. /home/ubuntu/{script_name}'),
                                                               hostname = dns)
                     fs::file_delete(script_name)
                     cmd_response
                  }, .progress = TRUE)
}




if (BUILD_STAGE == 'BUILD') {
   # PARAMS ------------------------------------------------------------------
   library(furrr)
   plan(multiprocess)

   sleep_a_sec(sleep_steps = 3, sleep_time = 10)
   stages <- c('dev', 'beta', 'master')
   # Create Security Group
   security_group_name <- 'production'
   security_group_description <- 'Ports for Production'
   key_name <- 'fdren'
   open_ports <-
      c(22, 80, 6000, 8000:8020, 8787, 5432, 5439, 3000, 8080)
   image_id <-  'ami-0010d386b82bc06f0'
   instance_type <- 't2.xlarge'


   # SECURITY GROUPS AND KEYFILES --------------------------------------------
   security_group_create(security_group_name = security_group_name,
                         description = security_group_description)
   security_group_id <-
      security_group_envoke(sg_name = security_group_name,
                            ports = open_ports)
   keyfile_creation <- tryCatch(
      expr = {
         keyfile_create(keyname = key_name)
      },
      error =  function(err) {
         message(glue('Keyfile {key_name} Already Exists'))
      }
   )



   # BUILD THE SERVERS -------------------------------------------------------

   build_script <- readr::read_file('instance.sh')
   message(build_script)

   servers_objects <-
      ec2_instance_create(
         ImageId = image_id,
         InstanceType = instance_type,
         min = length(stages),
         max = length(stages),
         KeyName = key_name,
         SecurityGroupId = security_group_id,
         InstanceStorage = 30,
         DeviceName = "/dev/sda1",
         user_data  = build_script
      )


   # Wait a few, so we can get a good SSH connection first try. --------------

   sleep_a_sec(sleep_time = 10)


   # Get DNS NAMES -----------------------------------------------------------

   dns_table <-
      grab_servers()[[1]] %>% filter(state == 'running') %>%
      mutate(stages = stages)

   # CHECK IF INSTALLATION SCRIPT IS COMPLETE --------------------------------

   initial_script_complete <-
      checking_if_complete(
         dns_names = dns_table$public_dns_name,
         username = "ubuntu",
         follow_file = '/home/ubuntu/logfile.txt',
         unique_file = 'user_data_complete',
         keyfile = "/Users/fdrennan/fdren.pem"
      )


   readr::write_rds(dns_table, 'dns_table.rda')

   build_service(dns_names = dns_table$public_dns_name,
                 stages = dns_table$stages)


} else if (BUILD_STAGE == 'STARTUP') {
   start_service()
   sleep_a_sec(sleep_steps = 3, sleep_time = 10)
   dns_table <- readr::read_rds('dns_table.rda')
   rebuild_service(dns_names = dns_table$public_dns_name,
                   stages = dns_table$stages)
} else if (BUILD_STAGE == 'STOP') {
   stop_service()
}

# map(
#    dns_table$public_dns_name,
#    ~ get_file(
#       hostname = .,
#       username = "ubuntu",
#       keyfile = "/Users/fdrennan/fdren.pem",
#       local_path = glue('{.}-post_install.txt'),
#       remote_path = glue('/home/ubuntu/post_install.txt')
#    )
# )

# system('rm ec2*')

