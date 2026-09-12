# YouTube Recap Skill

A portable Agent Skill for turning a YouTube video into an interactive hosted HTML recap.

The skill downloads a transcript with `yt-dlp`, summarizes the video, generates a navigable HTML artifact with timestamp links and an embedded player, then publishes the artifact to a hosted URL, preferably as a secret GitHub Gist rendered through a raw-content proxy.

## What it creates

Each recap includes:

- a concise header summary
- the main takeaway
- key highlights with timestamps
- timestamped sections following the video's flow
- an embedded YouTube player
- clickable timestamps that seek the player
- a dockable/floating video player
- a hosted URL for sharing or opening in a browser

See [`examples/david-cramer-interactive-recap.html`](examples/david-cramer-interactive-recap.html) for an example artifact.

## Requirements

- An agent harness that supports Agent Skills / `SKILL.md` directories
- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) available on `PATH`
- GitHub CLI authentication or a GitHub token if you want automatic Gist publishing

Install `yt-dlp` with Homebrew:

```bash
brew install yt-dlp
```

Or with pipx:

```bash
pipx install yt-dlp
```

## Installation

Clone this repository:

```bash
git clone https://github.com/<your-user>/youtube-recap.git
```

Then copy the repository folder into your harness's skill directory.

### Claude Code

Global install:

```bash
mkdir -p ~/.claude/skills
cp -R youtube-recap ~/.claude/skills/youtube-recap
```

Project-local install:

```bash
mkdir -p .claude/skills
cp -R youtube-recap .claude/skills/youtube-recap
```

### Pi

Global install:

```bash
mkdir -p ~/.pi/agent/skills
cp -R youtube-recap ~/.pi/agent/skills/youtube-recap
```

Project-local install:

```bash
mkdir -p .pi/skills
cp -R youtube-recap .pi/skills/youtube-recap
```

### OpenAI Codex

If your Codex setup includes the skill installer, install from the GitHub skill directory URL:

```bash
skill-installer install https://github.com/<your-user>/youtube-recap
```

Alternatively, copy the skill directory into the Codex skills directory used by your setup, for example:

```bash
mkdir -p ~/.codex/skills
cp -R youtube-recap ~/.codex/skills/youtube-recap
```

Restart or reload your agent harness after installation if it does not discover skills dynamically.

## Usage

Ask your agent to use the skill with a YouTube URL:

```text
Use the youtube-recap skill to summarize https://www.youtube.com/watch?v=VIDEO_ID
```

Or, in harnesses that expose skills as slash commands:

```text
/skill:youtube-recap https://www.youtube.com/watch?v=VIDEO_ID
```

The final response should include:

- the generated local `.html` path
- the hosted recap URL
- any caveat if Gist publishing was unavailable and a fallback URL was used

## Included files

```text
SKILL.md
README.md
LICENSE
templates/interactive-youtube-recap.html
examples/david-cramer-interactive-recap.html
examples/transcripts/why-im-moving-to-linux.en.srt
```

## Publishing behavior

The skill is designed to publish the generated recap after creating it. By default it attempts to create a secret GitHub Gist and return a rendered URL using a raw-content proxy. If GitHub publishing is unavailable, the skill falls back to a local hosted URL.

## License

MIT
