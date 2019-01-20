global:

### Instantiate databases with seed data. Usually used in dynamic and on-prem environments.
  #seedJobs: true
  #certsJobs: true

  appProtocol: https
### Codefresh App domain name
  appUrl: your-domain.com

### MTU Value for dockerd in builder and runner
#  mtu: 1400

### Environment variables applied to all pods
#  env:
#    HTTP_PROXY: "http://myproxy.domain.com:8080"
#    http_proxy: "http://myproxy.domain.com:8080"
#    HTTPS_PROXY: "http://myproxy.domain.com:8080"
#    https_proxy: "http://myproxy.domain.com:8080"
#    NO_PROXY: "127.0.0.1,localhost,kubernetes.default.svc,.codefresh.svc,100.64.0.1,169.254.169.254,cf-builder,cf-cfapi,cf-cfui,cf-chartmuseum,cf-charts-manager,cf-cluster-providers,cf-consul,cf-consul-ui,cf-context-manager,cf-cronus,cf-helm-repo-manager,cf-hermes,cf-ingress-controller,cf-ingress-http-backend,cf-kube-integration,cf-mongodb,cf-nats,cf-nomios,cf-pipeline-manager,cf-postgresql,cf-rabbitmq,cf-redis,cf-registry,cf-runner,cf-runtime-environment-manager,cf-store"
#    no_proxy: "127.0.0.1,localhost,kubernetes.default.svc,.codefresh.svc,100.64.0.1,169.254.169.254,cf-builder,cf-cfapi,cf-cfui,cf-chartmuseum,cf-charts-manager,cf-cluster-providers,cf-consul,cf-consul-ui,cf-context-manager,cf-cronus,cf-helm-repo-manager,cf-hermes,cf-ingress-controller,cf-ingress-http-backend,cf-kube-integration,cf-mongodb,cf-nats,cf-nomios,cf-pipeline-manager,cf-postgresql,cf-rabbitmq,cf-redis,cf-registry,cf-runner,cf-runtime-environment-manager,cf-store"


### Firebase secret
firebaseSecret: 

### Uncomment if kubernetes cluster is RBAC enabled
rbacEnable: true

## Custom annotations for Codefresh ingress resource that override defaults
#annotations:
   #kubernetes.io/ingress.class: nginx-codefresh

ingress:
### Codefresh App domain name    
  domain: your-domain.com
### Uncomment if kubernetes cluster is RBAC enabled
  rbacEnable: true
### The name of kebernetes secret with customer certificate and private key
  webTlsSecretName: "star.codefresh.io"  

### For github provider (the apiHost and loginHost are different)
cfapi:
  rbacEnable: true

### Define kubernetes secret name for customer certificate and private key
webTLS:
  secretName: star.codefresh.io


consul:
### If needed to use storage class that different from default
  StorageClass: {}
### Use existing volume claim name
  #pvcName: cf-consul
### Use NodeSelector to assing pod to a node
  nodeSelector: {}
#    services: consul-postgresql

postgresql:
  persistence:
    #existingClaim: cf-postgresql
    storageClass: {}
  nodeSelector: {}
#    services: consul-postgresql

mongodb:
## Enable persistence using Persistent Volume Claims
## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
##
##  IMPORTANT !
##  It is not possible the combination when pvcName is defined and persistence:enabled = true
##  Only one of two:
##  pvcName is defined AND persistence:enabled = false
##  OR
##  pvcName is not defined (commented out) AND persistence:enabled = true
##  
## Use existing volume claim name
  #pvcName: cf-mongodb
## Provision new volume claim
  persistence:
    enabled: true
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    storageClass: {}
    accessMode: ReadWriteOnce
    size: 8Gi

  nodeSelector: {}
#    provisioner: local-volume

redis:
  persistence:
## Use existing volume claim name    
    #existingClaim: cf-redis
    storageClass: {}
  nodeSelector: {}
#    provisioner: local-volume

rabbitmq:
  persistence:
## Use existing volume claim name
    #existingClaim: cf-rabbitmq  
    storageClass: {}
  nodeSelector: {}
#    services: rabbitmq-registry

registry:
  storageClass: {}
## Override default (4Gi) initial registry PV size  
  #storageSize: {}
  ## Use existing volume claim name
  #pvcName: cf-registry
  nodeSelector: {}
#    services: rabbitmq-registry
## Uncomment if needed to apply custom configuration to registry
  #registryConfig:
## Insert custom registry configuration (https://docs.docker.com/registry/configuration/)
    #version: 0.1
    #log:
      #level: debug
      #fields:
        #service: registry
    #storage:
      #cache:
        #blobdescriptor: inmemory
      #s3:
         #region: YOUR_REGION
         #bucket: YOUR_BUCKET_NAME
         #accesskey: AWS_ACCESS_KEY
         #secretkey: AWS_SECRET_KEY
    #http:
      #addr: :5000
      #headers:
        #X-Content-Type-Options: [nosniff]
    #health:
      #storagedriver:
        #enabled: true
        #interval: 10s
        #threshold: 3

hermes:
  nodeSelector: {}
#    services: rabbitmq-registry
  redis:
## Set hermes store password. It is mandatory
    redisPassword: verysecurepassword
    nodeSelector: {}
#      services: rabbitmq-registry
    persistence:
## Use existing volume claim name
      #existingClaim: cf-store
      storageClass: {}

cronus:
  storageClass: {}
## Use existing volume claim name
  #pvcName: cf-cronus
  nodeSelector: {}
#    services: rabbitmq-registry

builder:
## Use existing volume claim name
  #pvcName: cf-builder
## Set time to run docker cleaner  
  dockerCleanerCron: 0 0 * * *
## Override builder PV initial size
  varLibDockerVolume:
    storageClass: {}
    storageSize: 100Gi

runner:
## Use existing volume claim name  
  #pvcName: cf-runner
## Set time to run docker cleaner  
  dockerCleanerCron: 0 0 * * *
## Override runner PV initial size
  varLibDockerVolume:
    storageClass: {}
    storageSize: 100Gi

helm-repo-manager:
  RepoUrlPrefix: "cm://<app_url>"

backups:
  #enabled: true
  awsAccessKey: 
  awsSecretAccessKey: 
  s3Url: s3://<some-bucket>
    
