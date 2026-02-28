# Worker Types Reference

## Codex CLI

### Installation
```bash
npm i -g @openai/codex
```

### Headless Execution
```bash
codex exec --yolo --json --ephemeral -m <model> "<prompt>"
```

| Flag | Purpose |
|------|---------|
| `exec` | Non-interactive headless mode |
| `--yolo` | Skip all approvals (headless-safe; `--full-auto` can hang) |
| `--json` | JSONL stream to stdout |
| `--ephemeral` | Don't persist session to disk |
| `-m <model>` | Model selection |

### Available Models

| Model | Use Case |
|-------|----------|
| gpt-5.3-codex | Default — best agentic coding |
| gpt-5.3-codex-spark | Text-only research preview |
| gpt-5.2-codex | Complex real-world engineering |
| gpt-5.1-codex-max | Long agentic coding sessions |

### JSONL Output Format

Each line is a JSON event:

```jsonl
{"type":"thread.started","threadId":"..."}
{"type":"turn.started"}
{"type":"item.completed","item":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"..."}]}}
{"type":"turn.completed"}
```

**Parsing:** Extract the last `item.completed` where `item.role == "assistant"`, read `item.content[0].text`.

### Exit Codes
- 0: Success
- Non-zero: Error

---

## Gemini CLI

### Installation
```bash
npm i -g @google/gemini-cli
```

### Headless Execution
```bash
gemini -p "<prompt>" --yolo --output-format json
```

| Flag | Purpose |
|------|---------|
| `-p` / `--prompt` | Non-interactive prompt mode |
| `--yolo` | Skip all approvals |
| `--output-format json` | Single JSON output |
| `--output-format stream-json` | JSONL stream output |

### Available Models

| Model | Use Case |
|-------|----------|
| Auto (default) | Gemini 2.5 Flash + Gemini 3 Pro auto-routing |
| gemini-3-pro | General purpose |
| gemini-3-flash | Fast, lightweight |
| gemini-3.1-pro-preview | Latest preview |

### JSON Output Format

```json
{
  "response": "The generated text...",
  "stats": { ... },
  "error": null
}
```

**Parsing:** Read the `response` field directly.

### Exit Codes
- 0: Success
- 1: Error
- 42: Input error
- 53: Turn limit exceeded
