---
name: websearch
description: >-
  Google web search via Gemini CLI. Use when /websearch query invocation,
  need latest info or versions or current data, keywords like 검색 구글 구글링
  search google, research or investigation requests, recent news or current
  information needed, information beyond model knowledge cutoff. Leverages
  Gemini CLI built-in google_web_search tool for real-time Google search results.
---

# Web Search via Gemini CLI

Gemini CLI의 `google_web_search` 내장 도구를 사용하여 Google 웹 검색 수행.

## 사용법

1. `$ARGUMENTS`에서 검색 쿼리 추출
2. Bash로 실행:

```bash
gemini -p "Use google_web_search to find: $QUERY. Provide a comprehensive summary with source URLs." --output-format json 2>/dev/null | jq -r '.response'
```

3. 결과가 비어있거나 에러 시 `--output-format json` 없이 재시도:

```bash
gemini -p "Use google_web_search to find: $QUERY. Provide a comprehensive summary with source URLs." 2>/dev/null
```

4. 검색 결과를 사용자에게 그대로 전달. 필요 시 요약/번역 추가.

## 참고

- Free tier: 60 req/min, 1,000 req/day
- 응답 시간: 5~15초 (웹 검색 포함)
- 결과는 Gemini가 합성한 요약문 + 출처 URL
- `gemini` 명령어가 PATH에 있어야 함 (`/opt/homebrew/bin/gemini`)
