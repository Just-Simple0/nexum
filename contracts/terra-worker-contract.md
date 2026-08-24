# Terra Worker Contract

Use this adapter only for a bounded task with frozen scope and explicit acceptance criteria. The input file supplied to `scripts/terra-worker.sh` must include the task contract, relevant shared boundaries, owned paths, and evidence commands.

## Invocation

```text
scripts/terra-worker.sh --role builder|verifier --project <repository> --output <handoff-file> <contract-file>
```

Run with `--dry-run` when preparing a new route. The adapter pins `gpt-5.6-terra` to high reasoning effort and runs it in a workspace-write sandbox. Its temporary directory is `.nexum/tmp` inside the selected project.

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

Save the final response with `--output` and record model, role, commands, and evidence with `templates/worker-handoff.md`. The orchestrator, not the worker, decides integration and completion.
