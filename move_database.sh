#!/bin/bash

echo 'Начало работы скрипта переноса схем'
echo '====='
echo ''

SERVERFROM=cp-qa-db.cloud1
SERVERTO=cp-qa-db.cloud1
SCHEMA=sprint_scheduler
DBNAME=iqcard

echo "Переношу схему $DBNAME.$SCHEMA"
echo "Сервера $SERVERFROM --> $SERVERTO"

PGDUMPPATH=/usr/pgsql-10/bin/pg_dump
PSQLPATH=/usr/pgsql-10/bin/psql

DUMPNAME=$SCHEMA-`date +%Y%m%d`.sql

echo "На сервере $SERVERFROM снимаю дамп схемы $SCHEMA в базе данных $DBNAME в файл $SERVERFROM:/tmp/$DUMPNAME"
ssh $SERVERFROM -C "$PGDUMPPATH -n $SCHEMA -f /tmp/$DUMPNAME $DBNAME"
echo "Дамп снят."

echo "Переношу $DUMPNAME c $SERVERFROM на локальный сервер в /tmp/$DUMPNAME"
scp $SERVERFROM:/tmp/$DUMPNAME /tmp/$DUMPNAME
echo "Скачала на локальный сервер."

echo "Переношу $DUMPNAME на $SERVERTO в $SERVERTO:/tmp/$DUMPNAME"
scp /tmp/$DUMPNAME $SERVERTO:/tmp/
echo "Выгрузила на сервер $SERVERTO."
echo "Дропаю старую схему $SCHEMA на сервере $SERVERTO"
ssh $SERVERTO -C "$PSQLPATH -U postgres -d $DBNAME -c 'DROP SCHEMA IF EXISTS \"$SCHEMA\" CASCADE;'"
echo "Старая схема удалена"
echo "Разворачиваю схему $SCHEMA на $SERVERTO"
ssh $SERVERTO -C "$PSQLPATH -U postgres --file=/tmp/$DUMPNAME $DBNAME"
echo "Схема развернута"