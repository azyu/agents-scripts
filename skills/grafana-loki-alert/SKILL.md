---
name: grafana-loki-alert
description: >-
  Grafana alert rule writing guide for Loki datasource in LXP Services.
  Use when creating or modifying Grafana provisioned alert rules with Loki queries.
  Triggers on: "alert rule", "grafana alert", "loki alert", "error spike",
  "grafana-config-providers.yaml", "alerting provisioning".
---

# Grafana Loki Alert Rule Guide

LXP Services alert rule provisioning file:
`ops/k8s/clusters/lxp-servce-dev/overlays/observation/grafana/grafana-config-providers.yaml`

## Required Pipeline

Loki query results MUST pass through `reduce` before math/threshold expressions.

```
Loki Query(A) ──┐
                 ├→ Reduce(C) ──┐
Loki Query(B) ──┘               ├→ Math(E) → Threshold(F)
                 ├→ Reduce(D) ──┘
```

**condition** must reference the final threshold refId (e.g., `F`).

## Alert Rule Template

```yaml
rules:
  - uid: <unique-id>
    title: <Title>
    condition: F          # Must match threshold refId
    for: 5m
    noDataState: OK
    execErrState: Error
    annotations:
      summary: >-
        {{ $labels.service_name }} <summary>
        ({{ $values.E.Value | printf "%.1f" }}x)
      description: >-
        <description>
        현재: {{ $values.C.Value | printf "%.0f" }}건
        / 기준: {{ $values.D.Value | printf "%.1f" }}건
    labels:
      severity: warning
      team: lxp
      source: loki
    data:
      # A: Loki query (current window)
      - refId: A
        queryType: instant
        relativeTimeRange:
          from: 3600      # seconds
          to: 0
        datasourceUid: loki-dev
        model:
          expr: >-
            sum by(service_name)(count_over_time(
            {k8s_namespace_name="lxp-dev", level="error", service_name=~".+"}[1h]))
          instant: true
          refId: A
      # B: Loki query (baseline window)
      - refId: B
        queryType: instant
        relativeTimeRange:
          from: 3600
          to: 0
        datasourceUid: loki-dev
        model:
          expr: >-
            sum by(service_name)(count_over_time(
            {k8s_namespace_name="lxp-dev", level="error", service_name=~".+"}[168h])) / 168
          instant: true
          refId: B
      # C: Reduce A → single value per label set
      - refId: C
        relativeTimeRange: { from: 0, to: 0 }
        datasourceUid: "-100"
        model:
          type: reduce
          expression: A
          reducer: last
          refId: C
      # D: Reduce B → single value per label set
      - refId: D
        relativeTimeRange: { from: 0, to: 0 }
        datasourceUid: "-100"
        model:
          type: reduce
          expression: B
          reducer: last
          refId: D
      # E: Math expression
      - refId: E
        relativeTimeRange: { from: 0, to: 0 }
        datasourceUid: "-100"
        model:
          type: math
          expression: "$C / ($D + 1)"
          refId: E
      # F: Threshold (alert fires when true)
      - refId: F
        relativeTimeRange: { from: 0, to: 0 }
        datasourceUid: "-100"
        model:
          type: threshold
          expression: E
          conditions:
            - evaluator:
                type: gt
                params:
                  - 2.0
              operator:
                type: and
              query:
                params:
                  - E
              reducer:
                type: last
          refId: F
```

## Checklist

| # | Rule | Why |
|---|------|-----|
| 1 | **`sum by(label)` 사용 시 `label=~".+"` 필터 추가** | 라벨 없는 로그가 빈 `{}` 그룹 생성 → "duplicate results with labels {}" |
| 2 | **Loki 쿼리 뒤 반드시 `reduce` expression 추가** | Grafana가 instant vector를 time series frame으로 해석 → "looks like time series data" |
| 3 | **annotations에서 `$labels`/`$values` 그대로 사용** | provisioning YAML은 env var 치환 대상 아님, `$$` 이스케이프 불필요 |
| 4 | **`condition` 값 = threshold refId** | math가 아닌 최종 threshold의 refId를 지정 |
| 5 | **annotation `$values` 참조는 reduce/math refId 사용** | Loki query refId(A,B)가 아닌 reduce refId(C,D) 참조해야 값 접근 가능 |
| 6 | **ConfigMap 변경 후 Pod rollout restart 필수** | Grafana provisioned alert rule은 시작 시에만 로드됨 |

## Annotation Template Variables

| Variable | Source | Example |
|----------|--------|---------|
| `$labels.service_name` | Loki 쿼리의 `by` 절 라벨 | `auth` |
| `$values.<refId>.Value` | 해당 expression의 계산 결과 | `3.8` |

## Deployment

```bash
# 1. Commit & push & PR merge
# 2. ArgoCD sync 확인
kubectl get app mon-grafana -n argocd -o jsonpath='{.status.sync.status}'
# 3. Pod restart (필수)
kubectl rollout restart deployment/grafana -n monitoring
kubectl rollout status deployment/grafana -n monitoring
# 4. 에러 확인
kubectl logs deployment/grafana -n monitoring | grep "Error in expanding template"
```
