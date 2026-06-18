#!/usr/bin/env bash
# 중간에 실패하거나 정의되지 않은 변수를 사용하면 스크립트 종료
set -euo pipefail

# apt 비대화모드 + 기본  패키지 설치
export DEBIAN_FRONTEND=noninteractive

# agent-app.zip 배포와 압축해제
echo "[INFO] deploy app zip from repository"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ZIP_PATH="$(find "${REPO_DIR}" -maxdepth 3 -type f -name 'agent-app.zip' | head -n 1 || true)"

if [ -n "${ZIP_PATH}" ]; then
  cp "${ZIP_PATH}" /home/agent-admin/agent-app.zip
  chown agent-admin:agent-admin /home/agent-admin/agent-app.zip
  sudo -u agent-admin unzip -o /home/agent-admin/agent-app.zip -d "${AGENT_HOME}"
  chown -R agent-admin:agent-core "${AGENT_HOME}"
  find "${AGENT_HOME}" -maxdepth 2 -type f -name 'agent-app-linux-*' -exec chmod 755 {} \;
  echo "[INFO] app deployed"
else
  echo "[WARNING] agent-app.zip not found, skip deploy"
fi

echo "[INFO] provisioning complete"

