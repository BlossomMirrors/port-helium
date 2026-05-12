#!/bin/sh
CDM_DIR="${XDG_CONFIG_HOME}/net.imput.helium/WidevineCdm"
mkdir -p "${CDM_DIR}"
echo '{"Path":"/app/lib/helium/WidevineCdm"}' > "${CDM_DIR}/latest-component-updated-widevine-cdm"
exec /app/lib/helium/helium.real --no-sandbox --test-type "$@"
