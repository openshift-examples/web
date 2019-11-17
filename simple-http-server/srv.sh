#!/bin/sh
read request
url="${request#GET }"
url="${url% HTTP/*}"
query="${url#*\?}"
url="${url%%\?*}"

echo -e "HTTP/1.1 200 OK\r"
echo -e "Content-Type: text/plain\r"
echo -e "X-ENV-HOSTNAME: $HOSTNAME\r"
echo -e "\r"

if [ "$query" == "/demo" ] ; then
  echo "# Connection test from $HOSTNAME"
  DEMO_FROM="$(hostname | cut -f1 -d'-').$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)"
  # Skip connection to yourself, because of https://gist.github.com/rbo/4aa7840ebabf11aad3bf7961619e18e3
  # for i in marge.simpson homer.simpson selma.bouvier patty.bouvier ; do 
  echo "marge.simpson homer.simpson selma.bouvier patty.bouvier" | tr " " "\n" | grep -v "$(echo $HOSTNAME | cut -f1 -d'-')" | while read i ; do
    echo -n "$DEMO_FROM -> $i : " 
    curl -I -s --connect-timeout 1 $i:8080  >/dev/null && echo "OK" || echo "FAIL";
  done;
  exit;
fi;

echo "# Basic POD Informations"
echo -e "\n## Env"
env | sort

echo -e "\n## ip addr show"
ip addr show

echo -e "\n## ip route show"
ip route show

echo -e "\n## resolv.conf"
cat /etc/resolv.conf

echo -e "\n## request"
echo $request
