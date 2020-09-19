#' sleep_a_sec
#' @param sleep_steps = 3,
#' @param sleep_time = 2
#' @export sleep_a_sec
sleep_a_sec <- function(sleep_steps = 3,
                        sleep_time = 10) {

  sleep_quote <- function(sleep_time) {
    quote <- statquotes::statquote()
    message(quote$text)
    message(quote$source)
    Sys.sleep(sleep_time)
  }
  walk(
    sleep_steps:1,
    function(x) {
      message(glue('\n\nSleeping for {x*sleep_time} more seconds\n\n'))
      sleep_quote(sleep_time = sleep_time)
    }
  )
}
