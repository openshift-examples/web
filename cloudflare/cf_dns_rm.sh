#!/usr/bin/env sh

# export CF_Key=....
# export CF_Email=...

curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_Zone/dns_records/$1" \
     -H "X-Auth-Email: $CF_Email" \
     -H "X-Auth-Key: $CF_Key" \
     -H "Content-Type: application/json" 

