#!/usr/bin/env fish

set -l green (set_color green)
set -l yellow (set_color yellow)
set -l cyan (set_color cyan)
set -l red (set_color red)
set -l reset (set_color normal)

if not test -f .env
    echo -s $red "Error: .env file not found" $reset >&2
    exit 1
end

echo -s $cyan "Reading .env file..." $reset

for line in (cat .env)
    if test -z "$line"; or string match -q "#*" "$line"
        continue
    end
    
    if string match -q "*=*" "$line"
        set -l key (string split -m 1 "=" "$line" | head -n 1 | string trim)
        set -l value (string split -m 1 "=" "$line" | tail -n 1 | string trim | string replace -r '^["\047](.*)["\047]$' '$1')
        set -gx "$key" "$value"
        echo -s $green "✓" $reset " " $yellow "$key" $reset " = " $cyan "$value" $reset
    end
end

echo -s $green "Done!" $reset

