#!/bin/sh
WIDEVINE_DIR="${XDG_DATA_HOME}/WidevineCdm"
CDM_LIB="${WIDEVINE_DIR}/_platform_specific/linux_x64/libwidevinecdm.so"
CDM_REG="${XDG_CONFIG_HOME}/net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm"

if [ ! -f "${CDM_LIB}" ]; then
    python3 - "${WIDEVINE_DIR}" <<'PYEOF'
import sys, json, urllib.request, hashlib, zipfile, os, tempfile

install_dir = sys.argv[1]
meta_url = "https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/toolkit/content/gmp-sources/widevinecdm.json"

try:
    with urllib.request.urlopen(meta_url) as r:
        meta = json.load(r)

    platform = meta["vendors"]["gmp-widevinecdm"]["platforms"]["Linux_x86_64-gcc3"]
    url = platform["mirrorUrls"][0]
    expected_hash = platform["hashValue"]

    with urllib.request.urlopen(url) as r:
        data = r.read()

    if hashlib.sha512(data).hexdigest() != expected_hash:
        raise ValueError("Widevine checksum mismatch — aborting install")

    with tempfile.NamedTemporaryFile(suffix=".crx3", delete=False) as f:
        f.write(data)
        tmp = f.name

    os.makedirs(install_dir, exist_ok=True)
    with zipfile.ZipFile(tmp) as z:
        for name in ["manifest.json", "_platform_specific/linux_x64/libwidevinecdm.so"]:
            z.extract(name, install_dir)

    os.chmod(os.path.join(install_dir, "_platform_specific/linux_x64/libwidevinecdm.so"), 0o755)
    os.unlink(tmp)
    print("Widevine CDM installed.")
except Exception as e:
    print(f"Widevine setup failed: {e}", file=sys.stderr)
PYEOF
fi

if [ -f "${CDM_LIB}" ]; then
    mkdir -p "$(dirname "${CDM_REG}")"
    printf '{"Path":"%s"}' "${WIDEVINE_DIR}" > "${CDM_REG}"
fi

exec /app/lib/helium/helium.real --no-sandbox --test-type "$@"
