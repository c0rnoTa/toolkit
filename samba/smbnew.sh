#!/bin/bash

# Скрипт создания пользователя SAMBA и сетевой шары для него
# Разработал Антон Захаров hello@antonzakharov.ru

echo -n "Называние папки (без спец символов) [folder]: "
read origname
if [ "${origname}" == "" ]; then
	origname=folder
fi
foldername="/mnt/$origname"
if [ -d $foldername ]; then
	echo "Папка $foldername уже существует на сервере"
	exit
fi 

echo -n "Имя пользователя для доступа к папке (без спец символов) [$origname]: "
read username
if [ "${username}" == "" ]; then
	username=$origname
fi
userfound=`cat /etc/passwd | grep $username | wc -l`
if [ "$userfound" -gt "0" ]; then
	echo "Такой пользователь уже существует на сервере"
	exit
fi 

echo "Создаю в системе папку $foldername и пользователя $username ..."
useradd -d "$foldername" -m -N -G nobody -s '/bin/false' $username
if [ -d $foldername ]; then
	rm -f $foldername/.bash_logout
	rm -f $foldername/.bash_profile
	rm -f $foldername/.bashrc
fi 

echo "Пароль доступа к папке (любые символы): "
smbpasswd -a $username

echo "Папка и пользователь созданы. Необходимо добавить в /etc/samba/smb.conf следующее содержание: "
echo "
[$origname]
path = $foldername
browsable = no
writable = yes
guest ok = no
read only = no
public = no
valid users = $username"

