# Alertmanager

## Setup Slack receiver

{% embed url="https://docs.openshift.com/container-platform/latest/monitoring/cluster\_monitoring/configuring-the-monitoring-stack.html\#applying-custom-alertmanager-configuration\_configuring-monitoring" %}

### Example `alertmanager.yaml` with proxy settings

{% hint style="info" %}
Alertmanager do not pickup global proxy settings.
{% endhint %}

{% code title="foo.yaml" %}
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
{% endcode %}

#### Apply config:

```bash
oc -n openshift-monitoring create secret generic alertmanager-main \
   --from-file=alertmanager.yaml=foo.yaml \
   --dry-run -o=yaml |  oc -n openshift-monitoring replace secret \
   --filename=-
```

## Setup Telegram receiver

Connected Prometheus alertmanager via [webhook receiver](https://prometheus.io/docs/alerting/configuration/#webhook_config) to telegram.

```bash
oc new-project telegram
# Build and deploy
oc new-app --name=telegram \
    https://github.com/rbo/alertmanager-webhook-telegram.git
```

Add enviorment variables to deploymentconfig telegram

```bash
FLASK_ENV=development # If you like debug output ;-)
APP_FILE=flaskAlert.py
TELEGRAM_BOTTOKEN="9999999999:AAAAAA-AAAAAA-AAAAA...."
TELEGRAM_CHATID="999999999"
BASIC_AUTH_USERNAME="aiPh1eHu"
BASIC_AUTH_PASSWORD="eoPhait8"
```

Adjust alertmanager.yaml, example:

{% code title="alertmanager.yaml" %}
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
{% endcode %}

