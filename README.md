# codex-cli-switch

Smooth account switching for Codex CLI by isolating each account in its own `CODEX_HOME`.

## Core idea

Codex reads login state from `CODEX_HOME`. So the tool does not overwrite one shared `~/.codex/auth.json`.
Instead, it keeps one home directory per account and switches between them.

## Daily commands

You only need these 3 commands:

- `codex-switch <profile>`: switch directly to a profile
- `login`: create or reuse a profile, then log that profile into a Codex account
- `list`: show all profiles plus the last known local usage snapshot for each one

Optional cleanup command:

- `logout [profile|default]`: remove saved login state from one profile

Shared skills commands:

- `codex-switch skills path`: print the shared skills root
- `codex-switch skills init`: create the shared skills root and sync it to all profiles
- `codex-switch skills sync all`: resync shared skills to every profile

Shared resume commands:

- `codex-switch resume path`: print the shared resume root
- `codex-switch resume init`: enable shared Codex resume/session history
- `codex-switch resume update`: resync shared resume metadata from every profile

## Setup

```bash
bash install.sh
```

That installer:

- links the backend script into `~/.local/bin/codex-switch-bin`
- adds `~/.local/bin` to your shell `PATH` if needed
- installs a shell wrapper so `codex-switch hunk` can switch your current shell directly

Then reload your shell once:

```bash
source ~/.zshrc
```

If you use bash instead of zsh, reload `~/.bashrc` or `~/.bash_profile` instead.

## Workflow

Log different accounts into different profiles:

```bash
codex-switch login main
codex-switch login backup
printenv OPENAI_API_KEY_WORK | codex-switch login api-work --with-api-key
```

Switch the current shell:

```bash
codex-switch main
codex-switch backup
codex-switch default
```

After switching, any plain `codex` command in that shell uses that account.

## Shared skills

Shared skills live in:

```bash
codex-switch skills path
```

By default that is:

```text
~/.codex-shared/skills
```

Recommended flow:

```bash
codex-switch skills init
mkdir -p "$(codex-switch skills path)/my-team-skill"
```

Then put your `SKILL.md` inside that skill directory, for example:

```text
~/.codex-shared/skills/my-team-skill/SKILL.md
```

After adding or changing shared skills, run:

```bash
codex-switch skills sync all
```

That links the shared skills into every profile's `skills` directory.
New profiles also get shared skills synced automatically when you `login` or `switch`.

## Shared resume

Codex stores interactive resume data in `sessions/`, `archived_sessions/`, `session_index.jsonl`, and the local `state_5.sqlite` thread index under `CODEX_HOME`.
To let every account resume the same Codex threads while keeping each account's `auth.json` separate, enable the shared resume layer:

```bash
codex-switch resume init
```

By default the shared resume root is:

```text
~/.codex-shared/resume
```

After that, switching profiles syncs resume metadata automatically:

```bash
codex-switch main
codex resume --last
codex-switch backup
codex resume --last
```

Notes:

- shared resume is opt-in; `resume path` only prints/creates the root and does not enable syncing
- run `resume init` when no Codex TUI is actively writing session files
- existing local `sessions`, `archived_sessions`, and `session_index.jsonl` paths are copied into the shared root, then moved under `.codex-switch-backup/<timestamp>` before symlinks are created
- `auth.json`, `config.toml`, logs, model cache, and account-specific state stay profile-local
- `codex resume` filters by current working directory by default; use `codex resume --all` when you want to see sessions from other directories
- avoid resuming and writing to the same Codex thread from two accounts at the same time

List profiles, local auth state, and last known usage:

```bash
codex-switch list
```

Example output:

```text
current  profile        login  account        5h  r5   7d  r7   plan
*        main(default)  yes    abcd12...9xyz  6%  14:50 28% 16:10 plus
         work           yes    efgh34...7uvw  2%  15:10 11% 09:20 plus
```

Notes:

- `Auth` is inferred from local `auth.json`; `list` does not run `codex login status`
- `5h` and `7d` are the last known remaining quota percentages seen in local session logs
- `R5` shows the 5-hour reset time
- `R7` shows the 7-day reset date and time
- quota values come from local session history, not a live API query
- `switch default` returns the shell to the normal `~/.codex`
- `logout default` clears the saved login state in `~/.codex`
- after `logout default`, the `default` row is hidden from `list` unless you switch back to it or it has local usage history

## Commands

```text
codex-switch <profile|default>
codex-switch login <profile> [codex-login-args...]
codex-switch list
codex-switch logout [profile|default]
codex-switch skills path
codex-switch skills init
codex-switch skills sync [profile|default|all]
codex-switch resume path
codex-switch resume init
codex-switch resume update
codex-switch version
codex-switch help
```

## Compatibility aliases

These still work, but they are not the main interface anymore:

- `codex-switch switch <profile>` -> switch explicitly
- `codex-switch off` -> switch back to `default`

## GitHub install flow

Install from GitHub:

```bash
git clone <repo-url>
cd codex-cli-switch
bash install.sh
source ~/.zshrc
```

Update after pulling new changes:

```bash
cd codex-cli-switch
git pull
bash install.sh
source ~/.zshrc
```

One-line installer:

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/main/install.sh | bash
```

That is the piece that turns "a script sitting in a repo" into "a command I can use directly".
