#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
STATE="$BASE/.state/vm"; CACHE="$STATE/cache"
IMAGE_NAME=noble-server-cloudimg-arm64.img
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/$IMAGE_NAME"
SUMS_URL=https://cloud-images.ubuntu.com/noble/current/SHA256SUMS
BASE_IMAGE="$CACHE/$IMAGE_NAME"; BASE_SHA="$CACHE/$IMAGE_NAME.sha256"
OVERLAY="$STATE/root.qcow2"; SEED="$STATE/seed.iso"
KEY="$STATE/id_ed25519"; KNOWN_HOSTS="$STATE/known_hosts"
PIDFILE="$STATE/qemu.pid"; SERIAL_LOG="$STATE/serial.log"
QMP_SOCKET="$STATE/qmp.sock"; NAME_FILE="$STATE/vm-name"
VM_USER=scglab; VM_HOST=127.0.0.1; VM_PORT=22240
GUEST_DIR=/home/scglab/scg-network-lab
READY_TIMEOUT=${LAB_VM_READY_TIMEOUT:-900}; STOP_TIMEOUT=${LAB_VM_STOP_TIMEOUT:-60}
usage() {
  cat <<'HELP'
Usage: ./vm.sh up
       ./vm.sh exec <network.sh arguments...>
       ./vm.sh shell <a|r|b>
       ./vm.sh stop
       ./vm.sh status
up downloads and verifies the official Ubuntu 24.04 arm64 cloud image on first
use (about 591 MiB), boots QEMU, waits for cloud-init, and syncs this lab. It
does not create network namespaces; the parent launcher calls `vm.sh exec up`.
SSH is exposed only at 127.0.0.1:22240. State and the private SSH key stay in
lab/.state/vm. Set LAB_VM_READY_TIMEOUT to change the 900 second boot limit.
HELP
}
die() { printf 'vm.sh: %s\n' "$*" >&2; exit 2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing command '$1'; enter nix develop"; }
valid_seconds() { case $2 in ''|*[!0-9]*) die "$1 must be a non-negative integer" ;; esac; }
owned_qemu() {
  local rc
  VM_PID=unknown
  [[ ! -r $PIDFILE ]] || IFS= read -r VM_PID < "$PIDFILE" || true
  [[ -S $QMP_SOCKET ]] || return 1
  [[ -r $NAME_FILE ]] || return 2
  VM_NAME=$(cat "$NAME_FILE")
  if node "$BASE/engine/qmp.mjs" "$QMP_SOCKET" "$VM_NAME" status >/dev/null 2>&1; then return 0; fi
  # Repeat once to obtain an explicit unavailable vs unsafe/unknown status.
  node "$BASE/engine/qmp.mjs" "$QMP_SOCKET" "$VM_NAME" status >/dev/null 2>&1 && return 0 || rc=$?
  [[ $rc == 1 ]] && return 1
  return 2
}
check_not_foreign_pid() {
  local rc
  if owned_qemu; then return 0; else rc=$?; fi
  (( rc != 2 )) || die 'QMP ownership/status cannot be verified; refusing to touch a possibly running VM' 
  rm -f -- "$PIDFILE"
  return 1
}
ssh_options() {
  SSH_ARGS=(-F /dev/null -i "$KEY" -p "$VM_PORT" -o BatchMode=yes -o IdentitiesOnly=yes -o IdentityAgent=none
    -o ConnectTimeout=5 -o ConnectionAttempts=1 -o ServerAliveInterval=5 -o ServerAliveCountMax=3
    -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$KNOWN_HOSTS")
}
ssh_run() { ssh_options; ssh "${SSH_ARGS[@]}" "$VM_USER@$VM_HOST" "$@"; }
quote_command() {
  local word quoted command
  command=
  for word in "$@"; do
    printf -v quoted '%q' "$word"
    command="${command}${command:+ }$quoted"
  done
  printf '%s' "$command"
}
find_firmware() {
  local qemu_path qemu_dir candidate
  if [[ -n ${LAB_QEMU_FIRMWARE:-} ]]; then
    [[ -r $LAB_QEMU_FIRMWARE ]] || die "LAB_QEMU_FIRMWARE is not readable: $LAB_QEMU_FIRMWARE"
    FIRMWARE=$LAB_QEMU_FIRMWARE
    return
  fi
  qemu_path=$(command -v qemu-system-aarch64) || die "missing qemu-system-aarch64; enter nix develop"
  qemu_dir=$(cd -- "$(dirname -- "$qemu_path")" && pwd -P)
  candidate="$qemu_dir/../share/qemu/edk2-aarch64-code.fd"
  [[ -r $candidate ]] || die 'arm64 UEFI firmware not found; enter nix develop or set LAB_QEMU_FIRMWARE'
  FIRMWARE=$candidate
}
ensure_key() {
  if [[ ! -f $KEY || ! -f $KEY.pub ]]; then
    [[ ! -f $OVERLAY ]] || die 'overlay exists but its SSH key pair is missing; remove .state/vm to rebuild'
    rm -f -- "$KEY" "$KEY.pub"
    ssh-keygen -q -t ed25519 -N '' -C scg-network-lab -f "$KEY"
  fi
  chmod 600 "$KEY"
}
sha256_file() {
  node -e 'const h=require("node:crypto").createHash("sha256"); const s=require("node:fs").createReadStream(process.argv[1]); s.on("error",e=>{console.error(e.message);process.exitCode=1;}); s.on("data",c=>h.update(c)); s.on("end",()=>console.log(h.digest("hex")));' "$1"
}
fetch_image() {
  local sums expected actual part
  mkdir -p -- "$CACHE"
  if [[ -f $OVERLAY ]]; then
    [[ -r $BASE_IMAGE && -r $BASE_SHA ]] || die 'overlay exists but its cached base image/checksum is missing'
    IFS= read -r expected < "$BASE_SHA"
  else
    sums="$CACHE/SHA256SUMS.part"
    curl --fail --location --proto '=https' --proto-redir '=https' --retry 3 --connect-timeout 15 -o "$sums" "$SUMS_URL"
    if ! expected=$(awk -v f="$IMAGE_NAME" '{ n=$2; sub(/^\*/, "", n); if (n==f) { print $1; found++ } } END { if (found != 1) exit 1 }' "$sums"); then
      rm -f -- "$sums"
      die "could not find exactly one checksum for $IMAGE_NAME"
    fi
    rm -f -- "$sums"
    case $expected in *[!0-9a-fA-F]*|'') die 'invalid SHA256SUMS entry' ;; esac
    [[ ${#expected} == 64 ]] || die 'invalid SHA256SUMS digest length'
  fi
  actual=; [[ ! -f $BASE_IMAGE ]] || actual=$(sha256_file "$BASE_IMAGE")
  if [[ $actual != "$expected" ]]; then
    [[ ! -f $OVERLAY ]] || die 'cached base image checksum changed under an existing overlay'
    part="$BASE_IMAGE.part"
    actual=; [[ ! -f $part ]] || actual=$(sha256_file "$part")
    if [[ $actual != "$expected" ]]; then
      rm -f -- "$part"
      printf 'Downloading %s (about 591 MiB)...\n' "$IMAGE_URL"
      curl --fail --location --proto '=https' --proto-redir '=https' --retry 3 --connect-timeout 15 -o "$part" "$IMAGE_URL"
      actual=$(sha256_file "$part")
    fi
    [[ $actual == "$expected" ]] || { rm -f -- "$part"; die 'downloaded image SHA-256 mismatch'; }
    mv -f -- "$part" "$BASE_IMAGE"
  fi
  printf '%s\n' "$expected" > "$BASE_SHA"
}
make_seed() {
  local pub seed_dir
  pub=$(cat "$KEY.pub")
  seed_dir="$STATE/seed-src"
  rm -rf -- "$seed_dir"
  mkdir -p -- "$seed_dir"
  cat > "$seed_dir/user-data" <<EOF
#cloud-config
users:
  - name: $VM_USER
    gecos: SCG network lab
    groups: [sudo]
    shell: /bin/bash
    lock_passwd: true
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - $pub
ssh_pwauth: false
disable_root: true
package_update: true
packages:
  - iproute2
  - iputils-ping
  - tcpdump
  - iptables
  - traceroute
  - mtr-tiny
  - netcat-openbsd
  - nodejs
  - bash
  - coreutils
EOF
  cat > "$seed_dir/meta-data" <<'EOF'
instance-id: scg-network-lab
local-hostname: scg-network-lab
EOF
  rm -f -- "$SEED"
  (cd -- "$seed_dir" && mkisofs -quiet -output "$SEED" -volid cidata -joliet -rock user-data meta-data)
  rm -rf -- "$seed_dir"
}
start_qemu() {
  local accel=${LAB_VM_ACCEL:-hvf} cpu=host
  [[ $accel == hvf || $accel == tcg ]] || die 'LAB_VM_ACCEL must be hvf or tcg'
  [[ $accel != tcg ]] || cpu=max
  [[ -r $NAME_FILE ]] || node -e 'console.log("scg-network-lab-"+require("node:crypto").randomBytes(12).toString("hex"))' > "$NAME_FILE"
  VM_NAME=$(cat "$NAME_FILE")
  rm -f -- "$QMP_SOCKET"
  : > "$SERIAL_LOG"
  qemu-system-aarch64 \
    -name "$VM_NAME" -machine "virt,accel=$accel" -cpu "$cpu" -smp 2 -m 2048 \
    -qmp "unix:$QMP_SOCKET,server=on,wait=off" \
    -bios "$FIRMWARE" -display none -monitor none -serial "file:$SERIAL_LOG" \
    -drive "if=none,file=$OVERLAY,format=qcow2,id=rootdisk" \
    -device virtio-blk-pci,drive=rootdisk,serial=disk \
    -drive "if=none,file=$SEED,format=raw,readonly=on,id=seed" \
    -device virtio-blk-pci,drive=seed,serial=scg-seed \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$VM_PORT-:22" \
    -device virtio-net-pci,netdev=net0 -device virtio-rng-pci \
    -daemonize -pidfile "$PIDFILE"
  owned_qemu || { tail -n 40 "$SERIAL_LOG" >&2 || true; die 'QEMU did not remain running'; }
}
wait_ready() {
  local start now deadline remaining rc
  start=$(date +%s); deadline=$((start + READY_TIMEOUT))
  printf 'Waiting up to %s seconds for Ubuntu cloud-init...\n' "$READY_TIMEOUT"
  while :; do
    if owned_qemu; then :; else
      rc=$?
      tail -n 40 "$SERIAL_LOG" >&2 || true
      (( rc != 2 )) || die "QEMU PID $VM_PID no longer belongs to this VM"
      die 'QEMU exited before SSH became ready'
    fi
    if ssh_run 'test -f /var/lib/cloud/instance/boot-finished' >/dev/null 2>&1; then break; fi
    now=$(date +%s)
    (( now < deadline )) || { tail -n 40 "$SERIAL_LOG" >&2 || true; die 'timed out waiting for cloud-init'; }
    sleep 3
  done
  now=$(date +%s); remaining=$((deadline - now)); (( remaining > 0 )) || remaining=1
  if ! ssh_run "sudo timeout ${remaining}s cloud-init status --wait" >/dev/null; then
    ssh_run 'sudo cloud-init status --long' || true
    die 'cloud-init wait failed or exceeded the overall readiness timeout'
  fi
  ssh_run 'sudo cloud-init status --long' || die 'cloud-init reported an error; inspect the status above and serial.log'
}
ensure_guest_tools() {
  # Existing cached VMs do not rerun cloud-init package installation.
  if ! ssh_run 'command -v mtr >/dev/null && command -v nc >/dev/null'; then
    ssh_run 'sudo apt-get update -qq && sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y mtr-tiny netcat-openbsd'
  fi
}
sync_lab() {
  local remote
  # Preserve root-owned reports and user observations across source refreshes.
  remote="$(quote_command mkdir -p "$GUEST_DIR") && $(quote_command tar -xf - -C "$GUEST_DIR")"
  tar -C "$BASE" --exclude='./.state' --exclude='./.git' --exclude='./reports' \
    --exclude='*/reports' --exclude='*.pid' --exclude='*.key' --exclude='id_*' \
    --exclude='known_hosts' -cf - . | ssh_run "$remote"
  printf 'Synced lab sources to %s@%s:%s\n' "$VM_USER" "$VM_HOST" "$GUEST_DIR"
}
run_network() {
  local remote prefix
  (($#)) || die 'exec requires network.sh arguments'
  prefix=$(quote_command sudo env "BASE=$GUEST_DIR" bash "$GUEST_DIR/network.sh")
  remote="$prefix $(quote_command "$@")"
  ssh_run "$remote"
}
case ${1:-} in
  up)
    shift
    (($# == 0)) || die 'up takes no arguments'
    [[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || die 'up requires macOS arm64'
    valid_seconds LAB_VM_READY_TIMEOUT "$READY_TIMEOUT"
    for tool in qemu-system-aarch64 qemu-img mkisofs curl ssh ssh-keygen tar awk node; do need "$tool"; done
    mkdir -p -- "$STATE" "$CACHE"; chmod 700 "$STATE"
    ensure_key
    if ! check_not_foreign_pid; then
      find_firmware
      fetch_image
      [[ -f $OVERLAY ]] || qemu-img create -q -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$OVERLAY" 12G
      make_seed
      start_qemu
    fi
    wait_ready
    ensure_guest_tools
    sync_lab
    printf 'VM ready. Run ./vm.sh exec up to create the guest network lab.\n'
    ;;
  exec)
    shift; [[ -r $KEY ]] || die 'VM is not initialized; run ./vm.sh up'
    owned_qemu || die 'VM is not running; run ./vm.sh up'
    run_network "$@" ;;
  shell)
    shift
    (($# == 1)) || die 'shell expects exactly one role: a, r, or b'
    case $1 in a|r|b) ;; *) die 'shell role must be a, r, or b' ;; esac
    [[ -r $KEY ]] || die 'VM is not initialized; run ./vm.sh up'
    owned_qemu || die 'VM is not running; run ./vm.sh up'
    ssh_options
    remote=$(quote_command sudo env "BASE=$GUEST_DIR" bash "$GUEST_DIR/network.sh" shell "$1")
    exec ssh "${SSH_ARGS[@]}" -tt "$VM_USER@$VM_HOST" "$remote"
    ;;
  stop)
    shift
    (($# == 0)) || die 'stop takes no arguments'
    valid_seconds LAB_VM_STOP_TIMEOUT "$STOP_TIMEOUT"
    if ! check_not_foreign_pid; then printf 'VM is stopped.\n'; exit 0; fi
    ssh_run 'sudo shutdown -h now' >/dev/null 2>&1 || true
    end=$(( $(date +%s) + STOP_TIMEOUT ))
    while owned_qemu; do
      (( $(date +%s) < end )) || break
      sleep 2
    done
    if owned_qemu; then
      printf 'Guest did not stop in %s seconds; sending QMP quit to the verified lab VM.\n' "$STOP_TIMEOUT" >&2
      node "$BASE/engine/qmp.mjs" "$QMP_SOCKET" "$VM_NAME" quit || die 'QMP quit failed; no unrelated process was signalled' 
      end=$(( $(date +%s) + 10 ))
      while owned_qemu && (( $(date +%s) < end )); do sleep 1; done
    fi
    if owned_qemu; then die 'owned QEMU did not exit after QMP quit'
    else rc=$?; (( rc != 2 )) || die 'PID changed ownership while stopping; refusing further signals'; fi
    rm -f -- "$PIDFILE"
    printf 'VM stopped.\n'
    ;;
  status)
    shift
    (($# == 0)) || die 'status takes no arguments'
    if owned_qemu; then
      if [[ -r $KEY ]] && ssh_run true >/dev/null 2>&1; then
        printf 'running: PID %s, SSH ready at %s:%s\n' "$VM_PID" "$VM_HOST" "$VM_PORT"
      else
        printf 'running: PID %s, SSH not ready; serial log: %s\n' "$VM_PID" "$SERIAL_LOG"
      fi
    else
      rc=$?
      (( rc != 2 )) || die "PID $VM_PID is alive but does not belong to $OVERLAY"
      printf 'stopped\n'
    fi
    ;;
  help|-h|--help|'') usage ;;
  *) usage >&2; exit 2 ;;
esac
