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

