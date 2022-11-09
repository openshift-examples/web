---
title: Microsoft Teams receiver
linktitle: Microsoft Teams receiver
description: Send OpenShift alert to Microsoft Teams
tags:
  - alertmanager
  - prometheus
  - microsoft-teams
  - monitoring
---

# Microsoft Teams Configuration

- On Microsoft Teams, create new channel to the teams that should receive notifications

- Install "Incoming Webhook" connector by click the dots beside the channel and click on Connectors

- Configure the webhook, and notes the webhook URL 



# Deploy Microsoft Teams receiver

## Deploye prometheus-msteams

Create new project on OpenShift using [prometheus-msteams](https://github.com/prometheus-msteams/prometheus-msteams)

```bash
oc new-project prometheus-msteams
oc project prometheus-msteams
oc new-app --name="promteams" \
    -e TEAMS_INCOMING_WEBHOOK_URL="https://teams-webhook-url" \
    -e TEAMS_REQUEST_URI=alertmanager \
    -e HTTP_PROXY="http://x.x.x.x" \
    -e HTTPS_PROXY="http://x.x.x.x" \
    quay.io/prometheusmsteams/prometheus-msteams
```

## Configure Alertmanager

After deploying prometheus-msteams go to alert manager configuration, and create new webhook receiver with url:
```
http://promteams.prometheus-msteams.svc.cluster.local:2000/alertmanager
```