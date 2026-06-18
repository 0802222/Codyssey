#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/provision-01-users.sh"
bash "${SCRIPT_DIR}/provision-02-firewall.sh"
bash "${SCRIPT_DIR}/provision-03-monitor.sh"
bash "${SCRIPT_DIR}/provision-04-deploy-app.sh"