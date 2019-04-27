# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Cmd + Shift + B'
#   Check Package:             'Cmd + Shift + E'
#   Test Package:              'Cmd + Shift + T'


#' @export install_python
install_python <- function(method = "auto", conda = "auto") {
  reticulate::py_install("scipy", method = method, conda = conda)
  reticulate::py_install("awscli", method = method, conda = conda)
  reticulate::py_install("boto3", method = method, conda = conda)
}

#' @export configure_aws
configure_aws <- function(aws_access_key_id = NULL,
                          aws_secret_access_key = NULL,
                          default.region = NULL) {

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

