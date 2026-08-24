# Completion Policy

The orchestrator may close a run only after recording one terminal status.

| Status | Meaning |
| --- | --- |
| DONE | All acceptance criteria, required verification, review obligations, scope checks, cleanup, and approvals pass |
| DONE_WITH_NOTES | Work is complete but a non-blocking, explicitly recorded limitation remains; never use for unresolved BLOCKER/HIGH issues |
| BLOCKED | A dependency, decision, approval, or environment condition prevents progress |
| FAILED | The run exhausted approved recovery paths or cannot meet the contract |

Before `DONE`, confirm: requirements pass; verification passes; required reviews are complete; no unresolved BLOCKER/HIGH or critical uncertainty exists; scope check passes; temporary artifacts are handled; and required approvals are captured. Use `scripts/completion-check.sh` as a mechanical preflight, then make the evidence-based judgment.

