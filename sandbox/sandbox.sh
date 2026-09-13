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
    local agent_opts=()
    local net=--network=none
    local mount_mode=ro
    while [[ "${1:-}" == -* ]]; do
        # Expand combined short flags, e.g. -an -> -a -n.
        if [[ "$1" =~ ^-[a-zA-Z]{2,}$ ]]; then
            local i expanded=()
            for (( i = 1; i < ${#1}; i++ )); do
                expanded+=("-${1:i:1}")
            done
            set -- "${expanded[@]}" "${@:2}"
            continue
        fi
        case "$1" in
            -n|--network) net=--network=pasta ;;
            -c|--caps) opts+=(--cap-add=all) ;;
            -w|--write) mount_mode=rw ;;
            -a|--agent)
                # Prefer a dedicated (least-privilege) config, else inherit the
                # host's Cline config so no extra setup step is needed.
                local seed=""
                if [[ -f "$HOME/.config/brahma/cline/settings/providers.json" ]]; then
                    seed="$HOME/.config/brahma/cline/settings"
                elif [[ -f "$HOME/.cline/data/settings/providers.json" ]]; then
                    seed="$HOME/.cline/data/settings"
                fi
                if [[ -z "$seed" ]]; then
                    echo "No Cline config found. Log in with the CLI once, or set up a dedicated one:" >&2
                    echo "  cline auth -p openrouter -k '<key>' -m '<model>' --data-dir \"$HOME/.config/brahma/cline\"" >&2
                    return 1
                fi
                agent_opts=(-v "$seed:/opt/cline-settings:ro")
                ;;
            -b|--build) _sandbox_build; return $? ;;
            -h|--help)
                echo "Usage: sandbox [-n] [-c] [-w] [-a] [dir]"
                echo "       sandbox -b"
                echo "  -n, --network  Enable network access (needed for online models)"
                echo "  -c, --caps     Enable all capabilities"
                echo "  -w, --write    Mount the dir read-write (writes stay inside it)"
                echo "  -a, --agent    Mount Cline agent config (inherits host ~/.cline)"
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
        "$net" \
        --cap-drop=all --cap-add=SYS_PTRACE \
        --memory=512m --pids-limit=100 \
        --tmpfs /tmp --tmpfs /var/tmp \
        "${opts[@]}" \
        "${agent_opts[@]}" \
        -v "$dir:/root/host:$mount_mode" -w /root/host \
        sandbox-arch
}
