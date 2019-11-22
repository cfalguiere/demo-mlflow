# Demo MLflow


## Setup de l'instance EC2

ID de l'AMI :ami-0ad37dbbe571ce2a1  (Ubuntu v18.04)

Type d'instance : t2.micro (General-Purpose - 1 vCPU - 1 Go de RAM)

Volume EBS de 16 Go (attention à l'espace occupé par les deux environnements anaconda)

### le script d'install en User Data
```
#!/bin/bash
echo "INFO - starting init $( date )"

set -eu
trap "{ echo 'ERROR - install failed' ; exit 255; }" SIGINT SIGTERM INT TERM ERR 

# get IP as variables
export LOCAL_IP=$( curl --silent http://169.254.169.254/latest/meta-data/local-ipv4 )
export PUBLIC_IP=$( curl --silent http://169.254.169.254/latest/meta-data/public-ipv4 )

echo "installing linux packages"

# upgrade 
apt-get --quiet update

# install required packages
apt --quiet --assume-yes install aptitude
apt --quiet --assume-yes install awscli

# get script

echo "INFO - getting project"
mkdir -p /var/git-repos
cd $_
git clone https://github.com/cfalguiere/demo-mlflow.git

cd demo-mlflow

# tools installation
echo "INFO - installing demo-mlflow"

# utilisé dans l'URL. Le code est public mais le mot de passe n'est connu que dans mon espace AWS.
export MLFLOW_DB_PASSWORD=xxxxxxxx

./setup/install.sh

```

### ports à ouvrir dans le security group 
``` 
port 5000 (MLFlow server)
port 8888 (Jupyter)
port 3306 (MySQL) local pour outils d'admin
port 8080 ou autre pour l'API Serve
```

###  le script installe
- installe anaconda et mysql
- crée 2 conda env un pour le server mlflow l'autre pour le datascientist
- crée un dossier /opt/mlflow qui est home d'installatiton de mlflow
- crée un dossier /opt/anaconda qui le home de anaconda et des envs anaconda
- crée un dossier /opt/demo pour les fichiers de la démo. Les soures de base se trouvent dans ce projet (sous dossier demo-wine) et sont copiés dans le dossier /opt/demo par l'install
- download le quickstart mlflow

### URLs

MLflow server : http://<IP>:5000/

MLflow Jupyter : http://<IP>:8888/


### variables d'environnement 

De manière systématique : 
```
export MLFLOW_DB_PASSWORD=xxxxxxxx # en principe fait par l'install et sert à lancer le serveur en mode db
export MLFLOW_TRACKING_URI=http://localhost:5000
```


# Filaire de la démo

## Le modèle utilisé
c'est un Elstinet sur les données Wine dérivé du quickstart MLflow

Le modèle n'est pas optimisé et ne vaut pas grand chose. C'est juste un exemple.


## Démarrer un jupyter
```
Ouvrir une session SSH
cd /opt/demo
conda activate demo
./start-jupyter.sh
```
Aller sur http://<ip-ec2>:8888

Copier le token affiché dans le shell (Logout / login si besoin) 

## Comprendre le modèle
- Dans Jupyer, aller dans demo-wine
- Ouvrir explore data pour visulaiser les données
- Ouvrir build model pour voir le modèle initial

Params 
- alpha : la vitesse d'apprentissage
- l2_ratio : l'éuilibre etre les deux méthodes de régularisation

Métriques :
- Root Mean Square Error (RMSE) : écart-type des erreurs de prédiction. Indique la dispersion des données réelles par rapport à la prédiction. Doit être le plus bas possible.
- Mean Absolute Error (MAE) : écart moyen entre la prédiction et la valeur réelle. Doit être le plus bas possible.
- r2 score : proportion de la variance de la variable à expliquer prédictible par les variables explicatives. Varie de 0 à 100% (meilleur)

## Démarrer mlflow server
```
Ouvrir une session
cd /opt/demo
conda activate mlflow
./start-mlflow-server-basic.sh
```

ou  pour la version DB
```
./start-mlflow-server-db.sh
```

Aller sur http://<ip-ec2>:5000

### modèle avec MLflow
- Dans Jupyter, aller dans demo-wine-mlflow
- le nom de l'expérimentation est dans une des premières cellules. Il peut être changé, l'expérimentation sera crée automatiquement
- noter le with mlflow.run et les appels de log_param, log_metric et log_model
- le modèle loggue aussi des artefacts si verbose=True. Ce sont la liste des coefficients et une image des features du modèle.
- Faire tourner les 2 appels de train avec des paramètres différents et voir le résultat dans MLflow

La fin du notebook, crée des données en masse en utilisant un auto tuning par Optuna

### possibilités de l'IHM du server
- comparer des runs: les sélectionner et utiliser Compare 
- faire un graphe de MAE en fonction de alpha (ou toute métrique en fonction de tout param)
- faire une recherche par valeur de param, de métrique ou par tag : par exemple dans la cellule taper metrics.rmse < 0.8 (le modèle est peu pertinent mais tourne en général en 0.77 et 0.85)
- afficher un run, voir les métriques, voir les modèles et les artefacts associés

### les autres notebooks
- explore_model permet de lister le contenu d'un picke

Montrer ce qui est stocké via explore_model
Penser  changer l’experiment id et le numero de run

## Préparation d'un projet finalisé
Les éléments sont dans v1
- MLproject : descripteur projet MLflow avec deux entry points
- conda.yml : decripteur d'env anaconda
- train.py  : entry point principal - entraine le modèle en passant les paramètres alpha et l1_ratio (qui a une valeur par défaut)
- auto_train.py : entry point pour l'auto train

## partage d'un modèle

Disons que j'ai partagé ces 4 fichiers par Github. Un autre DataScientist fait un pull et obtient sa version du projet/

Quanf il va lancer run, MLflow va recréer un environnement à partir du conda.yamll (ou à partir de l'image Docker en mode Docker), puis lancer la commande mentionnéedans MLprokject comme main entry point

Ouvrir  session SSH
```
cd /opt/demo/demo_wine
conda activate demo
export MLFLOW_TRACKING_URI=http://localhost:5000
mlflow run v1 -P alpha=0.42 --experiment-id 9
```

Il crée un env anaconda à partir du conda.yaml la première fois, mais garde l'information. Par la suite l'environnement sera simplement mis à jour.

### lancer un autre entry-point, par exemple pour l'auto tuning

le programme auto_tuning utilise optuna pour chercher les meilleurs paramètres. dans cette phase il appele la fonction d'entrainement avec verbose=False. Quand il a fini il recalcule le modèle à partir des meilleurs paramètres et cette fois en verbose pour avoir tous les éléments de décision. La data prep n'et jouée qu'une fois avant l'entrée dans Optuna.

TODO isoler jeux de données de cross-val et de test.


Montrer l’entry point dans MLproject
``` 
mlflow experiments create --experiment-name wine-at-9 
mlflow run v1 -P n_iter=2000 --experiment-id 10 --entry-point auto_train
``` 

Le projet à exécuter peut aussi être identifié par une url github (pas testé) 


## Service du modèle

Ouvrir un shell SSH
```
cd /opt/demo
conda activate demo
mlflow models serve -m /opt/mlflow/mlruns/11/5a682c1c01704a09ae4a1c45d6d22eb4/artifacts/model -h 0.0.0.0 -p 54321
```
sélectionner une expérimentation et un run dans MLflow pur corriger la ligne.

Tester avec curl epuis une autre session
```
curl -X POST -H "Content-Type:application/json; format=pandas-split" --data '{"columns":["alcohol", "chlorides", "citric acid", "density", "fixed acidity", "free sulfur dioxide", "pH", "residual sugar", "sulphates", "total sulfur dioxide", "volatile acidity"],"data":[[12.8, 0.029, 0.48, 0.98, 6.2, 29, 3.33, 1.2, 0.39, 75, 0.66]]}' http://0.0.0.0:54321/invocations

[3.4262196411110866]

```

Notez que le code ne contient pas de programme predict. il est intégré dans serve et utilise le modèle stocké sous une forme "standardisée" par MLflow.
# Troubleshooting

Vérifier MySql

systemctl status mysql.server

MYSql utilise une authentification par socket

sudo -i -u root mysql
mysql> use mlflow;
mysql> show tables;
mysql> exit

ça diot ressembler à ça

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
