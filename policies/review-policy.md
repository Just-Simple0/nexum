# Review Policy

Review is an independent assessment of correctness, completeness, regression risk, maintainability, and security. It begins only after verification evidence is available.

| Risk | GPT Pro via `insane-review` | Gemini | Re-review |
| --- | --- | --- | --- |
| LOW | Skip | Skip | None |
| MEDIUM | Required once | Required only for UI/UX, a new external API/SDK, ambiguity, edge-heavy flows, difficult tests, or a spec/API concern | GPT when a BLOCKER/HIGH is fixed |
| HIGH | Required | Required | Relevant independent review after material fixes |
| CRITICAL | Required | Required | Both after each material fix |

Run `insane-review` through `scripts/review-lock.sh with -- …`; it must be serialized. Send GPT and Gemini fresh, independently assembled packages; neither gets the other result.

Each finding must be `VALID`, `INVALID`, or `UNCERTAIN` after evidence-based adjudication. Only actionable findings with location, impact, evidence, and recommendation qualify. Limit automatic fix-review cycles to two; then re-plan or escalate.

