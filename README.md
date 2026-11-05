# SafeWorld agent skills

Skills for coding agents (Claude Code, Codex, Cursor and any other agent that reads `SKILL.md`)
that test a robot stack on the SafeWorld platform.

## Before anything else: a SafeWorld API key

Every skill here talks to the platform, so it needs two values in the environment:

| Variable | Where it comes from |
|---|---|
| `SAFEWORLD_API_URL` | Your organization's SafeWorld API base URL. SafeWorld gives it to you with your account. |
| `SAFEWORLD_API_KEY` | An API key you mint in the SafeWorld web app under **Settings → API Keys**. Copy it once; it is not shown again. |

```bash
export SAFEWORLD_API_URL=<your organization's API base URL>
export SAFEWORLD_API_KEY=<the key>
```

Keep the key out of files in your repo and out of chat. Each skill's first step,
`preflight.sh`, stops with a plain message if either value is missing.

## Install

```bash
npx skills add safeworldai/skills
```

That installs every skill here for the agents it detects. One skill only:
`npx skills add safeworldai/skills@safeworld-platform`. Or copy a `skills/<name>/` directory into
your project's `.claude/skills/`, `.agents/skills/` or `.codex/skills/`.

## Skills

| Skill | What it does |
|---|---|
| [`safeworld-platform`](skills/safeworld-platform/SKILL.md) | Run your perception endpoint or your robot brain against SafeWorld platform test suites, by suite name or id, with the `safeworld` CLI, and read the verdicts and artifacts. |

## The `safeworld` CLI

The skills drive a pinned release of the `safeworld` CLI through `scripts/sw`, a wrapper that
writes every call and its result to `.safeworld/ledger.jsonl` (secrets redacted).
`scripts/install_safeworld_cli.sh` installs the release into `~/.local/bin`. Until the public
release channel exists, the installer downloads from the release mirror in
`safeworldai/customer-examples`, which needs a GitHub account with access to that repository.
Set `SAFEWORLD_CLI_REPO` to another mirror if SafeWorld gave you one.
