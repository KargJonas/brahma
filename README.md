# brahma

Single-command system setup.

## Install

```bash
git clone https://github.com/KargJonas/brahma.git ~/code/brahma
cd ~/code/brahma
./setup.sh

# Then, log out and back in
```

This
- Asks for your git name/email (stored in untracked `~/.gitconfig.local`)
- Installs a few packages
- Symlinks dotfiles from `home/` to `~/`
- Enables podman and libvirt
- Adds `scripts/` to PATH

## Scripts

### SYS

**`sys`** - system control for sway/Wayland. Run `sys` for help.

| Command          | Short Command | Does                                                |
| ---------------- | ------------- | --------------------------------------------------- |
| `sys power`      | `sys p`       | poweroff / reboot / suspend / lock / logout         |
| `sys brightness` | `sys b`       | set laptop + external (DDC/CI) screen brightness    |
| `sys gamma`      | `sys g`       | screen color temperature (eye comfort)              |
| `sys volume`     | `sys v`       | volume up / down / mute                             |
| `sys profile`    | `sys f`       | power profile (performance / balanced / saver)      |
| `sys screenshot` | `sys s`       | region screenshot. Saved clipboard and `~/Pictures` |
| `sys monitor`    | `sys m`       | open display configurator                           |

## Sandbox

**`sandbox [-n] [-c] [-w] [-a] [dir]`** - drop into a throwaway podman Arch container with `dir` (default: cwd) mounted read-only at `~/host`. Network off, capabilities dropped, and memory/PID limits by default - handy for running untrusted code. Defined in `sandbox/sandbox.sh` (sourced from `.bashrc`).

| Flag              | Effect                             |
| ----------------- | ---------------------------------- |
| `-n`, `--network` | enable network access              |
| `-c`, `--caps`    | grant all capabilities             |
| `-w`, `--write`   | mount the dir read-write           |
| `-a`, `--agent`   | mount Cline agent config (offline) |
| `-b`, `--build`   | rebuild the sandbox image          |

With `-w`, files written by the container (e.g. a binwalk extraction) land in `dir` on the host. Writes are confined to `dir`: nothing else from the host is mounted, so symlinks pointing outside it resolve inside the container's throwaway filesystem, not the host.

The image builds automatically on first use.

### Cline agent

The image ships the [Cline CLI](https://docs.cline.bot/cline-cli/overview), so an
AI agent can work on `dir` from inside the sandbox. API keys are **never** baked
into the image or committed to this repo - they are mounted read-only at runtime.

`sandbox -a` requires no extra setup: it inherits your host Cline config
(`~/.cline/data/settings`) read-only, so whatever provider you've already logged
into with the CLI is available inside the sandbox. `-a` alone keeps the network
off (local models); add `-n` for online providers like OpenRouter, and `-w` lets
it edit:

```bash
sandbox -a  -w .   # offline / local models
sandbox -an -w .   # online (e.g. OpenRouter)
cline
```

Inheriting the host config hands *all* your configured providers (and their keys)
to the sandbox. For untrusted code, set up a dedicated OpenRouter-only config
instead - it takes precedence over the host one:

```bash
cline auth -p openrouter -k 'sk-or-...' -m '<model>' --data-dir ~/.config/brahma/cline
```

`-m` is required by Cline's non-interactive setup and only sets the **default**
model. Switch models in a running session with `/model`, or override per run
with `cline -m <model>`.

`sandbox -a` mounts the chosen config read-only at `/opt/cline-settings`; the
container entrypoint copies it into the throwaway filesystem, so the host copy
can never be modified. Because `-an` lets the agent reach the network, use a
spend-limited API key and treat it as less isolated than a plain `sandbox` run.

## Dumpdir

**`dumpdir <dir> [depth] [exclude...]`** - dump a directory tree and file contents to stdout (skips `node_modules`, `.git`, etc.). Handy for feeding a codebase to an LLM.

## Structure

```
brahma/
├── setup.sh      # Main setup script
├── scripts/      # Utility scripts (in PATH)
│   ├── dumpdir
│   └── sys
├── sandbox/      # Throwaway podman container (sandbox cmd)
└── home/         # Config files (symlinked to ~/)
    ├── .bashrc
    └── .config/
```

Config files are symlinked - editing `~/.bashrc` edits the repo directly.
