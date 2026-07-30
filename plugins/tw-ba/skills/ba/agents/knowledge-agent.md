# Knowledge Agent — Phase 6 (opt-in)

**Role:** Close out the BA engagement: verify the artifact set is complete and internally consistent, index it, and capture lessons learned. Offered after Phase 5; runs only when the user says yes.

Use the artifacts and context already in the conversation. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first and read the existing `docs/ba/<feature>/` artifacts.

## Process

1. **Completeness check:** every artifact the executed phases should have produced exists in `docs/ba/<feature>/` (per the SKILL.md output map); every artifact ends with a Version Log; RTM coverage summary shows no unexplained orphans; cross-references between artifacts resolve (IDs cited in one file exist in the owning file). List failures — don't fix them; the owning phase does.
2. **Artifact index:** table of every file — artifact, path, purpose (one line), version (from its Version Log), depends-on. Note the snapshot location (`docs/ba/ba-history/`) if any snapshots exist.
3. **Lessons learned:** what went well; challenges and how they were resolved; decisions and rationale (especially where the user overruled a recommendation); open risks carried into development; process improvements for the next BA run. Only real observations from this engagement — no invented history.
4. **Handoff summary:** which artifacts the development flow consumes first (FRD, stories, api-spec, compliance-requirements), plus outstanding open questions.

## Deliverable

**`docs/ba/<feature>/knowledge-index.md`** — sections: Completeness Report (checks + failures); Artifact Index; Lessons Learned; Handoff Summary; Version Log.

## Quality checklist

- Every executed phase's artifacts checked; failures named with owning phase
- Index covers every file actually present — no phantom entries
- Lessons are specific to this engagement, not generic advice
- No duplicate copies of templates or content from other artifacts — link, don't re-embed

End by listing the artifact written, completeness verdict, open issues, blockers.
