# Review Policy

Review is an independent assessment of correctness, completeness, regression risk, maintainability, and security. It begins only after verification evidence is available.

| Risk | GPT Sol High via `insane-review` | Google reviewer via Antigravity | Re-review |
| --- | --- | --- | --- |
| LOW | Skip | Skip | None |
| MEDIUM | Required once | Required only for UI/UX, a new external API/SDK, ambiguity, edge-heavy flows, difficult tests, or a spec/API concern | GPT when a BLOCKER/HIGH is fixed |
| HIGH | Required | Required | Relevant independent review after material fixes |
| CRITICAL | Required | Required | Both after each material fix |

At contract time, copy `templates/review-state.yaml` to the run's `reviews/review-state.yaml`, set the risk and required reviewers, and preserve the two-cycle fix budget. `scripts/review-gate.sh` rejects an unset risk, missing required review, exhausted cycle budget, or an unresolved BLOCKER/HIGH finding.

Create each reviewer's evidence with `scripts/review-package.sh`. It atomically writes a reviewer-specific package containing only the requirement, contracts, acceptance criteria, verification report, final diff, and relevant paths. It intentionally excludes Builder rationale and the peer review.

Run `scripts/review-preflight.sh` before a required Google review. Before the orchestrator activates `insane-review`, acquire `scripts/review-lock.sh acquire`; release it after the Sol review artifacts are persisted, including on failure. It must be serialized. Use the configured `high` Sol reasoning tier and record the actual verified model/tier; do not claim a Pro tier unless it was verified. For the logical Gemini review lane, invoke OMC `ask antigravity` once with a fresh package; do not use `/ccg`, direct Google CLI invocation, or a resumed session. Send Sol and Google fresh, independently assembled packages; neither gets the other result.

Artifacts from another run are not reviewer input. Ignore them unless the current task contract explicitly includes them; an unexpected artifact is not evidence of tampering or malicious activity by itself.

Each finding starts `OPEN` and becomes `VALID`, `INVALID`, `UNCERTAIN`, or `FIXED` only after evidence-based adjudication. Only actionable findings with location, impact, evidence, and recommendation qualify. `VALID` BLOCKER/HIGH findings must be `FIXED` before the review gate passes. Limit automatic fix-review cycles to two; then re-plan or escalate.
