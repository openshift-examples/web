---
description: My person steps to learn and play with velero
---

# Velero

[https://velero.io/](https://velero.io/)

## My stupid copy & paste log

```bash
# Setup a fedoa-31 on hetzner cloud to play with Velero
hcloud server create \
    --image fedora-31 \
    --datacenter nbg1-dc3 \
    --name velero-test \
    --type cx41


Server 5098247 created
IPv4: 116.203.134.183
Root password: 9nUT3VfKFCmmtjn4fd9F
static.183.134.203.116.clients.your-server.de.

yum install -y tmux pwgen jq
yum update -y 


# Deploy min.io server

curl -L -O https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mkdir /srv/minio
export MINIO_ACCESS_KEY=$(pwgen -1 -n 16)
export MINIO_SECRET_KEY=$(pwgen -1 -n 16)

./minio server /srv/minio
Attempting encryption of all config, IAM users and policies on MinIO backend
Endpoint:  http://116.203.134.183:9000  http://127.0.0.1:9000
AccessKey: eimoh0Je9EipioTh
SecretKey: Eikohgeeth6coo8k

Browser Access:
   http://116.203.134.183:9000  http://127.0.0.1:9000

Command-line Access: https://docs.min.io/docs/minio-client-quickstart-guide
   $ mc config host add myminio http://116.203.134.183:9000 eimoh0Je9EipioTh Eikohgeeth6coo8k

Object API (Amazon S3 compatible):
   Go:         https://docs.min.io/docs/golang-client-quickstart-guide
   Java:       https://docs.min.io/docs/java-client-quickstart-guide
   Python:     https://docs.min.io/docs/python-client-quickstart-guide
   JavaScript: https://docs.min.io/docs/javascript-client-quickstart-guide
   .NET:       https://docs.min.io/docs/dotnet-client-quickstart-guide
   



# min.io client
curl -L -O https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/

mc config host add myminio http://116.203.134.183:9000 eimoh0Je9EipioTh Eikohgeeth6coo8k
mc mb myminio/velero
Bucket created successfully `myminio/velero`.
[root@velero-test ~]# mc ls myminio
[2020-03-24 16:53:23 CET]      0B velero/

Open http://116.203.134.183:9000 on your browser ;-)


# Install openshift client

curl -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.3.8/openshift-client-linux-4.3.8.tar.gz
tar -C /usr/local/bin/ -xzvf openshift-client-linux-4.3.8.tar.gz

oc login <your openshift client>

oc new-project velero

# Install velero cli
curl -L -O https://github.com/vmware-tanzu/velero/releases/download/v1.3.1/velero-v1.3.1-linux-amd64.tar.gz
tar --strip-components=1 -C /usr/local/bin/ -xzvf velero-v1.3.1-linux-amd64.tar.gz velero-v1.3.1-linux-amd64/velero



# https://velero.io/docs/v1.3.1/contributions/minio/
cat >credentials-velero <<EOF
[default]
aws_access_key_id = eimoh0Je9EipioTh
aws_secret_access_key = Eikohgeeth6coo8k
EOF

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.0.0 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://116.203.134.183:9000

CustomResourceDefinition/backups.velero.io: attempting to create resource
CustomResourceDefinition/backups.velero.io: already exists, proceeding
CustomResourceDefinition/backups.velero.io: created
CustomResourceDefinition/backupstoragelocations.velero.io: attempting to create resource
CustomResourceDefinition/backupstoragelocations.velero.io: already exists, proceeding
CustomResourceDefinition/backupstoragelocations.velero.io: created
CustomResourceDefinition/deletebackuprequests.velero.io: attempting to create resource
CustomResourceDefinition/deletebackuprequests.velero.io: already exists, proceeding
CustomResourceDefinition/deletebackuprequests.velero.io: created
CustomResourceDefinition/downloadrequests.velero.io: attempting to create resource
CustomResourceDefinition/downloadrequests.velero.io: already exists, proceeding
CustomResourceDefinition/downloadrequests.velero.io: created
CustomResourceDefinition/podvolumebackups.velero.io: attempting to create resource
CustomResourceDefinition/podvolumebackups.velero.io: already exists, proceeding
CustomResourceDefinition/podvolumebackups.velero.io: created
CustomResourceDefinition/podvolumerestores.velero.io: attempting to create resource
CustomResourceDefinition/podvolumerestores.velero.io: already exists, proceeding
CustomResourceDefinition/podvolumerestores.velero.io: created
CustomResourceDefinition/resticrepositories.velero.io: attempting to create resource
CustomResourceDefinition/resticrepositories.velero.io: already exists, proceeding
CustomResourceDefinition/resticrepositories.velero.io: created
CustomResourceDefinition/restores.velero.io: attempting to create resource
CustomResourceDefinition/restores.velero.io: already exists, proceeding
CustomResourceDefinition/restores.velero.io: created
CustomResourceDefinition/schedules.velero.io: attempting to create resource
CustomResourceDefinition/schedules.velero.io: already exists, proceeding
CustomResourceDefinition/schedules.velero.io: created
CustomResourceDefinition/serverstatusrequests.velero.io: attempting to create resource
CustomResourceDefinition/serverstatusrequests.velero.io: already exists, proceeding
CustomResourceDefinition/serverstatusrequests.velero.io: created
CustomResourceDefinition/volumesnapshotlocations.velero.io: attempting to create resource
CustomResourceDefinition/volumesnapshotlocations.velero.io: already exists, proceeding
CustomResourceDefinition/volumesnapshotlocations.velero.io: created
Waiting for resources to be ready in cluster...
Namespace/velero: attempting to create resource
Namespace/velero: already exists, proceeding
Namespace/velero: created
ClusterRoleBinding/velero: attempting to create resource
ClusterRoleBinding/velero: already exists, proceeding
ClusterRoleBinding/velero: created
ServiceAccount/velero: attempting to create resource
ServiceAccount/velero: already exists, proceeding
ServiceAccount/velero: created
Secret/cloud-credentials: attempting to create resource
Secret/cloud-credentials: already exists, proceeding
Secret/cloud-credentials: created
BackupStorageLocation/default: attempting to create resource
BackupStorageLocation/default: already exists, proceeding
BackupStorageLocation/default: created
Deployment/velero: attempting to create resource
Deployment/velero: already exists, proceeding
Deployment/velero: created
Velero is installed! ⛵ Use 'kubectl logs deployment/velero -n velero' to view the status.

# Check deployment/velero

velero backup create hetzner-ocp4 --include-namespaces hetzner-ocp4
Backup request "hetzner-ocp4" submitted successfully.
Run `velero backup describe hetzner-ocp4` or `velero backup logs hetzner-ocp4` for more details.

[root@velero-test ~]# mc cat myminio/velero/backups/hetzner-ocp4/hetzner-ocp4-resource-list.json.gz | gzip -d | jq | head
{
  "apiextensions.k8s.io/v1/CustomResourceDefinition": [
    "clusterserviceversions.operators.coreos.com",
    "pipelineresources.tekton.dev",
    "pipelineruns.tekton.dev",
    "pipelines.tekton.dev",
    "taskruns.tekton.dev",
    "tasks.tekton.dev"
  ],
  "authorization.openshift.io/v1/RoleBinding": [
 
  
velero restore  create --from-backup hetzner-ocp4 \
  --namespace-mappings hetzner-ocp4:restored-hetzner-ocp4

Restore request "hetzner-ocp4-20200324170808" submitted successfully.
Run `velero restore describe hetzner-ocp4-20200324170808` or `velero restore logs hetzner-ocp4-20200324170808` for more details.


velero restore get
NAME                          BACKUP         STATUS       WARNINGS   ERRORS   CREATED                         SELECTOR
hetzner-ocp4-20200324170808   hetzner-ocp4   InProgress   0          0        2020-03-24 17:08:07 +0100 CET   <none>

velero restore get
NAME                          BACKUP         STATUS            WARNINGS   ERRORS   CREATED                         SELECTOR
hetzner-ocp4-20200324170808   hetzner-ocp4   PartiallyFailed   9          6        2020-03-24 17:08:07 +0100 CET   <none>

# Skip customresourcedefinitions.apiextensions.k8s.io and taskruns

velero backup delete hetzner-ocp4
Are you sure you want to continue (Y/N)? y
Request to delete backup "hetzner-ocp4" submitted successfully.
The backup will be fully deleted after all associated data (disk snapshots, backup files, restores) are removed.

oc delete namespace restored-hetzner-ocp4
namespace "restored-hetzner-ocp4" deleted

velero backup create hetzner-ocp4 \
  --include-namespaces hetzner-ocp4 \
  --exclude-resources=taskruns.tekton.dev,customresourcedefinitions.apiextensions.k8s.io
  
  
mc cat myminio/velero/backups/hetzner-ocp4/hetzner-ocp4-resource-list.json.gz  | gzip -d | jq 'keys'
[
  "authorization.openshift.io/v1/RoleBinding",
  "operators.coreos.com/v1alpha1/ClusterServiceVersion",
  "rbac.authorization.k8s.io/v1/RoleBinding",
  "tekton.dev/v1alpha1/Pipeline",
  "tekton.dev/v1alpha1/PipelineResource",
  "tekton.dev/v1alpha1/PipelineRun",
  "tekton.dev/v1alpha1/Task",
  "v1/Namespace",
  "v1/Secret",
  "v1/ServiceAccount"
]

velero backup create hetzner-ocp4 \
  --include-namespaces hetzner-ocp4 \
  --exclude-resources=clusterserviceversions.operators.coreos.com,pipelinerun.tekton.dev,taskruns.tekton.dev,customresourcedefinitions.apiextensions.k8s.io

velero backup get
NAME           STATUS      CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
hetzner-ocp4   Completed   2020-03-24 17:18:10 +0100 CET   29d       default            <none>

mc cat myminio/velero/backups/hetzner-ocp4/hetzner-ocp4-resource-list.json.gz  | gzip -d | jq 'keys'
[
  "authorization.openshift.io/v1/RoleBinding",
  "rbac.authorization.k8s.io/v1/RoleBinding",
  "tekton.dev/v1alpha1/Pipeline",
  "tekton.dev/v1alpha1/PipelineResource",
  "tekton.dev/v1alpha1/Task",
  "v1/Namespace",
  "v1/Secret",
  "v1/ServiceAccount"
]


 oc get backups
NAME           AGE
hetzner-ocp4   3m25s

oc get crds | grep velero
backups.velero.io                                           2020-03-15T15:59:54Z
backupstoragelocations.velero.io                            2020-03-15T15:59:54Z
deletebackuprequests.velero.io                              2020-03-15T15:59:54Z
downloadrequests.velero.io                                  2020-03-15T15:59:54Z
podvolumebackups.velero.io                                  2020-03-15T15:59:54Z
podvolumerestores.velero.io                                 2020-03-15T15:59:54Z
resticrepositories.velero.io                                2020-03-15T15:59:54Z
restores.velero.io                                          2020-03-15T15:59:54Z
schedules.velero.io                                         2020-03-15T15:59:55Z
serverstatusrequests.velero.io                              2020-03-15T15:59:55Z
volumesnapshotlocations.velero.io                           2020-03-15T15:59:55Z


velero create schedule hetzner-ocp4-sched --schedule="@every 1m" \
  --include-namespaces hetzner-ocp4 \
  --exclude-resources=clusterserviceversions.operators.coreos.com,pipelinerun.tekton.dev,taskruns.tekton.dev,customresourcedefinitions.apiextensions.k8s.io



# Uninstall
oc delete velero
hcloud server delete velero-test
```

