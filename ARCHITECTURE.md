# TLDR Audio Briefing – Architecture & Design

## Overview

The TLDR Audio Briefing pipeline is a fully automated, cloud-native task that:
1. Fetches daily TLDR newsletter emails from Gmail
2. Extracts key stories and synthesizes them into conversational prose
3. Converts the briefing to audio via Google Cloud Text-to-Speech
4. Uploads the MP3 to Google Cloud Storage with a public URL
5. Posts the audio link to a Slack channel

**Total runtime:** ~30–40 seconds  
**Cost per day:** ~$0.03 (TTS) + storage fees (~$0.001)  
**Reliability:** Manual testing passed end-to-end; scheduled on Claude Code Scheduled Tasks (Anthropic-hosted)

---

## Pipeline Flow

```
┌──────────────────┐
│  Gmail Search    │
│ (from:tldr...)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Read Emails     │
│ (full content)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Extract News    │
│ (skip sponsors)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Write Briefing   │
│ (450-550 words)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Google TTS      │
│ (Neural2-F MP3)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  GCS Upload      │
│ (publicRead ACL) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Slack Message   │
│ (audio link)     │
└──────────────────┘
```

---

## Step-by-Step Breakdown

### Step 1: Fetch TLDR Emails from Gmail

**Query:** `from:tldrnewsletter.com newer_than:1d`

**Why this query:**
- `from:tldrnewsletter.com` → Matches all TLDR variants (main, Dev, Design, Founders, etc.)
- `newer_than:1d` → Fetches only today's emails (run once per day)

**Output:** List of message IDs and metadata

**What to do if no emails found:**
- Post Slack notification: "No TLDR emails found today."
- Exit gracefully (no error)

---

### Step 2: Read Full Email Content

**For each email found in Step 1:**

1. Use Gmail API to fetch full message by ID
2. Extract subject (headline) and body (full content)
3. Parse the body to identify sections

**Email Structure (TLDR Newsletters):**
```
[SPONSOR AD / PROMOTIONAL CONTENT]
────────────────────────────────────
[REAL NEWS]

Big Tech & Startups
- Story 1
- Story 2
- ...

Science
- Story 1
- ...

Programming
- Story 1
- ...

[Other sections: Design, Founders, etc.]
```

**Key insight:** The first section is always a sponsor ad. Skip it entirely.

---

### Step 3: Write Audio Briefing (450–550 words)

**Input:** Parsed sections from Step 2  
**Output:** Conversational, spoken-word text file (`/tmp/tldr_summary.txt`)

**Structural Requirements:**

1. **Opening:** 
   ```
   Good morning! Here's your TLDR tech briefing for [Date in words, e.g., "May 27, 2026"].
   ```

2. **Body:** 1–2 stories per section, 2–3 sentences each
   - Use natural spoken transitions: "First up...", "Next...", "Also worth noting...", "And finally..."
   - Each story: headline (1 sentence) + why it matters (1–2 sentences)
   - Prioritize: major launches, AI breakthroughs, industry shifts, funding news
   - Skip: minor updates, niche academic papers, speculative stories

3. **Closing:**
   ```
   That's your TLDR for today. Stay curious, and have a great day!
   ```

**Tone:**
- Conversational, not robotic
- No bullet points, headers, or markdown
- No URLs (listener can't click them during audio)
- No sponsor mentions or ads
- 450–550 words typically reads as 4–5 minutes at normal speed

**Example Structure:**
```
Good morning! Here's your TLDR tech briefing for May 27, 2026.

First up in Big Tech: Apple released... [story]. This matters because...

Next, in Programming: Rust hit version 1.75 with... [story]. The significance is...

Also worth noting: A new startup called... [story].

And finally, in Science: Researchers discovered... [story].

That's your TLDR for today. Stay curious, and have a great day!
```

---

### Step 4: Generate Audio via Google Cloud TTS

**Service:** Google Cloud Text-to-Speech API  
**Endpoint:** `https://texttospeech.googleapis.com/v1/text:synthesize`  
**Authentication:** JWT-based service account auth

**Configuration:**
```python
{
  'input': {'text': briefing_text},
  'voice': {
    'languageCode': 'en-US',
    'name': 'en-US-Neural2-F'  # Natural female voice
  },
  'audioConfig': {
    'audioEncoding': 'MP3',
    'speakingRate': 1.05        # 5% faster than natural
  }
}
```

**Why Neural2-F?**
- **Neural2:** High-quality, natural-sounding synthesis (vs. Standard voices)
- **Female voice:** Professional, approachable tone for morning briefings

**Why 1.05x speed?**
- Natural speech: 1.0x
- Slightly faster keeps listeners engaged without sounding rushed
- 450 words at 1.05x ≈ 4–5 minutes (ideal for morning listening)

**Output:** Base64-encoded MP3 audio (decoded and saved to `/tmp/tldr_today.mp3`)

---

### Step 5: Upload to GCS and Post Slack Link

**GCS Configuration:**

- **Bucket:** `tldr-audio-briefings`
- **Filename:** `tldr_YYYY-MM-DD.mp3` (e.g., `tldr_2026-05-27.mp3`)
- **ACL:** `predefinedAcl=publicRead` (makes file publicly accessible without auth)
- **Public URL:** `https://storage.googleapis.com/tldr-audio-briefings/tldr_2026-05-27.mp3`

**Important GCS Configuration:**
```json
{
  "uniformBucketLevelAccess": false,  // Allow per-object ACLs
  "defaultObjectAcl": [
    {
      "role": "roles/storage.objectViewer",
      "entity": "allUsers"  // Readable by anyone with URL
    }
  ]
}
```

**Slack Message:**
```
🎧 *Your TLDR Tech Briefing is ready!* Listen to today's top stories 👇
[Click to listen](https://storage.googleapis.com/tldr-audio-briefings/tldr_2026-05-27.mp3)
```

**Slack API:**
- **Endpoint:** `https://slack.com/api/chat.postMessage`
- **Method:** POST
- **Auth:** Bearer token (`xoxb-...`)
- **Scopes required:** `chat:write`

---

## Implementation Details

### Authentication Strategy

**Challenge:** Authenticate to Google Cloud APIs in a restricted environment (Claude Code Scheduled Tasks) without heavy libraries.

**Solution:** JWT-based service account auth using only Python's `cryptography` package.

**How it works:**

1. **Load service account JSON** (from environment variable)
2. **Build JWT payload:**
   ```python
   {
     "iss": "tldr-account@tldr-briefing-491917.iam.gserviceaccount.com",
     "scope": "https://www.googleapis.com/auth/cloud-platform",
     "aud": "https://oauth2.googleapis.com/token",
     "exp": now + 3600,
     "iat": now
   }
   ```
3. **Sign with RS256** (service account private key)
4. **Exchange JWT for access token** at `https://oauth2.googleapis.com/token`
5. **Use access token** as Bearer auth for all subsequent API calls

**Code outline:**
```python
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import padding

# Load private key
private_key = serialization.load_pem_private_key(
    sa['private_key'].encode(), password=None, backend=default_backend()
)

# Sign JWT
sig = private_key.sign(signing_input, padding.PKCS1v15(), hashes.SHA256())

# Exchange for token
token = requests.post('https://oauth2.googleapis.com/token', data={
    'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion': jwt
}).json()['access_token']

# Use token for API calls
headers = {'Authorization': f'Bearer {token}'}
```

**Why not use `google-auth`?**
- Adds unnecessary bulk to the environment
- `cryptography` is already available in Claude Code
- JWT signing is straightforward and fully self-contained

---

### Error Handling

**If Step 1 fails (Gmail fetch):**
```
Post to Slack: "Gmail search failed: [error reason]"
Exit
```

**If Step 2 fails (email parsing):**
```
Post to Slack: "Failed to parse TLDR email content: [error]"
Exit
```

**If Step 3 fails (TTS generation):**
```
Post to Slack: "Text-to-Speech generation failed: [error]"
Exit
```

**If Step 4 fails (GCS upload):**
```
Post to Slack: "Failed to upload audio to GCS: [error]"
Exit
```

**If Step 5 fails (Slack post):**
```
Log error locally (can't post to Slack if Slack API is down)
But audio is already uploaded; public URL is accessible
```

---

## Why Claude Code Scheduled Tasks?

**Alternatives considered:**
- ❌ GitHub Actions: Requires storing credentials in GitHub Secrets (less secure), cold starts, limited runtime
- ❌ Cron + local machine: Requires always-on infrastructure, maintenance burden
- ❌ AWS Lambda: More expensive, slower cold starts, more configuration
- ✅ **Claude Code Scheduled Tasks:** Cloud-hosted, free tier, integrates with MCP (Gmail, Slack), no infrastructure

**Benefits:**
1. **Zero infrastructure:** No Lambda functions, containers, or deployment pipelines
2. **Native Gmail/Slack integration:** MCP tools handle authentication automatically
3. **Free tier:** Up to 100 task executions per month (plenty for daily + testing)
4. **Easy debugging:** Run tasks manually, view logs, iterate quickly
5. **Cost:** ~$0.03 per day (TTS only); hosting is free

---

## Cost Breakdown

| Service | Cost/Day | Cost/Month | Details |
|---------|----------|-----------|---------|
| Google Cloud TTS | ~$0.03 | ~$0.90 | 450 words @ $0.00001/char |
| Google Cloud Storage | ~$0.001 | ~$0.03 | ~1 MB/day storage + retrieval |
| Gmail API | $0 | $0 | Free tier (unlimited) |
| Slack API | $0 | $0 | Free tier |
| Claude Code Tasks | $0 | $0 | Free tier (100 executions/mo) |
| **Total** | **~$0.031** | **~$0.93** | Negligible |

---

## Scaling Considerations

**Current design supports:**
- 1 briefing per day (any weekday)
- 1 Slack channel
- 450–550 word briefings
- Fully hands-off operation

**To scale to multiple channels/times:**
1. Add `SLACK_CHANNELS` env var (list of channel IDs)
2. Loop through channels in Step 5
3. Post same briefing to all channels
4. (Or: create separate tasks for different channels/times)

**To support custom topics (AI-only, startup-only, etc.):**
1. Modify Step 3 to filter stories by category
2. Add `BRIEFING_TOPICS` env var
3. Generate multiple briefings from same email fetch

---

## Monitoring & Observability

**Current monitoring:**
- Slack message on each task execution (success or error)
- Claude Code dashboard shows: last execution time, run duration, status

**To improve:**
1. Add structured logging (JSON format) to stdout
2. Archive briefing text + audio metadata
3. Post weekly summary to Slack (X briefings published, audio hours served)
4. Track TTS generation time (baseline for perf optimization)

---

## Future Improvements

| Feature | Benefit | Difficulty |
|---------|---------|-----------|
| Apple Podcasts RSS feed | Reach podcast listeners | Medium |
| Transcript archival | Searchable briefing history | Low |
| Morning + evening variants | Cover different time zones | Low |
| AI-only briefing filter | Focused content for AI enthusiasts | Medium |
| Email delivery | Reach non-Slack users | Medium |
| Multilingual briefings | International audience | High |

---

## Troubleshooting Guide

See `TROUBLESHOOTING.md` for common issues and solutions.
