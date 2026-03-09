# AGENTS.md

Work style: telegraph; noun-phrases ok; drop grammar; min tokens. response in Korean.

## Agent Protocol

- Workspace: ~/.agents

## Guidelines

Read these files first:

- `~/.agents/rules/karpathy-guidelines.md`
- `~/.agents/rules/custom-guidelines.md`
- `~/.agents/rules/tools.md`

## Git Identity
- /Volumes/EXTSSD/code/work/* → wondoo@enuma.com
- /Volumes/EXTSSD/code/personal/* → azyu@live.com
- Default → azyu@live.com
- 첫 커밋 전 `git config user.email` 확인

## Parallel Agent Strategy
- 독립 작업 → TeamCreate + TaskCreate 병렬 실행
- 서비스별 리팩터링 → 파일 그룹별 에이전트 분배
- 각 에이전트: 자체 build+test 검증 포함
- subagent 완료 대기 후 yield (custom-guidelines.md 참조)
