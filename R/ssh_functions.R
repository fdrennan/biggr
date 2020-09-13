#' @export run_command
run_command <- function(con, command) {
  as.character(con$exec_command(command)[[2]]$read())
}

#' @export send_file
send_file <- function(con, local_path, remote_path) {
  ftp_client = con$open_sftp()
  ftp_client$put(local_path, remote_path)
  ftp_client$close()
}

#' @export get_file
get_file <- function(con, remote_path, local_path) {
  ftp_client = con$open_sftp()
  ftp_client$get(remote_path, local_path)
  ftp_client$close()
}

#' @export stage_run_command
stage_run_command <- function(command = 'ls -lah', stage_name = 'DEV', key_filename='fdren.pem') {
  con <- suppressMessages(postgres_connector())
  on.exit(dbDisconnect(conn = con))
  ssh = paramiko$SSHClient()
  ssh$set_missing_host_key_policy(paramiko$AutoAddPolicy())
  server_stage <- tbl(con, in_schema('public', 'server_stage')) %>%
    inner_join( tbl(con, in_schema('public', 'servers')), by = 'instance_id') %>%
    filter(stage == stage_name, state == 'running') %>%
    collect %>%
    pull(public_dns_name)
  if(length(server_stage) == 0) {
    message('Not in state to run command')
    return(NULL)
  }
  ssh$connect(server_stage,
              username='ubuntu',
              key_filename=key_filename)
  run_command(ssh, command)
}

#' @export stage_transfer_file
stage_transfer_file <- function(local_path,
                                remote_path,
                                stage_name = 'DEV',
                                TO = TRUE,
                                key_filename='fdren.pem') {
  con <- postgres_connector()
  on.exit(dbDisconnect(conn = con))
  ssh = paramiko$SSHClient()
  ssh$set_missing_host_key_policy(paramiko$AutoAddPolicy())
  server_stage <- tbl(con, in_schema('public', 'server_stage')) %>%
    inner_join( tbl(con, in_schema('public', 'servers')) ) %>%
    filter(stage == stage_name, state == 'running') %>%
    collect %>%
    pull(public_dns_name)
  if(length(server_stage) == 0) {
    message('Not in state to run command')
    return(NULL)
  }
  ssh$connect(server_stage,
              username='ubuntu',
              key_filename=key_filename)



  if (TO) {
    send_file(ssh, local_path, remote_path)
  } else {
    get_file(ssh, remote_path, local_path)
  }

}

#' @export specify_server_priority
specify_server_priority <- function(instance_ids, values) {
  # Specify Server Priority
  con <- postgres_connector()
  on.exit(expr = {
    message('Disconnecting from Postgres')
    dbDisconnect(conn = con)
  })
  tryCatch(expr = {
    dbExecute(
      conn = con,
      statement = '
        create table public.server_stage (
            stage    varchar,
            instance_id   varchar,
            primary key (stage)
        )
        '
    )
  }, error = function(err) {
    message('Disregard already exists error if below')
    message(as.character(err))
  })
  server_stages <- tibble(stage = values,
                          instance_id = instance_ids)
  dbxUpsert(
    conn = con,
    table = "server_stage",
    records = server_stages,
    where_cols = c("stage")
  )

  tbl(con, in_schema('public', 'server_stage')) %>% collect
}

#' @export modify_server
modify_server <- function(server_id, action = 'stop') {
  servers <- server_info()
  print(servers)
  map(iterate(servers$instances$all()), function(x) {
    if (x$instance_id == server_id) {
      if (action == 'stop') {
        message(glue('Stopping {server_id}'))
        x$stop()
      }

      if (action == 'start') {
        message(glue('Starting {server_id}'))
        x$start()
      }

      if (action == 'terminate') {
        message(glue('Terminating {server_id}'))
        x$start()
      }
    }
  })
}

#' @export server_info
server_info <- function(CLEAN_UP = TRUE) {
  con <- postgres_connector()
  on.exit(expr = {
    message('Disconnecting from Postgres')
    dbDisconnect(conn = con)
  })

  tryCatch(expr = {
    dbExecute(
      conn = con,
      statement = '
        create table public.servers (
            public_ip_address          varchar,
            id  varchar,
            image_id    varchar,
            instance_id   varchar,
            instance_type     varchar,
            launch_time numeric,
            state varchar,
            public_dns_name varchar,
            primary key (instance_id)
        )
        '
    )
  }, error = function(err) {
    message('Disregard already exists error if below')
    message(as.character(err))
  })

  message('Grab All Existing servers')
  servers <- tbl(con, in_schema('public', 'servers')) %>% collect
  message('Get Resources')
  resource = resource_ec2()
  instance_ids <- unique(
    c(
      map_chr(iterate(resource$instances$all()), function(x) {x$instance_id}),
      servers$instance_id
    )
  )
  servers_list <- resource$instances$all()
  servers <- map_df(
    iterate(servers_list$all()),
    function(x) {
      servers <- tibble(
        public_ip_address = if_else(is.null(x$public_ip_address), 'missing', x$public_ip_address),
        id = x$id,
        image_id = x$image_id,
        instance_id = x$instance_id,
        instance_type = x$instance_type,
        launch_time = as.numeric(x$launch_time),
        public_dns_name = x$public_dns_name,
        state = x$state$Name
      )
      servers
    }
  )

  dbxUpsert(
    conn = con,
    table = "servers",
    records = servers,
    where_cols = c("instance_id")
  )

  servers <- tbl(con, in_schema('public', 'servers')) %>% collect

  if (CLEAN_UP) {
    message('Deleting old servers')
    delete_these <- instance_ids[!instance_ids %in% servers$instance_id]
    delete_these <- c(
      delete_these,
      filter(servers, state == 'terminated')$instance_id
    )
    message(paste0(delete_these, collapse = "\n"))
    dbxDelete(con, 'servers', where=data.frame(instance_id = delete_these))
    message('Resulting Dataframe')
    servers <- tbl(con, in_schema('public', 'servers')) %>% collect
  }

  list(servers = servers, instances = servers_list)
}
