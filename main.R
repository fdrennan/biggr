library(biggr)

paramiko <- import('paramiko')

run_command <- function(con, command) {
  as.character(con$exec_command(command)[[2]]$read())
}

send_file <- function(con, local_path, remote_path) {
  ftp_client = con$open_sftp()
  ftp_client$put(local_path, remote_path)
  ftp_client$close()
}


get_file <- function(self, remote_path, local_path) {
  ftp_client = con$open_sftp()
  ftp_client$get(remote_path, local_path)
  ftp_client$close()
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

if (TRUE) {
  security_group_delete(security_group_id = security_group_id)

  security_group_create(security_group_name = security_group_name,
                        description = 'Ports for Production')

  security_group_id <-
    security_group_envoke(sg_name = security_group_name,
                          ports = c(22, 80, 8000:8020, 8787, 5432, 5439, 3000, 8080),
                          get_ip())
}

response <-
  ec2_instance_create(ImageId = 'ami-0010d386b82bc06f0',
                      InstanceType='t2.2xlarge',
                      min = 3,
                      max = 3,
                      KeyName = 'fdren',
                      SecurityGroupId = security_group_id,
                      InstanceStorage = 50,
                      DeviceName = "/dev/sda1",
                      user_data  = readr::read_file('instance.sh'))


ip_addresses <- map_chr(response, function(x) x$public_ip_address)

# walk(response, function(x) x$terminate())
# ec2_instance_info()

nginx_conf <- glue('
events {}

http {
    autoindex on;
    autoindex_exact_size off;
    fastcgi_read_timeout 900;
    proxy_read_timeout 900;

    upstream devurl {
        server --ip_addresses[[1]]--:8000;
        server --ip_addresses[[1]]--:8001;
    }

    upstream betaurl {
        server --ip_addresses[[2]]--:8000;
        server --ip_addresses[[2]]--:8001;
    }

    upstream produrl {
        server --ip_addresses[[3]]--:8000;
        server --ip_addresses[[3]]--:8001;
    }

    server {

        listen 80;

        location /dev/ {
            proxy_pass http://devurl/;
        }

        location /beta/ {
            proxy_pass http://betaurl/;
        }

        location /prod/ {
            proxy_pass http://produrl/;
        }

    }
}
', .open = '--', .close = '--')

# walk(response[2:3], function(x) x$terminate())

sleep_time <- 40
message(glue('Sleeping for {sleep_time} seconds'))
Sys.sleep(sleep_time)
ssh = paramiko$SSHClient()
ssh$set_missing_host_key_policy(paramiko$AutoAddPolicy())

map2(
  response,
  c('DEV', 'BETA', 'PROD'),
  function(server, server_name) {

    public_dns_name <- server$public_dns_name
    message(glue('Generating {public_dns_name}'))
    ssh$connect(server$public_dns_name,
                username='ubuntu',
                key_filename='fdren.pem')
    time = 1
    cumulative_wait = sleep_time
    while (str_detect(run_command(ssh, 'ls -lah') , 'user_data_running')) {
      Sys.sleep(time)
      cumulative_wait = cumulative_wait + time
      message(glue('You have been waiting for {cumulative_wait} seconds'))
    }

    # Refresh connection for docker usergroup modification
    ssh$connect(server$public_dns_name,
                username='ubuntu',
                key_filename='fdren.pem')
    # send_file(con = ssh, local_path = 'nginx/nginx.conf', remote_path = '/home/ubuntu/nginx.conf')
    # send_file(con = ssh, local_path = 'nginx/docker-compose.yaml', remote_path = '/home/ubuntu/docker-compose.yaml')
    cat(run_command(con = ssh, command = 'ls -lah'))
    run_command(ssh, 'git clone https://github.com/fdrennan/productor.git')
    # send_file(con = ssh, local_path = '.Renviron', remote_path = '/home/ubuntu/productor/.Renviron')
    # send_file(con = ssh, local_path = '.env', remote_path = '/home/ubuntu/productor/.env')
    send_file(con = ssh, local_path = 'docker.sh', remote_path = '/home/ubuntu/docker.sh')
    run_command(ssh, glue('echo SERVER={server_name} >> /home/ubuntu/productor/.Renviron'))
    cat(run_command(con = ssh, command = '. docker.sh'))
  }
)

#
#
