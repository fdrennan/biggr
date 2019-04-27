#' install_python: sets up python environment for awsR
#' @param method  method argument for py_install
#' @param conda  conda argument for py_install
#' @export install_python
install_python <- function(method = "auto", conda = "auto") {
  reticulate::py_install("scipy", method = method, conda = conda)
  reticulate::py_install("awscli", method = method, conda = conda)
  reticulate::py_install("boto3", method = method, conda = conda)
}

#' configure_aws
#' @param aws_access_key_id IAM access key ID
#' @param aws_secret_access_key IAM secret access key
#' @param default.region AWS preferred region
#' @export configure_aws
configure_aws <- function(aws_access_key_id = NA,
                          aws_secret_access_key = NA,
                          default.region = NA) {

  access_key <-
    paste("aws configure set aws_access_key_id", aws_access_key_id)

  aws_secret_access_key <-
    paste("aws configure set aws_secret_access_key", aws_secret_access_key)

  default_region <-
    paste("aws configure set default.region", default.region)

  subprocess$call(access_key, shell=TRUE)
  subprocess$call(aws_secret_access_key, shell=TRUE)
  subprocess$call(default_region, shell=TRUE)


}

