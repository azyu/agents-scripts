---
name: k8s-ops
description: EKS/Kubernetes 운영 스킬. Use when checking pod status, deployments, rollouts, HPA, ArgoCD sync, ConfigMaps, or any kubectl/k8s operation. Triggers on - "pod 상태", "배포 확인", "rollout", "HPA", "ArgoCD", "kubectl", "EKS", "k8s", "쿠버네티스", "파드", "디플로이먼트".
---

# k8s-ops

EKS 클러스터 운영 스킬. lxp-services (NestJS monorepo) on AWS EKS.

## 1. 인증 & 컨텍스트

```bash
# aws-vault 인증
aws-vault exec <profile> -- kubectl get pods

# 현재 context 확인 (항상 먼저 실행)
kubectl config current-context
kubectl config get-contexts

# context 전환
kubectl config use-context <context-name>

# EKS kubeconfig 업데이트
aws-vault exec <profile> -- aws eks update-kubeconfig --name <cluster-name> --region ap-northeast-2
```

**규칙**: 모든 작업 전 context 확인 필수. 잘못된 클러스터 조작 방지.

## 2. 상태 확인 패턴

### Pod

```bash
kubectl get pods -n <namespace> -l app=<service>
kubectl get pods -n <namespace> -o wide
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --tail=100
kubectl logs <pod-name> -n <namespace> --previous  # 이전 컨테이너 로그
kubectl top pod -n <namespace>                      # 리소스 사용량
```

### Deployment

```bash
kubectl get deploy -n <namespace>
kubectl rollout status deploy/<name> -n <namespace>
kubectl rollout history deploy/<name> -n <namespace>
kubectl rollout restart deploy/<name> -n <namespace>
kubectl rollout undo deploy/<name> -n <namespace>           # 롤백
kubectl rollout undo deploy/<name> --to-revision=<N> -n <namespace>
```

### HPA

```bash
kubectl get hpa -n <namespace>
kubectl describe hpa <name> -n <namespace>
kubectl top pods -n <namespace> -l app=<service>  # 실제 사용량 vs HPA 설정 비교
```

### Service & Ingress

```bash
kubectl get svc -n <namespace>
kubectl get ingress -n <namespace>
kubectl describe ingress <name> -n <namespace>
```

## 3. ArgoCD 패턴

```bash
# 앱 상태 확인
argocd app get <app-name>
argocd app list

# Sync
argocd app sync <app-name>
argocd app sync <app-name> --force    # 강제 sync
argocd app sync <app-name> --prune    # 불필요 리소스 정리

# 히스토리 & 롤백
argocd app history <app-name>
argocd app rollback <app-name> <history-id>

# Diff 확인
argocd app diff <app-name>

# Hard refresh (캐시 무효화)
argocd app get <app-name> --hard-refresh
```

## 4. 트러블슈팅 체크리스트

### CrashLoopBackOff

1. `kubectl logs <pod> -n <ns> --previous` - 에러 로그 확인
2. OOM 여부: `kubectl describe pod` -> Last State -> OOMKilled
3. resource limits 확인 -> 메모리 부족이면 limits 조정
4. env vars 누락 확인 -> ConfigMap/Secret 마운트 상태

### ImagePullBackOff

1. ECR 인증: `aws ecr get-login-password` 만료 여부
2. image tag 존재 여부: `aws ecr describe-images --repository-name <repo>`
3. repository 존재 여부 확인
4. imagePullSecrets 설정 확인

### Pending

1. `kubectl describe pod` -> Events 섹션
2. resource quota: `kubectl describe resourcequota -n <ns>`
3. node capacity: `kubectl describe nodes | grep -A5 Allocatable`
4. nodeSelector / affinity / tolerations 확인

### ArgoCD OutOfSync

1. `argocd app diff <app-name>` - manifest 차이 확인
2. 수동 변경 여부 확인 (kubectl edit 등으로 직접 수정된 경우)
3. `argocd app sync <app-name>` - 재동기화
4. `argocd app get <app-name> --hard-refresh` - 캐시 문제 시

### OOMKilled

1. `kubectl describe pod` -> containers.lastState.terminated.reason
2. 현재 limits: `kubectl get deploy <name> -o jsonpath='{.spec.template.spec.containers[0].resources}'`
3. 실제 사용량: `kubectl top pod <pod> -n <ns>`
4. limits 조정 또는 애플리케이션 메모리 최적화

## 5. ConfigMap / Secret 관리

```bash
# 조회
kubectl get configmap -n <namespace>
kubectl get secret -n <namespace>
kubectl get configmap <name> -n <namespace> -o yaml
kubectl get secret <name> -n <namespace> -o jsonpath='{.data.<key>}' | base64 -d

# 생성
kubectl create configmap <name> --from-file=<path> -n <namespace>
kubectl create configmap <name> --from-literal=KEY=VALUE -n <namespace>
kubectl create secret generic <name> --from-literal=KEY=VALUE -n <namespace>

# 수정 후 반영 (Pod restart 필요할 수 있음)
kubectl rollout restart deploy/<name> -n <namespace>
```

## 6. 유용한 조합

```bash
# 전체 namespace 리소스 요약
kubectl get all -n <namespace>

# 특정 서비스 전체 상태 한눈에
kubectl get deploy,pods,svc,hpa,ingress -n <namespace> -l app=<service>

# 이벤트 (최근 문제 파악)
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20

# Node 상태
kubectl get nodes -o wide
kubectl top nodes
```

## 7. 주의사항

- **namespace 항상 명시** (`-n` flag). 생략 시 default namespace 조작 위험
- **삭제 전 dry-run 필수**: `kubectl delete <resource> --dry-run=client -o yaml`
- **rollout restart 전** 현재 replica 수, HPA 상태 확인
- **프로덕션**: 변경 전 반드시 현재 상태 스냅샷 (`kubectl get -o yaml > backup.yaml`)
- **ArgoCD 관리 리소스**: kubectl로 직접 수정 금지 -> Git 통해 변경 -> ArgoCD sync
- **Secret**: 로그/출력에 노출 주의. `-o yaml`로 조회 시 base64 인코딩 상태
