# Restore Codefresh Onprem Using Pipeline

Codefresh on-prem restore can be done using Codefresh pipeline that will fetch the archived restore artifact and restore each data layer.

## Environment Variables - Restore from Azure BLOB archive

| Variable| Value| Description|
| --- | --- | --- |
| CF_SKIP_MAIN_CLONE | true | Skip git clone step |
| MONGO_PWD |  | Mongo password (will be provided by Codefresh) |
| REDIS_PWD |  | Redis password (will be provided by Codefresh) |
| AZ_USER |  | Azure user in order to upload backup to Azure BLOB storage |
| AZ_PWD |  | Azure password in order to upload backup to Azure BLOB storage |
| AZ_STORAGE_ACCOUNT |  | Azure BLOB storage account name |
| AZ_STORAGE_ACCESS_KEY |  | Azure BLOB storage account key |
| AZ_CONTAINER |  | Azure BLOB storage container name |
| AZ_BLOB |  | Azure BLOB archive you want to restore from |

