#!/usr/bin/env bash
# Sync the 9router model catalog into the Pi Coding Agent custom-models file.
#
# ~/.pi/agent/models.json declares 9router as a custom OpenAI-compatible
# provider (docs/models.md): pi has no built-in catalog for it, so every
# model id, context window, and output cap is hand-listed and goes stale
# whenever 9router gains, drops, or resizes an upstream model. This script
# re-reads GET /v1/models and rewrites ONLY providers["9router"].models,
# leaving every other provider (opencode-zen-free, ...) and every other
# field on the 9router provider (baseUrl, apiKey, compat) untouched.
#
# pi reloads models.json itself each time /model opens (see docs/models.md,
# "The file reloads each time you open /model"), so no service restart is
# needed or attempted here.
#
# Idempotent: a run that finds no drift exits 0 without touching the file.
# Fail-loud: any unreachable endpoint, malformed payload, or unparsable
# document aborts before writing.
#
# Exit codes:
#   0  in sync (no write) or updated successfully
#   1  error (endpoint, parsing, or write failure)
#   2  drift detected while running with --check
set -euo pipefail

BASE_URL="${NINEROUTER_BASE_URL:-http://localhost:20128/v1}"
MODELS_FILE="${PI_MODELS_FILE:-$HOME/.pi/agent/models.json}"
PROVIDER="${PI_9ROUTER_PROVIDER:-9router}"

CHECK_ONLY=0
QUIET=0

usage() {
  cat <<'USAGE'
Usage: sync-pi-9router-models.sh [options]

Options:
  --check      Report drift and exit 2 without writing anything.
  --quiet      Only print on drift or error.
  -h, --help   Show this help.

Environment:
  NINEROUTER_BASE_URL   9router OpenAI-compatible base URL
                        (default: http://localhost:20128/v1)
  PI_MODELS_FILE        custom-models document path
                        (default: ~/.pi/agent/models.json)
  PI_9ROUTER_PROVIDER   provider key under "providers" (default: 9router)
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "sync-pi-9router-models: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

command -v node >/dev/null 2>&1 || {
  echo "sync-pi-9router-models: node not found in PATH" >&2
  exit 1
}

set +e
NINEROUTER_BASE_URL="$BASE_URL" \
PI_MODELS_FILE="$MODELS_FILE" \
PI_9ROUTER_PROVIDER="$PROVIDER" \
SYNC_CHECK_ONLY="$CHECK_ONLY" \
SYNC_QUIET="$QUIET" \
node --input-type=module <<'NODE_EOF'
import { readFileSync, writeFileSync, renameSync } from 'node:fs'

const baseURL = process.env.NINEROUTER_BASE_URL.replace(/\/+$/, '')
const modelsFile = process.env.PI_MODELS_FILE
const providerKey = process.env.PI_9ROUTER_PROVIDER
const checkOnly = process.env.SYNC_CHECK_ONLY === '1'
const quiet = process.env.SYNC_QUIET === '1'

const log = (...args) => { if (!quiet) console.log(...args) }
const fail = (msg) => { console.error(`sync-pi-9router-models: ${msg}`); process.exit(1) }

// ── naming: mirrors the hand-written labels already in the file ────────────
// "cx/gpt-5.5" -> "GPT 5.5 (9Router/Codex)"; "bai/claude-opus-4.7" ->
// "Claude Opus 4.7 (9Router/BAI)". Falls back to an upper-cased owner tag
// for a prefix this map does not yet know.
const OWNER_LABELS = { cc: 'CC', ps: 'PS', kgw: 'KGW', cx: 'Codex' }
const ACRONYMS = { gpt: 'GPT' }
const humanizeToken = (token) => {
  const lower = token.toLowerCase()
  if (ACRONYMS[lower] !== undefined) return ACRONYMS[lower]
  return token.length === 0 ? token : token.charAt(0).toUpperCase() + token.slice(1)
}
const buildName = (id) => {
  const [owner, ...restParts] = id.split('/')
  const rest = restParts.join('/')
  const words = rest.split(/[/\-:]+/).filter(Boolean).map(humanizeToken).join(' ')
  const label = OWNER_LABELS[owner] ?? owner.toUpperCase()
  return `${words} (9Router/${label})`
}

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
if (entries.length === 0) fail(`${baseURL}/models returned an empty catalog; refusing to blank the provider`)
for (const entry of entries) {
  if (typeof entry?.id !== 'string' || entry.id.length === 0) {
    fail(`${baseURL}/models returned an entry with no usable 'id'`)
  }
}

const DEFAULT_CONTEXT_WINDOW = 128000
const DEFAULT_MAX_TOKENS = 16384
const positive = (...candidates) => {
  for (const value of candidates) {
    if (typeof value === 'number' && Number.isInteger(value) && value > 0) return value
  }
  return undefined
}

// Model-config building is deferred until after step 2 reads the current
// document: an id already present keeps its hand-tuned `name` verbatim, and
// only a genuinely new id gets a generated one (see below).

// ── 2. read the models.json document ────────────────────────────────────────
let text
try {
  text = readFileSync(modelsFile, 'utf8')
} catch (error) {
  if (error.code === 'ENOENT') fail(`${modelsFile} does not exist; create the ${providerKey} provider first`)
  fail(`cannot read ${modelsFile}: ${error.message}`)
}

let doc
try {
  doc = JSON.parse(text)
} catch (error) {
  fail(`${modelsFile} is not valid JSON: ${error.message}`)
}

const provider = doc?.providers?.[providerKey]
if (provider === undefined) fail(`${modelsFile} has no providers.${providerKey} entry to update`)
if (!Array.isArray(provider.models)) fail(`providers.${providerKey}.models is not a list`)

// Existing hand-tuned names ("XS", "4.5" with the dot kept) beat the
// generated heuristic: a model already in the file keeps its current `name`
// verbatim, and only a genuinely new id gets a generated one.
const existingNames = new Map(
  provider.models.filter((m) => typeof m?.id === 'string' && typeof m?.name === 'string').map((m) => [m.id, m.name]),
)

const discovered = entries.map((entry) => {
  const vision = entry.capabilities?.vision === true
  return {
    id: entry.id,
    name: existingNames.get(entry.id) ?? buildName(entry.id),
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    reasoning: entry.capabilities?.reasoning === true,
    input: vision ? ['text', 'image'] : ['text'],
    contextWindow: positive(entry.context_length, entry.capabilities?.contextWindow) ?? DEFAULT_CONTEXT_WINDOW,
    maxTokens: positive(entry.max_completion_tokens, entry.capabilities?.maxOutput) ?? DEFAULT_MAX_TOKENS,
  }
}).sort((a, b) => a.id.localeCompare(b.id))

// ── 3. diff (id + every model-config field we own) ──────────────────────────
const current = provider.models
  .filter((m) => typeof m?.id === 'string')
  .map((m) => ({
    id: m.id,
    name: m.name,
    reasoning: m.reasoning,
    input: Array.isArray(m.input) ? [...m.input].sort().join(',') : '',
    contextWindow: m.contextWindow,
    maxTokens: m.maxTokens,
  }))
  .sort((a, b) => a.id.localeCompare(b.id))

const key = (m) => [
  m.id, m.name, m.reasoning,
  Array.isArray(m.input) ? [...m.input].sort().join(',') : m.input,
  m.contextWindow, m.maxTokens,
].join('\u0000')

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
  log(`9router models already in sync in ${modelsFile} (${discovered.length} models)`)
  process.exit(0)
}

console.log(`9router model drift detected in ${modelsFile}:`)
if (added.length > 0) console.log(`  + added   (${added.length}): ${added.join(', ')}`)
if (removed.length > 0) console.log(`  - removed (${removed.length}): ${removed.join(', ')}`)
if (changed.length > 0) console.log(`  ~ changed (${changed.length}): ${changed.join(', ')}`)

if (checkOnly) {
  console.log('(--check: no changes written)')
  process.exit(2)
}

// ── 4. rewrite only this provider's models array ────────────────────────────
// A removed model that a session still references keeps working until pi
// reloads models.json (which happens on the next /model open); this script
// never touches settings.json's defaultModel, so a stale default just stops
// resolving instead of silently pointing at a different model.
provider.models = discovered
const output = `${JSON.stringify(doc, null, 2)}\n`

// Re-parse before committing: a document pi cannot load must never reach
// disk, mirroring the guard used for the dsh settings sync.
let verify
try {
  verify = JSON.parse(output)
} catch (error) {
  fail(`refusing to write invalid JSON: ${error.message}`)
}
const verifyModels = verify?.providers?.[providerKey]?.models
if (!Array.isArray(verifyModels) || verifyModels.length !== discovered.length) {
  fail('refusing to write: rendered document did not round-trip the models list')
}

const tmp = `${modelsFile}.sync-${process.pid}.tmp`
writeFileSync(tmp, output, { mode: 0o644 })
renameSync(tmp, modelsFile)
console.log(`updated ${modelsFile} (${discovered.length} models); reopen /model in pi to pick it up`)
NODE_EOF
NODE_STATUS=$?
set -e

exit "$NODE_STATUS"
