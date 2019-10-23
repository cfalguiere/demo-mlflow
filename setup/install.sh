BASEDIR=$(readlink -f $0 | xargs dirname)

echo "INFO - starting install-tools $( date )"

set -eu
trap "{ echo 'ERROR - install failed' ; exit 255; }" SIGINT SIGTERM ERR

# prereq

LOG_DIR=/var/log/mlflow/setup
mkdir -p /opt
cd $_

aptitude --quiet --assume-yes install make build-essential
aptitude --quiet --assume-yes install tree
aptitude --quiet --assume-yes install unzip

# MySQL
[[ -f "${LOG_DIR}/.mariadb" ]] || {
  echo "INFO - install MariaDB"
  aptitude --quiet --assume-yes install mariadb-server mysql-client
  source setup/mysql_secure_installation_template.sql > mysql_secure_installation.sql
  source setup/mlflow_setup_template.sql > mlflow_setup.sql
  echo mysql_secure_installation.sql
  cat mysql_secure_installation.sql
  echo mlflow_setup.sql
  cat mlflow_setup.sql
  mysql -sfu root < "mlflow_setup.sql"
  mysql -sfu root < "mysql_secure_installation.sql"
}

# anaconda
[[ -f "${LOG_DIR}/.anaconda" ]] || {
  echo "INFO - install Anaconda"
  ANACONDA_VERSION="Anaconda3-2019.07-Linux-x86_64.sh"
  ANACONDA_URL="https://repo.anaconda.com/archive/${ANACONDA_VERSION}"
  wget -q  "${ANACONDA_URL}"  -O miniconda.sh
  bash ./miniconda.sh -b -p /opt/miniconda
  /opt/miniconda/bin/conda update -y conda
  rm /opt/miniconda.sh
}

#ajout pip et letsencrypt
#apt-get install --assume-yes python-pip
#pip install letsencrypt && sudo pip install letsencrypt-s3front


# mlflow
echo "INFO - install MLFlow"
[[ -f "${LOG_DIR}/.mlflow" ]] || {
  #/opt/miniconda/bin/conda env create --file ${BASEDIR}/conda-mlflow.yml
  /opt/miniconda/bin/conda create -c conda-forge --name mlflow python=3 mlflow mysqlclient

  mkdir -p /opt/mlflow/

  git clone --depth 1 https://github.com/mlflow/mlflow /opt/mlflow/mlflowquickstart

  # pre requisite for some mlflow operations
  aptitude --quiet --assume-yes install snapd
}

chown -R ubuntu:ubuntu /opt
chown -R ubuntu:ubuntu /var/log/mlflow

echo "INFO - install Completed"
