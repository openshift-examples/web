#!/bin/sh
echo -e "HTTP/1.1 200 OK\r"
echo -e "Content-Type: text/plain\r"
echo -e "\r"

echo "# Basic POD Informations"
echo -e "\n## Env"
env

echo -e "\n## ip link"
ip link

echo -e "\n## request"
read request
echo $request