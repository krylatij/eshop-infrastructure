Param(
    [parameter(Mandatory=$false)][string][ValidateSet('dev','qa')]$env="dev"
)
$ErrorActionPreference = "Stop"
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$workingDir = "infra/env"

Write-Host "Starting infrastructure deployment on '$env' environment."  -ForegroundColor Yellow

terraform -chdir="$workingDir" apply -var-file="$env.tfvar" -var-file="../shared/shared.tfvar"

$clusterName = terraform -chdir="$workingDir" output cluster_name
$rgName = terraform -chdir="$workingDir" output rg_name

Write-Host "Cluster '$clusterName' created."

az aks get-credentials --resource-group $rgName --name $clusterName --admin

Write-Host "Kubuctl logged in" -ForegroundColor Green

kubectl apply -f .\k8s\aks-httpaddon-cfg.yaml
kubectl apply -f .\k8s\nginx-ingress\mandatory.yaml
kubectl apply -f .\k8s\nginx-ingress\local-cm.yaml
kubectl apply -f .\k8s\nginx-ingress\local-svc.yaml
kubectl apply -f .\k8s\nginx-ingress\service-nodeport.yaml

Write-Host "Deployment comleted."