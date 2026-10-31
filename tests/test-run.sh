#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

# Mock Bashio and curl. The tests never make an actual API call.
bashio::config() {
    case "$1" in
        execute) printf '%s' "${MOCK_EXECUTE}" ;;
        confirmation) printf '%s' "${MOCK_CONFIRMATION}" ;;
    esac
}
bashio::log.info() { printf 'INFO: %s\n' "$*"; }
bashio::log.warning() { printf 'WARN: %s\n' "$*"; }
bashio::log.error() { printf 'ERROR: %s\n' "$*"; }

curl() {
    if [[ "$*" == *"/os/info"* ]]; then
        printf '%s\n' '{"result":"ok","data":{"version":"18.0","board":"rpi4-64"}}'
    elif [[ "$*" == *"/os/datadisk/wipe"* ]]; then
        printf 'POST\n' >> "${MOCK_REQUEST_LOG}"
        printf '%s\n' '{"result":"ok"}'
    else
        printf 'Unexpected curl call: %s\n' "$*" >&2
        return 99
    fi
}

run_test() {
    ( source "${ROOT}/factory_reset/run.sh" )
}

export APP_DATA_DIR="${TEMP_DIR}/data"
export SUPERVISOR_TOKEN='not-a-real-token'
export MOCK_REQUEST_LOG="${TEMP_DIR}/requests.log"
mkdir -p "${APP_DATA_DIR}"

MOCK_EXECUTE='false'; MOCK_CONFIRMATION='ERASE ALL DATA'
run_test >/dev/null
test ! -f "${MOCK_REQUEST_LOG}"
echo 'PASS: execute=false does not wipe'

MOCK_EXECUTE='true'; MOCK_CONFIRMATION='NOT ARMED'
run_test >/dev/null
test ! -f "${MOCK_REQUEST_LOG}"
echo 'PASS: wrong confirmation does not wipe'

MOCK_EXECUTE='true'; MOCK_CONFIRMATION='ERASE ALL DATA'
run_test >/dev/null
test "$(wc -l < "${MOCK_REQUEST_LOG}")" -eq 1
test -f "${APP_DATA_DIR}/wipe-requested"
echo 'PASS: armed startup sends exactly one wipe request'

if run_test >/dev/null 2>&1; then
    echo 'FAIL: repeat armed startup unexpectedly succeeded' >&2
    exit 1
fi
test "$(wc -l < "${MOCK_REQUEST_LOG}")" -eq 1
echo 'PASS: repeated startup sends no new requests'

rm -f "${APP_DATA_DIR}/wipe-requested"
unset SUPERVISOR_TOKEN
if run_test >/dev/null 2>&1; then
    echo 'FAIL: missing token unexpectedly succeeded' >&2
    exit 1
fi
test "$(wc -l < "${MOCK_REQUEST_LOG}")" -eq 1
echo 'PASS: missing token does not wipe'

export SUPERVISOR_TOKEN='not-a-real-token'
MOCK_EXECUTE='true'; MOCK_CONFIRMATION='Erase All Data'
run_test >/dev/null
test "$(wc -l < "${MOCK_REQUEST_LOG}")" -eq 1
echo 'PASS: confirmation must match exactly'

curl() {
    if [[ "$*" == *"/os/info"* ]]; then
        printf '%s\n' '{"result":"error","message":"OS unavailable"}'
    elif [[ "$*" == *"/os/datadisk/wipe"* ]]; then
        echo 'FAIL: no POST after invalid preflight' >&2
        return 99
    fi
}
MOCK_EXECUTE='true'; MOCK_CONFIRMATION='ERASE ALL DATA'
if run_test >/dev/null 2>&1; then
    echo 'FAIL: invalid preflight unexpectedly succeeded' >&2
    exit 1
fi
test "$(wc -l < "${MOCK_REQUEST_LOG}")" -eq 1
test ! -f "${APP_DATA_DIR}/wipe-requested"
echo 'PASS: failed OS preflight prevents wipe'

curl() {
    if [[ "$*" == *"/os/info"* ]]; then
        printf '%s\n' '{"result":"ok","data":{"version":"18.0","board":"rpi3-64"}}'
    elif [[ "$*" == *"/os/datadisk/wipe"* ]]; then
        echo 'FAIL: no POST for wrong board' >&2
        return 99
    fi
}
if run_test >/dev/null 2>&1; then
    echo 'FAIL: wrong-board preflight unexpectedly succeeded' >&2
    exit 1
fi
test "$(wc -l < "${MOCK_REQUEST_LOG}")" -eq 1
test ! -f "${APP_DATA_DIR}/wipe-requested"
echo 'PASS: wrong Raspberry Pi board prevents wipe'
