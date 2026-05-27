# Quick Start Guide

Get your TLDR Audio Briefing pipeline running in 15 minutes.

## Prerequisites Checklist

- [ ] TLDR newsletter email subscription (free at tldrnewsletter.com)
- [ ] Google Cloud account with a project
- [ ] Slack workspace and a channel to post to
- [ ] Claude.ai account (free tier available)

## Step 1: Set Up Google Cloud (5 minutes)

1. **Create GCS bucket:**
   ```bash
   gsutil mb -c STANDARD -l us-central1 gs://tldr-audio-briefings
   ```

2. **Disable uniform bucket ACLs** (so you can make files public):
   ```bash
   gsutil uniformbucketlevelaccess set off gs://tldr-audio-briefings
   ```

3. **Create service account:**
   - Go to [console.cloud.google.com](https://console.cloud.google.com)
   - Select your project
   - IAM & Admin → Service Accounts → Create Service Account
   - Name: `tldr-account`
   - Click "Create and Continue"

4. **Add roles to service account:**
   - Click the new service account
   - Go to the "Keys" tab
   - Click "Add Key" → "Create new key" → JSON
   - **Save this JSON file — you'll need it in Step 3**
   - Go back to the service account overview
   - Click "Grant roles"
   - Add these roles:
     - `roles/iam.serviceAccountTokenCreator`
     - `roles/storage.objectCreator`
     - `roles/storage.objectViewer`
     - `roles/iam.serviceAccountUser`

5. **Enable APIs:**
   - Go to APIs & Services → Enabled APIs & Services
   - Click "Enable APIs and Services"
   - Search for "Text-to-Speech"
   - Click → Enable
   - Repeat for "Cloud Storage API"

## Step 2: Set Up Slack (3 minutes)

1. **Create Slack app:**
   - Go to [api.slack.com/apps](https://api.slack.com/apps)
   - Click "Create New App" → "From scratch"
   - Name: `TLDR Briefing`
   - Select your workspace

2. **Add permissions:**
   - Go to "OAuth & Permissions"
   - Under "Scopes" → "Bot Token Scopes", click "Add an OAuth Scope"
   - Add: `chat:write`
   - Click "Install to Workspace"
   - Copy the "Bot User OAuth Token" (starts with `xoxb-`)
   - **Save this token — you'll need it in Step 3**

3. **Get channel ID:**
   - Go to your Slack workspace
   - Right-click the target channel (e.g., #announcements)
   - Click "Copy channel ID"
   - **Save this ID — you'll need it in Step 3**

4. **Add bot to channel:**
   - Go to the channel
   - Click the channel name at the top
   - Go to "Members" → "Add members"
   - Select your `TLDR Briefing` bot
   - Click "Add"

## Step 3: Configure Claude Code (5 minutes)

1. **Go to [claude.ai/tasks](https://claude.ai/tasks)**

2. **Click "Create New Task"**

3. **Fill in task details:**
   - **Name:** `tldr-audio-briefing`
   - **Description:** `Daily TLDR newsletter → audio summary → Slack`
   - **Schedule:** Weekdays at 11:00 AM EST
   - **Network Access:** Full

4. **Add setup script:**
   - Paste the contents of `setup.sh` from this repo:
     ```bash
     #!/bin/bash
     pip install cryptography --break-system-packages -q
     ```

5. **Add environment variables:**
   - Click "Add Environment Variable" and add:
     ```
     GOOGLE_SA_JSON = (paste the full service account JSON from Step 1)
     SLACK_TOKEN = xoxb-... (from Step 2)
     SLACK_CHANNEL = C0... (from Step 2)
     ```

6. **Add task prompt:**
   - Copy the complete task prompt from `task-prompt.md` in this repo
   - Paste into the "Prompt" field
   - Make sure it includes both the setup script AND the Python code for Steps 3–4

7. **Test the task:**
   - Click "Run Now"
   - Wait 30–40 seconds
   - Check your Slack channel for a message from the bot
   - If successful, you should see: "🎧 Your TLDR Tech Briefing is ready! [Click to listen](...)"

## Step 4: Verify It Works (2 minutes)

1. **Check Slack message:**
   - Go to the channel where you added the bot
   - Look for the briefing message with audio link

2. **Test the audio link:**
   - Click "Click to listen" in the Slack message
   - Audio should play in your browser or app

3. **Check task logs:**
   - Go back to [claude.ai/tasks](https://claude.ai/tasks)
   - Click the task
   - View "Recent Runs" to see execution details

## You're Done! 🎉

Your TLDR Audio Briefing will now run **automatically every weekday at 11:00 AM EST**.

Check your Slack channel the next morning for your briefing.

## Next Steps

- **Customize the briefing tone:** Edit Step 2 in the task prompt to change how stories are selected
- **Change the schedule:** Edit "Schedule" in task settings (e.g., 9 AM instead of 11 AM)
- **Add more channels:** Duplicate the task with a different channel ID in the environment variable
- **Share on GitHub:** This entire project is designed to be shareable without exposing secrets (see [GitHub instructions](./README.md#sharing-on-github))

## Troubleshooting

If something doesn't work:

1. **Check Slack for error message:**
   - The task posts error details if it fails
   - Error message tells you which step failed

2. **See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md):**
   - Common issues and how to fix them
   - Debug checklist

3. **Enable debug logging:**
   - Add `print(...)` statements in the task prompt
   - Re-run and check task output logs

## Questions?

- See [ARCHITECTURE.md](./ARCHITECTURE.md) for technical deep dive
- See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- Open a GitHub issue if you get stuck

Happy briefing! 📻
