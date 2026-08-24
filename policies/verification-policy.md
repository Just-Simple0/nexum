# Verification Policy

Verification answers whether the implementation satisfies the contract in execution. It is separate from code review and must be performed by the builder's opposite model family when feasible.

| Risk | Minimum evidence |
| --- | --- |
| LOW | Relevant existing tests; build or typecheck where applicable |
| MEDIUM | Relevant tests, a regression test for the changed behavior, build, lint, and typecheck where available |
| HIGH | Unit, integration, and regression coverage; impacted-suite execution; direct acceptance-criterion checks |
| CRITICAL | All HIGH evidence plus staging or dry-run first, rollback feasibility, and no irreversible action before final approval |

The verifier may create tests, fixtures, and disposable repro harnesses. It must not change production code, production configuration, contracts, or scope. Run `scripts/scope-check.sh` against the verifier diff; a prohibited modification invalidates the report.

Return `PASS`, `FAIL`, or `INCONCLUSIVE`. A failure must contain a command, input/preconditions, expected result, actual result, and relevant location.

