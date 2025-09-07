#!/bin/bash
#
# Script to interact with a network device API.
# Can list sites, list devices, or restart a specific device port.
#

# --- Configuration ---
HOST="10.0.0.1"
# Default values for the restart action if no arguments are provided.
DEFAULT_SITE_ID="x"
DEFAULT_DEVICE_ID="x"
DEFAULT_PORT_IDX=x

# --- API Key Configuration ---
# WARNING: Hardcoding API keys is a security risk.
# It is strongly recommended to use the environment variable method.
# To use the environment variable, run: export MY_API_KEY="your-secret-key"
#HARDCODED_API_KEY="x"

if [ -n "$MY_API_KEY" ]; then
    API_KEY="$MY_API_KEY"
else
    echo "Warning: Using hardcoded API key. This is insecure." >&2
    API_KEY="$HARDCODED_API_KEY"
fi

if [ -z "$API_KEY" ]; then
    echo "Error: API key is not set. Please set MY_API_KEY or HARDCODED_API_KEY." >&2
    exit 1
fi

# --- Functions ---

usage() {
    cat <<EOF
Usage: $0 [command]

A script to interact with the network device API to list resources or restart a port.

Commands:
  --list-sites                      List all available sites.
  --list-devices <site_id>          List all devices for a given site.
  --restart-port [<site_id> <device_id> <port_idx>]
                                    Restarts a port. Uses defaults if no args are given.
  --help                            Show this help message.

Options:
  --no-check                        Skip the interactive confirmation before restarting a port.

If no command is provided, it will restart port ${DEFAULT_PORT_IDX} on device ${DEFAULT_DEVICE_ID}
at site ${DEFAULT_SITE_ID} using the default configuration.
EOF
}

list_sites() {
    echo "Fetching all sites..."
    local api_url="https://${HOST}/proxy/network/integration/v1/sites"
    curl -k -s -X GET "${api_url}" \
         -H "X-API-KEY: ${API_KEY}" \
         -H "Accept: application/json" | jq
}

list_devices() {
    local site_id="$1"
    if [ -z "$site_id" ]; then
        echo "Error: Site ID is required to list devices." >&2
        usage
        exit 1
    fi
    echo "Fetching devices for site ID: ${site_id}..."
    local api_url="https://${HOST}/proxy/network/integration/v1/sites/${site_id}/devices"
    curl -k -s -X GET "${api_url}" \
         -H "X-API-KEY: ${API_KEY}" \
         -H "Accept: application/json" | jq
}

restart_port() {
    local site_id="$1"
    local device_id="$2"
    local port_idx="$3"
    if [ -z "$site_id" ] || [ -z "$device_id" ] || [ -z "$port_idx" ]; then
        echo "Error: Site ID, Device ID, and Port Index are required." >&2
        usage
        exit 1
    fi

    # Confirm with the user before proceeding, unless --no-check is used or not in a TTY
    if [ "$CONFIRM_ACTION" = true ] && [ -t 0 ]; then
        read -p "Are you sure you want to POWER_CYCLE port ${port_idx} on device ${device_id}? (y/N) " -n 1 -r
        echo # Move to a new line
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation aborted by user."
            exit 0
        fi
    fi

    echo "Sending POWER_CYCLE command to port ${port_idx} on device ${device_id}..."
    local api_url="https://${HOST}/proxy/network/integration/v1/sites/${site_id}/devices/${device_id}/interfaces/ports/${port_idx}/actions"
    local payload='{"action": "POWER_CYCLE"}'

    curl -k -s -X POST "${api_url}" \
         -H "Content-Type: application/json" \
         -H "X-API-KEY: ${API_KEY}" \
         -d "${payload}"
    echo # Add a newline for cleaner output
}

# --- Main Logic ---

CONFIRM_ACTION=true
COMMAND=""
ARGS=()

# Parse all arguments to handle commands and options in any order
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list-sites|--list-devices|--restart-port|--help)
      if [ -n "$COMMAND" ]; then
        echo "Error: Only one command can be specified." >&2
        usage
        exit 1
      fi
      COMMAND="$1"
      shift # consume command
      ;;
    --no-check)
      CONFIRM_ACTION=false
      shift # consume --no-check
      ;;
    -*)
      echo "Error: Unknown option '$1'" >&2
      usage
      exit 1
      ;;
    *)
      # Assume it's an argument for the command
      ARGS+=("$1")
      shift # consume argument
      ;;
  esac
done

# If no command was given, default to the restart action
if [ -z "$COMMAND" ]; then
    COMMAND="--restart-port"
fi

case "$COMMAND" in
    --list-sites) list_sites ;;
    --list-devices) list_devices "${ARGS[0]}" ;;
    --restart-port)
        if [ ${#ARGS[@]} -eq 0 ]; then
            restart_port "$DEFAULT_SITE_ID" "$DEFAULT_DEVICE_ID" "$DEFAULT_PORT_IDX"
        else
            restart_port "${ARGS[0]}" "${ARGS[1]}" "${ARGS[2]}"
        fi
        ;;
    --help) usage ;;
esac
