#!/usr/bin/env bash
# 중간에 실패하거나 정의되지 않은 변수를 사용하면 스크립트 종료
set -euo pipefail

# apt 비대화모드 + 기본  패키지 설치
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# SSH, 방화벽
log_info "configure sshd (Port ${SSH_PORT}, no root login)"
SSHD_CONFIG="/etc/ssh/sshd_config"

if grep -qE '^[#]*Port ' "${SSHD_CONFIG}"; then
  sed -i "s/^[#]*Port .*/Port ${SSH_PORT}/" "${SSHD_CONFIG}"
else
  echo "Port ${SSH_PORT}" >> "${SSHD_CONFIG}"
fi

if grep -qE '^[#]*PermitRootLogin ' "${SSHD_CONFIG}"; then
  sed -i 's/^[#]*PermitRootLogin .*/PermitRootLogin no/' "${SSHD_CONFIG}"
else
  echo "PermitRootLogin no" >> "${SSHD_CONFIG}"
fi

# ssh 재시작 전 문법체크
sshd -t

# ssh 재시작
systemctl restart ssh || systemctl restart sshd

log_info "configure UFW"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}/tcp"
ufw allow "${APP_PORT}/tcp"
ufw --force enable