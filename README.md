# codex-cli-switch

Smooth account switching for Codex CLI by isolating each account in its own `CODEX_HOME`.

## Core idea

Codex reads login state from `CODEX_HOME`. So the tool does not overwrite one shared `~/.codex/auth.json`.
Instead, it keeps one home directory per account and switches between them.

## Daily commands

You only need these 3 commands:

- `codex-switch <profile>`: switch directly to a profile
- `login`: create or reuse a profile, then log that profile into a Codex account
- `list`: show all profiles plus the last known Codex usage snapshot for each one

Optional cleanup command:

- `logout [profile|default]`: remove saved login state from one profile

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

List profiles and last known usage:

```bash
codex-switch list
```

Example output:

```text
current  profile  login  mode     account        5h  7d   reset        plan
*        default  yes    chatgpt  abcd12...9xyz  6%  28%  04-23 14:50  plus
         main     yes    chatgpt  efgh34...7uvw  2%  11%  04-23 15:10  plus
```

Notes:

- `5h` and `7d` are the last known Codex usage percentages seen in local session logs
- they are not a live API query
- `switch default` returns the shell to the normal `~/.codex`
- `logout default` clears the saved login state in `~/.codex`
- after `logout default`, the `default` row is hidden from `list` unless you switch back to it

## Commands

```text
codex-switch <profile|default>
codex-switch login <profile> [codex-login-args...]
codex-switch list
codex-switch logout [profile|default]
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
