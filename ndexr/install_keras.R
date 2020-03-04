library(keras)
library(reticulate)


virtualenv_create('r_tensorflow')
# RETICULATE_PYTHON_ENV=~/.virtualenvs/r_tensorflow
install_keras(tensorflow = 'gpu')

