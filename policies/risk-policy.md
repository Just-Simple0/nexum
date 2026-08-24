# Risk Policy

Risk controls workflow depth; it is not an estimate of implementation effort. Classify using the highest applicable level and record the reasons in the task contract.

| Level | Signals | Required controls |
| --- | --- | --- |
| LOW | Isolated, reversible change; no auth, data, money, external side effect, or broad compatibility risk | Automatic approval; verifier; existing relevant tests plus build/typecheck |
| MEDIUM | Multiple files, user flow, external API/SDK, migration-safe persistence change, or meaningful regression risk | Contract; independent verifier; GPT review; Gemini only when its trigger applies |
| HIGH | Auth/permissions, payments, sensitive data, destructive migration, cross-cutting architecture, major compatibility or availability impact | User approval of plan; independent verifier; GPT and Gemini reviews; re-review after material fixes |
| CRITICAL | Production or irreversible action, security incident response, data loss/corruption risk, compliance/legal impact, or safety-critical behavior | User approval of plan and final action; staging/dry-run and rollback validation; both reviews and re-reviews |

Raise risk if uncertainty, blast radius, or irreversibility increases. Lowering risk requires recorded evidence and orchestrator approval.

