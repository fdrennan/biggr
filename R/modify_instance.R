#' @export modify_instance
modify_instance <- function(id = NULL, method = NULL, instance_type = NULL) {
  if (is.null(id)) {
    stop('Must supply an instance id')
  }

  if (is.null(method) | !(method %in% c('start', 'stop', 'reboot', 'terminate', 'modify'))) {
    stop('Must supply an instance modification method: start, stop, reboot, terminate, modify')
  }

  switch(
    method,
    'start' = {
      tryCatch({
        ec2_instance_start(instance_id = id)
        return('Instance started')
      },
      error = function(err) {
        stop(err)
      })
    },
    'stop' = {
      tryCatch({
        ec2_instance_stop(ids = id)
        return('Instance stopping')
      },
      error = function(err) {
        stop(err)
      })
    },

    'reboot' = {
      tryCatch({
        ec2_instance_reboot(instance_id = id)
        return('Instance rebooting')
      },
      error  = function(err) {
        stop(err)
      })
    },

    'terminate' = {
      tryCatch({
        ec2_instance_terminate(ids = id, force = TRUE)
        return('Terminate success')
      },
      error = function(err) {
        stop('Terminate fail')
      })
    },

    'modify' = {
      if (is.null(instance_type)) {
        stop('Must supply an instance type, see https://aws.amazon.com/ec2/instance-types/ for applicable types')
      }
      tryCatch({
        ec2_instance_modify(instance_id = id, value = instance_type)
      },
      error = function(err) {
        stop(err)
      })
    }
  )
}

