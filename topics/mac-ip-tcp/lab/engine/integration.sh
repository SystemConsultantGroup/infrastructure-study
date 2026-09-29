#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
A=scg-mit-a; B=scg-mit-b
REPORT="$BASE/.state/test-results/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$REPORT"
exec > >(tee "$REPORT/result.log") 2>&1
server_pid=; capture_pid=; route_removed=0
cleanup() {
  local rc=$?
  trap - EXIT
  trap '' INT TERM HUP
  if [[ -n $capture_pid ]]; then kill -INT "$capture_pid" 2>/dev/null || true; wait "$capture_pid" 2>/dev/null || true; fi
  if [[ -n $server_pid ]]; then kill -TERM "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi
  if (( route_removed )); then ip -n "$A" route replace default via 10.77.1.1 || exit 3; fi
  echo "Report: $REPORT"
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
pass() { printf '\nPASS %s\n' "$*"; }
fail() { printf '\nFAIL %s\n' "$*" >&2; exit 1; }
expect_client() {
  local pattern=$1 expected=$2 output rc
  set +e
  output=$(ip netns exec "$A" node "$BASE/engine/endpoint.mjs" client 10.77.2.2 18080 2>&1)
  rc=$?
  set -e
  printf '%s\n' "$output"
  [[ $rc == "$expected" ]] || fail "exit $rc expected $expected"
  printf '%s\n' "$output" | grep -F "$pattern" >/dev/null || fail "missing $pattern"
}
start_server() {
  local mode=$1 i
  ip netns exec "$B" node "$BASE/engine/endpoint.mjs" server 10.77.2.2 18080 "$mode" > "$REPORT/server-$mode.log" 2>&1 &
  server_pid=$!
  for i in $(seq 1 60); do
    if grep -q '^LISTEN ' "$REPORT/server-$mode.log"; then return 0; fi
    kill -0 "$server_pid" 2>/dev/null || { cat "$REPORT/server-$mode.log"; fail 'server exited'; }
    sleep 0.05
  done
  fail 'server readiness timeout'
}
stop_server() {
  kill -TERM "$server_pid"
  wait "$server_pid" || true
  server_pid=
}
[[ -z $(ip netns exec "$B" ss -H -ltn 'sport = :18080') ]] || fail 'Stop B listen/server before ./lab test. No existing process was changed.'
[[ ! -e /run/scg-mac-ip-tcp-lab/drop-active ]] || fail 'Timeout demo active/dirty. Stop it or rebuild the lab first.'
echo "Actual Linux integration run: $(date -u); $(uname -sm)"
bash "$BASE/network.sh" inspect

ip netns exec "$A" ping -n -c 2 -W 1 10.77.1.1
pass 'same-link ICMP A -> R'
ip netns exec "$A" ping -n -c 2 -W 1 10.77.2.2
pass 'routed ICMP A -> B'
ip netns exec "$B" ping -n -c 2 -W 1 10.77.1.2
pass 'reverse ICMP B -> A'
ip -n "$A" route get 10.77.2.2 | tee "$REPORT/route.txt"
grep -F 'via 10.77.1.1' "$REPORT/route.txt" >/dev/null || fail 'unexpected next hop'
pass 'route chooses R'
ip netns exec "$A" traceroute -n -I -m 5 -w 1 10.77.2.2 | tee "$REPORT/hops.txt"
grep -E '^ *1 +10\.77\.1\.1' "$REPORT/hops.txt" >/dev/null || fail 'router hop missing'
grep -E '^ *2 +10\.77\.2\.2' "$REPORT/hops.txt" >/dev/null || fail 'destination hop missing'
pass 'TTL probes show R then B'

ip netns exec "$A" mtr -n -r -c 2 -i 0.2 10.77.2.2 | tee "$REPORT/mtr.txt"
grep -F 10.77.1.1 "$REPORT/mtr.txt" >/dev/null || fail 'mtr router hop missing'
grep -F 10.77.2.2 "$REPORT/mtr.txt" >/dev/null || fail 'mtr destination missing'
pass 'standard mtr shows router and destination'
set +e
ttl_output=$(ip netns exec "$A" ping -n -c 1 -W 1 -t 1 10.77.2.2 2>&1)
rc=$?
set -e
printf '%s\n' "$ttl_output"
[[ $rc != 0 ]] || fail 'TTL=1 unexpectedly reached B'
printf '%s\n' "$ttl_output" | grep -F 'Time to live exceeded' >/dev/null || fail 'ICMP time-exceeded missing'
pass 'standard ping TTL=1 receives ICMP time exceeded'

# Exercise the actual nc/ss commands taught in README, not just the Node helpers.
ip netns exec "$A" tcpdump --immediate-mode -U -nn -i eth0 -w "$REPORT/nc-handshake.pcap" 'tcp port 18080' 2> "$REPORT/nc-capture.log" &
capture_pid=$!
for i in $(seq 1 60); do
  grep -q 'listening on' "$REPORT/nc-capture.log" && break
  kill -0 "$capture_pid" 2>/dev/null || fail 'nc capture exited'
  sleep 0.05
done
grep -q 'listening on' "$REPORT/nc-capture.log" || fail 'nc capture readiness timeout'
printf 'reply-from-B\n' | ip netns exec "$B" nc -N -l 10.77.2.2 18080 > "$REPORT/nc-server.txt" &
server_pid=$!
for i in $(seq 1 60); do
  listening=$(ip netns exec "$B" ss -H -ltn 'sport = :18080')
  [[ -z $listening ]] || break
  sleep 0.05
done
[[ -n $listening ]] || fail 'nc listener missing'
printf '%s\n' "$listening" | tee "$REPORT/nc-listen.txt"
printf 'hello-from-A\n' | ip netns exec "$A" nc -N -w 2 10.77.2.2 18080 > "$REPORT/nc-client.txt"
wait "$server_pid"
server_pid=
grep -F hello-from-A "$REPORT/nc-server.txt" >/dev/null || fail 'nc server did not receive client message'
grep -F reply-from-B "$REPORT/nc-client.txt" >/dev/null || fail 'nc client did not receive server reply'
sleep 0.2
kill -INT "$capture_pid"
wait "$capture_pid" || true
capture_pid=
tcpdump -nn -r "$REPORT/nc-handshake.pcap" > "$REPORT/nc-handshake.txt" 2>/dev/null
for flag in '[S]' '[S.]' '[.]'; do
  grep -F "Flags $flag" "$REPORT/nc-handshake.txt" >/dev/null || fail "nc handshake $flag missing"
done
cat "$REPORT/nc-handshake.txt"
pass 'standard nc bidirectional data, ss listener and captured TCP handshake'
set +e
refused_output=$(ip netns exec "$A" nc -vz -w 2 10.77.2.2 18080 2>&1)
rc=$?
set -e
printf '%s\n' "$refused_output"
[[ $rc != 0 ]] || fail 'nc connected despite absent listener'
printf '%s\n' "$refused_output" | grep -i 'refused' >/dev/null || fail 'nc refused evidence missing'
pass 'standard nc reports connection refused'

ip netns exec "$A" tcpdump --immediate-mode -U -nn -i eth0 -w "$REPORT/handshake.pcap" 'tcp port 18080' 2> "$REPORT/capture.log" &
capture_pid=$!
for i in $(seq 1 60); do
  grep -q 'listening on' "$REPORT/capture.log" && break
  kill -0 "$capture_pid" 2>/dev/null || fail 'capture exited'
  sleep 0.05
done
grep -q 'listening on' "$REPORT/capture.log" || fail 'capture readiness timeout'
start_server echo
expect_client SUCCESS 0
sleep 0.2
kill -INT "$capture_pid"
wait "$capture_pid" || true
capture_pid=
tcpdump -nn -r "$REPORT/handshake.pcap" > "$REPORT/handshake.txt" 2>/dev/null
cat "$REPORT/handshake.txt"
grep -F 'Flags [S]' "$REPORT/handshake.txt" >/dev/null || fail 'SYN missing'
grep -F 'Flags [S.]' "$REPORT/handshake.txt" >/dev/null || fail 'SYN+ACK missing'
grep -F 'Flags [.]' "$REPORT/handshake.txt" >/dev/null || fail 'ACK missing'
pass 'TCP handshake and application echo'

set +e
timeout_output=$(bash "$BASE/network.sh" timeout-demo 2>&1)
rc=$?
set -e
printf '%s\n' "$timeout_output"
[[ $rc == 1 ]] || fail "timeout-demo status $rc (3 means cleanup failed)"
printf '%s\n' "$timeout_output" | grep -F CONNECT_TIMEOUT >/dev/null || fail 'connect timeout missing'
expect_client SUCCESS 0
pass 'connect timeout and automatic firewall restoration'
stop_server
expect_client 'CONNECT_ERROR ECONNREFUSED' 1
pass 'refused without listener'
start_server hold
expect_client READ_TIMEOUT 1
pass 'read timeout after successful connect'
stop_server
start_server reset
expect_client 'AFTER_CONNECT ECONNRESET' 1
pass 'connection reset'
stop_server

route_removed=1
ip -n "$A" route del default
set +e
route_output=$(ip -n "$A" route get 10.77.2.2 2>&1)
rc=$?
set -e
printf '%s\n' "$route_output"
[[ $rc != 0 ]] || fail 'missing default route did not fail lookup'
ip -n "$A" route replace default via 10.77.1.1
route_removed=0
ip netns exec "$A" ping -n -c 1 -W 1 10.77.2.2
pass 'missing-route failure and route restoration'
echo '\nALL NETWORK CHECKS PASSED (actual Linux run, not simulated output)'
