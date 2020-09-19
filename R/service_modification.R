#' @importFrom reticulate iterate
#' @importFrom purrr map
#' @export stop_service
stop_service <- function(wait = TRUE) {
  map(iterate(resource_ec2()$instances$all()), ~ try(.$stop()))
  if(wait) {
    map(iterate(resource_ec2()$instances$all()), ~ try(.$wait_until_stopped()))
  }
}

#' @importFrom reticulate iterate
#' @importFrom purrr map
#' @export start_service
start_service <- function(wait = TRUE) {
  map(iterate(resource_ec2()$instances$all()), ~ try(.$start()))
  if (wait) {
    map(iterate(resource_ec2()$instances$all()), ~ try(.$wait_until_running()))
  }
}

#' @importFrom reticulate iterate
#' @importFrom purrr map
#' @export terminate_service
terminate_service <- function(wait = TRUE) {
  map(iterate(resource_ec2()$instances$all()), ~ try(.$terminate()))
  if (wait) {
    map(iterate(resource_ec2()$instances$all()), ~ try(.$wait_until_terminated()))
  }
}
