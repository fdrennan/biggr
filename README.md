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

## Connecting to an ec2 client

Client is a lower level wrapper. Most functions will use the resource function.
```{r}
client = client_ec2()
```

## Connecting to an ec2 resource
```{r}
resource = resource_ec2()
```

Using the resource connection, you can create, change the status of, and get information about your ec2 instances.

```{r}
ec2_data = get_ec2_info()
```

```
# A tibble: 6 x 7
  public_ip_addre… priviate_ip_add… image_id instance_id launch_time        
  <chr>            <chr>            <chr>    <chr>       <dttm>             
1 NA               172.31.35.224    ami-0c5… i-0f49b651… 2019-04-27 18:14:32
2 NA               172.31.42.198    ami-0c5… i-0c36f716… 2019-04-27 18:11:33
3 18.217.102.18    172.31.27.124    ami-06d… i-0fdab899… 2019-04-27 18:32:51
4 NA               172.31.44.30     ami-017… i-0bfbb430… 2019-04-27 18:47:53
5 NA               172.31.45.198    ami-0c5… i-0045ea7f… 2019-04-27 18:20:18
6 NA               172.31.32.48     ami-0c5… i-00270b7f… 2019-04-27 18:26:10
# … with 2 more variables: instance_type <chr>, state <chr>
```

Now let's create an instance and then destroy it.

```{r}
instance_ec2_create(resource, 
                    ImageId = 'ami-0174e69c12bae5410', 
                    InstanceType='t2.nano', 
                    min = 1, 
                    max = 1)
```

```
[[1]]
ec2.Instance(id='i-091d4fdcd1d9dffa5')                
```
We can verify that it does get created.
```{r}
ec2_data = get_ec2_info()
new_instances = ec2_data %>% filter(launch_time >= Sys.time() - minutes(5))
```

```
# A tibble: 1 x 7
  public_ip_address priviate_ip_addr… image_id  instance_id  launch_time         instance_type state
  <chr>             <chr>             <chr>     <chr>        <dttm>              <chr>         <chr>
1 18.220.108.19     172.31.41.49      ami-0174… i-091d4fdcd… 2019-04-27 19:08:28 t3.micro      runn…

```

And finally we terminate or stop it it
```{r}
result = instance_ec2_stop(resource, new_instances$instance_id, terminate = FALSE)
```

```
[[1]]
[[1]]$StoppingInstances
[[1]]$StoppingInstances[[1]]
[[1]]$StoppingInstances[[1]]$InstanceId
[1] "i-091d4fdcd1d9dffa5"

[[1]]$StoppingInstances[[1]]$CurrentState
[[1]]$StoppingInstances[[1]]$CurrentState$Code
[1] 64

[[1]]$StoppingInstances[[1]]$CurrentState$Name
[1] "stopping"


[[1]]$StoppingInstances[[1]]$PreviousState
[[1]]$StoppingInstances[[1]]$PreviousState$Code
[1] 16

[[1]]$StoppingInstances[[1]]$PreviousState$Name
[1] "running"




[[1]]$ResponseMetadata
[[1]]$ResponseMetadata$RetryAttempts
[1] 0

[[1]]$ResponseMetadata$HTTPStatusCode
[1] 200

[[1]]$ResponseMetadata$RequestId
[1] "bd29f15b-18c9-44de-ad3d-5f04c91cbcf6"

[[1]]$ResponseMetadata$HTTPHeaders
[[1]]$ResponseMetadata$HTTPHeaders$date
[1] "Sat, 27 Apr 2019 19:09:02 GMT"

[[1]]$ResponseMetadata$HTTPHeaders$`content-length`
[1] "579"

[[1]]$ResponseMetadata$HTTPHeaders$`content-type`
[1] "text/xml;charset=UTF-8"

[[1]]$ResponseMetadata$HTTPHeaders$server
[1] "AmazonEC2"
```
