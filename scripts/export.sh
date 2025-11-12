#!/usr/bin/env bash

if [[ -t 1 ]]; then
    green='\033[0;32m'
    yellow='\033[0;33m'
    cyan='\033[0;36m'
    red='\033[0;31m'
    reset='\033[0m'
else
    green='' yellow='' cyan='' red='' reset=''
fi

if [[ ! -f .env ]]; then
    echo -e "${red}Error: .env file not found${reset}" >&2
    exit 1
fi

echo -e "${cyan}Reading .env file...${reset}"

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" != *"="* ]] && continue
    
    key="${line%%=*}"
    value="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    
    if [[ ${#value} -ge 2 ]]; then
        first_char="${value:0:1}"
        last_char="${value: -1}"
        [[ "$first_char" == "$last_char" ]] && ([[ "$first_char" == "'" ]] || [[ "$first_char" == '"' ]]) && value="${value:1:-1}"
    fi
    
    export "$key"="$value"
    echo -e "${green}✓${reset} ${yellow}$key${reset} = ${cyan}$value${reset}"
done < .env

echo -e "${green}Done!${reset}"