# demo-mlflow

requires ubuntu TODO version

requires aptitude
with root account or sudo
requires env variables MYSQL_ADMIN_PASSWORD and MLFLOW_DB_PASSWORD before calling setuo/install.sh

TODO user database
TODO table
uses  and 5000 (MLFlow server), 8888 (Jupyter)
port 3306 (MySQL) local

tested against AWS ubuntu AMI

install script
- installs anaconda and mysql
- creates 2 conda env with mlflow (server and demo)
- create a /opt/mlflow directory
- provides scripts to run mlflow server with a db backend and a local filesystem repository
- download mlflow's quickstart

```
conda init bash
bash
conda activate mlflow
cd /opt/mlflow
export MLFLOW_DB_PASSWORD=XXXXXXXX
./start-mlflow-server-db.sh
```

MLflow UI : http://<IP>:5000/

conda activate demo
cd /opt/demo

export MLFLOW_TRACKING_URI=http://localhost:5000

cd /opt/mlflow/mlflowquickstart/examples/

python sklearn_elasticnet_wine/train.py

export MLFLOW_EXPERIMENT_NAME=demo
mlflow experiments create --experiment-name $MLFLOW_EXPERIMENT_NAME

python sklearn_elasticnet_wine/train.py


TODO Jupyter
start-jopyter

Troubleshooting

systemctl status mysql.server

sudo -i -u root mysql
mysql> use mlflow;
mysql> show tables;
mysql> exit


+------------------+
| Tables_in_mlflow |
+------------------+
| alembic_version  |
| experiment_tags  |
| experiments      |
| latest_metrics   |
| metrics          |
| params           |
| runs             |
| tags             |
+------------------+
8 rows in set (0.00 sec)
