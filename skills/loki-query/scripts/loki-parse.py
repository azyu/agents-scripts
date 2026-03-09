#!/usr/bin/env python3
"""Parse Loki query_range JSON output into readable format.

Usage:
  loki-query.sh '...' | python3 loki-parse.py [--json] [--count]

Options:
  --json    Output full JSON objects (not just summary)
  --count   Show count per level only
"""
import sys
import json
from collections import Counter


def main():
    raw = sys.stdin.read().strip()
    if not raw:
        print("No input received")
        return

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")
        print(f"Raw input (first 200 chars): {raw[:200]}")
        return

    results = data.get("data", {}).get("result", [])
    total = sum(len(s.get("values", [])) for s in results)

    args = set(sys.argv[1:])

    if "--count" in args:
        levels = Counter()
        for stream in results:
            loki_level = stream.get("stream", {}).get("level", "unknown")
            levels[loki_level] += len(stream.get("values", []))
        print(f"Total: {total} entries")
        for level, count in levels.most_common():
            print(f"  {level}: {count}")
        return

    print(f"Total: {total} entries, {len(results)} streams")
    print()

    for stream in results:
        labels = stream.get("stream", {})
        loki_level = labels.get("level", "?")
        service = labels.get("service_name", "?")

        for ts, line in stream.get("values", []):
            try:
                obj = json.loads(line)
                json_level = obj.get("level", "?")
                ts_str = obj.get("timestamp", "?")
                msg = obj.get("message", "")
                ctx = obj.get("context", "")
                trace = obj.get("trace_id", "")

                level_mark = (
                    ""
                    if loki_level == json_level
                    else f" !!MISMATCH(loki={loki_level})"
                )

                if "--json" in args:
                    print(json.dumps(obj, indent=2))
                else:
                    trace_str = f" trace={trace[:16]}" if trace else ""
                    ctx_str = f" [{ctx}]" if ctx else ""
                    print(
                        f"  {ts_str} [{json_level}{level_mark}]"
                        f"{ctx_str}{trace_str} {msg[:120]}"
                    )
            except json.JSONDecodeError:
                print(f"  (raw) {line[:150]}")


if __name__ == "__main__":
    main()
