# Prompt: Generate next main lesson

Copy this file (or point an agent at it) when the user asks to **generate the next lesson**.

You are extending an incremental UA→EN fluency curriculum. Generate **exactly one** new main-track lesson. Do not invent a parallel curriculum.

---

## Mission

Create the next `listen_produce` lesson so the learner keeps building **automatic oral translation** (Ukrainian prompt → produce English → compare with American English model), with spaced review, varied contexts, and slow complexity growth.

---

## Required reading (in order)

1. `docs/curriculum-spec.md` — rules, schemas, pedagogy constraints  
2. `curriculum/project.json` — tracks, budgets, SRS steps, generation pointers  
3. Latest lesson on the track (usually `curriculum/lessons/main/` with highest `lessonId` / filename). Prefer `project.generation.latestMainLessonId` if present.

Do **not** require the full history of older lessons. The latest lesson’s `learnerState` + `generationSeed` are the checkpoint.

Optional: skim `docs/prompts/generate-next-lesson.md` only if you are not already following it (this file).

---

## Inputs you must obey

From the latest lesson:

| Field | Use for |
|--|--|
| `learnerState` | what is known/weak/due; update after new pairs |
| `generationSeed` | hard constraints for **this** new lesson |
| `cefr` / `unlocks` | level band and side-track gates |
| `pairs` | avoid near-duplicate sentences; prefer new contexts for reviewed atoms |

From `generationSeed` (authoritative for lesson N+1):

- `cefrAllow`, `grammarCeiling`
- `mustReview`
- `mayIntroduce` caps + preferred topics/candidates
- `forbid` (grammar, lexicon, register)
- `quotas` (pairs count + role mix)
- `complexity` (`lessonMean`, `maxJump`)
- `style` (must stay `en-US`)

From `project.json`:

- `budgets` / `srsStepsLessons` / `graduationDefaults` if seed is silent
- `tracks.main.lessonsDir`
- unlock thresholds for side tracks

---

## Hard rules

1. **One lesson only** — write a single new file; do not batch-generate many lessons unless the user explicitly asks.  
2. **Do not rewrite** previous lesson files unless the user explicitly requests a fix.  
3. **Locale:** every `en` string = **modern American English** (`locale: "en-US"`).  
   - US spelling and vocabulary (apartment, elevator, math, vacation, …)  
   - Natural spoken register; contractions preferred when natural  
   - No British defaults (`flat`, `lift`, `lorry`, `whilst`, …)  
4. **Pair direction for content:** store `ua` + `en`. Practice UX is UA front → EN back.  
5. Respect **`forbid`** strictly.  
6. Stay within **`grammarCeiling`** and **`cefrAllow`**.  
7. Hit **`quotas.pairs`** (default 30). Approximate role mix from seed/project budgets:  
   - ~50–60% review  
   - ~20–25% varied_reuse (known atoms, **new** context/template)  
   - ~10–20% new (within `mayIntroduce` caps)  
   - ~5–10% contrast when relevant  
8. Every `mustReview` atom must appear in **at least one** pair (preferably more if weak).  
9. For reviewed atoms, maximize **contextual novelty** vs `learnerState.*.contexts` / previous templates.  
10. Complexity mean of the new lesson must not jump more than `complexity.maxJump` above the previous `lessonMean`.  
11. Keep schema compatible with lesson `0001` / `docs/curriculum-spec.md` (`schemaVersion`, metadata blocks, pair shape).

---

## Algorithm (do this)

### A. Plan the lesson slotting

1. Set `newLessonId = previous.lessonId + 1`.  
2. Filename: zero-padded 4 digits, e.g. `0002.json`.  
3. Build a slot plan of N pairs (`quotas.pairs`):  
   - Fill review slots from `mustReview`, then `priorityQueue.overdue` / `weak` / `dueNext`.  
   - Add varied_reuse slots for familiar atoms with new templates/collocations.  
   - Add new atoms only within `mayIntroduce` (prefer `preferCandidates` / `preferTopics`).  
   - Add a few contrast pairs if the seed/pedagogy mentions contrasts (e.g. will vs going to).  
4. Assign each slot: target lexicon/grammar/template + `roles`.

### B. Write pairs

For each slot, write natural `{ ua, en }` aligned in meaning.

Pair object shape:

```json
{
  "id": "main-0002-01",
  "ua": "...",
  "en": "...",
  "pauseMs": 3500,
  "atoms": {
    "lexicon": ["..."],
    "grammar": ["..."],
    "template": "T_..."
  },
  "roles": ["review"],
  "cefr": "A2",
  "notes": null
}
```

Guidelines:

- One clear communicative idea per pair; speakable aloud.  
- Length appropriate to current CEFR band (A2: shorter; later: denser).  
- Tag real atoms used; don’t invent grammar IDs outside the ceiling unless introducing under `mayIntroduce.maxNewGrammar`.  
- `pauseMs`: usually 3200–4200 (longer for denser sentences).

### C. Refresh `learnerState`

Start from previous `learnerState`, then for every atom that appeared:

- increment `exposures`
- add new context ids to `contexts` / bump `distinctContexts`
- set `lastLessonId` = new lesson id  
- recompute rough `strength` (0–1): up with varied exposures; keep weak items clearly < known threshold  
- advance `srsStep` when appropriate; set `nextDueLessonId` using expanding steps from project `srsStepsLessons` (e.g. after intro: +1, +3, +7, +15…)  
- update `status`: `new` → `learning` → `familiar` → `known` per `graduationDefaults`  
- update `stats`  
- rebuild `priorityQueue` (`overdue`, `dueNext`, `weak`, `readyToGraduate`)  
- set `asOfLessonId` / `cefrEstimated`

For brand-new atoms: set `introLessonId`, `srsStep: 0`, `nextDueLessonId: newLessonId + 1`, low strength.

Queued-but-forbidden items (e.g. still in `forbid.lexicon`) stay unintroduced.

### D. Refresh `unlocks`

- `nextMainLessonAllowed`: true (unless you intentionally gate)  
- Update side-track progress, e.g. pronunciation/dialogues `progress: "{n}/20"`; set `unlocked: true` when threshold met  
- `suggestedNext`: prefer `generate_next_lesson` for main; include optional `micro_practice` if unlocked

### E. Write `generationSeed` for the **following** lesson (N+2)

Based on the **new** learnerState:

- `fromLessonId` = new lesson id  
- refresh `mustReview` (due/weak/high-priority)  
- set next `mayIntroduce` caps (still slow)  
- keep or slightly extend `grammarCeiling` only when pedagogy warrants and `maxJump` allows  
- keep `forbid` unless unlocking a previously blocked item on purpose  
- nudge `complexity.lessonMean` by at most `maxJump`  
- keep `style.locale: "en-US"`

### F. Top-level lesson metadata

Fill:

- `schemaVersion`, `lessonId`, `trackId: "main"`, `kind: "listen_produce"`, `locale: "en-US"`
- `title` (include CEFR cue, short topic)
- `sequence.prevLessonId` / `nextLessonId`
- `timing` (`pairsCount`, `targetMinutes` ≈ 15, `defaultPauseMs`)
- `cefr` (`lessonLevel`, `band`, `spineProgress`, …)
- `pedagogy` (`focus`, `contrast`, `newAtomRatio`, short `notes`)

### G. Repo bookkeeping

After writing the lesson file:

1. Update `curriculum/project.json`:  
   - `generation.latestMainLessonId`  
   - `generation.nextMainLessonId`  
2. Run: `./scripts/update-lessons-index.sh`  
3. Sanity-check JSON parses and `pairs.length === quotas.pairs`.

Do **not** commit or push unless the user asks.

---

## Quality checklist (before finishing)

- [ ] New file path: `curriculum/lessons/main/NNNN.json`  
- [ ] Exactly one new lesson; previous lessons untouched  
- [ ] `pairs.length` matches quota  
- [ ] All `mustReview` atoms covered  
- [ ] New atoms within `mayIntroduce` caps  
- [ ] Nothing from `forbid` introduced  
- [ ] All `en` are natural en-US  
- [ ] `learnerState`, `unlocks`, `generationSeed` updated and self-contained  
- [ ] From this file alone + spec, next lesson could be generated again  
- [ ] `project.json` pointers + `index.json` updated  

---

## Output to the user

Briefly report:

1. New lesson id + title + CEFR  
2. What was reviewed vs newly introduced  
3. Notable weak items still due  
4. Whether side tracks unlocked  
5. Paths touched  

---

## Side tracks (only if asked)

If the user asks for `micro_practice` / `pronunciation` / `dialogues`:

1. Check `unlocks.sideTracks` on the latest main lesson (or project gates).  
2. If locked, explain the gate; do not generate.  
3. If unlocked, follow the same spirit (en-US, reuse lexicon ids) but shorter content; still write full metadata + updated state snapshot.

Default request **without** a track name = **main** next lesson.

---

## Example user triggers

- «Згенеруй наступний урок»  
- «Generate next lesson»  
- «Add main lesson 0002»

Treat all of these as: follow this prompt end-to-end.
