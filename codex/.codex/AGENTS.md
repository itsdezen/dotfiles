# Global Codex Rules

Rules that apply to every project on this machine.

---

## Communication

- Keep responses short and concise. Do not explain what the code already makes obvious.

---

## Code Defaults

- Write no comments by default. Only add one when the WHY is non-obvious.
- No error handling for scenarios that cannot happen.
- No refactoring or abstractions beyond what the task requires.
- Do not add features beyond what was asked.
- Do not create README or doc files unless explicitly requested.

---

## Git & Destructive Operations

- Always confirm before: push, force push, `reset --hard`, branch deletion, or any hard-to-reverse operation.
- Never skip hooks (`--no-verify`) unless explicitly asked.
- Commit style: emoji prefix — `🚀 🐞 🔧 ♻️ 📝 🗑️ ⬆️`

---

## Security

- Never commit `.env`, credentials, or secrets.
- Warn immediately if hardcoded secrets are detected in code.

---

## Tool Behavior

- Ask before installing new packages (`npm install`, `brew install`, etc.).
