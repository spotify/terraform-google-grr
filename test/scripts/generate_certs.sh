#/bin/bash
set +o posix
set -e

basedir=$(dirname "$0")

echo "Generating CA private key"
ca_private_key=$(openssl genrsa 2048)

echo "\nGenerating CA certificate"
ca_cert=$( openssl req -x509 -new -nodes -key <(echo "$ca_private_key") -sha256 -days 1825 -subj '/CN=ca.grr.test/O=grr-test/C=US' )

echo "\nGenerating frontend private key"
frontend_private_key=$(openssl genrsa 2048)

echo "\nGenerating frontend signing key"
frontend_private_signing_key=$(openssl genrsa 2048)

echo "\nCalculating frontend public signing key"
frontend_signing_key=$(openssl rsa -in <(echo "$frontend_private_signing_key") -pubout)

echo "\nGenerating frontend CSR"
frontend_csr=$( openssl req -new -nodes -key <(echo "$frontend_private_key") -subj '/CN=frontend.grr.test/O=grr-test/C=US' )

echo "\nGenerating frontend certificate"
frontend_cert=$(openssl x509 -req -in <(echo "$frontend_csr") -CA <(echo "$ca_cert") -CAkey <(echo "$ca_private_key") -set_serial 1  -days 1825)


echo "\nWriting frontend-keys.env file"
cat <<EOF > "$basedir/../frontend-keys.env"
FRONTEND_CERT=$(echo "$frontend_cert" | base64)

FRONTEND_PRIVATE_KEY=$(echo "$frontend_private_key" | base64)

FRONTEND_PRIVATE_SIGNING_KEY=$(echo "$frontend_private_signing_key" | base64)

FRONTEND_PUBLIC_SIGNING_KEY=$(echo "$frontend_signing_key" | base64)

CA_CERT=$(echo "$ca_cert" | base64)

CA_PRIVATE_KEY=$(echo "$ca_private_key" | base64)
EOF

echo "Writing worker-keys.env file"
cat <<EOF > "$basedir/../worker-keys.env"
CA_CERT=$(echo "$ca_cert" | base64)

CA_PRIVATE_KEY=$(echo "$ca_private_key" | base64)
EOF

echo "Writing adminui-keys.env file"
cat <<EOF > "$basedir/../adminui-keys.env"
FRONTEND_PUBLIC_SIGNING_KEY=$(echo "$frontend_signing_key" | base64)
EOF
