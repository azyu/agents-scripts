---
name: bwssh
description: Manage SSH keys with Bitwarden. Use when user wants to backup, restore, list, diff, or delete SSH keys from Bitwarden vault. Triggers on keywords like "bwssh", "ssh key", "ssh backup", "ssh restore", "SSH 키", "SSH 백업".
---

# bwssh — Bitwarden SSH Key Manager

Bitwarden vault를 통해 SSH 키를 프로필 단위로 백업/복원하는 CLI 도구.

## Quick Reference

| Item | Value |
|------|-------|
| CLI Path | `~/.local/bin/bwssh` |
| Dependencies | `bw` (bitwarden-cli), `jq`, `ssh-keygen` |
| Storage | Bitwarden "bwssh" 폴더 |
| Key files | SSH Key 타입 (type 5) |
| Non-key files | Secure Note 타입 (type 2) |
| Naming | `bwssh/<profile>/<relative-path>` |
| Auto-skip | `known_hosts`, `.DS_Store`, `authorized_keys` |

## BW_SESSION Handling

bwenv와 동일. Bash 도구에서 vault 잠겨있으면:

```bash
export BW_SESSION=$(bw unlock --raw)
```

## Command Reference

### save — SSH 키 백업

```bash
bwssh save <profile> [ssh_path]    # default: ~/.ssh
```

- Private key → SSH Key 타입 (pub key 자동 쌍으로 저장)
- config 등 → Secure Note 타입
- pub 파일 없으면 `ssh-keygen -y -f`로 자동 추출
- 동일 이름 존재 시 업데이트

### list — 프로필 목록

```bash
bwssh list
```

### show — 프로필 내 파일 목록

```bash
bwssh show <profile>
```

### export — SSH 키 복원

```bash
bwssh export <profile> [target_path]    # default: ~/.ssh
```

- 파일 권한 자동 설정 (private: 600, pub: 644, config: 644)
- 하위 디렉토리 자동 생성

### diff — 로컬 vs Bitwarden 비교

```bash
bwssh diff <profile> [ssh_path]
```

### delete — 프로필 삭제

```bash
bwssh delete <profile>
```

## Scenario Guide

### 현재 머신 SSH 키 백업

```bash
bwssh save macstudio
```

### 새 머신에서 SSH 키 복원

```bash
bwssh export macstudio ~/.ssh
```

### 변경 확인 후 업데이트

```bash
bwssh diff macstudio
bwssh save macstudio
```

## Important Notes

- Bash 도구에서 vault 잠겨있으면 실패. 터미널에서 `BW_SESSION` export 후 재시도 안내
- `known_hosts`는 머신마다 다르므로 기본 제외
- 기존 `bw-ssh-auto-backup` (🖥️ MacStudio 폴더)과는 독립 운영
