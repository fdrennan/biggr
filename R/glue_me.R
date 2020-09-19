#' glue_me
#' @importFrom glue glue
#' @param string_value Any string
#' @export glue_me
glue_me <- function(string_value='') {
  message(glue(string_value))
}
