#!/usr/bin/env sh

# export CF_Key=....
# export CF_Email=...
# export CF_Zone=...


curl -X GET "https://api.cloudflare.com/client/v4/zones/$CF_Zone/dns_records?type=A,SRV" \
     -H "X-Auth-Email: $CF_Email" \
     -H "X-Auth-Key: $CF_Key" \
     -H "Content-Type: application/json" \
     -s | jq -r '.result[] | [.id,.name,.type,.content] |@tsv'	


