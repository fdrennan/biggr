#' @description Check to see if complete file exists
#' @importFrom glue glue
#' @importFrom purrr walk map map_lgl
#' @importFrom stringr str_detect
#' @param dns_names dns names
#' @param username username
#' @param password password
#' @param unique_file unique_file
#' @param keyfile keyfile
#' @export checking_if_complete
checking_if_complete <- function(dns_names = NULL,
                                 username = "ubuntu",
                                 password = "password",
                                 unique_file = "complete",
                                 follow_file = NULL,
                                 keyfile = "/Users/fdrennan/fdren.pem") {
  all_done <- FALSE
  sleep_time <- 1
  total_iterations <- 0
  while (!all_done) {
    message(glue('Waiting for {sleep_time} seconds'))
    message(glue('Iteration number {total_iterations}'))

    Sys.sleep(sleep_time)
    total_iterations = total_iterations + 1

    all_done <- tryCatch(expr = {

      if (!is.null(follow_file)) {
        status <-
          map(dns_names,
              ~ {
                response <- execute_command_to_server(
                  command = glue('tail {follow_file}'),
                  hostname = .,
                  username = username,
                  keyfile = keyfile
                )[[1]]

                cat(response)
                response
              })
      }


      current_directories <-
        map(dns_names,
            ~ {
              response <- execute_command_to_server(
                command = 'ls -la',
                hostname = .,
                username = username,
                keyfile = keyfile
              )[[1]]
            })

      all_done <- all(map_lgl(current_directories, ~ str_detect(., unique_file)))

    }, error = function(err) {
      message(as.character(err))
      return(FALSE)
    })
  }
}
