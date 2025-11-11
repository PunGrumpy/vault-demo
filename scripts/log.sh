#!/usr/bin/env bash

# ========================
# Logging library
# Usage: source ./log.sh
# ========================

LOG_DATE_FORMAT="+%Y-%m-%d %H:%M:%S"
LOG_ENABLE_COLOR=true
LOG_DEBUG=false

if [ "$LOG_ENABLE_COLOR" = true ]; then
  CLR_RESET='\033[0m'
  CLR_INFO='\033[0;32m'     # Green
  CLR_WARN='\033[0;33m'     # Yellow
  CLR_ERROR='\033[0;31m'    # Red
  CLR_DEBUG='\033[0;36m'    # Cyan
else
  CLR_RESET='' CLR_INFO='' CLR_WARN='' CLR_ERROR='' CLR_DEBUG='' CLR_SUCCESS=''
fi

_timestamp() {
  date "$LOG_DATE_FORMAT"
}

info() {
  echo -e "${CLR_INFO}[$(_timestamp)] [INFO]${CLR_RESET} $*"
}

warn() {
  echo -e "${CLR_WARN}[$(_timestamp)] [WARN]${CLR_RESET} $*"
}

error() {
  echo -e "${CLR_ERROR}[$(_timestamp)] [ERROR]${CLR_RESET} $*" >&2
}

debug() {
  if [ "$LOG_DEBUG" = true ]; then
    echo -e "${CLR_DEBUG}[$(_timestamp)] [DEBUG]${CLR_RESET} $*"
  fi
}
