# tmux CLI Worker Orchestration

Claude Code(Opus 4.6)가 오케스트레이터로서 Codex CLI(GPT-5.3)와 Gemini CLI(Gemini 3.1 Pro)에 작업을 위임하는 멀티모델 병렬 실행 시스템.

## 사전 요건

```bash
# 필수
brew install jq tmux        # 또는 이미 설치되어 있다면 생략
npm i -g @openai/codex      # Codex CLI
npm i -g @google/gemini-cli # Gemini CLI

# symlink 설치
~/.agents/install.sh
```

## 빠른 시작

### 1. tasks.json 작성

```json
[
  {
    "id": 1,
    "subject": "Auth API 구현",
    "description": "JWT 기반 인증 API를 /api/auth에 구현해줘.\n\n경로: /home/user/myapp\n스택: Next.js 15, Prisma, PostgreSQL\n\n- POST /api/auth/login\n- POST /api/auth/register\n- GET /api/auth/me\n\nbcrypt로 비밀번호 해싱, JWT 토큰 15분 만료.",
    "worker_type": "codex",
    "model": "gpt-5.3-codex"
  },
  {
    "id": 2,
    "subject": "로그인 페이지 UI",
    "description": "로그인/회원가입 페이지를 만들어줘.\n\n경로: /home/user/myapp\n스택: Next.js 15, Tailwind CSS, shadcn/ui\n\n- src/app/login/page.tsx\n- src/app/register/page.tsx\n- 이메일 + 비밀번호 폼\n- API: POST /api/auth/login, POST /api/auth/register",
    "worker_type": "gemini",
    "model": "gemini-3.1-pro"
  }
]
```

### 2. 실행

```bash
# 워커 스폰
~/.agents/scripts/orchestrate-start.sh \
  --team auth-feature \
  --tasks tasks.json \
  --cwd "$(pwd)"

# 상태 확인 (완료까지 반복)
~/.agents/scripts/orchestrate-status.sh --team auth-feature --json

# 결과 수집 + 정리
~/.agents/scripts/orchestrate-collect.sh --team auth-feature --json
```

### 3. tmux에서 실시간 확인

```bash
tmux attach -t orc-auth-feature
# Ctrl+B, D 로 detach
```

## 워커 라우팅 규칙

| 도메인 | 워커 | 모델 |
|--------|------|------|
| 아키텍처, 백엔드, 시스템, DevOps, DB | Codex CLI | gpt-5.3-codex |
| 프론트엔드, UI/UX, CSS, React, 디자인 | Gemini CLI | gemini-3.1-pro |
| 리서치, 분석, 범용 | 둘 다 가능 (Codex 우선) | — |

## 스크립트 레퍼런스

### orchestrate-start.sh

팀을 생성하고 tmux 워커를 스폰한다.

```
orchestrate-start.sh --team <name> --tasks <tasks.json> [--cwd <dir>]
```

| 인자 | 필수 | 설명 |
|------|------|------|
| `--team` | O | 팀 이름 (tmux 세션: `orc-<name>`) |
| `--tasks` | O | tasks.json 경로 |
| `--cwd` | X | 워커 작업 디렉토리 (기본: 현재 디렉토리) |

**tasks.json 스키마:**

```json
[
  {
    "id": 1,
    "subject": "짧은 제목",
    "description": "워커에게 전달할 전체 지시사항",
    "worker_type": "codex | gemini",
    "model": "모델명 (선택)"
  }
]
```

**출력:** 메타데이터 JSON (team, tmux_session, workers 목록)

### orchestrate-status.sh

워커 상태를 확인한다.

```
orchestrate-status.sh --team <name> [--json]
```

**3단계 생존 확인:**
1. `done.json` 존재 → completed / failed
2. `pid` 파일 → `kill -0` 프로세스 확인 → running / crashed
3. PID 파일 없음 → unknown

**출력 (--json):**

```json
{
  "team": "auth-feature",
  "total": 2,
  "completed": 1,
  "running": 1,
  "failed": 0,
  "crashed": 0,
  "all_done": false,
  "workers": [
    {"name": "codex-1", "status": "completed", "exit_code": 0, "duration_seconds": 45},
    {"name": "gemini-2", "status": "running"}
  ]
}
```

### orchestrate-collect.sh

결과를 수집하고 tmux 세션을 정리한다.

```
orchestrate-collect.sh --team <name> [--keep-session] [--json]
```

| 인자 | 설명 |
|------|------|
| `--keep-session` | tmux 세션을 유지 (디버깅용) |
| `--json` | JSON 형식 출력 |

**출력 (--json):**

```json
{
  "team": "auth-feature",
  "total": 2,
  "succeeded": 2,
  "failed": 0,
  "results": [
    {
      "name": "codex-1",
      "status": "completed",
      "exit_code": 0,
      "output": "워커 응답 텍스트...",
      "duration_seconds": 45,
      "completed_at": "2026-02-28T10:30:00Z"
    }
  ]
}
```

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `ORC_TIMEOUT` | `300` | 워커 타임아웃 (초) |
| `ORC_BASE_DIR` | `.` (cwd) | `.orc/` 상태 디렉토리 기준 경로 |
| `ORC_CODEX_BIN` | `codex` | Codex 바이너리 경로 (테스트용) |
| `ORC_GEMINI_BIN` | `gemini` | Gemini 바이너리 경로 (테스트용) |

## 런타임 상태 구조

프로젝트 cwd에 `.orc/` 디렉토리가 자동 생성된다. `.gitignore`가 자동으로 추가되어 git에서 무시된다.

```
<project>/.orc/
  .gitignore                    # 내용: *
  teams/<team-name>/
    config.json                 # 팀 메타데이터
    tasks/{1,2,...}.json        # 태스크 정의
    workers/<type>-<id>/
      inbox.md                  # 워커에게 전달된 지시사항
      done.json                 # 완료 신호 + 출력
      raw.jsonl / raw.json      # CLI 원본 출력
      pid                       # 워커 프로세스 PID
```

## 좋은 inbox.md 작성법

워커는 대화 컨텍스트에 접근할 수 없다. inbox.md가 워커가 받는 유일한 정보이므로 완전히 자기 완결적이어야 한다.

```markdown
# Task: 사용자 인증 API

## 컨텍스트
- 프로젝트: /home/user/myapp (Next.js 15)
- 스택: TypeScript, Prisma, PostgreSQL
- 관련 파일: src/lib/db.ts, prisma/schema.prisma

## 현재 상태
User 모델이 이미 schema.prisma에 정의됨 (email, passwordHash 필드)

## 필요한 변경
1. src/app/api/auth/login/route.ts — POST 엔드포인트
2. src/app/api/auth/register/route.ts — POST 엔드포인트
3. src/lib/auth.ts — JWT 생성/검증 유틸리티

## 제약사항
- bcrypt로 비밀번호 해싱
- JWT 만료: 15분 (access), 7일 (refresh)
- 기존 API 패턴 (src/app/api/ 참조) 준수

## 기대 출력
완성된 코드 파일들
```

## 에러 대응

| 상황 | 원인 | 해결 |
|------|------|------|
| `Required command not found: codex` | CLI 미설치 | `npm i -g @openai/codex` |
| `Team already exists` | 동일 팀명 충돌 | 다른 이름 사용 또는 `tmux kill-session -t orc-<name>` |
| 워커 timeout (300s) | 태스크가 너무 복잡 | `ORC_TIMEOUT=600` 으로 증가 후 재시도 |
| 워커 crashed | CLI 오류 또는 인증 문제 | `done.json`, `raw.jsonl` 확인 후 지시사항 수정 |
| `still running` (collect 실패) | 워커 미완료 | `orchestrate-status.sh`로 확인 후 대기 |

## Claude Code 스킬로 사용

대화 중 `/orchestrate`를 호출하면 Claude가 자동으로:
1. 사용자 요청을 독립적 서브태스크로 분해
2. 라우팅 규칙에 따라 tasks.json 생성
3. `orchestrate-start.sh`로 워커 스폰
4. `orchestrate-status.sh`로 폴링
5. `orchestrate-collect.sh`로 결과 수집
6. 모든 워커 출력을 종합하여 보고

## 테스트

```bash
cd ~/.agents

# 단위 테스트 (stub CLI 사용, 실제 CLI 불필요)
scripts/tests/test-worker.sh     # codex/gemini 파싱, 빈 inbox, PID 기록
scripts/tests/test-timeout.sh    # 3초 타임아웃 동작
scripts/tests/test-crash.sh      # 크래시 복구 (EXIT trap)

# shellcheck
shellcheck -e SC1091 scripts/orchestrate-*.sh
```

## Codex CLI 모델 옵션

| 모델 | 용도 |
|------|------|
| `gpt-5.3-codex` | 기본 — 최고 성능 에이전틱 코딩 |
| `gpt-5.3-codex-spark` | 텍스트 전용 리서치 |
| `gpt-5.2-codex` | 복잡한 실제 엔지니어링 |
| `gpt-5.1-codex-max` | 장기 에이전틱 세션 |

## Gemini CLI 모델 옵션

| 모델 | 용도 |
|------|------|
| Auto (기본) | Gemini 2.5 Flash + 3 Pro 자동 라우팅 |
| `gemini-3-pro` | 범용 |
| `gemini-3-flash` | 빠른 경량 작업 |
| `gemini-3.1-pro-preview` | 최신 프리뷰 |
