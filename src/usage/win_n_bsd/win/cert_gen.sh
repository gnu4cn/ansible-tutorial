#!/usr/bin/env bash
# Set the username to the name of the user the certificate will be mapped to
USERNAME="local-user"

cat > openssl.conf << EOL
distinguished_name = req_distinguished_name

[req_distinguished_name]
[v3_req_client]
extendedKeyUsage = clientAuth
subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:${USERNAME}@localhost
EOL

openssl req \
    -new \
    -sha256 \
    -subj "/CN=${USERNAME}" \
    -newkey rsa:2048 \
    -nodes \
    -keyout cert.key \
    -out cert.csr \
    -config openssl.conf \
    -reqexts v3_req_client

openssl x509 \
    -req \
    -in cert.csr \
    -sha256 \
    -out cert.pem \
    -days 365 \
    -extfile openssl.conf \
    -extensions v3_req_client \
    -key cert.key

rm openssl.conf cert.csr
