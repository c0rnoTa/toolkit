#!/usr/bin/env bash

[[ $# -ne 4 ]] && echo 'Error! You must to define four params' && exit 1

TOKEN="$1"
CHAT_ID="$2"
SUBJECT="$3"
MESSAGE="$4"

curl -s  --header 'Content-Type: application/json' --request 'POST' --data "{\"chat_id\":\"${CHAT_ID}\",\"text\":\"${SUBJECT}\n${MESSAGE}\"}" "https://api.telegram.org/bot${TOKEN}/sendMessage" | grep -q '"ok":false,'

if [ $? -eq 0 ] ; then exit 1 ; fi
