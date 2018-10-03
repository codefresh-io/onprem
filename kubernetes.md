## How to deploy Codefresh application on Azure Kubernetes Service (AKS) cluster

### Pre-requisites

* The Azure CLI version 2.0.46 or later. `az --version` to check installed version.
* The `kubectl` binary version 1.10+ . `kubectl version` to check installed version.

### AKS cluster deployment 

1. Make `az login` if needed
2. Create a resource group
```
az group create --name onprem-aks-rg --location centralus
```
3. Get available Kubernetes versions
```
az aks get-versions --location centralus -otable
```
4. Create AKS cluster
```
az aks create --resource-group onprem-aks-rg --name onprem-aks --kubernetes-version 1.11.3 --node-count 1 --node-vm-size Standard_DS2_v2 --node-osdisk-size 128 --enable-addons monitoring --admin-username ubuntu --ssh-key-value <path_to_ssh_public_key>
```
5. Get and configure kubernetes cluster credentials
```
az aks get-credentials --resource-group onprem-aks-rg --name onprem-aks --admin
```
6. Check out your current context 
```
kubectl config current-context
```

### Register Codefresh app in a git provider

1. Define your CF app URL: example `https://onprem-aks.codefresh.io`

2. Register CF application on git provider side. The procedure is described in this [document](https://docs.google.com/document/d/1j_u2kunM69jTDcBW_8acQ1hnUawXZoUGcE1CxFu5njg/edit#heading=h.h4zd9clx0w2w)

3. Write down Client ID, Client Secret, git provider URL.

### Deploy Codefresh app

1. Clone [onprem](https://github.com/codefresh-io/onprem) repository
```
git clone git@github.com:codefresh-io/onprem.git
cd onprem
```
2. Download values.yaml and sa-dec.json files from [1Password](https://codefresh.1password.com/) into current `./onprem` directory. When logged in search for `onprem` in `devops-shared` vault.

3. Make configuration changes in `sa-dec.json`, `values.yaml` files. 

* `sa.json` contains GCP service account that enables a customer to pull codefresh images (created in GCP [codefres-enterprise project](https://console.cloud.google.com/iam-admin/serviceaccounts?organizationId=304925537542&orgonly=true&project=codefresh-enterprise) )
* `values.yaml` set CF application domain name, git provider domain name, secrets such as `githubClientID`, `githubClientSecret`, or `gitlabClientID`, `gitlabClientSecret` etc.

4. Give a node `local-volume` label
```
kubectl get node

kubectl label nodes <NODENAME> provisioner=local-volume

``` 
5. Run `cf-onprem` script
```
sudo ./cf-onprem
```
6. Wait for CF App to be deployed
```
watch kubectl -ncodefresh get pods
```
7. Get ingress service ip address

```
kubectl -ncodefresh get svc | grep ingress-controller
```
8. Register CF application URL with ip addrees at Cloudflare.com (or other domain name registrar)
9. Open web browser and go to the CF application URL (ex. https://onprem-aks.codefresh.io)
10. Log in with `ON PREMISE CODEFRESH` credentials.
11. Go to `Admin Management --> IDPs`.
12. Edit your git provider with git provider domain name and then Log Out.
13. Wait for several minutes and Sign up with chosen git provider.
14. Go to `Integrations --> Git --> Congifure --> ADD GIT PROVIDER` and configure it. [Git providers document](https://codefresh.io/docs/docs/integrations/git-providers/) can help.
15. Log in with `ON PREMISE CODEFRESH` credentials once again, Go to `Admin Management --> Users` and add `Admin` role for your user if needed.  Go to `Admin Management --> Nodes` and ensure cfapi is up and has running status. If not it is needed to restart cfapi pod
```
kubectl -ncodefresh get pod | grep cfapi
kubectl -ncodefresh delete pod <cfapi-pod-name>
```
16. Sign in with your git provider.
17. Add Repository.
18.Click `BUILD`