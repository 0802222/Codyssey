#!/usr/bin/env bash
# 중간에 실패하거나 정의되지 않은 변수를 사용하면 스크립트 종료
set -euo pipefail

# apt 비대화모드 + 기본  패키지 설치
export DEBIAN_FRONTEND=noninteractive

echo "[INFO] apt update / upgrade"
apt-get update -y
apt-get upgrade -y

echo "[INFO] install base packages"
apt-get install -y \
  nano \
  openssh-server \
  ufw \
  cron \
  iproute2 \
  net-tools \
  acl \
  sudo \
  curl \
  unzip \
  python3 \
  python3-pip \
  git

echo "[INFO] ensure cron enabled"
systemctl enable cron
systemctl restart cron

# 사용자, 그룹, 디렉터리, 권한 설정
echo "[INFO] create groups"
getent group agent-common >/dev/null || groupadd agent-common
getent group agent-core   >/dev/null || groupadd agent-core

echo "[INFO] create users"
id -u agent-admin >/dev/null 2>&1 || useradd -m -s /bin/bash agent-admin
id -u agent-dev   >/dev/null 2>&1 || useradd -m -s /bin/bash agent-dev
id -u agent-test  >/dev/null 2>&1 || useradd -m -s /bin/bash agent-test

echo "[INFO] add users to groups"
usermod -aG agent-common,agent-core agent-admin
usermod -aG agent-common,agent-core agent-dev
usermod -aG agent-common           agent-test

AGENT_HOME="/home/agent-admin/agent-app"
UPLOAD_DIR="${AGENT_HOME}/upload_files"
KEY_DIR="${AGENT_HOME}/api_keys"
BIN_DIR="${AGENT_HOME}/bin"
LOG_DIR="/var/log/agent-app"

echo "[INFO] create directories"
mkdir -p "${UPLOAD_DIR}" "${KEY_DIR}" "${BIN_DIR}" "${LOG_DIR}"

echo "[INFO] set ownership & basic perms"
chown -R agent-admin:agent-core "${AGENT_HOME}"
chown -R agent-admin:agent-core "${LOG_DIR}"

chgrp agent-common "${UPLOAD_DIR}"
chgrp agent-core   "${KEY_DIR}" "${BIN_DIR}" "${LOG_DIR}"

chmod 770 "${UPLOAD_DIR}"
chmod 750 "${KEY_DIR}" "${BIN_DIR}"
chmod 770 "${LOG_DIR}"

echo "[INFO] set ACL"
setfacl -m g:agent-common:rwx "${UPLOAD_DIR}"
setfacl -m g:agent-core:rwx   "${KEY_DIR}"
setfacl -m g:agent-core:rwx   "${LOG_DIR}"

echo "[INFO] create key file (secret.key)"
echo "agent_api_key_test" > "${KEY_DIR}/secret.key"
chown agent-admin:agent-core "${KEY_DIR}/secret.key"
chmod 640 "${KEY_DIR}/secret.key"

echo "[INFO] create env file"
cat >/etc/profile.d/agent-app.sh <<'EOF'
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=/home/agent-admin/agent-app/upload_files
export AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys
export AGENT_LOG_DIR=/var/log/agent-app
EOF
chmod 644 /etc/profile.d/agent-app.sh