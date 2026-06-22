#!/usr/bin/env bash
# 중간에 실패하거나 정의되지 않은 변수를 사용하면 스크립트 종료
set -euo pipefail

# apt 비대화모드 + 기본  패키지 설치
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# agent-app.zip 배포와 압축해제
log_info "deploy app zip from repository"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ZIP_PATH="$(find "${REPO_DIR}" -maxdepth 3 -type f -name 'agent-app.zip' | head -n 1 || true)"

if [ -n "${ZIP_PATH}" ]; then
  cp "${ZIP_PATH}" "/home/${AGENT_USER}/agent-app.zip"
  chown "${AGENT_USER}:${AGENT_CORE_GROUP}" "/home/${AGENT_USER}/agent-app.zip"
  sudo -u "${AGENT_USER}" unzip -o "/home/${AGENT_USER}/agent-app.zip" -d "${AGENT_HOME}"
  chown -R "${AGENT_USER}:${AGENT_CORE_GROUP}" "${AGENT_HOME}"
  find "${AGENT_HOME}" -maxdepth 2 -type f -name 'agent-app-linux-*' -exec chmod 755 {} \;
  log_info "app deployed"
else
  log_warn "agent-app.zip not found, skip deploy"
fi

log_info "provisioning complete"