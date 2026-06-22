AGENT_USER="${AGENT_USER:-agent-admin}"
AGENT_DEV_USER="${AGENT_DEV_USER:-agent-dev}"
AGENT_TEST_USER="${AGENT_TEST_USER:-agent-test}"

AGENT_COMMON_GROUP="${AGENT_COMMON_GROUP:-agent-common}"
AGENT_CORE_GROUP="${AGENT_CORE_GROUP:-agent-core}"

AGENT_HOME="${AGENT_HOME:-/home/${AGENT_USER}/agent-app}"
BIN_DIR="${BIN_DIR:-${AGENT_HOME}/bin}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
LOG_FILE="${LOG_FILE:-${AGENT_LOG_DIR}/monitor.log}"

UPLOAD_DIR="${UPLOAD_DIR:-${AGENT_HOME}/upload_files}"
AGENT_KEY_DIR="${AGENT_KEY_DIR:-${AGENT_HOME}/api_keys}"
LOG_DIR="${AGENT_LOG_DIR}"

APP_NAME="${APP_NAME:-agent-app-linux-x86}"
APP_PORT="${APP_PORT:-15034}"
SSH_PORT="${SSH_PORT:-20022}"

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}