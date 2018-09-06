#!/bin/bash

# Скрипт переноса XML файлов на другой сервер
# Разработал Антон Захаров hello@antonzakharov.ru

################
# КОНФИГУРАЦИЯ #
################

# Путь где находятся файлы
PATH_SOURCE=/home/localuser/folder

# куда складывать архивы
PATH_DESTINATION=remoteuser@192.168.1.1:
DESTINATION_PASSWORD=password

DO_DELETE=1

########################
# НАЧАЛО АРХИВИРОВАНИЯ #
########################

# Инициализируем переменные
BDATEFORMAT=`date +%Y%m%d_%H%M%S`
BSERVERNAME=`hostname`

echo `date` 'Начало переноса'

count=$(find $PATH_SOURCE -type f -name *.xml -not -path "$PATH_SOURCE/archive/*" | wc -l)
if [ $count -gt 0 ]; then
    echo "Нашла $count файлов"
else
    echo "Нет файлов для переноса"
	exit
fi

# Создание временной директории, куда будут перенесены файлы
BTEMPDIR=/tmp/$BDATEFORMAT
mkdir -p $BTEMPDIR
chmod 777 $BTEMPDIR
cd $BTEMPDIR

if [ ! -z "$PATH_SOURCE" ]; then
    # Переносим файлы в tmp директорий
    find $PATH_SOURCE -type f -name '*.xml' -not -path "$PATH_SOURCE/archive/*" -exec mv {} $BTEMPDIR/ \;
fi



# Копирование на внешний ресурс
SSHPASS=$DESTINATION_PASSWORD sshpass -e sftp  -oBatchMode=no -b - $PATH_DESTINATION<<EOC
cd upload
mput *.xml
EOC

# Сжимаем конечный архив
echo `date` 'Сжимаю архив' $BSERVERNAME-$BDATEFORMAT.tar.gz
cd $BTEMPDIR
tar cfz $PATH_SOURCE/archive/$BSERVERNAME-$BDATEFORMAT.tar.gz .
cd ..

if [ "${DO_DELETE}" == "1" ]; then
    if [ -f $PATH_SOURCE/archive/$BSERVERNAME-$BDATEFORMAT.tar.gz ]; then
        echo `date` 'Удаляю временные файлы после бэкапа'
        rm -rf /tmp/$BDATEFORMAT
    fi
fi

echo `date` 'Удаляю старые архивы'
find $PATH_SOURCE/archive -type f -name $BSERVERNAME-*.tzr.gz -mtime +365 -delete

echo `date` 'Работа завершена'
exit
