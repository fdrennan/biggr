# INSTALLATION

To get the package on your computer, run the following command.

```{r}
devtools::install_github("fdrennan/awsR")
```

Once installed, run the following.
```{r}
library(awsR)
install_python() # Only need to once
configure_aws(
          aws_access_key_id     = "XXXXXX",
          aws_secret_access_key = "XXXXXX",
          default.region        = "XXXXXX"
)
```
## EC2

### Connecting to an ec2 client

Client is a lower level wrapper. Most functions will use the resource function.
```{r}
client = client_ec2()
```

### Connecting to an ec2 resource
```{r}
resource = resource_ec2()
```

Using the resource connection, you can create, change the status of, and get information about your ec2 instances.

First, if you haven't created a key pair run the following commands. 

```{r}
key_pair <- client_ec2()$create_key_pair(KeyName='foo')
 
write.table(key_pair$KeyMaterial,
            file = 'foo.pem',
            row.names = FALSE, 
            col.names = FALSE, 
            quote = FALSE)
```

Then, run `chmod 400 foo.pem`

Now you're ready to create a server. 
```{r}
server <- 
  ec2_instance_create(ImageId = 'ami-0c55b159cbfafe1f0',
                      KeyName = 'foo',
                      InstanceType = 't2.medium',
                      InstanceStorage = 50,
                      postgres_password = 'password',
                      phone_number = 2549318313,
                      DeviceName = "/dev/sda1")
```

Get the most recent server data 
```{r}
ec2_info <- ec2_get_info() %>% 
  filter(state == 'running') %>%
  filter(launch_time == max(launch_time))
```

Check out the ec2_instance data
```{r}
glimpse(ec2_info)
```

```
Observations: 1
Variables: 7
$ public_ip_address   <chr> "18.188.34.221"
$ priviate_ip_address <chr> "172.31.12.51"
$ image_id            <chr> "ami-0c55b159cbfafe1f0"
$ instance_id         <chr> "i-09532cd8df558929a"
$ launch_time         <dttm> 2019-04-28 21:24:38
$ instance_type       <chr> "t2.medium"
$ state               <chr> "running"
```


Clean version of messaging I need to add to creation function. 
```{r}
ec2_info$public_ip_address %>% 
  str_replace_all('\\.', '\\-') %>% 
  paste0('ssh -i "foo.pem" ubuntu@ec2-', ., '.us-east-2.compute.amazonaws.com', collapse = "") %>% 
  paste("Please enter the follwing into your terminal", 
        ., 
        'Then type on the remote server to set your password: sudo passwd ubuntu',
        paste0('Login with the username ubuntu with the password you just set at RStudio Server: ', ec2_info$public_ip_address,  ":8787"),
        sep = "\n") %>% 
  message
```

```
Please enter the follwing into your terminal
ssh -i "foo.pem" ubuntu@ec2-18-188-34-221.us-east-2.compute.amazonaws.com
Then type on the remote server to set your password: sudo passwd ubuntu
Login with the username ubuntu with the password you just set at RStudio Server: 18.188.34.221:8787
```

Once you hear a ding, try connecting to the database using the instructions above. 
```{r}
library(RPostgreSQL)
library(tidyverse)
library(dbplyr)
library(lubridate)
library(DBI)

con <- dbConnect(PostgreSQL(),
                 # dbname   = 'linkedin',
                 host     = ec2_info$public_ip_address,
                 port     = 5432,
                 user     = "postgres",
                 password = "password")
```

Write to the database you just made. 
```{r}
dbWriteTable(con, 'mtcars', mtcars, append = TRUE)

mtcars_data <-
  tbl(con, in_schema('public', 'mtcars'))
  
head(mtcars_data) %>%
  collect
```

Terminate the instance
```{r}
ec2_instance_stop(ids = ec2_info$instance_id, terminate = TRUE)
```

Modify the instance
```{r}
client$modify_instance_attribute(InstanceId=ec2_info$instance_id, 
                                 Attribute='instanceType',
                                 Value='t2.small')

client$start_instances(InstanceIds = list(ec2_info$instance_id))
```


## S3

Create a bucket using `s3_create_bucket`

```{r}
s3_create_bucket(
  bucket_name = 'freddydbucket', 
  location = 'us-east-2'
)
```

```
$Location
[1] "http://freddydbucket.s3.amazonaws.com/"

$ResponseMetadata
$ResponseMetadata$HostId
[1] "G43iK+UUYoo31NbHC5QlAD5ci+6EJwbHulr0qNfy54i87jkPsPhcs14haR+Sg9jOgeyV70Z8URY="

$ResponseMetadata$RetryAttempts
[1] 0

$ResponseMetadata$HTTPStatusCode
[1] 200

$ResponseMetadata$RequestId
[1] "F639FDF93B2A8EA2"

$ResponseMetadata$HTTPHeaders
$ResponseMetadata$HTTPHeaders$date
[1] "Sat, 27 Apr 2019 23:24:09 GMT"

$ResponseMetadata$HTTPHeaders$`content-length`
[1] "0"

$ResponseMetadata$HTTPHeaders$`x-amz-request-id`
[1] "F639FDF93B2A8EA2"

$ResponseMetadata$HTTPHeaders$location
[1] "http://freddydbucket.s3.amazonaws.com/"

$ResponseMetadata$HTTPHeaders$`x-amz-id-2`
[1] "G43iK+UUYoo31NbHC5QlAD5ci+6EJwbHulr0qNfy54i87jkPsPhcs14haR+Sg9jOgeyV70Z8URY="

$ResponseMetadata$HTTPHeaders$server
[1] "AmazonS3"
```

Upload a file using `s3_upload_file`
```{r}
s3_upload_file(
    bucket = 'freddydbucket', 
    from = 'NAMESPACE', 
    to = 'uploaded_NAMESPACE'
)
```

Download a file using `s3_download_file`
```{r}
s3_download_file(
    bucket = 'freddydbucket', 
    from = 'uploaded_NAMESPACE', 
    to = 'downloaded_NAMESPACE'
)
```

