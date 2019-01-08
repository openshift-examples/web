#!/bin/sh
echo -e "HTTP/1.1 200 OK\r"
echo -e "Content-Type: text/plain\r"
echo -e "\r"

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
read request
echo $request
