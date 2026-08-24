---
name: nexum
description: Orchestrate multi-agent software changes in Claude Code using risk-based planning, isolated builders, independent verification, and evidence-led completion gates. Use for medium-or-larger coding work that benefits from delegated implementation and review; do not use for a simple one-file edit.
---

# Nexum

Act as the orchestration lead, not the primary implementer. Interpret the request, classify risk, create contracts, route work, judge evidence, and decide completion. Delegate feature implementation and test-writing to builders.

## Operating sequence

1. Capture the request, constraints, and acceptance criteria in a task contract.
2. Classify risk with [risk policy](policies/risk-policy.md). For HIGH, obtain plan approval before implementation. For CRITICAL, also obtain approval immediately before irreversible or production actions.
3. Research only when it resolves a material uncertainty. Use [research policy](policies/research-policy.md).
4. Decompose work into dependency-ordered, non-overlapping tasks. Freeze the shared contract before parallel dispatch; follow [dispatch policy](policies/dispatch-policy.md).
5. Give each worker only the context allowed by [context policy](policies/context-policy.md), its task contract, and acceptance criteria. Use the Sonnet builder by default; use Terra only for bounded, explicit tasks.
6. Integrate compatible changes, then require an independent verifier. The verifier must not see builder reasoning and must not modify production code.
7. Apply [review policy](policies/review-policy.md) only after verification. Adjudicate each finding using evidence, not model consensus.
8. Run the required completion gate. Only report `DONE`, `DONE_WITH_NOTES`, `BLOCKED`, or `FAILED` after [completion policy](policies/completion-policy.md) is satisfied.

## Non-negotiable boundaries

- Only the orchestrator may dispatch workers, change scope/risk, request approvals, or declare completion.
- Do not bypass a state: a risk level may make a state a documented no-op, never absent.
- Do not let builders self-verify, reviewers fix code, or reviewers influence one another.
- Stop and report a contract conflict, missing prerequisite, repeated root cause, or exhausted retry budget.
- Keep run artifacts under `.nexum/runs/<run-id>/`; initialize a run with `scripts/run-init.sh`.

## Read when needed

- [Task contract](contracts/task-contract.md) and [shared contract](contracts/shared-contract.md) before dispatch.
- [Terra worker contract](contracts/terra-worker-contract.md) before routing a bounded task to Codex Terra.
- [Dispatch packet](templates/dispatch-packet.md) when a Builder needs a compact execution brief.
- [Verification](policies/verification-policy.md), [failure](policies/failure-policy.md), and [completion](policies/completion-policy.md) for every verification or rework cycle.
- [Review policy](policies/review-policy.md), [review package](templates/review-package.md), and [review state](templates/review-state.yaml) before dispatching an external review.
- [Agent prompts](agents/) when installing them into `~/.claude/agents/`.
- [Templates](templates/) to create durable run artifacts.
