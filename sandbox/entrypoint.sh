#!/bin/bash
# Seeds Cline's config from the read-only mount set up by `sandbox -a` into a
# writable, throwaway location, so the host's config file stays untouched.
if [[ -d /opt/cline-settings ]]; then
    install -d -m 700 /root/.cline/data/settings
    cp -a /opt/cline-settings/. /root/.cline/data/settings/
    chmod -R go-rwx /root/.cline/data/settings
fi

exec "${@:-/bin/bash}"