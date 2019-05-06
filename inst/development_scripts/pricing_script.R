library(biggr)
library(tidyverse)

boto <- boto3()
client <- boto$client("pricing", region_name = "us-east-1")

pricing <- client$get_products(
  ServiceCode="AmazonEC2",
  Filters = list(
    list(
      Type = 'TERM_MATCH',
      Field = 'location',
      Value = 'US East (Ohio)'
    )
  )
)


price_list <-pricing$PriceList

prices <- price_list %>%
  map_df(
    function(x) {
      x <- x %>%
        fromJSON %>%
        unlist %>%
        enframe %>%
        mutate(
          name = str_extract(name, "\\.[:alnum:]+$"),
          name = str_remove_all(name, "\\.")
        ) %>%
        as.data.frame() %>%
        filter(!is.na(name))
      # browser()
      x = t(x)
      column_names <- x[1,]
      x = as.data.frame(t(x[2,]))
      colnames(x) = column_names
      x
    }
  )
