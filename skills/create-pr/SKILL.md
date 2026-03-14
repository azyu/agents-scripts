---
name: create-pr
description: 'Git diff 분석 기반 고품질 PR 생성. What/Why/How 구조. PR 템플릿 자동 감지 적응.'
allowed-tools: Bash(git *), Bash(gh pr create*), Bash(gh api *)
---

## Workflow

**Follow these 7 steps sequentially:**

### Step 1: Branch 확인

```bash
git branch --show-current
git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'
```

- 현재 브랜치가 `main` 또는 `master`면 → 사용자에게 feature branch 생성 요청 후 중단
- base branch 자동 감지 (origin HEAD branch). 감지 실패 시 사용자에게 질문

### Step 2: 변경 분석

아래 3개 명령을 **병렬** 실행:

```bash
git log <base>..HEAD --oneline
git diff <base>...HEAD --stat
git diff <base>...HEAD
```

- `<base>` = Step 1에서 감지한 base branch
- 커밋이 없으면 → "No commits to create PR" 메시지 후 중단
- diff가 너무 크면(5000줄+) `--stat` 결과 중심으로 분석

### Step 3: PR 템플릿 감지

```bash
cat .github/pull_request_template.md 2>/dev/null || cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

- 파일 존재 → **템플릿 모드**: 템플릿 섹션을 diff 분석 결과로 채움
- 파일 없음 → **기본 모드**: What/Why/How 구조 사용

### Step 4: PR Title 생성

규칙:
- **70자 이내**
- Conventional commit type prefix: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `perf:`, `ci:`
- 변경의 핵심을 한 줄로 요약
- scope가 명확하면 `feat(auth):` 형태 사용

### Step 5: PR Body 생성

#### 기본 모드 (What/Why/How)

```markdown
## What
<!-- 무엇을 변경했는지 1-3 bullet points -->

## Why
<!-- 왜 이 변경이 필요한지 -->

## How
<!-- 어떻게 구현했는지 — 핵심 접근 방식 -->

## Test Plan
- [ ] 테스트 항목들

## Related Issues
<!-- closes #123 등 -->
```

#### 템플릿 모드

Step 3에서 감지한 템플릿의 각 섹션을 diff 분석 결과로 채움. 빈 섹션 남기지 않음.

#### Body 작성 규칙

- **diff 기반 사실만 기술** — 추측/과장 금지
- What: 변경된 파일과 기능을 구체적으로 나열
- Why: 커밋 메시지, 브랜치명, 코드 컨텍스트에서 추론. 불명확하면 간단히 기술
- How: 핵심 구현 접근 방식. 아키텍처 변경이 있으면 강조
- Test Plan: 변경된 파일/기능 기반으로 테스트 항목 추론. 테스트 코드가 포함되어 있으면 해당 내용 반영
- Related Issues: 커밋 메시지에서 `#숫자`, `closes`, `fixes`, `resolves` 패턴 자동 추출

### Step 6: Auto-delete branch 설정 확인

```bash
gh api repos/{owner}/{repo} --jq '.delete_branch_on_merge'
```

- `false`면 → 자동 활성화:
  ```bash
  gh api repos/{owner}/{repo} --method PATCH -f delete_branch_on_merge=true
  ```
- 머지 후 head branch가 자동 삭제되므로 수동 정리 불필요

### Step 7: PR 생성

remote에 push 후 PR 생성:

```bash
git push -u origin $(git branch --show-current)
```

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

- push 실패 시 원인 분석 후 사용자에게 안내
- `gh` CLI 미설치 시 설치 안내

### Step 8: 결과 출력

- PR URL 반환
- 주요 변경 요약 (1-2줄)
