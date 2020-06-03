global:

### expose codefresh internal registry from ingress
  #registryPort: 443
  #exposeRegistry: true

### configuring external mongo database service
  #mongodbRootUser: my-mongo-admin-user
  #mongodbRootPassword: yeqTeVwqVa9qDqebq
  #mongoURI: mongodb://someuser:mTiqweAsdw@my-mongo-cluster-shard-00-00-vziq1.mongodb.net:27017/?ssl=true
  #mongoSkipUserCreation: true
  #mongoDeploy: false   # disables deployment of internal mongo service

  appProtocol: https
### Codefresh App domain name
  appUrl: your-domain.com

# Storage class for all persistent services (only in case your storage class supports automatic volume provisioning). By default Codefresh will use the default storage class configured in your cluster, if the storage class you want to use isn't set as default in your k8s cluster please use this variable to describe it
#  storageClass: my-storage-class

# Default nodeSelector for storage pods. Useful in case of local volumes
#  storagePodNodeSelector:
#    kubernetes.io/hostname: storage-host-01

### MTU Value for dockerd in builder and runner
#  mtu: 1400

### Environment variables applied to all pods
#  env:
#    HTTP_PROXY: "http://myproxy.domain.com:8080"
#    http_proxy: "http://myproxy.domain.com:8080"
#    HTTPS_PROXY: "http://myproxy.domain.com:8080"
#    https_proxy: "http://myproxy.domain.com:8080"
#    NO_PROXY: "127.0.0.1,localhost,kubernetes.default.svc,.codefresh.svc,100.64.0.1,169.254.169.254,cf-builder,cf-cfapi,cf-payments,cf-cfui,cf-chartmuseum,cf-charts-manager,cf-cluster-providers,cf-consul,cf-consul-ui,cf-context-manager,cf-cronus,cf-helm-repo-manager,cf-hermes,cf-ingress-controller,cf-ingress-http-backend,cf-kube-integration,cf-mongodb,cf-nats,cf-nomios,cf-pipeline-manager,cf-postgresql,cf-rabbitmq,cf-redis,cf-registry,cf-runner,cf-runtime-environment-manager,cf-store,cf-tasker-kubernetes"
#    no_proxy: "127.0.0.1,localhost,kubernetes.default.svc,.codefresh.svc,100.64.0.1,169.254.169.254,cf-builder,cf-cfapi,cf-payments,cf-cfui,cf-chartmuseum,cf-charts-manager,cf-cluster-providers,cf-consul,cf-consul-ui,cf-context-manager,cf-cronus,cf-helm-repo-manager,cf-hermes,cf-ingress-controller,cf-ingress-http-backend,cf-kube-integration,cf-mongodb,cf-nats,cf-nomios,cf-pipeline-manager,cf-postgresql,cf-rabbitmq,cf-redis,cf-registry,cf-runner,cf-runtime-environment-manager,cf-store,cf-tasker-kubernetes"

### Firebase secret
firebaseSecret: 

tls:
  selfSigned: false
  cert: certs/ssl.crt
  key: certs/private.key

## Custom annotations for Codefresh ingress resource that override defaults
#annotations:
#  kubernetes.io/ingress.class: nginx-codefresh

## Persistent services (mongodb, consul, postgress, redit, rabbit) configuration
# you can configure storageClass for dynamic volume provisoning or precreated existingPvc name
# existingPvc should exist before launching the intallation and takes precedence over storageClass
#
# Specify node selector if 
# Example 1, mongodb with storageClass for dynamic volume provisoning:
# mongodb:
#   storageClass: ceph-pool-1
#   storageSize: 8Gi
#
# Example 2, postgresql on precreated pvc for local volume on cpecific volume
# 
# postgresql:
#   existingPvc: cf-postgress-lv
#   nodeSelector:
#     kubernetes.io/hostname: storage-host-01

mongodb:
  storageSize: 8Gi
  storageClass: 
  #existingPvc: cf-mongodb
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01

postgresql:
  storageSize: 8Gi
  storageClass:
  #existingPvc: cf-postgresql
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01

consul:
  storageSize: 1Gi
  storageClass:
  #existingPvc: cf-consul-0
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01

redis:
  storageSize: 8Gi
  storageClass:
  #existingPvc: cf-redis
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01

rabbitmq:
  storageSize: 8Gi
  storageClass:
  #existingPvc: cf-rabbitmq
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01

cronus:
  storageSize: 1Gi
  storageClass:
  #existingPvc: cf-cronus
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01

chartmuseum:
  storageSize: 8Gi
  storageClass:
  #existingPvc: cf-chartmuseum
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01

hermes:
  redis:
## Set hermes store password. It is mandatory
    redisPassword: verysecurepassword
    storageSize: 8Gi
    storageClass:
    #existingPvc: cf-store
    #nodeSelector:
    #  kubernetes.io/hostname: storage-host-01

registry:
  storageSize: 100Gi
  storageClass:
  #existingPvc: cf-registry
  #nodeSelector:
  #  kubernetes.io/hostname: storage-host-01
# Insert custom registry configuration (https://docs.docker.com/registry/configuration/)
#   registryConfig:
#     version: 0.1
#     log:
#       level: debug
#       fields:
#         service: registry
#     storage:
#       cache:
#         blobdescriptor: inmemory
#       s3:
#          region: YOUR_REGION
#          bucket: YOUR_BUCKET_NAME
#          accesskey: AWS_ACCESS_KEY
#          secretkey: AWS_SECRET_KEY
#     http:
#       addr: :5000
#       headers:
#         X-Content-Type-Options: [nosniff]
#     health:
#       storagedriver:
#         enabled: true
#         interval: 10s
#         threshold: 3 

builder:
  nodeSelector: {}
## Set time to run docker cleaner  
  dockerCleanerCron: 0 0 * * *
## Override builder PV initial size
  storageSize: 100Gi
  storageClass:
  #existingPvc: cf-builder-0

runner:
  nodeSelector: {}
## Set time to run docker cleaner  
  dockerCleanerCron: 0 0 * * *
## Override runner PV initial size
  storageSize: 100Gi
  storageClass:
  #existingPvc: cf-runner-0


# backups:
#   #enabled: true
#   awsAccessKey: 
#   awsSecretAccessKey: 
#   s3Url: s3://<some-bucket>

# Set github token in order to enable public marketplace steps
# pipeline-manager:
#   stepsCatalogGithubToken: <GITHUB-TOKEN>
