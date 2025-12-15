# brahma

Single-command system setup.

## What it does

- Installs packages (pacman + yay)
- Symlinks dotfiles from `home/` to `~/`
- Enables podman and libvirt
- Adds `scripts/` to PATH

## Install

```bash
git clone git@github.com:KargJonas/brahma.git ~/code/brahma
cd ~/code/brahma
./setup.sh
```

Log out and back in.

## Structure

```
brahma/
├── setup.sh      # Main setup script
├── scripts/      # Utility scripts (in PATH)
│   ├── dumpdir
│   └── sys
└── home/         # Config files (symlinked to ~/)
    ├── .bashrc
    └── .config/
```

Config files are symlinked - editing `~/.bashrc` edits the repo directly.
