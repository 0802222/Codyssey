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
  python3-pip

echo "[INFO] ensure cron enabled"
systemctl enable cron
systemctl restart cron

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
export AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys/secret.key
export AGENT_LOG_DIR=/var/log/agent-app
EOF
chmod 644 /etc/profile.d/agent-app.sh

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

echo "[INFO] create monitor.sh template (if not exists)"
if [ ! -f "${BIN_DIR}/monitor.sh" ]; then
  cat > "${BIN_DIR}/monitor.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
LOG_FILE="${LOG_DIR}/monitor.log"
APP_PORT="${AGENT_PORT:-15034}"
APP_PROC="agent-app-linux-x86"

mkdir -p "${LOG_DIR}"

echo "====== SYSTEM MONITOR RESULT ======"

echo
echo "[HEALTH CHECK]"
PID="$(pgrep -f "${APP_PROC}" | head -n 1 || true)"
if [ -z "${PID}" ]; then
  echo "[ERROR] ${APP_PROC} process not found"
  exit 1
fi
echo "Checking process '${APP_PROC}'... [OK] (PID: ${PID})"

if ! ss -tuln | grep -q ":${APP_PORT} "; then
  echo "[ERROR] port ${APP_PORT} not listening"
  exit 1
fi
echo "Checking port ${APP_PORT}... [OK]"

echo
echo "[RESOURCE MONITORING]"
CPU_IDLE_LINE="$(LANG=C top -bn1 | awk '/Cpu\(s\)/ {print}')"
CPU_IDLE="$(echo "${CPU_IDLE_LINE}" | awk -F',' '{for(i=1;i<=NF;i++){if($i ~ /id/){print $i}}}' | awk '{print $1}')"
CPU_USAGE=$(awk "BEGIN {printf \"%.1f\", 100 - ${CPU_IDLE}}")

MEM_USAGE=$(free | awk '/Mem:/ {printf \"%.1f\", $3/$2*100}')
DISK_USED=$(df -P / | awk 'NR==2 {gsub(\"%\",\"\",$5); print $5}')

echo "CPU Usage : ${CPU_USAGE}%"
echo "MEM Usage : ${MEM_USAGE}%"
echo "DISK Used : ${DISK_USED}%"

if ! ufw status | grep -q "Status: active"; then
  echo
  echo "[WARNING] UFW is inactive"
fi

if awk "BEGIN {exit !(${CPU_USAGE} > 20)}"; then
  echo "[WARNING] CPU threshold exceeded (${CPU_USAGE}% > 20%)"
fi
if awk "BEGIN {exit !(${MEM_USAGE} > 10)}"; then
  echo "[WARNING] MEM threshold exceeded (${MEM_USAGE}% > 10%)"
fi
if awk "BEGIN {exit !(${DISK_USED} > 80)}"; then
  echo "[WARNING] DISK threshold exceeded (${DISK_USED}% > 80%)"
fi

mkdir -p "${LOG_DIR}"
printf "[%s] PID:%s CPU:%.1f%% MEM:%s%% DISK_USED:%s%%\n" \
  "$(date '+%F %T')" "${PID}" "${CPU_USAGE}" "${MEM_USAGE}" "${DISK_USED}" >> "${LOG_FILE}"

echo
echo "[INFO] Log appended: ${LOG_FILE}"
EOF
fi

chown agent-dev:agent-core "${BIN_DIR}/monitor.sh"
chmod 750 "${BIN_DIR}/monitor.sh"

echo "[INFO] register cron for agent-admin"
TMP_CRON="$(mktemp)"
crontab -u agent-admin -l 2>/dev/null | grep -v 'monitor.sh' > "${TMP_CRON}" || true
echo "* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/monitor.cron.log 2>&1" >> "${TMP_CRON}"
crontab -u agent-admin "${TMP_CRON}"
rm -f "${TMP_CRON}"

echo "[INFO] deploy app zip from repository"
REPO_DIR="/home/c08022220523/Codyssey"
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

