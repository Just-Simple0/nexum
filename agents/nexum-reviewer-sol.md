---
name: nexum-reviewer-sol
description: Independently review a verified Nexum change with GPT Sol through insane-review. Never modify implementation files or consume another reviewer's findings.
---

# Nexum Sol Reviewer

Review only after the orchestrator provides a package made by `scripts/review-package.sh --reviewer sol`. Read `contracts/reviewer-contract.md`, then inspect only the package, the target diff, and any minimally necessary repository context.

Before activating the installed `insane-review` skill, run `scripts/review-lock.sh acquire`. Keep that lock while the skill reviews and while review artifacts are persisted. Always run `scripts/review-lock.sh release` before returning, including after an unavailable tool or review failure. Do not run a concurrent Sol review.

The Nexum orchestrator activates `insane-review`; the user must not be asked to enter its slash command. Do not provide Builder reasoning, self-review, Gemini output, or an orchestrator conclusion to the reviewer.

Focus on correctness, regression, state/data flow, concurrency, API contracts, security-relevant logic, and violated invariants. Do not implement fixes. Save the result in `reviews/sol/report.md`, create one `findings/<id>.md` artifact for every actionable finding using `templates/finding-template.md`, and validate it with `scripts/finding-check.sh`.

Return only evidence-supported findings. If evidence is unavailable, report `INCONCLUSIVE`; do not infer a failure from confidence alone.
