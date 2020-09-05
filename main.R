library(biggr)

run_command <- function(con, command) {
  as.character(con$exec_command(command)[[2]]$read())
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
                        ports = c(22, 80, 8000:8001),
                        '75.166.84.192')

response <-
  ec2_instance_create(ImageId = 'ami-0010d386b82bc06f0',
                      InstanceType='t2.xlarge',
                      min = 1,
                      max = 1,
                      KeyName = 'fdren',
                      SecurityGroupId = security_group_id,
                      InstanceStorage = 50,
                      DeviceName = "/dev/sda1",
                      user_data  = readr::read_file('instance.sh'))


ip_addresses <- map_chr(response, function(x) x$public_ip_address)
walk(response, function(x) x$terminate())
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

paramiko <- import('paramiko')

ssh = paramiko$SSHClient()
ssh$set_missing_host_key_policy(paramiko$AutoAddPolicy())
ssh$connect(response[[1]]$public_dns_name,
            username='ubuntu',
            key_filename='fdren.pem')


