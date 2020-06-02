#Cluster setup
#The Azure CLI, version 2.2.0 or later

subscriptionId="subscriptionId"
resourceGroup="devops-tools-rg"
clusterName="devops-tools"

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