---
name: edit-for-lucidity
description: Edit English text for lucidity, following Michael McIntyre's lucidity principles of lucid repetition (the same word for the same thing, not gratuitous variation), explicitness (more explicit than feels necessary, no ambiguous "this"), and coherent ordering (context before each new point). Use this skill when the user asks to edit for lucidity or mentions McIntyre or lucidity principles, and when a draft (especially scientific or technical writing such as a paper, thesis, proposal, README, or documentation) needs checking for inconsistent terminology, ambiguous pronouns, unexplained terms or steps, or points made out of order. Complements edit-for-clarity, which fixes sentence-level reading difficulty.
---

# Edit for Lucidity

Make text quick to understand in one reading, without changing what it says.

## Source

This skill is based on Michael McIntyre's lucidity principles:

> Michael E. McIntyre (1997–1998). *Lucidity and science*, Parts I–III. Interdisciplinary Science Reviews 22, 199–216 and 285–303; 23, 29–70. Part I, *Writing skills and the pattern perception hypothesis*, is the one about writing. https://www.damtp.cam.ac.uk/user/mem2/papers/LHCE/index.html
>
> *Lucidity principles in brief*: https://www.damtp.cam.ac.uk/user/mem2/lucidity-in-brief/
>
> Draft-revision toolkit: https://www.damtp.cam.ac.uk/user/mem2/oldftp/lucidity-supplem.txt

McIntyre's argument: readers understand text the way the brain perceives anything, by unconsciously fitting models to the input, ahead of conscious thought. Lucid text helps because its surface patterns agree with its meaning. When they disagree, reading slows, as when the word "red" is printed in green ink. This skill turns his principles, and the marginal marks of his toolkit (GV, LR, EX, CO, ...), into editing rules.

## The rule in one sentence

Use the same word for the same thing and different words for different things, be more explicit than feels necessary, and prepare each point before making it.

## The three principles

### 1. Lucid repetition (LR), not gratuitous variation (GV)

**What it is:** Gratuitous variation is using different words for the same thing, usually to avoid repeating a word; Fowler ironically called it "elegant variation". Gratuitous pattern-variation (GPV) is expressing comparable things in different word patterns. Side-slip (SS) mixes two standard patterns, as in "distinguish A versus B".

**Why it hurts:** Each new word makes the reader ask whether a new thing is meant: one model or two? Synonyms are not interchangeable; each brings its own associations (believing otherwise is McIntyre's "1-1 lexical fallacy"). By his organic-change principle, we perceive patterns best when some elements change while others stay the same, and repeated words are the elements that stay the same. Writers vary words because repetition bores *them* after many re-readings; the reader meets each sentence once, at reading speed.

**How to find it:** For each important thing (an object, method, file, option, quantity, person, or idea), list every term the text uses for it, in figures, captions, and tables as well as in the prose. More than one term is gratuitous variation, unless the terms mean different things. In each comparison or contrast, check that both halves use the same word pattern.

**How to fix:** Choose one term, usually the one introduced first or the plainest, and use it every time (LR). Give comparable things the same word pattern, so that the repeated part signals the comparison and the changed part carries the difference (lucid pattern-repetition, LPR; Strunk and White's "parallel construction"). Use the standard form of a pattern: "distinguish A from B", "provided that".

| Before | After |
|---|---|
| Whereas the spectral method engenders Gibbs fringes, no discretisation oscillations are manifested by the TVD algorithm. | Whereas the spectral method produces Gibbs fringes, the TVD method produces no Gibbs fringes. |
| If you are serious, then I'll be also. | If you are serious, then I'll be serious. |
| Skilled writers distinguish what helps the reader versus indulging themselves. | Skilled writers distinguish what helps the reader from what indulges the writer. |
| Set the timeout in `config.yaml`. If the settings file is missing, defaults are used. | Set the timeout in `config.yaml`. If `config.yaml` is missing, defaults are used. |
| Anticyclones (cyclones) rotate clockwise (anticlockwise) in the northern hemisphere. | In the northern hemisphere, anticyclones rotate clockwise and cyclones anticlockwise. |

Also note:
- **Two terms really needed** (say, a standard alternative name): declare them once, at first occurrence, then keep to one. "Gibbs fringes, i.e. truncation oscillations, ..." or "We use the idea of X, also known as Y". Avoid "X, or Y": the "or" can be misread as two alternatives.
- **The opposite faults:** incongruous repetition (IR) uses the same noticeable word nearby for a different thing ("the absence of a marked interhemispheric gradient. This is in marked contrast to ..."); incongruous juxtaposition (IJ) uses related words for unrelated things ("The experiments concentrated on dilute solutions").
- **Shortened repetition** is fine right after the full pattern, if no variation comes in between, as in the last example above.
- **Not repetitiousness.** Lucid repetition repeats words while the content moves on. Saying the same thing again without developing it is still a fault.
- **Unsure whether two terms mean the same thing?** Don't merge them. Flag them for the author.

### 2. Explicitness (EX): more explicit than feels necessary

**What it is:** Leaving the reader to supply what the writer knows: what a pronoun refers to (an ambiguous antecedent, AA), a step in an argument, the meaning of a symbol, or a small word that marks the structure of a sentence.

**Why it hurts:** The reader's head isn't full of what the writer's head is full of, and the writer's mind fills the gaps without noticing. "Two trivialities omitted can add up to an impasse" (J. E. Littlewood). McIntyre's rule of thumb is to be about twice as explicit as seems necessary, and not to worry about insulting the reader's intelligence.

**How to find it:**
- Imagine every pronoun flashing red: "this" and "these" fastest, then "it", "its", "they", "them", "their", "those", "ones", "none", "the former", "the latter". A pronoun is safe only if its antecedent is the last thing mentioned and the only thing just mentioned.
- Look for dropped words that mark structure: the "then" of "if ... then", the preposition before each item of a list, the second "at" in "both at A and at B".
- Look for symbols, abbreviations, and names used far from where they were introduced.
- Look for steps the writer found too obvious to state, and for assertions that give no source and no sense in which they hold.
- Look for words with more than one sense in context: "drive" (control, or supply the energy?), "implies" (or only "suggests"?), "proof" and "truth" (the practical certainty that scientists mean, or the absolute certainty that many readers hear?).

**How to fix:** Replace the pronoun with its noun, or put a noun after "this" or "these" ("this change", "these files"). Restore the dropped word. Remind the reader what a symbol or name stands for when it returns after a gap ("the potential energy P", not "P" alone). Add the missing step, or say where the claim comes from. Choose an unambiguous word, or state the sense.

| Before | After |
|---|---|
| The cache is rebuilt when the index changes. This can take minutes. | The cache is rebuilt when the index changes. The rebuild can take minutes. |
| ... hoped that members would send one to the Prime Minister, William Waldegrave, and others. | ... hoped that members would send one to the Prime Minister, to William Waldegrave, and to others. |
| Whereas the spectral method produces Gibbs fringes, associated with [a long explanation], the TVD method produces none. | Whereas the spectral method produces Gibbs fringes, associated with [a long explanation], the TVD method produces no Gibbs fringes. |
| A button labelled "Cancel" | A button labelled "Cancel upload" |

Without the second "to", many readers take the Prime Minister and William Waldegrave to be one person.

### 3. Coherent ordering (CO): context before new points

**What it is:** A point, term, or symbol that appears before the reader has what is needed to understand it.

**Why it hurts:** With no context to fit it to, the reader must read on and come back, or give up. McIntyre's typical referee: "The author uses three undefined terms and two undefined symbols on page 2." The author: "But if only the referee had read on, all would have become clear."

**How to find it:**
- Find the first occurrence of each important term, symbol, and abbreviation. Is its sense established there? An explanation that comes later, often in parentheses or disguised as a second term for the same thing, means that the order is wrong.
- For each paragraph, ask: does the reader already have everything this paragraph needs?
- Check the key positions: the first and last sentences of the text, of each section, and of each paragraph. Readers remember them best. Do they carry main points, or something that no reader needs to be told ("The Earth's atmosphere is constantly in motion")?
- Check the level. Is it clear when the text is approximate and when it is exact? Does it explain easy terms but not hard ones?

**How to fix:** Move each explanation to the first occurrence of its term, with a signpost: "X, i.e. Y, ..."; "We use X in the sense of ..., not to be confused with ...". If the full explanation must wait, give a rough sense and say that more follows. Move preparation in front of the point that it prepares. Signal changes of precision: "Roughly speaking, ... More precisely, ...". Put the main points in key positions; the end of a sentence carries the most emphasis.

## Supporting checks

From McIntyre's toolkit, with his marks:

| Mark | Problem | Fix |
|---|---|---|
| NW (needless words) | Words that add nothing | Omit them, but keep any word that makes a pattern clearer: a repeated noun, a "then", a preposition, a word that fixes the rhythm |
| P (plainness) | Long, fashionable, or in-group words; idioms | Use the plainest, most literal word ("buoyancy frequency", not "Brunt–Väisälä frequency"); avoid idioms that trip non-native readers ("in my book") |
| SC (simplicity of construction) | Over-elaborate sentence | Split it into two or more sentences |
| UP (unnecessary parentheses) | Parentheses holding afterthoughts | Reorder, or use a comma pair: "An additional plot, not shown, was obtained" |
| CP (comma pair) | One comma of a parenthetical pair | Use both commas or neither |
| SA (stray adjective) | Adjective attaching to the wrong noun ("mean mass-weighted potential vorticity") | Put it next to its noun ("mass-weighted mean of the potential vorticity") |
| LFC (lazy figure caption), RI (redundancy of information) | Caption that says "as in Fig. 3"; key number given only once | Repeat the information where the reader needs it |
| IRW (incongruous royal we) | "We" meaning a single author | "I", or the passive ("g was measured"); "we" meaning "you and I, dear reader" is fine |
| SU (seriously unclear) | Inconsistency: statements or numbers that contradict each other, or a self-contradictory term | Flag for the author. Language has no built-in consistency check, so look for these deliberately |

## Procedure

1. **Read the whole text once** without editing. Note the reader, the purpose, and the main points.
2. **List the terms.** For each important thing, note every term used for it and where each term first appears. Choose one term per thing.
3. **Check the order.** Each term should be explained at its first occurrence, and each point should come after its preparation. Move explanations and sentences within a section as needed; propose, rather than make, moves between sections.
4. **Go sentence by sentence:** lucid repetition, then explicitness, then the supporting checks.
5. **Re-read once as a newcomer, at reading speed.** Check that every edit keeps the meaning and that no new variation crept in.
6. **Output** the result as described below.

When unsure whether a shorter version is safe, keep the explicit one ("safety first"). Shorten by using plainer words and cutting needless words. Shorten by using pronouns or telescoping word patterns only when certain that it is safe.

## What NOT to change

- **Meaning.** Never add, remove, or soften a claim. If being explicit needs knowledge that you lack (what "it" refers to, which sense of a word is meant, a missing step), don't guess. Flag it.
- **Code, commands, identifiers, paths, and quotations.** Keep them exactly as written. Repeating an identifier in place of a vague phrase is fine.
- **Tone and register.** Keep casual text casual and formal text formal. Don't swap active and passive voice by rule.
- **Folk rules.** Don't enforce "never repeat a word", "never start a sentence with But", "never split an infinitive", or "never use the passive". The first of these is what causes gratuitous variation.
- **Literary play.** In poetry, fiction, and jokes, variation and ambiguity may be the point.
- **Lucid passages.** If a passage is already lucid, leave it alone.

Lucid text is often longer for the writer and shorter for the reader. Adding words is fine.

## Output format

Default: the full edited text, then a short list of changes labelled with McIntyre's marks, then any flags for the author (questions, and proposed moves between sections). Example:

```
[edited text]

---
Changes:
- GV → LR: "TVD algorithm", "TVD scheme" → "TVD method" (3×)
- AA: "This can take minutes" → "The rebuild can take minutes"
- CO: moved the definition of "Gibbs fringes" to its first occurrence
Flags:
- AA, paragraph 2: "it" could be the cache or the index. Which?
```

If the user asks for edits in a file, edit the file in place and report the list in chat. If the user says "just the text" or similar, return only the edited text. If nothing needs changing, say so and return the text unchanged.

## Quick checklist

- [ ] One term per thing, every time; any alternative term declared once, at first occurrence
- [ ] Comparable things in the same word pattern; standard patterns, no side-slip
- [ ] No noticeable word reused nearby for a different thing
- [ ] Every "this" and "these" followed by a noun or replaced; every other pronoun unambiguous
- [ ] No dropped "then", prepositions, or steps; symbols tied to their names when they return
- [ ] Every term and symbol explained at first occurrence; every point prepared before it is made
- [ ] Main points in key positions; changes of precision signposted
- [ ] Needless words cut, clarifying words kept
- [ ] No statements, numbers, or terms that contradict each other (flag any you find)
- [ ] Meaning, code, quotations, and tone unchanged
