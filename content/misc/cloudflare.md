---
title: CloudFlare
linktitle: CloudFlare
weight: 99100
description: TBD
---
# Cloudflare

## API
### Remove
```bash
#!/usr/bin/env sh

# export CF_Key=....
# export CF_Email=...

curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_Zone/dns_records/$1" \
     -H "X-Auth-Email: $CF_Email" \
     -H "X-Auth-Key: $CF_Key" \
     -H "Content-Type: application/json"
```
### List
```bash
#!/usr/bin/env sh

# export CF_Key=....
# export CF_Email=...
# export CF_Zone=...


curl -X GET "https://api.cloudflare.com/client/v4/zones/$CF_Zone/dns_records?type=A,SRV" \
     -H "X-Auth-Email: $CF_Email" \
     -H "X-Auth-Key: $CF_Key" \
     -H "Content-Type: application/json" \
     -s | jq -r '.result[] | [.id,.name,.type,.content] |@tsv'
```

### Add
```bash
#!/usr/bin/env sh

# export CF_Key=....
# export CF_Email=...


curl -X POST "https://api.cloudflare.com/client/v4/zones/$CF_Zone/dns_records" \
     -H "X-Auth-Email: $CF_Email" \
     -H "X-Auth-Key: $CF_Key" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"A\",\"name\":\"$1\",\"content\":\"$2\",\"ttl\":120,\"priority\":10,\"proxied\":false}"

```
