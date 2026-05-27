# Claude Code Scheduled Task: TLDR Audio Briefing

**Copy and paste the content below into your Claude Code task at claude.ai/tasks**

---

## Task Configuration

- **Name:** TLDR Newsletter → Audio Briefing → Slack
- **Schedule:** Weekdays (Mon–Fri) at 11:00 AM EST
- **Network Access:** Full
- **Setup Script:** See section below

---

## Setup Script

Paste this into the "Setup" field in Claude Code Scheduled Tasks:

```bash
#!/bin/bash
pip install cryptography --break-system-packages -q
```

---

## Environment Variables

In the Claude Code task settings, add these environment variables:

```
GOOGLE_SA_JSON = (your full service account JSON as a single-line string)
SLACK_TOKEN = xoxb-...
SLACK_CHANNEL = C0...
```

**⚠️ DO NOT commit these to GitHub.** Store them only in Claude Code task secrets.

---

## Task Prompt

Paste the following prompt into your Claude Code task (replace `<env_vars>` with actual values from task settings):

```
---
name: tldr-audio-briefing
description: Daily TLDR newsletter → audio summary → Slack (weekdays 11 AM EST)
---

You are running an automated daily task. Today's date is available via the system clock.

## Credentials

GOOGLE_SA_JSON = {GOOGLE_SA_JSON_ENV_VAR}
SLACK_TOKEN = {SLACK_TOKEN_ENV_VAR}
SLACK_CHANNEL = {SLACK_CHANNEL_ENV_VAR}

## Your job: TLDR Newsletter → Audio Summary → Slack

Complete these steps in order. If any step fails, send a Slack message to the channel explaining which step failed and why, then stop.

### Step 1: Fetch today's TLDR emails

Search Gmail for TLDR newsletter emails received today using the query: `from:tldrnewsletter.com newer_than:1d`

Read the full content of every TLDR email found.

If no emails are found, send a Slack message saying "No TLDR emails found today." and stop.

### Step 2: Write a spoken-word audio briefing

TLDR emails have a predictable structure:
- **First section**: Always a sponsor ad — SKIP this entirely
- **Remaining sections**: Real news (Big Tech & Startups, Science, Programming, etc.)

Write a 450-550 word conversational audio briefing from the real news sections:
- Natural spoken prose only — no bullet points, markdown, headers, or URLs
- Use spoken transitions: "First up...", "Next...", "Also worth noting...", "And finally..."
- Cover 1-2 stories from each section
- Give priority to: major product launches, AI breakthroughs, significant industry shifts
- Each story gets 2-3 spoken sentences — headline + why it matters
- Open with: "Good morning! Here's your TLDR tech briefing for [today's date]."
- Close with: "That's your TLDR for today. Stay curious, and have a great day!"
- Never mention sponsors, ads, or promotional content

Save the briefing to /tmp/tldr_summary.txt using the Write tool.

### Step 3: Generate audio using Google Cloud TTS

[Python script for TTS - see ARCHITECTURE.md or repository for complete script]

### Step 4: Upload audio to GCS and post link to Slack

[Python script for GCS upload and Slack notification - see repository for complete script]
```

**Note:** The full Python scripts for Steps 3–4 are in the GitHub repository. You can copy them directly into your task prompt.

---

## How to Set Up

1. **Create GCP resources:**
   - Create a GCP project
   - Enable Text-to-Speech and Cloud Storage APIs
   - Create a service account with `roles/iam.serviceAccountTokenCreator` + `roles/storage.objectCreator` + `roles/storage.objectViewer`
   - Download the service account JSON

2. **Create GCS bucket:**
   - Bucket name: `tldr-audio-briefings` (or custom name)
   - Region: `us-central1`
   - **Important:** Disable "Enforce public access prevention" so you can set per-object ACLs
   - Verify `uniformBucketLevelAccess: false`

3. **Get Slack credentials:**
   - Create a Slack app in your workspace
   - Add `chat:write` permission
   - Generate a bot token (`xoxb-...`)
   - Add bot to your target channel
   - Get the channel ID (right-click channel → Copy channel ID)

4. **Go to claude.ai/tasks:**
   - Click "Create New Task"
   - Enter task name: `tldr-audio-briefing`
   - Set schedule: Weekdays, 11:00 AM EST
   - Set network access: **Full** (critical for Google APIs)
   - Paste the setup script above
   - Add environment variables from Step 1–3
   - Paste the complete task prompt (with Python scripts)
   - Save and test!

---

## Testing Locally (Optional)

To test the pipeline manually before deploying to Claude Code:

```bash
# Set environment variables
export GOOGLE_SA_JSON='...'
export SLACK_TOKEN='...'
export SLACK_CHANNEL='...'

# Run the task
python3 task.py
```

---

## Monitoring

Check your Claude Code dashboard to see:
- Last execution time
- Success/failure status
- Slack notifications (auto-posted on each run)

---

## Troubleshooting

See `TROUBLESHOOTING.md` in the repository for common issues and solutions.
```

---

**End of Task Prompt**

---

### Important Notes

1. **Network access must be "Full":** Google Cloud APIs (`oauth2.googleapis.com`, `texttospeech.googleapis.com`, `storage.googleapis.com`) are not on Claude Code's default allowlist.

2. **Environment variables:** Paste the full service account JSON as a single-line string (replace newlines with `\n` or paste directly into the task settings UI).

3. **GCS bucket configuration:** Ensure `uniformBucketLevelAccess: false` so you can set `predefinedAcl=publicRead` on individual objects.

4. **Testing:** Always test manually once before scheduling to catch credential/configuration issues.
