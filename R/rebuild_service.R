#' rebuild_service
#' @description Rebuild the service
#' @importFrom purrr map
#' @importFrom furrr future_map2
#' @importFrom glue glue
#' @importFrom fs file_delete
#' @export rebuild_service
rebuild_service <- function(dns_names = NULL, stages = NULL) {
  stage_scripts <-
    map(stages,
        function(stage) {
          command_block <- c(
            "#!/bin/bash",
            "rm /home/ubuntu/last_git_update_complete || echo 'last_git_update_complete does not exist'",
            "rm /home/ubuntu/last_git_update.txt || echo 'last_git_update does not exist'",
            "exec &> /home/ubuntu/last_git_update.txt",
            "docker-compose -f docker_pull_postgres/docker-compose.yml pull",
            "docker-compose -f docker_pull_postgres/docker-compose.yml down",
            "docker-compose -f docker_pull_postgres/docker-compose.yml up -d",
            glue('cd productor && git reset --hard'),
            glue(
              "cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R"
            ),
            glue(
              'cd /home/ubuntu/productor && git pull origin {stage} && git branch'
            ),
            glue(
              "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml pull"
            ),
            glue(
              "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d --build productor_postgres"
            ),
            glue(
              "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d --build productor_initdb"
            ),
            glue(
              "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml down"
            ),
            glue(
              "cd /home/ubuntu/productor && docker-compose -f docker-compose-{stage}.yaml up -d"
            ),
            "touch /home/ubuntu/last_git_update_complete"
          )
        })

  response <-
    future_map2(stage_scripts,
                dns_names,
                function(script, dns) {
                  script_name <- glue('{dns}script.sh')
                  writeLines(text = script, con = script_name)
                  message(glue('Building: ssh -i "~/fdren.pem" ubuntu@{dns}'))
                  send_file(
                    hostname = dns,
                    username = "ubuntu",
                    keyfile = "/Users/fdrennan/fdren.pem",
                    local_path = script_name,
                    remote_path = glue('/home/ubuntu/{script_name}')
                  )
                  cmd_response <- execute_command_to_server(command = glue('. /home/ubuntu/{script_name}'),
                                                            hostname = dns)
                  file_delete(script_name)
                  cmd_response
                }, .progress = TRUE)
}
