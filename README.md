# INSTALLATION

To get the package on your computer, run the following command.
```
devtools::install_github("fdrennan/awsR")
```

Once installed, run the following.
```
library(awsR)
install_python() # Only need to once
configure_aws(
          aws_access_key_id     = "XXXXXX",
          aws_secret_access_key = "XXXXXX",
          default.region        = "XXXXXX"
)
```


