library(biggr)
library(dbx)
library(ndexssh)



stages <- c('BUILD', 'STARTUP', 'STOP')
BUILD_STAGE = stages[1]







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
   library(furrr)
   plan(multiprocess)
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

