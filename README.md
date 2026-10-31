# Home Assistant Factory Reset

Reset a supported **Home Assistant OS** installation to its fresh-install state remotely, without removing the boot drive or connecting a monitor and keyboard.

> **Warning:** This operation permanently deletes Home Assistant configuration, users, integrations, installed apps, history, local backups, media, and data-disk network settings. Home Assistant OS stays installed. This is not secure disk sanitization.

## Instructions

1. In Home Assistant, open **Settings → Apps → Install app → ⋮ → Repositories**. In older versions, use **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Add this repository: `https://github.com/ge0kan/Home-Assistant-factory-reset`.
3. Install **Factory Reset (destructive)**.
4. Open **Configuration**. There is one text field named `confirmation`; enter plain text, **not YAML**.

### Test without erasing anything

1. Enter **any non-empty text other than the exact phrase `ERASE ALL DATA`**. For example, leave the default `NOT ARMED`, or enter `TEST`.
2. Save the configuration and press **Start**.
3. Open **Log** and look for `Safe mode: wipe NOT requested.`. The app exits without erasing data.

### Perform the factory reset

1. In **Configuration**, replace the entire `confirmation` field with exactly `ERASE ALL DATA` (uppercase, single spaces, no quotes or extra characters).
2. Press **Save**, then **Start** **once**. Stop the app first if it is still running.
3. Home Assistant may disconnect immediately while the system wipes the data disk, reboots, and reinstalls its components. **Do not power off the device or blindly retry.**
4. When it is ready, open `http://homeassistant.local:8123` or the IP address assigned by your router to complete the initial setup.

## Important notes

- Works only with **Home Assistant OS + Supervisor** on supported **64-bit ARM64 or x86-64** systems. It does not support Home Assistant Container or Core.
- The app does **not start automatically**. Reset requires the exact confirmation phrase and a manual **Start**.
- **Any text other than `ERASE ALL DATA` is a safe test**, not a reset request.
- If updating an already installed copy, **check the saved `confirmation` value before pressing Start**. It may retain the reset phrase from an earlier attempt.
- Ethernet with DHCP and internet access are recommended because network settings may be reset and Home Assistant components may need to be downloaded again.
- A lost connection does not necessarily mean the operation failed. Do not attempt another reset until you have checked the device.
- Hardware-specific customizations, such as fan-control services, may need to be reinstalled.
