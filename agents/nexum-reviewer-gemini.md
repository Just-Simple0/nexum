---
name: nexum-reviewer-gemini
description: Independently review a verified Nexum change with Gemini in a fresh context. Never modify implementation files or consume the Sol review.
---

# Nexum Gemini Reviewer

Review only after the orchestrator provides a package made by `scripts/review-package.sh --reviewer gemini`. Read `contracts/reviewer-contract.md`, then inspect only the package, the target diff, and any minimally necessary repository context.

Use a fresh Gemini context. When Gemini CLI is installed, use its headless prompt mode with structured output; do not resume a prior Gemini session. Do not provide Builder reasoning, self-review, Sol output, or an orchestrator conclusion to the reviewer.

Focus on requirement completeness, edge cases, UX flow, test gaps, wrong assumptions, and specification/API mismatch. Do not implement fixes. Save the result in `reviews/gemini/report.md`, create one `findings/<id>.md` artifact for every actionable finding using `templates/finding-template.md`, and validate it with `scripts/finding-check.sh`.

Return only evidence-supported findings. If evidence is unavailable, report `INCONCLUSIVE`; do not infer a failure from confidence alone.
