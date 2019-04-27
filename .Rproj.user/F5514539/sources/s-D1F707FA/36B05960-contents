# global reference to scipy (will be initialized in .onLoad)
scipy <- NULL
boto <- NULL
subprocess <- NULL
sys <- NULL

.onLoad <- function(libname, pkgname) {
  # use superassignment to update global reference to scipy
  scipy <<- reticulate::import("scipy", delay_load = TRUE)
  subprocess <<- reticulate::import("subprocess", delay_load = TRUE)
  boto <<- reticulate::import("boto3", delay_load = TRUE)
  sys <<- reticulate::import("sys", delay_load = TRUE)
}
