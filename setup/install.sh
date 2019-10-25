BASEDIR=$(readlink -f $0 | xargs dirname)

echo "INFO - starting install-tools $( date )"

set -eu
trap "{ echo 'ERROR - install failed' ; exit 255; }" SIGINT SIGTERM ERR

# prereq
# requires var MLFLOW_DB_PASSWORD

LOG_DIR=/var/log/demo-mlflow/setup
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
[[ -f "${LOG_DIR}/.mysql" ]] || {
  echo "INFO - install MariaDB"
  #aptitude --quiet --assume-yes install mariadb-server mysql-client
  aptitude --quiet --assume-yes install mysql-server mysql-client
  source ${BASEDIR}/mysql_secure_installation_template.sql > ${BASEDIR}/mysql_secure_installation.sql
  source ${BASEDIR}/mlflow_setup_template.sql > ${BASEDIR}/mlflow_setup.sql
  echo "INFO - mysql_secure_installation.sql content"
  cat ${BASEDIR}/mysql_secure_installation.sql
  echo "INFO - mlflow_setup.sql content"
  cat ${BASEDIR}/mlflow_setup.sql
  mysql -sfu root < "${BASEDIR}/mysql_secure_installation.sql"
  mysql -sfu root < "${BASEDIR}/mlflow_setup.sql"

  # mysql server port
  ufw allow 3306

  touch "${LOG_DIR}/.mysql"
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
  ln -s /opt/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
  #echo 'PATH="${PATH}:/opt/miniconda/bin/"' > /etc/profile.d/conda.sh
  #echo 'conda init bash' >> /etc/profile.d/conda.sh
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

  cp ${BASEDIR}/scripts/start-mlflow-server-*.sh /opt/mlflow/
  chmod u+x /opt/mlflow/start*.sh

# TODO setenv pour mot de passe
# config MySQL
#useradd --home "$path_home"  --shell /bin/bash $account
#usermod -aG tools $account
#usermod -aG sudo $account
#groupadd tools

  # MLFlow UI port
  ufw allow 5000

  touch "${LOG_DIR}/.mlflow"
}

# mlflow
echo "INFO - install MLFlow"
[[ -f "${LOG_DIR}/.jupyter" ]] || {
  /opt/miniconda/bin/conda create -c conda-forge --name demo python=3 mlflow anaconda

  mkdir -p /opt/demo/
  git clone --depth 1 https://github.com/mlflow/mlflow /opt/demo/mlflowquickstart
  cp ${BASEDIR}/scripts/start-jupyter.sh /opt/demo/
  chmod u+x /opt/mlflow/start*.sh
  cp ${BASEDIR}/scripts/setenv.sh /opt/demo/

  # pre requisite for some mlflow operations
  aptitude --quiet --assume-yes install snapd
  # Jupyter UI port
  ufw allow 8888
  touch "${LOG_DIR}/.jupyter"
}

chown -R ubuntu:ubuntu /opt
chown -R ubuntu:ubuntu /var/log/demo-mlflow
chown -R ubuntu:ubuntu /opt/mlflow # future use

echo "INFO - install Completed"
