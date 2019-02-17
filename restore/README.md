# Restoring Codefresh on-premises

There are a few options provided to restore Codefresh on-premises from a backup - either using a Codefresh pipeline or via a K8 Job. Both options imply having a running installation of Codefresh. Otherwise, one would need to install Codefresh anew from the helm chart and then restore its state using the options below.

## Restore using pipeline

To restore Codefresh from a backup:

1. Create a pipeline using one of the YAMLs from the `restore` folder corresponding to your storage provider (Azure Blob or S3)
2. Supply the pipeline with the required environment variables
3. Run the pipeline

## Restore using a K8 job

One can restore Codefresh creating a Kubernetes Job in the same namespace where the on-prem installation is present, providing it with the necessary environment variables. Below is an example of a K8 Job YAML, which downloads a backup file from S3 and restores Codefresh from it.

```
apiVersion: batch/v1
kind: Job
metadata:
  name: codefresh-restore-job
spec:
 template:
  spec:
   initContainers:
   - name: aws-cli
     image: mesosphere/aws-cli
     env:
       - name: AWS_ACCESS_KEY_ID
         value: ...
       - name: AWS_SECRET_ACCESS_KEY
         value: ...
       - name: S3_URL
         value: s3://some-s3-bucket
       - name: BACKUP_TO_RESTORE
         value: cf-backup-20190217_103400.tar.gz
       - name: AWS_DEFAULT_REGION
         value: us-east-1
     command: 
       - "/bin/sh"
       - "-ec"
       - |
         cd /restored
         aws s3 cp $S3_URL/$BACKUP_TO_RESTORE $BACKUP_TO_RESTORE
         tar -xzvf $BACKUP_TO_RESTORE
     volumeMounts:
     - name: restored-data
       mountPath: /restored
   containers:
   - name: consul-restore
     image: consul
     command:
       - "/bin/sh"
       - "-ec"
       - |
         cd /restored/backup/*/consul
         echo "Starting Consul restore"
         curl -v -T consul.bkp http://cf-consul:8500/v1/snapshot
         echo "Consul restore completed successfully"
     volumeMounts:
     - name: restored-data
       mountPath: /restored
   - name: redis-restore
     image: codefresh/rdbtools:master
     env:
      - name: REDIS_PWD
        value: ...
     command:
       - "/bin/sh"
       - "-ec"
       - |
         cd /restored/backup/*/redis
         echo "Starting Redis restore"
         rdb --c protocol ./redis.bkp | redis-cli -u redis://cf-store:6379 -a $REDIS_PWD --pipe
         echo "Redis restore completed successfully"
     volumeMounts:
     - name: restored-data
       mountPath: /restored
   - name: mongo-restore
     image: mongo
     env:
       - name: MONGO_PWD
         value: ...
     command:
       - "/bin/sh"
       - "-ec"
       - |
         cd /restored/backup/*
         mongorestore mongo --host cf-mongodb:27017 -u root -p $MONGO_PWD --drop
         echo "Mongo restore completed successfully"
     volumeMounts:
     - name: restored-data
       mountPath: /restored
   restartPolicy: Never
   volumes:
   - name: restored-data
     emptyDir: {}
```

## Environment Variables

##### Common
| Variable| Value| Description|
| --- | --- | --- |
| MONGO_PWD |  provided by Codefresh| Mongo password |
| REDIS_PWD | provided by Codefresh | Redis password |
| BACKUP_TO_RESTORE | | The archive file contiaining the needed backup |

##### S3
| Variable| Description|
| --- | --- |
| S3_URL | S3 bucket URL in form s3://my-bucket |
| AWS_ACCESS_KEY_ID | AWS access key id |
| AWS_SECRET_ACCESS_KEY | AWS secret key |
| AWS_DEFAULT_REGION | AWS default region |

##### Azure Blob
| Variable| Description|
| --- | --- |
| AZ_USER | Azure user in order to upload backup to Azure BLOB storage |
| AZ_PWD | Azure password in order to upload backup to Azure BLOB storage |
| AZ_STORAGE_ACCOUNT | Azure BLOB storage account name |
| AZ_STORAGE_ACCESS_KEY | Azure BLOB storage account key |
| AZ_CONTAINER | Azure BLOB storage container name |