# Troubleshooting Guide

## Quick Diagnosis

1. **Check Claude Code dashboard** for last execution status and error messages
2. **Check Slack channel** for error notification from the task
3. **Check Google Cloud Console** for API quota/permission issues
4. **Check GCS bucket** for uploaded MP3 files (if it got that far)

---

## Common Issues & Solutions

### 1. "No TLDR emails found today"

**Symptoms:** Task runs but Slack shows "No TLDR emails found today."

**Possible causes:**
- TLDR newsletter not subscribed
- Newsletter email goes to spam/filtered folder
- Gmail search query doesn't match your email

**Solutions:**

a) **Verify TLDR subscription:**
   - Log into Gmail
   - Search: `from:tldrnewsletter.com`
   - Do you see past TLDR emails? (If not, subscribe at tldrnewsletter.com)

b) **Check Gmail filters/labels:**
   - Make sure TLDR emails are in your inbox (not archived/labeled)
   - Try searching with advanced Gmail query:
     ```
     from:tldrnewsletter.com is:inbox newer_than:1d
     ```

c) **Check timezone:**
   - Task runs at 11 AM **EST**
   - TLDR typically sends ~9 AM EST
   - Verify your Gmail account timezone matches

d) **Manual test (run task immediately):**
   - Go to Claude Code task dashboard
   - Click "Run Now" instead of waiting for scheduled execution
   - Check if today's email arrives

---

### 2. Gmail API Fails to Authenticate

**Symptoms:** Slack message says "Gmail search failed" or "Failed to authenticate to Gmail"

**Possible causes:**
- Claude Code task doesn't have Gmail MCP enabled
- Gmail account not connected to Claude

**Solutions:**

a) **Enable Gmail MCP in Claude Code task:**
   - Go to task settings
   - Under "Integrations" or "MCP Servers", ensure Gmail is enabled
   - Re-run task

b) **Connect Gmail to Claude.ai:**
   - Visit [claude.ai/settings](https://claude.ai/settings)
   - Go to "Connected apps" or "Integrations"
   - Click "Connect Gmail"
   - Authorize the scope popup
   - Re-run task

c) **Check Gmail permissions:**
   - Visit [myaccount.google.com/permissions](https://myaccount.google.com/permissions)
   - Find "Claude" or "Anthropic"
   - Ensure it has "Gmail" access

---

### 3. Google Cloud TTS Fails

**Symptoms:** Slack message says "Text-to-Speech generation failed"

**Error patterns:**
- `403 Forbidden` → Service account lacks permissions or quota exceeded
- `401 Unauthorized` → JWT auth failed or token expired
- `400 Bad Request` → Invalid TTS request parameters
- `503 Service Unavailable` → Google Cloud API is down

**Solutions:**

a) **Check service account permissions:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Project: `tldr-briefing-491917`
   - IAM & Admin → Service Accounts
   - Click `tldr-account@tldr-briefing-491917.iam.gserviceaccount.com`
   - Verify roles: `roles/iam.serviceAccountTokenCreator` + `roles/iam.serviceAccountUser`
   - For TTS specifically: `roles/serviceusage.serviceUsageConsumer`

b) **Check TTS API is enabled:**
   - Go to APIs & Services → Enabled APIs
   - Search for "Text-to-Speech"
   - If not listed, click "Enable"

c) **Check TTS quota:**
   - Go to APIs & Services → Quotas
   - Search for "Cloud Text-to-Speech API"
   - Check if you're hitting daily quota
   - Request quota increase if needed

d) **Verify request parameters:**
   - Ensure `text` is not empty
   - Ensure voice `languageCode` is valid (`en-US`)
   - Ensure voice `name` exists (`en-US-Neural2-F`)
   - Ensure `audioEncoding` is `MP3`

e) **Test manually with curl:**
   ```bash
   export GOOGLE_SA_JSON='...'
   export TOKEN=$(python3 -c "
   import json, base64, time, subprocess
   from cryptography.hazmat.primitives import serialization, hashes
   from cryptography.hazmat.primitives.asymmetric import padding
   from cryptography.hazmat.backends import default_backend
   
   sa = json.loads(os.environ['GOOGLE_SA_JSON'])
   # [JWT code from task-prompt.md]
   # Print token
   ")
   
   curl -X POST https://texttospeech.googleapis.com/v1/text:synthesize \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"input":{"text":"Hello world"},"voice":{"languageCode":"en-US","name":"en-US-Neural2-F"},"audioConfig":{"audioEncoding":"MP3"}}'
   ```

---

### 4. GCS Upload Fails / 403 Forbidden

**Symptoms:** Slack message says "Failed to upload audio to GCS"

**Possible causes:**
- Service account lacks GCS permissions
- Bucket doesn't exist
- Bucket ACL not configured correctly
- Network access blocked

**Solutions:**

a) **Check service account GCS permissions:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - IAM & Admin → Service Accounts
   - Click `tldr-account@...`
   - Check roles: Must have `roles/storage.objectCreator` + `roles/storage.objectViewer`
   - If missing, click "Add Role" and add both

b) **Verify bucket exists and is accessible:**
   ```bash
   gsutil ls -b gs://tldr-audio-briefings
   ```
   If bucket doesn't exist:
   ```bash
   gsutil mb -c STANDARD -l us-central1 gs://tldr-audio-briefings
   ```

c) **Check bucket ACL settings:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Cloud Storage → Buckets
   - Click `tldr-audio-briefings`
   - Go to "Permissions"
   - Ensure `tldr-account@...` has `roles/storage.objectCreator` on the bucket
   - Go to "Edit Bucket Configuration"
   - Under "Uniform bucket-level access", click "Edit"
   - **Turn OFF** "Enforce public access prevention"
   - Save

d) **Verify per-object ACL is set:**
   - Upload a test file with `predefinedAcl=publicRead`:
   ```bash
   gsutil -h "Cache-Control:public, max-age=3600" acl ch -u AllUsers:R gs://tldr-audio-briefings/test.txt
   ```
   - Try to access the public URL: `https://storage.googleapis.com/tldr-audio-briefings/test.txt`
   - If 403, the bucket ACL is blocking public access

e) **Check network access in Claude Code:**
   - Go to task settings
   - Network access: Must be set to **"Full"** (not "Trusted")
   - `storage.googleapis.com` is not on the default allowlist

---

### 5. Slack Message Fails to Post

**Symptoms:** Slack shows "Failed to post to Slack channel"

**Possible causes:**
- Invalid bot token
- Channel ID incorrect
- Bot not added to channel
- Slack API is down

**Solutions:**

a) **Verify bot token:**
   - Go to [api.slack.com/apps](https://api.slack.com/apps)
   - Select your app
   - Click "OAuth & Permissions"
   - Copy the "Bot User OAuth Token" (starts with `xoxb-`)
   - Paste into Claude Code task environment variable `SLACK_TOKEN`

b) **Verify channel ID:**
   - Go to your Slack workspace
   - Right-click the target channel
   - Click "Copy channel ID"
   - Paste into Claude Code task environment variable `SLACK_CHANNEL`

c) **Verify bot is in the channel:**
   - Go to the target channel in Slack
   - Click the channel name at the top
   - Go to "Members" or "Details"
   - Look for your bot name (e.g., `tldr-bot`)
   - If not there, click "Add members" and add the bot

d) **Verify bot has chat:write permission:**
   - Go to [api.slack.com/apps](https://api.slack.com/apps)
   - Select your app
   - Click "OAuth & Permissions"
   - Under "Scopes" → "Bot Token Scopes", verify `chat:write` is listed
   - If not, click "Add an OAuth Scope" and add `chat:write`
   - Reinstall the app to your workspace

e) **Test Slack API manually:**
   ```bash
   curl -X POST https://slack.com/api/chat.postMessage \
     -H "Authorization: Bearer xoxb-..." \
     -H "Content-Type: application/json" \
     -d '{
       "channel": "C0ANY873YP4",
       "text": "Test message from TLDR pipeline"
     }'
   ```

---

### 6. Network Access Errors (oauth2.googleapis.com, texttospeech.googleapis.com)

**Symptoms:** Curl fails with "Connection refused" or "Network is unreachable"

**Root cause:** Claude Code network access is set to "Trusted" (default), which only allows a whitelist of domains. Google APIs not on the list.

**Solution:**

a) **Set network access to "Full":**
   - Go to Claude Code task settings
   - Find "Network Access" or "Egress" setting
   - Change from "Trusted" to "Full"
   - Save

b) **Verify allowed domains include:**
   - `oauth2.googleapis.com`
   - `texttospeech.googleapis.com`
   - `storage.googleapis.com`

c) **If "Additional allowed domains" option exists:**
   - Add these domains:
     ```
     oauth2.googleapis.com
     texttospeech.googleapis.com
     storage.googleapis.com
     ```

---

### 7. Task Runs but Nothing Happens

**Symptoms:** Task shows "Completed" but no Slack message appears

**Possible causes:**
- Task completed successfully but hasn't posted to Slack yet
- Slack posting is the last step (so if Slack API is slow, you might not see it immediately)
- Claude Code environment variable expansion failed silently

**Solutions:**

a) **Wait a few seconds:** Sometimes Slack takes 5–10 seconds to deliver messages.

b) **Check Slack workspace notifications:**
   - Make sure your workspace notification settings allow bot messages
   - Check the channel directly (go to channel, scroll up to today's messages)

c) **Verify environment variables:**
   - Go to task settings
   - Click "Edit" on environment variables
   - Ensure all three are filled in:
     - `GOOGLE_SA_JSON` (full JSON as single line)
     - `SLACK_TOKEN` (xoxb-...)
     - `SLACK_CHANNEL` (C0...)

d) **Enable debug logging:**
   - Re-run the task and check Claude Code output logs
   - Look for error messages or print statements from the Python scripts

e) **Check GCS bucket:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Cloud Storage → Buckets → `tldr-audio-briefings`
   - Are there any MP3 files uploaded today?
   - If yes, task got far enough to generate audio (Slack post is the only remaining step)

---

### 8. Audio Quality Issues

**Symptoms:** MP3 audio is generated but sounds poor (robotic, unnatural, too fast/slow)

**Solutions:**

a) **Adjust speaking rate (if unnatural speed):**
   - Current: `1.05x` (slightly faster)
   - Try: `1.0x` (natural speed) or `0.95x` (slower, more dramatic)
   - Edit the TTS request in the task prompt:
     ```python
     'audioConfig': {'audioEncoding': 'MP3', 'speakingRate': 1.0}
     ```

b) **Change voice (if robotic):**
   - Current: `en-US-Neural2-F`
   - Alternatives:
     - `en-US-Neural2-A` (male voice)
     - `en-US-Neural2-C` (male, higher pitch)
     - `en-US-Neural2-E` (female, different tone)
   - Test different voices by editing the task prompt and running manually

c) **Improve briefing text (if unnatural pacing):**
   - Add more punctuation (commas, periods) to clarify pauses
   - Break long sentences into shorter ones
   - Add natural words like "um," "you know" if it helps

d) **Check briefing word count:**
   - Current target: 450–550 words
   - Too short (<300 words): Feels rushed
   - Too long (>650 words): Feels dragging
   - Adjust in Step 2 (writing the briefing)

---

### 9. GCS Files Not Publicly Accessible

**Symptoms:** Audio link works initially, then returns 403 after a few hours

**Possible causes:**
- Object ACL not set correctly
- Bucket has "Enforce public access prevention" enabled
- `uniformBucketLevelAccess` is `true` (prevents per-object ACLs)

**Solutions:**

a) **Disable "Enforce public access prevention":**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Cloud Storage → Buckets → `tldr-audio-briefings`
   - Click "Edit bucket configuration"
   - Under "Uniform bucket-level access", click "Edit"
   - **Turn OFF** "Enforce public access prevention"
   - Save

b) **Set `uniformBucketLevelAccess` to false:**
   - Go to bucket permissions
   - Ensure `uniformBucketLevelAccess: false` in the bucket JSON config
   - Verify via `gsutil`:
     ```bash
     gsutil uniformbucketlevelaccess get gs://tldr-audio-briefings
     ```
     Should show: `Enabled: False`

c) **Verify object ACL after upload:**
   - List objects with ACL:
     ```bash
     gsutil acl get gs://tldr-audio-briefings/tldr_2026-05-27.mp3
     ```
   - Should include: `"role": "roles/storage.objectViewer", "entity": "allUsers"`

d) **Manually fix uploaded files:**
   ```bash
   gsutil acl ch -u AllUsers:R gs://tldr-audio-briefings/tldr_2026-05-27.mp3
   ```

---

### 10. Task Never Runs (Scheduled Task Not Triggering)

**Symptoms:** Task is configured but never executes at 11 AM

**Possible causes:**
- Schedule is wrong (not weekdays, or wrong time zone)
- Task is disabled
- Weekday calculation is wrong (e.g., Sunday is weekday 0)

**Solutions:**

a) **Verify schedule:**
   - Go to task settings
   - Check "Schedule" or "Frequency"
   - Should show: "Weekdays at 11:00 AM EST"
   - Not: "Daily", "Every 6 hours", etc.

b) **Check time zone:**
   - Schedule time zone should be **EST** (or UTC with manual conversion)
   - If you're in a different time zone, convert: 11 AM EST = ? in your local time
   - For example: 11 AM EST = 10 AM CST = 9 AM MST = 8 AM PST

c) **Verify task is enabled:**
   - Go to task settings
   - Look for "Enable", "Active", or toggle switch
   - Ensure it's turned **ON**

d) **Test manually:**
   - Click "Run Now" button in task dashboard
   - Should execute immediately
   - Check output/logs
   - If manual run works, task is fine; scheduled execution might just not have run yet

e) **Check your timezone in Claude Code:**
   - Some Claude Code environments might use UTC by default
   - If scheduled for "11 AM EST" but runs at "4 PM UTC", time zone conversion might be the issue
   - Verify by checking actual execution time in task logs

---

## Debug Checklist

Before opening an issue, verify:

- [ ] TLDR newsletter is subscribed in Gmail
- [ ] Task is enabled in Claude Code
- [ ] Network access is set to "Full"
- [ ] All environment variables are filled (GOOGLE_SA_JSON, SLACK_TOKEN, SLACK_CHANNEL)
- [ ] Google Cloud TTS and Storage APIs are enabled
- [ ] Service account has correct roles (TTS, Storage, Token Creator)
- [ ] GCS bucket exists and has correct ACL settings
- [ ] Slack bot token is valid and has `chat:write` permission
- [ ] Slack bot is added to the target channel
- [ ] Gmail is connected to Claude.ai (if using MCP)
- [ ] Task has been run manually at least once (to verify credentials work)

---

## Getting Help

**If you're still stuck:**

1. **Check Google Cloud Console** for detailed error messages in:
   - Cloud Logging (logs for TTS and Storage API calls)
   - IAM & Admin (verify service account permissions)

2. **Check Slack API logs** at [api.slack.com/apps](https://api.slack.com/apps):
   - Select your app
   - Click "Event Subscriptions" or "Activity"
   - Look for failed API calls

3. **Enable verbose logging** in the task prompt:
   - Add `print()` statements after each major step
   - Re-run and check Claude Code output logs

4. **Test components individually:**
   - Test Gmail search manually
   - Test TTS via curl
   - Test GCS upload via `gsutil`
   - Test Slack API via curl

5. **Open a GitHub issue** with:
   - Error message from Slack notification
   - Cloud Logging error details (redact any credentials)
   - Which step is failing (Gmail, TTS, GCS, Slack)
   - Verification checklist items (✓ or ✗)
