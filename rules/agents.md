# Agent Orchestration

## Available Agents

Agents come from several scopes. Do not hardcode a roster here — it goes stale.
List what is actually available with `ls ~/.claude/agents/`, and check the
agent-types list the session provides for plugin- and project-scoped ones.

**User scope** (`~/.claude/agents/`): `code-review`, `code-reviewer`,
`design-review`, `requirements-review`.

**Plugin scope**: the `everything-claude-code` plugin supplies the planning,
TDD, security, build-fix and per-language review agents under an
`everything-claude-code:` prefix (e.g. `everything-claude-code:planner`,
`everything-claude-code:tdd-guide`, `everything-claude-code:security-reviewer`,
`everything-claude-code:build-error-resolver`). Use the prefixed name — there is
no bare `planner` / `tdd-guide` / `architect` agent at user scope.

**Project scope**: repositories may add their own under `.claude/agents/`.

## Agent Usage

**Agents are dispatched only when the user asks for one.** Do not spawn agents
unprompted — the session config sets "Do not call the AgentTool unless the user
requested it", and that takes precedence over this file.

When the user does ask, match the task to the agent:
1. Complex feature requests - Use a planning agent (`everything-claude-code:planner`)
2. Code just written/modified - Use **code-reviewer**
3. Bug fix or new feature - Use a TDD agent (`everything-claude-code:tdd-guide`)
4. Architectural decision - Use an architecture agent (`everything-claude-code:architect`)

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
