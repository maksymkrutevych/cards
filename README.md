# UA→EN Audio Fluency (American)

Incremental curriculum for building automatic English speaking through **Ukrainian → pause → American English** drills.

This repo currently ships:

- curriculum JSON (lessons + learner state)
- a simple static viewer (`index.html` / `deck.html`) to browse lesson pairs as flip cards

Full design rules live in [`docs/curriculum-spec.md`](docs/curriculum-spec.md).

## Quick start

Serve the project root over HTTP (required for `fetch` of JSON):

```bash
cd /path/to/cards
python3 -m http.server 8080
```

Open [http://localhost:8080](http://localhost:8080):

- **`index.html`** — list of main-track lessons
- **`deck.html?track=main&lesson=0001`** — flip cards for that lesson

Card order matches production practice:

1. Front: Ukrainian prompt  
2. Flip: modern American English model  

Controls: tap/click to flip · swipe or ←/→ to change pair · Space/Enter to flip.

## Project layout

```
docs/curriculum-spec.md          # source of truth for generation rules
curriculum/project.json          # project + tracks + generation pointers
curriculum/lessons/main/0001.json
curriculum/lessons/main/index.json   # auto-built lesson list for the UI
index.html                       # lessons list
deck.html                        # lesson pair viewer
scripts/update-lessons-index.sh  # rebuild main/index.json
```

## Curriculum model (short)

Lessons are generated **one at a time**, not all 1000 upfront.

Each lesson JSON includes:

- `pairs` — UA/EN utterances for practice
- `learnerState` — vocabulary/grammar strength, dues, weak items
- `generationSeed` — quotas and constraints for the **next** lesson
- `unlocks` — side tracks (micro practice, pronunciation, dialogues)

From **one lesson file + the spec**, you can assess level and generate the next lesson.

Language policy: **modern American English** (`en-US`) only.

Spine: **A2 → B1 → B2** on the main listen/produce track. Parallel tracks unlock later (see `project.json`).

## Adding / updating lessons

1. Add or edit `curriculum/lessons/main/NNNN.json` following the schema in the spec.
2. Rebuild the UI index:

```bash
./scripts/update-lessons-index.sh
```

The pre-commit hook runs this automatically when installed.

## Generate the next lesson

Use an agent or script with:

1. `docs/curriculum-spec.md`
2. `curriculum/project.json`
3. Latest `curriculum/lessons/main/NNNN.json` (`learnerState` + `generationSeed`)

Then write `NNNN+1.json`, bump `project.json` generation pointers, and run `update-lessons-index.sh`.

## Audio (planned)

TTS (e.g. ElevenLabs) will generate short clips per segment and store them on your server. Playback can preload the next clip; optional offline exports can stitch a full lesson MP3 later. See the curriculum discussion in the spec — generation is one-time, storage is yours.
