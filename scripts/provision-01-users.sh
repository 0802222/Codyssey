#!/usr/bin/env bash
# 중간에 실패하거나 정의되지 않은 변수를 사용하면 스크립트 종료
set -euo pipefail

# apt 비대화모드 + 기본  패키지 설치
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_info "apt update / upgrade"
apt-get update -y
apt-get upgrade -y

log_info "install base packages"
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
  git

log_info "ensure cron enabled"
systemctl enable cron
systemctl restart cron

# 사용자, 그룹, 디렉터리, 권한 설정
log_info "create groups"
getent group "${AGENT_COMMON_GROUP}" >/dev/null || groupadd "${AGENT_COMMON_GROUP}"
getent group "${AGENT_CORE_GROUP}"   >/dev/null || groupadd "${AGENT_CORE_GROUP}"

log_info "create users"
id -u "${AGENT_USER}"      >/dev/null 2>&1 || useradd -m -s /bin/bash "${AGENT_USER}"
id -u "${AGENT_DEV_USER}"  >/dev/null 2>&1 || useradd -m -s /bin/bash "${AGENT_DEV_USER}"
id -u "${AGENT_TEST_USER}" >/dev/null 2>&1 || useradd -m -s /bin/bash "${AGENT_TEST_USER}"

log_info "add users to groups"
usermod -aG "${AGENT_COMMON_GROUP},${AGENT_CORE_GROUP}" "${AGENT_USER}"
usermod -aG "${AGENT_COMMON_GROUP},${AGENT_CORE_GROUP}" "${AGENT_DEV_USER}"
usermod -aG "${AGENT_COMMON_GROUP}"                     "${AGENT_TEST_USER}"

log_info "create directories"
mkdir -p "${UPLOAD_DIR}" "${AGENT_KEY_DIR}" "${BIN_DIR}" "${LOG_DIR}"

log_info "set ownership & basic perms"
chown -R "${AGENT_USER}:${AGENT_CORE_GROUP}" "${AGENT_HOME}"
chown -R "${AGENT_USER}:${AGENT_CORE_GROUP}" "${LOG_DIR}"

chgrp "${AGENT_COMMON_GROUP}" "${UPLOAD_DIR}"
chgrp "${AGENT_CORE_GROUP}"   "${AGENT_KEY_DIR}" "${BIN_DIR}" "${LOG_DIR}"

chmod 770 "${UPLOAD_DIR}"
chmod 750 "${AGENT_KEY_DIR}" "${BIN_DIR}"
chmod 770 "${LOG_DIR}"

log_info "set ACL"
setfacl -m "g:${AGENT_COMMON_GROUP}:rwx" "${UPLOAD_DIR}"
setfacl -m "g:${AGENT_CORE_GROUP}:rwx"   "${AGENT_KEY_DIR}"
setfacl -m "g:${AGENT_CORE_GROUP}:rwx"   "${LOG_DIR}"

log_info "create key file (secret.key)"
echo "agent_api_key_test" > "${AGENT_KEY_DIR}/secret.key"
chown "${AGENT_USER}:${AGENT_CORE_GROUP}" "${AGENT_KEY_DIR}/secret.key"
chmod 640 "${AGENT_KEY_DIR}/secret.key"

log_info "create env file"
cat >/etc/profile.d/agent-app.sh <<EOF
export AGENT_HOME=${AGENT_HOME}
export AGENT_PORT=${APP_PORT}
export AGENT_UPLOAD_DIR=${UPLOAD_DIR}
export AGENT_KEY_PATH=${AGENT_KEY_DIR}
export AGENT_LOG_DIR=${AGENT_LOG_DIR}
EOF
chmod 644 /etc/profile.d/agent-app.sh