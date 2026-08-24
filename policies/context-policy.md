# Context Policy

Give each role the smallest context that lets it make a sound decision. Do not use hidden context as a substitute for a clear contract.

| Role | Receives | Must not receive |
| --- | --- | --- |
| Builder | Task contract, relevant shared contract, owned files/interfaces, acceptance criteria, execution constraints | Other builders' private reasoning, reviewer conclusions, orchestrator preference beyond the contract |
| Verifier | Original request, task/shared contracts, final diff, acceptance criteria, commands/environment | Builder reasoning, self-review, reviewer findings, orchestrator conclusion |
| GPT reviewer | Review package: requirements, contracts, final diff, verification evidence | Builder rationale, Gemini findings, adjudication |
| Gemini reviewer | The same independently assembled review package | Builder rationale, GPT findings, adjudication |
| Research worker | Research question, decision required, source constraints | Preferred outcome or unsupported conclusion |

When a contract lacks information required to proceed, the worker must report the gap rather than infer a scope expansion.

