---
title: Alertmanager
linktitle: Alertmanager
weight: 17100
description: TBD
---
# Alertmanager

Documentation: [Sending notifications to external systems](https://docs.openshift.com/container-platform/latest/monitoring/managing-alerts.html#sending-notifications-to-external-systems_managing-alerts)

## Example receiver

* Webhook: [Debug receiver - log alerts to stdout](debug-receiver.md)
* Webhook: [Telegram receiver](telegram-receiver.md)
* Webhook: [Microsoft Teams receiver](microsoft-teams-receiver.md)
* E-Mail: [Using labels to direct email notifications](https://www.robustperception.io/using-labels-to-direct-email-notifications)

### Proxy & Alertmanager

!!! warning
    Alertmanager do not pickup global proxy settings.

alertmanager.yaml

```yaml
"global":
  "resolve_timeout": "5m"
  slack_api_url: https://hooks.slack.com/services/xxxx/xxxx/xxxxx
"receivers":
  - name: slack
    slack_configs:
    - channel: '#ops'
      http_config:
        proxy_url: http://192.168.51.1:8888

"route":
  "group_by":
  - "job"
  "group_interval": "5m"
  "group_wait": "30s"
  "receiver": "slack"
  "repeat_interval": "12h"
  "routes":
    - receiver: slack
      match:
        alertname: Watchdog

```

#### Apply config

```bash
oc -n openshift-monitoring create secret generic alertmanager-main \
   --from-file=alertmanager.yaml=alertmanager.yaml \
   --dry-run -o=yaml |  oc -n openshift-monitoring replace secret \
   --filename=-
```
