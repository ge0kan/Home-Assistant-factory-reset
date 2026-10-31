#!/command/with-contenv bashio
set -Eeuo pipefail

readonly SUPERVISOR_URL="http://supervisor"
readonly EXPECTED_CONFIRMATION="ERASE ALL DATA"
readonly APP_DATA_DIR="${APP_DATA_DIR:-/data}"
readonly ATTEMPT_MARKER="${APP_DATA_DIR}/wipe-requested"

confirmation="$(bashio::config 'confirmation')"

bashio::log.warning "This app PERMANENTLY erases all Home Assistant OS user data."

if [[ "${confirmation}" != "${EXPECTED_CONFIRMATION}" ]]; then
    bashio::log.info "Safe mode: wipe NOT requested. Enter exactly ERASE ALL DATA in the confirmation field, save, then manually start the app."
    exit 0
fi

if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
    bashio::log.error "Supervisor token is missing; refusing to proceed."
    exit 1
fi

if [[ -e "${ATTEMPT_MARKER}" ]]; then
    bashio::log.error "A wipe request was already attempted. No repeat request will be sent."
    bashio::log.error "If the system did not reset, inspect logs and reinstall the app before another attempt."
    exit 1
fi

bashio::log.info "Checking Home Assistant OS and Supervisor access..."
if ! os_info="$(curl --fail --silent --show-error --connect-timeout 5 --max-time 15 \
    --header "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    "${SUPERVISOR_URL}/os/info")"; then
    bashio::log.error "Unable to query Home Assistant OS; refusing to wipe."
    exit 1
fi

if ! printf '%s' "${os_info}" | jq --exit-status '.result == "ok" and (.data.version | type == "string")' >/dev/null; then
    bashio::log.error "Unexpected Supervisor OS response; refusing to wipe."
    exit 1
fi

os_version="$(printf '%s' "${os_info}" | jq --raw-output '.data.version')"
bashio::log.info "Home Assistant OS version: ${os_version}."

# Prevent repeated destructive requests after a container restart or lost response.
mkdir -p "${APP_DATA_DIR}"
printf 'Wipe requested once. Reinstall app to retry after investigation.\n' > "${ATTEMPT_MARKER}"

bashio::log.warning "Sending irreversible wipe request. Home Assistant may disconnect immediately."
if response="$(curl --fail --silent --show-error --connect-timeout 5 --max-time 30 \
    --request POST \
    --header "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    "${SUPERVISOR_URL}/os/datadisk/wipe")"; then
    bashio::log.warning "Supervisor acknowledged the wipe request. Wait for HAOS to reboot and reinstall Home Assistant."
else
    bashio::log.error "The connection failed or closed while sending the wipe request."
    bashio::log.error "The wipe MAY still have started. Check the host before retrying."
    exit 1
fi
