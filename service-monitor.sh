#!/usr/bin/env bash

SERVICE="$1"

if [[ $# -eq 0 ]]; then
    echo "Error: At least one service name is required."
    echo "Usage:  $0 <service> [service...]"
    exit 1
fi

echo "======= SERVICE MONITOR ======="

TOTAL=0
RUNNING=0
STOPPED=0
NOT_FOUND=0

for SERVICE in "$@";do

    ((TOTAL++))
    echo
    echo "Service: $SERVICE"

    if ! systemctl cat "$SERVICE.service" &>/dev/null; then
    echo "Status: NOT FOUND"
    ((NOT_FOUND++))
    continue
    fi

    if systemctl is-active --quiet "$SERVICE"; then
    STATUS="RUNNING"
    ((RUNNING++))
    else
    STATUS="STOPPED"
    ((STOPPED++))
    fi

    if systemctl is-enabled --quiet "$SERVICE"; then
    ENABLED="YES"
    else
    ENABLED="NO"
    fi

    echo "Status: $STATUS"
    echo "Enabled: $ENABLED"

   
done

echo
echo "======= SUMMARY ======="
echo "Total Services: $TOTAL"
echo "Running: $RUNNING"
echo "Stopped: $STOPPED"
echo "Not Found: $NOT_FOUND"

if [[ $NOT_FOUND -gt 0 ]]; then
    exit 3
elif [[ $STOPPED -gt 0 ]]; then
    exit 2
else
    exit 0
fi
