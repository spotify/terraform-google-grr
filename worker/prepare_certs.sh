#/bin/bash

# Make sure we have everything we need
: "${CA_CERT:?CA_CERT must be set}"
: "${CA_CERT_PATH:?CA_CERT_PATH must be set}"
: "${CA_PRIVATE_KEY:?CA_PRIVATE_KEY must be set}"
: "${CA_PRIVATE_KEY_PATH:?CA_PRIVATE_KEY_PATH must be set}"

# Decode and write to file
echo "$CA_CERT" | base64 -d > $CA_CERT_PATH
echo "$CA_PRIVATE_KEY" | base64 -d > $CA_PRIVATE_KEY_PATH
