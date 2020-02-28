library(biggr)

# print(fs::dir_ls(all =TRUE))
# install_python(envname = 'r-reticulate', method = 'conda')
use_condaenv(condaenv = 'r-reticulate')

configure_aws(
  aws_access_key_id     = Sys.getenv('AWS_ACCESS'),
  aws_secret_access_key = Sys.getenv('AWS_SECRET'),
  default.region        = Sys.getenv('AWS_REGION')
)

con <- message(glue('Within Plumber API {Sys.time()}'))


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


#* @get /
#* @serializer unboxedJSON
function(req, res) {
  print(req)
  list(msg = 'Hello world')
}


#* @param instance_type
#* @param key_name
#* @param instance_storage
#* @get /create_instance
#* @serializer unboxedJSON
function(instance_type = NULL,
         key_name = NULL,
         image_id = 'ami-0fc20dd1da406780b',
         security_group_id = 'sg-0221bdbcdc66ac93c',
         instance_storage = 50,
         to_json = TRUE) {

  instance_storage = as.numeric(instance_storage)

  message(glue('Within create_instance {Sys.time()}'))

  # Build the response object (list will be serialized as JSON)
  response <- list(
    statusCode = 200,
    data = 'false',
    message = "Success!",
    metaData = list(
      args = list(
        instance_type = instance_type,
        key_name = key_name
      ),
      runtime = 0
    )
  )


  response <- tryCatch({
    # Run the algorithm
    tic()
    response$data <- api_instance_start(
      instance_type = instance_type,
      key_name = key_name
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


#* @param instance_ids
#* @get /instance_data
#* @serializer unboxedJSON
function(instance_ids = NULL) {

  message(glue('Within create_instance {Sys.time()}'))

  # Build the response object (list will be serialized as JSON)
  response <- list(
    statusCode = 200,
    data = 'false',
    message = "Success!",
    metaData = list(
      args = list(
        instance_ids = instance_ids
      ),
      runtime = 0
    )
  )


  response <- tryCatch({
    # Run the algorithm
    tic()
    response$data <- ec2_instance_info(instance_ids = instance_ids,
                                       return_json = TRUE)
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


#* @param id
#* @param method
#* @param instance_type
#* @get /instance_modify
#* @serializer unboxedJSON
function(id = NULL, method = NULL, instance_type = NULL) {

  message(glue('Within create_instance {Sys.time()}'))


  response <- list(
    statusCode = 200,
    data = 'false',
    message = "Success!",
    metaData = list(
      args = list(
        id = id,
        method = method,
        instance_type = instance_type
      ),
      runtime = 0
    )
  )


  response <- tryCatch({
    # Run the algorithm
    tic()
    response$data <- modify_instance(id = id,
                                     method = method,
                                     instance_type = instance_type)
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
