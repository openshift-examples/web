---
title: Telegram receiver
linktitle: Telegram receiver
description: Telegram receiver
tags:
  - alertmanager
  - prometheus
  - Telegram
  - monitoring
---

# Deploy Telegram receiver

Connected Prometheus alertmanager via [webhook receiver](https://prometheus.io/docs/alerting/configuration/#webhook_config) to telegram.

```bash
oc new-project telegram
# Build and deploy
oc new-app --name=telegram \
    https://github.com/openshift-examples/alertmanager-webhook-telegram.git
```

Add enviorment variables to deploymentconfig telegram

```bash
FLASK_ENV=development # If you like debug output ;-)
APP_FILE=flaskAlert.py
TELEGRAM_BOTTOKEN="9999999999:AAAAAA-AAAAAA-AAAAA...."
TELEGRAM_CHATID="999999999"
BASIC_AUTH_USERNAME="aiPh1eHu"
BASIC_AUTH_PASSWORD="eoPhait8"
# In case of proxy env:
HTTP_PROXY="http://192.168.51.1:8888"
HTTPS_PROXY="http://192.168.51.1:8888"
```

Adjust alertmanager.yaml, example:

alertmanager.yaml
```yaml
"global":
  "resolve_timeout": "5m"
"receivers":
  - name: 'telegram-webhook'
    webhook_configs:
    - url: http://telegram.telegram.svc.cluster.local:8080/alert
      send_resolved: true
      http_config:
        basic_auth:
          username: 'aiPh1eHu'
          password: 'eoPhait8'
"route":
  "group_by":
  - "job"
  "group_interval": "5m"
  "group_wait": "30s"
  "receiver": "telegram-webhook"
  "repeat_interval": "12h"
  "routes":
    - receiver: telegram-webhook
      match:
        alertname: Watchdog

```

