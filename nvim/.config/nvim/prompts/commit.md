---
name: Commit message (emoji)
interaction: chat
description: Generate an emoji-prefixed commit message
opts:
  alias: gitmoji
  auto_submit: true
  is_slash_cmd: true
---

## user

Given the git diff below, generate a commit message in this exact style: a single short line starting with one emoji prefix — 🚀 (feature), 🐞 (bugfix), 🔧 (config/tooling), ♻️ (refactor), 📝 (docs), 🗑️ (removal), ⬆️ (upgrade) — followed by a concise lowercase summary. Output only the commit message, nothing else.

`````diff
${commit.diff}
`````
