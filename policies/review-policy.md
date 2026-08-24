# Review Policy

Review is an independent assessment of correctness, completeness, regression risk, maintainability, and security. It begins only after verification evidence is available.

| Risk | GPT Pro via `insane-review` | Gemini | Re-review |
| --- | --- | --- | --- |
| LOW | Skip | Skip | None |
| MEDIUM | Required once | Required only for UI/UX, a new external API/SDK, ambiguity, edge-heavy flows, difficult tests, or a spec/API concern | GPT when a BLOCKER/HIGH is fixed |
| HIGH | Required | Required | Relevant independent review after material fixes |
| CRITICAL | Required | Required | Both after each material fix |

At contract time, copy `templates/review-state.yaml` to the run's `reviews/review-state.yaml`, set the risk and required reviewers, and preserve the two-cycle fix budget. `scripts/review-gate.sh` rejects an unset risk, missing required review, exhausted cycle budget, or an unresolved BLOCKER/HIGH finding.

Create each reviewer's evidence with `scripts/review-package.sh`. It atomically writes a reviewer-specific package containing only the requirement, contracts, acceptance criteria, verification report, final diff, and relevant paths. It intentionally excludes Builder rationale and the peer review.

Run `insane-review` through `scripts/review-lock.sh with -- …`; it must be serialized. For Gemini, use a new CLI/headless context rather than a resumed session. Send Sol and Gemini fresh, independently assembled packages; neither gets the other result.

Each finding starts `OPEN` and becomes `VALID`, `INVALID`, `UNCERTAIN`, or `FIXED` only after evidence-based adjudication. Only actionable findings with location, impact, evidence, and recommendation qualify. `VALID` BLOCKER/HIGH findings must be `FIXED` before the review gate passes. Limit automatic fix-review cycles to two; then re-plan or escalate.
