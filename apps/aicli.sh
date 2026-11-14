#!/bin/sh
# The AiCLI app's image: AI coding CLIs on Node.js LTS on top of userland-ubuntu.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs
npm install -g @anthropic-ai/claude-code @google/gemini-cli @openai/codex @github/copilot
npm cache clean --force
apt-get clean
rm -rf /var/lib/apt/lists/*
