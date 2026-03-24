#!/bin/bash
set -e

# ── Colors ──────────────────────────────────────────────
yellow='\033[38;2;255;230;0m'
green='\033[38;2;0;175;80m'
red='\033[38;2;255;85;85m'
cyan='\033[38;2;86;182;194m'
dim='\033[2m'
reset='\033[0m'

REPO="renathoaz/pacman-statusline"
INSTALL_DIR="$HOME/.claude"
SCRIPT_NAME="pacline.sh"
SCRIPT_URL="https://raw.githubusercontent.com/${REPO}/main/${SCRIPT_NAME}"

printf "\n"
printf "  ${yellow}ᗧ${reset} ${dim}• • • • •${reset} ${green}Installing pacman-statusline${reset} ${dim}• • • • •${reset} ${yellow}ᗧ${reset}\n"
printf "\n"

# ── Check prerequisites ─────────────────────────────────
check_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf "  ${red}✗${reset} Missing required tool: ${cyan}%s${reset}\n" "$1"
        printf "    Install it and try again.\n"
        exit 1
    fi
    printf "  ${green}✓${reset} Found ${cyan}%s${reset}\n" "$1"
}

check_cmd bash
check_cmd jq
check_cmd curl

# ── Check bash version ──────────────────────────────────
bash_version="${BASH_VERSINFO[0]}"
if [ "$bash_version" -lt 4 ]; then
    printf "  ${red}✗${reset} Bash 4+ required (found %s)\n" "$BASH_VERSION"
    exit 1
fi
printf "  ${green}✓${reset} Bash %s\n" "$BASH_VERSION"

# ── Download script ─────────────────────────────────────
printf "\n"
mkdir -p "$INSTALL_DIR"

if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    printf "  ${yellow}!${reset} Existing ${cyan}%s${reset} found — backing up to ${dim}%s.bak${reset}\n" "$SCRIPT_NAME" "$SCRIPT_NAME"
    cp "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/${SCRIPT_NAME}.bak"
fi

printf "  ${dim}Downloading %s...${reset}\n" "$SCRIPT_NAME"
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
printf "  ${green}✓${reset} Installed to ${cyan}%s/%s${reset}\n" "$INSTALL_DIR" "$SCRIPT_NAME"

# ── Configure Claude Code settings ──────────────────────
printf "\n"
SETTINGS_FILE="$INSTALL_DIR/settings.json"

STATUSLINE_CONFIG='"statusLine": { "type": "command", "command": "bash ~/.claude/pacline.sh" }'

if [ -f "$SETTINGS_FILE" ]; then
    if grep -q '"statusLine"' "$SETTINGS_FILE" 2>/dev/null; then
        printf "  ${yellow}!${reset} Your ${cyan}settings.json${reset} already has a statusLine config.\n"
        printf "    Replace it with:\n"
        printf "\n"
        printf "    ${dim}\"statusLine\": {${reset}\n"
        printf "    ${dim}  \"type\": \"command\",${reset}\n"
        printf "    ${dim}  \"command\": \"bash ~/.claude/pacline.sh\"${reset}\n"
        printf "    ${dim}}${reset}\n"
    else
        # Add statusLine to existing settings
        tmp_file=$(mktemp)
        jq '. + { "statusLine": { "type": "command", "command": "bash ~/.claude/pacline.sh" } }' "$SETTINGS_FILE" > "$tmp_file" 2>/dev/null
        if [ $? -eq 0 ]; then
            mv "$tmp_file" "$SETTINGS_FILE"
            printf "  ${green}✓${reset} Added statusLine config to ${cyan}settings.json${reset}\n"
        else
            rm -f "$tmp_file"
            printf "  ${yellow}!${reset} Could not auto-update settings.json. Add manually:\n"
            printf "\n"
            printf "    ${dim}%s${reset}\n" "$STATUSLINE_CONFIG"
        fi
    fi
else
    # Create new settings file
    printf '{\n  "statusLine": {\n    "type": "command",\n    "command": "bash ~/.claude/pacline.sh"\n  }\n}\n' > "$SETTINGS_FILE"
    printf "  ${green}✓${reset} Created ${cyan}settings.json${reset} with statusLine config\n"
fi

# ── Done ────────────────────────────────────────────────
printf "\n"
printf "  ${yellow}ᗧ${reset} ${dim}• • •${reset} ${green}Ready!${reset} Restart Claude Code to see Pac-Man in action.\n"
printf "\n"
printf "  ${dim}ᗣ ᗣ ᗣ ᗧ · · · · · ●${reset}\n"
printf "\n"
