# CASE is App Storage for Enterprise (backend)

## Мотивация

Идея данного проекта - централизованное хранение и отдача apk файлов для установки на мобильные устройства.

## Первоначальная настройка

Настроить POSTGRESQL:

Название схемы - public

Создать таблицу скриптом:

```
CREATE TABLE public.apps (
	id serial4 NOT NULL,
	"name" varchar(100) NOT NULL,
	"version" varchar(100) NOT NULL,
	"path" varchar(100) NOT NULL,
	arch varchar(100) NOT NULL,
	"size" int8 NOT NULL,
	package varchar(100) NOT NULL,
	"date" date NOT NULL,
	icon_path varchar(100) NULL,
	description varchar(400) NULL,
	CONSTRAINT apps_pkey PRIMARY KEY (id)
);
```

Установить переменные окружения:

* APKPATH = <путь сохранения артефактов>
* PSHOST = <хост БД>
* PSPORT = <порт БД>
* PSDBNAME = <имя БД>
* PSLOGIN = <имя пользователя БД>
* PSPASSWORD = <пароль БД>

## Компиляция бинарника

* Установить [Dart SDK](https://dart.dev/get-darthttps:/).
* Склонировать/скачать данный репозиторий.
* Зайти в корневую папку репозитория и выполнить команду `dart compile exe bin/server.dart`.

## Настройка на сервере в качестве демона (Linux)

Создать файл с расширением .service следующего содержания и скопировать его в `/etc/systemd/system`

```
[Unit]
Description=<Ваше описание>
After=network.target
[Install]
WantedBy=multi-user.target
[Service]
Type=simple
ExecStart=<пусть к исполняемому файлу>
WorkingDirectory=<путь к папке с бинарником>
Restart=always
RestartSec=5
StandardOutput=syslog
StandartError=syslog
SyslogIdentifier=%n
Environment="APKPATH=<путь сохранения артефактов>"
Environment="PSHOST=<хост БД>"
Environment="PSPORT=<порт БД>"
Environment="PSDBNAME=<имя БД>"
Environment="PSLOGIN=<имя пользователя БД>"
Environment="PSPASSWORD=<пароль БД>"
```

После этого перезагружаем systemctl: `sudo systemctl daemon-reload`

Включаем службу: `sudo systemcel enable <название вашего сервиса>.service`

Запуск службы: `sudo systemctl status <название вашего сервиса>.service`

## Загрузка файла

Загрузка производится методом POST запроса на хост /host/upload с портом 1337 и следующим payload:

```
{
    "fileName": "Название приложения",
    "version": "Версия",
    "arch": "Архитектура",
    "package": "Пакет",
    "description": "Описание приложения",
    "body": "Файл в BASE64"
}
```

При попытке загрузить приложение с тем же именем произойдёт замена файла и обновится запись в БД с новой версией.

## Загрузка иконки

Загрузка производится методом POST запроса на хост /host/icon с портом 1337 и следующим payload:

```
{
    "name": "Название приложения",
    "body": "Файл иконки в BASE64"
}
```

Если имя не найдётся или формат файла будет не png, запрос не пройдёт.

## Скачивание файла

Файл apk скачивается по GET запросу

```
host/download/<название приложения>
```

Если название пустое, возвращается 404 ошибка, если не найдено - 403.

## Получение информации о всех приложениях

Для этого используется GET запрос в /.

Формат ответа:

```
[
    {
        "id": int,
        "name": string,
        "version": string,
        "path": string,
        "arch": string,
        "size": int,
        "package": string,
        "date": DateTime
    }
]
```

Значения arch могут быть common, armv7, armv8, x86.

## Roadmap

* [X] Загрузка файлов POST-запросом и сохранение в БД
* [X] Отдача на скачивание файла по названию приложения
* [X] Подтягивание пути сохранения файла и прочих настроек из переменных окружения
* [ ] Защита POST-запросов
* [ ] Автоматическое разворачивание артефактов через CI/CD (в репозиториях приложений)
