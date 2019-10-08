# initContainers example

Example for

* DNS Check
* TCP Check

```text
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: myapp-container
    image: busybox
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: check-tcp
    image: rhel7/rhel-tools
    command: ['sh', '-c', 'while true ; do echo "Try to connect " ; nc -z myserver 8080 && break; sleep 5; done; echo "Eventserver is running..."']
  - name: check-nslookup
    image: busybox
    command: ['sh', '-c', 'while true; do nslookup mydb || break ; sleep 2 ; echo "waiting for mydb"; done;']
```

