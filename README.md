# Home Assistant Factory Reset

A one-time Home Assistant App for remotely restoring **Home Assistant OS** to a fresh-install state. Works with **supported 64-bit HAOS systems** (ARM64 / x86-64), including Raspberry Pi, mini-PCs and VMs. It does **not** work with Home Assistant Container or Core installations.

> ⚠️ **Destructive and irreversible.** Deletes HA configuration, users, integrations, apps, history, locally stored backups, media and data-disk network settings. HAOS and boot configuration remain installed. This is **not secure disk sanitization**.

## Швидка інструкція українською

1. У Home Assistant відкрий **Settings → Apps → Install app → ⋮ → Repositories** (у старішому UI: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**).
2. Додай репозиторій: **https://github.com/ge0kan/Home-Assistant-factory-reset**.
3. Встанови **Factory Reset (destructive)**. У **Configuration / Параметри** побачиш **одне текстове поле `confirmation`**.
4. **Безпечний тест:** залиш `NOT ARMED`, натисни **Start**. У **Log / Журнал** має з'явитися `Safe mode: wipe NOT requested.`
5. **Стерти все:** у полі **`confirmation`** видали старий текст і введи рівно **`ERASE ALL DATA`** (великими літерами, без лапок). **Не вставляй YAML**, `confirmation:` або `execute: true`.
6. Натисни **Save / Зберегти**, потім **Start / Запустити** **один раз**. Якщо додаток іще працює, спочатку зупини його (**Stop**).
7. Home Assistant може відразу втратити з'єднання й перезавантажитися. **Не вимикай живлення і не повторюй запуск навмання.** Після відновлення відкрий `http://homeassistant.local:8123` або IP-адресу, видану роутером.

**Важливо:** `ERASE ALL DATA` + натискання **Start** запускають незворотну операцію. Перемикача `execute` більше немає — він не був системною вимогою. Автозапуск заборонений (`boot: manual_only`).

## Quick start (English)

1. In Home Assistant OS, go to **Settings → Apps → Install app → ⋮ → Repositories** (older UI: **Settings → Add-ons → Add-on Store**).
2. Add **https://github.com/ge0kan/Home-Assistant-factory-reset**, then install **Factory Reset (destructive)**.
3. On **Configuration**, there is just **one text field: `confirmation`**. To dry-run safely, leave `NOT ARMED` and press **Start**. The log should say `Safe mode: wipe NOT requested.`
4. To wipe, enter **exactly `ERASE ALL DATA`** in the field (not YAML), press **Save**, then **Start** exactly once.
5. Do not power off or blindly retry if the UI disconnects. Wait for HAOS to restart and reinstall Home Assistant, then reopen `http://homeassistant.local:8123` or the DHCP IP.

## Safeguards and compatibility

- Restricted to supported Home Assistant OS architectures: **aarch64** and **amd64**. No Raspberry Pi or device-model restriction.
- Manual start only; a case-sensitive confirmation phrase is required.
- Supervisor API is checked before wiping, and a one-shot marker prevents repeat requests in the same installation.
- Uses the official Supervisor `POST /os/datadisk/wipe` endpoint, without direct host-disk access or privileged Docker.
- Requires internet access to install the App and reinstall Home Assistant components after the wipe. Ethernet with DHCP is recommended.
- An interrupted API call may still initiate a wipe; never blindly retry.
- Tested with non-destructive mocks and syntax checks. **A full wipe has not been independently verified across platforms.**

Full technical notes: [DOCS.md](factory_reset/DOCS.md).

### Home Assistant documentation

- [App configuration](https://developers.home-assistant.io/docs/apps/configuration/)
- [App repository](https://developers.home-assistant.io/docs/apps/repository/)
- [App communication and Supervisor API](https://developers.home-assistant.io/docs/apps/communication/)
