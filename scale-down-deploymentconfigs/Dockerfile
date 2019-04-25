FROM python:2

RUN pip install openshift
ADD scale_down.py /scale_down.py

ENV K8S_AUTH_KEY_FILE=/var/run/secrets/kubernetes.io/serviceaccount
ENTRYPOINT ["/scale_down.py"]
CMD []
