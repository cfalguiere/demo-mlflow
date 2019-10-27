#!/bin/bash
PUBLIC_IP=$( curl --silent http://169.254.169.254/latest/meta-data/public-ipv4 )
echo "MLflow server : http://${PUBLIC_IP}:5000/"
echo "Jupyter server : http://${PUBLIC_IP}:8888/"
