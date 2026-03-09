---
name: loki-query
description: Query Loki logs on EKS for LXP Services. Use when user wants to search logs, check errors, query Loki, investigate incidents, or view service logs. Triggers on keywords like "loki", "log query", "log search", "grafana logs", "check logs", "view logs", "search logs", "error logs", "로그 조회", "로그 확인", "로그 검색".
---

# Loki Log Query

Query Loki logs from the LXP Services EKS cluster via ephemeral kubectl pods.

## Quick Reference

| Item | Value |
|------|-------|
| Loki Read Endpoint | `loki-read.monitoring.svc.cluster.local:3100` |
| Tenant ID Header | `X-Scope-OrgID: dev` |
| AWS Vault Profile | `204620195120-azyu` |
| EKS Cluster | `lxp-services-dev` |
| App Namespace | `lxp-dev` |

### Available Labels (only these 5)

| Label | Example Values |
|-------|---------------|
| `k8s_container_name` | container name |
| `k8s_namespace_name` | `lxp-dev` |
| `k8s_pod_name` | pod name |
| `level` | `info`, `warn`, `error`, `debug` |
| `service_name` | `bff-se-web`, `lms`, `lcms`, `auth`, etc. |

### Services (24 total)

**Backend (16):** lms, lcms, lrs, lrs-kafka-consumer, lr-spec, auth, user, audit, announcement, activity, activity-group, learning-trace, rec-sys, tb-se, widget-cs, widget-dailylesson

**BFF (8):** bff-ac, bff-ac-cms, bff-ac-lrm, bff-rtc, bff-se-app, bff-se-portal, bff-se-web, bff-tdea

## Helper Scripts

### Query logs

```bash
# Basic usage: query + minutes_back + limit
~/.claude/skills/loki-query/scripts/loki-query.sh '{service_name="bff-se-web", level="error"}' 30 100

# Pipe to parser for readable output
~/.claude/skills/loki-query/scripts/loki-query.sh '{service_name="lms", level="error"} |~ "timeout"' 60 200 \
  | python3 ~/.claude/skills/loki-query/scripts/loki-parse.py

# Count by level
~/.claude/skills/loki-query/scripts/loki-query.sh '{service_name="auth"}' 60 500 \
  | python3 ~/.claude/skills/loki-query/scripts/loki-parse.py --count

# Full JSON output
~/.claude/skills/loki-query/scripts/loki-query.sh '{service_name="lms"}' 10 20 \
  | python3 ~/.claude/skills/loki-query/scripts/loki-parse.py --json
```

## LogQL Examples

```logql
# Service errors
{service_name="bff-se-web", level="error"}

# Multi-level filter
{service_name="lms", level=~"error|warn"}

# Text search (regex)
{service_name="lms"} |~ "Failed to|timeout|UNAVAILABLE"

# Exclude health checks
{service_name="auth", level="error"} != "health"

# JSON field extraction
{service_name="lcms"} | json | context="LcmsClientService"

# Combined: errors excluding noise, with text search
{k8s_namespace_name="lxp-dev", service_name="lms", level=~"error|warn"} != "health" |~ "gRPC"
```

## Loki API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/loki/api/v1/query_range` | Range queries (start/end time) |
| `/loki/api/v1/query` | Instant queries |
| `/loki/api/v1/labels` | List available labels |
| `/loki/api/v1/label/{name}/values` | List values for a label |

### Discover labels/values (useful for debugging empty results)

```bash
~/.claude/skills/loki-query/scripts/loki-query.sh '' 1 1  # (won't work directly)
# Instead, use a raw kubectl command for label discovery:
aws-vault exec 204620195120-azyu -- kubectl run loki-labels-$(date +%s) --rm -i --restart=Never \
  --image=curlimages/curl:8.12.1 -n monitoring -- \
  curl -s -H 'X-Scope-OrgID: dev' \
  'http://loki-read.monitoring.svc.cluster.local:3100/loki/api/v1/labels'
```

## Log Pipeline

```
App (ServiceLogger/Winston) -> JSON stdout -> filelog receiver (json_parser) -> OTel Collector -> otlphttp/loki -> Loki
```

The `level` label comes from OTel Collector's `transform/log_level` processor: copies `severity_text` to resource attribute `level`. Severity is parsed from the JSON `level` field by filelog receiver's json_parser.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Empty `"result":[]` | Wrong label names | Check labels via `/loki/api/v1/labels` |
| `no org id` error | Missing tenant header | Add `-H 'X-Scope-OrgID: dev'` |
| Variables not expanded | curl args not in sh -c | Wrap curl in `sh -c "..."` |
| JSON parse error in python | kubectl metadata in output | Filter with `grep -v "^If you\|^pod "` |
| `level` label missing/wrong | OTel pipeline issue | Check json_parser and transform/log_level processor |
