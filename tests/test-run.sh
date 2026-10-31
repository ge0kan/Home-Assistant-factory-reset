#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

# Mock bashio and curl: no real HTTP requests, never a real wipe.
bashio::config() {
    if [[ "$1" == "confirmation" ]]; then
        printf '%s' "${MOCK_CONFIRMATION}"
    else
        echo "Unexpected option: $1" >&2
        return 1
    fi
}
bashio::log.info() { printf 'INFO: %s\n' "$*"; }
bashio::log.warning() { printf 'WARN: %s\n' "$*"; }
bashio::log.error() { printf 'ERROR: %s\n' "$*"; }

curl() {
    if [[ "$*" == *"/os/info"* ]]; then
        printf '%s\n' "${MOCK_OS_INFO}"
    elif [[ "$*" == *"/os/datadisk/wipe"* ]]; then
        printf 'POST\n' >> "${MOCK_REQUEST_LOG}"
        if [[ "${MOCK_POST_FAIL:-false}" == "true" ]]; then
            return 22
        fi
        printf '%s\n' '{"result":"ok"}'
    else
        printf 'Unexpected curl call: %s\n' "$*" >&2
        return 99
    fi
}

run_test() { ( source "${ROOT}/factory_reset/run.sh" ); }
fail() { echo "FAIL: $*" >&2; exit 1; }
assert_posts() {
    local expected="$1" actual=0
    if [[ -f "${MOCK_REQUEST_LOG}" ]]; then
        actual="$(wc -l < "${MOCK_REQUEST_LOG}")"
    fi
    [[ "${actual}" -eq "${expected}" ]] || fail "expected ${expected} requests, found ${actual}"
}
reset_attempt() { rm -f "${APP_DATA_DIR}/wipe-requested"; }

export APP_DATA_DIR="${TEMP_DIR}/data"
export SUPERVISOR_TOKEN="fake-test-token"
export MOCK_REQUEST_LOG="${TEMP_DIR}/requests.log"
export MOCK_OS_INFO='{"result":"ok","data":{"version":"18.0","board":"rpi4-64"}}'
export MOCK_CONFIRMATION="NOT ARMED"
mkdir -p "${APP_DATA_DIR}"

run_test >/dev/null
assert_posts 0
echo "PASS 1: safe default does not wipe"

MOCK_CONFIRMATION="ERASE ALL DATA "
run_test >/dev/null
assert_posts 0
echo "PASS 2: near-match confirmation is rejected"

MOCK_CONFIRMATION="ERASE ALL DATA"
run_test >/dev/null
assert_posts 1
[[ -f "${APP_DATA_DIR}/wipe-requested" ]] || fail "marker missing"
echo "PASS 3: exact phrase requests wipe once"

if run_test >/dev/null 2>&1; then fail "repeated start succeeded"; fi
assert_posts 1
echo "PASS 4: repeated start blocked"

reset_attempt
unset SUPERVISOR_TOKEN
if run_test >/dev/null 2>&1; then fail "missing token accepted"; fi
assert_posts 1
echo "PASS 5: missing Supervisor token blocked"
export SUPERVISOR_TOKEN="fake-test-token"

MOCK_OS_INFO='{"result":"error","message":"OS unavailable"}'
if run_test >/dev/null 2>&1; then fail "invalid OS response accepted"; fi
assert_posts 1
[[ ! -f "${APP_DATA_DIR}/wipe-requested" ]] || fail "marker created for invalid preflight"
echo "PASS 6: invalid HAOS preflight blocked"

MOCK_OS_INFO='{"result":"ok","data":{"version":"18.0","board":"generic-x86-64"}}'
run_test >/dev/null
assert_posts 2
echo "PASS 7: amd64 board accepted"

reset_attempt
MOCK_OS_INFO='{"result":"ok","data":{"version":"18.0","board":"rpi3-64"}}'
run_test >/dev/null
assert_posts 3
echo "PASS 8: different ARM64 board accepted"

reset_attempt
MOCK_OS_INFO='{"result":"ok","data":{"version":"18.0"}}'
run_test >/dev/null
assert_posts 4
echo "PASS 9: missing optional board field accepted"

reset_attempt
MOCK_POST_FAIL=true
if run_test >/dev/null 2>&1; then fail "failed request returned success"; fi
assert_posts 5
[[ -f "${APP_DATA_DIR}/wipe-requested" ]] || fail "marker missing after uncertain POST"
echo "PASS 10: failed request is not retried without investigation"
