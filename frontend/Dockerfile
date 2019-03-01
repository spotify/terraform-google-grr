FROM grrdocker/grr

RUN apt-get update && \
  apt-get install -y \
  curl \
  jq

EXPOSE 8444

ENV DISABLE_INTERNAL_MYSQL=true
ENV CLIENT_INSTALLER_FINGERPRINT=docker
ENV NO_CLIENT_UPLOAD=true
ENV FRONTEND_SERVER_PORT=8080
ENV MONITORING_HTTP_PORT=8444
ENV CERTS_PATH=/etc/grr/certs
ENV FRONTEND_CERT_PATH=$CERTS_PATH/frontend-cert.pem
ENV FRONTEND_PRIVATE_KEY_PATH=$CERTS_PATH/frontend-private.key
ENV FRONTEND_PRIVATE_SIGNING_KEY_PATH=$CERTS_PATH/frontend-signing.key
ENV FRONTEND_PUBLIC_SIGNING_KEY_PATH=$CERTS_PATH/frontend-signing.pub
ENV CA_CERT_PATH=$CERTS_PATH/ca-cert.pem
ENV CA_PRIVATE_KEY_PATH=$CERTS_PATH/ca-private.key

RUN mkdir -p $CERTS_PATH

COPY repack_clients.sh $GRR_VENV/bin/repack_clients.sh
COPY prepare_certs.sh $GRR_VENV/bin/prepare_certs.sh
COPY config.yaml /etc/grr/server.local.yaml

CMD $GRR_VENV/bin/prepare_certs.sh && \
  $GRR_VENV/bin/repack_clients.sh && \
  $GRR_VENV/bin/grr_server \
    --component frontend \
    --secondary_configs /etc/grr/server.local.yaml
