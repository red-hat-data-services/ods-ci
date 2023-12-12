#!/bin/sh

mkdir tmp
BASE_CERT_DIR=tmp/client_cert
mkdir $BASE_CERT_DIR

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj "/O=Example Inc./CN=myclient.local" -keyout $BASE_CERT_DIR/root.key -out $BASE_CERT_DIR/root.crt

openssl req -nodes -newkey rsa:2048 -subj "/CN=test.myclient.local/O=Example Inc." -keyout $BASE_CERT_DIR/private.key -out $BASE_CERT_DIR/sign_req.csr

openssl x509 -req -days 365 -set_serial 0 -CA $BASE_CERT_DIR/root.crt -CAkey $BASE_CERT_DIR/root.key -in $BASE_CERT_DIR/sign_req.csr -out $BASE_CERT_DIR/public.crt

# openssl x509 -in ${BASE_CERT_DIR}/public.crt -text