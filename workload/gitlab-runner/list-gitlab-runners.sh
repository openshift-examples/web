#!/usr/bin/env bash


curl -s --header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" "https://gitlab.com/api/v4/runners" | jq -r  ' .[] | [.id, .name, .description, .ip_address, .status ]|@tsv'
