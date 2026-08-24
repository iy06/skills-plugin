# Performance Optimization

## Model Selection Strategy

Current generation is the Claude 5 family plus Haiku 4.5. Prefer the latest and
most capable model by default; drop a tier only for cheap, high-volume work.

**Haiku 4.5** (`claude-haiku-4-5-20251001`) — fast and cheap:
- Lightweight agents with frequent invocation
- Mechanical, high-volume worker agents in multi-agent systems

**Sonnet 5** (`claude-sonnet-5`) — balanced:
- Main development work
- Orchestrating multi-agent workflows

**Opus 5** (`claude-opus-5`) — deepest reasoning:
- Complex architectural decisions
- Research and analysis tasks

**Fable 5** (`claude-fable-5`) is also available.

Do not name retired versions (Sonnet 4.6, Opus 4.5) in model-selection guidance.

## Context Window Management

Avoid last 20% of context window for:
- Large-scale refactoring
- Feature implementation spanning multiple files
- Debugging complex interactions

Lower context sensitivity tasks:
- Single-file edits
- Independent utility creation
- Documentation updates
- Simple bug fixes

## Extended Thinking + Plan Mode

Extended thinking is enabled by default, reserving up to 31,999 tokens for internal reasoning.

Control extended thinking via:
- **Toggle**: Option+T (macOS) / Alt+T (Windows/Linux)
- **Config**: Set `alwaysThinkingEnabled` in `~/.claude/settings.json`
- **Budget cap**: `export MAX_THINKING_TOKENS=10000`
- **Verbose mode**: Ctrl+O to see thinking output

For complex tasks requiring deep reasoning:
1. Ensure extended thinking is enabled (on by default)
2. Enable **Plan Mode** for structured approach
3. Use multiple critique rounds for thorough analysis
4. Use split role sub-agents for diverse perspectives

## Build Troubleshooting

If build fails:
1. Use a build-fix agent (`everything-claude-code:build-error-resolver`, or the
   language-specific variant such as `everything-claude-code:cpp-build-resolver`)
2. Analyze error messages
3. Fix incrementally
4. Verify after each fix
