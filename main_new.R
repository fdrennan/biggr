library(biggr)
library(dbx)
library(ndexssh)

stages <- c('beta', 'master', 'dev')
master_branch <- 'master'
if (FALSE) {
   build_servers <- function() {
      library(furrr)
      plan(multiprocess)
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
                               ports = open_ports,
                               ips = open_ips)

      # Create Keyfile
      keyfile_creation <- tryCatch(expr = {
         keyfile_create(keyname = key_name)
      }, error =  function(err) {
         message(glue('Keyfile {key_name} Already Exists'))
      })

      servers_objects <-
         ec2_instance_create(ImageId = 'ami-0010d386b82bc06f0',
                             InstanceType='t2.large',
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
                              keyfile = "/Users/fdrennan/fdren.pem")

      stage_scripts <-
         map(
            stages,
            function(stage) {
               command_block <-c(
                  "#!/bin/bash",
                  "exec &> /home/ubuntu/dockerlogs.txt",
                  "ls -lah",
                  "sudo apt-get update -y",
                  "git clone https://github.com/fdrennan/docker_pull_postgres.git || echo 'Directory already exists...'",
                  "docker-compose -f docker_pull_postgres/docker-compose.yml pull",
                  "docker-compose -f docker_pull_postgres/docker-compose.yml down",
                  "docker-compose -f docker_pull_postgres/docker-compose.yml up -d",
                  "docker container ls",
                  "git clone https://github.com/fdrennan/productor.git",
                  glue("cd /home/ubuntu/productor && git checkout -b {stage} && git pull origin {stage}"),
                  glue("cd /home/ubuntu/productor && echo SERVER={stage} >> .env"),
                  glue("cd /home/ubuntu/productor && echo SERVER={stage} >> .Renviron"),
                  "cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R",
                  "cd /home/ubuntu/productor && docker-compose pull",
                  "cd /home/ubuntu/productor && docker-compose up -d --build productor_postgres",
                  "cd /home/ubuntu/productor && docker-compose up -d --build productor_initdb",
                  "cd /home/ubuntu/productor && docker-compose up -d --remove-orphans"
               )
            }
         )

      response <-
         future_map2(
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
               cmd_response
            }
         )
   }

   build_servers()
}




if (FALSE) {
   servers <- grab_servers()
   # map(servers, ~ try(.$terminate()))
   n <- 0
   while ( n < 3 ) {
      ids_to_start <- servers[[1]] %>%
         filter(state == 'running') %>%
         select(public_dns_name)
      #
      responses <- map(
         ids_to_start$public_dns_name,
         function(id) {
            message(glue('  KEYFILE: ssh -i "fdren.pem" ubuntu@{id}\n'))
            execute_command_to_server(
               command = 'tail dockerlogs.txt',
               hostname = id
            )
         }
      )
      n <- n + 1
      Sys.sleep(1)
   }
}

# Check Git Branch of Servers
if (FALSE) {
   servers <- grab_servers()

   ids_to_start <- servers[[1]] %>%
      filter(state == 'running') %>%
      select(public_dns_name)

   responses <- map(
      ids_to_start$public_dns_name,
      function(id) {
         message(glue('  KEYFILE: ssh -i "fdren.pem" ubuntu@{id}\n'))
         execute_command_to_server(
            command = 'cd productor && git branch',
            hostname = id
         )
      }
   )
}

# Checkout ALL to a SPECIFC Computer
if (FALSE) {

   servers <- grab_servers()

   ids_to_start <- servers[[1]] %>%
      filter(state == 'running') %>%
      select(public_dns_name)

   responses <- map2(
      ids_to_start$public_dns_name,
      stages,
      function(id, branch) {
         message(glue('  KEYFILE: ssh -i "fdren.pem" ubuntu@{id}\n'))
         execute_command_to_server(
            command = glue('cd productor && git reset --hard'),
            hostname = id
         )
         execute_command_to_server(
            command = glue('cd productor && git checkout -b {branch} && git pull origin {branch} && git branch'),
            hostname = id
         )
         execute_command_to_server(
            command = glue('cd productor && git checkout {branch} && git pull origin {branch} && git branch'),
            hostname = id
         )
         execute_command_to_server(
            command = glue('cd productor && ls -lah'),
            hostname = id
         )
      }
   )
}


if (TRUE) {
   servers <- grab_servers()

   ids_to_start <- servers[[1]] %>%
      filter(state == 'running') %>%
      select(public_dns_name)

   responses <- map2(
      ids_to_start$public_dns_name,
      stages,
      function(id, branch) {
         message(glue('  KEYFILE: ssh -i "fdren.pem" ubuntu@{id}\n'))
         message(paste(rep(branch, 5), collapse = '\n'))
         execute_command_to_server(
            command = glue('cd productor && git reset --hard'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && git checkout {branch} && git pull origin {branch} && git branch'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && Rscript update_env.R'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && cat .env'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && cat nginx*'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && cat nginx/nginx.conf'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('docker container ls'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && docker-compose -f docker-compose-{branch}.yaml pull'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && docker-compose -f docker-compose-{branch}.yaml reset'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && docker-compose -f docker-compose-{branch}.yaml down'),
            hostname = id
         )

         execute_command_to_server(
            command = glue('cd ~/productor && docker-compose -f docker-compose-{branch}.yaml up -d'),
            hostname = id
         )

      }
   )
}

#
# library(glue)
#
# LOCALHOST_IP <- Sys.getenv('LOCALHOST_IP')
# LOCALHOST_IP
#
#
#
#
#
# write(nginx_conf, file = file.path(Sys.getenv('PRODUCTOR_HOME'), 'shiny', 'nginx.conf'))
