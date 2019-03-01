#/bin/bash

# Make sure we have everything we need
: "${FRONTEND_PUBLIC_SIGNING_KEY:?FRONTEND_PUBLIC_SIGNING_KEY must be set}"
: "${FRONTEND_PUBLIC_SIGNING_KEY_PATH:?FRONTEND_PUBLIC_SIGNING_KEY_PATH must be set}"

# Decode and write to file
echo "$FRONTEND_PUBLIC_SIGNING_KEY" | base64 -d > $FRONTEND_PUBLIC_SIGNING_KEY_PATH
