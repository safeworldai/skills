# SafeWorld CLI and agent skill

The `safeworld` CLI tests a robot stack on the SafeWorld platform. A coding agent (Claude Code,
Codex, Cursor and any other agent that reads `SKILL.md`) can drive it for you.

You install the CLI and log in. The CLI gives your agent its skill. The agent reads Markdown and
runs CLI commands. It does not install software, and it never holds your API key.

## Set up, one time per machine

### 1. Install the `safeworld` CLI

```bash
curl -fsSL https://raw.githubusercontent.com/safeworldai/skills/main/install.sh | bash
```

[`install.sh`](install.sh) downloads the newest CLI release from this repository's
[Releases](https://github.com/safeworldai/skills/releases) page (no GitHub account needed), checks
its SHA-256, and installs it into `~/.local/bin`. On Windows, download the `.zip` from the
Releases page and put `safeworld.exe` on `PATH`.

### 2. Log in

```bash
safeworld auth login --api-url <your organization's API base URL> --api-key
```

SafeWorld gives you the API base URL with your account. The command asks for an API key. Mint
one in the SafeWorld web app under **Settings → API Keys**; copy it once, it is not shown again.
The CLI keeps the key in its own credential file. Do not put the key in your repo or in chat.

### 3. Give the skill to your agent

```bash
safeworld skill install --dir .claude/skills
```

| Agent | Directory |
|---|---|
| Claude Code, in one project | `.claude/skills` |
| Claude Code, for your user | `~/.claude/skills` |
| Codex and other agents that read `.agents/skills` | `.agents/skills` |

`npx skills add safeworldai/skills` installs the same skill for the agents it detects.

## Use

Ask your agent in plain words, for example: "Run the dock clips suite against my perception
endpoint on port 8000."

The agent reads the installed skill, which is short. It tells the agent to run
`safeworld skill show`. That command prints the guide for the CLI version on your machine. The
agent then finds the suite with `safeworld suite list`, runs it, and reports the verdict of each
item. It stops and tells you when the CLI is missing or the login fails.

You can read the same texts:

```bash
safeworld skill show
```

```bash
safeworld skill show perception-endpoint
```

## What a suite needs

| Suite kind | Needs |
|---|---|
| Video (your perception endpoint on recorded clips) | `ffmpeg` 5.1 or later, `jq`, your endpoint |
| Simulation (your planner as an external brain) | Docker, your brain container |

## Upgrade

Run the install line again. The guide ships inside the CLI, so it changes with the CLI. Run
`safeworld skill install --dir <DIR>` again only when the release notes say the skill file changed.

## Pin a release

A CI job must pin its CLI release:

```bash
curl -fsSL https://raw.githubusercontent.com/safeworldai/skills/main/install.sh | SAFEWORLD_CLI_VERSION=cli-v0.2.0 bash
```

`SAFEWORLD_CLI_DEST` changes the install directory. `SAFEWORLD_CLI_REPO` names another mirror.
The agent skill needs CLI 0.2.0 or later.
