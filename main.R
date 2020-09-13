library(biggr)
library(dbx)
# a <- server_info()
paramiko <- import('paramiko')


get_server_stage <- function() {
  con <- suppressMessages(postgres_connector())
  on.exit(dbDisconnect(con))
  tbl(con, in_schema('public', 'server_stage')) %>% collect
}

tryCatch(expr = {
  keyfile_create(keyname = 'fdren')
}, error =  function(err) {
  message('Keyfile Already Exists')
})

security_group_name <- 'production'

security_group_create(security_group_name = security_group_name,
                      description = 'Ports for Production')

security_group_id <-
  security_group_envoke(sg_name = security_group_name,
                        ports = c(22, 80, 8000:8020, 8787, 5432, 5439, 3000, 8080),
                        get_ip())

server_names <- c('DEV', 'BETA', 'PROD')

response <-
  ec2_instance_create(ImageId = 'ami-0010d386b82bc06f0',
                      InstanceType='t2.large',
                      min = length(server_names),
                      max = length(server_names),
                      KeyName = 'fdren',
                      SecurityGroupId = security_group_id,
                      InstanceStorage = 30,
                      DeviceName = "/dev/sda1",
                      user_data  = readr::read_file('instance.sh'))

specify_server_priority(instance_ids = map_chr(response, ~ .$instance_id),
                        values = server_names)

sleep_time <- 60
message(glue('Sleeping for {sleep_time} seconds'))
Sys.sleep(sleep_time)

# Refresh Database
servers <- server_info()

map2(
  response,
  server_names,
  function(server, server_name) {
    server_info()
    time = 1
    cumulative_wait = sleep_time
    while (str_detect(stage_run_command('ls -lah', stage_name = server_name) , 'user_data_running')) {
      Sys.sleep(time)
      cumulative_wait = cumulative_wait + time
      message(glue('You have been waiting for {cumulative_wait} seconds'))
      cat(stage_run_command(command = 'tail -n 30 logfile.txt'))
    }

    stage_run_command('ls -lah', stage_name = server_name)
    stage_run_command('git clone https://github.com/fdrennan/productor.git', stage_name = server_name)

    lower_server <- str_to_lower(server_name)
    stage_run_command(command = glue('cd /home/ubuntu/productor && git checkout -b {lower_server} && git pull origin {lower_server}'),
                      stage_name = server_name)

    if (lower_server == 'prod') {
      stage_transfer_file(local_path = glue('docker.sh'), remote_path = '/home/ubuntu/docker.sh', stage_name = server_name)
    } else {
      stage_transfer_file(local_path = glue('docker-{server_name}.sh'), remote_path = '/home/ubuntu/docker.sh', stage_name = server_name)
    }
    stage_run_command(glue('echo SERVER={server_name} >> /home/ubuntu/productor/.Renviron'),
                      stage_name = server_name)
    stage_run_command('. docker.sh',
                      stage_name = server_name)
  }
)

map(
  server_names,
  function(server_name) {
    message(glue('Monitoring over {server_name}'))
    lower_server <- str_to_lower(server_name)
    time = 1
    cumulative_wait = 0
    while (!str_detect(stage_run_command('ls -lah', stage_name = server_name) , 'docker_data_complete')) {
      Sys.sleep(time)
      cumulative_wait = cumulative_wait + time
      cat(
        cat(stage_run_command(command = 'tail -n 30 docker.txt'))
      )
    }
    if (lower_server == 'prod') {
      stage_run_command('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose.yaml pull', stage_name = server_name)
      stage_run_command(glue('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose.yaml up -d --build productor_postgres'), stage_name = server_name)
      stage_run_command('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose.yaml up -d --build productor_initdb', stage_name = server_name)
      stage_run_command('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose.yaml up -d --remove-orphans', stage_name = server_name)
    } else {
      stage_run_command(glue('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml pull'), stage_name = server_name)
      stage_run_command(glue('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml up -d --build productor_postgres'), stage_name = server_name)
      stage_run_command(glue('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml up -d --build productor_initdb'), stage_name = server_name)
      stage_run_command(glue('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml up -d --remove-orphans'), stage_name = server_name)
    }
  }
)


sns_send_message(phone_number = Sys.getenv('PHONE'), message = 'All Done')
# library(biggr)
# library(dbx)
# server_info()$instances$terminate()



# stage_run_command('/home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R', stage_name = 'BETA')
# stage_run_command('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml pull', stage_name = 'BETA')
# stage_run_command(glue('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml up -d --build productor_postgres'), stage_name = server_name)
# # stage_run_command('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml up -d --build productor_initdb', stage_name = server_name)
# stage_run_command('cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-{lower_server}.yaml up -d --remove-orphans', stage_name = server_name)

