# Curriculum Spec — UA→EN Audio Fluency Track

> Source of truth for incremental lesson generation.
> From **any single lesson file + this document**, an agent or script must be able to:
> 1) assess the learner’s state, 2) generate the next lesson, 3) insert optional practice tracks.

**Variety:** modern **American English** (US spelling, vocabulary, rhythm, idioms).  
**Not:** British defaults, archaic formalisms, textbookese unless marked as register practice.

---

## 0. Product intent

Listener practices **oral translation**:

`Ukrainian prompt → pause (produce English) → American English model`

Goals:

- Automatic recall of high-frequency lexicon + patterns up to **B2 productive base**
- Same items in **changing contexts** (encoding variability)
- Slow complexity ramp with heavy recycling
- Generate **lesson-by-lesson**, not 1000 upfront
- Support **parallel short practice tracks** (pronunciation, dialogues, etc.) branching from any checkpoint

Initial spine: **A2 → B1 → B2** listening/production drills.  
Later: A1 prequel, C1 extension, or side tracks unlocked by metadata gates.

---

## 1. Scientific constraints (encoded as rules)

| Principle | Implementation rule |
|--|--|
| Spacing effect | Expanding gaps between reviews of each atom (by **lesson index**, not calendar) |
| Retrieval practice | Every pair is active UA→EN production |
| Encoding variability | Same atom must reappear in new templates/collocations |
| Interleaving | Mix old grammar layers; avoid long mono-topic blocks |
| i+1 / desirable difficulty | ~10–20% new atoms per lesson; rest known |
| Frequency first | Prioritize high-frequency US English + formulaic chunks |
| Automaticity | Core atoms get more exposures + more context types |

### Strength score (per atom)

After lesson \(k\):

\[
S_k(x)=\sum_{t\in hist(x),\,t\le k} w\!\left(\frac{k-t}{\tau(x)}\right)\cdot\kappa(t,x)
\]

- \(w\) — decay weight (recent reviews count more; overdue gaps hurt)
- \(\tau(x)\) — stability (rises with successful varied reviews)
- \(\kappa\) — context quality bonus if template/collocation/grammar frame is **new** for \(x\)

**Operational SRS gaps (lesson indices after intro):**  
`0, 1, 3, 7, 15, 30, 60, …` (expanding rehearsal)

---

## 2. Language policy — Modern American English

All `en` strings and TTS voices must follow:

- **US spelling:** color, organize, traveler, defense, practice (noun), …
- **US vocabulary defaults:** apartment (not flat), elevator (not lift), truck (not lorry), vacation (not holiday *unless* public holiday), cell phone / phone, faucet, cookie, soccer only if intentional, etc.
- **Natural spoken register** for drills: contractions OK (`I'm`, `don't`, `gonna` sparingly and only when marked informal)
- Prefer **high-frequency conversational American** over literary/British exam English
- Phrasal verbs and chunks as first-class atoms (`come up with`, `run into`, `figure out`)
- Dates, money, phones: US conventions when relevant (`$20`, month-day if stated)
- Pronunciation track (when present): General American (GA), not RP

Metadata field: `"locale": "en-US"` on every lesson (required).

---

## 3. Atom types

| Type | Examples | Stored in |
|--|--|--|
| `lemma` | likely, struggle, enhance | lexicon |
| `chunk` | come up with, rather than | lexicon (kind=chunk) |
| `grammar` | present_perfect_experience, going_to_plans | grammar catalog |
| `template` | `SUBJECT be likely to VERB …` | templates |
| `pair` | concrete ua/en utterance | lesson.pairs |

An atom is **introduced** once (`introLessonId`), then **reviewed** with rising contextual novelty.

---

## 4. Project snapshot (global, versioned)

Path suggestion: `curriculum/project.json`

```json
{
  "projectId": "ua-en-fluency-us",
  "title": "UA→EN Audio Fluency (American)",
  "locale": "en-US",
  "sourceLang": "uk",
  "targetLang": "en-US",
  "cefrSpine": ["A2", "B1", "B2"],
  "pairFormat": ["ua", "pause", "en"],
  "defaultPairsPerLesson": 30,
  "targetLessonMinutes": 15,
  "voicePolicy": {
    "ua": "ukrainian_neural",
    "en": "american_neural_ga"
  },
  "tracks": {
    "main": { "id": "main", "kind": "listen_produce", "status": "active" },
    "pronunciation": { "id": "pronunciation", "kind": "minimal_pairs_ga", "status": "planned", "unlockAfterMainLessons": 20 },
    "dialogues": { "id": "dialogues", "kind": "short_dialogue_shadow", "status": "planned", "unlockAfterMainLessons": 20 }
  },
  "generation": {
    "mode": "incremental",
    "nextMainLessonId": 1,
    "batchHint": "Generate one lesson at a time from previous lesson learnerState + this spec"
  },
  "budgets": {
    "newAtomRatio": [0.10, 0.20],
    "reviewRatio": [0.50, 0.60],
    "variedReuseRatio": [0.20, 0.25],
    "contrastRatio": [0.05, 0.10]
  },
  "srsStepsLessons": [0, 1, 3, 7, 15, 30, 60]
}
```

---

## 5. Lesson file — full metadata contract

Path suggestion: `curriculum/lessons/main/0001.json`

**Requirement:** reading **only** `docs/curriculum-spec.md` + **one** lesson JSON must answer:

- Where is the learner on the CEFR spine?
- What vocabulary/grammar base do they have?
- How strong is each known atom?
- What may / must be introduced next?
- Which side tracks are unlocked?
- How to build lesson \(k+1\) without earlier files (state is self-contained in the lesson)

### 5.1 Top-level schema

```json
{
  "schemaVersion": 1,
  "lessonId": 1,
  "trackId": "main",
  "kind": "listen_produce",
  "locale": "en-US",
  "title": "A2 · Getting things done",
  "sequence": {
    "index": 1,
    "prevLessonId": null,
    "nextLessonId": null
  },
  "timing": {
    "targetMinutes": 15,
    "pairsCount": 30,
    "defaultPauseMs": 3500
  },
  "cefr": {
    "lessonLevel": "A2",
    "band": "A2.2",
    "spineProgress": 0.02,
    "unlockedLevels": ["A2"],
    "targetExitLevel": "B2"
  },
  "pedagogy": {
    "newAtomRatio": 0.15,
    "focus": ["be_going_to", "likely", "come_up_with"],
    "contrast": ["will_vs_going_to"],
    "notes": "First exposure to 'come up with' in planning contexts."
  },
  "learnerState": { },
  "unlocks": { },
  "generationSeed": { },
  "pairs": [ ]
}
```

### 5.2 `learnerState` — the portable brain dump

This is the critical block for incremental generation.

```json
"learnerState": {
  "asOfLessonId": 1,
  "cefrEstimated": "A2",
  "stats": {
    "lessonsCompletedOnTrack": 1,
    "totalPairsSeen": 30,
    "uniqueLemmasKnown": 120,
    "uniqueChunksKnown": 18,
    "grammarNodesUnlocked": 12
  },
  "lexicon": {
    "likely": {
      "kind": "lemma",
      "cefr": "B1",
      "status": "learning",
      "introLessonId": 1,
      "exposures": 4,
      "distinctContexts": 3,
      "lastLessonId": 1,
      "nextDueLessonId": 2,
      "strength": 0.22,
      "srsStep": 1,
      "contexts": ["be_likely_to_V", "will_likely_V", "it_is_likely_that"]
    },
    "come_up_with": {
      "kind": "chunk",
      "cefr": "B1",
      "status": "new",
      "introLessonId": 1,
      "exposures": 2,
      "distinctContexts": 2,
      "lastLessonId": 1,
      "nextDueLessonId": 2,
      "strength": 0.08,
      "srsStep": 0,
      "contexts": ["come_up_with_idea", "come_up_with_plan"]
    }
  },
  "grammar": {
    "be_going_to": {
      "status": "learning",
      "introLessonId": 1,
      "exposures": 8,
      "lastLessonId": 1,
      "nextDueLessonId": 2,
      "strength": 0.35,
      "srsStep": 1,
      "contrastsSeen": []
    }
  },
  "templatesMastered": ["T_be_going_to_V", "T_want_to_V"],
  "priorityQueue": {
    "overdue": [],
    "dueNext": ["likely", "come_up_with", "be_going_to"],
    "weak": ["come_up_with"],
    "readyToGraduate": []
  }
}
```

#### Atom `status` enum

| status | meaning |
|--|--|
| `new` | introduced this lesson or still <3 exposures |
| `learning` | in active SRS climb |
| `familiar` | decent strength, still needs varied contexts |
| `known` | strong + enough contexts; rare maintenance reviews |
| `retired` | optional; superseded or out of band |

#### Graduation rule (example defaults)

Mark `known` when **all** hold:

- `exposures >= 10`
- `distinctContexts >= 8`
- `strength >= 0.75`
- `srsStep >= 4`

### 5.3 `unlocks` — gates for parallel tracks & bands

```json
"unlocks": {
  "nextMainLessonAllowed": true,
  "cefrBandAvailable": ["A2", "B1"],
  "sideTracks": {
    "pronunciation": { "unlocked": false, "reason": "Need 20 main lessons", "progress": "1/20" },
    "dialogues": { "unlocked": false, "reason": "Need 20 main lessons", "progress": "1/20" },
    "micro_practice": { "unlocked": true, "kinds": ["quick_recall_10"] }
  },
  "suggestedNext": [
    { "trackId": "main", "action": "generate_next_lesson" },
    { "trackId": "micro_practice", "action": "optional_between_lessons", "kind": "quick_recall_10" }
  ]
}
```

### 5.4 `generationSeed` — enough to build \(k+1\) without history files

```json
"generationSeed": {
  "fromLessonId": 1,
  "locale": "en-US",
  "cefrAllow": ["A2"],
  "grammarCeiling": ["present_simple", "present_continuous", "past_simple", "be_going_to", "will_future_basic"],
  "mustReview": ["likely", "come_up_with", "be_going_to"],
  "mayIntroduce": {
    "maxNewLemmas": 2,
    "maxNewChunks": 1,
    "maxNewGrammar": 0,
    "preferTopics": ["daily_plans", "work_small_talk"]
  },
  "forbid": {
    "grammar": ["third_conditional", "inversion", "past_perfect_continuous"],
    "register": ["legal", "academic_heavy"]
  },
  "quotas": {
    "pairs": 30,
    "newAtomRatio": 0.15,
    "review": 0.55,
    "variedReuse": 0.22,
    "contrast": 0.08
  },
  "complexity": {
    "lessonMean": 0.28,
    "maxJump": 0.03
  }
}
```

**Generator contract:**  
`nextLesson = f(spec, currentLesson.learnerState, currentLesson.generationSeed)`  
Then write new lesson with **updated** `learnerState` / `unlocks` / `generationSeed`.

### 5.5 Pair object

```json
{
  "id": "main-0001-07",
  "ua": "Ймовірно, сьогодні пізніше піде дощ.",
  "en": "It's likely to rain later today.",
  "pauseMs": 3500,
  "atoms": {
    "lexicon": ["likely", "rain"],
    "grammar": ["be_likely_to"],
    "template": "T_it_be_likely_to_V"
  },
  "roles": ["review", "varied_reuse"],
  "cefr": "A2",
  "notes": null
}
```

`en` must be natural **en-US**. Prefer contractions where spoken US English would.

---

## 6. Lesson composition algorithm (main track)

For lesson \(k+1\) given seed from \(k\):

1. **Refresh dues** — anything with `nextDueLessonId <= k+1` → `mustReview`
2. **Fill review slots** (~50–60%) from overdue/weak/high-frequency
3. **Varied reuse** (~20–25%) — known atoms, **new** context not in `contexts[]`
4. **New** (~10–20%) — within `mayIntroduce` caps and `grammarCeiling`
5. **Contrast** (~5–10%) — near-miss pairs (will vs going to, etc.)
6. **Assemble 30 pairs** (LLM or templates), tag atoms/roles
7. **Update learnerState** — exposures, contexts, strength, srsStep, nextDue
8. **Update unlocks** — e.g. if `lessonsCompletedOnTrack >= 20` → open pronunciation/dialogues
9. **Write generationSeed** for \(k+2\)

### Complexity ramp

\[
C(k)=C_{\max}\cdot\frac{1}{1+e^{-a(k-k_0)}}
\]

Slow early growth (automate A2 core) → mid climb (B1) → plateau into B2 automation.

Per-lesson mean complexity must not jump more than `maxJump` in seed.

---

## 7. Track kinds

| trackId | kind | Role |
|--|--|--|
| `main` | `listen_produce` | Core 15‑min UA→pause→EN drills |
| `micro_practice` | `quick_recall_10` | 3–5 min between mains; 8–12 pairs from `priorityQueue.weak/dueNext` |
| `pronunciation` | `minimal_pairs_ga` / `shadow_ga` | Parallel after unlock; GA targets |
| `dialogues` | `short_dialogue_shadow` | Parallel after unlock; 2-speaker US conversational |

Each track uses the **same** `learnerState` lexicon/grammar ids where possible, so progress stays coherent.

Side-track lesson metadata still includes full `learnerState` snapshot (copy-forward + track-specific deltas).

---

## 8. CEFR spine mapping (initial)

| Band | Lesson index guide (soft) | Focus |
|--|--|--|
| A2 | 1–250 | High-freq daily language, core tenses, essential chunks |
| B1 | 251–650 | Narration, plans/opinions, more phrasals, present perfect contrasts |
| B2 | 651–1000 | Nuance, hypotheticals, denser chunks, flexible rephrase |

Indices are **guides**; actual band is whatever `cefr.lessonLevel` + `learnerState.cefrEstimated` say.  
Starting mid-spine (e.g. enter at A2.2 or B1) is allowed: set initial `learnerState` accordingly.

---

## 9. Incremental workflow

```
project.json
    ↓
[bootstrap lesson 0001 with initial learnerState]
    ↓
lesson k  ──(spec + learnerState + generationSeed)──►  generate lesson k+1
    ↓
optional micro_practice / pronunciation / dialogues
    ↓
TTS generate only new/changed pair audio → save on server
```

**Do not** require the full history of lesson files to continue — only:

1. This spec  
2. `project.json`  
3. **Latest** lesson JSON on the track (or a exported `learnerState` checkpoint)

Older lessons remain immutable content artifacts for playback.

---

## 10. Assessment from metadata alone (checklist)

Given one lesson file + this spec, you must report:

1. **Level now:** `cefr.lessonLevel` / `learnerState.cefrEstimated`  
2. **Progress on spine:** `cefr.spineProgress`  
3. **Vocabulary base size:** `stats.uniqueLemmasKnown` + `uniqueChunksKnown`  
4. **Weak spots:** `priorityQueue.weak` + low `strength`  
5. **Due reviews:** `priorityQueue.dueNext` / `overdue`  
6. **Grammar ceiling:** `generationSeed.grammarCeiling`  
7. **What next main lesson may add:** `generationSeed.mayIntroduce`  
8. **Side content available:** `unlocks.sideTracks` + `suggestedNext`  
9. **Locale compliance:** `locale === "en-US"`  

If any of these cannot be answered, the lesson JSON is incomplete.

---

## 11. Bootstrap profile (example entry points)

| Profile | Initial state |
|--|--|
| `start_a2` | empty/minimal A2 lexicon, grammarCeiling = A2 core |
| `start_a2_seeded` | bootstrap with a small focus set already in `learnerState` (see lesson `0001`) |
| `enter_b1` | prefill A2 atoms as `known`, unlock B1 grammarCeiling |

---

## 12. Non-goals (for clarity)

- Not a full CEFR exam prep course  
- Not live tutor replacement  
- Not British English variant  
- Not generating all 1000 lessons in one shot  
- Main track alone ≠ guaranteed B2 free conversation (parallel speaking/dialogue practice still needed)

---

## 13. File layout (target)

```
docs/curriculum-spec.md          ← this file
curriculum/project.json
curriculum/catalog/lexicon.json  ← optional global dictionary
curriculum/catalog/grammar.json
curriculum/catalog/templates.json
curriculum/lessons/main/0001.json
curriculum/lessons/main/0002.json
curriculum/lessons/micro_practice/...
curriculum/lessons/pronunciation/...
curriculum/lessons/dialogues/...
audio/...                        ← generated later on server
```

---

## 14. Agent / generator prompt contract (short)

When asked to generate the next lesson:

1. Read `docs/curriculum-spec.md` and `curriculum/project.json`
2. Load the latest lesson on the requested track
3. Obey `generationSeed` quotas and forbids
4. Output **one** new lesson JSON with refreshed `learnerState`, `unlocks`, `generationSeed`
5. All `en` = modern American English
6. Do not rewrite past lessons unless explicitly asked
7. If user asks for a side track, check `unlocks.sideTracks` first

---

## 15. Open parameters (tune later, keep explicit)

- Exact core lexicon size (suggested 1500–2500 lemmas + chunks toward B2)
- Exact `known` thresholds
- Unlock gates (default: 20 main lessons → pronunciation & dialogues)
- Pause length defaults
- Whether micro_practice updates `strength` at full or reduced weight

Changes to these parameters belong in `project.json`, with a note in the lesson `pedagogy.notes` when a policy shift starts.
