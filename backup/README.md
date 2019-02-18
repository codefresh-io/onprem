# Backup Codefresh on-premises

Codefresh on-premises backup can be done either with a Codefresh pipeline or with a K8 CronJob. To save the state of an on-prem installation, it is needed to backup 3 databases - mongo, consul and redis. 

## Backup using pipeline

The backup pipeline provides automation to save the Codefresh on-prem installation state to a tarball and upload it to a storage of your choice. Currently pipelines for S3 and Azure Blob Storage are available.

To enable Codefresh backups:

1. Create a pipeline using one of the YAMLs from the `backup` folder corresponding to your storage provider (Azure Blob or S3)
2. Supply the pipeline with the required environment variables
3. Setup a [cron trigger](https://codefresh.io/docs/docs/configure-ci-cd-pipeline/triggers/cron-triggers/) to run the backup pipeline continuosly
4. [Configure notifications](https://codefresh.io/docs/docs/integrations/notifications) to be informed in case if a backup fails

## Backup using a CronJob

One can create a custom CronJob for Codefresh on-prem backups. [Here](./BackupCronJobExample.yml) is a working example of such CronJob, which dumps all the databases every day at 1.00AM and uploads the archive file to an S3 bucket. To run just fill in the environment variable values and type `kubectl apply -f yourBackupCronJob.yaml -n codefresh`

## Environment Variables

##### Common
| Variable| Value| Description|
| --- | --- | --- |
| MONGO_PWD |  provided by Codefresh| Mongo password |
| REDIS_PWD | provided by Codefresh | Redis password |

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
