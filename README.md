# Nexum

Nexum is a Claude Code orchestration layer for software changes that need more than one pair of eyes. It separates planning, implementation, verification, review, and evidence-based completion instead of treating a coding task as one uninterrupted agent run.

## What it provides

- Risk-based workflow controls: LOW, MEDIUM, HIGH, and CRITICAL.
- Isolated Sonnet builders and cross-model Terra execution routing.
- Independent verification that cannot modify production code.
- Fresh-context GPT Sol High and Google/Antigravity review lanes.
- Contracts, report templates, retry limits, scope guards, and completion gates.

## Cross-model route (V2)

For a bounded, frozen task, run `scripts/preflight.sh` before `scripts/terra-worker.sh`. Preflight validates the Codex CLI capabilities, Git worktree, and writable project-local temporary directory without creating a model run. The adapter canonicalizes `--project`, supports separate `builder` and non-modifying `verifier` roles, explicit `--model` and `--effort` selection, a `--dry-run` check, and `--output` for durable handoffs. Add `--session-record` to persist a session ID for retry evidence; current Codex resume cannot safely reassert the project and sandbox boundary, so retries start a fresh validated session.

Validate the adapter locally with `bash tests/smoke/terra-worker.smoke.sh`.

Nexum keeps high reasoning for tasks that need it. It reduces waste first with `scripts/preflight.sh`, the `direct | bounded | context-heavy` route, and compact Builder dispatch packets rather than lowering effort indiscriminately.

## Independent reviews (V3)

After verification, Nexum creates one fresh, reviewer-specific evidence package with `scripts/review-package.sh`. `scripts/review-preflight.sh` verifies the local Antigravity runtime before a required Google review. The Sol lane activates the installed `insane-review` skill at the configured High tier under the Nexum review lock. The logical Gemini lane uses one fresh OMC `ask antigravity` invocation—not `/ccg`, a direct Google CLI session, or a resumed conversation. Neither reviewer receives Builder rationale or the other reviewer's findings. Their reports and normalized findings are checked by `scripts/finding-check.sh` and `scripts/review-gate.sh`; the latter enforces risk-based reviewer obligations, invocation provenance, and the two-cycle review-fix budget.

## Install in Claude Code

Copy this repository into your personal skills directory as `~/.claude/skills/nexum`. Then copy the files in `agents/` to `~/.claude/agents/`.

Invoke the skill for a substantial software change. Nexum creates its local run evidence in `.nexum/`, which is intentionally ignored by Git.

## Operating model

```text
request → risk → contract → builder → verifier → review → evidence gate → completion
```

Nexum is a policy layer. It uses Claude Code native agents and can integrate existing tools such as `insane-review`, `docs-guide`, `insane-search`, and `insane-research`; those tools remain optional external dependencies.

## License

Apache-2.0. See [LICENSE](LICENSE).
