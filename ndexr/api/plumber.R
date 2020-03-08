library(biggr)

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

  cat(as.character(Sys.time()), "-",
      req$REQUEST_METHOD, req$PATH_INFO, "-",
      req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")

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

#* @get /test
#* @serializer unboxedJSON
function(req, res) {
  list(mtcars = mtcars)
}


#* @param instance_ids
#* @get /instance_data
#* @serializer unboxedJSON
function(req, res, user_token = NULL,instance_ids = NULL) {

  message(glue('Within instance_data {Sys.time()}'))

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

  print(response)

  response <- tryCatch({
    # Run the algorithm

    tic()
    user_token <- parse_user_token(user_token, 'secret')
    con <- postgres_connector()
    on.exit(dbDisconnect(con))

    instance_created <- tbl(con, in_schema('public', 'instance_created')) %>%
      filter(user_id %in% local(user_token$user_id)) %>%
      rename(instance_id = id) %>%
      collect %>%
      arrange(desc(creation_time)) %>%
      select(-instance_type)

    ec2_info <-
      ec2_instance_info(instance_ids = instance_ids,
                        return_json = FALSE)

    servers <- inner_join(instance_created, ec2_info)
    servers$login <- servers %>%
      split(.$instance_id) %>%
      map(
        ~ glue('ssh -i \"', .$key_name, '.pem\" ubuntu@ec2-',
               str_replace_all(.$public_ip_address, '\\.', '-'), '.us-east-2.compute.amazonaws.com')
      ) %>%
      unlist

    response$data <- servers

    timer <- toc(quiet = T)
    response$metaData$runtime <- as.numeric(timer$toc - timer$tic)
    print(response)
    return(response)
  },
  error = function(err) {
    response$statusCode <- 400
    response$message <- paste(err)
    print(response)
    return(response)
  })

  return(response)

}


#* @get /security_group_list
#* @serializer unboxedJSON
function(req, res) {

  message(glue('Within create_instance {Sys.time()}'))

  # Build the response object (list will be serialized as JSON)
  response <- list(
    statusCode = 200,
    data = 'false',
    message = "Success!",
    metaData = list(
      runtime = 0
    )
  )

  print(response)

  response <- tryCatch({

    # token <-
    #   user_token %>%
    #   jwt_decode_hmac('secret')
    #
    # instance_storage = as.numeric(instance_storage)

    security_group_list()
    # Run the algorithm
    tic()
    response$data <- security_group_list()
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

#* @param instance_type
#* @param key_name
#* @param instance_storage
#* @get /create_instance
#* @serializer unboxedJSON
function(req, res,
         user_token = NULL,
         instance_type = NULL,
         key_name = NULL,
         image_id = 'ami-0fc20dd1da406780b',
         security_group_id = 'sg-0221bdbcdc66ac93c',
         instance_storage = 50,
         security_group_name = 'testr',
         to_json = TRUE) {

  message(glue('Within create_instance {Sys.time()}'))

  # Build the response object (list will be serialized as JSON)
  response <- list(
    statusCode = 200,
    data = 'false',
    message = "Success!",
    metaData = list(
      args = list(
        instance_type = instance_type,
        key_name = key_name,
        image_id = image_id,
        security_group_id = security_group_id,
        instance_storage = instance_storage,
        security_group_name = security_group_name
      ),
      runtime = 0
    )
  )

  print(response)

  response <- tryCatch({

    token <-
      user_token %>%
      jwt_decode_hmac('secret')

    instance_storage = as.numeric(instance_storage)

    # Run the algorithm
    tic()
    response$data <-api_instance_start (
      user_token = user_token,
      token_secret = 'secret',
      instance_type = instance_type,
      key_name = key_name,
      instance_storage = instance_storage,
      security_group_name = security_group_name,
      image_id = image_id
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
  print(response)

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


#* @param keyname
#* @get /keyfile_create
#* @serializer unboxedJSON
function(req, res, keyname = NULL) {

  message(glue('Within create_instance {Sys.time()}'))

  response <- list(
    statusCode = 200,
    data = 'false',
    message = "Success!",
    metaData = list(
      args = list(
        keyname = keyname
      ),
      runtime = 0
    )
  )
  print(response)

  response <- tryCatch({
    # Run the algorithm
    tic()
    keyfile <-
      try(keyfile_create(keyname = keyname,
                         save_to_directory = TRUE))


    if(inherits(keyfile, 'try-error')) {
      con = postgres_connector()
      on.exit(dbDisconnect(conn = con))
      keyfile <- tbl(con, in_schema('public', 'keyfiles')) %>%
        filter(key_file_name == keyname,
               created_at == max(created_at)) %>%
        collect %>%
        pull(keyfile)
    }



    response$data <- list(
      keyfile = paste0(
        keyfile
      )
    )
    timer <- toc(quiet = T)
    response$metaData$runtime <- as.numeric(timer$toc - timer$tic)

    print(response)
    return(response)
  },
  error = function(err) {
    response$statusCode <- 400
    response$message <- paste(err)
    print(response)
    return(response)
  })

  return(response)

}

