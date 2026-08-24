# Failure Policy

Recover deliberately; do not loop indefinitely.

- Tool failures: retry once, then use an approved fallback or report the blocker.
- Builder failures: retry the same builder once; then one cross-builder attempt; then re-plan; finally escalate if the root cause remains unresolved.
- Verification failures: return reproducible evidence to the builder. Allow at most two verification-fix cycles before orchestration reassessment.
- Review failures: allow at most two automatic fix-review cycles before re-plan or escalation.
- Repeated root cause: if the same underlying issue occurs twice, stop applying local patches and re-examine requirements, architecture, contract, and environment.

Use `INCONCLUSIVE` for missing evidence or environment limits. Do not convert it to `PASS` through confidence alone.

