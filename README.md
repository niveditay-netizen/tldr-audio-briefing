# TLDR Audio Briefing Pipeline

Automated daily task that converts TLDR newsletter emails into conversational audio briefings and delivers them to Slack.

**Status:** ✅ MVP complete with end-to-end manual testing  
**Hosting:** Claude Code Scheduled Tasks (Anthropic)  
**Schedule:** Weekdays 11 AM EST

## What it does

1. **Fetch** → Pulls daily TLDR newsletter emails from Gmail (main, Dev, Design, Founders variants)
2. **Summarize** → Extracts key stories and generates a 450–550 word spoken-word briefing
3. **Synthesize** → Converts briefing text to audio using Google Cloud Text-to-Speech
4. **Store** → Uploads MP3 to Google Cloud Storage with public URL
5. **Notify** → Posts audio link to Slack channel for your team

## Architecture

```
Gmail (TLDR emails)
        ↓
    [Extract & Parse]
        ↓
    [Write Briefing] (450-550 words, spoken prose)
        ↓
Google Cloud TTS (Neural2-F voice, 1.05x speed, MP3)
        ↓
Google Cloud Storage (public read bucket)
        ↓
Slack (channel notification + audio link)
```

## Setup & Deployment

### Prerequisites

- **Gmail account** with TLDR newsletter subscription
- **Google Cloud project** with:
  - Text-to-Speech API enabled
  - Cloud Storage bucket created (`tldr-audio-briefings`)
  - Service account with TTS + GCS permissions
- **Slack workspace** with:
  - Bot token with `chat:write` permission
  - Target channel ID
- **Claude Code Scheduled Tasks** account (free tier available at claude.ai)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/tldr-audio-briefing.git
   cd tldr-audio-briefing
   ```

2. **Set up environment variables**
   
   Create a `.env` file (never commit this):
   ```bash
   GOOGLE_SA_JSON='{"type":"service_account", ... }' # Your GCP service account JSON
   SLACK_TOKEN='xoxb-...'                             # Your Slack bot token
   SLACK_CHANNEL='C0...'                              # Target Slack channel ID
   ```

3. **Configure Claude Code Scheduled Tasks**
   
   - Visit [claude.ai/tasks](https://claude.ai/tasks)
   - Create a new scheduled task
   - Set schedule: **Weekdays at 11:00 AM EST**
   - Network access: **Full** (required for Google APIs)
   - Setup script (see [`setup.sh`](#setup-script-reference))
   - Paste the task prompt from [`task-prompt.md`](./task-prompt.md)

4. **Verify GCS bucket configuration**
   
   Your bucket must have:
   ```
   uniformBucketLevelAccess: false
   predefinedAcl: publicRead (per object)
   ```
   
   This ensures the generated MP3 URLs are publicly accessible without additional auth headers.

### Setup Script Reference

The setup script (pasted into Claude Code Scheduled Tasks) installs dependencies and configures the environment:

```bash
#!/bin/bash
pip install cryptography --break-system-packages -q
export GOOGLE_SA_JSON='...'  # Populated from env var
export SLACK_TOKEN='...'     # Populated from env var
export SLACK_CHANNEL='...'   # Populated from env var
```

**Important:** Network access must be set to **Full**, not Trusted, because `oauth2.googleapis.com` and `texttospeech.googleapis.com` may not be on the default allowlist.

## How It Works

### Step 1: Fetch TLDR Emails
```
Gmail search: from:tldrnewsletter.com newer_than:1d
```
- Searches for all TLDR variants received today
- Reads full email body (subject + content) for each result
- Skips emails if none found (posts notification to Slack)

### Step 2: Write Audio Briefing
- **Skips** the first section (always a sponsor ad)
- Covers real news sections: Big Tech, Science, Programming, Design, Startups, etc.
- Generates 450–550 words of conversational, spoken prose
- Uses transitions: "First up...", "Next...", "Also worth noting..."
- Each story gets 2–3 spoken sentences: headline + why it matters
- Adds opening: `"Good morning! Here's your TLDR tech briefing for [date]."`
- Adds closing: `"That's your TLDR for today. Stay curious, and have a great day!"`

### Step 3: Generate Audio
- **Service:** Google Cloud Text-to-Speech API
- **Voice:** `en-US-Neural2-F` (natural, professional female voice)
- **Speed:** 1.05x (slightly faster than natural for punchiness)
- **Format:** MP3
- **Auth:** JWT-based service account auth (no `google-auth` lib needed, only `cryptography`)

### Step 4: Upload & Share
- **Upload:** MP3 to GCS bucket with `predefinedAcl=publicRead`
- **Filename:** `tldr_YYYY-MM-DD.mp3`
- **Public URL:** `https://storage.googleapis.com/tldr-audio-briefings/tldr_YYYY-MM-DD.mp3`
- **Slack:** Posts message with clickable audio link

## Key Technical Decisions

### Why JWT Service Account Auth?
- No heavy Google libraries (`google-auth`, `google-cloud-*`)
- Only requires Python's `cryptography` package
- Fully self-contained in ~20 lines of code
- Works in restricted environments (Claude Code Scheduled Tasks)

### Why Claude Code Scheduled Tasks?
- Cloud-hosted (no local machine required)
- Integrates with Gmail/Slack via MCP
- Free tier available
- No GitHub Actions setup, cron jobs, or infrastructure overhead

### Why Neural2-F + 1.05x Speed?
- Neural2-F: Natural-sounding female voice (professional, approachable)
- 1.05x: Slightly faster than natural speech, better for information delivery
- 450–550 words: ~4–5 minutes of audio (digestible morning briefing length)

## Monitoring & Troubleshooting

### Check Recent Runs
Visit your Claude Code task dashboard to see:
- Last execution timestamp
- Run duration
- Slack notification (success or error message)

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "No TLDR emails found" | TLDR newsletter not subscribed or Gmail search failed | Check Gmail filters; verify `from:tldrnewsletter.com` matches inbox |
| GCS upload fails with `403` | Service account lacks GCS permissions | Re-check IAM roles: `roles/storage.objectCreator` |
| Audio URL returns 403 | Bucket lacks `predefinedAcl=publicRead` or wrong bucket policy | Verify `uniformBucketLevelAccess: false` and object ACL |
| Slack message fails to post | Invalid token or channel ID | Verify token scopes include `chat:write` and channel exists |
| TTS fails with network error | Domain not allowlisted | Ensure network access set to **Full** in Claude Code task settings |

## File Structure

```
tldr-audio-briefing/
├── README.md                    # This file
├── task-prompt.md               # Complete task prompt (paste into Claude Code)
├── setup.sh                     # Setup script (reference only)
├── ARCHITECTURE.md              # Deep dive into pipeline design
├── TROUBLESHOOTING.md           # Common issues & solutions
├── examples/
│   ├── sample-briefing.txt      # Example audio briefing output
│   ├── sample-slack-message.md  # Example Slack notification
│   └── gcs-bucket-config.json   # Reference bucket configuration
└── .gitignore                   # Excludes .env and credentials
```

## Example Output

### Audio Briefing Text (450–550 words)
```
Good morning! Here's your TLDR tech briefing for May 27, 2026.

First up in Big Tech: OpenAI released GPT-5, a new reasoning model that 
can tackle complex multi-step problems. The model is now available via API 
and claims 40% improvement on reasoning benchmarks. This is significant for 
enterprises building AI agents.

Next, in Science: Researchers at MIT published a breakthrough in quantum 
error correction, achieving logical qubits that maintain coherence longer 
than raw qubits. This is a major step toward practical quantum computers, 
and major tech companies are already integrating the techniques.

Also worth noting: A new startup called Anthropic-Competitor raised $500M 
in Series B funding...

That's your TLDR for today. Stay curious, and have a great day!
```

### Slack Message
```
🎧 *Your TLDR Tech Briefing is ready!* Listen to today's top stories 👇
[Click to listen](https://storage.googleapis.com/tldr-audio-briefings/tldr_2026-05-27.mp3)
```

## Contributing

This is a personal project, but ideas and suggestions are welcome! Open an issue to discuss improvements.

## License

MIT License – see LICENSE file

## Roadmap

- [ ] Support multiple Slack channels
- [ ] Add morning/evening briefing variants
- [ ] Integrate Apple Podcasts RSS feed
- [ ] Add transcript generation + archival
- [ ] Custom briefing topics (e.g., AI-only, startup-only)
- [ ] Email delivery of briefing transcript

## Contact

Questions? Reach out on [Twitter](https://twitter.com/yourhandle) or open a GitHub issue.
