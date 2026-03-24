#!/bin/bash
set -e

# ── Colors ──────────────────────────────────────────────
yellow='\033[38;2;255;230;0m'
green='\033[38;2;0;175;80m'
red='\033[38;2;255;85;85m'
cyan='\033[38;2;86;182;194m'
dim='\033[2m'
reset='\033[0m'

INSTALL_DIR="$HOME/.claude"
SCRIPT_NAME="pacline.sh"
CACHE_FILE="/tmp/claude/pacline-cache.json"

printf "\n"
printf "  ${red}ᗣ${reset} ${dim}• • • • •${reset} Uninstalling pacman-statusline ${dim}• • • • •${reset} ${red}ᗣ${reset}\n"
printf "\n"

# ── Remove script ───────────────────────────────────────
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    rm "$INSTALL_DIR/$SCRIPT_NAME"
    printf "  ${green}✓${reset} Removed ${cyan}%s/%s${reset}\n" "$INSTALL_DIR" "$SCRIPT_NAME"
else
    printf "  ${dim}-${reset} ${cyan}%s/%s${reset} not found (already removed?)\n" "$INSTALL_DIR" "$SCRIPT_NAME"
fi

# ── Remove backup ──────────────────────────────────────
if [ -f "$INSTALL_DIR/${SCRIPT_NAME}.bak" ]; then
    rm "$INSTALL_DIR/${SCRIPT_NAME}.bak"
    printf "  ${green}✓${reset} Removed backup ${cyan}%s.bak${reset}\n" "$SCRIPT_NAME"
fi

# ── Remove cache ───────────────────────────────────────
if [ -f "$CACHE_FILE" ]; then
    rm "$CACHE_FILE"
    printf "  ${green}✓${reset} Removed cache ${cyan}%s${reset}\n" "$CACHE_FILE"
else
    printf "  ${dim}-${reset} No cache file found\n"
fi

# ── Remind about settings ──────────────────────────────
printf "\n"
printf "  ${yellow}!${reset} Remember to remove the ${cyan}statusLine${reset} block from:\n"
printf "    ${dim}%s/settings.json${reset}\n" "$INSTALL_DIR"
printf "\n"
printf "  ${dim}ᗧ · · · Game Over · · · ᗧ${reset}\n"
printf "\n"
