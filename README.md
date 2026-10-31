# Home Assistant Factory Reset

Одноразовий Home Assistant App для **повного віддаленого скидання Home Assistant OS** на **Raspberry Pi 4 (64-bit)** із SSD. Не потребує підключення монітора, клавіатури чи розбирання корпусу.

> **Увага!** Скидання безповоротно видаляє Home Assistant, налаштування, інтеграції, користувачів, додатки, історію, локальні резервні копії та мережеві налаштування. Home Assistant OS та boot-конфігурація залишаються. Це не фізичне очищення SSD.

## Встановлення через UI

1. Перевір, що в **Settings → System → Repairs → ⋮ → System information** тип інсталяції — **Home Assistant OS**, а архітектура — **aarch64**. Стара 32-бітна HAOS не підтримується.
2. Відкрий **Settings → Apps → Install app → ⋮ → Repositories** (в окремих версіях це **Settings → Add-ons → Add-on Store → ⋮ → Repositories**).
3. Додай URL **https://github.com/ge0kan/Home-Assistant-factory-reset**.
4. Знайди **Factory Reset (destructive)** та натисни **Install**. App збирається з відкритого коду на самій Raspberry Pi; потрібен доступ до інтернету.

## Спочатку безпечна перевірка

У вкладці **Configuration** залиш типові значення:

```yaml
execute: false
confirmation: NOT ARMED
```

Натисни **Start**. У журналі (**Log**) має з'явитися `Safe mode: wipe NOT requested.` **Жодних даних не буде стерто.**

## Повне скидання — незворотна дія

1. У **Configuration** зміни параметри на:

   ```yaml
   execute: true
   confirmation: ERASE ALL DATA
   ```

2. Натисни **Save** → **Start** **один раз**.
3. App перевірить Supervisor та тип плати (обов'язково **rpi4-64**), виконає офіційний API-виклик `POST /os/datadisk/wipe`.
4. Raspberry Pi перезавантажиться, повторно завантажить компоненти й покаже початкове налаштування. Відкрий `http://homeassistant.local:8123` або IP від DHCP роутера.

**Після запуску не вимикай живлення.** Втрата HTTP-з'єднання не означає невдачі: скидання могло вже початися. Не запускай операцію повторно наосліп.

## Запобіжники

- `boot: manual_only` — немає автозапуску.
- Потрібні обидва параметри: `execute=true` та **точний текст** `ERASE ALL DATA`.
- Фільтр платформи `raspberrypi4-64` і перевірка `rpi4-64` через Supervisor API.
- Одноразовий файл-маркер блокує повторну спробу після невизначеного результату.
- Немає привілейованого контейнера, доступу до host Docker чи прямого запису на SSD.

**Стан тестування:** синтаксичні перевірки + 8 автоматизованих безпечних сценаріїв. Реальне скидання фізичного пристрою не тестувалося. Повний опис: [DOCS.md](factory_reset/DOCS.md).

**Важливо для корпусу Argon:** додаткові скрипти управління вентилятором або кнопкою можуть потребувати повторного встановлення після скидання.

### Документація Home Assistant

- [App repository](https://developers.home-assistant.io/docs/apps/repository/)
- [App configuration](https://developers.home-assistant.io/docs/apps/configuration/)
- [Supervisor OS API](https://contributors.home-assistant.io/apps/supervisor-api/host/)
- [OS data wipe](https://www.home-assistant.io/common-tasks/os/)
