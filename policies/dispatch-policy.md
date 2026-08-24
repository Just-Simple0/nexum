# Dispatch Policy

The orchestrator owns decomposition, dispatch, integration, and task state.

## Builder routing

- **Direct:** a mechanical, reversible change with no runtime behavior change. Do not invoke a worker.
- **Terra High:** bounded implementation with an explicit file scope, frozen contract, known interfaces, and clear acceptance criteria.
- **Sonnet High:** repository-wide understanding, ambiguous requirements, refactors, long-running exploration, or architecture-sensitive work.
- **Lower effort/model:** use only after representative evidence shows equivalent verified outcomes for that execution class. Do not lower effort solely to reduce a single run's tokens.
- **Cross-builder retry:** after one unsuccessful retry by the original builder, route one independent attempt to the other builder family before replanning.

## Terra dispatch protocol

Before dispatching Terra, freeze the task contract and run `scripts/preflight.sh`. This must validate the selected model/effort, Codex CLI capabilities, Git worktree, and writable project-local temporary directory without creating a model run. Then validate the adapter with `scripts/terra-worker.sh --dry-run`.

Choose model and effort in the contract, not during a worker run. Change model only at a retry boundary.

For a recoverable retry, preserve the prior Builder session ID with `--session-record` when session continuity is useful. Resume only if the installed Codex CLI can reassert the original project root, `workspace-write` sandbox, and writable temporary directory for that session. The current `codex exec resume` interface cannot accept those boundary options, so this adapter must start a fresh preflight-validated sandboxed session instead. Include a compact retry summary and the prior session record in that fresh contract; never silently use `resume --last`.

Use the builder lane for a bounded Terra implementation; verify it with `nexum-verifier-sonnet` in a fresh context. For a Sonnet-built task, invoke the Terra verifier lane with a package that includes the final diff and verifier contract.

Use `templates/dispatch-packet.md` for Builder context. Its default limit is a 350-word execution brief plus exact commands and narrow initial file references. A larger packet requires a recorded reason; do not send policy documents, prior agent reasoning, or review results to a Builder.

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
