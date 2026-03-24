#!/bin/bash
# pacman-statusline v1.0.0
# https://github.com/renathoaz/pacman-statusline
set -f

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ── Colors ──────────────────────────────────────────────
blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;175;80m'
cyan='\033[38;2;86;182;194m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
magenta='\033[38;2;180;140;255m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}•${reset} "

# ── Helpers ─────────────────────────────────────────────
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

color_for_pct() {
    local pct=$1
    if [ "$pct" -ge 90 ]; then printf "$red"
    elif [ "$pct" -ge 70 ]; then printf "$yellow"
    elif [ "$pct" -ge 50 ]; then printf "$orange"
    else printf "$green"
    fi
}

pac_yellow='\033[38;2;255;230;0m'
pac_orange='\033[38;2;255;176;85m'
pac_red='\033[38;2;255;85;85m'
pac_purple='\033[38;2;180;140;255m'
ghost_red='\033[38;2;255;85;85m'
ghost_pink='\033[38;2;255;184;255m'
ghost_cyan='\033[38;2;0;255;255m'
ghost_orange='\033[38;2;255;176;85m'
cherry_color='\033[38;2;220;20;60m'

build_bar() {
    local pct=$1
    local width=$2
    [ "$pct" -lt 0 ] 2>/dev/null && pct=0
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100

    local filled=$(( pct * width / 100 ))
    [ "$filled" -gt $(( width - 1 )) ] && filled=$(( width - 1 ))
    local empty=$(( width - filled ))

    # Pac-man color based on usage
    local pac_color
    if [ "$pct" -ge 90 ]; then
        pac_color="$pac_purple"
    elif [ "$pct" -ge 70 ]; then
        pac_color="$pac_red"
    elif [ "$pct" -ge 50 ]; then
        pac_color="$pac_orange"
    else
        pac_color="$pac_yellow"
    fi

    # Ghost intensity based on pct (50%=dim, 100%=bright)
    # Interpolate RGB from dim (80,60,80) to bright red (255,85,85)
    ghost_color_for_pct() {
        local p=$1
        local intensity=$(( (p - 50) * 100 / 50 ))
        [ "$intensity" -lt 0 ] && intensity=0
        [ "$intensity" -gt 100 ] && intensity=100
        local r=$(( 80 + (255 - 80) * intensity / 100 ))
        local g=$(( 60 + (85 - 60) * intensity / 100 ))
        local b=$(( 80 + (85 - 80) * intensity / 100 ))
        printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
    }

    # Ghost position: at 50% it's at start, at 95%+ it's right behind pacman
    ghost_pos_for_pct() {
        local p=$1 f=$2
        [ "$f" -lt 1 ] && echo -1 && return
        if [ "$p" -ge 95 ]; then
            echo $(( f - 1 ))
        else
            local progress=$(( (p - 50) * 100 / 45 ))
            [ "$progress" -lt 0 ] && progress=0
            [ "$progress" -gt 100 ] && progress=100
            echo $(( progress * (f - 1) / 100 ))
        fi
    }

    # Build trail (behind pac-man)
    local trail=""
    if [ "$pct" -ge 50 ] && [ "$filled" -gt 0 ]; then
        local ghost_pos
        ghost_pos=$(ghost_pos_for_pct "$pct" "$filled")
        local gc
        gc=$(ghost_color_for_pct "$pct")
        for ((i=0; i<filled; i++)); do
            if [ "$i" -eq "$ghost_pos" ]; then
                trail+="${gc}ᗣ${reset}"
            else
                trail+="${dim}·${reset}"
            fi
        done
    else
        # No ghost or flash-off frame
        for ((i=0; i<filled; i++)); do trail+="${dim}·${reset}"; done
    fi

    # Build dots (ahead of pac-man)
    local dots=""
    local dots_count=$(( empty - 1 ))
    [ "$dots_count" -lt 0 ] && dots_count=0

    # Cherry at ~50% of remaining dots (when there's enough space)
    local cherry_pos=-1
    if [ "$dots_count" -ge 2 ]; then
        # Compensate: cherry takes 2 columns, so reduce dot count by 1
        dots_count=$(( dots_count - 1 ))
        cherry_pos=$(( dots_count / 2 ))
    fi

    for ((i=0; i<dots_count; i++)); do
        if [ "$i" -eq "$cherry_pos" ]; then
            dots+="${cherry_color}🍒${reset}"
        else
            dots+="${dim}•${reset}"
        fi
    done

    if [ "$empty" -gt 0 ]; then
        printf "%b${pac_color}ᗧ${reset}%b" "$trail" "$dots"
    else
        printf "%b${pac_color}ᗧ${reset}" "$trail"
    fi
}

iso_to_epoch() {
    local iso_str="$1"

    local epoch
    epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"
    stripped="${stripped%%+*}"
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"

    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi

    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    return 1
}

# Detect date flavor once
if date -d "2024-01-01" +%s >/dev/null 2>&1; then
    DATE_FLAVOR="gnu"
else
    DATE_FLAVOR="bsd"
fi

format_reset_time() {
    local iso_str="$1"
    local style="$2"
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return

    local epoch
    epoch=$(iso_to_epoch "$iso_str")
    [ -z "$epoch" ] && return

    local result=""
    if [ "$DATE_FLAVOR" = "gnu" ]; then
        case "$style" in
            time)     result=$(date -d "@$epoch" +"%l:%M%P" 2>/dev/null) ;;
            datetime) result=$(date -d "@$epoch" +"%b %-d, %l:%M%P" 2>/dev/null) ;;
            *)        result=$(date -d "@$epoch" +"%b %-d" 2>/dev/null) ;;
        esac
    else
        case "$style" in
            time)     result=$(date -j -r "$epoch" +"%l:%M%p" 2>/dev/null) ;;
            datetime) result=$(date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null) ;;
            *)        result=$(date -j -r "$epoch" +"%b %-d" 2>/dev/null) ;;
        esac
    fi

    echo "$result" | sed 's/^ *//; s/  / /g; s/\.//g' | tr '[:upper:]' '[:lower:]'
}

# ── Extract JSON data (single jq call) ──────────────────
eval "$(echo "$input" | jq -r '
  "model_name=" + ((.model.display_name // "Claude") | @sh),
  "size=" + ((.context_window.context_window_size // 200000) | tostring | @sh),
  "input_tokens=" + ((.context_window.current_usage.input_tokens // 0) | tostring | @sh),
  "cache_create=" + ((.context_window.current_usage.cache_creation_input_tokens // 0) | tostring | @sh),
  "cache_read=" + ((.context_window.current_usage.cache_read_input_tokens // 0) | tostring | @sh),
  "cwd=" + ((.cwd // "") | @sh),
  "transcript_path=" + ((.transcript_path // "") | @sh)
' 2>/dev/null)"

[ -z "$size" ] || [ "$size" -eq 0 ] 2>/dev/null && size=200000
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)

if [ "$size" -gt 0 ]; then
    pct_used=$(( current * 100 / size ))
else
    pct_used=0
fi

# ── 2x Off-peak check ────────────────────────────────
is_offpeak=false
et_hour=$(TZ="America/New_York" date +%H | sed 's/^0//')
et_dow=$(TZ="America/New_York" date +%u)  # 1=Mon..7=Sun

# Weekends (Sat=6, Sun=7) always off-peak
if [ "$et_dow" -ge 6 ]; then
    is_offpeak=true
# Weekdays: off-peak before 8am or after 2pm ET
elif [ "$et_hour" -lt 8 ] || [ "$et_hour" -ge 14 ]; then
    is_offpeak=true
fi

offpeak_badge=""
if $is_offpeak; then
    offpeak_badge="${yellow}2x${reset}${sep}"
fi

# ── LINE 1: Model • Directory (branch) • Session ──
pct_color=$(color_for_pct "$pct_used")
dirname=$(basename "$cwd")

git_branch=""
git_dirty=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
        git_dirty="*"
    fi
fi

session_duration=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    start_epoch=$(stat -c %W "$transcript_path" 2>/dev/null)
    [ -z "$start_epoch" ] || [ "$start_epoch" = "0" ] && start_epoch=$(stat -c %Y "$transcript_path" 2>/dev/null)
    if [ -n "$start_epoch" ] && [ "$start_epoch" -gt 0 ] 2>/dev/null; then
        now_epoch=$(date +%s)
        elapsed=$(( now_epoch - start_epoch ))
        if [ "$elapsed" -ge 3600 ]; then
            session_duration="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
        elif [ "$elapsed" -ge 60 ]; then
            session_duration="$(( elapsed / 60 ))m"
        else
            session_duration="${elapsed}s"
        fi
    fi
fi

line1="${offpeak_badge}${blue}${model_name}${reset}"
line1+="${sep}"
line1+="${cyan}${dirname}${reset}"
if [ -n "$git_branch" ]; then
    line1+=" ${green}(${git_branch}${red}${git_dirty}${green})${reset}"
fi
if [ -n "$session_duration" ]; then
    line1+="${sep}"
    line1+="${dim}⌚ ${reset}${white}${session_duration}${reset}"
fi

# ── LINE 2: Context bar + tokens + compaction ────────────
ctx_bar=$(build_bar "$pct_used" 15)
pct_remaining=$(( 100 - pct_used ))
line2="${ctx_bar} ${pct_color}${used_tokens}${reset}${dim}/${reset}${white}${total_tokens}${reset} ${dim}⟳ ${reset}${pct_color}${pct_remaining}%${reset}"

# ── OAuth token resolution ──────────────────────────────
get_oauth_token() {
    local token=""

    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        echo "$CLAUDE_CODE_OAUTH_TOKEN"
        return 0
    fi

    if command -v security >/dev/null 2>&1; then
        local blob
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        if [ -n "$blob" ]; then
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                echo "$token"
                return 0
            fi
        fi
    fi

    local creds_file="${HOME}/.claude/.credentials.json"
    if [ -f "$creds_file" ]; then
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            echo "$token"
            return 0
        fi
    fi

    if command -v secret-tool >/dev/null 2>&1; then
        local blob
        blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
        if [ -n "$blob" ]; then
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                echo "$token"
                return 0
            fi
        fi
    fi

    echo ""
}

# ── Fetch usage data (cached) ──────────────────────────
cache_file="/tmp/claude/pacline-cache.json"
cache_max_age=60
mkdir -p /tmp/claude

needs_refresh=true
usage_data=""

if [ -f "$cache_file" ]; then
    cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
    now=$(date +%s)
    cache_age=$(( now - cache_mtime ))
    if [ "$cache_age" -lt "$cache_max_age" ]; then
        needs_refresh=false
        usage_data=$(cat "$cache_file" 2>/dev/null)
    fi
fi

if $needs_refresh; then
    token=$(get_oauth_token)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        response=$(curl -s --max-time 5 \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            -H "User-Agent: pacman-statusline/1.0.0" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
            usage_data="$response"
            echo "$response" > "$cache_file"
        fi
    fi
    if [ -z "$usage_data" ] && [ -f "$cache_file" ]; then
        usage_data=$(cat "$cache_file" 2>/dev/null)
    fi
fi

# ── Rate limits (inline) ─────────────────────────────────
rate_suffix=""

if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
    eval "$(echo "$usage_data" | jq -r '
        "five_hour_pct_raw=" + ((.five_hour.utilization // 0) | tostring | @sh),
        "five_hour_reset_iso=" + ((.five_hour.resets_at // "") | @sh),
        "seven_day_pct_raw=" + ((.seven_day.utilization // 0) | tostring | @sh),
        "seven_day_reset_iso=" + ((.seven_day.resets_at // "") | @sh),
        "extra_enabled=" + ((.extra_usage.is_enabled // false) | tostring | @sh),
        "extra_used_raw=" + ((.extra_usage.used_credits // 0) | tostring | @sh),
        "extra_limit_raw=" + ((.extra_usage.monthly_limit // 0) | tostring | @sh),
        "extra_pct_raw=" + ((.extra_usage.utilization // 0) | tostring | @sh)
    ' 2>/dev/null)"

    five_hour_pct=$(awk "BEGIN {printf \"%.0f\", $five_hour_pct_raw}")
    five_hour_pct_color=$(color_for_pct "$five_hour_pct")
    five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")

    seven_day_pct=$(awk "BEGIN {printf \"%.0f\", $seven_day_pct_raw}")
    seven_day_pct_color=$(color_for_pct "$seven_day_pct")
    seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")

    rate_suffix="${dim}⏳${reset} ${five_hour_pct_color}${five_hour_pct}%${reset}"
    [ -n "$five_hour_reset" ] && rate_suffix+=" ${dim}↻ ${five_hour_reset}${reset}"
    rate_suffix+=" ${dim}•${reset} ${dim}📅${reset} ${seven_day_pct_color}${seven_day_pct}%${reset}"
    [ -n "$seven_day_reset" ] && rate_suffix+=" ${dim}↻ ${seven_day_reset}${reset}"

    if [ "$extra_enabled" = "true" ]; then
        extra_used=$(awk "BEGIN {printf \"%.2f\", $extra_used_raw/100}")
        extra_limit=$(awk "BEGIN {printf \"%.2f\", $extra_limit_raw/100}")
        extra_pct=$(awk "BEGIN {printf \"%.0f\", $extra_pct_raw}")
        extra_pct_color=$(color_for_pct "$extra_pct")
        rate_suffix+=" ${dim}$$${reset} ${extra_pct_color}\$${extra_used}${dim}/${reset}${white}\$${extra_limit}${reset}"
    fi
fi

# ── Output ──────────────────────────────────────────────
printf "%b" "$line1"
printf "\n%b" "$line2"
[ -n "$rate_suffix" ] && printf "\n%b" "$rate_suffix"

exit 0
