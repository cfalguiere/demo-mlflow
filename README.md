# demo-mlflow

requires ubuntu TODO

requires aptitude
requires env variables MYSQL_ADMIN_PASSWORD and MLFLOW_DB_PASSWORD
uses port 3306 (MySQL) and 5000 (MLFlow server)

tested against AWS ubuntu AMI

install script
- installs anaconda and mariadb
- creates a conda env with mlflow
- create a /opt/mlflow directory
- provides scripts to run mlflow server with a mariadb backend and a file repository
- download mlflow's quickstart
