---
name: safeworld-platform
description: Run your perception endpoint or your robot brain against SafeWorld platform test suites with the safeworld CLI, and read the verdicts and artifacts. Use for a video suite (your perception scored on recorded clips) or a simulation suite (your planner as an external brain inside Isaac with realistic humans). Needs the safeworld CLI, installed and logged in by a person.
compatibility: Requires the safeworld CLI on PATH and a stored login; jq; ffmpeg 5.1 or later for video suites; Docker for simulation suites.
---

# SafeWorld platform suites

Run `safeworld skill show` and obey the guide that it prints. The guide matches the CLI version on this machine.

If `safeworld` is not on PATH, stop. Tell the person to install it from https://github.com/safeworldai/skills. Do not download or install it yourself.

If `safeworld skill show` is not a known command, the CLI is older than 0.2.0. Stop. Tell the person to install the newest CLI from the same page.

If a command fails with a login error or an API URL error, stop. Tell the person to run `safeworld auth login --api-url <API URL> --api-key`.

<!-- safeworld skill install wrote this file. The next install replaces it. -->
