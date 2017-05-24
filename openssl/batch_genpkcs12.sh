#!/bin/bash

# Скрипт создания по файлу пачки шифрованных PKCS12 контейнеров с ключом, сертификатом и СА сертификатом
# Разработал Антон Захаров hello@antonzakharov.ru

file=`cat $1`
for clientname in $file; do
    echo  "Создаю ключ: ./private/$clientname.key.pem"
    openssl genrsa -out ./private/$clientname.key.pem 2048
    echo  "Создаю CSR: ./csr/$clientname.csr.pem"
    export KEY_COMMONNAME=$clientname
    yes '' | openssl req -config openssl.cnf -key private/$clientname.key.pem -new -sha256 -out csr/$clientname.csr.pem -subj "/C=RU/ST=Moscow/L=Moscow/O=API-RU/OU=CLIENTS/CN=$clientname"
    echo  "Подписываю сертификат: ./certs/$clientname.cert.pem"
    echo -ne 'y\ny\n' | openssl ca -config openssl.cnf -extensions usr_cert -days 2920 -notext -md sha256 -cert certs/ca.cert.pem -keyfile private/ca.keynopass.pem -in csr/$clientname.csr.pem -out certs/$clientname.cert.pem
    echo "Получаю fingerprint..."
    fingerprint=`openssl x509 -in ./certs/$clientname.cert.pem -fingerprint -noout`
    echo "Формирую PKCS12..."
    echo -n "Генерирую пароль на котейнер: "
    # read pkcspass
    pkcspass=`tr -dc ABCEFGHJKLMNP-Za-kmnp-z2-9 < /dev/urandom | head -c 12 | xargs`
    clearpass=${pkcspass:0:${#pkcspass}-1}
    openssl pkcs12 -export -in certs/$clientname.cert.pem -inkey private/$clientname.key.pem -certfile certs/ca.cert.pem -out ../P12/$clientname.p12 -passout pass:$clearpass
    echo "$clientname ; $clearpass ; $fingerprint" >> ./genpkcs12.log
done
echo "Готово!
