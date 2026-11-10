# SafeWorld agent skills

Skills for coding agents (Claude Code, Codex, Cursor and any other agent that reads `SKILL.md`)
that test a robot stack on the SafeWorld platform.

You install the `safeworld` CLI. Your agent reads the skill and drives the CLI. The agent does
not download or install software.

## Set up, one time per machine

### 1. Install the `safeworld` CLI

```bash
curl -fsSL https://raw.githubusercontent.com/safeworldai/skills/main/install.sh | bash
```

[`install.sh`](install.sh) downloads a pinned CLI release from this repository's
[Releases](https://github.com/safeworldai/skills/releases) page (no GitHub account needed), checks
its SHA-256, and installs it into `~/.local/bin`. On Windows, download the `.zip` from the
Releases page and put `safeworld.exe` on `PATH`. Set `SAFEWORLD_CLI_VERSION` to install another
release, or `SAFEWORLD_CLI_REPO` to use another mirror.

### 2. Give your shell the two platform values

| Variable | Where it comes from |
|---|---|
| `SAFEWORLD_API_URL` | Your organization's SafeWorld API base URL. SafeWorld gives it to you with your account. |
| `SAFEWORLD_API_KEY` | An API key you mint in the SafeWorld web app under **Settings → API Keys**. Copy it once; it is not shown again. |

```bash
export SAFEWORLD_API_URL=<your organization's API base URL>
export SAFEWORLD_API_KEY=<the key>
```

Keep the key out of files in your repo and out of chat.

### 3. Add the skills to your agent

```bash
npx skills add safeworldai/skills
```

That installs every skill here for the agents it detects. One skill only:
`npx skills add safeworldai/skills@safeworld-platform`. Or copy a `skills/<name>/` directory into
your project's `.claude/skills/`, `.agents/skills/` or `.codex/skills/`.

## Use

Ask your agent in plain words, for example: "Run the warehouse video suite against my perception
endpoint on port 8000." The agent runs the skill's first step, `preflight.sh`. It stops with a
plain message if the CLI or one of the two values is missing.

## Skills

| Skill | What it does |
|---|---|
| [`safeworld-platform`](skills/safeworld-platform/SKILL.md) | Run your perception endpoint or your robot brain against SafeWorld platform test suites, by suite name or id, with the `safeworld` CLI, and read the verdicts and artifacts. |

## The ledger

The skills call the CLI through `scripts/sw`, a wrapper that writes every call and its result to
`.safeworld/ledger.jsonl` under the current directory (secrets redacted).
