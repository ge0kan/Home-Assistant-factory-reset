# Factory Reset (destructive)

**WARNING:** Irreversibly wipes Home Assistant OS data (configuration, users, installed apps, backups, media, and network settings), then reboots. The operating system and boot configuration remain. This is **not** secure SSD sanitization.

## Requirements

- Home Assistant OS with Supervisor on a **64-bit Raspberry Pi 4**.
- Ethernet with DHCP recommended, as network settings are reset.
- Internet access for reinstallation of Home Assistant after reboot.

## Safe test (no wipe)

1. Install the app. It has `boot: manual_only` and never automatically starts at boot.
2. On **Configuration**, leave `execute: false` and `confirmation: NOT ARMED`.
3. Press **Start**. In **Log**, expect `Safe mode: wipe NOT requested.`

## Irreversible wipe

1. On **Configuration**, set `execute: true`.
2. Set `confirmation` to the **exact, case-sensitive** text `ERASE ALL DATA`.
3. Press **Save** and then **Start** exactly once.
4. The app checks the OS version and board, verifies the Supervisor API, and calls `POST /os/datadisk/wipe` using its admin-scoped token.
5. Home Assistant may disconnect at once. Do **not** turn off the Raspberry Pi. After the reboot and component installation, look for onboarding at `http://homeassistant.local:8123` or the router-assigned IP address.

If the request loses its HTTP connection, wiping **may still have started**. Do not blindly retry. A persistent one-shot marker prevents repeated POST requests in the same installation.

## Security and limits

- Requires `hassio_api: true` with `hassio_role: admin`. No privileged containers, USB, host devices or disk access requested.
- Restricted to `aarch64` / `raspberrypi4-64`; also checks `rpi4-64` in the runtime OS API response.
- All local data is erased; OS and boot configuration survive. Argon fan-control app/scripts may need to be reinstalled.
- Verified by non-destructive unit tests; **not tested with a live wipe** on hardware.
