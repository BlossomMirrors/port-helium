# Helium Flatpak

This repository contains the [Flatpak](https://flatpak.org/) manifest for **Helium**, a private, fast, and honest web browser based on Ungoogled Chromium.

It wraps the official prebuilt binaries from the [Helium Linux project](https://github.com/imputnet/helium-linux) into a partially sandboxed Flatpak environment,
ensuring it runs consistently across different Linux distributions.  
Sandbox protection is supported via Zypak.  
Automatic updates are available on [BlossomOS](https://blossomos.org/).

---

## Installation (Recommended)

The easiest way to install Helium is using the standalone bundle. This bypasses the need for manual repositories and works on any system with Flatpak installed.

1.  **Download** the latest `.flatpak` bundle from the [**Releases Page**](https://github.com/ShyVortex/helium-flatpak/releases).
2.  **Install** it via the command line, in the directory where you downloaded the file:

    ```bash
    flatpak install ./helium-[VERSION]-[ARCH].flatpak
    ```

    *Note: on some distributions, you can simply double-click the downloaded file to install it via your Software Center.*

---

## Building from Source

If you want to build the package yourself or contribute to the manifest, follow these steps.

### Prerequisites
Ensure you have `flatpak` and `flatpak-builder` installed. You also need the Flathub repository enabled to download the Freedesktop SDK/Runtime (version 24.08).

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install org.freedesktop.Sdk/x86_64/24.08
```

### Build & Install
Run the following command in the root of this repository. This will download the binary, build the sandbox, and install it to your user directory.

For x86_64 systems:

```bash
flatpak-builder --arch=x86_64 --user --install --force-clean build-dir net.imput.helium.yml
```

For ARM64 systems:

```bash
flatpak-builder --arch=aarch64 --user --install --force-clean build-dir net.imput.helium.yml
```

*Note: to install for all users, use sudo and replace '--user' with '--system'.*

---

## Running the App

Once installed (via bundle or local build), you can launch Helium from your application menu or via the terminal:

```bash
flatpak run net.imput.helium
```

---

## Uninstallation

To remove Helium and its data:

```bash
flatpak uninstall net.imput.helium
# Optional: Remove app data
rm -rf ~/.var/app/net.imput.helium
```

---

**Disclaimer:** This is an unofficial packaging project. For issues related to the browser itself, please refer to the [upstream repository](https://github.com/imputnet/helium). For packaging issues, feel free to open an issue here.
