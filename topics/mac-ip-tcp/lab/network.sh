#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
STATE=/run/scg-mac-ip-tcp-lab
A=scg-mit-a
R=scg-mit-r
B=scg-mit-b

usage() {
  cat <<'HELP'
SCG MAC/IP/TCP lab (Linux only)
Usage: lab.sh up|down|inspect|same|routed|sockets|refused|timeout-demo
       lab.sh capture a|r-left|r-right|b
       lab.sh serve echo|hold|reset
       network.sh client|hops|test
       network.sh shell a|b|r
       network.sh help
Run from a Nix shell with:
  lab() { sudo env "PATH=$PATH" bash ./lab.sh "$@"; }
All networking changes are inside three lab-owned namespaces.
HELP
}
[[ ${1:-help} != help && ${1:-help} != --help ]] || { usage; exit 0; }
[[ $(uname -s) == Linux ]] || { echo 'BLOCKED: use a Linux VM; Nix on macOS is not a Linux kernel.' >&2; exit 2; }
[[ $EUID == 0 ]] || { echo 'BLOCKED: use the documented sudo lab() wrapper.' >&2; exit 2; }
command -v ip >/dev/null || { echo 'Missing ip: enter nix develop.' >&2; exit 2; }

namespace_present() {
  local names name
  names=$(ip netns list) || return 2
  while read -r name; do
    [[ ${name%% *} != "$1" ]] || return 0
  done <<< "$names"
  return 1
}

need_lab() {
  [[ -d $STATE ]] || { echo 'Run lab up first.' >&2; exit 2; }
  [[ -f $STATE/ready ]] || { echo 'Incomplete setup: run lab down, then lab up.' >&2; exit 2; }
  for ns in "$A" "$R" "$B"; do
    [[ -f $STATE/$ns ]] && ip -n "$ns" link show lo >/dev/null || {
      echo "Incomplete lab ($ns). Run lab down, then lab up." >&2; exit 2;
    }
  done
}

cleanup() {
  [[ -d $STATE ]] || { echo 'No owned lab state; nothing removed.'; return 0; }
  local ns pid pids rc failed=0
  for ns in "$A" "$R" "$B"; do
    [[ -f $STATE/$ns || ${owned_pending:-} == "$ns" ]] || continue
    if namespace_present "$ns"; then
      if pids=$(ip netns pids "$ns"); then
        for pid in $pids; do kill -TERM "$pid" 2>/dev/null || true; done
        sleep 0.2
        if pids=$(ip netns pids "$ns"); then
          for pid in $pids; do kill -KILL "$pid" 2>/dev/null || true; done
        else
          echo "Cannot inspect remaining processes in $ns; state retained." >&2
          failed=1
          continue
        fi
      else
        echo "Cannot inspect processes in $ns; state retained." >&2
        failed=1
        continue
      fi
      if ! ip netns delete "$ns"; then failed=1; fi
    else
      rc=$?
      if (( rc != 1 )); then failed=1; fi
    fi
  done
  if (( failed )); then
    echo 'Cleanup incomplete. State retained; retry lab down.' >&2
    return 3
  fi
  rm -rf -- "$STATE"
  echo 'Removed lab-owned namespaces. Host routes/firewall were not changed.'
}

case ${1:-} in
  up)
    for tool in ping tcpdump node iptables timeout ss traceroute; do
      command -v "$tool" >/dev/null || { echo "Missing $tool: enter nix develop." >&2; exit 2; }
    done
    [[ ! -e $STATE ]] || { echo 'Lab state exists. If ready use lab inspect; otherwise run lab down, then lab up.' >&2; exit 2; }
    for ns in "$A" "$R" "$B"; do
      if namespace_present "$ns"; then
        echo "Namespace collision: $ns. Nothing changed; do not delete an unowned namespace." >&2
        exit 2
      else
        rc=$?
        [[ $rc == 1 ]] || { echo 'Cannot list network namespaces.' >&2; exit 2; }
      fi
    done
    mkdir -- "$STATE"
    owned_pending=
    rollback_setup() {
      local rc=$?
      trap - EXIT
      trap '' INT TERM HUP
      echo 'Setup interrupted or failed; rolling back owned resources.' >&2
      cleanup || exit 3
      (( rc != 0 )) || rc=2
      exit "$rc"
    }
    trap rollback_setup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    for ns in "$A" "$R" "$B"; do
      ip netns add "$ns"
      owned_pending=$ns
      touch "$STATE/$ns"
      owned_pending=
      ip -n "$ns" link set lo up
    done
    # veth endpoints are created directly in lab namespaces, not the host.
    ip -n "$A" link add eth0 type veth peer name left0 netns "$R"
    ip -n "$R" link add right0 type veth peer name eth0 netns "$B"
    ip -n "$A" addr add 10.77.1.2/24 dev eth0
    ip -n "$R" addr add 10.77.1.1/24 dev left0
    ip -n "$R" addr add 10.77.2.1/24 dev right0
    ip -n "$B" addr add 10.77.2.2/24 dev eth0
    ip -n "$A" link set eth0 up
    ip -n "$R" link set left0 up
    ip -n "$R" link set right0 up
    ip -n "$B" link set eth0 up
    ip -n "$A" route add default via 10.77.1.1
    ip -n "$B" route add default via 10.77.2.1
    ip netns exec "$R" bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
    touch "$STATE/ready"
    trap - EXIT INT TERM HUP
    echo 'READY: A 10.77.1.2 -> R 10.77.1.1 / 10.77.2.1 -> B 10.77.2.2'
    ;;
  down) cleanup ;;
  inspect)
    need_lab
    for ns in "$A" "$R" "$B"; do
      printf '\n=== %s: addresses / routes / neighbours ===\n' "$ns"
      ip -n "$ns" -br -4 addr
      ip -n "$ns" -4 route
      ip -n "$ns" -4 neigh
    done
    printf '\n=== A route lookup: same link ===\n'
    ip -n "$A" route get 10.77.1.1
    printf '\n=== A route lookup: routed destination ===\n'
    ip -n "$A" route get 10.77.2.2
    ;;
  same)
    need_lab
    # Only flush A's lab-owned cache, never a host interface.
    ip -n "$A" neigh flush dev eth0 >/dev/null
    ip netns exec "$A" ping -n -c 3 -W 1 10.77.1.1
    ;;
  routed)
    need_lab
    ip -n "$A" neigh flush dev eth0 >/dev/null
    ip -n "$R" neigh flush dev right0 >/dev/null
    ip netns exec "$A" ping -n -c 3 -W 1 10.77.2.2
    ;;
  capture)
    need_lab
    case ${2:-} in
      a) ns=$A; iface=eth0 ;;
      r-left) ns=$R; iface=left0 ;;
      r-right) ns=$R; iface=right0 ;;
      b) ns=$B; iface=eth0 ;;
      *) echo 'capture expects a|r-left|r-right|b' >&2; exit 2 ;;
    esac
    echo "Capture $ns/$iface for at most 60 seconds. Ctrl+C to stop."
    set +e
    ip netns exec "$ns" timeout --signal=INT 60 tcpdump --immediate-mode -l -nn -e -vv -i "$iface" 'arp or icmp or (tcp port 18080)'
    rc=$?
    set -e
    [[ $rc == 0 || $rc == 124 || $rc == 130 ]] || exit "$rc"
    ;;
  shell)
    need_lab
    case ${2:-} in a) ns=$A ;; b) ns=$B ;; r) ns=$R ;; *) echo 'Choose a, b, or r.' >&2; exit 2 ;; esac
    exec ip netns exec "$ns" env PC_ROLE="${2}" LAB_DIR="$BASE" bash --noprofile --rcfile "$BASE/engine/pc.bash" -i
    ;;
  test)
    need_lab
    exec bash "$BASE/engine/integration.sh"
    ;;
  hops)
    need_lab
    exec ip netns exec "$A" traceroute -n -I -m 5 -w 1 10.77.2.2
    ;;
  serve)
    need_lab
    case ${2:-echo} in echo|hold|reset) ;; *) echo 'serve expects echo|hold|reset' >&2; exit 2 ;; esac
    exec ip netns exec "$B" node "$BASE/engine/endpoint.mjs" server 10.77.2.2 18080 "${2:-echo}"
    ;;
  client)
    need_lab
    exec ip netns exec "$A" node "$BASE/engine/endpoint.mjs" client 10.77.2.2 18080
    ;;
  sockets)
    need_lab
    for ns in "$A" "$B"; do
      printf '\n=== %s TCP sockets ===\n' "$ns"
      ip netns exec "$ns" ss -tan
    done
    ;;
  refused)
    need_lab
    listening=$(ip netns exec "$B" ss -H -ltn 'sport = :18080')
    [[ -z $listening ]] || { echo 'Stop lab serve first (Ctrl+C in its terminal).' >&2; exit 2; }
    echo 'No B:18080 listener. Expected result: CONNECT_ERROR ECONNREFUSED (exit 1).'
    exec ip netns exec "$A" node "$BASE/engine/endpoint.mjs" client 10.77.2.2 18080
    ;;
  timeout-demo)
    need_lab
    mkdir "$STATE/drop-active" 2>/dev/null || { echo 'Timeout demo active or stale dirty marker. Stop it; if stale run lab down, then lab up.' >&2; exit 2; }
    inserted=0
    remove_drop() {
      local original_rc=$? attempt removed=0
      trap - EXIT
      trap '' INT TERM HUP
      if (( inserted )); then
        for attempt in 1 2 3; do
          if ip netns exec "$R" iptables -w 2 -D FORWARD -s 10.77.1.2 -d 10.77.2.2 -p tcp --dport 18080 -m comment --comment scg-mit-timeout -j DROP; then
            removed=1
            break
          fi
          echo "DROP cleanup retry $attempt/3" >&2
          sleep 0.2
        done
        if (( ! removed )); then
          echo 'CLEANUP_ERROR: temporary DROP may remain. Run lab down before continuing. Dirty marker retained.' >&2
          exit 3
        fi
      fi
      rmdir "$STATE/drop-active" || exit 3
      exit "$original_rc"
    }
    trap remove_drop EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    ip netns exec "$R" iptables -w 2 -I FORWARD 1 -s 10.77.1.2 -d 10.77.2.2 -p tcp --dport 18080 -m comment --comment scg-mit-timeout -j DROP
    inserted=1
    echo 'Only R forwarding A -> B TCP:18080 is temporarily dropped.'
    echo 'Expected: CONNECT_TIMEOUT; this is the client application deadline, not the kernel TCP retransmission limit.'
    ip netns exec "$A" node "$BASE/engine/endpoint.mjs" client 10.77.2.2 18080
    ;;
  *) usage >&2; exit 2 ;;
esac
