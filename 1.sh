#!/bin/bash
gcloud auth revoke --all

while [[ -z "$(gcloud config get-value core/account)" ]]; 
do echo "waiting login" && sleep 2; 
done

while [[ -z "$(gcloud config get-value project)" ]]; 
do echo "waiting project" && sleep 2; 
done



# Copy paste ke terminal


gcloud config set compute/zone us-central1-f

# use lab 11765
# cd ~
# git clone https://github.com/googlecodelabs/monolith-to-microservices.git
# cd ~/monolith-to-microservices
# ./setup.sh


gcloud services enable container.googleapis.com
gcloud container clusters create fancy-cluster --num-nodes 3


export PROJECT_ID=$(gcloud info --format='value(config.project)')
export PRODIR=$(pwd)

cd monolith-to-microservices
printf "Enabling Cloud Build APIs..."
gcloud services enable cloudbuild.googleapis.com > /dev/null 2>&1
printf "Completed.\n"

printf "Building Monolith Container..."
cd ../monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:1.0.0 . > /dev/null 2>&1
printf "Completed.\n"

printf "Deploying Monolith To GKE Cluster..."
kubectl create deployment monolith --image=gcr.io/${PROJECT_ID}/monolith:1.0.0 > /dev/null 2>&1
kubectl expose deployment monolith --type=LoadBalancer --port 80 --target-port 8080 > /dev/null 2>&1
printf "Completed.\n\n"

printf "Please run the following command to find the IP address for the monolith service:  kubectl get service monolith\n\n"

printf "Deployment Complete\n"


cd ../../monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${PROJECT_ID}/orders:1.0.0 .


kubectl create deployment orders --image=gcr.io/${PROJECT_ID}/orders:1.0.0

kubectl expose deployment orders --type=LoadBalancer --port 80 --target-port 8081


cd ../../../../monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:2.0.0 .

kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:2.0.0



cd ../../monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${PROJECT_ID}/products:1.0.0 .

kubectl create deployment products --image=gcr.io/${PROJECT_ID}/products:1.0.0

kubectl expose deployment products --type=LoadBalancer --port 80 --target-port 8082


cd ../../../../monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:3.0.0 .

kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:3.0.0


cd ../../monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${PROJECT_ID}/frontend:1.0.0 .

kubectl create deployment frontend --image=gcr.io/${PROJECT_ID}/frontend:1.0.0

kubectl expose deployment frontend --type=LoadBalancer --port 80 --target-port 8080







