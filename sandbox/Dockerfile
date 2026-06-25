FROM archlinux:latest

RUN pacman -Syu --noconfirm \
    bash coreutils grep sed gawk git neovim binwalk

COPY .bashrc /root/.bashrc
COPY .git-prompt.sh /root/.git-prompt.sh

# Transparent sudo shim: we're already root, so just exec the wrapped command.
COPY fakesudo /usr/local/bin/sudo
RUN chmod +x /usr/local/bin/sudo

CMD ["/bin/bash"]
