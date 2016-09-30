# OpenShift 3.2
## Storing binding
|   |PersistentVolume|PersistentVolumeClaim|Result|
|---|---|---|
|accessModes|ReadWriteMany|ReadWriteOnce|Not Bound|
|accessModes|ReadWriteMany, ReadWriteOnce|ReadWriteOnce|Bound|
|storage|5Gi   |5Gi   | Bound
|storage|5Gi   |3Gi   | Bound
