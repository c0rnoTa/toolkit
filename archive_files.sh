#!/bin/bash

# Скрипт создания архивов файлов старше N дней
# Разработал Антон Захаров hello@antonzakharov.ru

################
# КОНФИГУРАЦИЯ #
################

# Путь где находятся файлы
PATH_SOURCE=/home/gpc1c/upload

# Путь куда складывать архивы
PATH_DESTINATION=/home/gpc1c/upload

# Количество дней, старше которых файлы будут обрабатываться
ROTATE_DAYS=60

# Удалять или не удалять файлы после обработки
DO_DELETE=1

########################
# НАЧАЛО АРХИВИРОВАНИЯ #
########################

# Инициализируем переменные
BDATEFORMAT=`date +%Y%m%d`
BSERVERNAME=`hostname`

echo `date` 'Начало архивирования'

# Создание временной директории, куда будут перенесены файлы
BTEMPDIR=/tmp/$BDATEFORMAT
mkdir -p $BTEMPDIR
chmod 777 $BTEMPDIR
cd $BTEMPDIR

if [ ! -z "$PATH_SOURCE" ]; then
    # Переносим файлы в tmp директорий
    find $PATH_SOURCE -type f -mtime +60 -exec mv {} $BTEMPDIR/ \;
fi

# Сжимаем конечный архив
echo `date` 'Сжимаю архив' $BSERVERNAME-$BDATEFORMAT.tar.gz
cd $BTEMPDIR
tar cfz $PATH_DESTINATION/$BSERVERNAME-$BDATEFORMAT.tar.gz .
cd ..

if [ "${DO_DELETE}" == "1" ]; then
    if [ -f $PATH_DESTINATION/$BSERVERNAME-$BDATEFORMAT.tar.gz ]; then
        echo `date` 'Удаляю временные файлы после бэкапа'
        rm -rf /tmp/$BDATEFORMAT
    fi
fi

echo `date` 'Работа завершена'
exit