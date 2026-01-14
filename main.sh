#!/bin/bash

set -e

API_URL="https://discord.com/api/v10"

install_deps() {
  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y curl jq
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y curl jq
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm curl jq
  elif command -v brew >/dev/null 2>&1; then
    brew install curl jq
  else
    echo "No supported package manager found. Please install curl and jq manually."
    exit 1
  fi
}

echo "Checking dependencies..."
install_deps

read -s -p "Enter Discord bot token: " TOKEN
echo

AUTH_HEADER="Authorization: Bot $TOKEN"

BOT_INFO=$(curl -s -H "$AUTH_HEADER" "$API_URL/users/@me")

if ! echo "$BOT_INFO" | jq -e '.id' >/dev/null 2>&1; then
  echo "Invalid token"
  exit 1
fi

BOT_ID=$(echo "$BOT_INFO" | jq -r '.id')
USERNAME=$(echo "$BOT_INFO" | jq -r '.username')
DISCRIMINATOR=$(echo "$BOT_INFO" | jq -r '.discriminator')
IS_BOT=$(echo "$BOT_INFO" | jq -r '.bot')

echo
echo "Bot information"
echo "---------------"
echo "ID           : $BOT_ID"
echo "Username     : $USERNAME"
echo "Discriminator: $DISCRIMINATOR"
echo "Bot account  : $IS_BOT"
echo

echo "Guilds"
echo "------"

GUILDS=$(curl -s -H "$AUTH_HEADER" "$API_URL/users/@me/guilds")

if [[ $(echo "$GUILDS" | jq length) -eq 0 ]]; then
  echo "No guilds found"
else
  echo "$GUILDS" | jq -r '.[] | "- \(.name) (ID: \(.id))"'
fi

echo
echo "Actions"
echo "1) Change bot username"
echo "2) Exit"
read -p "Choice: " CHOICE

if [[ "$CHOICE" == "1" ]]; then
  read -p "New bot username: " NEW_NAME

  RESPONSE=$(curl -s -X PATCH \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$NEW_NAME\"}" \
    "$API_URL/users/@me")

  if echo "$RESPONSE" | jq -e '.username' >/dev/null 2>&1; then
    echo "Username successfully changed to: $(echo "$RESPONSE" | jq -r '.username')"
    echo "Note: Discord enforces strict rate limits on username changes."
  else
    echo "Failed to change username"
    echo "$RESPONSE" | jq
  fi
fi
