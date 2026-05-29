#!/usr/bin/env bash

set -u

AGENT_HOME="/home/agent-admin/agent-app"
AGENT_LOG_DIR="/var/log/agent-app"
LOG_FILE="$AGENT_LOG_DIR/monitor.log"
APP_NAME="agent-app-linux-x86"
APP_PORT="15034"

CPU_THRESHOLD=20
MEM_THRESHOLD=10
DISK_THRESHOLD=80

timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

# 1. 헬스 체크 - 프로세스
APP_PID="$(pgrep -f "$APP_NAME" | head -n 1)"
if [ -z "${APP_PID:-}" ]; then
  echo "[HEALTH CHECK] Process '$APP_NAME' not running. exit 1"
  exit 1
fi

# 1. 헬스 체크 - 포트
if ! ss -tuln | grep -q ":$APP_PORT "; then
  echo "[HEALTH CHECK] Port $APP_PORT is not listening. exit 1"
  exit 1
fi

# 2. 경고 체크 - 방화벽 활성화 여부
FIREWALL_WARNING=""

if command -v ufw >/dev/null 2>&1; then
  UFW_STATUS="$(sudo /usr/sbin/ufw status 2>/dev/null || true)"

  if echo "$UFW_STATUS" | grep -q "Status: active"; then
    :
  else
    FIREWALL_WARNING="[WARNING] UFW is inactive"
  fi

elif command -v firewall-cmd >/dev/null 2>&1; then
  if ! firewall-cmd --state 2>/dev/null | grep -q "running"; then
    FIREWALL_WARNING="[WARNING] firewalld is inactive"
  fi

else
  FIREWALL_WARNING="[WARNING] No firewall tool detected"
fi

# 3. 자원 수집 - CPU 사용률
CPU_USAGE="$(top -bn1 | awk -F'id,' '/Cpu\(s\)/ {split($1, a, ","); gsub(/[^0-9.]/, "", a[length(a)]); printf "%.0f", 100 - a[length(a)]}')"

# 3. 자원 수집 - 메모리 사용률
MEM_USAGE="$(free | awk '/Mem:/ {printf "%.0f", ($3 / $2) * 100}')"

# 3. 자원 수집 - 디스크 사용률 (/ 기준)
DISK_USAGE="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"

# 4. 임계값 경고
RESOURCE_WARNINGS=""

if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] CPU threshold exceeded (${CPU_USAGE}% > ${CPU_THRESHOLD}%)\n"
fi

if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] MEM threshold exceeded (${MEM_USAGE}% > ${MEM_THRESHOLD}%)\n"
fi

if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] DISK threshold exceeded (${DISK_USAGE}% > ${DISK_THRESHOLD}%)\n"
fi

# 5. 로그 기록
mkdir -p "$AGENT_LOG_DIR"

printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' \
  "$timestamp" "$APP_PID" "$CPU_USAGE" "$MEM_USAGE" "$DISK_USAGE" >> "$LOG_FILE"

# 콘솔 출력
echo "====== SYSTEM MONITOR RESULT ======"
echo
echo "[HEALTH CHECK]"
echo "Checking process '$APP_NAME'... [OK] (PID: $APP_PID)"
echo "Checking port $APP_PORT... [OK]"
echo
echo "[RESOURCE MONITORING]"
echo "CPU Usage : ${CPU_USAGE}%"
echo "MEM Usage : ${MEM_USAGE}%"
echo "DISK Used : ${DISK_USAGE}%"
echo

if [ -n "$FIREWALL_WARNING" ]; then
  echo "$FIREWALL_WARNING"
fi

if [ -n "$RESOURCE_WARNINGS" ]; then
  printf "%b" "$RESOURCE_WARNINGS"
fi

echo
echo "[INFO] Log appended: $LOG_FILE"