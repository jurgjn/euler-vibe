---
name: edit-for-coherence
description: Write or edit biomedical and other scientific text in the standard paragraph format, in which each paragraph makes one point, opens with a topic sentence, develops it in the body, and ends on a conclusion, and each sentence runs from old to new information. Use when the user asks to structure, restructure, or tighten paragraphs, to draft or edit an Introduction, Results, or Discussion, or mentions topic sentences, context-content-conclusion (C-C-C), or the standard paragraph. Complements edit-for-clarity (sentence patterns) and edit-for-lucidity (terms, explicitness, ordering).
---

# Edit for Coherence

Give every paragraph one point, and let the reader find it in the first sentence.

## Sources

- Strunk W (1920). *The Elements of Style*, rules 8–9. https://www.gutenberg.org/ebooks/37134
- Mensh B, Kording K (2017). Ten simple rules for structuring papers. *PLoS Comput Biol* 13:e1005619. https://doi.org/10.1371/journal.pcbi.1005619
- Gopen GD, Swan JA (1990). The science of scientific writing. *Am Sci* 78:550–558.
- Plaxco KW (2010). The art of writing science. *Protein Sci* 19:2261–2266. https://doi.org/10.1002/pro.514
- Carandini M (2022). Some tips for writing science. *eNeuro* 9:ENEURO.0497-22.2022. https://doi.org/10.1523/ENEURO.0497-22.2022

## The standard paragraph

Strunk calls it "the most generally useful kind of paragraph"; Mensh and Kording call it context-content-conclusion (C-C-C).

| Part | Job | Check |
|---|---|---|
| **Topic sentence** (first one or two sentences) | Sets the context and, ideally, states the point | Reading only the first sentences of all paragraphs tells the whole story (Plaxco, Carandini) |
| **Body** | Every sentence explains, supports, or develops the topic sentence: data, figure references, citations, reasoning | One opening sentence can cover everything in the paragraph; if not, split it (Plaxco) |
| **Conclusion** (last sentence) | The point to remember: an answer, a consequence, or an implication | Not a digression, a minor detail (Strunk), or a verbatim repeat of the topic sentence (Carandini) |

Without the context, readers ask "Why was I told that?"; without the conclusion, "So what?" (Mensh and Kording).

## Paragraph patterns by section (Mensh and Kording, rules 6–8)

- **Introduction:** context, then what is known, ending on what is unknown (the gap). The last paragraph says what the paper does and finds.
- **Results:** the question ("We next tested whether …"), then data and logic, ending on the answer. Also state the claim in the subsection heading or figure title. Cite figures in parentheses, "X increased Y (Fig. 2b)", not "Fig. 2b shows that …" (Carandini).
- **Discussion:** a strength or limitation, then how other work bears on it, ending on the implication or next step. The first paragraph summarizes the main findings.

For rushed readers (abstracts, grant aims, reviewers), put the point itself in the first sentence, then justify it (Carandini's "assert/justify").

| Before | After |
|---|---|
| We treated HeLa cells with bafilomycin A1 for 4 h and stained them for LC3. Fig. 2a shows that LC3 puncta increased 3-fold. Autophagic flux is therefore active in these cells. | To test whether autophagic flux is active in HeLa cells, we blocked lysosomal degradation with bafilomycin A1 for 4 h. LC3 puncta increased 3-fold (Fig. 2a). Autophagic flux is therefore active in these cells. |

## Inside the paragraph: old before new (Gopen and Swan)

- Begin each sentence with old information that links back (the topic position); end it with the new information to stress (the stress position).
- Keep the same "whose story" in the topic positions instead of switching subject every sentence.
- Put the action in the verb, and keep the subject close to its verb.
- Keep the links between sentences ("Because of this, …"). Don't open a paragraph with a bare "However,"; restate the idea it links to (Plaxco).

| Before | After (Gopen and Swan's revision) |
|---|---|
| Transcription of the 5S RNA genes in the egg extract is TFIIIA-dependent. This is surprising, because the concentration of TFIIIA is the same as in the oocyte nuclear extract. | In the egg extract, the availability of TFIIIA limits transcription of the 5S RNA genes. This is surprising because the same concentration of TFIIIA does not limit transcription in the oocyte nuclear extract. |

## Procedure

1. **Reverse-outline.** Write each paragraph's point as one sentence. Two points: split. No point: merge or cut. One subject spread over several places: bring it together (Mensh and Kording's "zig-zag").
2. **Read the outline alone.** It should tell the story in order; if not, reorder the paragraphs.
3. **Fix each paragraph:** topic sentence first, body on topic, conclusion last.
4. **Fix each sentence:** old before new.
5. **Re-read only the first sentences.** They should still tell the story.

## Limits and output

- Keep claims, data, numbers, citations, and figure references unchanged. If a paragraph has no clear point, ask the author rather than invent one; restructuring often exposes a gap in the argument (Gopen and Swan).
- These are principles, not rules: any of them can be broken to good effect, as long as most of the text follows them (Gopen and Swan).
- Output the edited text, then one line per changed paragraph ("¶3: split in two; topic sentence added; conclusion moved to the end") and any questions for the author. For a file, edit it in place and report the list in chat.
