#!/bin/bash

# Скрипт создания резервной копии конфигурации сервера
# Разработал Антон Захаров hello@antonzakharov.ru

################
# КОНФИГУРАЦИЯ #
################

# Параметры подключения к серверу бэкапов по SAMBA
BSAMBAHOST=""
BSAMBAUSER=""
BSAMBAPASS=""

# Пути к директориям (через пробел), которые будем бэкапить
BPATHS="/etc/nginx /var/www/"

# Пути к файлам (через пробел), которые будем бэкапить
BFILES=""

# Параметры подключения к MySQL
BMYSQLUSER=""
BMYSQLPASSWORD=""

#################
# НАЧАЛО БЭКАПА #
#################

# Инициализируем переменные
BLOG="/var/log/backup.log"
BSERVERNAME=`hostname`
BDATEFORMAT=`date +%Y%m%d`

# Вывод всех сообщений в лог
exec 3>&1 4>&2 >>$BLOG 2>&1
echo `date` 'Начало резервирования' $BSERVERNAME

# Проверяем наличие SAMBA клиента
BSAMBACMD=`whereis smbclient | awk '{print $2}'`
if [ ! -f $BSAMBACMD ]; then
	echo `date` 'SAMBA клиент в системе не обнаружен. Установите smbclient.'
	exit
fi

# Создание временной директории с резервной копией
BTEMPDIR=/tmp/$BDATEFORMAT
mkdir -p $BTEMPDIR
cd $BTEMPDIR

# Дамп директорий
i=1
for CURRDIR in $BPATHS; do
	echo `date` 'Копирую директорию' $CURRDIR
	echo "$i : $CURRDIR" >> paths.log
	tar cf $BTEMPDIR/$BSERVERNAME-$i-$BDATEFORMAT.tar $CURRDIR --recursion
	i=`expr $i + 1`
done

# Дамп файлов
i=1
for CURRFILE in $BFILES; do
	echo `date` 'Копирую файл' $CURRFILE
	echo "$i : $CURRFILE" >> paths.log
	cp $CURRFILE $BTEMPDIR/
	i=`expr $i + 1`
done


# Дамп базы данных, если запущен MySQL
if [ -f /var/run/mysqld/mysqld.pid ]; then
	echo `date` "Обнаружен PID файл MySQL. Сохраняем все базы данных."
	DATABASESLIST=`echo 'SHOW DATABASES' | mysql -u$BMYSQLUSER -p$BMYSQLPASSWORD | egrep -v '(Database|information_schema|mysql|performance_schema|test)'`
	for DATABASE in $DATABASESLIST; do
		echo `date` 'Делаю дамп базы' $DATABASE
		mysqldump -u$BMYSQLUSER -p$BMYSQLPASSWORD $DATABASE > $BTEMPDIR/$BSERVERNAME-$DATABASE-$BDATEFORMAT.sql
		echo `date` 'Сжимаю дамп базы' $DATABASE
		gzip -9 $BTEMPDIR/$BSERVERNAME-$DATABASE-$BDATEFORMAT.sql
	done
	echo `date` "Сохранение баз MySQL завершено."
fi

# Сжимаем конечный архив
echo `date` 'Сжимаю архив' $BSERVERNAME-$BDATEFORMAT.tar.gz
cd $BTEMPDIR
tar cfz ../$BSERVERNAME-$BDATEFORMAT.tar.gz .
cd ..
if [ -f $BSERVERNAME-$BDATEFORMAT.tar.gz ]; then
  echo `date` 'Удаляю временные файлы после бэкапа'
  rm -rf /tmp/$BDATEFORMAT
fi

# Сохраняем архив на ресурсе SAMBA
BSAMBASHARE="//$BSAMBAHOST/$BSAMBAUSER"
echo `date` 'Сохраняю' $BSERVERNAME-$BDATEFORMAT.tar.gz 'на' $BSAMBASHARE
if [ "$BSAMBAUSER" = "" ]; then
	BSAMBAUSER='Guest'
fi
if [ "$BSAMBAPASS" = "" ]; then
	BSAMBAUSER="$BSAMBAUSER --no-pass"
fi
# Вынесено без ТАБов. Копирование на внешний ресурс
smbclient $BSAMBASHARE --timeout=60 -U $BSAMBAUSER $BSAMBAPASS<<EOC
put $BSERVERNAME-$BDATEFORMAT.tar.gz
EOC
# Конец копирования на SAMBA

# Удаляю локальный файл бэкапа
if [ -f $BSERVERNAME-$BDATEFORMAT.tar.gz ]; then
  echo `date` 'Удаляю локальный файл бэкапа'
  rm /tmp/$BSERVERNAME-$BDATEFORMAT.tar.gz
fi

echo `date` 'Работа завершена'

# Возврат вывода всех сообщений
exec 1>&3 2>&4
