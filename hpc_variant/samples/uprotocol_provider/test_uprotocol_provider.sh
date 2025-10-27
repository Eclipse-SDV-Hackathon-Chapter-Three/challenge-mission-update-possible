#!/bin/bash

export SYMPHONY_API_URL=http://localhost:8082/v1alpha2/

TOKEN=$(curl -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":""}' "${SYMPHONY_API_URL}users/auth" | jq -r '.accessToken')

curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./target.json "${SYMPHONY_API_URL}targets/registry/ecu-updater-target"

# Prompt user to press Enter to continue after the target has been registered
read -p "Target registered. Press Enter to remove..."

curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}targets/registry/ecu-updater-target"
