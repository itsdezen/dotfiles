#!/usr/bin/env python3
import fnmatch
import json
import subprocess


def agent(name):
    output = subprocess.check_output(["opencode", "debug", "agent", name], text=True)
    return json.loads(output)


def decision(profile, permission, value="*"):
    matches = [
        rule
        for rule in profile["permission"]
        if rule["permission"] == permission
        and fnmatch.fnmatchcase(value, rule["pattern"])
    ]
    assert matches, f"missing {permission} policy"
    return matches[-1]["action"]


build = agent("build")
plan = agent("plan")
debug = agent("debug")
review = agent("review")

assert build["mode"] == "primary"
assert decision(build, "edit", "src/app.ts") == "ask"
assert decision(build, "bash", "npm test") == "ask"

assert plan["mode"] == "primary"
assert plan["tools"]["bash"] is False
assert decision(plan, "read", "src/app.ts") == "allow"
assert decision(plan, "edit", "src/app.ts") == "deny"
assert decision(plan, "bash", "git status --short") == "deny"
assert decision(plan, "bash", "git diff --output=changed.txt") == "deny"
assert decision(plan, "bash", "bash -c 'echo changed > file'") == "deny"
assert decision(plan, "task") == "deny"
assert decision(plan, "plan_exit") == "deny"

assert debug["mode"] == "subagent"
assert review["mode"] == "subagent"

listing = subprocess.check_output(["opencode", "agent", "list"], text=True)
assert "build (primary)" in listing
assert "plan (primary)" in listing
for name in ("edit", "auto", "chief", "staff"):
    assert f"{name} (primary)" not in listing

print("opencode workflow checks passed")
