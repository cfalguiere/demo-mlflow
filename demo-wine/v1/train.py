#!/usr/bin/env python
# coding: utf-8


import sys
import warnings
import logging
import tempfile
import shutil
import os

import pandas as pd 
import numpy as np

import mlflow
import mlflow.sklearn

import matplotlib.pyplot as plt


def data_prep(datafile):

    # read data from file
    df = pd.read_csv("../wine-quality.csv")

    from sklearn.model_selection import train_test_split
    # Split the data into training and test sets. (0.75, 0.25) split.
    train, test = train_test_split(df)

    # The predicted column is "quality" which is a scalar from [3, 9]
    train_x = train.drop(["quality"], axis=1)
    test_x = test.drop(["quality"], axis=1)
    train_y = train[["quality"]]
    test_y = test[["quality"]]

    # make it easy to pass datasets
    datasets = { 'train_x': train_x, 'train_y': train_y, 'test_x': test_x, 'test_y': test_y }

    shapes = [ "%s : %s" % (name, dataset.shape) for (name,dataset) in datasets.items() ]
    print(shapes)

    return datasets


def eval_parameters(in_alpha, in_l1_ratio):
    # Set default values if no alpha is provided
    alpha = float(in_alpha) if not in_alpha is None else 0.5
    # Set default values if no l1_ratio is provided
    l1_ratio = float(in_l1_ratio) if not in_l1_ratio is None else 0.5
    return alpha, l1_ratio


def eval_metrics(actual, predicted):
    from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
    rmse = np.sqrt(mean_squared_error(actual, predicted))
    mae = mean_absolute_error(actual, predicted)
    r2 = r2_score(actual, predicted)
    return rmse, mae, r2


def output_enet_coefs(tempdir, columns, lr):
    coef_file_name = os.path.join(tempdir, "coefs.txt")
    with open(coef_file_name, "w") as f: 
        f.write("Coefs:\n")         
        [ f.write("\t %s: %s\n" % (name, coef)) for (name, coef) in zip(columns, lr.coef_) ]
        f.write("\t intercept: %s\n" % lr.intercept_) 

        
def plot_enet_feature_importance(tempdir, columns, coefs):
    # Reference the global image variable
    global image
    
    # Display results
    fig = plt.figure(1)
    ax = plt.gca()
    
    feature_importance = pd.Series(index = columns, data = np.abs(coefs))
    n_selected_features = (feature_importance>0).sum()
    print('{0:d} features, reduction of {1:2.2f}%'.format(
        n_selected_features,(1-n_selected_features/len(feature_importance))*100))
    feature_importance.sort_values().tail(30).plot(kind = 'bar', figsize = (20,12));
    
    # Display images
    image = fig
    
    # Save figure
    fig.savefig(os.path.join(tempdir, "feature-importance.png"))

    # Close plot
    plt.close(fig)

    # Return images
    return image    
   
    
def train_elasticnet(datasets, in_alpha, in_l1_ratio, trial=None):
    from sklearn.linear_model import ElasticNet
    
    train_x = datasets['train_x']
    train_y = datasets['train_y']
    test_x = datasets['test_x']
    test_y = datasets['test_y']

    alpha, l1_ratio = eval_parameters(in_alpha, in_l1_ratio)
    print("Parameters (alpha=%f, l1_ratio=%f):" % (alpha, l1_ratio))
    
    server_uri = "http://localhost:5000"
    #mlflow.set_tracking_uri(server_uri)
    #mlflow.set_experiment("wine6")
    with mlflow.start_run():
        # train with ElasticNet
        lr = ElasticNet(alpha=alpha, l1_ratio=l1_ratio, random_state=42)
        lr.fit(train_x, train_y)

        # Evaluate Metrics
        predicted_qualities = lr.predict(test_x)
        (rmse, mae, r2) = eval_metrics(test_y, predicted_qualities)

        # Print out metrics
        print("Elasticnet model (alpha=%f, l1_ratio=%f):" % (alpha, l1_ratio))
        print("  RMSE: %s" % rmse)
        print("  MAE: %s" % mae)
        print("  R2: %s" % r2)

        # Log parameter, metrics, and model to MLflow
        mlflow.log_param("alpha", alpha)
        mlflow.log_param("l1_ratio", l1_ratio)
        mlflow.log_metric("rmse", rmse)
        mlflow.log_metric("mae", mae)
        mlflow.log_metric("r2", r2)
        mlflow.set_tag("algo", "ElastiNet")
        if trial != None:
             mlflow.set_tag("trial", trial)
           
        # store info
        # store info       
        workdir = tempfile.mkdtemp()
        with tempfile.TemporaryDirectory() as tmpdirname:  
            output_enet_coefs(tmpdirname, train_x.columns, lr) 

            # plots
            plot_enet_feature_importance(tmpdirname, train_x.columns, lr.coef_)
            # Call plot_enet_descent_path
            #image = plot_enet_descent_path(tmpdirname, train_x, train_y, l1_ratio)

            # Log artifacts (output files)
            mlflow.log_artifacts(tmpdirname, artifact_path="artifacts")

        # store model
        mlflow.sklearn.log_model(lr, "model")
        
        return rmse

    
if __name__ == "__main__":
    logging.basicConfig(level=logging.WARN)
    logger = logging.getLogger(__name__)
    warnings.filterwarnings("ignore")
    np.random.seed(40)

    in_alpha = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
    in_l1_ratio = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5


    try:
        datasets = data_prep("../wine-quality.csv")
    except Exception as e:
        logger.exception(
            "Unable to download training & test CSV, check your internet connection. Error: %s", e)
        exit(-1)

    train_elasticnet(datasets, in_alpha, in_l1_ratio)

