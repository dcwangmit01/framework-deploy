#!/bin/bash
set -euo pipefail

kubectl get secret grafana -o go-template='{{ index .data "admin-password" | base64decode }}'
printf "\n"
