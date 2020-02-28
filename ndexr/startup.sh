#!/bin/bash

# sudo wget https://s3.us-east-2.amazonaws.com/ndexr-files/startup.sh
# ami-01c085148101c3bde
cd /home/ubuntu

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'

sudo curl -O https://nginx.org/keys/nginx_signing.key && sudo apt-key add ./nginx_signing.key
sudo add-apt-repository 'deb http://nginx.org/packages/ubuntu/ bionic nginx'

sudo apt-get update

sudo apt-get install htop

# Install R Stuff
sudo apt-get install r-base -y
sudo apt-get install r-base-dev  -y

# Install Python
sudo apt-get install python3-dev python3-pip -y
sudo pip3 install -U virtualenv  # system-wide install

# Install Libraries
sudo apt-get install libcurl4-openssl-dev  -y
sudo apt-get install libgit2-dev  -y
sudo apt-get install libssl-dev  -y
sudo apt-get install libssh2-1-dev  -y
sudo apt-get install libpq-dev  -y
sudo apt-get install libxml2-dev  -y

sudo apt-get install gdebi-core  -y

# Install RSTUDIO SERVER
wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5033-amd64.deb
yes | sudo gdebi rstudio-server-1.2.5033-amd64.deb

# Install SHINY SERVER
wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.12.933-amd64.deb
yes | sudo gdebi shiny-server-1.5.12.933-amd64.deb

# Create dirs/files for SHINY Server
sudo apt-get install nginx  -y
mkdir -p /home/ubuntu/log/shiny_logs
sudo mv  /etc/shiny-server/shiny-server.conf /etc/shiny-server/shiny-server.conf.bak
sudo wget https://s3.us-east-2.amazonaws.com/ndexr-files/shiny-server.conf -P /etc/shiny-server/
sudo mv /srv/shiny-server /home/ubuntu/
sudo systemctl restart shiny-server

# Setup NGINX
mkdir /home/ubuntu/website
sudo mv  /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
sudo wget https://s3.us-east-2.amazonaws.com/ndexr-files/nginx.conf -P /etc/nginx/
sudo systemctl restart nginx
sudo mv /usr/share/nginx/html/index.html /home/ubuntu/website/index.html

# Install Docker
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo curl -L https://raw.githubusercontent.com/docker/compose/1.25.3/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# INSTALL NVIDIA DRIVERS
sudo apt-get install --no-install-recommends nvidia-driver-418 -y

# Install NVIDIA Docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

wget https://s3.us-east-2.amazonaws.com/ndexr-files/ndexr-gpu

# Install ROOT R PACKAGES
sudo su - \
  -c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
sudo su - \
  -c "R -e \"install.packages('rmarkdown', repos='https://cran.rstudio.com/')\""



# docker build -t rockerpy .
# docker run --gpus all  -p 8788:8787 rockerpy

# # INSTALL CUDNN
# wget https://s3.us-east-2.amazonaws.com/ndexr-files/cudnn-10.0-linux-x64-v7.6.5.32.tgz
# tar -xzvf cudnn-10.0-linux-x64-v7.6.5.32.tgz
# sudo mkdir -p /usr/local/cuda/include
# sudo cp cuda/include/cudnn.h /usr/local/cuda/include
# sudo mkdir -p /usr/local/cuda/lib64
# sudo cp cuda/lib64/libcudnn* /usr/local/cuda/lib64
# sudo chmod a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*
#
# # INSTALL CUDN TOOLKIT
# wget https://s3.us-east-2.amazonaws.com/ndexr-files/cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64.deb
# sudo dpkg -i cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64.deb
# sudo apt-key add /var/cuda-repo-10-0-local-10.0.130-410.48/7fa2af80.pub
# sudo apt-get update
# # Install NVIDIA driver
#
# # Install development and runtime libraries (~4GB)
# sudo apt install cuda-command-line-tools-10-0 -y
# sudo apt-get install libcudnn7=7.6.4.38-1+cuda10.0 -y
# sudo apt-get install libcudnn7-dev=7.4.1.5-1+cuda10.0 -y
#
# tree / -fiC | grep libcuda.so
#
#
# echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64' >> /home/ubuntu/.profile
# echo 'export CUDA_HOME=/usr/local/cuda' >> /home/ubuntu/.profile
# echo 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${CUDA_HOME}/lib64' >> /home/ubuntu/.profile
# echo 'PATH=${CUDA_HOME}/bin:${PATH}' >> /home/ubuntu/.profile
# echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64' >> /home/ubuntu/.profile
# echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.0/targets/x86_64-linux/lib/stubs/'>> /home/ubuntu/.profile
# echo 'export PATH' >> /home/ubuntu/.profile
#
# echo 'export CUDA_HOME=/usr/local/cuda' >> /home/ubuntu/.bashrc
# echo 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${CUDA_HOME}/lib64' >> /home/ubuntu/.bashrc
# echo 'PATH=${CUDA_HOME}/bin:${PATH}' >> /home/ubuntu/.bashrc
# echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64' >> /home/ubuntu/.bashrc
# echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.0/targets/x86_64-linux/lib/stubs/'>> /home/ubuntu/.bashrc
# echo 'export PATH' >> /home/ubuntu/.bashrc
#
