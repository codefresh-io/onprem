## Codefresh On-premise installation repository

## `cf-onprem` - script that deploys Codefresh application on any kubernetes cluster 

## How it works
### `cf-onprem` script reads default variables and environment variables that can override defaults, validates and approves current cluster context, checks if `helm` binary is installed, installs `helm` binary, deploys `codefresh` chart with `helm`.

## Pre-requisites

### Before running `cf-onprem` script it is needed to:
* override default environment variables in `env-vars` file if needed
* make configuration changes specific for each customer

### There are three files that customize `codefresh` chart deployment:
* `sa-dec.json` contains GCP service account that enables a customer to pull codefresh images
* `values.yaml` contains different parameters for chart customization
* `values-dec.yaml` contains secrets such as `githubClientSecret`, etc.

### Also to be able to encrypt `*-dec.*` files and decrypt `*-enc.*` files `aws cli` should be configured with permissions to use AWS KMS service and [sops](https://github.com/mozilla/sops/releases) binary installed on your system.

## How to run
### 1. Clone [onprem](https://github.com/codefresh-io/onprem) repository
```
git clone git@github.com:codefresh-io/onprem.git
cd onprem
```
### 2. Decrypt `sa-enc.json` and `values-enc.yaml` files
```
./sops.sh -d
```

### 3. Make configuration changes in `sa-dec.json`, `values.yaml`, `values-dec.yaml` files and customize variables in `env-vars` file
### 4. Run `cf-onprem` script
### 5. If it is needed to upload new configuration into remote repository then encrypt `sa-dec.json`, `values-dec.yaml` files
```
./sops.sh -e
```
### 6. Commit and push changes
```
git push origin master
```



on-prem installer
pipeline quality: validation of shared volumes
