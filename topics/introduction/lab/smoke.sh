#!/usr/bin/env bash
set -euo pipefail
# Tests the Java currently on PATH. Run inside nix develop to test the pinned JDK.
cd "$(dirname "$0")"
work=$(mktemp -d)
pid=''
cleanup() {
  if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT
javac --release 21 -d "$work" StudyApi.java
BIND_ADDRESS=127.0.0.1 PORT=0 APP_ENV=smoke APP_MESSAGE='hello smoke' java -cp "$work" StudyApi >"$work/server.log" 2>&1 &
pid=$!
for ((i=0; i<100; i++)); do
  grep -q 'listening on' "$work/server.log" && break
  kill -0 "$pid" 2>/dev/null || { cat "$work/server.log"; exit 1; }
  sleep 0.1
done
port=$(sed -n 's/.*listening on 127.0.0.1:\([0-9]*\)/\1/p' "$work/server.log")
[ -n "$port" ] || { cat "$work/server.log"; exit 1; }
base="http://127.0.0.1:$port"
[ "$(curl -fsS "$base/health")" = ok ]
[ "$(curl -fsS "$base/message")" = 'hello smoke' ]
curl -fsS "$base/info" | grep -qx 'environment=smoke'
curl -fsS -D - -o /dev/null "$base/health" | grep -qi '^content-type: text/plain; charset=utf-8'
[ "$(curl -sS -o /dev/null -w '%{http_code}' "$base/missing")" = 404 ]
[ "$(curl -sS -X POST -o /dev/null -w '%{http_code}' "$base/health")" = 405 ]
printf 'PASS: health, configured message, environment, content type, 404, 405 (6 checks)\n'
