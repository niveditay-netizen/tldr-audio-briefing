#!/bin/bash
# Setup script for TLDR Audio Briefing Pipeline (Claude Code Scheduled Tasks)
#
# This script is pasted into the "Setup" field in Claude Code task settings.
# It runs once per task execution to prepare the environment.
#
# Note: Environment variables (GOOGLE_SA_JSON, SLACK_TOKEN, SLACK_CHANNEL)
# are populated from the task's environment variable settings in Claude Code.

# Install Python dependencies
pip install cryptography --break-system-packages -q

# The following are examples; actual values come from Claude Code task settings:
# export GOOGLE_SA_JSON='...'     # Full service account JSON (populated by Claude Code)
# export SLACK_TOKEN='xoxb-...'   # Slack bot token (populated by Claude Code)
# export SLACK_CHANNEL='C0...'    # Slack channel ID (populated by Claude Code)

# No additional setup needed; the task prompt (pasted after this script)
# has full access to these environment variables.

echo "Environment ready. Starting task..."
