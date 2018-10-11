#!/bin/bash

# Скрипт выгрузки файла status.log на FTP сервер
# Разработал Антон Захаров hello@antonzakharov.ru

echo `date` 'Сервис выгрузки файлов status.log запущен'
STOREDCHECKSUMM=0
echo `date` 'Начинаю следить за изменением файла'
while true
do
sleep 2
CHECKSUMM=$(cat /tmp/status.log | tail -n +3 | cksum | awk '{print $1}')

if [ "$CHECKSUMM" -ne "$STOREDCHECKSUMM" ] ; then
echo `date` "Файл изменился"

STOREDCHECKSUMM=$CHECKSUMM

ftp -n <<EOF
open ftp-server-ip
user FTPUserName FTPPassword
put /tmp/status.log /status.log
quit
EOF

echo `date` "Выгрузка файла на FTP завершена"

fi

done

