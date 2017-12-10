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
BPATHS=""

# Пути к файлам (через пробел), которые будем бэкапить
BFILES=""

# Параметры подключения к MySQL
BMYSQLUSER=""
BMYSQLPASSWORD=""

# Параметры подключения к PostgreSQL
BPSQLUSER="postgres"
BPSQLDATABASE=""

# Параметры отправки уведомления на e-mail
FROMMAIL=""
NOTIFYMAIL=""
SMTPHOST=""

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
chmod 777 $BTEMPDIR
cd $BTEMPDIR

if [ ! -z "$BPATHS" ]; then
    # Дамп директорий
    i=1
    for CURRDIR in $BPATHS; do
    	echo `date` 'Копирую директорию' $CURRDIR
    	echo "$i : $CURRDIR" >> paths.log
    	tar cf $BTEMPDIR/$BSERVERNAME-$i-$BDATEFORMAT.tar $CURRDIR --recursion
    	i=`expr $i + 1`
    done
fi

if [ ! -z "$BFILES" ]; then
    # Дамп файлов
    i=1
    for CURRFILE in $BFILES; do
        echo `date` 'Копирую файл' $CURRFILE
        echo "$i : $CURRFILE" >> paths.log
        cp $CURRFILE $BTEMPDIR/
        i=`expr $i + 1`
    done
fi

# Дамп базы данных MySQL, если запущен сервис
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

# Дамп базы данных PostgreSQL, если установлен pg_dump и указано имя базы
PSQLDUMPBIN=`whereis pg_dump | awk '{print $2}'`
if [ -f $PSQLDUMPBIN ]; then
    echo `date` 'Обнаружен pg_dump. Сохраняем базы данных.'
    if [ ! -z "$BPSQLDATABASE" ]; then
        for DATABASE in $BPSQLDATABASE; do
            echo `date` 'Делаю дамп базы' $DATABASE
            sudo -u postgres $PSQLDUMPBIN -f $BTEMPDIR/$BSERVERNAME-$DATABASE-$BDATEFORMAT.sql $DATABASE
            echo `date` 'Сжимаю дамп базы' $DATABASE
		    gzip -9 $BTEMPDIR/$BSERVERNAME-$DATABASE-$BDATEFORMAT.sql
        done
        echo `date` "Сохранение баз PostgreSQL завершено."
    fi
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
if [ ! -z "$BSAMBAHOST" ]; then
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
fi

# Отправляем нотификацию о выполненной работе
SENDEMAILBIN=`whereis sendEmail | awk '{print $2}'`
if [ -f $SENDEMAILBIN ]; then
    if [ ! -z "$NOTIFYMAIL" ]; then
        if [ ! -z "$FROMMAIL" ]; then
            if [ ! -z "$SMTPHOST" ]; then
                echo `date` 'Отправляю уведомление о выполненной работе на ' $NOTIFYMAIL ' через ' $SMTPHOST
                NOTIFYMSG="Резервное копирование на сервере $BSERVERNAME выполнено в файл $BSERVERNAME-$BDATEFORMAT.tar.gz."
                $SENDEMAILBIN -o timeout=10 -f $FROMMAIL -t $NOTIFYMAIL -u "Резервное копирование $BSERVERNAME" -m "$NOTIFYMSG" -s $SMTPHOST
            else
                echo `date` 'Уведомление о выполненной работе не отправлено. Не указан SMTP сервер.'
            fi
        else
            echo `date` 'Уведомление о выполненной работе не отправлено. Не указан адрес отправителя.'
        fi
    else
        echo `date` 'Уведомление о выполненной работе не отправлено. Не указан адрес получателя.'
    fi
fi


echo `date` 'Работа завершена'

# Возврат вывода всех сообщений
exec 1>&3 2>&4
exit