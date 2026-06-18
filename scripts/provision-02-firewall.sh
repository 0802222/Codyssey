#!/usr/bin/env bash
# 중간에 실패하거나 정의되지 않은 변수를 사용하면 스크립트 종료
set -euo pipefail

# apt 비대화모드 + 기본  패키지 설치
export DEBIAN_FRONTEND=noninteractive

# SSH, 방화벽
echo "[INFO] configure sshd (Port 20022, no root login)"
SSHD_CONFIG="/etc/ssh/sshd_config"

if grep -qE '^[#]*Port ' "${SSHD_CONFIG}"; then
  sed -i 's/^[#]*Port .*/Port 20022/' "${SSHD_CONFIG}"
else
  echo "Port 20022" >> "${SSHD_CONFIG}"
fi

if grep -qE '^[#]*PermitRootLogin ' "${SSHD_CONFIG}"; then
  sed -i 's/^[#]*PermitRootLogin .*/PermitRootLogin no/' "${SSHD_CONFIG}"
else
  echo "PermitRootLogin no" >> "${SSHD_CONFIG}"
fi

systemctl restart ssh || systemctl restart sshd

echo "[INFO] configure UFW"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 20022/tcp
ufw allow 15034/tcp
ufw --force enable