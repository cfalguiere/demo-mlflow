#!/usr/bin/env python
# coding: utf-8

import logging
import warnings
from datetime import datetime

import numpy as np

from train import data_prep, train_elasticnet

import mlflow
from mlflow.entities import ViewType
from  mlflow.tracking import MlflowClient

import optuna
    

if __name__ == "__main__":
    logging.basicConfig(level=logging.WARN)
    logger = logging.getLogger(__name__)
    warnings.filterwarnings("ignore")
    np.random.seed(40)
    optuna.logging.set_verbosity(optuna.logging.INFO)
    ts = datetime.now().strftime('%Y%m%dT%H%M%S')
    
    try:
        datasets = data_prep("../wine-quality.csv")
    except Exception as e:
        logger.exception(
            "Unable to download training & test CSV, check your internet connection. Error: %s", e)
        exit(-1)

    # Define an objective function to be minimized.
    def objective(trial):

        suggested_alpha = trial.suggest_uniform('alpha', 0.1, 0.8)
        suggested_l1_ratio = trial.suggest_uniform('l1_ratio', 0.1, 0.8)

        error = train_elasticnet(datasets, suggested_alpha, suggested_l1_ratio, trial="%s_%s" % (ts,trial.trial_id))

        return error  # A objective value linked with the Trial object.
        

    study = optuna.create_study()  # Create a new study.
    study.optimize(objective, n_trials=100)  # Invoke optimization of the objective function.


    study.best_params

    study.best_trial

    # best model
    trial_id = study.best_trial.number
    print("trial_id: %s" % trial_id)
    tag = "%s_%s" % (ts, trial_id)
    print("tag: %s" % tag)
    query = "tags.trial = '%s'" % tag
    runs = mlflow.search_runs(filter_string=query, run_view_type=ViewType.ACTIVE_ONLY)
    best_model_id = runs['run_id'][0]
    best_model_uri = runs['artifact_uri'][0]
    print("best model - id: %s - uri: %s" % (best_model_id, best_model_uri) )

    mlflow_client = MlflowClient()
    mlflow_client.set_tag(best_model_id, "best_model", "true")


