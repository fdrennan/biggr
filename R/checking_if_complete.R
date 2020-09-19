#' checking_if_complete
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


  while (!all_done) {
    cat("\f")
    glue_me('The current time is {Sys.time()}')
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


      message(glue('\n\nLooking for {unique_file}'))
      current_directories <-
        map(dns_names,
            ~ {
              response <- execute_command_to_server(
                command = 'ls -lah',
                hostname = .,
                username = username,
                keyfile = keyfile
              )[[1]]
            })

      sleep_a_sec(sleep_time = 10)

      all_done <- all(map_lgl(current_directories, ~ str_detect(., unique_file)))

    }, error = function(err) {
      message(as.character(err))
      return(FALSE)
    })
  }
}
