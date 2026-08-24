# Terra Worker Contract

Use this adapter only for a bounded task with frozen scope and explicit acceptance criteria. The input file supplied to `scripts/terra-worker.sh` must include the task contract, relevant shared boundaries, owned paths, and evidence commands.

## Invocation

```text
scripts/terra-worker.sh --role builder|verifier --project <repository> --output <handoff-file> [--session-record <session-file>] <contract-file>
```

Run `scripts/preflight.sh` before dispatching. The adapter defaults to `gpt-5.6-terra` at high reasoning effort, but accepts an explicit supported model and effort selected in the task contract. It canonicalizes the project path before running in a workspace-write sandbox; its temporary directory is `.nexum/tmp` inside the selected project.

## Builder lane

- Receives only its frozen task contract and relevant shared boundaries.
- Implements owned paths and reports commands, changed files, and unresolved risk.
- Does not alter contracts, risk, scope, or completion status.

## Verifier lane

- Receives the original request, contracts, final diff, acceptance criteria, and verification commands.
- Verifies a Sonnet-built task. A Terra-built task is verified by `nexum-verifier-sonnet`.
- Reports `PASS`, `FAIL`, or `INCONCLUSIVE` from execution evidence.
- Must not modify production code or configuration.

## Handoff

Save the final response with `--output` and record model, role, commands, and evidence with `templates/worker-handoff.md`. When continuity is useful, add `--session-record` to store the Codex session ID and the original run boundary. The current Codex resume command cannot reassert the project and sandbox boundary, so the orchestrator must use a fresh preflight-validated session unless a future CLI version supports that safely. The orchestrator, not the worker, decides integration and completion.
