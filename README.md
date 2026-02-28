# agents-scripts

AI 코딩 에이전트를 위한 agents & skills 컬렉션. Claude Code, OpenCode, Cursor 등에서 사용.

## 구조

```
AGENTS.md               # 에이전트 진입점 — rules/ 참조
rules/                   # 공통 가이드라인 (모든 에이전트 적용)
├── karpathy-guidelines.md
├── custom-guidelines.md
└── tools.md
agents/                  # 서브에이전트 정의 (11개)
skills/                  # 스킬 패키지 (11개)
├── agents-md-creator/
├── frontend-design/
├── last30days/
├── plugins-creator/
├── security-review/
├── skill-creator/
├── tdd-workflow/
├── backend-patterns.md
├── clickhouse-io.md
├── coding-standards.md
└── frontend-patterns.md
```

## Rules

`AGENTS.md`가 참조하는 공통 가이드라인. 모든 AI 에이전트에 적용.

| Rule | 설명 |
|------|------|
| `karpathy-guidelines` | 가정 표면화, 최소 코드, 수술적 변경, 목표 기반 실행 |
| `custom-guidelines` | 서브에이전트 병렬 실행, 버그 수정 시 TDD (RED→GREEN) |
| `tools` | gh CLI, tmux 등 도구 사용 가이드 |

## Agents

특정 역할에 특화된 서브에이전트. 메인 에이전트가 작업을 위임할 때 사용.

| Agent | 역할 |
|-------|------|
| `architect` | 시스템 설계, 확장성, 기술 의사결정 |
| `planner` | 복잡한 기능/리팩토링 계획 수립 |
| `code-reviewer` | 코드 품질, 보안, 유지보수성 리뷰 |
| `code-simplifier` | 코드 간소화 및 가독성 개선 |
| `build-error-resolver` | 빌드/타입 에러 해결 (최소 diff) |
| `tdd-guide` | TDD 워크플로우 (테스트 먼저, 80%+ 커버리지) |
| `e2e-runner` | Playwright E2E 테스트 생성/실행 |
| `security-reviewer` | 보안 취약점 탐지 (OWASP Top 10) |
| `database-reviewer` | PostgreSQL 쿼리 최적화, 스키마 설계 |
| `refactor-cleaner` | 데드 코드 제거, 중복 통합 |
| `doc-updater` | 문서/코드맵 자동 업데이트 |

## Skills

에이전트에 로드하여 전문 지식을 부여하는 스킬 패키지.

| Skill | 타입 | 설명 |
|-------|------|------|
| `agents-md-creator` | 디렉토리 | AGENTS.md 생성/업데이트 — 10+ 탑 레포 분석 기반 |
| `frontend-design` | 디렉토리 | 프로덕션급 프론트엔드 UI 생성 |
| `last30days` | 디렉토리 | 최근 30일 Reddit+X+Web 리서치 → 프롬프트 생성 |
| `plugins-creator` | 디렉토리 | Claude Code 플러그인 생성 가이드 |
| `security-review` | 디렉토리 | 인증, 입력 처리, 시크릿, API 보안 체크리스트 |
| `skill-creator` | 디렉토리 | 새 스킬 생성/패키징 가이드 |
| `tdd-workflow` | 디렉토리 | TDD 워크플로우 (Jest/Vitest/Playwright 패턴) |
| `coding-standards` | 단일 파일 | TypeScript/JavaScript/React/Node.js 코딩 표준 |
| `frontend-patterns` | 단일 파일 | React, Next.js, 상태 관리, 성능 최적화 패턴 |
| `backend-patterns` | 단일 파일 | Node.js/Express/Next.js API 설계, DB 최적화 |
| `clickhouse-io` | 단일 파일 | ClickHouse 쿼리 최적화, 분석 데이터 엔지니어링 |

## 사용법

### 스킬 로드 (OpenCode / Claude Code)

```bash
npx openskills read agents-md-creator
npx openskills read skill-one,skill-two
```

### 다른 머신에 동기화

```bash
git clone git@github.com:azyu/agents-scripts.git ~/.agents
```
