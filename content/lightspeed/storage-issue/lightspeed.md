You: Why is my deployment storage-issue in project demo-app only one of two pods running?

OpenShift Lightspeed: The issue lies with the second pod (`storage-issue-5cb4d5d794-qph6w`) being stuck in `ContainerCreating` state. This is likely due to the `PersistentVolumeClaim` (`storage-issue`) being configured with `ReadWriteOnce` access mode, which restricts the volume to be mounted by only one pod at a time.

### Resolution:
1. **Change Access Mode**: Update the PVC to use `ReadWriteMany` if your storage backend supports it.
2. **Separate PVCs**: Create individual PVCs for each pod if `ReadWriteMany` is not supported.
3. **Verify Storage Backend**: Ensure the storage class (`coe-netapp-san`) supports the required access mode.

Let me know if you need guidance on implementing these changes.