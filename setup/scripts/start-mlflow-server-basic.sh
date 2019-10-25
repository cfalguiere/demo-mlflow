mlflow server --backend-store-uri /opt/mlflow/mlruns --default-artifact-root /opt/mlflow/mlruns --host 0.0.0.0 2>&1 | tee -a /var/log/demo-mlflow/mlflowserver.out
