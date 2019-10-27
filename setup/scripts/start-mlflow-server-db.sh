#!/bin/bash
# TODO check var
# mysql db mlflow and user mlflow must have been created
# var MLFLOW_DB_PASSWORD must have been set to the password of te mlflow account
mlflow server --backend-store-uri mysql://mlflow:${MLFLOW_DB_PASSWORD}@127.0.0.1/mlflow --default-artifact-root /opt/mlflow/mlruns --host 0.0.0.0 2>&1 | tee -a /var/log/demo-mlflow/mlflowserver.out
