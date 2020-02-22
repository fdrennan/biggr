#' @export db_instance_status
db_instance_status = function(id, status) {

  con = postgres_connector()
  on.exit(dbDisconnect(con))
  table_name = 'instance_status'
  missing_table <- !table_name %in% dbListTables(conn = con)

  update_data <- data.frame(
    id = id,
    status = status,
    time = now(tzone = 'UTC')
  )

  if (missing_table) {
    dbCreateTable(conn = con, table_name, update_data)
  }


  dbAppendTable(
    conn = con,
    name = table_name,
    value = update_data
  )
}
