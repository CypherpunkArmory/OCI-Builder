#!/bin/sh
# The AiCLI app's image: AI coding CLIs on Node.js on top of userland-ubuntu.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
# Ubuntu's own Node.js: NodeSource's setup script doesn't cover new Ubuntu releases until well
# after they come out, and Ubuntu's Node is new enough for these CLIs.
apt-get install -y nodejs npm
npm install -g @anthropic-ai/claude-code @google/gemini-cli @openai/codex @github/copilot
npm cache clean --force
apt-get clean
rm -rf /var/lib/apt/lists/*
