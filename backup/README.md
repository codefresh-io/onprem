# Backup Codefresh on-premises

## Backup using pipeline

Codefresh on-prem backup can be done using Codefresh pipeline and the archive can be uploaded to a storage of your choice. Currently pipelines for S3 and Azure Blob Storage are available.

To enable Codefresh backups:

1. Create a pipeline using one of the YAMLs from the `backup` folder corresponding to your storage provider (Azure Blob or S3)
2. Supply the pipeline with the required environment variables
3. Setup a [cron trigger](https://codefresh.io/docs/docs/configure-ci-cd-pipeline/triggers/cron-triggers/) to run the backup pipeline continuosly
4. [Configure notifications](https://codefresh.io/docs/docs/integrations/notifications) to be informed in case if a backup fails

It is strongly advised to run at least **one test restore** on a **separate clean** Codefresh installation before leaving the backups running on a regular basis.

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
