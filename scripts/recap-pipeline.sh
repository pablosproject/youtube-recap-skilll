#!/usr/bin/env bash
set -euo pipefail

# Simple YouTube recap pipeline for this skill.
#
# Run from the per-video output directory. The script reads schema/template files
# from the skill repo and reads/writes recap artifacts in the current directory.
#
# Usage:
#   /path/to/skill/scripts/recap-pipeline.sh fetch 'https://www.youtube.com/watch?v=VIDEO_ID'
#   /path/to/skill/scripts/recap-pipeline.sh generate-json-stub
#   /path/to/skill/scripts/recap-pipeline.sh validate
#   /path/to/skill/scripts/recap-pipeline.sh render
#   /path/to/skill/scripts/recap-pipeline.sh publish
#   /path/to/skill/scripts/recap-pipeline.sh all 'https://www.youtube.com/watch?v=VIDEO_ID'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKDIR="$(pwd)"

DATA_JSON="${DATA_JSON:-video-recap-data.json}"
SCHEMA_JSON="${SCHEMA_JSON:-$SKILL_ROOT/schemas/video-recap.schema.json}"
TEMPLATE="${TEMPLATE:-$SKILL_ROOT/templates/recap.eta}"
HTML_OUT="${HTML_OUT:-interactive-recap.html}"
VIDEO_URL="${2:-${VIDEO_URL:-}}"

need() {
  command -v "$1" >/dev/null || { echo "Missing required command: $1" >&2; exit 1; }
}

fetch_transcript() {
  local url="$1"
  [[ -n "$url" ]] || { echo "Usage: $0 fetch VIDEO_URL" >&2; exit 1; }
  need yt-dlp

  yt-dlp --skip-download --write-auto-subs --sub-lang en --sub-format vtt \
    --convert-subs srt -o "%(title)s.%(ext)s" "$url" \
  || yt-dlp --skip-download --write-subs --sub-lang en \
    -o "%(title)s.%(ext)s" "$url"
}

generate_json_stub() {
  local transcript
  transcript="$(ls -t ./*.srt 2>/dev/null | head -1 || true)"
  [[ -n "$transcript" ]] || { echo "No .srt transcript found. Run: $0 fetch VIDEO_URL" >&2; exit 1; }

  cat > recap-json-prompt.md <<EOF
Create ${DATA_JSON} from this transcript.

Validate against ${SCHEMA_JSON}.
Required content: video title/url/id, abstract, mainTakeaway, highlights with time/seconds/title/description, sections with timestamped points, conclusion, footerText.

Transcript file: ${transcript}
EOF

  if [[ ! -f "$DATA_JSON" ]]; then
    cat > "$DATA_JSON" <<'EOF'
{
  "schemaVersion": "1.0",
  "video": {
    "id": "TODO",
    "url": "TODO",
    "title": "TODO"
  },
  "abstract": "TODO",
  "mainTakeaway": "TODO",
  "highlights": [],
  "sections": [],
  "conclusion": "TODO",
  "footerText": "Interactive recap generated from the YouTube transcript."
}
EOF
  fi

  echo "Wrote recap-json-prompt.md"
  echo "Edit ${DATA_JSON}, then run: $0 validate && $0 render"
}

validate_json() {
  need node
  node --input-type=module - "$SKILL_ROOT" "$SCHEMA_JSON" "$DATA_JSON" <<'NODE'
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';

const [, , skillRoot, schemaPath, dataPath] = process.argv;
const require = createRequire(`${skillRoot}/package.json`);
const Ajv2020 = require('ajv/dist/2020').default;
const addFormats = require('ajv-formats').default;

const schema = JSON.parse(await readFile(schemaPath, 'utf8'));
const data = JSON.parse(await readFile(dataPath, 'utf8'));

const ajv = new Ajv2020({ allErrors: true, strict: true });
addFormats(ajv);
const validate = ajv.compile(schema);

if (!validate(data)) {
  console.error('Schema validation failed:');
  for (const error of validate.errors ?? []) {
    console.error(`- ${error.instancePath || '/'} ${error.message ?? ''}`.trim());
  }
  process.exit(1);
}

const points = [
  ...data.highlights,
  ...data.sections.flatMap((section) => section.points),
];
for (const point of points) {
  const match = /^(\d{2}):(\d{2}):(\d{2})$/.exec(point.time);
  if (!match) throw new Error(`Invalid timestamp: ${point.time}`);
  const expected = Number(match[1]) * 3600 + Number(match[2]) * 60 + Number(match[3]);
  if (point.seconds !== expected) {
    throw new Error(`Timestamp mismatch for ${point.time}: expected ${expected}, got ${point.seconds}`);
  }
}

console.log(`valid: ${dataPath}`);
NODE
}

render_html() {
  validate_json
  need node
  node --input-type=module - "$SKILL_ROOT" "$DATA_JSON" "$TEMPLATE" "$HTML_OUT" <<'NODE'
import { readFile, writeFile } from 'node:fs/promises';
import { dirname, basename, resolve } from 'node:path';
import { createRequire } from 'node:module';

const [, , skillRoot, dataPath, templatePath, outputPath] = process.argv;
const require = createRequire(`${skillRoot}/package.json`);
const { Eta } = require('eta');

const data = JSON.parse(await readFile(dataPath, 'utf8'));
const eta = new Eta({ views: dirname(resolve(templatePath)), autoEscape: true });

const html = eta.render(`./${basename(templatePath)}`, {
  ...data,
  footerText: data.footerText ?? 'Interactive recap generated from the YouTube transcript.',
  videoIdJson: JSON.stringify(data.video.id),
  renderSections: [
    { title: 'Key Highlights', points: data.highlights },
    ...data.sections,
  ],
}) + '\n';

let status = 'created';
try {
  const current = await readFile(outputPath, 'utf8');
  if (current === html) status = 'unchanged';
  else status = 'updated';
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}

if (status !== 'unchanged') await writeFile(outputPath, html);
console.log(`${status}: ${outputPath}`);
NODE
}

publish_html() {
  need gh
  need git
  [[ -f "$HTML_OUT" ]] || { echo "Missing HTML: $HTML_OUT. Run: $0 render" >&2; exit 1; }

  local gist_url raw_url hosted_url gist_id gist_owner gist_sha
  if [[ -f gist_url.txt ]]; then
    gist_url="$(cat gist_url.txt)"
    gist_id="${gist_url##*/}"
    gh gist edit "$gist_id" --filename "$HTML_OUT" "$HTML_OUT" >/dev/null
  else
    # Gists are secret by default in current gh versions.
    gist_url="$(gh gist create "$HTML_OUT" --desc "YouTube recap: $HTML_OUT")"
    echo "$gist_url" > gist_url.txt
    gist_id="${gist_url##*/}"
  fi

  gist_owner="$(printf '%s\n' "$gist_url" | awk -F/ '{print $(NF-1)}')"
  gist_sha="$(git ls-remote "https://gist.github.com/${gist_owner}/${gist_id}.git" HEAD | awk '{print $1}')"
  raw_url="https://gist.githubusercontent.com/${gist_owner}/${gist_id}/raw/${gist_sha}/${HTML_OUT}"
  hosted_url="https://htmlpreview.github.io/?${raw_url}"
  echo "$hosted_url" > hosted_url.txt
  echo "$hosted_url"
}

case "${1:-}" in
  fetch) fetch_transcript "$VIDEO_URL" ;;
  generate-json-stub) generate_json_stub ;;
  validate) validate_json ;;
  render) render_html ;;
  publish) publish_html ;;
  all)
    fetch_transcript "$VIDEO_URL"
    if [[ ! -f "$DATA_JSON" ]]; then generate_json_stub; exit 0; fi
    render_html
    publish_html
    ;;
  *)
    sed -n '1,28p' "$0" >&2
    exit 1
    ;;
esac
