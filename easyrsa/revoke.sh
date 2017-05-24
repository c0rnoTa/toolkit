#!/bin/bash

# Скрипт отзыва сертификата на подключение к OpenVPN
# Разработал Антон Захаров hello@antonzakharov.ru

EASY_RSA_DIR="/etc/openvpn/easy-rsa/"
KEYS_DIR="$EASY_RSA_DIR/keys"

if [ -z "$1" ]
then 
        echo -n "Enter certificate name to delete (CN): "
        read -e CN
else
        CN=$1
fi

if [ -z "$CN" ]
        then echo "You must provide a certificate name (CN)."
        exit
fi

cd $EASY_RSA_DIR
if [ -f $KEYS_DIR/$CN.crt ]
then 
	source ./vars > /dev/null
	./revoke-full $CN
else
        echo "Certificate with the CN $CN does not exist!"
        echo " $KEYS_DIR/$CN.crt"
		exit
fi

if [ -f $KEYS_DIR/crl.pem ]
then
	mv $KEYS_DIR/crl.pem /etc/openvpn/
	chmod 644 /etc/openvpn/crl.pem
	echo "Certificate $CN removed!"
fi

