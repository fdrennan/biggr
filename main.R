library(biggr)
library(dbx)

paramiko <- import('paramiko')

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
                      InstanceType='t2.2xlarge',
                      min = length(server_names),
                      max = length(server_names),
                      KeyName = 'fdren',
                      SecurityGroupId = security_group_id,
                      InstanceStorage = 50,
                      DeviceName = "/dev/sda1",
                      user_data  = readr::read_file('instance.sh'))

specify_server_priority(instance_ids = map_chr(response, ~ .$instance_id),
                        values = server_names)

servers <- server_info()
# dbxDelete(conn = con, table = 'server_stage', where = data.frame(stage = 'STAGE'))



sleep_time <- 60
message(glue('Sleeping for {sleep_time} seconds'))
Sys.sleep(sleep_time)

# Refresh Database
server_info()

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

    stage_transfer_file(local_path = 'docker.sh', remote_path = '/home/ubuntu/docker.sh', stage_name = server_name)
    stage_run_command(glue('echo SERVER={server_name} >> /home/ubuntu/productor/.Renviron'),
                      stage_name = server_name)
    stage_run_command('. docker.sh',
                      stage_name = server_name)
  }
)

map(
  server_names,
  function(server_name) {
    time = 1
    cumulative_wait = 0
    while (!str_detect(stage_run_command('ls -lah', stage_name = server_name) , 'docker_data_complete')) {
      Sys.sleep(time)
      cumulative_wait = cumulative_wait + time
      cat(
        cat(stage_run_command(command = 'tail -n 30 docker.txt'))
      )
    }
  }
)


sns_send_message(phone_number = Sys.getenv('PHONE'), message = 'All Done')

server_info()$instances$stop()
