library(biggr)
# install_python(envname = 'biggr')
use_virtualenv('biggr')

configure_aws(
  aws_access_key_id     = Sys.getenv('AWS_ACCESS'),
  aws_secret_access_key = Sys.getenv('AWS_SECRET'),
  default.region        = Sys.getenv('AWS_REGION')
)

message(glue('Within Plumber API {Sys.time()}'))


# serializer_excel <- function(){
#   function(val, req, res, errorHandler){
#     tryCatch({
#       res$setHeader("Content-Type", "application/vnd.ms-excel")
#       res$setHeader("Content-Disposition", 'attachment; filename=name_of_excel_file.xls')
#       res$body <- paste0(val, collapse="\n")
#       return(res$toResponse())
#     }, error=function(e){
#       errorHandler(req, res, e)
#     })
#   }
# }
#
# plumber::addSerializer("excel", serializer_excel)
#
# serializer_csv <- function(){
#   function(val, req, res, errorHandler){
#     tryCatch({
#       res$setHeader("Content-Type", "application/vnd.ms-excel")
#       res$setHeader("Content-Disposition", 'attachment; filename="xxx.csv"')
#       res$body <- paste0(val, collapse="\n")
#       return(res$toResponse())
#     }, error=function(e){
#       errorHandler(req, res, e)
#     })
#   }
# }
#
# plumber::addSerializer("csv", serializer_csv)





#* @filter cors
cors <- function(req, res) {
  message(glue('Within filter {Sys.time()}'))

  res$setHeader("Access-Control-Allow-Origin", "*")

  if (req$REQUEST_METHOD == "OPTIONS") {
    res$setHeader("Access-Control-Allow-Methods", "*")
    res$setHeader("Access-Control-Allow-Headers",
                  req$HTTP_ACCESS_CONTROL_REQUEST_HEADERS)
    res$status <- 200
    return(list())
  } else {
    plumber::forward()
  }

}
if(FALSE) {


  # #* @serializer csv
  # #* @get /csv
  # function() {
  #   df <- data.frame(CHAR = letters, NUM = rnorm(length(letters)), stringsAsFactors = F)
  #   csv_file <- tempfile(fileext = ".csv")
  #   on.exit(unlink(csv_file), add = TRUE)
  #   write.csv(df, file = csv_file)
  #   readLines(csv_file)
  # }

  #  EXCLUDED@jpeg (width = 1000, height = 800)
  #* @jpeg (width = 1523, height = 895)
  #* @param stocks  Stocks in JSON
  #* @param startDate  Stocks in JSON
  #* @param endDate  Stocks in JSON
  #* @param ma_days  Stocks in JSON
  #* @get /get_stocks
  function(stocks = '["AAPL"]',
           startDate = '2019-01-01',
           endDate = '2020-01-01',
           DATA = FALSE,
           ma_days = 50) {
    message(glue('Within get_stocks {Sys.time()}'))

    # Build the response object (list will be serialized as JSON)
    response <- list(
      statusCode = 200,
      data = "",
      message = "Success!",
      metaData = list(
        args = list(
          stocks = stocks,
          DATA = DATA,
          startDate = startDate,
          endDate = endDate,
          ma_days = ma_days
        ),
        runtime = 0
      )
    )


    response <- tryCatch({
      # Run the algorithm
      tic()
      response$data <- stockAPI::get_stocks(
        stocks = stocks,
        DATA = DATA,
        startDate = startDate,
        endDate = endDate,
        ma_days = ma_days
      )
      timer <- toc(quiet = T)
      response$metaData$runtime <- as.numeric(timer$toc - timer$tic)

      return(response)
    },
    error = function(err) {
      response$statusCode <- 400
      response$message <- paste(err)

      return(response)
    })

    return(response)


  }


  #* @param stocks  Stocks in JSON
  #* @param startDate  Stocks in JSON
  #* @param endDate  Stocks in JSON
  #* @get /get_stocks_data
  #* @serializer unboxedJSON
  function(stocks = '["AAPL"]',
           startDate = '2019-01-01',
           endDate = '2020-01-01',
           DATA = TRUE) {
    message(glue('Within get_stocks_data {Sys.time()}'))

    print(stocks)
    # Build the response object (list will be serialized as JSON)
    response <- list(
      statusCode = 200,
      data = "",
      message = "Success!",
      metaData = list(
        args = list(
          stocks = stocks,
          DATA = DATA,
          startDate = startDate,
          endDate = endDate
        ),
        runtime = 0
      )
    )


    response <- tryCatch({
      # Run the algorithm
      tic()
      response$data <- stockAPI::get_stocks(
        stocks = stocks,
        DATA = DATA,
        startDate = startDate,
        endDate = endDate
      )
      timer <- toc(quiet = T)
      response$metaData$runtime <- as.numeric(timer$toc - timer$tic)

      return(response)
    },
    error = function(err) {
      response$statusCode <- 400
      response$message <- paste(err)

      return(response)
    })

    return(response)


  }

  #* @serializer contentType list(type="application/vnd.ms-excel")
  #* @param file_name
  #* @param stocks
  #* @param startDate
  #* @param endDate
  #* @get /stocks_excel
  function(req,
           res,
           file_name = 'data.xlsx',
           stocks = '["AAPL", "AMZN"]',
           startDate = '2019-01-01',
           endDate = '2020-01-01',
           DATA = TRUE) {
    message(glue('Within stocks_excel {Sys.time()}'))
    res$setHeader("Content-Disposition",
                  glue('attachment; filename={file_name}.xlsx'))

    stock_data <- stockAPI::get_stocks(
      stocks = stocks,
      DATA = DATA,
      startDate = startDate,
      endDate = endDate
    )
    stock_data <- fromJSON(stock_data)

    wb <- createWorkbook()
    addWorksheet(wb, "stock_data")
    writeDataTable(wb = wb, sheet = "stock_data", x = stock_data)

    if (n_distinct(stock_data$symbol) > 1) {
      cor_stock_data <-
        stock_data %>%
        select(date, symbol, adjusted) %>%
        pivot_wider(names_from = symbol, values_from = c(adjusted)) %>%
        select_if(is.numeric) %>%
        cor

      addWorksheet(wb = wb, sheetName =  "correlations")
      writeDataTable(wb = wb,
                     sheet =  "correlations",
                     x = as.data.frame(cor_stock_data))
    }

    saveWorkbook(wb, file_name, overwrite = TRUE)

    bin <- readBin(file_name, "raw", n = file.info(file_name)$size)
    file.remove(file_name)

    bin
    # read.xlsx(filename, 'sheet_1')
    # write.csv(iris, filename, row.names = FALSE)
    # bin
  }

  #* @serializer contentType list(type="application/pdf")
  #* @get /pdf
  function(res,
           stocks = 2019,
           region = 'Asia',
           data = 'file2.csv',
           html_page = FALSE) {
    tmp <- tempfile()
    rmarkdown::render(
      "base_notebook.Rmd",
      output_format = 'pdf_document',
      params = list(
        stocks = stocks,
        data = data,
        html_page = html_page
      ),
      output_file = tmp
    )

    readBin(glue('{tmp}.pdf'), "raw", n = file.info(glue('{tmp}.pdf'))$size)
  }




  #* @param year A number
  #* @get /html
  function(res,
           stocks = 2019,
           data = 'file2.csv',
           html_page = TRUE) {
    tmp <- tempfile()


    rmarkdown::render(
      "base_notebook.Rmd",
      output_format = 'html_document',
      params = list(
        stocks = stocks,
        data = data,
        html_page = html_page
      ),
      output_file = tmp
    )

    include_html(glue('{tmp}.html'), res)
    # readBin(glue('{tmp}.html'), "raw", n=file.info(glue('{tmp}.html'))$size)
  }


  #* @param csv_file A string
  #* @get /submit_data
  function(res, csv_file) {
    print(res)
    print(csv_file)
  }

  #' @param id An identifier
  #' @post /file_upload
  function(req) {
    # biggr::s3_create_bucket('drenruploadapi')
    log_entry(req, 'file_upload')

    if (!dir.exists('files')) {
      dir.create('files')
    }

    resp <- Rook::Multipart$parse(req)
    query_arguments <- shiny::parseQueryString(req$QUERY_STRING)
    id <- query_arguments$id
    print(id)
    print(resp$filepond$filename)
    total_path = file.path('files', resp$filepond$filename)
    fs::dir_ls('files')
    write_file(read_file(resp$filepond$tempfile), total_path)
    s3_upload_file(bucket = 'drenruploadapi', from = total_path, to = total_path)
    fs::dir_ls('files')
    list(formContents = Rook::Multipart$parse(req))
  }


  #' @param id An identifier
  #' @get /print_data
  function(req, filename = 'files/lm.R') {
    read_file(filename)
  }

  #' @serializer unboxedJSON
  #' @param id An identifier
  #' @get /s3_objects
  function() {
    response <- list(
      statusCode = 200,
      data = "",
      message = "Success!"
    )

    tryCatch(
      {
        response$data = toJSON(s3_list_objects('drenruploadapi') %>% select(key))
        return(response)
      },
      error = function(err) {
        response$statusCode <- 400
        response$message <- paste(err)

        return(response)
      }
    )
  }







}
