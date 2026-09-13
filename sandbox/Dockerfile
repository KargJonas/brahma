FROM archlinux:latest

RUN sed -i '/NoExtract.*usr\/share\/man/d' /etc/pacman.conf

RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm man-db man-pages texinfo less
RUN pacman -S --noconfirm \
    bash coreutils grep sed gawk git neovim binwalk hexedit \
    bc gcc gdb \
    nodejs npm ripgrep inetutils

# Cline coding agent (CLI). Config/API keys are NOT baked in; they are mounted
# at runtime by `sandbox -a` (see entrypoint.sh).
RUN npm install -g cline

RUN pacman -Scc --noconfirm

COPY .bashrc /root/.bashrc
COPY .git-prompt.sh /root/.git-prompt.sh

# Transparent sudo shim: we're already root, so just exec the wrapped command.
COPY fakesudo /usr/local/bin/sudo
RUN chmod +x /usr/local/bin/sudo

# Seeds mounted Cline config (if any), then drops into the requested command.
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["/bin/bash"]
