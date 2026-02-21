---
name: context-manager
description: Automatically discovers and loads relevant project context from markdown documentation before each task. This skill should be used at the start of every task to ensure Claude has access to project plans, architecture, implementation status, and feedback. It intelligently matches context documents based on keywords, file paths, and task types, then loads relevant documentation to inform the current work.
---

# Context Manager

## Overview

Automatically manage project context documentation stored in `.context/` directories (hidden for cleaner project structure). This skill ensures Claude always has access to relevant project information by:

1. **Auto-discovering** context documents before starting work
2. **Intelligently matching** documentation to the current task
3. **Loading** relevant context into the conversation
4. **Updating** or creating documentation based on work completed

**Core Goal: Reducing Implicit Knowledge (암묵지 감소)**
The primary purpose of this skill is to capture and share knowledge that isn't explicitly visible in the code, such as design intent, background decisions, and implementation plans.

## When to Use

This skill should be activated **at the start of every task** to ensure proper context awareness. It is especially critical when:

- Starting work on any codebase with a `.context/` directory
- Implementing features or fixing bugs that may have been planned or documented
- Working on projects with established architecture or design decisions
- Contributing to teams that maintain project documentation

## Workflow

### Step 0: Reference Global Policy

Before interacting with project-specific context, ensure you are familiar with the **Global Context Management Standard** located at `~/.agents/CONTEXT.md`. This document defines the expected structure and agent behavior for all projects.

### Step 1: Check for Context Directory

First, verify if a `.context/` directory exists in the current working directory or project root:

```bash
# Check current directory
ls -la .context/ 2>/dev/null

# Check common project roots
ls -la ./.context/ ../.context/ ../../.context/ 2>/dev/null
```

**If no context directory exists:**
- Ask the user if they want to initialize a context structure
- Suggest common categories based on project type (see references/context_patterns.md)
- Create initial structure if requested

**If context directory exists:**
- Proceed to Step 2

### Step 2: Discover Relevant Context

Use `scripts/find_context.py` to identify relevant documentation based on:

**Task-based matching:**
- User's request keywords (e.g., "monitoring" → `.context/monitoring/`)
- Mentioned file paths (e.g., working in `agent/` code → `.context/agents/`)
- Task type inference (e.g., "add feature" → `.context/planning/`, `.context/architecture/`)

**Example execution:**
```bash
python scripts/find_context.py \
  --context-dir ./.context \
  --keywords "monitoring agent setup" \
  --files "agent/executor.py" \
  --task-type "implementation"
```

This returns a ranked list of relevant markdown files.

### Step 3: Load Context Documents

Read the top-ranked context documents (typically 2-5 files) and incorporate them into your understanding:

```python
# Example output from find_context.py
{
  "relevant_files": [
    "context/agents/agent_configuration_guide.md",
    "context/monitoring/getting_started_monitoring.md",
    "context/planning/implementation_plan.md"
  ],
  "relevance_scores": [0.92, 0.85, 0.78]
}
```

**Loading strategy:**
- Always load README.md if it exists in context/
- Load top 3-5 most relevant documents
- Prioritize recent files for ongoing work
- Read documents using the Read tool

**After loading:**
- Briefly summarize key context to the user (1-2 sentences)
- Mention which documents were loaded
- Note any conflicts or outdated information

### Step 4: Execute Task with Context

Proceed with the user's requested task, informed by the loaded context:

- Reference relevant architecture decisions
- Follow established patterns and conventions
- Check implementation status for dependencies
- Adhere to project-specific guidelines

### Step 5: Update Context After Task

After completing work, use `scripts/update_context.py` to manage feedback:

**Update existing documents when:**
- Implementation status changes
- Architecture evolves
- Bugs are fixed (add to operations/)
- Features are completed (update planning/)

**Create new documents when:**
- Starting a new feature area
- Documenting a new integration
- Recording a significant architectural decision
- Establishing new operational procedures

**Example execution:**
```bash
python scripts/update_context.py \
  --context-dir ./.context \
  --category "monitoring" \
  --file "agent_streaming_implementation.md" \
  --action "update" \
  --summary "Completed agent streaming feature with WebSocket support"
```

**Update guidelines:**
- Prefer updating existing docs over creating new ones
- Use git for version control (no date-based file names needed)
- Keep updates concise and actionable
- Cross-reference related documents

## Context Categories

Common categories found in `.context/` directories:

| Category | Purpose | When to Load |
|----------|---------|--------------|
| `planning/` | Implementation plans, roadmaps, status | Feature work, project planning |
| `architecture/` | System design, technical decisions | Major changes, new features |
| `guides/` | Getting started, user guides | Setup, onboarding |
| `operations/` | Deployment, troubleshooting, ops | Bug fixes, incidents, deployment |
| `reference/` | API docs, CLI guides | Integration work, API usage |
| `integrations/` | External service setup | Third-party integrations |
| `agents/` | Agent configuration, capabilities | Agent-related work |
| `monitoring/` | Observability, metrics | Performance, debugging |

See `references/context_patterns.md` for detailed guidance.

## Context Discovery Algorithm

The skill uses a weighted scoring system:

**Keyword matching (40%):**
- Exact match in filename: +0.4
- Match in category name: +0.3
- Match in content (if indexed): +0.2

**Path-based matching (30%):**
- File path overlap with context category
- Related code directories

**Task type matching (20%):**
- Implementation tasks → planning/, architecture/
- Bug fixes → operations/, troubleshooting/
- Setup tasks → guides/, reference/

**Recency (10%):**
- Recently modified files get a boost
- Prioritize active work areas

## Examples

### 예시 1: 프로젝트 시작 시 컨텍스트 로드

```
사용자: 모니터링 기능 개선해줘

Claude: (context-manager 활성화)

📂 컨텍스트 디렉토리 확인 중...
✓ .context/ 디렉토리 발견

🔍 관련 문서 검색 중...
키워드: "모니터링", "monitoring"
작업 유형: implementation

📄 로드된 컨텍스트:
1. .context/monitoring/architecture.md (점수: 0.92)
2. .context/monitoring/metrics_guide.md (점수: 0.85)
3. .context/planning/monitoring_roadmap.md (점수: 0.78)

📋 요약:
- 현재 Prometheus + Grafana 스택 사용 중
- 메트릭 수집 주기: 30초
- 다음 마일스톤: 알림 시스템 구축

이제 모니터링 개선 작업을 시작하겠습니다.
```

### 예시 2: 컨텍스트 디렉토리 없는 경우

```
사용자: 새 기능 구현해줘

Claude: (context-manager 활성화)

📂 컨텍스트 디렉토리 확인 중...
⚠️ .context/ 디렉토리가 없습니다.

프로젝트 문서화를 위해 컨텍스트 구조를 생성할까요?

권장 구조:
.context/
├── planning/       # 기획, 로드맵
├── architecture/   # 시스템 설계
├── guides/         # 가이드 문서
└── operations/     # 운영, 트러블슈팅

[Y] 생성 / [N] 건너뛰기
```

### 예시 3: 작업 완료 후 컨텍스트 업데이트

```
사용자: (기능 구현 완료 후) 끝났어

Claude: 기능 구현이 완료되었습니다.

📝 컨텍스트 업데이트 중...

업데이트된 문서:
- .context/planning/implementation_status.md
  └─ "사용자 인증 기능" 상태: ✅ 완료

새로 생성된 문서:
- .context/architecture/auth_design.md
  └─ JWT 기반 인증 아키텍처 문서화

✓ 컨텍스트 업데이트 완료
```

### 예시 4: 버그 수정 시 컨텍스트 활용

```
사용자: 로그인 안 되는 버그 수정해줘

Claude: (context-manager 활성화)

🔍 관련 문서 검색 중...
키워드: "로그인", "login", "인증"
작업 유형: bugfix

📄 로드된 컨텍스트:
1. .context/operations/known_issues.md (점수: 0.88)
2. .context/architecture/auth_design.md (점수: 0.82)

📋 발견된 관련 정보:
- known_issues.md에 "세션 만료 후 리다이렉트 실패" 이슈 기록됨
- 해결 방안: refreshToken 로직 확인 필요

이 정보를 바탕으로 버그를 수정하겠습니다.
```

---

## Troubleshooting

### 컨텍스트 검색 결과 없음

```
문제: 관련 컨텍스트를 찾지 못함

해결:
1. 키워드를 더 일반적으로 확장
2. 카테고리 디렉토리 직접 확인
3. README.md가 있으면 먼저 로드
```

### 너무 많은 문서 로드

```
문제: 관련 문서가 너무 많아 토큰 낭비

해결:
1. 상위 3-5개 문서만 로드
2. 문서 요약 먼저 확인
3. 필요한 섹션만 선택적 로드
```

### 오래된 컨텍스트

```
문제: 로드된 문서가 현재 코드와 불일치

해결:
1. git log로 최근 변경 확인
2. 사용자에게 업데이트 필요 여부 질문
3. 작업 완료 후 컨텍스트 업데이트
```

### 스크립트 실행 오류

```bash
# find_context.py 오류 시
pip install pyyaml

# 권한 오류 시
chmod +x scripts/*.py
```

---

## Best Practices

**DO:**
- Always check for context at task start
- Load relevant context before making changes
- Update context after significant work
- Keep context documents concise and actionable
- Use categories consistently

**DON'T:**
- Skip context loading to save time
- Create duplicate documentation
- Use date-based filenames (git tracks history)
- Load entire .context/ directory (be selective)
- Forget to update implementation status

---

## Resources

### scripts/find_context.py

Python script that discovers relevant context documents using keyword matching, file path analysis, and task type inference. Returns ranked list of relevant files with relevance scores.

**Usage:**
```bash
python scripts/find_context.py \
  --context-dir <path> \
  --keywords <space-separated-keywords> \
  --files <space-separated-file-paths> \
  --task-type <implementation|bugfix|setup|planning>
```

### scripts/update_context.py

Python script that updates existing context documents or creates new ones based on completed work. Handles document merging, category selection, and maintains consistency.

**Usage:**
```bash
python scripts/update_context.py \
  --context-dir <path> \
  --category <category-name> \
  --file <filename> \
  --action <update|create> \
  --summary <work-summary>
```

### references/context_patterns.md

Comprehensive guide to common context directory structures, category conventions, and best practices for organizing project documentation. Includes templates for different project types and examples from real projects.
