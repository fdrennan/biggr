#!/bin/bash
echo 'Successully started' >> /notes

echo 'deb https://cloud.r-project.org/bin/linux/ubuntu disco-cran35/' >> /etc/apt/sources.list

echo 'Updating server' >> /notes
sudo apt-get update

install_r=false
if [ "$install_r" = true ]; then

  echo 'Installing R' >> /notes
  sudo apt-get install r-base -y
  sudo apt-get install libcurl4-openssl-dev -y
  sudo apt-get install libgit2-dev -y
  sudo apt-get install libssl-dev -y
  sudo apt-get install libssh2-1-dev -y
  sudo apt-get install gdebi-core
  sudo apt-get install python3-pip -y
  sudo apt-get install libpq-dev -y
  sudo apt-get install libxml2-dev -y
  sudo /usr/bin/pip3 install virtualenv
  sudo apt-get install python3-venv

  echo 'Installing RStudio Server' >> /notes
  sudo wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.1335-amd64.deb
  yes | sudo gdebi rstudio-server-1.2.1335-amd64.deb

  echo 'Installing Shiny' >> /notes
  sudo su - \
    -c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""

  echo 'Installing Markdown' >> /notes
  sudo su - \
    -c "R -e \"install.packages('rmarkdown', repos='https://cran.rstudio.com/')\""

  echo 'Installing Shiny Server' >> /notes
  sudo wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.9.923-amd64.deb
  yes | gdebi shiny-server-1.5.9.923-amd64.deb
fi

echo 'Installing Postgres' >> /notes
sudo apt install postgresql postgresql-contrib -y
CONF_FILE=$(find / -name "postgresql.conf" | grep main)
PG_FILE=$(find / -name "pg_hba.conf" | grep main)
echo "listen_addresses = '*'" >> $CONF_FILE
echo "host    all             all             0.0.0.0/0               md5" >> $PG_FILE
echo "host    all             all             ::/0                    md5" >> $PG_FILE
echo "#!/bin/bash" >> /tmp/update_pass
echo  "sudo -u postgres -H -- psql -c \"ALTER USER postgres PASSWORD 'password'\"" >> /tmp/update_pass
sh /tmp/update_pass
service postgresql stop
service postgresql start

echo 'Grabbing data and loading it' >> /notes
wget https://s3.us-east-2.amazonaws.com/fdrennancsv/mtcars.sql
wget https://s3.us-east-2.amazonaws.com/fdrennancsv/mtcars.csv
sudo -u postgres -H -- psql -a -f mtcars.sql

echo 'Finished' >> /notes
/usr/bin/curl -X POST https://textbelt.com/text \
                              --data-urlencode phone='5555555555' \
                              --data-urlencode message='Find Your Phone!' \
                              -d key=textbelt
