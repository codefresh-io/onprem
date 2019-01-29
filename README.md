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

4. run `./cf-onprem [ --web-tls-key certs/key.pem --web-tls-cert certs/cert.pem ]`