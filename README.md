# Network Port Restarter Script

This shell script provides a command-line interface to interact with a network device API. It allows you to discover network sites and devices, and most importantly, to remotely power cycle (restart) a specific port on a device.

## Features

- **List Network Sites**: Discover all available sites managed by the API.
- **List Devices**: List all devices within a specific site.
- **Restart Port**: Send a `POWER_CYCLE` command to a specific port on a device.
- **Interactive Confirmation**: Includes a safety prompt to prevent accidental port restarts.
- **Automation-Friendly**: The confirmation prompt can be bypassed with a `--no-check` flag, making it suitable for automated scripts or cron jobs.
- **Flexible Configuration**: Uses default values for common actions but allows overriding with command-line arguments.
- **Secure API Key Handling**: Prioritizes using an environment variable for the API key to avoid hardcoding secrets.

## Prerequisites

Before running this script, you need to have the following command-line tools installed:

- `bash`
- `curl`
- `jq` (for parsing and pretty-printing JSON responses)

You can typically install `jq` using a package manager like Homebrew (`brew install jq`) or `apt` (`sudo apt-get install jq`).

## Configuration

### 1. API Key (Recommended)

For security, it is strongly recommended to provide the API key via an environment variable. This prevents the secret key from being saved in your shell history or committed to version control.

```sh
export MY_API_KEY="your-secret-api-key-here"
```

### 2. Default Values

The script contains the provision for default values for the `HOST`, `SITE_ID`, `DEVICE_ID`, and `PORT_IDX` at the top of the file. You can modify these to fit your most common use case.

```shellscript
# --- Configuration ---
HOST=""
DEFAULT_SITE_ID=""
DEFAULT_DEVICE_ID=""
DEFAULT_PORT_IDX=
```

## Usage

First, make the script executable:
```sh
chmod +x restart_port.sh
```

### Display Help

To see all available commands and options:
```sh
./restart_port.sh --help
```

### Example Workflow

A typical workflow involves discovering the required IDs and then executing the action.

**1. List all sites to find the `site_id`:**
```sh
./restart_port.sh --list-sites
```

**2. List devices in that site to find the `device_id`:**
```sh
# Replace <site_id> with the ID from the previous step
./restart_port.sh --list-devices <site_id>
```

**3. Restart a specific port (with confirmation):**
```sh
# Replace with the correct IDs and desired port number
./restart_port.sh --restart-port <site_id> <device_id> 15
```
The script will ask for confirmation: `Are you sure you want to POWER_CYCLE port 15...? (y/N)`

### Other Commands

**Restart the Default Port**

If you run the script without any commands, it will use the `DEFAULT_` variables defined in the configuration section.
```sh
./restart_port.sh
```

**Restart a Port without Confirmation (for automation)**

Use the `--no-check` flag to bypass the interactive prompt.
```sh
./restart_port.sh --restart-port <site_id> <device_id> 15 --no-check
```