#!/bin/bash

# Скрипт создания ovpn профайла для подключения по OpenVPN
# Разработал Антон Захаров hello@antonzakharov.ru

#Dir where easy-rsa is placed
EASY_RSA_DIR="/etc/openvpn/easy-rsa/"
KEYS_DIR="$EASY_RSA_DIR/keys"
# Dir where profiles will be placed
OVPN_PATH="/root/profiles"
REMOTE="127.0.0.1 1337"
 
 
if [ -z "$1" ]
then 
        echo -n "Enter new client common name (CN): "
        read -e CN
else
        CN=$1
fi
 
 
if [ -z "$CN" ]
        then echo "You must provide a CN."
        exit
fi
 
cd $EASY_RSA_DIR
if [ -f $KEYS_DIR/$CN.crt ]
then 
        echo "Certificate with the CN $CN already exists!"
        echo " $KEYS_DIR/$CN.crt"
else
source ./vars > /dev/null
./pkitool --pass $CN
fi
 
cat > $OVPN_PATH/${CN}.ovpn << END
client
remote $REMOTE
dev tun
proto tcp
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
cipher AES-128-CBC
key-direction 1

<ca>
`cat $KEYS_DIR/ca.crt`
</ca>
 
<cert>
`sed -n '/BEGIN/,$p' $KEYS_DIR/${CN}.crt`
</cert>

<key>
`cat $KEYS_DIR/${CN}.key`
</key>

<tls-auth>
`cat $KEYS_DIR/ta.key`
</tls-auth>

END

