---
name: safeworld-platform
description: Run your perception endpoint or your robot brain against SafeWorld platform test suites, by suite name or id, with the safeworld CLI, and read the verdicts and artifacts. Use for a video suite (your perception scored on recorded clips) or a brain suite (your planner as an external brain inside Isaac with realistic humans). Needs a SafeWorld API key (web app, Settings → API Keys) in SAFEWORLD_API_KEY and your organization's SAFEWORLD_API_URL before anything else; step 0 checks both.
compatibility: Requires network access to the SafeWorld API and a SafeWorld API key minted in the web app under Settings → API Keys; the pinned safeworld CLI (scripts/install_safeworld_cli.sh installs it), ffmpeg 5.1 or later, jq, curl, Python 3 and git; Docker for brain suites.
---

# SafeWorld platform suites

Two suite kinds, one command set. `scripts/sw` beside this file is the `safeworld` CLI plus a
ledger: every call, its exit code and its JSON result land in `.safeworld/ledger.jsonl` under the
current directory, secrets redacted. Use it for every call.

Put the scripts on PATH once per session (`SKILL_DIR` is the directory of this file):

```bash
export PATH="$SKILL_DIR/scripts:$PATH"
```

## Step 0: preflight, before anything else

```bash
preflight.sh
```

It stops at the first missing thing and says how to get it. The platform needs two values:

| Variable | Where it comes from |
|---|---|
| `SAFEWORLD_API_URL` | your organization's SafeWorld API base URL; SafeWorld gives it with the account |
| `SAFEWORLD_API_KEY` | an API key minted in the SafeWorld web app under **Settings → API Keys** (copy it once) |

Ask the person for them if they are missing. Never write the key into a file in the repo, into
the ledger, or into chat. Preflight logs the CLI in with the key and prints `preflight: ok`.

## Find the suite

The CLI has no `suite list`; read the API. Given a suite name, pick the row whose title matches
and use its `suite_id`. A suite id is a row's `suite_id`, never the template slug in a web URL.

Video suites are the `/api/v1/benchmarks` rows with `origin == "video"`:

```bash
curl -s -H "Authorization: Bearer $SAFEWORLD_API_KEY" "$SAFEWORLD_API_URL/api/v1/benchmarks" \
  | jq -r '.benchmarks[] | select(.origin == "video" and .suite_id != null) | "\(.suite_id)  \(.title)  items=\(.counts.scenarios)"'
```

Brain suites are the `/api/v1/base-suite` adoptions:

```bash
curl -s -H "Authorization: Bearer $SAFEWORLD_API_KEY" "$SAFEWORLD_API_URL/api/v1/base-suite" \
  | jq -r '.suites[].adoptions[] | "\(.suite_id)  \(.title)  \(.robot_name)"'
```

Run `suite start --endpoint` only on a video suite.

## Video suite: your perception endpoint on recorded clips

Your endpoint implements `safeworld.perception_endpoint/v1`: `GET /health`, `POST /reset`,
`POST /act` (one PNG frame in, boxes out). The full contract, the scoring rule and a minimal
endpoint are in [`reference/perception-endpoint.md`](reference/perception-endpoint.md). The CLI
sends one PNG per frame, in order, and waits for each answer. Clips never leave the platform
except through the CLI's signed download; the ground truth never leaves it at all.

1. Start your endpoint in the background. Wait for `GET http://127.0.0.1:8000/health` to answer 2xx.
2. ```bash
   sw suite run <suite-id> --label "$(git rev-parse --short HEAD)" --manifest .safeworld/suite.json --output-json
   sw suite start <suite-run-id> $(jq -r '.items[] | "--item \(.item_id)"' .safeworld/suite.json) --endpoint http://127.0.0.1:8000 --output-json
   sw suite status <suite-run-id> --wait --timeout 0 --output-json
   ```
   Items stream one after the other, about 6 s per short clip: a 948-item suite takes about two
   hours. Run `suite start` in the background past 50 items. Unstarted items expire after 24 h
   (`suite run --expires-in` changes that). To go faster, split the item list, run one endpoint
   per split on its own port, and start the splits in parallel; never share one endpoint between
   two streams, because `/reset` holds per-clip state.
3. Read each item: `approved` means recall reached the rule's `min_recall`; `rejected` names the
   recall; `failed` names the endpoint error (`endpoint_unreachable`, `endpoint_error` for a
   non-2xx answer, `endpoint_bad_response`, `decode_failed`). The web report's Watch clip shows
   your boxes beside the ground truth. Report per-look and per-clip counts, not only the total.

## Brain suite: your planner inside Isaac with humans

Your brain runs as an external brain: a container on your machine, built with the SafeWorld
policy-bridge SDK, that dials the simulation over TLS with a per-run credential. Nothing of yours
is uploaded. The SDK and a template brain are in SafeWorld's customer examples; ask SafeWorld for
access if you do not have them.

Gate: the image must answer `--selftest` naming your adapter. If there is no brain image for this
repo, or the self-test names another adapter, do not run a suite. Report "not run: no brain
container for this stack".

```bash
docker run --rm <brain-image> --selftest                     # must name your adapter
sw suite run <suite-id> --label "$(git rev-parse --short HEAD)" --shards 1 --manifest .safeworld/suite.json --output-json
sw suite start <suite-run-id> --item <id> [--item <id>] --compose docker-compose.yaml --brain-service brain --wait-timeout 1500 --output-json
sw suite status <suite-run-id> --wait --timeout 0 --output-json
```

A single scenario instead of a suite: `sw sim run <config-id> --compose <file> --brain-service brain --wait-timeout 1500 --output-json`.

## Reading a platform verdict

`approved` on a brain item means the run completed with outcome `success`. That is a wiring
verdict, not a safety verdict: the platform records the physics and does not score contact.
Score it yourself from the artifacts:

```bash
sw run artifacts <run-id> --output-json | jq -r '.links[].key'
sw run download <run-id> --name surface_separation --name pose_trace --out .safeworld/runs/<run-id>/
```

`--name` takes an artifact key from `run artifacts`, not a file name; the file keeps its own name
(`surface_separation.json`). It holds the robot-to-human surface gap per sample; contact while the
robot moves is a fail under `contact_rule/v1`. The run page in the web app (the `url` in
`suite status`) shows video, poses and acceptance screens.

## Exit codes (the CLI's contract)

| Code | Meaning |
|---|---|
| 0 | success / every item approved |
| 2 | API, auth or usage error |
| 3 | suite start: run or endpoint failed · suite status: any item rejected or failed (read each item) |
| 4 | no capacity (retry once after 120 s) |
| 5 | timeout |
| 6 | suite start only: non-success outcome / item rejected |
| 7 | docker or compose error |

Exit 3 and 6 are verdicts, not tool failures: read the items and report them.

## Don'ts

- Do not pass `--external-brain` on a suite whose placements are already external.
- Do not read ground truth; the CLI never has it and the report is the only place to compare.
- Do not retry a `rejected` item with changed thresholds. Report it.
- Do not put the API key in a file, a commit, the ledger or chat.
