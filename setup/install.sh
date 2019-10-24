BASEDIR=$(readlink -f $0 | xargs dirname)

echo "INFO - starting install-tools $( date )"

set -eu
trap "{ echo 'ERROR - install failed' ; exit 255; }" SIGINT SIGTERM ERR

# prereq
# requires var MLFLOW_DB_PASSWORD

LOG_DIR=/var/log/mlflow/setup
mkdir -p ${LOG_DIR}
mkdir -p /opt
cd $_

[[ -f "${LOG_DIR}/.common" ]] || {
  aptitude --quiet --assume-yes install make build-essential
  aptitude --quiet --assume-yes install tree
  aptitude --quiet --assume-yes install unzip
  touch "${LOG_DIR}/.common"
}

# MySQL
[[ -f "${LOG_DIR}/.mariadb" ]] || {
  echo "INFO - install MariaDB"
  aptitude --quiet --assume-yes install mariadb-server mysql-client
  source ${BASEDIR}/mysql_secure_installation_template.sql > ${BASEDIR}/mysql_secure_installation.sql
  source ${BASEDIR}/mlflow_setup_template.sql > ${BASEDIR}/mlflow_setup.sql
  echo "INFO - mysql_secure_installation.sql content"
  cat ${BASEDIR}/mysql_secure_installation.sql
  echo "INFO - mlflow_setup.sql content"
  cat ${BASEDIR}/mlflow_setup.sql
  mysql -sf  < "${BASEDIR}/mysql_secure_installation.sql"
  mysql -sf  < "${BASEDIR}/mlflow_setup.sql"
  touch "${LOG_DIR}/.mariadb"
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
  echo 'PATH="${PATH}:/opt/miniconda/bin/"' >> /etc/profile.d/conda.sh
  touch "${LOG_DIR}/.anaconda"
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

  cp ${BASEDIR}/start-mlflow-server-*.sh /opt/mlflow/
  chmod u+x /opt/mlflow/start*.sh

  touch "${LOG_DIR}/.mlflow"
}

chown -R ubuntu:ubuntu /opt
chown -R ubuntu:ubuntu /var/log/mlflow

echo "INFO - install Completed"
