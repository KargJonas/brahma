#!/bin/bash

# Runs in a subshell so the `cd` doesn't move the caller's shell.
_sandbox_build() (
    local dir="$(dirname "${BASH_SOURCE[0]}")"
    cd "$dir" || return 1
    cp ~/.git-prompt.sh .git-prompt.sh
    sed '/^# sandbox-ignore/,$d' ~/.bashrc > .bashrc
    podman build -t sandbox-arch .
    local rc=$?
    rm .bashrc .git-prompt.sh
    return $rc
)

sandbox() {
    local opts=()
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -n|--network) opts+=(--network=slirp4netns) ;;
            -c|--caps) opts+=(--cap-add=all) ;;
            -b|--build) _sandbox_build; return $? ;;
            -h|--help)
                echo "Usage: sandbox [-n] [-c] [dir]"
                echo "       sandbox -b"
                echo "  -n, --network  Enable network access"
                echo "  -c, --caps     Enable all capabilities"
                echo "  -b, --build    Build the sandbox image"
                echo "  -h, --help     Show this help"
                return 0 ;;
        esac
        shift
    done

    if ! podman image exists sandbox-arch; then
        echo "Building sandbox image..."
        _sandbox_build
    fi

    local dir=$(realpath "${1:-$PWD}")

    podman run -it --rm \
        --network=none \
        --cap-drop=all --cap-add=SYS_PTRACE \
        --memory=512m --pids-limit=100 \
        --tmpfs /tmp --tmpfs /var/tmp \
        "${opts[@]}" \
        -v "$dir:/root/host:ro" -w /root \
        sandbox-arch
}
