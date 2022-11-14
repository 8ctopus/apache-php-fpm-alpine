#!/bin/sh

DIR=$1
DOMAIN=$2

echo "Generate self-signed SSL certificate for $DOMAIN..."

# generate domain private key
openssl genrsa -out /sites/$DIR/ssl/private.key 2048 2> /dev/null

# create certificate signing request
# to read content openssl x590 -in certificate_authority.pem -noout -text
openssl req -new -key /sites/$DIR/ssl/private.key -out /sites/$DIR/ssl/request.csr -subj "/C=RU/O=8ctopus/CN=$DOMAIN" 2> /dev/null

# create certificate config file
> /sites/$DIR/ssl/config.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
DNS.2 = www.$DOMAIN # add additional domains and subdomains if needed
IP.1 = 192.168.0.13 # you can also add an IP address (if the connection which you have planned requires it)
EOF

# create signed certificate by certificate authority
openssl x509 -req -in /sites/$DIR/ssl/request.csr -CA /sites/config/ssl/certificate_authority.pem -CAkey /sites/config/ssl/certificate_authority.key \
    -CAcreateserial -out /sites/$DIR/ssl/certificate.pem -days 825 -sha256 -extfile /sites/$DIR/ssl/config.ext 2> /dev/null

echo "Generate self-signed SSL certificate for $DOMAIN - OK"
