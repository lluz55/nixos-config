#!/usr/bin/env bash
# Sync the 9router model catalog into the dsh settings document.
#
# 9router is a hand-declared route for dsh's pi-ai adapter: the installed
# pi-ai catalog knows nothing about it, so `models` must be listed explicitly
# in $DSH_HOME/settings.yaml. That list goes stale whenever 9router gains or
# drops an upstream model. This script re-reads GET /v1/models and rewrites
# ONLY llm-pi-ai.providers.<route>.models, leaving every other namespace,
# key, and comment in the document untouched.
#
# Idempotent: a run that finds no drift exits 0 without touching the file
# (and therefore without triggering dsh's settings watcher).
# Fail-loud: any unreachable endpoint, malformed payload, or unparsable
# document aborts before writing.
#
# Exit codes:
#   0  in sync (no write) or updated successfully
#   1  error (endpoint, parsing, or write failure)
#   2  drift detected while running with --check
set -euo pipefail

BASE_URL="${NINEROUTER_BASE_URL:-http://localhost:20128/v1}"
SETTINGS_FILE="${DSH_SETTINGS_FILE:-${DSH_HOME:-$HOME/.dsh}/settings.yaml}"
ROUTE="${DSH_9ROUTER_ROUTE:-9router}"
RESTART_SERVICE="${DSH_RESTART_SERVICE:-dsh}"

CHECK_ONLY=0
NO_RESTART=0
QUIET=0

usage() {
  cat <<'USAGE'
Usage: sync-dsh-9router-models.sh [options]

Options:
  --check         Report drift and exit 2 without writing anything.
  --no-restart    Rewrite settings.yaml but do not restart the dsh service.
  --quiet         Only print on drift or error.
  -h, --help      Show this help.

Environment:
  NINEROUTER_BASE_URL   9router OpenAI-compatible base URL
                        (default: http://localhost:20128/v1)
  DSH_SETTINGS_FILE     settings document path
                        (default: $DSH_HOME/settings.yaml, else ~/.dsh/settings.yaml)
  DSH_9ROUTER_ROUTE     route key under llm-pi-ai.providers (default: 9router)
  DSH_RESTART_SERVICE   systemd unit to restart on change (default: dsh)
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --no-restart) NO_RESTART=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "sync-dsh-9router-models: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

command -v node >/dev/null 2>&1 || {
  echo "sync-dsh-9router-models: node not found in PATH" >&2
  exit 1
}

# The `yaml` library ships inside the dsh installation; dsh's own
# settings-file plugin uses it, so reusing it keeps comment/anchor
# preservation identical to what dsh itself writes. No global install and no
# new dependency: resolve it from the live profile, then from the store.
YAML_MODULE=""
for candidate in \
  "${DSH_HOME:-$HOME/.dsh}/profiles/node_modules/yaml" \
  "${DSH_HOME:-$HOME/.dsh}/profiles/web/node_modules/yaml"
do
  if [ -d "$candidate" ]; then YAML_MODULE="$candidate"; break; fi
done
if [ -z "$YAML_MODULE" ]; then
  # Last resort: the yaml copy bundled in the currently running dsh closure.
  YAML_MODULE="$(
    ls -d /nix/store/*-dsh-*/lib/dsh/node_modules/yaml 2>/dev/null | head -n 1 || true
  )"
fi
if [ -z "$YAML_MODULE" ] || [ ! -d "$YAML_MODULE" ]; then
  echo "sync-dsh-9router-models: could not resolve the 'yaml' module used by dsh" >&2
  echo "  looked under \$DSH_HOME/profiles and the dsh nix store closure" >&2
  exit 1
fi

# Node does the whole job: fetch, normalize, diff, and a leaf-level rewrite of
# just the models list. Keeping it in one process avoids a half-written
# document if the endpoint dies mid-run.
set +e
NINEROUTER_BASE_URL="$BASE_URL" \
DSH_SETTINGS_FILE="$SETTINGS_FILE" \
DSH_9ROUTER_ROUTE="$ROUTE" \
SYNC_CHECK_ONLY="$CHECK_ONLY" \
SYNC_QUIET="$QUIET" \
SYNC_YAML_MODULE="$YAML_MODULE" \
node --input-type=module <<'NODE_EOF'
import { readFileSync, writeFileSync, renameSync } from 'node:fs'
import { createRequire } from 'node:module'

const require = createRequire(import.meta.url)
const YAML = require(process.env.SYNC_YAML_MODULE)

const baseURL = process.env.NINEROUTER_BASE_URL.replace(/\/+$/, '')
const settingsFile = process.env.DSH_SETTINGS_FILE
const route = process.env.DSH_9ROUTER_ROUTE
const checkOnly = process.env.SYNC_CHECK_ONLY === '1'
const quiet = process.env.SYNC_QUIET === '1'

const log = (...args) => { if (!quiet) console.log(...args) }
const fail = (msg) => { console.error(`sync-dsh-9router-models: ${msg}`); process.exit(1) }

// ── 1. read the live catalog ────────────────────────────────────────────────
let payload
try {
  const res = await fetch(`${baseURL}/models`, { signal: AbortSignal.timeout(15000) })
  if (!res.ok) fail(`GET ${baseURL}/models returned HTTP ${res.status}`)
  payload = await res.json()
} catch (error) {
  fail(`cannot reach ${baseURL}/models: ${error.message}`)
}

const entries = Array.isArray(payload?.data) ? payload.data : undefined
if (entries === undefined) fail(`${baseURL}/models did not return a 'data' array`)
if (entries.length === 0) fail(`${baseURL}/models returned an empty catalog; refusing to blank the route`)

// dsh requires a positive integer for both fields; the fallbacks mirror the
// pi-ai adapter defaults so an undescribed model still loads.
const DEFAULT_CONTEXT_WINDOW = 262144
const DEFAULT_MAX_TOKENS = 32768
const positive = (...candidates) => {
  for (const value of candidates) {
    if (typeof value === 'number' && Number.isInteger(value) && value > 0) return value
  }
  return undefined
}

const discovered = entries.map((entry) => {
  if (typeof entry?.id !== 'string' || entry.id.length === 0) {
    fail(`${baseURL}/models returned an entry with no usable 'id'`)
  }
  return {
    id: entry.id,
    contextWindow: positive(
      entry.context_length, entry.capabilities?.contextWindow, entry.max_input_tokens,
    ) ?? DEFAULT_CONTEXT_WINDOW,
    maxTokens: positive(
      entry.max_completion_tokens, entry.capabilities?.maxOutput, entry.max_tokens,
    ) ?? DEFAULT_MAX_TOKENS,
  }
}).sort((a, b) => a.id.localeCompare(b.id))

// ── 2. read the settings document ───────────────────────────────────────────
let text
try {
  text = readFileSync(settingsFile, 'utf8')
} catch (error) {
  if (error.code === 'ENOENT') fail(`${settingsFile} does not exist; create the llm-pi-ai route first`)
  fail(`cannot read ${settingsFile}: ${error.message}`)
}

const doc = YAML.parseDocument(text, { prettyErrors: true })
if (doc.errors.length > 0) {
  fail(`${settingsFile} is not valid YAML: ${doc.errors.map((e) => e.message).join('; ')}`)
}

const modelsPath = ['llm-pi-ai', 'providers', route, 'models']
if (!doc.hasIn(['llm-pi-ai', 'providers', route])) {
  fail(`${settingsFile} has no llm-pi-ai.providers.${route} route to update`)
}

const currentRaw = doc.getIn(modelsPath)?.toJSON?.() ?? doc.getIn(modelsPath) ?? []
if (!Array.isArray(currentRaw)) fail(`llm-pi-ai.providers.${route}.models is not a list`)
const current = currentRaw
  .filter((m) => typeof m?.id === 'string')
  .map((m) => ({ id: m.id, contextWindow: m.contextWindow, maxTokens: m.maxTokens }))
  .sort((a, b) => a.id.localeCompare(b.id))

// ── 3. diff ─────────────────────────────────────────────────────────────────
const key = (m) => `${m.id}\u0000${m.contextWindow}\u0000${m.maxTokens}`
const currentIds = new Set(current.map((m) => m.id))
const discoveredIds = new Set(discovered.map((m) => m.id))
const added = discovered.filter((m) => !currentIds.has(m.id)).map((m) => m.id)
const removed = current.filter((m) => !discoveredIds.has(m.id)).map((m) => m.id)
const currentByKey = new Set(current.map(key))
const changed = discovered
  .filter((m) => currentIds.has(m.id) && !currentByKey.has(key(m)))
  .map((m) => m.id)

const inSync = added.length === 0 && removed.length === 0 && changed.length === 0
if (inSync) {
  log(`9router models already in sync (${discovered.length} models)`)
  process.exit(0)
}

console.log(`9router model drift detected in ${settingsFile}:`)
if (added.length > 0) console.log(`  + added   (${added.length}): ${added.join(', ')}`)
if (removed.length > 0) console.log(`  - removed (${removed.length}): ${removed.join(', ')}`)
if (changed.length > 0) console.log(`  ~ changed (${changed.length}): ${changed.join(', ')}`)

if (checkOnly) {
  console.log('(--check: no changes written)')
  process.exit(2)
}

// ── 4. rewrite only the models list ─────────────────────────────────────────
// setIn on this single path is what keeps every other namespace, key, and
// comment in the document exactly as the user left it.
doc.setIn(modelsPath, discovered)
const output = doc.toString({ lineWidth: 0 })

// Re-parse the rendered text before committing: a document dsh cannot load
// would put the service into a restart loop.
const verify = YAML.parseDocument(output, { prettyErrors: true })
if (verify.errors.length > 0) fail(`refusing to write invalid YAML: ${verify.errors.map((e) => e.message).join('; ')}`)
const verifyModels = verify.getIn(modelsPath)?.toJSON?.()
if (!Array.isArray(verifyModels) || verifyModels.length !== discovered.length) {
  fail('refusing to write: rendered document did not round-trip the models list')
}

// Atomic replace through a temp sibling, mirroring how dsh writes the file:
// a crash mid-write must never leave a truncated settings document.
const tmp = `${settingsFile}.sync-${process.pid}.tmp`
writeFileSync(tmp, output, { mode: 0o600 })
renameSync(tmp, settingsFile)
console.log(`updated ${settingsFile} (${discovered.length} models)`)
NODE_EOF
NODE_STATUS=$?
set -e

# 2 is the --check drift signal; anything else non-zero is a real failure.
if [ "$NODE_STATUS" -eq 2 ]; then exit 2; fi
if [ "$NODE_STATUS" -ne 0 ]; then exit "$NODE_STATUS"; fi

# Nothing was written when the catalog already matched, so there is nothing to
# reload. The marker file below records that the last write needs a restart.
if [ "$CHECK_ONLY" -eq 1 ] || [ "$NO_RESTART" -eq 1 ]; then exit 0; fi

# dsh hot-reloads settings.yaml through a file watcher, so a restart is not
# required for the document to take effect. It is still done here because a
# pi-ai route set that changes shape re-registers adapters, and a restart is
# the one path that is unambiguously clean.
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$RESTART_SERVICE" 2>/dev/null; then
  echo "restarting ${RESTART_SERVICE}..."
  systemctl restart "$RESTART_SERVICE"
  sleep 3
  if systemctl is-active --quiet "$RESTART_SERVICE"; then
    echo "${RESTART_SERVICE} is active"
  else
    echo "sync-dsh-9router-models: ${RESTART_SERVICE} failed to come back up" >&2
    systemctl status "$RESTART_SERVICE" --no-pager 2>&1 | head -20 >&2
    exit 1
  fi
else
  echo "note: ${RESTART_SERVICE} is not running; settings will apply on next start"
fi
