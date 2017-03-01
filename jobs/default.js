apiVersion: batch/v1
kind: Job
metadata:
  name: pi-fail
spec:
  parallelism: 1
  completions: 1
  template:
    metadata:
      name: pi-fail
    spec:
      containers:
      - name: pi-fail
        image: perl
        command: ["perl",  "-wle", "exit 1"]
      restartPolicy: Never
