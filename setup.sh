#!/usr/bin/env bash
set -euo pipefail

# Color definitions
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' RESET=''
fi

readonly ENV_EXAMPLE=".env.example"
readonly ENV_FILE=".env"

trim() {
  local str="$1"
  str="${str#"${str%%[![:space:]]*}"}"
  str="${str%"${str##*[![:space:]]}"}"
  echo "$str"
}

unquote() {
  local val="$1"
  if [[ ${#val} -ge 2 ]]; then
    local first="${val:0:1}" last="${val: -1}"
    [[ "$first" == "$last" ]] && [[ "$first" =~ [\"\'] ]] && echo "${val:1:-1}" && return
  fi
  echo "$val"
}

extract_value() {
  local line="$1"
  if [[ "$line" =~ =\"([^\"]*)\" ]] || [[ "$line" =~ =\'([^\']*)\' ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$line" =~ =([^[:space:]#]*) ]]; then
    trim "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

[[ ! -f "$ENV_EXAMPLE" ]] && echo -e "${RED}[ERROR]${RESET} $ENV_EXAMPLE not found" >&2 && exit 1

if [[ -f "$ENV_FILE" ]]; then
  read -p "$(echo -e "${YELLOW}[WARN]${RESET} $ENV_FILE exists. Overwrite? (y/N): ")" -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && echo "Aborted." && exit 0
fi

declare -a keys=()
declare -A defaults=()

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)= ]] || continue
  key="${BASH_REMATCH[1]}"
  keys+=("$key")
  defaults["$key"]=$(extract_value "$line")
done < "$ENV_EXAMPLE"

[[ ${#keys[@]} -eq 0 ]] && echo -e "${RED}[ERROR]${RESET} No variables found in $ENV_EXAMPLE" >&2 && exit 1

echo -e "${CYAN}[SETUP]${RESET} Environment Setup"
echo "Variables to configure:"
for key in "${keys[@]}"; do echo "  • $key"; done
echo

declare -A values=()
for key in "${keys[@]}"; do
  default="${defaults[$key]}"
  [[ -n "$default" ]] && read -rp "  $key [$default]: " input || read -rp "  $key: " input
  values["$key"]="${input:-$default}"
done

> "$ENV_FILE"
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
    echo "$line" >> "$ENV_FILE"
  elif [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)= ]]; then
    echo "${BASH_REMATCH[1]}=\"${values[${BASH_REMATCH[1]}]}\"" >> "$ENV_FILE"
  else
    echo "$line" >> "$ENV_FILE"
  fi
done < "$ENV_EXAMPLE"

echo -e "${GREEN}[OK]${RESET} Created $ENV_FILE"
echo -e "${CYAN}[EXPORT]${RESET} Exporting variables..."
echo ""
echo -e "${CYAN}[TIP]${RESET} If you only want to export environment variables (without setup),"
echo "   you can use the scripts in the scripts/ folder:"
echo "   • For bash: source ./scripts/export.sh"
echo "   • For fish: source ./scripts/export.fish"
echo ""

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] || [[ "$line" != *"="* ]] && continue
  key=$(trim "${line%%=*}")
  value=$(unquote "$(trim "${line#*=}")")
  export "$key"="$value"
  echo -e "${GREEN}[OK]${RESET} $key = $value"
done < "$ENV_FILE"

echo -e "${GREEN}[OK]${RESET} Done"
