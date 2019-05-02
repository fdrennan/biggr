#' ec2_instance_stop
#' @param ids An aws ec2 id: i.e., 'i-034e6090b1eb879e7'
#' @param terminate An boolean to specify whether to stop or terminate
#' @export ec2_instance_stop
ec2_instance_stop = function(ids, terminate = FALSE) {

  if(terminate) {
    resp <- readline(prompt="Are you sure you want to terminate this instance? All data will be destroyed - y/n: ")
    if(resp != 'y') {
      stop()
    }
  }
  resource = resource_ec2()
  ids = list(ids)
  instances = resource$instances
  if(terminate) {
    instances$filter(InstanceIds = ids)$terminate()
  } else {
    instances$filter(InstanceIds = ids)$stop()
  }
}
