---
name: weekly-report
description: 주간 업무 리포트 생성. Use when creating weekly reports, work summaries, or standup updates from git history. Triggers on "주간 보고", "weekly report", "업무 정리", "주간 리포트", "work summary", "standup", "이번 주 작업".
---

# Weekly Report Generator

## Git History 수집
```bash
# 이번 주 커밋 (월요일부터)
git log --since="last monday" --until="now" --oneline --author="Wondoo"

# 프로젝트별 수집
for dir in /Volumes/EXTSSD/code/work/*/; do
  echo "=== $(basename $dir) ==="
  cd "$dir" && git log --since="last monday" --oneline --author="Wondoo" 2>/dev/null
done
```

## 리포트 형식
```markdown
# 주간 업무 보고 (M/D ~ M/D)

## 완료
- [프로젝트] 작업 내용

## 진행 중
- [프로젝트] 작업 내용 (진행률)

## 이슈/블로커
- 내용

## 다음 주 계획
- 내용
```

## 작성 가이드
- 커밋 메시지에서 작업 추출 → 비개발자도 이해할 수 있게 요약
- feat/fix/refactor prefix로 작업 유형 분류
- PR 링크 포함 (가능 시)
- 기술 디테일은 최소화, 비즈니스 임팩트 위주
