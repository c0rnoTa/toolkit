#!/bin/bash

# Скрипт создания шифрованного PKCS12 контейнера с ключом, сертификатом и СА сертификатом
# Разработал Антон Захаров hello@antonzakharov.ru

cert_type='usr_cert'
#cert_type='server_cert'

echo -n "Как называется партнёр [$cert_type]? "
read clientname
echo  "Создаю ключ: ./private/$clientname.key.pem"
openssl genrsa -out ./private/$clientname.key.pem 2048
echo  "Создаю CSR: ./csr/$clientname.csr.pem"
openssl req -config openssl.cnf -key private/$clientname.key.pem -new -sha256 -out csr/$clientname.csr.pem
echo  "Подписываю сертификат: ./certs/$clientname.cert.pem"
#usr_cert
#server_cert
openssl ca -config openssl.cnf -extensions $cert_type -days 2920 -notext -md sha256 -in csr/$clientname.csr.pem -out certs/$clientname.cert.pem
echo "Получаю fingerprint..."
fingerprint=`openssl x509 -in ./certs/$clientname.cert.pem -fingerprint -noout`
echo "Формирую PKCS12..."
echo "Генерирую пароль на котейнер: "
# read pkcspass
pkcspass=`tr -dc ABCEFGHJKLMNP-Za-kmnp-z2-9 < /dev/urandom | head -c 12 | xargs`
openssl pkcs12 -export -in certs/$clientname.cert.pem -inkey private/$clientname.key.pem -certfile certs/ca.cert.pem -out /tmp/$clientname.p12 -passout pass:$pkcspass
echo "$clientname ; $pkcspass ; $fingerprint"
echo "Готово!"
