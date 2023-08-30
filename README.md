# CASE is App Storage for Enterprise (backend)

## Мотивация

Идея данного проекта - централизованное хранение и отдача apk файлов для установки на мобильные устройства.

## Первоначальная настройка

Настроить POSTGRESQL:

Название схемы - public

### Создание таблиц и полей

Последовательность "apps_id_seq":

```
CREATE SEQUENCE public.apps_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;
```

Последовательность "apk_id_seq":

```
CREATE SEQUENCE public.apk_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
```

Таблица "app":

```
CREATE TABLE public.app (
	id int8 NOT NULL DEFAULT nextval('apps_id_seq'::regclass),
	"name" varchar(100) NOT NULL,
	"version" varchar(100) NOT NULL,
	package varchar(100) NOT NULL,
	icon_path varchar(100) NULL,
	description varchar(400) NULL,
	CONSTRAINT apps_pkey PRIMARY KEY (id)
);
```

Таблица "apk":

```
CREATE TABLE public.apk (
	"size" int8 NOT NULL,
	"path" varchar(400) NOT NULL,
	arch varchar(40) NOT NULL,
	id bigserial NOT NULL,
	app_id int8 NOT NULL,
	CONSTRAINT apk_pk PRIMARY KEY (id)
);


-- public.apk foreign keys

ALTER TABLE public.apk ADD CONSTRAINT apk_fk FOREIGN KEY (app_id) REFERENCES public.app(id);
```

Установить переменные окружения:

* PORT = <порт запуска сервера>. По умолчанию 1337.
* WORKPATH = <путь сохранения артефактов>
* PGHOST = <хост БД>
* PGPORT = <порт БД>
* DBNAME = <имя БД>
* DBUSERNAME = <имя пользователя БД>
* DBPASSWORD = <пароль БД>

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
Environment="WORKPATH=<путь сохранения артефактов>"
Environment="PGHOST=<хост БД>"
Environment="PGPORT=<порт БД>"
Environment="DBNAME=<имя БД>"
Environment="DBUSERNAME=<имя пользователя БД>"
Environment="DBPASSWORD=<пароль БД>"
Environment="PORT=<порт хоста>"
```

После этого перезагружаем systemctl: `sudo systemctl daemon-reload`

Включаем службу: `sudo systemcel enable <название вашего сервиса>.service`

Запуск службы: `sudo systemctl status <название вашего сервиса>.service`

## Создание записи "Приложение"

Создание происходит путём отправки POST запроса на эндпоинт `HOST:PORT/apps/<имя пакета>/info` следующего payload:

```
{
    "icon": "PNG в BASE64",
    "version": "Версия",
    "name": "Название приложения",
    "description": "Описание" (может отсутствовать)
}
```

## Обновление записи "Приложение"

Обновление происходит путём отправки PATCH запроса на эндпоинт `/HOST:PORT/apps/<имя пакета>/info` следующего payload:

```
{
    "icon": "PNG в BASE64" 
}
```

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
