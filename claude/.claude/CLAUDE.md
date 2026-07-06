# Global Claude Rules

Rules that apply to every project on this machine.

---

## Language & Communication

- Detect the language of the user's prompt and respond in that same language.
- Default fallback is English when the language is ambiguous.
- All implementation (code, identifiers, comments, commit messages, file names) must always be in English, regardless of the conversation language — unless explicitly requested otherwise.
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

- Prefer `Read`/`Edit`/`Write` tools over Bash `cat`/`sed`/`echo`.
- Ask before installing new packages (`npm install`, `brew install`, etc.).
