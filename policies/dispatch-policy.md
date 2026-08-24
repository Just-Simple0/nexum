# Dispatch Policy

The orchestrator owns decomposition, dispatch, integration, and task state.

## Builder routing

- **Sonnet High (default):** repository-wide understanding, ambiguous requirements, refactors, long-running exploration, or architecture-sensitive work.
- **Terra High:** bounded implementation with an explicit file scope, frozen contract, known interfaces, and clear acceptance criteria.
- **Cross-builder retry:** after one unsuccessful retry by the original builder, route one independent attempt to the other builder family before replanning.

## Terra dispatch protocol

Before dispatching Terra, freeze the task contract and validate the adapter with `scripts/terra-worker.sh --dry-run`. Use the builder lane for a bounded Terra implementation; verify it with `nexum-verifier-sonnet` in a fresh context. For a Sonnet-built task, invoke the Terra verifier lane with a package that includes the final diff and verifier contract.

Persist the worker's final response with `--output` and record model, role, commands, and evidence using `templates/worker-handoff.md`. A worker handoff is evidence, not a completion decision.

## Parallel work

Run at most three builders at once and only if all are true:

- dependency nodes are independent;
- the shared contract is frozen;
- file ownership does not overlap;
- outputs are not consumed by another active task; and
- acceptance criteria are independently testable.

Use worktree isolation for parallel native workers. The orchestrator integrates changes; workers never merge or reassign ownership.

## Authority

Workers may implement, test, report, and recommend. They may not spawn workers, expand scope, alter contracts, alter risk, request user approval, or declare final completion.
