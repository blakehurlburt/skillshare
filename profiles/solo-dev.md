# Solo developer workflow

This is a personal or small-circle project, not an enterprise rollout. Match the process to the size of the task: use structure for work larger than an afternoon and skip ceremony for small changes.

## Workflow routing

- Interactive browser testing, navigation, and live-page inspection: use `/browse`.
- New product or project exploration: use `/brainstorm` before implementation.
- Debugging and root-cause analysis: use `/investigate`.
- Pre-share or pre-deploy security review: use `/security` as the single security entry point.
- Independent review from another model: use `/second-opinion`.
- For larger plans, use `/brainstorm`, then `/autoplan`. Do not suggest that flow for small tasks.

## Working conventions

- For a new project, initialize a small Git repository when one does not exist.
- Add relevant tests to the pre-commit hook and commit cohesive changes.
- Ask before running any command that uses SSH, SCP, rsync over SSH, or an SSH tunnel. Local-only file copies do not require approval.
- Prefer local operation and modest hosting suitable for sharing with friends.
