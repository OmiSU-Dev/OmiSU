# Crash reporting

When a crash looks like an OmiSu bug (not a third-party app), search and file
against the OmiSu fork repo.

```bash
gh search issues --repo OmiSU-Dev/OmiSU "<program> crash"
gh issue list --repo OmiSU-Dev/OmiSU --state all --search "<signal> <program>"
```

```bash
gh issue view <number> --repo OmiSU-Dev/OmiSU --comments
gh issue comment <number> --repo OmiSU-Dev/OmiSU --body "..."
gh issue create --repo OmiSU-Dev/OmiSU --title "..." --body "..."
```

Include `omisu debug --no-sudo --print` output and steps to reproduce.
