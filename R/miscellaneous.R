#' if_is_null
#' @param x  input
#' @export if_is_null
if_is_null <- function(x) {
  if_else(is.null(x), as.character(NA), x)
}
