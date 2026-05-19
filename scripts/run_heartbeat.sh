#!/bin/bash
# run_heartbeat.sh - Hermes agent heartbeat/health check script
# Runs periodically to ensure the Hermes agent process is alive
# and optionally pings the service endpoint.

set -euo pipefail

HERMES_DIR="/opt/hermes"
LOG_FILE="${HERMES_DIR}/logs/heartbeat.log"
HERMES_URL="${HERMES_URL:-http://localhost:8000}"
MAX_RETRIES=3
RETRY_DELAY=5

mkdir -p "${HERMES_DIR}/logs"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

check_health() {
  local retries=0
  while [ "${retries}" -lt "${MAX_RETRIES}" ]; do
    if curl -sf --max-time 10 "${HERMES_URL}/health" > /dev/null 2>&1; then
      return 0
    fi
    retries=$((retries + 1))
    log "Health check attempt ${retries}/${MAX_RETRIES} failed. Retrying in ${RETRY_DELAY}s..."
    sleep "${RETRY_DELAY}"
  done
  return 1
}

log "Running heartbeat check..."

if check_health; then
  log "Heartbeat OK - Hermes agent is healthy at ${HERMES_URL}"
  exit 0
else
  log "ERROR: Hermes agent at ${HERMES_URL} is not responding after ${MAX_RETRIES} attempts."
  exit 1
fi
