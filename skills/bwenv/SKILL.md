---
name: bwenv
description: Manage .env secrets with Bitwarden. Use when user wants to save, load, export, list, diff, or delete environment variables from Bitwarden vault. Triggers on keywords like "bwenv", ".env", "bitwarden", "secrets", "환경변수", "시크릿".
---

# bwenv — Bitwarden .env Secret Manager

Bitwarden vault를 통해 .env 시크릿을 관리하는 CLI 도구.

## Quick Reference

| Item | Value |
|------|-------|
| CLI Path | `~/.local/bin/bwenv` |
| Dependencies | `bw` (bitwarden-cli), `jq` |
| Storage | Bitwarden "bwenv" 폴더 내 Secure Note |
| Install deps | `brew install bitwarden-cli jq` |

## BW_SESSION Handling

Vault unlock이 필요한 경우:
- **터미널**: `bwenv`가 자동으로 `bw unlock` 호출 (인터랙티브 마스터 패스워드 입력)
- **Bash 도구**: 인터랙티브 입력 불가. 사용자에게 터미널에서 직접 실행하도록 안내:

```bash
# 터미널에서 먼저 실행
export BW_SESSION=$(bw unlock --raw)
```

## Command Reference

### save — .env를 Bitwarden에 저장

```bash
bwenv save <name> [path]    # default path: ./.env
```

- 동일 이름 존재 시 업데이트, 없으면 신규 생성
- 저장 후 자동 sync

### load — 환경변수를 셸에 export

```bash
source <(bwenv load <name>)
```

- `export KEY=VALUE` 형태로 출력
- 주석(`#`)과 빈 줄 스킵
- `source` 없이 실행하면 export 구문만 출력 (적용 안됨)

### export — .env 원본 내용 출력

```bash
bwenv export <name> > .env
```

- Bitwarden에 저장된 원본 그대로 stdout 출력
- 파일 리다이렉트로 .env 복원

### list — 저장된 시크릿 목록

```bash
bwenv list
```

- bwenv 폴더 내 모든 Secure Note 표시
- 이름, 수정일 포함

### diff — 로컬 vs Bitwarden 비교

```bash
bwenv diff <name> [path]    # default path: ./.env
```

- `diff` 출력: `< Bitwarden`, `> local`
- 차이 없으면 "No differences" 표시

### delete — Bitwarden에서 삭제

```bash
bwenv delete <name>
```

- 삭제 후 자동 sync

## Scenario Guide

### 프로젝트 .env 백업

```bash
cd /path/to/project
bwenv save my-project        # ./.env 저장
bwenv save my-project .env.production  # 특정 파일 저장
```

### 새 환경에서 .env 복원

```bash
cd /path/to/project
bwenv export my-project > .env
```

### 셸에 환경변수 로드 (파일 생성 없이)

```bash
source <(bwenv load my-project)
```

### 로컬 변경 확인 후 업데이트

```bash
bwenv diff my-project        # 차이 확인
bwenv save my-project        # 변경사항 반영
```

## Important Notes

- Bash 도구에서 `bwenv` 실행 시 vault가 잠겨있으면 실패함. 사용자에게 터미널에서 `BW_SESSION` export 후 재시도 안내
- `bwenv load`는 반드시 `source <(...)` 형태로 실행해야 환경변수가 현재 셸에 적용됨
- 모든 항목은 Bitwarden "bwenv" 폴더에 Secure Note 타입으로 저장
