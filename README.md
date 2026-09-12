# YouTube Recap Skill

Turn long YouTube videos into polished, interactive recaps your agent can publish and share.

This portable Agent Skill downloads a transcript with `yt-dlp`, identifies the strongest takeaways, and generates a hosted HTML recap with timestamped notes, clickable navigation, and a dockable/floating embedded player.

## Examples

- [Pi Building Pi, Openclaw's Minimalist Coding Agent](https://gist.githack.com/pablosproject/bf6a5d02237011e5f935f69218013386/raw/db8eb6ff831553d976b685589eb72073ad42aa11/pi-building-pi-interactive-recap.html)
- [State of Agentic Coding #8](https://gist.githack.com/pablosproject/5a9fa0affd4e5ac71c4465864e749254/raw/861171d106c83a6aa9447be4ce6fd7c0feba4473/state-of-agentic-coding-8-interactive-recap.html)
- [How To Ship Real Code With AI (Not Junk)](https://gist.githack.com/pablosproject/73fba668d3e458e8a4c8ecb6f74d5793/raw/8718633930ab7cf82757fbbd077ee27fb91610d3/youtube-summary-david-cramer-ai-code.html)

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

A local example artifact is also included at [`examples/david-cramer-interactive-recap.html`](examples/david-cramer-interactive-recap.html).

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
git clone https://github.com/pablosproject/youtube-recap-skilll.git
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
skill-installer install https://github.com/pablosproject/youtube-recap-skilll
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
