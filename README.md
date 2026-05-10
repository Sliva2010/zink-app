# ZINK

> Персональный ИИ-репетитор на базе **GigaChat:Lite**. Строгий чёрно-белый минимализм, плавные премиум-анимации и 15+ продвинутых функций.

[![Build APK](https://github.com/Sliva2010/ZINK/actions/workflows/build.yml/badge.svg)](https://github.com/Sliva2010/ZINK/actions/workflows/build.yml)

---

## Возможности

| Раздел | Описание |
|---|---|
| Адаптивный онбординг | Имя, возраст, любимые предметы, цель на день, стиль общения |
| Чат-репетитор | Стриминг ответов GigaChat, история, регенерация, сохранение в конспект |
| Голосовой ввод | Распознавание речи на русском (speech_to_text) |
| Озвучка ответов | TTS на русском |
| OCR-сканер тетрадей | ML Kit, прикрепление текста к вопросу |
| Конспекты | Создание, редактирование, поиск, экспорт в фирменный PDF |
| Карточки SRS | Алгоритм SuperMemo SM-2, очередь повторений |
| Квизы | Авто-генерация ИИ по любой теме, мгновенная оценка |
| Mind Maps | Радиальная визуализация структуры темы от ИИ |
| История чатов | Полнотекстовый поиск по всем диалогам |
| Геймификация | XP, 30+ уровней, 20+ достижений |
| Streak / Daily Goal | Учёт ежедневной активности |
| Оффлайн-кеш | Последние ответы и конспекты доступны без сети |
| Инверсный режим | Переключение чёрный ↔ белый |
| Премиум-переходы | Кастомные fade/shared-axis на go_router |
| Haptic feedback | Лёгкая вибрация при каждом значимом действии |

## Стек

- **Flutter** 3.32.4, **Dart** 3.5+
- **state**: `flutter_riverpod`
- **routing**: `go_router` + кастомные `CustomTransitionPage`
- **network**: `dio` + кастомный `SecurityContext` с CA Минцифры РФ
- **storage**: `hive` + `hive_flutter`
- **OCR**: `google_mlkit_text_recognition`
- **STT/TTS**: `speech_to_text` + `flutter_tts`
- **PDF**: `pdf` + `printing` + `share_plus`
- **charts**: `fl_chart`

## SSL Минцифры РФ

GigaChat API доступен только через сертификаты Минцифры (Russian Trusted Root CA, Russian Trusted Sub CA). Сертификаты встроены в `assets/certificates/` и регистрируются в `SecurityContext` при инициализации HTTP-клиента.

## Сборка

### Локально

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

### CI

GitHub Actions автоматически собирает release APK при пуше в `main`:
- `app-armeabi-v7a-release.apk` (~25 МБ)
- `app-arm64-v8a-release.apk` (~26 МБ)
- `app-x86_64-release.apk` (~28 МБ)
- `app-release.apk` (universal, ~60 МБ)

APK скачивается из вкладки **Actions → последний билд → Artifacts → `zink-release-apks`**.

### Секреты GitHub (опционально)

Для подмены креденшелов GigaChat задать `GIGACHAT_AUTH_KEY`, `GIGACHAT_CLIENT_ID`, `GIGACHAT_SCOPE`, `GIGACHAT_MODEL`. Если секреты не заданы — используются defaults из `lib/core/config/app_config.dart`.

## Производительность

- `minSdk` 24, `targetSdk` 35
- ProGuard + R8 (shrink + minify) — минимизирован размер APK
- `--split-per-abi` — APK на конкретное устройство ~25 МБ
- Все списки на `ListView.builder`, виджеты с `const` где возможно
- Анимации только GPU-friendly (Opacity, Transform)
- Прогрев STT/TTS в фоне на старте

## Структура

```
lib/
├── main.dart               # Entry: Hive init, SystemUI, ProviderScope
├── app/zink_app.dart       # MaterialApp.router, локализация, темы
├── core/
│   ├── config/             # AppConfig (creds, константы XP)
│   ├── theme/              # B&W палитра, типографика Inter, тема M3
│   ├── animations/         # Premium-переходы для go_router
│   ├── network/            # SSL Минцифры + GigaChat OAuth/Stream
│   ├── storage/            # Hive boxes (user, chats, notes, cards, …)
│   ├── router/             # go_router + RoutePaths
│   ├── services/           # Voice, TTS, OCR, PDF, gamification, streak
│   ├── srs/                # SM-2 алгоритм
│   ├── gamification/       # Уровни + каталог достижений
│   ├── utils/              # Даты, haptics
│   └── providers.dart      # Riverpod провайдеры
├── models/                 # Plain Dart data-classes + JSON serde
├── features/               # По одной папке на фичу
└── widgets/                # ZinkButton, ZinkCard, ZinkChip, …
```

## License

Образовательный проект. Все права на бренд и интеграцию GigaChat принадлежат соответствующим правообладателям.
