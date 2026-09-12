---
name: youtube-recap
description: Create a summary of a YouTube video in the form of an interactive HTML recap artifact, with a header summary, key highlights, timestamped navigation, and an embedded dockable/floating player.
license: MIT
compatibility: Requires an agent harness with Agent Skills support, yt-dlp for transcript acquisition, and GitHub authentication for Gist publishing.
allowed-tools: Bash(yt-dlp *)
---

## Purpose

This skill summarizes YouTube videos and produces an **interactive HTML recap artifact**.

The artifact should help the user:

- Quickly understand what the video is about.
- Decide whether the video is interesting or worth watching.
- Identify the most valuable moments.
- Jump directly to those moments in the embedded player using timestamped highlights.

The primary deliverable is the HTML artifact **plus a published, hosted URL for that artifact**.

**Do not stop after generating the local HTML file.** The skill is only complete after the recap has been published to a hosted URL (preferably a secret GitHub Gist rendered through a raw-content proxy, otherwise a localhost fallback) and that URL is returned to the user.

## Steps

1. Download the transcript with `yt-dlp` (see [Transcript Acquisition](#transcript-acquisition)).
2. Read the downloaded transcript and write a temporary planning summary.
3. Generate the HTML artifact from the planning summary and the template.
4. **Publish the HTML and return a working hosted URL as the final mandatory step** (see [Publishing to GitHub Gist](#publishing-to-github-gist)).

## References

Use these skill-local files when creating the artifact:

- Template: `templates/interactive-youtube-recap.html`
- Example: `examples/david-cramer-interactive-recap.html`

References are relative to this skill directory.

## Transcript Acquisition

When the user provides a YouTube URL or video ID, fetch the transcript before analysis. Use `yt-dlp` to extract subtitles:

```bash
yt-dlp --skip-download --write-auto-subs --sub-lang en --sub-format vtt \
  --convert-subs srt -o "%(title)s.%(ext)s" "VIDEO_URL"
```

If subtitles are unavailable, try extracting uploaded subtitles:

```bash
yt-dlp --skip-download --write-subs --sub-lang en -o "%(title)s.%(ext)s" "VIDEO_URL"
```

For age-restricted or login-required content, use browser cookies:

```bash
yt-dlp --cookies-from-browser chrome --skip-download --write-auto-subs ...
```

Read the resulting `.srt` file and use it as the transcript input.


## Analysis Goals

Analyze the transcript to extract the information needed for the interactive artifact.

Produce these content elements:

1. **Header Summary**
   - A concise 1–2 sentence summary of the video.
   - It should explain what the video is about and why it matters.
   - This appears in the artifact header beside the video player.

2. **Main Takeaway**
   - The single strongest idea, argument, or conclusion from the video.
   - This appears prominently in the header.

3. **Key Highlights**
   - The most interesting or valuable moments in the video.
   - Each highlight must include a timestamp.
   - Highlights should help the user decide where to jump first.

4. **Timestamped Sections / Timeframes**
   - Organize the video into logical sections that follow the video's progression.
   - Each section should contain timestamped key points.
   - Use timestamps in `[HH:MM:SS]` format during planning, then convert them to seconds for the HTML `data-seconds` attributes.

5. **Conclusion**
   - A brief final synthesis of the video's main message, implication, or call to action.

## Recommended Intermediate Structure

Before writing the HTML, structure the extracted content like this:

```markdown
# Video Recap Data

## Header Summary
A concise 1–2 sentence summary explaining what the video is about and why it matters.

## Main Takeaway
The single strongest idea or conclusion from the video.

## Key Highlights
- [HH:MM:SS] Highlight title — short explanation
- [HH:MM:SS] Highlight title — short explanation

## Sections / Timeframes
### Section title
- [HH:MM:SS] Key point
- [HH:MM:SS] Key point

### Section title
- [HH:MM:SS] Key point
- [HH:MM:SS] Key point

## Conclusion
Brief final synthesis of the video's message.
```

This structure is an internal planning aid. The final user-facing deliverable should be the HTML artifact.

## Artifact Generation

When generating the HTML artifact:

1. Read `templates/interactive-youtube-recap.html`.
2. Replace all placeholders with the extracted video recap data.
3. Generate timestamp list items using this pattern:

```html
<li>
  <a class="time"
     href="https://www.youtube.com/watch?v=VIDEO_ID&t=SECONDSs"
     data-seconds="SECONDS"
     target="_blank"
     rel="noopener">HH:MM:SS</a>
  Key point text
</li>
```

4. Keep the YouTube URL in `href` as a fallback.
5. Set `data-seconds` to the timestamp converted to total seconds.
6. Save the artifact as a descriptive `.html` file.
7. **Always publish the artifact after generating it.** Do this even if the user did not explicitly ask to open, share, or host it.
8. Publish the artifact as a **secret GitHub Gist** by default and build a rendered URL using `gist.githack.com` (or an equivalent raw proxy URL) so the HTML is served with the correct content type.
9. **Do not consider the task complete until you have a working hosted URL to report back.** Do not end with only a local file path unless every hosting attempt fails.
10. Do not use `file://` for YouTube recap artifacts, because the embedded player may not load there.
11. If GitHub publishing is unavailable or fails, fall back to a local `localhost` server and report that URL instead.

## Artifact Behavior Requirements

The generated artifact must preserve these behaviors from the template:

- The video player starts **docked in the header**.
- The header includes:
  - video title
  - short summary
  - YouTube source link
  - main takeaway
  - embedded player
- A `Float` button detaches the player.
- In floating mode:
  - the player opens centered
  - default floating width is approximately 31% of the viewport
  - the player can be dragged by its top bar
  - the player can be resized with the bottom-right handle
  - `−` and `+` buttons reduce/enlarge the player
  - `Dock` returns the player to the header
- Clicking a timestamp seeks the embedded YouTube player to that exact time.
- Clicking a timestamp highlights the selected item immediately.
- As playback continues, the currently playing timestamp/section should sync with the highlighted entry in the notes list.
- Only one timestamp item should be highlighted at a time.
- Timestamp clicks respect the current player mode:
  - docked stays docked
  - floating stays floating
- Playback itself must **not** automatically change docked/floating mode.
- Do not auto-scroll the notes based on playback time.

## Summary Quality Guidelines

- Preserve the video's logical flow.
- Prefer useful, specific highlights over generic chapter titles.
- Make timestamps precise enough to be useful for navigation.
- Keep the artifact concise but comprehensive.
- Bold particularly important concepts or takeaways where helpful.
- Avoid overloading the page with too many timestamp items; choose the moments that best support comprehension and navigation.

## Publishing to GitHub Gist

This is the last step after the HTML artifact has been generated.

Publishing is **mandatory for every run of this skill**. Do not wait for the user to ask to open or share it.

1. Create a **secret** gist containing a single `.html` file with the final recap HTML.
2. Capture the gist response fields needed to build the rendered URL, especially the gist id, filename, and latest revision/version.
3. Build the browser URL using the gist raw proxy format, e.g. `https://gist.githack.com/<github-username>/<gist-id>/raw/<revision>/<filename>.html`.
4. Verify you have a usable hosted URL and return it to the user. If browser-opening is available, open that rendered URL as well.
5. **Never end the task after only saving the HTML locally if publishing succeeded.** The hosted URL must be included in the final answer.
6. If the user asks to remove/delete the published recap, delete the gist using GitHub's API or `gh gist delete`, then confirm removal.
7. If GitHub publishing is unavailable or fails, fall back to a local `localhost` server and return that URL.
8. Only if both Gist publishing and localhost hosting fail may you fall back to returning just the local file path, and in that case you must explicitly say hosting failed.

Note: the raw GitHub Gist URL by itself is not enough for this use case because the browser may treat it as plain text; the proxy URL is what makes the HTML render.

## Final Response to User

After creating the artifact, respond concisely with:

- The path to the generated `.html` file.
- The hosted URL you published for it — normally the GitHub Gist proxy URL, or the localhost fallback URL.
- Any important caveat, such as if GitHub publishing failed and a fallback was used.

**Do not omit the hosted URL from the final response unless every hosting attempt failed.**
