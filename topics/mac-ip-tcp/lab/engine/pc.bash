# Interactive shell setup for the mac-ip-tcp network-namespace lab.
# The parent launcher supplies PC_ROLE and LAB_DIR.

unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history

NODE_BIN=${NODE_BIN:-node}
ENDPOINT="$LAB_DIR/engine/endpoint.mjs"
PORT=18080

case "${PC_ROLE:-}" in
  a)
    PC_NAME=PC-A
    IFACE=eth0
    SELF=10.77.1.2
    PEER=10.77.2.2
    ;;
  b)
    PC_NAME=PC-B
    IFACE=eth0
    SELF=10.77.2.2
    PEER=10.77.1.2
    ;;
  r)
    PC_NAME=R
    IFACE=right0
    SELF=10.77.2.1
    PEER=10.77.2.2
    ;;
  *)
    printf 'pc.bash: PC_ROLE must be a, b, or r\n' >&2
    return 2
    ;;
esac

if [[ $PC_ROLE == r ]]; then
  PS1='[router R 10.77.1.1|10.77.2.1] \$ '
else
  PS1="[$PC_NAME $SELF] \\$ "
fi
PS2='> '

lab-help() {
  cat <<EOF
Commands:
  lab-help                 show this help
  routes [target]          addresses, routes, and route lookup (default: $PEER)
  neighbors                ARP/neighbor cache
  hops [target]            ICMP traceroute, max 5 hops (default: $PEER)
  sniff [target]           foreground packet capture for ARP/ICMP/TCP $PORT
  capture-start            background capture, so two terminals are enough
  capture-stop             stop owned background capture and print its log
  drop-demo                scoped connect-timeout demo (run on PC-A)
  listen [echo|hold|reset] listen on $SELF:$PORT (default: echo)
  send [text]              connect to $PEER:$PORT and send text
  ping-peer                send 3 ICMP echo requests to $PEER

This shell runs in a Linux network namespace. It shares the host kernel and is
not a separate physical PC. Ctrl-C stops foreground listen/sniff commands.
Set LAB_TIMEOUT_MS before send to change the client deadline (default: 2000 ms).
EOF
}

routes() {
  local target=${1:-$PEER}
  printf '%s\n' '--- IPv4 addresses ---'
  ip -br -4 addr
  printf '%s\n' '--- routes ---'
  ip route show
  printf '%s\n' "--- route get $target ---"
  ip route get "$target"
}

neighbors() {
  ip neigh show
}

hops() {
  local target=${1:-$PEER}
  traceroute -n -I -m 5 -w 1 "$target"
}

sniff() {
  local target=${1:-$PEER}
  printf 'Capturing traffic involving %s (ARP, ICMP, or TCP port %s). Ctrl-C stops.\n' "$target" "$PORT"
  tcpdump --immediate-mode -l -i "$IFACE" -nn -e -vv "arp or icmp or (host $target and tcp port $PORT)"
}

listen() {
  local mode=${1:-echo}
  case "$mode" in
    echo|hold|reset) ;;
    *)
      printf 'usage: listen [echo|hold|reset]\n' >&2
      return 2
      ;;
  esac
  "$NODE_BIN" "$ENDPOINT" server "$SELF" "$PORT" "$mode"
}

send() {
  if (($#)); then
    "$NODE_BIN" "$ENDPOINT" client "$PEER" "$PORT" "$*"
  else
    "$NODE_BIN" "$ENDPOINT" client "$PEER" "$PORT"
  fi
}

ping-peer() {
  ping -n -c 3 -W 1 "$PEER"
}

printf '\n%s namespace shell: self=%s peer=%s\n' "$PC_NAME" "$SELF" "$PEER"
printf '%s\n' 'Shared host kernel, isolated network namespace; this is not a physical PC.'
printf '%s\n\n' 'Run lab-help for commands.'

CAPTURE_PID=
CAPTURE_LOG=
capture-start() {
  if [[ -n $CAPTURE_PID ]] && kill -0 "$CAPTURE_PID" 2>/dev/null; then
    printf 'Capture already running. Run capture-stop first.\n'
    return 2
  fi
  mkdir -p "$LAB_DIR/.state/captures"
  CAPTURE_LOG="$LAB_DIR/.state/captures/$PC_NAME-$(date -u +%Y%m%dT%H%M%SZ).txt"
  tcpdump --immediate-mode -l -i "$IFACE" -nn -e -vv "arp or icmp or tcp port $PORT" > "$CAPTURE_LOG" 2>&1 &
  CAPTURE_PID=$!
  local count
  for count in 1 2 3 4 5 6 7 8 9 10; do
    if grep -q 'listening on' "$CAPTURE_LOG"; then
      printf 'Capture ready: %s (PID %s). Run capture-stop to read it.\n' "$CAPTURE_LOG" "$CAPTURE_PID"
      return 0
    fi
    kill -0 "$CAPTURE_PID" 2>/dev/null || { cat "$CAPTURE_LOG"; CAPTURE_PID=; return 1; }
    sleep 0.1
  done
  printf 'Capture startup timed out. Run capture-stop.\n' >&2
  return 1
}
capture-stop() {
  if [[ -n $CAPTURE_PID ]]; then
    kill -INT "$CAPTURE_PID" 2>/dev/null || true
    wait "$CAPTURE_PID" 2>/dev/null || true
    CAPTURE_PID=
  fi
  [[ -z $CAPTURE_LOG ]] || cat "$CAPTURE_LOG"
}
drop-demo() {
  [[ $PC_ROLE == a ]] || { printf 'Run drop-demo on PC-A.\n' >&2; return 2; }
  bash "$LAB_DIR/network.sh" timeout-demo
}
trap capture-stop EXIT
