#Cluster setup
#The Azure CLI, version 2.2.0 or later

subscriptionId="subscriptionId"
resourceGroup="devops-tools-rg"
clusterName="devops-tools"
namespace="graylog-nonprod"

az account set --subscription $subscriptionId
az aks get-credentials --resource-group $resourceGroup --name $clusterName

# Install Private Load Balancer
# Locate a free internal IP and update ingress-internal.yaml

# Use Helm to deploy an NGINX ingress controller
helm install nginx-internal stable/nginx-ingress \
    --create-namespace \
    --namespace ingress-internal \
    -f internal-ingress.yaml \
    --set controller.ingressClass=nginx-internal
    

kubectl create namespace $namespace
kubectl config set-context $(kubectl config current-context) --namespace=$namespace

# Install MongoDB
helm install mongodb stable/mongodb-replicaset --namespace $namespace -f mongodb.yaml

# Install Elasticsearch
helm upgrade --install --namespace $namespace --values ./elasticsearch-master.yaml elasticsearch-master elastic/elasticsearch
helm upgrade --install --namespace $namespace --values ./elasticsearch-client.yaml elasticsearch-client elastic/elasticsearch
helm upgrade --install --namespace $namespace --values ./elasticsearch-data.yaml elasticsearch-data elastic/elasticsearch



# Install SSL Certificate

kubectl create secret tls mydomain-ssl --key mydomain.key --cert mydomain.cert --namespace $namespace

helm upgrade --install --namespace $namespace  graylog stable/graylog \
  --set tags.install-mongodb=false\
  --set tags.install-elasticsearch=false\
  --set graylog.mongodb.uri=mongodb://mongodb-mongodb-replicaset-0.mongodb-mongodb-replicaset.$namespace.svc.cluster.local:27017/graylog?replicaSet=rs0 \
  --set graylog.elasticsearch.hosts=http://elasticsearch-client.$namespace.svc.cluster.local:9200 \
  -f graylog.yaml



az network lb rule create -g mc_ebusiness-tools-k8s-rg_ebusiness-tools_eastus \
    --lb-name kubernetes-internal \
    --name udp30010 \
    --protocol Udp \
    --frontend-port 30010 \
    --backend-port 30010 \
    --backend-pool-name Kubernetes

################################################################
################################################################
################################################################
#Increase the size of the elasticsearch data node


# Step 1 - Shutdown the elasticsearch data scaleset
kubectl scale sts elasticsearch-data --replicas=0

# Wait for the scale set to show 0 pods
kubectl get sts

# Now, scale up the Physical Volume Claim
kubectl get pvc

kubectl edit pvc elasticsearch-data-elasticsearch-data-0

# look for resources.requests.storage and update it with the new storage limit. Note that you cannot scale down, only scale up. Update and save

# Repeat the same for the other data pvcs
kubectl edit pvc elasticsearch-data-elasticsearch-data-1
kubectl edit pvc elasticsearch-data-elasticsearch-data-2

#Use the following command to view the log of the resizing
kubectl describe pvc elasticsearch-data-elasticsearch-data-0

#It should say waiting for the pod to boot up to resize.
# Open Azure Portal and goto the k8s resource group. Verify that the physical volumes are resized.

#Now scale the sts back

kubectl scale sts elasticsearch-data --replicas=3
