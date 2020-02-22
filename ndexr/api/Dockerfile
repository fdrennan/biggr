FROM trestletech/plumber
MAINTAINER Docker User <docker@user.org>

RUN apt-get update --allow-releaseinfo-change -qq && apt-get install -y \
  git-core \
  libssl-dev \
  default-jdk \
  libcurl4-openssl-dev \
  curl \
  libxml2-dev \
  libpq-dev -y

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN R CMD javareconf

RUN R -e "install.packages('devtools')"
RUN R -e "install.packages('tidyverse')"
RUN R -e "install.packages('glue')"
RUN R -e "install.packages('reticulate')"
RUN R -e "install.packages('purrr')"
RUN R -e "install.packages('lubridate')"
RUN R -e "install.packages('plumber')"
RUN R -e "install.packages('tictoc')"
RUN R -e "install.packages('jsonlite')"
RUN R -e "install.packages('RPostgres')"
RUN R -e "install.packages('dbplyr')"
RUN R -e "install.packages('DBI')"
RUN R -e 'devtools::install_github("gregce/ipify")'

RUN R -e 'library(reticulate); install_miniconda(force = TRUE);'

WORKDIR /app

RUN R -e 'devtools::install_github("fdrennan/biggr")'
RUN R -e 'library(biggr); install_python(envname = "r-reticulate");'

RUN R -e 'devtools::install_github("fdrennan/biggr")'

EXPOSE 8000
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(commandArgs()[4]); pr$run(host='0.0.0.0', port=8000)"]
CMD ["/app/plumber.R"]
