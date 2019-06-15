[![Build Status](https://dev.azure.com/mabenoit-ms/MyOwnBacklog/_apis/build/status/myakscluster?branchName=master)](https://dev.azure.com/mabenoit-ms/MyOwnBacklog/_build/latest?definitionId=97?branchName=master)

# myakscluster

To properly setup and secure your AKS cluster, there is a couple of features and components to enable in order to respect the Security Principle of Least Privilege, here is the list:

- [X] Service Principal [#6](https://github.com/mathieu-benoit/myakscluster/issues/6)
- [X] Azure Lock [#21](https://github.com/mathieu-benoit/myakscluster/issues/21)
- [X] Azure KeyVault for Azure pipelines [#3](https://github.com/mathieu-benoit/myakscluster/issues/3)
- [X] kured [#13](https://github.com/mathieu-benoit/myakscluster/issues/13)
- [X] Disable K8S Dashboard [#24](https://github.com/mathieu-benoit/myakscluster/issues/24)
- [ ] AAD [#10](https://github.com/mathieu-benoit/myakscluster/issues/10)
- [ ] Network Policy [#9](https://github.com/mathieu-benoit/myakscluster/issues/9)
- [ ] (Preview) Pod Security Policy [#20](https://github.com/mathieu-benoit/myakscluster/issues/20)
- [ ] (Preview) Limit Egress Traffic [#16](https://github.com/mathieu-benoit/myakscluster/issues/16)
- [ ] (Preview) IP whitelisting for Kubernetes API [#12](https://github.com/mathieu-benoit/myakscluster/issues/12)
- [ ] (Preview) Azure Policy [#11](https://github.com/mathieu-benoit/myakscluster/issues/11)
- [ ] (Beta) Azure KeyVault Flex Volume [#18](https://github.com/mathieu-benoit/myakscluster/issues/18)
- [ ] (Beta) Pod Identity [#17](https://github.com/mathieu-benoit/myakscluster/issues/17)

TODO - img

# Setup

```
#az account list -o table
#az account set -s <subscriptionId>
subscriptionId=$(az account show --query id -o tsv)
tenantId=$(az account show --query tenantId -o tsv)
spName=<spName>
spSecret=$(az ad sp create-for-rbac -n $spName --role Owner --query password -o tsv)
spId=$(az ad sp show --id http://$spName --query appId -o tsv)

location=<location>
kvName=<kvName>
rg=<rg>
az group create -n $rg -l $location
az keyvault create -l $location -n $kvName -g $rg
az keyvault secret set --vault-name $kvName -n subscriptionId --value $subscriptionId
az keyvault secret set --vault-name $kvName -n spTenantId --value $tenantId
az keyvault secret set --vault-name $kvName -n spId --value $spId
az keyvault secret set --vault-name $kvName -n spSecret --value $spSecret

az keyvault set-policy -n $kvName --spn $spId --secret-permissions get list
                       
az devops service-endpoint create --authorization-scheme ServicePrincipal
                                  --name
                                  --service-endpoint-type azurerm
                                  [--azure-rm-service-principal-id]
                                  [--azure-rm-subscription-id]
                                  [--azure-rm-subscription-name]
                                  [--azure-rm-tenant-id]
                                  [--detect {false, true}]
                                  [--org]
                                  [--project]
```

# Further considerations

- Azure API Management
- Azure Front Door
- Azure Container Registry:
  - CI's Service Principal (acrpush)
  - AKS's Service Principal (acrpull)
  - VNET
  - Scanning

# Resources

- [Azure webinar series - Help Deliver Applications Securely with DevSecOps](https://info.microsoft.com/ww-ondemand-help-deliver-applications-securely-with-devsecops-us.html)
- [Enterprise security in the era of containers and Kubernetes](https://mybuild.techcommunity.microsoft.com/sessions/77061)
- [Azure Kubernetes Services: Container Security for a Cloud Native World](https://info.cloudops.com/azure-kubernetes-services-container-security)
- [11 Ways (Not) to Get Hacked](https://kubernetes.io/blog/2018/07/18/11-ways-not-to-get-hacked/)
- [Tutorial: Bullet-Proof Kubernetes: Learn by Hacking - Luke Bond & Ana-Maria Calin](https://www.youtube.com/watch?v=NEfwUxId1Uk)
- [Tutorial: Building Security into Kubernetes Deployment Pipelines - Michael Hough & Sam Irvine](https://www.youtube.com/watch?v=xjTBwZG8TtY)
- [How Spotify Accidentally Deleted All its Kube Clusters with No User Impact](https://www.youtube.com/watch?v=ix0Tw8uinWs)
