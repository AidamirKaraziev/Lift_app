---
tags: [debugging, тесты, docker, worktree, инструменты]
date: 2026-09-15
---

# make test из worktree не идёт — тестовый контейнер держит основной чекаут

## Симптом

В `.claude/worktrees/E04` команда `make test` не поднимает тестовую базу:
`docker compose … up -d --wait` спотыкается о контейнер
`lift-test-postgres`, и до pytest дело не доходит. Повторялось в каждой
сессии E04 (S02, S03, S05), каждый раз разбирались заново.

## Настоящая причина

Две вещи в `Makefile` и `infra/docker-compose.test.yml` считают, что чекаут
один:

- `container_name: lift-test-postgres` зашито, а имя compose-проекта берётся
  из каталога (`--project-directory .`): для основного чекаута это
  `lift_app`, для worktree — `e04`. Второй проект пытается создать
  контейнер с тем же именем, который уже занят первым, — Docker отказывает.
- `.test.env` не в git (это правильно), и в свежем worktree его нет —
  `--env-file .test.env` падает ещё раньше, пока файл не скопирован.

Сами тесты к каталогу не привязаны: `backend/tests/conftest.py` берёт
`.test.env` из корня репо или из `backend/` и ходит на `localhost:${DB_PORT}`
(5435).

## Как починили

Не чинили — обходили. Пока в основном чекауте контейнер уже поднят
(`make test-db-up` там), из worktree достаточно:

```bash
cd backend && uv run pytest
```

Плюс скопировать `.test.env` из основного чекаута в корень worktree один
раз. Результат тот же, что у `make test`: E04·S05 — 1046 passed.

## Урок

- Перед `make test` в worktree проверить `docker ps | grep lift-test` —
  если контейнер жив, звать pytest напрямую и не тратить время на compose.
- Настоящая правка — снять `container_name` из тестового compose (тогда у
  каждого проекта свой контейнер, но и свой порт придётся разводить) либо
  вынести `-p lift-test` в `COMPOSE_TEST`, чтобы оба чекаута считали
  контейнер одним и тем же проектом и переиспользовали его. Второе проще
  и не трогает порт.
- Та же болезнь у `frontend/.dart_tool/`: в worktree его нет, и
  `dart analyze` / `flutter test` требуют скопировать `package_config.json`
  из main, не запуская `pub get`
  ([[flutter pub get в контейнере переписывает pubspec.lock и ломает анализ]]).

Связано: [[бэкенд в контейнере падал на DB_HOST из локального .env]],
[[правка примонтированного файла не доезжает до контейнера]]
