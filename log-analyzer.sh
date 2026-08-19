#!/usr/bin/env bash

# Day 2 - Log Analyzer
# Analyze Apache/Nginx-style access logs using Bash and standard Linux tools.

set -o pipefail

SCRIPT_NAME="$0"
LOG_FILE="${1:-access.log}"

show_help() {
    cat <<EOF
Usage: $SCRIPT_NAME [LOG_FILE]

Analyze an Apache/Nginx combined access log.

Arguments:
  LOG_FILE    Optional path to a log file. Defaults to access.log.
  --help      Show this help message.

Exit codes:
  0  Analysis completed successfully.
  1  Log file is missing, unreadable, or invalid.
  2  Invalid command-line argument.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$#" -gt 1 ]]; then
    echo "Error: too many arguments." >&2
    show_help >&2
    exit 2
fi

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: Log file '$LOG_FILE' not found." >&2
    exit 1
fi

if [[ ! -r "$LOG_FILE" ]]; then
    echo "Error: Log file '$LOG_FILE' is not readable." >&2
    exit 1
fi

if [[ ! -s "$LOG_FILE" ]]; then
    echo "Error: Log file '$LOG_FILE' is empty." >&2
    exit 1
fi

# Validate that at least one line contains the expected HTTP status field.
if ! awk 'NF >= 9 && $9 ~ /^[0-9][0-9][0-9]$/ { found=1; exit } END { exit(found ? 0 : 1) }' "$LOG_FILE"; then
    echo "Error: Log file '$LOG_FILE' does not look like a supported access log." >&2
    exit 1
fi

TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
ERROR_4XX=$(awk '$9 ~ /^4[0-9][0-9]$/ { count++ } END { print count + 0 }' "$LOG_FILE")
ERROR_5XX=$(awk '$9 ~ /^5[0-9][0-9]$/ { count++ } END { print count + 0 }' "$LOG_FILE")
TOTAL_ERRORS=$((ERROR_4XX + ERROR_5XX))

print_ranked() {
    local title="$1"
    local awk_program="$2"
    local limit="$3"

    echo "$title"
    awk "$awk_program" "$LOG_FILE" | sort | uniq -c | sort -nr | head -n "$limit"
    echo
}

echo "======= LOG ANALYZER ======="
echo "Log File: $LOG_FILE"
echo "Total Requests: $TOTAL_REQUESTS"
echo "4xx Errors: $ERROR_4XX"
echo "5xx Errors: $ERROR_5XX"
echo "Total Errors: $TOTAL_ERRORS"
echo

print_ranked "======= Top 5 IP Addresses =======" '{print $1}' 5
print_ranked "======= Top 5 URLs =======" '{print $7}' 5
print_ranked "======= Top 4xx Error URLs =======" '$9 ~ /^4[0-9][0-9]$/ {print $7}' 5
print_ranked "======= Top 5xx Error URLs =======" '$9 ~ /^5[0-9][0-9]$/ {print $7}' 5

echo "Analysis completed successfully."
exit 0
