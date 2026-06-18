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

# SSH, 방화벽, 모니터링
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

AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
LOG_FILE="${AGENT_LOG_DIR}/monitor.log"
APP_NAME="agent-app-linux-x86"
APP_PORT="${AGENT_PORT:-15034}"

CPU_THRESHOLD=20
MEM_THRESHOLD=10
DISK_THRESHOLD=80

MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
MAX_FILES=10


timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

mkdir -p "${AGENT_LOG_DIR}"

# 1. 헬스 체크 - 프로세스
APP_PID="$(pgrep -f "${APP_NAME}" | head -n 1 || true)"
if [ -z "${APP_PID:-}" ]; then
  echo "====== SYSTEM MONITOR RESULT ======"
  echo
  echo "[HEALTH CHECK]"
  echo "[ERROR] Process '${APP_NAME}' not running"
  exit 1
fi

# 2. 헬스 체크 - 포트
if ! ss -tuln | grep -q ":$APP_PORT "; then
  echo "====== SYSTEM MONITOR RESULT ======"
  echo
  echo "[HEALTH CHECK]"
  echo "[ERROR] Port ${APP_PORT} is not listening"
  exit 1
fi

# 3. 경고 체크 - 방화벽 활성화 여부
FIREWALL_WARNING=""
FIREWALL_STATUS="unknown"

if command -v ufw >/dev/null 2>&1; then
  UFW_STATUS="$(sudo /usr/sbin/ufw status 2>&1 || true)"

  if echo "$UFW_STATUS" | grep -q "Status: active"; then
    FIREWALL_STATUS="active"
  elif echo "$UFW_STATUS" | grep -qi "sudo"; then
    FIREWALL_STATUS="permission denied"
    FIREWALL_WARNING="[INFO] UFW status check failed (sudo permission required)"
  else
    FIREWALL_STATUS="inactive"
    FIREWALL_WARNING="[WARNING] UFW is inactive"
  fi

elif command -v firewall-cmd >/dev/null 2>&1; then
  FWD_STATUS="$(sudo firewall-cmd --state 2>&1 || true)"

  if echo "$FWD_STATUS" | grep -q "running"; then
    FIREWALL_STATUS="active"
  elif echo "$FWD_STATUS" | grep -qi "sudo"; then
    FIREWALL_STATUS="permission denied"
    FIREWALL_WARNING="[INFO] firewalld status check failed (sudo permission required)"
  else
    FIREWALL_STATUS="inactive"
    FIREWALL_WARNING="[WARNING] firewalld is inactive"
  fi

else
  FIREWALL_STATUS="not found"
  FIREWALL_WARNING="[WARNING] No firewall tool detected"
fi

# 4. 자원 수집 - CPU 사용률
CPU_IDLE_LINE="$(LANG=C top -bn1 | awk '/Cpu\(s\)/ {print}')"
CPU_IDLE="$(echo "${CPU_IDLE_LINE}" | awk -F',' '{for(i=1;i<=NF;i++){if($i ~ /id/){print $i}}}' | awk '{print $1}')"
CPU_USAGE="$(awk "BEGIN {printf \"%.1f\", 100 - ${CPU_IDLE}}")"

# 4. 자원 수집 - 메모리 사용률
MEM_USAGE="$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')"

# 4. 자원 수집 - 디스크 사용률 (/ 기준)
DISK_USAGE="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"

# 5. 임계값 경고
RESOURCE_WARNINGS=""

if awk "BEGIN {exit !(${CPU_USAGE} > ${CPU_THRESHOLD})}"; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] CPU threshold exceeded (${CPU_USAGE}% > ${CPU_THRESHOLD}%)\n"
fi

if awk "BEGIN {exit !(${MEM_USAGE} > ${MEM_THRESHOLD})}"; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] MEM threshold exceeded (${MEM_USAGE}% > ${MEM_THRESHOLD}%)\n"
fi

if awk "BEGIN {exit !(${DISK_USAGE} > ${DISK_THRESHOLD})}"; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] DISK threshold exceeded (${DISK_USAGE}% > ${DISK_THRESHOLD}%)\n"
fi

# 6. 로그 기록
printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' \
  "${timestamp}" "${APP_PID}" "${CPU_USAGE}" "${MEM_USAGE}" "${DISK_USAGE}" >> "${LOG_FILE}"

# 7. 로그 롤링 (최대 10MB / 10개 파일 유지)

if [ -f "${LOG_FILE}" ]; then
  CURRENT_SIZE="$(stat -c%s "${LOG_FILE}")"
  if [ "${CURRENT_SIZE}" -gt "${MAX_SIZE}" ]; then
    TS="$(date '+%Y%m%d%H%M%S')"
    mv "${LOG_FILE}" "${AGENT_LOG_DIR}/monitor.log.${TS}"
    touch "${LOG_FILE}"
  fi
fi

mapfile -t LOG_ROLLED_FILES < <(ls -1t "${AGENT_LOG_DIR}"/monitor.log.* 2>/dev/null || true)
COUNT="${#LOG_ROLLED_FILES[@]}"

if [ "${COUNT}" -gt "${MAX_FILES}" ]; then
  for ((i=MAX_FILES; i<COUNT; i++)); do
    rm -f "${LOG_ROLLED_FILES[$i]}"
  done
fi

# 8. 콘솔 출력
echo "====== SYSTEM MONITOR RESULT ======"
echo
echo "[HEALTH CHECK]"
echo "Checking process '${APP_NAME}'... [OK] (PID: ${APP_PID})"
echo "Checking port ${APP_PORT}... [OK]"
echo
echo "[RESOURCE MONITORING]"
echo "CPU Usage : ${CPU_USAGE}%"
echo "MEM Usage : ${MEM_USAGE}%"
echo "DISK Used : ${DISK_USAGE}%"
echo
echo "Firewall : ${FIREWALL_STATUS}"
echo

if [ -n "$FIREWALL_WARNING" ]; then
  echo "$FIREWALL_WARNING"
fi

if [ -n "$RESOURCE_WARNINGS" ]; then
  printf "%b" "$RESOURCE_WARNINGS"
fi

echo
echo "[INFO] Log appended: $LOG_FILE"
EOF
  chown agent-dev:agent-core "${BIN_DIR}/monitor.sh"
  chmod 750 "${BIN_DIR}/monitor.sh"
fi



echo "[INFO] register cron for agent-admin"
TMP_CRON="$(mktemp)"
crontab -u agent-admin -l 2>/dev/null | grep -v 'monitor.sh' > "${TMP_CRON}" || true
echo "* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/monitor.cron.log 2>&1" >> "${TMP_CRON}"
crontab -u agent-admin "${TMP_CRON}"
rm -f "${TMP_CRON}"

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

