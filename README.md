## Codefresh On-premise installation repository

`cf-onprem` - script that deploys Codefresh application on any kubernetes cluster 

### How it works
`cf-onprem` script reads default variables and environment variables that can override defaults, validates and approves current cluster context, checks if `helm` binary is installed, installs `helm` binary, deploys `codefresh` chart with `helm`.

### Pre-requisites

Before running `cf-onprem` script it is needed to:
* override default environment variables in `env-vars` file if needed
* make configuration changes specific for each customer

There are three files that customize `codefresh` chart deployment:
* `values.yaml.tpl` contains template of values.yaml for different parameters for chart customization


### How to run
1. Clone [onprem](https://github.com/codefresh-io/onprem) repository
```
git clone git@github.com:codefresh-io/onprem.git
cd onprem
```
2. cp `values.yaml.tpl`  `values.yaml`

3. Edit values.yaml
Mandatory to set `global.appUrl` and `firebaseToken` 

    ##### Running on local volumes
        Codefresh can run on local volumes - https://kubernetes.io/docs/concepts/storage/volumes/#local  

        To create local volumes edit `local-volumes/values.yaml`, set:
        - defaultNodeSelector
        - mkdirPods.nodes

        then run `local-volumes/create-local-pvcs.sh`
        edit values.yaml and set the values for `existingPvc`s

4. Validate values and cluster
   `./run-validator.sh`
   It will validate:
   - values.yaml
   - ability to launch persistent services on specified storage classes
   - ability to launch persistent services on specified existing pvcs
   - To do: validating networks, dns, loadbalances, ingress

5. run Intaller:
 ```
 ./cf-onprem [ --web-tls-key certs/key.pem --web-tls-cert certs/cert.pem ]
 ```