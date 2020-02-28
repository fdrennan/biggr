library(biggr)
# install_python(envname = 'biggr')
use_virtualenv('biggr')

configure_aws(
  aws_access_key_id     = Sys.getenv('AWS_ACCESS'),
  aws_secret_access_key = Sys.getenv('AWS_SECRET'),
  default.region        = Sys.getenv('AWS_REGION')
)

message(glue('Within Plumber API {Sys.time()}'))

# s3_create_bucket(bucket_name = 'fdrennan-personal')

s3_upload_file(bucket = 'fdrennan-personal', from = '/Users/fdrennan/Desktop/data.tar.gz', to = 'data.tar.gz')

s3_upload_file('ndexr-files', 'ndexr/startup.sh', 'startup.sh', make_public = TRUE)
s3_upload_file('ndexr-files', 'ndexr/.Renviron.gpu', '.Renviron.gpu', make_public = TRUE)
s3_upload_file('ndexr-files', 'ndexr/ndexr-gpu', 'ndexr-gpu', make_public = TRUE)
s3_upload_file('ndexr-files', 'ndexr/install_keras.R', 'install_keras.R', make_public = TRUE)
s3_upload_file('ndexr-files', 'ndexr/keras_model.R', 'keras_model.R', make_public = TRUE)
s3_upload_file('ndexr-files', 'ndexr/nginx.conf', 'nginx.conf', make_public = TRUE)
s3_upload_file('ndexr-files', 'ndexr/shiny-server.conf', 'shiny-server.conf', make_public = TRUE)
s3_upload_file('ndexr-files', '/Users/fdrennan/Downloads/cudnn-10.0-linux-x64-v7.6.5.32.tgz',
               'cudnn-10.0-linux-x64-v7.6.5.32.tgz', make_public = TRUE)
s3_upload_file('ndexr-files', '/Users/fdrennan/Downloads/cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64.deb',
               'cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64.deb', make_public = TRUE)
