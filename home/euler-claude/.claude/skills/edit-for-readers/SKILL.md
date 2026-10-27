---
name: edit-for-readers
description: Full edit of English prose for a human reader, combining edit-for-coherence (paragraphs), edit-for-lucidity (terms and explicitness), and edit-for-clarity (sentences) in one top-down pass. Use when the user asks for a thorough or complete edit, wants all the editing skills applied at once, or wants a scientific or biomedical draft (paper, thesis, grant, report) made easy to read. The three individual skills remain available for narrower requests.
---

# Edit for Readers

A reader reads once, at reading speed, without access to the writer's head. Edit so that one reading is enough, without changing what the text says.

## Sources

This skill combines three skills and their sources:

- **edit-for-coherence:** Strunk W (1920), *The Elements of Style*, rules 8–9; Mensh B, Kording K (2017), Ten simple rules for structuring papers, *PLoS Comput Biol* 13:e1005619; Gopen GD, Swan JA (1990), The science of scientific writing, *Am Sci* 78:550–558; Plaxco KW (2010), The art of writing science, *Protein Sci* 19:2261–2266; Carandini M (2022), Some tips for writing science, *eNeuro* 9:ENEURO.0497-22.2022.
- **edit-for-lucidity:** McIntyre ME (1997–1998), Lucidity and science, Parts I–III, *Interdiscip Sci Rev* 22:199–216, 22:285–303, 23:29–70; *Lucidity principles in brief*, https://www.damtp.cam.ac.uk/user/mem2/lucidity-in-brief/
- **edit-for-clarity:** Clark TH, Martin MB, Mahowald K (2026), Why is AI-generated language so hard to understand? arXiv:2610.29162.

The common reason behind all of them: readers interpret text as they go, predicting what comes next and fitting it to what came before. Text that meets those expectations is understood in one pass; text that breaks them forces re-reading.

## The rule in one sentence

One point per paragraph, stated first; one word for each thing; more explicit than feels necessary; old information before new; plain, predictable words.

## 1. Paragraphs

**The standard paragraph** (Strunk's "most generally useful kind of paragraph"; Mensh and Kording's context-content-conclusion):

| Part | Job | Check |
|---|---|---|
| Topic sentence (first one or two) | Context and, ideally, the point | The first sentences alone tell the whole story |
| Body | Every sentence supports or develops the topic sentence | One opening sentence covers it all; if not, split |
| Conclusion (last sentence) | The answer, consequence, or implication | Not a digression, a minor detail, or a verbatim repeat |

**By section** (Mensh and Kording):
- Introduction: context, then what is known, ending on the gap. The last paragraph says what the paper does and finds.
- Results: the question ("We next tested whether …"), then data and logic, ending on the answer. The claim also goes in the heading or figure title. Cite figures in parentheses, "X increased Y (Fig. 2b)", not "Fig. 2b shows that …" (Carandini).
- Discussion: a strength or limitation, then how other work bears on it, ending on the implication. The first paragraph summarizes the findings.
- For rushed readers (abstracts, grant aims), state the point first, then justify it (Carandini).

**Order:** prepare each point before making it; keep each subject in one place instead of returning to it ("zig-zag"); put the main points in first and last sentences, where readers notice them.

| Before | After |
|---|---|
| We treated HeLa cells with bafilomycin A1 for 4 h and stained them for LC3. Fig. 2a shows that LC3 puncta increased 3-fold. Autophagic flux is therefore active in these cells. | To test whether autophagic flux is active in HeLa cells, we blocked lysosomal degradation with bafilomycin A1 for 4 h. LC3 puncta increased 3-fold (Fig. 2a). Autophagic flux is therefore active in these cells. |

## 2. Terms and references

- **One word for each thing.** List every term used for each important thing, in figures and tables as well as prose; choose one and use it every time. Writers vary words to avoid boring themselves; readers take each new word as a new thing. Declare a needed alternative once ("Gibbs fringes, i.e. truncation oscillations, ..."). If unsure that two terms are synonyms, ask instead of merging them.
- **The same word pattern for comparable things**, and different words for different things. Use the standard form of a pattern: "distinguish A from B".
- **Pronouns.** Put a noun after "this" and "these", or replace them with the noun. Any other pronoun is safe only if its antecedent is the last and only thing just mentioned.
- **Definitions at first occurrence** for every term, symbol, and abbreviation. Remind the reader when one returns after a gap ("the potential energy P", not "P").
- **Small structural words.** Keep or restore "that" before a clause, "then" after "if", and the preposition before each item of a list.
- **Explicitness.** Be about twice as explicit as feels necessary: "two trivialities omitted can add up to an impasse" (Littlewood, quoted by McIntyre). Watch for words with two senses: "drive" (control, or supply energy?), "implies" (or only "suggests"?), "proof" (practical or absolute certainty?).

| Before | After |
|---|---|
| Whereas the spectral method engenders Gibbs fringes, no discretisation oscillations are manifested by the TVD algorithm. | Whereas the spectral method produces Gibbs fringes, the TVD method produces no Gibbs fringes. |
| The cache is rebuilt when the index changes. This can take minutes. | The cache is rebuilt when the index changes. The rebuild can take minutes. |
| ... send one to the Prime Minister, William Waldegrave, and others. | ... send one to the Prime Minister, to William Waldegrave, and to others. |
| The fix the reviewer asked for is in. | The fix that the reviewer asked for is in. |

## 3. Sentences

- **Old before new.** Start each sentence with information that links back (the topic position), and end it with the new information to stress (the stress position). Keep the same "whose story" in the topic positions.
- **Subject close to verb.** If more than about eight words separate them, move the insertion to the start or end, or split the sentence.
- **Action in the verb:** "we implanted the widget", not "the implantation of the widget was performed".
- **Plain, predictable words.** Replace rare word combinations and coined metaphors with the common phrase. Give things verbs that things can do. Avoid unusual nouns used as verbs. Unpack runs of three or more nouns.
- **Needless words.** Cut words that add nothing, but keep the words that make structure or reference explicit.

| Before | After |
|---|---|
| Transcription of the 5S RNA genes in the egg extract is TFIIIA-dependent. | In the egg extract, the availability of TFIIIA limits transcription of the 5S RNA genes. |
| The deadline is quietly eating your margin. | The deadline is reducing your margin. |
| `parse()` swallows the error and returns None. | `parse()` catches the error and returns None. |
| I'll ticket this for next sprint. | I'll create a ticket for this for next sprint. |
| The user session token refresh logic is broken. | The logic that refreshes session tokens for users is broken. |
| All five expression shapes, including attribute access, subscripts, calls, nested calls, and string literals, leave the cursor on the same token. | All five expression shapes leave the cursor on the same token. The five shapes are attribute access, subscripts, calls, nested calls, and string literals. |

## Procedure

Work top-down, because each level moves text that the next level edits.

1. **Read once** without editing. Note the reader, the purpose, and the main points.
2. **Paragraphs.** Reverse-outline: write each paragraph's point in one sentence. Split paragraphs with two points, merge or cut those with none, and reorder within sections. Then fix each topic sentence, body, and conclusion.
3. **Terms.** Choose one word per thing; define each at first occurrence.
4. **Sentences.** Pronouns, structural words, old before new, plain words.
5. **Re-read once as a newcomer**, at reading speed, then read only the first sentences. Check that the meaning is unchanged and that no new problems crept in.

## What not to change

- **Meaning:** claims, data, numbers, citations, and figure references. If a fix needs knowledge you lack (what "it" refers to, a paragraph's point, a missing step), ask instead of guessing.
- **Code, commands, identifiers, paths, and quotations.**
- **Tone and register.** Choose active or passive voice for what it puts first, not by rule. Don't enforce folk rules such as "never repeat a word" or "never start a sentence with But".
- **Headings and lists.** Propose moves between sections rather than making them.
- **Text that already works.** These are principles, not rules; keep a deliberate exception that works.

Adding words is fine: longer for the writer often means shorter for the reader.

## Output

Return the edited text, then a short list of changes grouped by level, then questions for the author:

```
[edited text]

---
Paragraphs: ¶3 split in two; topic sentence added to ¶4
Terms: "TVD algorithm", "TVD scheme" → "TVD method" (3×); "This" → "The rebuild"
Sentences: "swallows the error" → "catches the error"; split one 40-word sentence
Questions: ¶2, does "it" mean the cache or the index?
```

For a file, edit it in place and give the list in chat. If the user says "just the text", return only the text. If nothing needs changing, say so.

## Quick checklist

- [ ] The first sentences alone tell the story; each paragraph makes one point and ends on its conclusion
- [ ] Each point prepared before it is made; each subject in one place
- [ ] One word per thing; comparable things in the same pattern
- [ ] Every "this" and "these" followed by a noun; no other pronoun ambiguous
- [ ] Every term, symbol, and abbreviation defined at first occurrence
- [ ] "that", "then", and list prepositions present where needed
- [ ] Old before new; subject close to verb; action in the verb
- [ ] No rare word pairs, human verbs for things, odd noun-verbs, or noun stacks
- [ ] Meaning, code, quotations, and tone unchanged
