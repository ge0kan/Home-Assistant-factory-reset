# Factory Reset (destructive)

**WARNING:** This app irreversibly wipes Home Assistant OS user data (configuration, users, installed apps, backups, media and data-disk network configuration), then reboots. HAOS and boot configuration remain installed. It does **not** securely sanitize an SSD or disk.

## Requirements

- **Home Assistant OS + Supervisor**, on a supported **64-bit aarch64 or amd64** host (Raspberry Pi, other ARM64 board, mini-PC or supported VM).
- Does **not** support Home Assistant Container or Core installations.
- Ethernet with DHCP recommended, because network settings are reset.
- Internet access for app installation and reinstalling Home Assistant after reboot.

## Install

1. **Settings → Apps → Install app → ⋮ → Repositories** (older UI: **Settings → Add-ons → Add-on Store**).
2. Add `https://github.com/ge0kan/Home-Assistant-factory-reset`.
3. Install **Factory Reset (destructive)**.

## Safe test (no wipe)

1. On **Configuration**, leave the single field `confirmation` at its default value, `NOT ARMED`.
2. Press **Start**. In **Log**, expect `Safe mode: wipe NOT requested.`
3. No user data is changed.

## Irreversible wipe

1. On **Configuration**, set **only the text in the `confirmation` field** to `ERASE ALL DATA` (case-sensitive).
2. Press **Save**, then **Start** exactly once. Do not paste YAML or any key names into the text field.
3. The app checks the HAOS API before calling `POST /os/datadisk/wipe` using its admin-scoped Supervisor token.
4. Home Assistant may disconnect immediately. Do not power off the host. After reboot and installation, look for onboarding at `http://homeassistant.local:8123` or the router-assigned IP address.

If the HTTP connection closes, wiping **may still have started**. Never blindly retry. A one-shot marker prevents repeat requests in the same installation.

## Safety and limitations

- `boot: manual_only`; **no automatic start on boot**.
- An **exact confirmation phrase** is mandatory; the previous `execute` toggle was redundant and is removed in v1.1.0.
- Works on both HAOS architectures, with no model or board restriction. It requires the official OS data-disk wipe endpoint.
- Uses `hassio_api: true` and `hassio_role: admin`. No privileged containers, host Docker, host devices or direct disk access.
- Wiping deletes local backups. Optional hardware-specific software (fan controllers, buttons) may need reinstallation.
- Non-destructive tests only; no full wipe is claimed as proven on every platform.
