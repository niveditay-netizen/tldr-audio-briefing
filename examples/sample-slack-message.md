# Example Slack Message

When the task completes successfully, it posts a message like this to your Slack channel:

```
🎧 *Your TLDR Tech Briefing is ready!* Listen to today's top stories 👇
[Click to listen](https://storage.googleapis.com/tldr-audio-briefings/tldr_2026-05-27.mp3)
```

## Message Breakdown

- **Emoji:** 🎧 (headphones) makes the notification visually distinct
- **Bold text:** "Your TLDR Tech Briefing is ready!" draws attention
- **Link:** The text "Click to listen" is a markdown link to the MP3 URL
  - Users can click it directly in Slack to listen
  - Works on desktop, mobile, and web

## Error Message Example

If the task fails, it posts an error notification:

```
❌ TLDR briefing pipeline failed at Step 3: Text-to-Speech generation failed
Error: Google Cloud TTS API returned 403 Forbidden (check service account permissions)
Attempted to process emails at 2026-05-27 11:00:00 EST
```

This helps you quickly identify which step failed and why.

## Customization

To customize the Slack message:
1. Edit the task prompt (in Claude Code task settings)
2. Find the line: `POST to Slack: ...`
3. Change the message text
4. Re-run or wait for next scheduled execution
