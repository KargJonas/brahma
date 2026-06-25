# brahma

Single-command system setup.

## Install

```bash
git clone git@github.com:KargJonas/brahma.git ~/code/brahma
cd ~/code/brahma
./setup.sh

# Then, log out and back in
```

This
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

**`sandbox [-n] [-c] [dir]`** - drop into a throwaway podman Arch container with `dir` (default: cwd) mounted read-only at `~/host`. Network off, capabilities dropped, and memory/PID limits by default - handy for running untrusted code. Defined in `sandbox/sandbox.sh` (sourced from `.bashrc`).

| Flag              | Effect                    |
| ----------------- | ------------------------- |
| `-n`, `--network` | enable network access     |
| `-c`, `--caps`    | grant all capabilities    |
| `-b`, `--build`   | rebuild the sandbox image |

The image builds automatically on first use.

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
