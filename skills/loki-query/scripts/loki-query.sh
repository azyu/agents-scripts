#!/usr/bin/env bash
# Usage: loki-query.sh <logql-query> [minutes-back] [limit]
# Example: loki-query.sh '{service_name="bff-se-web", level="error"}' 30 100

set -euo pipefail

QUERY="${1:?Usage: loki-query.sh '<logql-query>' [minutes_back] [limit]}"
MINUTES_BACK="${2:-10}"
LIMIT="${3:-50}"
PROFILE="204620195120-azyu"
LOKI_ENDPOINT="http://loki-read.monitoring.svc.cluster.local:3100/loki/api/v1/query_range"
TENANT_ID="dev"

END=$(date -u +%s)000000000
START=$(( $(date -u +%s) - MINUTES_BACK * 60 ))000000000
POD_NAME="loki-q-$(date +%s)"

aws-vault exec "$PROFILE" -- kubectl run "$POD_NAME" --rm -i --restart=Never \
  --image=curlimages/curl:8.12.1 -n monitoring -- sh -c "\
  curl -s -H 'X-Scope-OrgID: $TENANT_ID' \
  '$LOKI_ENDPOINT' \
  --data-urlencode 'query=$QUERY' \
  --data-urlencode 'start=$START' \
  --data-urlencode 'end=$END' \
  --data-urlencode 'limit=$LIMIT'" 2>&1 | grep -v "^If you\|^pod "
