Param(
    [parameter(Mandatory=$false)][string][ValidateSet('dev','qa')]$env="dev",
    [parameter(Mandatory=$false)][string]$imageTag="linux-latest"
)
$ErrorActionPreference = "Stop"
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

function Install-Chart  {
    Param([string]$chartName, [string]$chartPath, [string]$initialOptions,
    [string] $registry="", [string]$user="", [string]$pass="")  

    $options = $initialOptions
    if ($registry -ne ""){
        $options = "$options --set inf.registry.server=$registry --set inf.registry.login=$user --set inf.registry.pwd=$pass --set inf.registry.secretName=eshop-docker-scret"
    }

    $command = "install $appName-$chartName $options $chartPath"
    Write-Host "Helm Command: helm $command" -ForegroundColor Gray
    Invoke-Expression 'cmd /c "helm $command"'
}


$appName = "eshop"

$aksRg = "rg-eshop-dev-paid"
$aksName = "aks-eshop-dev-paid"
$registry = "creshoppaid.azurecr.io"
$registryUser = $(az acr credential show -n creshoppaid --query "username" -o tsv)
$registryPassword = $(az acr credential show -n creshoppaid --query "password" -o tsv)


Write-Host "Getting DNS of AKS of AKS $aksName (in resource group $aksRg)..." -ForegroundColor Green
$dns = $(az aks show -n $aksName  -g $aksRg --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName)
if ([string]::IsNullOrEmpty($dns)) {
    Write-Host "Error getting DNS of AKS $aksName (in resource group $aksRg). Please ensure AKS has httpRouting enabled AND Azure CLI is logged & in version 2.0.37 or higher" -ForegroundColor Red
    exit 1
}
$dns = $dns -replace '[\"]'
Write-Host "DNS base found is $dns. Will use $appName.$dns for the app!" -ForegroundColor Green
$dns = "$appName.$dns"

# CLEAN
$listOfReleases=$(helm ls --filter $appName -q)    
if ([string]::IsNullOrEmpty($listOfReleases)) {
    Write-Host "No previous releases found!" -ForegroundColor Green
}else{
    Write-Host "Previous releases found" -ForegroundColor Green
    Write-Host "Cleaning previous helm releases..." -ForegroundColor Green
    helm uninstall $listOfReleases
    Write-Host "Previous releases deleted" -ForegroundColor Green
}        


$infras = ("sql-data", "nosql-data", "rabbitmq", "keystore-data", "basket-data")
$charts = ("eshop-common", "basket-api","catalog-api", "identity-api", "coupon-api", "mobileshoppingagg","ordering-api","ordering-backgroundtasks","ordering-signalrhub", "payment-api", "webmvc", "webshoppingagg", "webspa", "webstatus", "webhooks-api", "webhooks-web")
$gateways = ("apigwms", "apigwws")


$helmPath="./app/helm"
$appValuesFile="$helmPath/app.yaml"
$infValuesFile="$helmPath/inf.yaml"
$ingressValuesFile="$helmPath/ingress_values.yaml"
$ingressMeshAnnotationsFile="$helmPath/ingress_values_linkerd.yaml"
$imagePullPolicy="Always"

foreach ($infra in $infras) {
    Write-Host "Installing infrastructure: $infra" -ForegroundColor Green
    helm install "$appName-$infra" --values $appValuesFile --values $infValuesFile --values $ingressValuesFile --set app.name=$appName --set inf.k8s.dns=$dns --set "ingress.hosts={$dns}" ./app/helm/$infra
}

Write-Host "Infra deployed." 

foreach ($chart in $charts) {
    $params = @{
        chartName = $chart
        chartPath = "$helmPath/$chart"
        initialOptions = "-f $appValuesFile -f $infValuesFile -f $ingressValuesFile -f $ingressMeshAnnotationsFile --set app.name=$appName --set inf.k8s.dns=$dns --set ingress.hosts={$dns} --set image.tag=$imageTag --set image.pullPolicy=$imagePullPolicy --set inf.mesh.enabled=false --set inf.tls.enabled=false --set inf.k8s.local=false"
        registry = $registry
        user = $registryUser
        pass = $registryPassword  
    }

    Write-Host "Installing: $chart" -ForegroundColor Green
   # Install-Chart $chart "-f app.yaml --values inf.yaml -f $ingressValuesFile -f $ingressMeshAnnotationsFile ingressMeshAnnotationsFile --set app.name=$appName --set inf.k8s.dns=$dns --set ingress.hosts={$dns} --set image.tag=$imageTag --set image.pullPolicy=$imagePullPolicy --set inf.tls.enabled=$sslEnabled --set inf.mesh.enabled=$useMesh --set inf.k8s.local=$useLocalk8s" $useCustomRegistry
    Install-Chart @params
}

Write-Host "Apps deployed." 


foreach ($chart in $gateways) {    
    Write-Host "Installing Api Gateway Chart: $chart" -ForegroundColor Green
    $params = @{
        chartName = $chart
        chartPath = "$helmPath/$chart"
        initialOptions = "-f $appValuesFile -f $infValuesFile -f $ingressValuesFile --set app.name=$appName --set inf.k8s.dns=$dns  --set image.pullPolicy=$imagePullPolicy --set inf.mesh.enabled=false --set ingress.hosts={$dns} --set inf.tls.enabled=false"
      
    }

    Install-Chart @params          
}

Write-Host "Gateways deployed." 



Write-Host "Deployment completed. Use $dns to access." 

# Show ACR credentials
